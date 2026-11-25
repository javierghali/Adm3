-- adm_autotrade_join_safe.lua
-- Receiver-only; native trade safety checks are not overridden.
-- Internal Adopt Me interfaces are not public/stable; test on one client.
local CONFIG = {
    MASTER_ENABLED = true,
    FORCE_SETTINGS = {
        enabled = true,
        also_force_giving = false,
    },
    AUTO_ACCEPT = {
        enabled = true,
        poll = 0.4,
        refire_every = 1.0,
    },
    JOIN_PROTECTION = {
        ready_grace = 30,
        first_trade_idle = 60,
    },
    WINTERHUB = {
        enabled = true,
        idle_hop_seconds = 12,
        heartbeat = 5,
    },
    WEBHOOK = {
        enabled = false,
        url = "",
        report = "received",
    },
    DEBUG = true,
}

local function log(...)
    if CONFIG.DEBUG then print("[autotrade-safe]", ...) end
end
if not CONFIG.MASTER_ENABLED then return end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait(0.5)
    LocalPlayer = Players.LocalPlayer
end
local guard = "__adm_autotrade_" .. tostring(LocalPlayer.UserId)
if getgenv then
    if getgenv()[guard] then log("duplicate execution ignored") return end
    getgenv()[guard] = true
end

local ready, teleporting, scan_ok = false, false, false
local in_trade, dialog_pending = false, true
local last_activity, last_scan = os.clock(), 0
local trade_count, last_items = 0, {}
local last_stage, last_fire = nil, 0
local pending_trade = nil
local ready_since, current_dialog, current_trade = nil, nil, nil
local settings_done, last_settings_try = false, -math.huge
local UIManager, Fsys, load, Promise, KindDB
local hooked = setmetatable({}, {__mode = "k"})
local wh_file = LocalPlayer.Name .. "_winteraddons.json"
local last_status

local function mark_activity() last_activity = os.clock() end
local function reset_readiness(reason)
    ready, scan_ok, in_trade, dialog_pending = false, false, false, true
    ready_since, current_dialog, current_trade = nil, nil, nil
    last_stage, last_fire, pending_trade = nil, 0, nil
    settings_done, last_settings_try = false, -math.huge
    mark_activity()
    log("LOADING:", reason)
end

-- Independent heartbeat: overwrite a previous server's completed status
-- before trying to load the game's internal modules.
local function publish_status()
    if not CONFIG.WINTERHUB.enabled then return end
    local now = os.clock()
    local status = "active"
    local idle_limit = trade_count == 0 and
        math.max(CONFIG.JOIN_PROTECTION.first_trade_idle, CONFIG.WINTERHUB.idle_hop_seconds)
        or CONFIG.WINTERHUB.idle_hop_seconds
    if ready and settings_done and scan_ok and not teleporting and
        not in_trade and not dialog_pending and
        now - last_scan <= math.max(3, CONFIG.AUTO_ACCEPT.poll * 4) and
        now - last_activity >= idle_limit then
        status = "completed"
    end
    local ok, err = pcall(function()
        writefile(wh_file, HttpService:JSONEncode({
            status = status, ts = os.time(), count = trade_count, items = last_items,
        }))
    end)
    if not ok then log("heartbeat write failed:", err)
    elseif status ~= last_status then log("WinterHub:", status) end
    if ok then last_status = status end
end
publish_status()
if CONFIG.WINTERHUB.enabled then
    task.spawn(function()
        while true do
            task.wait(CONFIG.WINTERHUB.heartbeat)
            publish_status()
        end
    end)
end

-- Do not allow an old READY state to survive a teleport attempt.
pcall(function()
    LocalPlayer.OnTeleport:Connect(function(state)
        local name = state.Name
        if name == "Failed" then
            teleporting = false
            reset_readiness("teleport failed")
        else
            teleporting = true
            reset_readiness("teleport: " .. name)
        end
        publish_status()
    end)
end)

-- Preserve the original optional idle handler; never install it twice.
pcall(function()
    local VirtualUser = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end)

local function ensure_modules()
    if not Fsys then
        local module = game.ReplicatedStorage:FindFirstChild("Fsys")
        if not module then return false end
        Fsys = require(module)
        load = Fsys.load
    end
    if not UIManager then UIManager = load("UIManager") end
    if not UIManager then return false end
    if CONFIG.AUTO_ACCEPT.enabled and not Promise then
        pcall(function() Promise = load("package:Promise") end)
        if not Promise then pcall(function() Promise = load("Promise") end) end
    end
    return not CONFIG.AUTO_ACCEPT.enabled or Promise ~= nil
end

local function force_trade_settings()
    if not CONFIG.FORCE_SETTINGS.enabled then return true end
    local helper = load("SettingsHelper")
    local db = require(game.ReplicatedStorage.ClientDB.SettingsDB)
    local function set_everyone(id)
        local def = db.by_id[id]
        if not def then error("missing setting: " .. id) end
        local idx = table.find(def.element_options.choices, "Everyone")
        if not idx then error("missing Everyone option: " .. id) end
        helper.set_setting_client({setting_id = id, value = idx})
    end
    set_everyone("trade_requests")
    if CONFIG.FORCE_SETTINGS.also_force_giving then set_everyone("give_item_requests") end
    return true
end

-- Instance-scoped wrapper. Only normal incoming trade requests are answered.
-- Never override exclusion rules, CAPTCHA, warnings or unrelated dialogs.
local function install_accept_hook(dialog)
    if not CONFIG.AUTO_ACCEPT.enabled then return true end
    if hooked[dialog] and dialog.dialog == hooked[dialog] then return true end
    local original = dialog.dialog
    if type(original) ~= "function" or not Promise then return false end
    local wrapper = function(self, opts, ...)
        if ready and not teleporting and self == current_dialog and
            type(opts) == "table" and opts.handle == "trade_request" then
            mark_activity()
            log("incoming trade request")
            local p = Promise.resolve("Accept")
            if opts.yields or opts.yields == nil then return p:expect() end
            return p
        end
        return original(self, opts, ...)
    end
    dialog.dialog = wrapper
    if dialog.dialog ~= wrapper then return false end
    hooked[dialog] = wrapper
    return true
end

-- Read dialog state only; do not respond to already-open generic tickets.
local function has_pending_dialog(dialog)
    local count, done = dialog.ticket_count, dialog.completed_ticket
    if type(count) == "number" and type(done) == "number" then
        return count > done or dialog.is_dialog_open == true
    end
    if type(dialog.is_dialog_open) == "boolean" then return dialog.is_dialog_open end
    return true -- unknown state: no hop and no automated trade button presses
end

local function pet_label(item)
    local def = KindDB and KindDB[item.kind]
    local name = tostring((def and def.name) or item.kind or "Unknown")
    local p = item.properties or {}
    local prefix = p.mega_neon and "Mega Neon " or (p.neon and "Neon " or "")
    local tag = (p.rideable and "R" or "") .. (p.flyable and "F" or "")
    return prefix .. name .. (tag ~= "" and (" [" .. tag .. "]") or "")
end

local function summarize(items, with_forms)
    local counts, order, out = {}, {}, {}
    for _, item in pairs(items or {}) do
        local def = KindDB and KindDB[item.kind]
        local name = with_forms and pet_label(item) or tostring((def and def.name) or item.kind or "Unknown")
        if not counts[name] then order[#order + 1] = name end
        counts[name] = (counts[name] or 0) + 1
    end
    for _, name in ipairs(order) do out[#out + 1] = {name = name, qty = counts[name]} end
    return out
end

local function report_trade(received, given, partner_name)
    if not CONFIG.WEBHOOK.enabled or CONFIG.WEBHOOK.url == "" then return end
    local req = (syn and syn.request) or (http and http.request) or http_request or request
    if not req then log("no webhook HTTP function") return end
    local fields = {}
    local function field(title, items)
        local lines, n = {}, 0
        for _, row in ipairs(summarize(items, true)) do
            n = n + row.qty
            lines[#lines + 1] = tostring(row.qty) .. "x " .. row.name
        end
        fields[#fields + 1] = {name = title .. " (" .. n .. ")", value = #lines > 0 and table.concat(lines, "\n") or "nothing", inline = false}
    end
    if CONFIG.WEBHOOK.report ~= "given" then field("Received (observed offer)", received) end
    if CONFIG.WEBHOOK.report == "given" or CONFIG.WEBHOOK.report == "both" then field("Given (observed offer)", given) end
    local res = req({Url = CONFIG.WEBHOOK.url, Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = HttpService:JSONEncode({username = "ADM AutoTrade", embeds = {{
            title = "Trade closed after both confirmed",
            description = partner_name and ("Partner: " .. partner_name) or nil,
            fields = fields, footer = {text = LocalPlayer.Name .. " | client observation, not server receipt"},
        }}}),
    })
    local code = type(res) == "table" and tonumber(res.StatusCode or res.Status) or nil
    if code and code >= 200 and code < 300 then log("webhook sent")
    else log("webhook response:", code or "unknown") end
end

local function copy_items(items)
    local out = {}
    for _, item in pairs(items or {}) do
        local p = item.properties or {}
        out[#out + 1] = {kind = item.kind, properties = {
            mega_neon = p.mega_neon, neon = p.neon, rideable = p.rideable, flyable = p.flyable,
        }}
    end
    return out
end

local function step_trade(app)
    local state = app:_get_local_trade_state()
    if not state then
        if last_stage == "confirmation" and pending_trade then
            trade_count = trade_count + 1
            last_items = summarize(pending_trade.received, false)
            local record = pending_trade
            task.spawn(function()
                local ok, err = pcall(report_trade, record.received, record.given, record.partner)
                if not ok then log("webhook error:", err) end
            end)
            log("trade closed after both confirmed; server completion unverified")
        end
        last_stage, pending_trade, in_trade = nil, nil, false
        return
    end
    in_trade = true
    mark_activity()
    local stage = state.current_stage
    if stage ~= last_stage then
        last_stage, last_fire, pending_trade = stage, 0, nil
        log("trade stage:", stage)
    end
    local mine, partner = app:_get_my_offer(), app:_get_partner_offer()
    if stage == "confirmation" then
        if mine and partner and mine.confirmed and partner.confirmed then
            local pp = state.sender == LocalPlayer and state.recipient or state.sender
            pending_trade = {received = copy_items(partner.items), given = copy_items(mine.items),
                partner = typeof(pp) == "Instance" and pp.Name or nil}
        else
            pending_trade = nil
        end
    end
    -- Receiver only: never automate accepting/confirming an outgoing offer.
    -- Pending security dialogs are left for the player to handle.
    if not CONFIG.AUTO_ACCEPT.enabled or dialog_pending or not mine or
        type(mine.items) ~= "table" or next(mine.items) ~= nil then return end
    if os.clock() - last_fire < CONFIG.AUTO_ACCEPT.refire_every then return end
    last_fire = os.clock()
    if stage == "negotiation" and not mine.accepted then app:_on_accept_pressed()
    elseif stage == "confirmation" and not mine.confirmed then app:_on_confirm_pressed() end
end

local job_id = game.JobId
local function tick()
    if game.JobId ~= job_id then
        job_id = game.JobId
        teleporting = false
        trade_count, last_items = 0, {}
        reset_readiness("new server")
        publish_status()
    end
    if teleporting then return end
    if not game:IsLoaded() or not LocalPlayer.Character then
        if ready or ready_since then reset_readiness("game/character unavailable") end
        return
    end
    if not ensure_modules() then return end
    local apps = UIManager.apps
    local dialog, trade = apps and apps.DialogApp, apps and apps.TradeApp
    if not dialog or not trade or type(trade._get_local_trade_state) ~= "function" then
        if ready or ready_since then reset_readiness("UI unavailable") end
        return
    end
    if dialog ~= current_dialog or trade ~= current_trade then
        reset_readiness("UI instances changed")
        current_dialog, current_trade = dialog, trade
        ready_since = os.clock()
    end
    if not ready_since then ready_since = os.clock() end
    if os.clock() - ready_since < CONFIG.JOIN_PROTECTION.ready_grace then return end
    if not install_accept_hook(dialog) then
        ready = false
        return
    end
    if not settings_done then
        if os.clock() - last_settings_try < 5 then return end
        last_settings_try = os.clock()
        settings_done = force_trade_settings()
        if not settings_done then return end
    end
    if not ready then
        ready = true
        mark_activity()
        log("READY")
    end
    dialog_pending = has_pending_dialog(dialog)
    if dialog_pending then mark_activity() end
    if not KindDB then pcall(function() KindDB = load("KindDB") end) end
    step_trade(trade)
    last_scan, scan_ok = os.clock(), true
end

log("starting; waiting for game and UI")
while true do
    scan_ok = false
    local ok, err = pcall(tick)
    if not ok then
        ready = false
        mark_activity()
        log("tick error; hop blocked:", err)
    end
    task.wait(CONFIG.AUTO_ACCEPT.poll)
end
