 getgenv().Config = {
        Dashboard = {
            Enabled = true; -- Enable dashboard features (live stats, etc)
            SyncConfig = true; -- Allow dashboard to update config in real-time
            GroupName = "zeke"; -- Group name for organising bots (https://zekehub.com/dashboard/mm2)
        };
        Farming = {
            Enabled = false; -- Farm currencies (Coins, etc)
            ResetOnBagFull = false; -- Reset character when any bag fills up (instead of teleporting to lobby)
        };
        Webhook = {
            Enabled = false,
            URL = "",
            Post = {},           -- rarities to post; empty = all
            Ping = {"Godly"},    -- @everyone on these
        },
        AutoBuy = {
            Enabled = false; -- True or false
            PriorityCurrencies = {"Coins", "Gems"}; -- Try in order, fallback = any active currency you own
            Items = {"KnifeBox5"}; -- Item names it will buy in order of priority (e.g. "KnifeBox5", "KnifeBox4", "KnifeBox3", "KnifeBox2", "KnifeBox1")
        };
       AutoInventory = {
            Enabled = false,
            Salvage = {
                Rarities = {"Common", "Uncommon"}, -- weapons of these rarities get salvaged for shards
                Items = {}, -- specific weapon IDs to always salvage regardless of rarity (e.g. {"Lugar", "Saw"})
                Exclude = {}, -- weapon IDs to never salvage even if rarity matches (e.g. {"Lugar"} to keep your Lugar)
            },
            Craft = {
                Recipes = {}, -- recipe IDs in priority order, tries first one first then falls down list if mats short
                -- RandomUncommonWeapon (12 CommonShards)
                -- RandomRareWeapon (12 UncommonShards)
                -- RandomLegendaryWeapon (12 RareShards)
                -- TheSeer (20 LegendaryShards)
                -- PaintedSeer (10 GodlyShards, 10 GodlyMetal)
            },
        },
        BattlePass = {
            Enabled = false,
            ClaimTiers = true,   -- claim unlocked tiers as you reach them
            BuyTiers = false,    -- spend event currency to buy tiers
            ClaimFinal = false,  -- drain repeatable final reward once pass is maxed
            BuyGifts = false,    -- convert currency into gifts + claim gift rewards (gifting events only)
        },
        AutoTrade = {
            Enabled = false, -- Enable auto trading
            AutoAcceptTrades = false, -- Accept incoming trade requests
            AutoLeaveAfterTrades = false, -- Leave game after sending all trades
            Usernames = {}, -- Players to send trades to (e.g. {"player1", "player2"})
            TradeMode = "all", -- "all" = send everything matching Categories/Rarities, "specific" = only Items list
            Items = {}, -- Item IDs when TradeMode = "specific" (e.g. {"SeerChroma", "Icebringer", "Lightbringer"})
            ItemCounts = {}, -- Max count per item matching Items order (e.g. {2, 5, 1}. {} = unlimited)
            Categories = {"Weapons"}, -- "Weapons" and/or "Pets" (only categories MM2 trade allows)
            Rarities = {}, -- Rarities to trade when TradeMode = "all" (e.g. {"Godly", "Ancient", "Unique"}. {} = all rarities)
        },
        AccountManager = {
            Enabled = false, -- Master toggle for account management
            Tool = "kick", -- "yummy", "farmsync", "farmerv5", "kick" = just kicks you from the game

            Yummy = {
                Action = "completed", -- "completed" = remove cookie/stop, "swap" = next cookie
                HaveGodly = "Godly",  -- suffix when acc has godly (Completed-Godly)
                NoGodly = "Done",     -- suffix when it doesn't (Completed-Done)
            },
            FarmSync = {
                Action = "completed", -- "completed" = move to done folder, "swap" = move and replace, "disable" = disable on FarmSync (requires ApiKey)
                ApiKey = "",          -- FarmSync API key (device key), disable only
                FromFolderId = "",    -- Fresh cookies folder ID
                HaveGodly = "",       -- Done folder ID for accs with godly
                NoGodly = "",         -- Done folder ID for everything else
                ChangeWithoutReplacement = false, -- Remove even if no replacement available
                ConfigId = nil,       -- Config for new account (nil = same config)
            },
            FarmerV5 = {
                ApiKey = "",     -- AccountOps API key
                Action = "swap", -- "swap" = fire autoswap rule, "disable" = flip enabled off
                HaveGodly = 2,   -- Autoswap rule when acc has godly
                NoGodly = 1,     -- Autoswap rule when it doesn't
            },

            EventQuestsDone = false,    -- Swap once a box has been bought and nothing more is affordable
            AfterTradeComplete = false, -- Requires AutoTrade.AutoLeaveAfterTrades
            WaitForLevel10 = {},        -- e.g. {"Godly", "Ancient"} - hold until lvl 10 so it can trade first
        },
        ServerHop = {
            Enabled = false;
            CheckWindow = 600; -- track coins earned over last 10min
            MinCoinsPerWindow = 500; -- if earned less than this in window, hop
        };
        Settings = {
            ShowOverlay = true; -- show in-game overlay with stats and info
            FPSCap = 144; -- set fps cap
        }
    };
getgenv().scriptkey="DYPATzcJsHXNuWsrcVzIXndrKyVoEGwP"
loadstring(game:HttpGet("https://zekehub.com/scripts/MM2/MassFarm.lua"))()
