# Vein Clothing - Advanced Item-Based Clothing System for FiveM

A comprehensive clothing system for FiveM (QB-Core) that implements a realistic, immersive approach to clothing with wear and tear, multiple stores, trading, and a modern React-based UI.

## Features

### Core Features
- **Item-Based Clothing System**: All clothing exists as actual inventory items
- **Multi-Store Support**: Different stores with unique inventories and pricing
- **Modern React UI**: Clean, intuitive interface for shopping and managing outfits
- **Clothing Condition System**: Items degrade over time and need maintenance
- **ox_lib Integration**: Enhanced UI and functionality through ox_lib

### Enhanced Experience
- **Outfit System**: Save, load, name, and set default outfits
- **Laundromat & Tailor**: Clean dirty clothes and repair damaged items
- **Wishlist System**: Mark items to remember for future purchase
- **Rarity System**: Common to exclusive items with appropriate stock levels
- **Dynamic Stock**: Stores restock based on item rarity and demand
- **Advanced Search**: Filter by category, rarity, price, and condition
- **Real-time Preview**: 3D preview of items before purchase

### Advanced Features
- **In-game Preview**: Preview items with 3D camera before buying
- **Player-to-Player Trading**: Give or sell clothing to other players
- **Condition Degradation**: Items worn frequently will degrade faster
- **Multi-Language Support**: Easily add new language translations
- **Comprehensive API**: Extensive exports for integration with other scripts
- **Custom Animations**: Store-specific NPC animations and scenarios
- **Dynamic Pricing**: Store-specific price multipliers and discounts

## File Structure

```
vein-clothing/
├── client/
│   ├── main.lua       # Core client functionality
│   ├── events.lua     # Event handlers
│   └── nui.lua        # NUI callback handlers
├── server/
│   ├── main.lua       # Core server functionality
│   └── events.lua     # Server-side event handlers
├── locales/
│   └── en.lua         # English translations
├── html/              # Web UI files
│   ├── index.html     # Main UI template
│   ├── css/           # Stylesheets
│   ├── js/            # JavaScript files
│   ├── fonts/         # Custom fonts
│   └── img/           # UI images
├── database/          # SQL files
├── examples/          # Example configurations
├── client.lua         # Backward compatibility wrapper
├── server.lua         # Backward compatibility wrapper
├── config.lua         # Configuration options
├── fxmanifest.lua     # Resource manifest
└── README.md          # Documentation
```

## Installation

1. Extract the resource to your server's resources folder
2. Import the provided SQL file into your database
3. Add `ensure vein-clothing` to your server.cfg
4. Configure the `config.lua` file to match your server's needs
5. Start or restart your server

## Dependencies

- QB-Core Framework
- oxmysql
- ox_lib (recommended for enhanced features)

## Detailed Setup Guide for QB-Core & ox_inventory

### 1. Database Setup

```sql
-- Run this SQL query in your database
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `outfitname` varchar(50) NOT NULL,
  `outfit` longtext NOT NULL,
  `is_default` tinyint(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
);

CREATE TABLE IF NOT EXISTS `player_wishlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`)
);

CREATE TABLE IF NOT EXISTS `player_clothing_condition` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  `condition` float NOT NULL DEFAULT 100,
  `last_worn` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen_item` (`citizenid`, `item`)
);

CREATE TABLE IF NOT EXISTS `clothing_stores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `store` varchar(50) NOT NULL,
  `item` varchar(50) NOT NULL,
  `stock` int(11) NOT NULL DEFAULT 0,
  `last_restock` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `store_item` (`store`, `item`)
);
```

### 2. ox_inventory Integration

1. **Add clothing items to ox_inventory/data/items.lua**:

```lua
-- Example items (add these to your items.lua)
['tshirt_white'] = {
    label = 'White T-Shirt',
    weight = 200,
    stack = false,
    close = true,
    description = 'A simple white t-shirt',
    client = {
        category = 'tops',
        component = 11,
        rarity = 'common',
        variations = {
            {drawable = 0, texture = 0},
            {drawable = 0, texture = 1}
        },
        image = 'tshirt_white',  -- Image file name
    }
},
['jeans_blue'] = {
    label = 'Blue Jeans',      -- Display name shown in inventory and UI
    weight = 400,              -- Item weight (affects inventory capacity)
    stack = false,             -- Whether multiple items can stack (clothing should always be false)
    close = true,              -- Whether inventory should close when item is used
    description = 'Classic blue jeans',  -- Description shown when hovering item
    client = {
        category = 'pants',    -- Clothing category (affects which body component changes)
        component = 4,         -- GTA component ID (4 = legs/pants)
        rarity = 'common',     -- Rarity tier (affects price and stock availability)
        variations = {         -- Different style/color options for this item
            {drawable = 0, texture = 0},  -- First variation (drawable = GTA model ID, texture = color/pattern) 
            {drawable = 0, texture = 1}   -- Second variation (same model, different texture)
        },
        image = 'jeans_blue'   -- Inventory image filename (without extension)
    }
}
```

2. **Add item images to your inventory resource**:
   - Place item images in `ox_inventory/web/images/`
   - Images should be named according to the item name (e.g., `tshirt_white.png`)
   - Recommended size: 100x100 pixels, PNG format with transparency

### 3. QB-Core Integration

1. **Add items to your QBCore shared items**:

```lua
-- Add to qb-core/shared/items.lua (if not using ox_inventory)
QBShared.Items = {
    -- Existing items here
    
    -- Clothing items
    ['tshirt_white'] = {
        name = 'tshirt_white',
        label = 'White T-Shirt',
        weight = 200,
        type = 'item',
        image = 'tshirt_white.png',
        unique = true,
        useable = true,
        shouldClose = true,
        combinable = nil,
        description = 'A simple white t-shirt',
        client = {
            category = 'tops',
            component = 11,
            rarity = 'common',
            variations = {
                {drawable = 0, texture = 0},
                {drawable = 0, texture = 1}
            }
        }
    },
    -- Add more clothing items as needed
}
```

### 4. Configure Store Locations

1. Edit `config.lua` to set up store locations and inventories:

```lua
Config.Stores = {
    ['suburban'] = {
        label = "Suburban",
        blip = {
            sprite = 73,
            color = 47,
            scale = 0.7
        },
        clerk = {
            model = "a_f_y_hipster_02",
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        },
        priceMultiplier = 1.0,
        locations = {
            vector4(127.02, -223.69, 54.56, 68.0),
            vector4(613.08, 2761.72, 42.09, 275.0)
        },
        inventory = {
            "tshirt_white", "tshirt_black", "jeans_blue", "jeans_black",
            "sneakers_white", "cap_black", "hoodie_gray"
        }
    },
    ['ponsonbys'] = {
        label = "Ponsonbys",
        blip = {
            sprite = 73,
            color = 4,
            scale = 0.7
        },
        clerk = {
            model = "s_m_m_tailor_01",
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        },
        priceMultiplier = 2.0,
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

Config.Laundromats = {
    vector4(1136.0, -992.0, 46.0, 96.0),
    vector4(2561.0, 382.0, 108.0, 267.0),
    vector4(-1889.0, 2163.0, 114.0, 81.0)
}

Config.Tailors = {
    vector4(614.0, 2762.0, 42.0, 277.0),
    vector4(1196.0, 2710.0, 38.0, 178.0),
    vector4(-1187.0, -768.0, 17.0, 36.0)
}
```

### 5. Configure Degradation System

```lua
-- Condition system parameters
Config.WornDegradationMin = 1       -- Minimum degradation for worn items per check
Config.WornDegradationMax = 3       -- Maximum degradation for worn items per check
Config.DegradationInterval = 300000  -- Check interval in milliseconds (5 minutes)
Config.DirtyThreshold = 50          -- Condition threshold for items becoming dirty
Config.DamagedThreshold = 30        -- Condition threshold for items becoming damaged
```

## Item Properties Reference

### Basic Item Properties
```lua
{
    label = 'Item Name',           -- Display name
    weight = 200,                  -- Weight in grams
    stack = false,                 -- Whether items can stack
    close = true,                  -- Close inventory on use
    description = 'Description',   -- Item description
    client = {
        -- Clothing-specific properties
    }
}
```

### Clothing-Specific Properties
```lua
client = {
    category = 'tops',             -- Clothing category
    component = 11,                -- GTA component ID
    rarity = 'common',             -- Rarity tier
    variations = {                 -- Style/color variations
        {drawable = 0, texture = 0},
        {drawable = 0, texture = 1}
    },
    image = 'item_name'            -- Inventory image
}
```

### GTA V Component IDs Reference
| Component | Description |
|-----------|-------------|
| 0 | Face |
| 1 | Mask |
| 2 | Hair |
| 3 | Torso |
| 4 | Legs |
| 5 | Parachute/Bag |
| 6 | Shoes |
| 7 | Accessory |
| 8 | Undershirt |
| 9 | Kevlar |
| 10 | Badge |
| 11 | Torso 2 |

### GTA V Prop IDs Reference
| Prop | Description |
|------|-------------|
| 0 | Hat |
| 1 | Glasses |
| 2 | Ear |
| 6 | Watch |
| 7 | Bracelet |

## API Reference

### Client Exports
```lua
-- Open clothing store
exports['vein-clothing']:OpenStore(storeName)

-- Open wardrobe
exports['vein-clothing']:OpenWardrobe()

-- Open laundromat
exports['vein-clothing']:OpenLaundromat()

-- Open tailor
exports['vein-clothing']:OpenTailor()

-- Get item condition
local condition = exports['vein-clothing']:GetItemCondition(itemName)

-- Set item condition
exports['vein-clothing']:SetItemCondition(itemName, condition)
```

### Server Exports
```lua
-- Get player's outfits
local outfits = exports['vein-clothing']:GetPlayerOutfits(source)

-- Save player outfit
exports['vein-clothing']:SavePlayerOutfit(source, outfitName, outfitData)

-- Delete player outfit
exports['vein-clothing']:DeletePlayerOutfit(source, outfitId)

-- Update item condition
exports['vein-clothing']:UpdateItemCondition(source, itemName, condition)
```

## Commands

- `/outfits` - Open outfit management menu
- `/wardrobe` - Open wardrobe
- `/clothes` - Open clothing store
- `/laundry` - Open laundromat
- `/tailor` - Open tailor shop

## Support

For support, feature requests, or bug reports, please visit our [GitHub Issues](https://github.com/your-repo/issues) page.

## License

This project is licensed under the MIT License - see the LICENSE file for details. 