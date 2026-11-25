-- adm_autotrade_join_safe.lua
-- ZekeHub Utility configuration: incoming trades only.
-- Provide your licensed scriptkey privately before loading this file.
-- No custom trade hooks or WinterHub completion signals.
local env = getgenv()
if type(env.scriptkey) ~= "string" or env.scriptkey == "" then
    warn("[ADM/ZEKE] Missing private scriptkey; Utility not started")
    return
end

env.Utility = {
    AutoPotion = {
        Enabled = false,
        UseAllOnAll = false,
        SelectedPets = {},
    },
    AutoNeon = {
        Enabled = false,
        MakeMega = false,
        SelectedPets = {},
    },
    AutoRecycle = {
        Enabled = false,
        Rarities = {},
        Versions = {"regular"},
        Ages = {},
        Keep = 0,
        Excluded = {},
    },
    AutoTrade = {
        Enabled = false,
        Debug = true,
        AutoAcceptTrades = true,
        AutoLeaveAfterTrades = false,
        LeaveDelay = 5,
        Usernames = {},
        TradeMode = "specific",
        Categories = {},
        Items = {},
        ItemCounts = {},
        BlacklistedRarities = {},
        GlobalPetFilter = {Versions = {}, Ages = {}},
        PetFilters = {},
        Filters = {Kind = "ALL", Type = "ALL", Rarity = "ALL", Search = ""},
    },
    AutoOpen = {Enabled = false, Items = {}, OpenDelay = 1},
    Shop = {Enabled = false, Items = {}, BuyQuantity = 1, BuyDelay = 1},
    AccountManager = {
        Enabled = false,
        Tool = "none",
        FarmSync = {
            Action = "completed",
            FromFolderId = "",
            ToFolderId = "",
            ChangeWithoutReplacement = false,
            ConfigId = nil,
            ApiKey = "",
        },
        FarmerV5 = {ApiKey = "", Action = "swap", Option = 1},
    },
    Settings = {
        AutoShowUI = true,
        Theme = "Dark",
        ToggleKey = "RightShift",
        UIScale = "auto",
    },
}

print("[ADM/ZEKE] Loading Utility configuration")
local ok, err = pcall(function()
    local source = game:HttpGet("https://zekehub.com/scripts/AdoptMe/Utility.lua")
    local run, compile_error = loadstring(source)
    if not run then error(compile_error or "Utility compile failed") end
    run()
end)
if not ok then
    warn("[ADM/ZEKE] Utility failed:", err)
else
    print("[ADM/ZEKE] Utility loader returned; check the Utility UI")
end
