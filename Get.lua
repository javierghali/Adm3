
-- ZEKEHUB | TRADE LICENSE MODE
-- All farming disabled

getgenv().Config = {

    Dashboard = {
        Enabled = true,
        SyncConfig = false,
        GroupName = "vps1",
    },

    Settings = {
        AutoShowUI = true,
        ShowOverlay = false,
        ReduceGraphics = false,
        FPSCap = 0,
        LureId = "ice_dimension_2025_ice_soup_bait",
        TradeInvites = "Everyone",
    },

    BabyFarm = false,
    AutoCertificate = false,

    PetFarm = {
        Enabled = false,
        FarmEggs = false,
        BuyEggs = false,
        EggTypes = {},
        BuyEggType = "any",
        MaxPets = 1,
        FarmUntilFullGrown = false,
        PrioritizeFriendship = false,
        SelectiveFarm = false,
        SelectedPetTypes = {},
    },

    EventFarm = {
        Halloween = {
            CandyPile = false,
            StrayCat = false,
            Crypt = false,
            PigeonNest = false,
            GhostGallery = false,
            Hauntlet = false,
            Spotlight = false,
            Shoebill = false,
            WhereBear = false,
        },
    },

    TaskExclusion = {
        Enabled = false,
        ExcludedTasks = {},
    },

    PetPen = {
        Enabled = false,
        Eggs = {},
        Pets = {},
        Priority = {"egg", "neon", "regular"},
        Excluded = {},
    },

    AutoPotion = {
        Enabled = false,
        SelectedPets = {},
        PotionVersionFilter = {},
    },

    AutoNeon = {
        Enabled = false,
        MakeMega = false,
        NeonAll = false,
        SelectedPets = {},
        MaxPerType = {},
    },

    AutoRecycle = {
        Enabled = false,
        RarityFilter = {},
        Pets = {},
        Keep = {},
        Excluded = {},
    },

    AutoTrade = {
        Enabled = false,
        AutoAcceptTrades = false,
        AutoLeaveAfterTrades = false,
        Usernames = {},
        TradeMode = "all",
        Categories = {},
        Items = {},
        ItemCounts = {},
        GlobalPetFilter = {
            Versions = {},
            Ages = {},
        },
        PetFilters = {},
    },

    AutoPay = {
        Enabled = false,
        TargetPlayer = {},
        Methods = {},
    },

    AutoBuy = {
        Enabled = false,
        SelectedItems = {},
        BuyAmounts = {},
    },

    AutoOpen = {
        Enabled = false,
        Items = {},
    },

    Webhook = {
        Enabled = false,
        URL = "",
        PetUnlock = {
            Enabled = false,
            URL = "",
            FilterRarities = {},
        },
    },

    AccountManager = {
        Enabled = false,
        Tool = "",
        FarmSync = {
            Action = "completed",
            FromFolderId = "",
            ToFolderId = "",
            ChangeWithoutReplacement = false,
            ConfigId = nil,
            ApiKey = "",
        },
        FarmerV5 = {
            ApiKey = "",
            Action = "swap",
            Option = 1,
        },
        Triggers = {
            AfterTradeComplete = false,
            MinBucks = 0,
            MinPotions = 0,
        },
    },
}

-- Enter your own Mass Farm key
getgenv().scriptkey = "SrWdjOZSKnynbBCxLZHVrnuNPISdXHRP"

-- Load ZekeHub
loadstring(game:HttpGet(
    "https://zekehub.com/scripts/AdoptMe/MassFarm.lua"
))()
