--[[=====================================================================adm_autotrade.lua  -  FULL FIXED + STABLE=======================================================================]]

local CONFIG = {MASTER_ENABLED = true,

FORCE_SETTINGS = {
    enabled = true,
    also_force_giving = true,
},

AUTO_ACCEPT = {
    enabled = true,
    poll = 0.4,
    refire_every = 1.0,
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

DEBUG = false,

}

local function log(...)if CONFIG.DEBUG thenprint("[autotrade]", ...)endend

if not CONFIG.MASTER_ENABLED then return end

local Players = game("Players")local LocalPlayer = Players.LocalPlayer

-- ANTI AFKpcall(function()local VirtualUser = game("VirtualUser")LocalPlayer.Idled(function()VirtualUser()VirtualUser(Vector2.new())end)end)

-- SINGLETONlocal _guard_key = "_adm_autotrade" .. tostring(LocalPlayer.UserId)if getgenv thenif getgenv()[_guard_key] then return endgetgenv()[_guard_key] = trueend

local Fsys = require(game.ReplicatedStorage("Fsys"))local load = Fsys.load

local UIManagerpcall(function()UIManager = load("UIManager")end)

-- SAFE ACCESSlocal function safe_get_apps()if not UIManager then return nil endif not UIManager.apps then return nil endreturn UIManager.appsend

-- PATCH TRADE APPlocal function patch_trade_app(app)if not app or app.__patched then return end

app._confirm_player_if_suspicious = function() return true end
app._evaluate_trade_fairness = function() end
app.show_scam_warning = function() end

app.__patched = true

end

-- GET TRADE APP (FIXED)local app_cache = nillocal function get_trade_app()if app_cache then return app_cache end

local ok, app = pcall(function()
    return UIManager.apps.TradeApp
end)

if ok and app then
    app_cache = app
    patch_trade_app(app)
    return app
end

return nil

end

-- HOOK READYlocal function hook_ready()local apps = safe_get_apps()if not apps then return false end

local d = apps.DialogApp
return d ~= nil and d.__autotrade_hooked == true

end

-- INSTALL HOOKlocal function install_accept_hook()local apps = safe_get_apps()if not apps then return false end

local DialogApp = apps.DialogApp
if not DialogApp then return false end

if not DialogApp.__autotrade_hooked then
    local cls = getmetatable(DialogApp)
    cls = cls and cls.__index

    if cls and cls.dialog then
        local orig = cls.dialog
        cls.dialog = function(self, opts)
            if opts and opts.handle == "trade_request" then
                log("auto accept trade")
                return "Accept"
            end
            return orig(self, opts)
        end
        DialogApp.__autotrade_hooked = true
    end
end

return DialogApp.__autotrade_hooked

end

-- TRADE DRIVERlocal last_stage = nillocal last_fire = 0

local function step_trade()if not CONFIG.AUTO_ACCEPT.enabled then return end

local app = get_trade_app()
if not app then
    last_stage = nil
    return
end

local state = app:_get_local_trade_state()
if not state then
    last_stage = nil
    return
end

local stage = state.current_stage

if stage ~= last_stage then
    log("stage:", stage)
    last_stage = stage
    last_fire = 0
end

if os.clock() - last_fire < CONFIG.AUTO_ACCEPT.refire_every then return end
last_fire = os.clock()

if stage == "negotiation" then
    pcall(function()
        app:_on_accept_pressed()
    end)
elseif stage == "confirmation" then
    pcall(function()
        app:_on_confirm_pressed()
    end)
end

end

-- INIT FAST HOOKlocal t0 = os.clock()repeatinstall_accept_hook()if hook_ready() then break endtask.wait()until os.clock() - t0 > 10

-- MAIN LOOPwhile true doif not hook_ready() theninstall_accept_hook()end

local ok, err = pcall(step_trade)
if not ok then
    log("error:", err)
end

task.wait(CONFIG.AUTO_ACCEPT.poll)

end
