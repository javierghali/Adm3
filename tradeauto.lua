-- Adopt Me auto-trader for Delta / WinterHub.
-- Edit CONFIG only. Test on a small trade before using unattended.
local CONFIG = {
    MASTER_ENABLED = true,
    FORCE_SETTINGS = { enabled = true, also_force_giving = true },
    AUTO_ACCEPT = { enabled = true, poll = 0.25, refire_every = 0.5 },
    WINTERHUB = { enabled = true, idle_hop_seconds = 6, heartbeat = 1 },
    WEBHOOK = { enabled = false, url = "", report = "received" },
    DEBUG = false,
}
local function log(...) if CONFIG.DEBUG then print("[autotrade]", ...) end end
if not CONFIG.MASTER_ENABLED then return end
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer
local env = getgenv and getgenv()
local guard_key = "__adm_autotrade_" .. tostring(LP.UserId)
if env and env[guard_key] then
    print("[autotrade] already running for this account")
    return
end
local token = {}
if env then env[guard_key] = token end
local function release()
    if env and env[guard_key] == token then env[guard_key] = nil end
end
local function run()
    pcall(function()
        local vu = game:GetService("VirtualUser")
        LP.Idled:Connect(function() vu:CaptureController(); vu:ClickButton2(Vector2.new()) end)
    end)
    local Fsys = require(game.ReplicatedStorage:WaitForChild("Fsys"))
    local load = Fsys.load
    local UIManager, SettingsHelper, SettingsDB, KindDB
    local function try_load(name)
        local ok, result = pcall(load, name)
        if ok then return result end
        return nil
    end
    local function ui()
        -- Retry after early execution or a UI reload.
        local current = try_load("UIManager")
        if current then UIManager = current end
        return UIManager and UIManager.apps
    end
    local function settings_deps()
        SettingsHelper = SettingsHelper or try_load("SettingsHelper")
        if not SettingsDB then
            pcall(function() SettingsDB = require(game.ReplicatedStorage.ClientDB.SettingsDB) end)
        end
        return SettingsHelper and SettingsDB
    end
    local function kind_db()
        KindDB = KindDB or try_load("KindDB")
        return KindDB
    end
    local last_activity = os.clock()
    local function activity() last_activity = os.clock() end
    local function force_everyone(id)
        if not settings_deps() then return false end
        local ok, result = pcall(function()
            local def = SettingsDB.by_id[id]
            local choices = def and def.element_options and def.element_options.choices
            local index = choices and table.find(choices, "Everyone")
            if not index then return false end
            SettingsHelper.set_setting_client({ setting_id = id, value = index })
            return true
        end)
        return ok and result == true
    end
    local function force_settings()
        if not CONFIG.FORCE_SETTINGS.enabled then return true end
        local trade_ok = force_everyone("trade_requests")
        local giving_ok = not CONFIG.FORCE_SETTINGS.also_force_giving or force_everyone("give_item_requests")
        return trade_ok and giving_ok
    end
    local hooked_classes = setmetatable({}, { __mode = "k" })
    local function hook_ready()
        local apps = ui()
        local d = apps and apps.DialogApp
        local class = d and getmetatable(d)
        class = class and class.__index
        return class and hooked_classes[class] == class.dialog
    end
    local function install_hook()
        if not CONFIG.AUTO_ACCEPT.enabled then return false end
        local apps = ui()
        local dialog = apps and apps.DialogApp
        local class = dialog and getmetatable(dialog)
        class = class and class.__index
        if not class or type(class.dialog) ~= "function" then return false end
        if hooked_classes[class] == class.dialog then return true end
        local promise = try_load("package:Promise") or try_load("Promise")
        if not promise or not promise.resolve then return false end
        local original = class.dialog
        local wrapper = function(self, opts, ...)
            if opts and opts.handle == "trade_request" then
                activity()
                local p = promise.resolve("Accept")
                if opts.yields or opts.yields == nil then return p:expect() end
                return p
            end
            return original(self, opts, ...)
        end
        class.dialog = wrapper
        hooked_classes[class] = wrapper
        log("trade dialog hooked")
        return true
    end
    -- The hook only sees future dialogs. Answer an already open ticket only
    -- while the game's visible trade-request dialog is on screen.
    local forced_dialog, forced_ticket
    local function visible_dialog_text(needle)
        local gui = LP:FindFirstChildOfClass("PlayerGui")
        if not gui then return false end
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local words = string.upper(tostring(child.Text or "")):gsub("%s+", " ")
                if string.find(words, needle, 1, true) then
                    local node, visible = child, true
                    while node and node ~= gui do
                        if node:IsA("GuiObject") and not node.Visible then visible = false break end
                        if node:IsA("ScreenGui") and not node.Enabled then visible = false break end
                        node = node.Parent
                    end
                    if visible then return true end
                end
            end
        end
        return false
    end
    local function answer_open_dialog()
        local response
        if visible_dialog_text("SENT YOU A TRADE REQUEST") then
            response = "Accept"
        elseif visible_dialog_text("BE CAREFUL WHEN TRADING")
            and visible_dialog_text("NEVER TRADE ITEMS FOR BUCKS")
            and visible_dialog_text("OKAY") then
            response = "Okay"
        elseif visible_dialog_text("THIS TRADE SEEMS UNBALANCED")
            and visible_dialog_text("TRADING ARE BANNABLE")
            and visible_dialog_text("NEXT") then
            response = "Next"
        else
            return
        end
        local apps = ui()
        local dialog = apps and apps.DialogApp
        if not dialog or not dialog.force_response_signal then return end
        local count = tonumber(dialog.ticket_count) or 0
        local done = tonumber(dialog.completed_ticket) or 0
        if count <= done then return end
        local ticket = done + 1
        if forced_dialog == dialog and forced_ticket == ticket then return end
        dialog.force_response_signal:Fire(ticket, table.pack(response))
        forced_dialog, forced_ticket = dialog, ticket
        activity()
        log("answered visible trade dialog", response, ticket)
    end
    local function snapshot(items)
        local out = {}
        for _, item in ipairs(items or {}) do
            local prop = item.properties or {}
            out[#out + 1] = { kind = tostring(item.kind or "unknown"), properties = {
                mega_neon = prop.mega_neon, neon = prop.neon,
                rideable = prop.rideable, flyable = prop.flyable,
            } }
        end
        return out
    end
    local function label(item)
        local db = kind_db()
        local def = db and db[item.kind]
        local name = tostring((def and def.name) or item.kind)
        local p = item.properties or {}
        local prefix = p.mega_neon and "Mega Neon " or (p.neon and "Neon " or "")
        local tag = (p.rideable and "R" or "") .. (p.flyable and "F" or "")
        return prefix .. name .. (tag ~= "" and (" [" .. tag .. "]") or "")
    end
    local function summarize(items)
        local counts, order = {}, {}
        for _, item in ipairs(items or {}) do
            local name = label(item)
            if not counts[name] then order[#order + 1] = name end
            counts[name] = (counts[name] or 0) + 1
        end
        local lines = {}
        for _, name in ipairs(order) do lines[#lines + 1] = ("%dx %s"):format(counts[name], name) end
        return lines
    end
    local last_sig, last_sig_time
    local function webhook(received, given, partner)
        local cfg = CONFIG.WEBHOOK
        if not cfg.enabled or cfg.url == "" then return end
        local sig = HttpService:JSONEncode({ partner, received, given })
        if sig == last_sig and os.clock() - last_sig_time < 6 then return end
        local fields = {}
        if cfg.report ~= "given" then
            local lines = summarize(received)
            fields[#fields + 1] = { name = "Received (" .. #received .. ")", value = #lines > 0 and table.concat(lines, "\n") or "nothing", inline = false }
        end
        if cfg.report == "given" or cfg.report == "both" then
            local lines = summarize(given)
            fields[#fields + 1] = { name = "Given (" .. #given .. ")", value = #lines > 0 and table.concat(lines, "\n") or "nothing", inline = false }
        end
        local req = (syn and syn.request) or (http and http.request) or http_request or request
        if not req then return end
        local payload = { username = "ADM AutoTrade", embeds = {{
            title = "Trade complete", description = partner and ("with **" .. partner .. "**") or nil,
            color = 5763719, fields = fields, footer = { text = LP.Name },
        }} }
        local ok, response = pcall(req, { Url = cfg.url, Method = "POST",
            Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
        if ok and response and (not response.StatusCode or response.StatusCode < 400) then
            last_sig, last_sig_time = sig, os.clock()
        else log("webhook failed", response and response.StatusCode) end
    end
    local last_app, last_stage, last_fire, in_trade = nil, nil, 0, false
    local completing, pending_received, pending_given, pending_partner = false, nil, nil, nil
    local trade_count, last_items = 0, nil
    local function reset_trade()
        last_stage, last_fire, in_trade, completing = nil, 0, false, false
        pending_received, pending_given, pending_partner = nil, nil, nil
    end
    local function step_trade()
        if not CONFIG.AUTO_ACCEPT.enabled then in_trade = false return end
        local apps = ui()
        local app = apps and apps.TradeApp
        if not app then return end -- UI may be loading; don't infer completion.
        if app ~= last_app then
            last_app = app
            reset_trade()
        end
        local state = app:_get_local_trade_state()
        if not state then
            if last_stage == "confirmation" and completing then
                trade_count = trade_count + 1
                last_items = pending_received
                webhook(pending_received, pending_given, pending_partner)
                activity()
            end
            reset_trade()
            return
        end
        in_trade = true
        activity()
        local stage = state.current_stage
        if stage ~= last_stage then last_stage, last_fire = stage, 0 end
        if stage == "confirmation" then
            local mine, partner = app:_get_my_offer(), app:_get_partner_offer()
            if mine and partner then
                -- Keep independent item snapshots before the game's tables are cleared.
                pending_received, pending_given = snapshot(partner.items), snapshot(mine.items)
                local other = (state.sender == LP) and state.recipient or state.sender
                pending_partner = typeof(other) == "Instance" and other.Name or nil
                if mine.confirmed and partner.confirmed then completing = true end
            end
        end
        if os.clock() - last_fire < CONFIG.AUTO_ACCEPT.refire_every then return end
        last_fire = os.clock()
        if stage == "negotiation" then app:_on_accept_pressed()
        elseif stage == "confirmation" then app:_on_confirm_pressed() end
    end
    local file = LP.Name .. "_winteraddons.json"
    local last_write = 0
    local function write_status()
        local cfg = CONFIG.WINTERHUB
        if not cfg.enabled or os.clock() - last_write < cfg.heartbeat then return end
        last_write = os.clock()
        local status = (not in_trade and os.clock() - last_activity > cfg.idle_hop_seconds) and "completed" or "active"
        local counts, order = {}, {}
        for _, item in ipairs(last_items or {}) do
            local name = label(item)
            if not counts[name] then order[#order + 1] = name end
            counts[name] = (counts[name] or 0) + 1
        end
        local items = {}
        for _, name in ipairs(order) do items[#items + 1] = { name = name, qty = counts[name] } end
        writefile(file, HttpService:JSONEncode({ status = status, ts = os.time(), count = trade_count, items = items }))
    end
    local settings_done = false
    if not CONFIG.AUTO_ACCEPT.enabled and not CONFIG.WINTERHUB.enabled then
        force_settings()
        return
    end
    while true do
        local ok, err = pcall(function()
            if CONFIG.AUTO_ACCEPT.enabled and not hook_ready() then install_hook() end
            if CONFIG.AUTO_ACCEPT.enabled then answer_open_dialog() end
            if not settings_done and (not CONFIG.AUTO_ACCEPT.enabled or hook_ready()) then
                settings_done = force_settings()
            end
            step_trade()
            write_status()
        end)
        if not ok then log("loop error:", err) end
        task.wait(math.max(0.1, tonumber(CONFIG.AUTO_ACCEPT.poll) or 0.4))
    end
end
local ok, err = xpcall(run, debug.traceback)
release()
if not ok then warn("[autotrade] stopped: " .. tostring(err)) end
