-- config.lua
Config = {}

-- General settings
Config.Debug = false                     -- Enable debug mode for development
Config.UseTarget = true                  -- Use qb-target for interactions
Config.DefaultInteractKey = 38           -- Default key for non-target interactions (E)
Config.EnableBlips = true                -- Show clothing store blips on map
Config.StockSystem = true                -- Enable stock system for stores
Config.RestockInterval = 24              -- Hours between restocks (server restart also restocks)
Config.WardrobeCommand = 'wardrobe'      -- Command to open personal wardrobe
Config.OutfitCommand = 'outfit'          -- Command to quickly change outfits
Config.MaxOutfits = 15                   -- Maximum number of outfits per player
Config.MaxWishlistItems = 30             -- Maximum number of wishlist items per player

-- Framework checks
Config.UseOxInventory = true             -- Set to false if not using ox_inventory

-- Store configuration
Config.Stores = {
    ['suburban'] = {
        label = "Suburban",
        description = "Affordable everyday clothing",
        blip = {
            sprite = 73,
            color = 47,
            scale = 0.7
        },
        locations = {
            vector3(127.02, -223.69, 54.56),
            vector3(613.08, 2761.72, 42.09),
            vector3(-1193.13, -767.93, 17.32),
            vector3(-3172.52, 1048.13, 20.86)
        },
        inventory = {
            "tshirt_white", "tshirt_black", "tshirt_red", "tshirt_blue",
            "jeans_blue", "jeans_black", "shorts_khaki", "shorts_blue",
            "sneakers_white", "sneakers_black", "sneakers_red",
            "cap_black", "cap_red", "cap_blue",
            "hoodie_black", "hoodie_gray", "sweater_green",
            "backpack_small", "bracelet_silver"
        }
    },
    ['ponsonbys'] = {
        label = "Ponsonbys",
        description = "Luxury designer clothing",
        blip = {
            sprite = 73,
            color = 4,
            scale = 0.7
        },
        locations = {
            vector3(-708.72, -152.13, 37.42),
            vector3(-165.12, -302.94, 39.73)
        },
        inventory = {
            "suit_black", "suit_navy", "suit_gray",
            "dress_red", "dress_black", "dress_blue",
            "luxury_shoes_black", "luxury_shoes_brown",
            "designer_watch_gold", "designer_watch_silver",
            "luxury_sunglasses_black", "luxury_sunglasses_gold",
            "designer_bag", "silk_tie", "cufflinks_gold"
        }
    },
    ['binco'] = {
        label = "Binco",
        description = "Discount clothing for the budget-conscious",
        blip = {
            sprite = 73,
            color = 38,
            scale = 0.7
        },
        locations = {
            vector3(425.91, -807.34, 29.49),
            vector3(75.96, -1393.01, 29.38),
            vector3(-822.42, -1074.22, 11.33)
        },
        inventory = {
            "tshirt_basic_white", "tshirt_basic_black",
            "jeans_basic_blue", "jeans_basic_black",
            "sneakers_basic_white", "sneakers_basic_black",
            "cap_basic_black", "cap_basic_white",
            "hoodie_basic_black", "hoodie_basic_gray",
            "sunglasses_basic"
        }
    },
    ['underground'] = {
        label = "Underground Market",
        description = "Rare and exclusive clothing items",
        blip = {
            sprite = 524,
            color = 1,
            scale = 0.5
        },
        locations = {
            vector3(75.39, -1387.69, 29.38),
            vector3(427.09, -807.46, 29.49)
        },
        inventory = {
            "limited_jacket_black", "limited_sneakers_gold",
            "exclusive_watch", "rare_sunglasses",
            "exclusive_chain_gold", "exclusive_chain_diamond",
            "rare_hat_special", "exclusive_rings"
        }
    }
}

-- Clothing categories
Config.Categories = {
    "tops",
    "pants",
    "shoes",
    "hats",
    "glasses",
    "accessories",
    "bags",
    "watches",
    "jewelry"
}

-- Rarity levels with corresponding prices
Config.Rarity = {
    common = { minPrice = 50, maxPrice = 250 },
    uncommon = { minPrice = 250, maxPrice = 750 },
    rare = { minPrice = 750, maxPrice = 2000 },
    exclusive = { minPrice = 2000, maxPrice = 5000 },
    limited = { minPrice = 5000, maxPrice = 15000 }
}

-- Condition degradation settings
Config.Condition = {
    enabled = true,
    degradePerUse = 0.5,         -- How much condition is lost per use (%)
    washCost = 25,               -- Cost to wash/clean clothing
    repairCosts = {
        common = 50,
        uncommon = 100,
        rare = 250,
        exclusive = 500,
        limited = 1000
    }
}

-- Laundromat locations
Config.Laundromats = {
    vector3(1132.62, -992.63, 46.11),
    vector3(-40.77, -1749.74, 29.42),
    vector3(420.02, 3559.83, 33.24)
}

-- Tailor repair shops
Config.TailorShops = {
    vector3(614.22, 2761.72, 42.09),
    vector3(1196.77, 2709.95, 38.22),
    vector3(-1438.57, -242.28, 49.82)
}
