getgenv().Config = {
    Dashboard = {
        Enabled = true, -- Send stats to dashboard
        SyncConfig = true, -- Accept config pushes from dashboard
        GroupName = "104", -- Group name for organizing accounts on dashboard
    },

    BabyFarm = true, -- Enable baby farming
    AutoCertificate = false, -- Auto use Pet Handler Pro Certificate when < 30 days remaining

    PetFarm = {
        Enabled = true, -- Enable pet farming
        FarmEggs = false, -- Use eggs instead of pets
        BuyEggs = false, -- Auto buy eggs if none available
        EggTypes = {"any"}, -- {} = any egg, or {"cracked_egg", "royal_egg"}
        BuyEggType = "any", -- Egg type to buy
        MaxPets = 1, -- Max pets equipped (2 requires gamepass)
        FarmUntilFullGrown = false, -- Prioritize non-full-grown pets
        PrioritizeFriendship = true, -- Prioritize higher friendship pets
        SelectiveFarm = false, -- Only farm selected pets
        SelectedPetTypes = {}, -- e.g. {"dog", "cat"}
    },

    AutoTrade = {
        Enabled = false,
        AutoAcceptTrades = false,
        AutoLeaveAfterTrades = false,
        Usernames = {"lanapiastaga"}, -- Target players
        TradeMode = "specific", -- "all" or "specific"
        Categories = {"pets"}, -- Categories to trade
        Items = {}, -- Specific item IDs
        ItemCounts = {}, -- Max count per item

        GlobalPetFilter = {
            Versions = {}, -- {"regular", "neon", "mega"}
            Ages = {}, -- {1-6}
        },

        PetFilters = {}, -- Override per pet
    },

    AutoNeon = {
        Enabled = false,
        MakeMega = false,
        NeonAll = true,
        SelectedPets = {},
        MaxPerType = {},
    },

    AutoPotion = {
        Enabled = false,
        SelectedPets = {"lny_2026_fire_foal"},
        PotionVersionFilter = {},
    },

    AutoBuy = {
        Enabled = false,
        SelectedItems = {},
        BuyAmounts = {},
    },

    AutoPay = {
        Enabled = false,
        TargetPlayer = {}, -- Username list
        Methods = {}, -- "register", "mannequin", "hotdog"
    },

    AutoOpen = {
        Enabled = false,
        Items = {},
    },

    AutoRecycle = {
        Enabled = false,

        RarityFilter = {
            -- Example:
            -- common = {"regular", "neon", "mega"},
            -- legendary = {"mega"},
        },

        AgeFilter = {},
        ExcludedPets = {},
    },

    IdleProgression = {
        Enabled = false,
        SelectedPets = {"cracked_egg"},
        ExcludedPets = {},
        PriorityOrder = {},
        PenVersionFilter = {},
    },

    AccountManager = {
        Enabled = false,
        Tool = "", -- "yummy", "farmsync", "kick"

        Yummy = {
            Action = "completed",
            Reason = "Done",
        },

        FarmSync = {
            Action = "completed",
            FromFolderId = "",
            ToFolderId = "",
            ChangeWithoutReplacement = false,
            ConfigId = nil,
            ApiKey = "",
        },

        Triggers = {
            AfterTradeComplete = false,
            MinBucks = 0,
            MinPotions = 0,
        },
    },

    Settings = {
        AutoShowUI = false,
        ShowOverlay = true, -- Fixed typo (was broken text)
        ReduceGraphics = true,
        FPSCap = 3,
        LureId = "ice_dimension_2025_ice_soup_bait",
        TradeInvites = "Everyone",
    },

    Webhook = {
        Enabled = false,
        URL = "https://discord.com/api/",

        PetUnlock = {
            Enabled = false,
            URL = "https://discord.com/api/",
            FilterRarities = {"legendary"},
        },
    },

    TaskExclusion = {
        Enabled = false,
        ExcludedTasks = {},
    },
}

getgenv().scriptkey = "tESFzqaTyJmoRicjUHcIFflqTfGIxAzv"

loadstring(game:HttpGet("https://zekehub.com/scripts/AdoptMe/MassFarm.lua"))()
