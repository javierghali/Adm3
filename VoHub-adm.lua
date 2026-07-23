getgenv().VO_CONFIG = {
    -- === HUB / AUTH ===
    HubKey = "87AhyIiurMPokrVSVNnfBaIbcnwQqw8QKTlEWXXssWw",
    DeviceName = "Test",

    -- === MAIN FARM (choose one mode) ===
    PotFarm = true,
    EggFarm = false,
    PetFarm = false, -- Third mode: farm pets from PetFarmList in order (natural task-aging)
    KeepEggFarm = false, -- If true, will keep trying to hatch eggs even when no bucks
    KeepPetFarm = false, -- If true, will switch back when PetFarmList targets appear
    EggName = {}, -- Ganti "Egg Name" dengan nama telur asli
    PetFarmList = {}, -- Ordered pet names: age all non-FG of first name, then second, etc.
    PrioritizePet = "Tealwood Monster",

    -- === EVENT ===
    PrioritizeCraft = "Tealwood Monster Bait", -- "Rainbow Trout" | "Tealwood Monster Bait" | nil (auto)
    Craft = false, -- If false, collect karps only — skip purchases
    AutoSellFish = false, -- Sell all karps each pass
    BuyIrishSetter = false,
    AutoSkydive = false,
    AutoStormSkydive = false,

    -- === PET PEN ===
    PetPen = true,
    CustomPenEggs = {"Garden Egg"},
    CustomPenPets = {"Tealwood Monster"},
    PrioritizePetPenTypes = {"Neon"}, -- "Egg", "Normal", "Neon" (empty = all)

    -- === PET RELEASER ===
    PetReleaser = false,
    ReleasePets = {},
    ExcludeReleasePets = {},
    ReleaseTypes = {},
    ReleaseRarities = {},
    ExcludeRarities = {},

    -- === AGE PETS ===
    AgePets = false,
    AgePetsNames = {},
    AgePetsTypes = {"Normal"}, -- "Normal", "Neon", "ALL"

    -- === AUTO FUSE ===
    AutoFuse = true,
    AutoFuseBlacklist = {},

    -- === BUY PETS ===
    BuyPets = false,
    BuyPetName = {},

    -- === BOXES ===
    BuyBoxes = false,
    BoxName = "",
    OpenBoxes = false,

    -- === LURE ===
    BaitName = "Ice Soup Bait",

    -- === AUTO TRADE ===
    AutoTrade = true,
    ReceiverUsernames = {"Exauddd7","Exauddd4","Exauddd","Exauddd2","Exauddd3","Exauddd5","Exauddd6","Exauddd8","Exauddd9"},
    TradeItemList = {
        pets = {}, -- Dikosongkan jika tidak ada pet spesifik
        toys = {"Paint Sealer"},
    },
    TradePetType = {"ALL"},

    -- === CASH TRANSFER ===
    CashTransfer = false,
    TransferMethods = {"mannequin"},
    TransferAccount = "",

    -- === DISCORD WEBHOOK ===
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookPets = {},

    ExtraOpti = true
}

loadstring(game:HttpGet("https://raw.githubusercontent.com/voltrex2/VoHub/refs/heads/main/FARM"))()
