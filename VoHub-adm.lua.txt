getgenv().VO_CONFIG = {
    -- === HUB / AUTH ===
    HubKey = "ztOZVe47zX7dsa7JJKpxWYLg7NThkueue96KcFuPn1s",
    DeviceName = "Test",

    -- === MAIN FARM (choose one mode) ===
    PotFarm = true,
    EggFarm = false,
    PetFarm = false, -- Third mode: farm pets from PetFarmList in order (natural task-aging)
    KeepEggFarm = false, -- If true, will keep trying to hatch eggs even when no bucks
    KeepPetFarm = false, -- If true, will switch back when PetFarmList targets appear
    EggName = {"Egg Name"},  -- Priority order: first egg tried, then second, etc.
    PetFarmList = {}, -- Ordered pet names: age all non-FG of first name, then second, etc.; fallback if none available
    PrioritizePet = "2D Kitty",

    -- === EVENT ===
    PrioritizeCraft = "Tealwood Monster Bait",  -- "Rainbow Trout" | "Tealwood Monster Bait" | nil (auto). AutoFish always runs.
    Craft = false,             -- If false, collect karps only — skip purchases (Tealwood bait / Rainbow Trout)
    AutoSellFish = false,     -- Sell all karps each pass; disables tealwood/rainbow purchases
    BuyIrishSetter = false,
    AutoSkydive = false,      -- [RENDERS MAIN MAP] Complete Skydive Minigame
    AutoStormSkydive = false, -- [DOESNT RENDER MAIN MAP] Complete storm challenge + buy all Storm Condors

    -- === PET PEN ===
    PetPen = true,
    CustomPenEggs = {"Egg Name"},
    CustomPenPets = {"River Otter"},
    PrioritizePetPenTypes = {"Neon"},  -- "Egg", "Normal", "Neon" (empty = all)

    -- === PET RELEASER ===
    PetReleaser = false,
    ReleasePets = {},       -- Whitelist: names to release (empty = all)
    ExcludeReleasePets = {}, -- Blacklist: base names or prefixed like ReleasePets ("Neon Dog", "Normal Cat", "Mega FG X")
    ReleaseTypes = {},      -- "Mega", "Neon", "Normal" (empty = all)
    ReleaseRarities = {},   -- If ReleasePets non-empty: only used for pets NOT named in ReleasePets. If ReleasePets empty: filters all candidates.
    ExcludeRarities = {},   -- Blacklist rarities (pets on ReleasePets by name bypass this)

    -- === AGE PETS ===
    AgePets = false,
    AgePetsNames = {},
    AgePetsTypes = {"Normal"},  -- "Normal", "Neon", "ALL"

    -- === AUTO FUSE ===
    AutoFuse = true,
    AutoFuseBlacklist = {}, -- Pet names to never include in neon/mega fusion

    -- === BUY PETS ===
    BuyPets = false,
    BuyPetName = {"Pet Name", "Pet Name 2"},  -- Loops in order, buys all of first pet then moves to next

    -- === BOXES ===
    BuyBoxes = false,
    BoxName = "Box Name",   -- Name of the box to buy/open
    OpenBoxes = false,

    -- === LURE ===
    BaitName = "Ice Soup Bait",

    -- === AUTO TRADE ===
    AutoTrade = false,
    ReceiverUsernames = {},
    TradeItemList = {
         pets = {"Dog","Neon Cat"}
    }, -- Per category: { pets = {"Dog","Neon Cat"}, food = {}, toys = {}, ... } — use "ALL" in a category to allow that whole category (pets still gated by TradePetType for bare names)
    TradePetType = {"ALL"},       -- Only applies to pets: "ALL", "Mega", "Neon", "Regular", "Neon_FG", "Regular_FG" — not used for food/toys/etc.; inline prefixes on pet strings (e.g. "Mega Dog") bypass this

    -- === CASH TRANSFER ===
    CashTransfer = false,
    TransferMethods = {"mannequin"},  -- Current Methods: "mannequin"
    TransferAccount = "",

    -- === DISCORD WEBHOOK ===
    WebhookEnabled = false,
    WebhookURL = "",
    WebhookPets = {},  -- Pet names to send (empty = all)

    ExtraOpti = true
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/voltrex2/VoHub/refs/heads/main/FARM"))()
