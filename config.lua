-- config.lua
Config = {}

--[[
    GENERAL SETTINGS
    These settings control the basic functionality of the clothing system
]]
Config.Debug = false -- Enable debug mode for development
Config.UseOxLib = true -- Enable ox_lib integration for enhanced features
Config.UseOxInventory = true -- Set to true if using ox_inventory, false for QB-Core inventory

--[[
    INVENTORY INTEGRATION
    Configure how the script interacts with your inventory system
]]
Config.Inventory = {
    -- Set to true if using ox_inventory, false for QB-Core inventory
    UseOxInventory = true,
    
    -- The name of your inventory resource
    ResourceName = 'ox_inventory',
    
    -- The name of your core framework
    CoreName = 'qb-core',
    
    -- The name of your database resource
    DatabaseName = 'oxmysql'
}

--[[
    CLOTHING STORES
    Configure all clothing stores in your server
    Each store can have multiple locations and unique inventories
]]
Config.Stores = {
    ['suburban'] = {
        label = "Suburban", -- Display name of the store
        blip = {
            sprite = 73, -- Blip sprite ID
            color = 47, -- Blip color
            scale = 0.7, -- Blip size
            label = "Suburban Clothing" -- Blip label
        },
        clerk = {
            model = "a_f_y_hipster_02", -- Ped model for the store clerk
            scenario = "WORLD_HUMAN_STAND_IMPATIENT" -- Ped animation
        },
        priceMultiplier = 1.0, -- Price multiplier for this store (1.0 = normal price)
        locations = { -- Store locations (vector4: x, y, z, heading)
            vector4(127.02, -223.69, 54.56, 68.0),
            vector4(613.08, 2761.72, 42.09, 275.0)
        },
        inventory = { -- List of items available in this store
            "tshirt_white", "tshirt_black", "jeans_blue", "jeans_black",
            "sneakers_white", "cap_black", "hoodie_gray"
        }
    },
    ['ponsonbys'] = {
        label = "Ponsonbys",
        blip = {
            sprite = 73,
            color = 4,
            scale = 0.7,
            label = "Ponsonbys"
        },
        clerk = {
            model = "s_m_m_tailor_01",
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        },
        priceMultiplier = 2.0, -- Higher prices for luxury store
        locations = {
            vector4(-708.72, -152.13, 37.42, 120.0),
            vector4(-165.12, -302.94, 39.73, 250.0)
        },
        inventory = {
            "suit_black", "suit_navy", "dress_shoes_black", 
            "dress_shoes_brown", "luxury_watch", "designer_glasses"
        }
    }
}

--[[
    LAUNDROMAT LOCATIONS
    Configure locations where players can wash their clothes
]]
Config.Laundromats = {
    {
        coords = vector4(1136.0, -992.0, 46.0, 96.0),
        blip = {
            sprite = 318,
            color = 3,
            scale = 0.7,
            label = "Laundromat"
        }
    },
    {
        coords = vector4(2561.0, 382.0, 108.0, 267.0),
        blip = {
            sprite = 318,
            color = 3,
            scale = 0.7,
            label = "Laundromat"
        }
    }
}

--[[
    TAILOR LOCATIONS
    Configure locations where players can repair their clothes
]]
Config.Tailors = {
    {
        coords = vector4(614.0, 2762.0, 42.0, 277.0),
        blip = {
            sprite = 366,
            color = 4,
            scale = 0.7,
            label = "Tailor"
        }
    },
    {
        coords = vector4(1196.0, 2710.0, 38.0, 178.0),
        blip = {
            sprite = 366,
            color = 4,
            scale = 0.7,
            label = "Tailor"
        }
    }
}

--[[
    CLOTHING CONDITION SYSTEM
    Configure how clothing items degrade over time
]]
Config.Condition = {
    -- Base degradation rates
    WornDegradationMin = 1, -- Minimum degradation when worn
    WornDegradationMax = 3, -- Maximum degradation when worn
    StoredDegradationMin = 0, -- Minimum degradation when stored
    StoredDegradationMax = 1, -- Maximum degradation when stored
    
    -- Degradation check intervals (in milliseconds)
    DegradationInterval = 300000, -- 5 minutes
    
    -- Condition thresholds
    DirtyThreshold = 50, -- Items become dirty below this condition
    DamagedThreshold = 30, -- Items become damaged below this condition
    
    -- Repair and cleaning costs
    LaundryPrice = 25, -- Cost to clean each dirty item
    RepairPrice = 50, -- Base cost to repair each damaged item
}

--[[
    RARITY SYSTEM
    Configure how different rarity tiers affect items
]]
Config.Rarity = {
    common = {
        maxStock = 15, -- Maximum stock level
        minRestock = 3, -- Minimum items to restock
        maxRestock = 7, -- Maximum items to restock
        priceMultiplier = 1.0 -- Price multiplier
    },
    uncommon = {
        maxStock = 10,
        minRestock = 2,
        maxRestock = 5,
        priceMultiplier = 1.5
    },
    rare = {
        maxStock = 5,
        minRestock = 1,
        maxRestock = 3,
        priceMultiplier = 2.5
    },
    exclusive = {
        maxStock = 3,
        minRestock = 0,
        maxRestock = 2,
        priceMultiplier = 5.0
    },
    limited = {
        maxStock = 1,
        minRestock = 0,
        maxRestock = 1,
        priceMultiplier = 10.0
    }
}

--[[
    REPAIR COST MULTIPLIERS
    Configure how rarity affects repair costs
]]
Config.RarityRepairMultiplier = {
    common = 1.0,
    uncommon = 1.5,
    rare = 2.5,
    exclusive = 4.0,
    limited = 6.0
}

--[[
    STORE RESTOCKING
    Configure how stores restock their inventory
]]
Config.Restocking = {
    Interval = 180, -- Time in minutes between restocks
    MinItems = 1, -- Minimum items to restock
    MaxItems = 5, -- Maximum items to restock
    RestockAll = false -- Set to true to restock all items at once
}

--[[
    OUTFIT SYSTEM
    Configure the outfit saving and management system
]]
Config.Outfits = {
    MaxOutfits = 10, -- Maximum number of saved outfits per player
    SaveOnDisconnect = true, -- Save current outfit when player disconnects
    LoadOnConnect = true, -- Load saved outfit when player connects
    DefaultOutfit = true -- Allow setting a default outfit
}

--[[
    PLAYER INTERACTION
    Configure player-to-player trading and selling
]]
Config.PlayerInteraction = {
    MaxDistance = 3.0, -- Maximum distance for player interactions
    TradeTimeout = 30, -- Time in seconds before trade offer expires
    SellTimeout = 30, -- Time in seconds before sell offer expires
    RequireConsent = true -- Require consent for trades/sales
}

--[[
    UI SETTINGS
    Configure the user interface
]]
Config.UI = {
    Theme = 'dark', -- UI theme (dark/light)
    Language = 'en', -- Default language
    EnableAnimations = true, -- Enable UI animations
    EnableSounds = true, -- Enable UI sounds
    EnableNotifications = true -- Enable in-game notifications
}

--[[
    COMMANDS
    Configure available commands
]]
Config.Commands = {
    Outfits = 'outfits', -- Command to open outfit management
    Wardrobe = 'wardrobe', -- Command to open wardrobe
    Clothes = 'clothes', -- Command to open clothing store
    Laundry = 'laundry', -- Command to open laundromat
    Tailor = 'tailor' -- Command to open tailor shop
}

--[[
    PERMISSIONS
    Configure permission levels for different features
]]
Config.Permissions = {
    AdminGroups = { -- Groups that have admin access
        'admin',
        'superadmin'
    },
    StaffGroups = { -- Groups that have staff access
        'mod',
        'staff'
    },
    Features = { -- Feature-specific permissions
        ['restock'] = {'admin', 'superadmin'}, -- Who can restock stores
        ['give'] = {'admin', 'superadmin'}, -- Who can give items
        ['delete'] = {'admin', 'superadmin'} -- Who can delete outfits
    }
}

--[[
    NOTIFICATIONS
    Configure notification settings
]]
Config.Notifications = {
    Type = 'qb', -- Notification type (qb/ox_lib)
    Position = 'top-right', -- Notification position
    Duration = 5000, -- Duration in milliseconds
    Sound = true -- Enable notification sounds
}

--[[
    DEBUG SETTINGS
    Configure debug features
]]
Config.Debug = {
    Enable = false, -- Enable debug mode
    LogLevel = 'info', -- Log level (error/warn/info/debug)
    LogToFile = false, -- Log to file
    LogToConsole = true -- Log to console
}
