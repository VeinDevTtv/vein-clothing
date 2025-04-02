# Vein Clothing - Advanced Item-Based Clothing System for FiveM

A comprehensive clothing system for FiveM (QB-Core) that implements a realistic, immersive approach to clothing with wear and tear, multiple stores, trading, and a modern React-based UI.

## Features

### Core Features
- **Item-Based Clothing System**: All clothing exists as actual inventory items
- **Multi-Store Support**: Different stores with unique inventories and pricing
- **Modern React UI**: Clean, intuitive interface for shopping and managing outfits
- **Clothing Condition System**: Items degrade over time and need maintenance

### Enhanced Experience
- **Outfit System**: Save, load, name, and set default outfits
- **Laundromat & Tailor**: Clean dirty clothes and repair damaged items
- **Wishlist System**: Mark items to remember for future purchase
- **Rarity System**: Common to exclusive items with appropriate stock levels
- **Dynamic Stock**: Stores restock based on item rarity and demand

### Advanced Features
- **In-game Preview**: Preview items with 3D camera before buying
- **Player-to-Player Trading**: Give or sell clothing to other players
- **Condition Degradation**: Items worn frequently will degrade faster
- **Multi-Language Support**: Easily add new language translations
- **Comprehensive API**: Extensive exports for integration with other scripts

## File Structure

```
clothing-system/
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
├── client.lua         # Backward compatibility wrapper
├── server.lua         # Backward compatibility wrapper
├── config.lua         # Configuration options
├── fxmanifest.lua     # Resource manifest
└── README.md          # Documentation
```

## Installation

1. Extract the resource to your server's resources folder
2. Import the provided SQL file into your database
3. Add `ensure clothing-system` to your server.cfg
4. Configure the `config.lua` file to match your server's needs
5. Start or restart your server

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
    label = 'Blue Jeans',
    weight = 400,
    stack = false,
    close = true,
    description = 'Classic blue jeans',
    client = {
        category = 'pants',
        component = 4,
        rarity = 'common',
        variations = {
            {drawable = 0, texture = 0},
            {drawable = 0, texture = 1}
        },
        image = 'jeans_blue'
    }
}
```

2. **Add item images to your inventory resource**:
   - Place item images in `ox_inventory/web/images/`
   - Images should be named according to the item name (e.g., `tshirt_white.png`)

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
Config.StoredDegradationMin = 0     -- Minimum degradation for stored items per check
Config.StoredDegradationMax = 1     -- Maximum degradation for stored items per check
Config.ConditionUpdateInterval = 30 -- Time in minutes between condition checks
Config.DirtyChance = 0.2            -- Chance (0-1) that an item becomes dirty when worn

-- Laundry and Repair Costs
Config.LaundryPrice = 25            -- Cost to clean each dirty item
Config.RepairPrice = 50             -- Base cost to repair each damaged item

-- Rarity configuration
Config.Rarity = {
    common = {
        maxStock = 15,
        minRestock = 3,
        maxRestock = 7,
        priceMultiplier = 1.0
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

Config.RarityRepairMultiplier = {
    common = 1.0,
    uncommon = 1.5,
    rare = 2.5,
    exclusive = 4.0,
    limited = 6.0
}

Config.RestockInterval = 180        -- Time in minutes between store restocks
Config.MaxOutfits = 10              -- Maximum number of saved outfits per player
```

## How to Use All Features

### For Players

#### Clothing Stores
1. **Finding Stores**
   - Stores are marked on the map with clothing blips
   - Different stores carry different items at varying price points

2. **Shopping for Clothes**
   - Enter any clothing store and press `E` to interact with the clerk
   - Browse items by category (tops, pants, shoes, hats, etc.)
   - Use the search function to find specific items
   - Filter by rarity or price using the UI controls

3. **Item Preview**
   - Click "Try On" on any item to see how it looks on your character
   - Use the camera controls to rotate your view (A/D keys or arrow keys)
   - Try different color variations if available
   - Press ESC to exit preview mode

4. **Purchasing Items**
   - Click "Buy" to purchase the item
   - The item will be added to your inventory
   - Purchased items can be found in your inventory for later use

#### Managing Your Wardrobe

1. **Accessing Your Wardrobe**
   - Use command `/outfits` to open your personal wardrobe
   - View all clothing items in your inventory by category
   - See condition status of each clothing item

2. **Wearing Items**
   - Click on any item to wear it
   - If an item is already worn, click "Remove" to take it off
   - Preview items before wearing them with the "Preview" button

3. **Creating Outfits**
   - Wear the combination of clothing you want to save
   - Click "Save Current Outfit" and give it a name
   - Saved outfits appear in the "Outfits" tab

4. **Managing Outfits**
   - Wear: Click an outfit to wear all items in that outfit
   - Rename: Change the name of any saved outfit
   - Delete: Remove outfits you no longer want
   - Set Default: Make an outfit your default when you log in

5. **Wishlist System**
   - Heart icon: Click on the heart icon on any item to add/remove from wishlist
   - View your wishlist in the "Wishlist" tab
   - Easily track items you want to purchase later

#### Clothing Maintenance

1. **Understanding Condition**
   - All clothing degrades over time, especially when worn
   - Condition levels: Excellent (76-100%), Good (51-75%), Poor (26-50%), Terrible (0-25%)
   - Items can become dirty through regular use

2. **Washing Clothes**
   - Dirty clothes affect your character's appearance
   - Visit any laundromat (marked on the map)
   - Press `E` to interact with the washing machines
   - Select dirty items to wash and pay the fee

3. **Repairing Damaged Clothes**
   - Severely damaged clothes provide fewer benefits and look worn
   - Visit any tailor shop (marked on the map)
   - Press `E` to interact with the tailor
   - Select damaged items to repair and pay the fee (higher rarity = higher cost)

#### Player Interaction

1. **Trading Items**
   - Stand near another player
   - Open your inventory and select the clothing item
   - Choose "Trade" and select the nearby player
   - They will receive a notification to accept or decline

2. **Selling Items**
   - Stand near another player
   - Open your inventory and select the clothing item
   - Choose "Sell" and set your price
   - Select the nearby player
   - They will receive a purchase offer to accept or decline

### For Administrators

#### Adding New Clothing Items

1. Add the item definition to your inventory system (as shown in setup)
2. Make sure to include all required client parameters:
   - `category`: The clothing category (tops, pants, etc.)
   - `component`: The GTA component ID for the clothing
   - `rarity`: The rarity level (affects price and stock)
   - `variations`: Array of drawable/texture combinations

3. Add the item to a store's inventory in the config

#### Restocking Stores Manually

1. Use the admin command `/restockclothing` to force a restock of all stores
2. Alternatively, use the export in a script:
   ```lua
   exports['clothing-system']:restockStore('storeName')
   ```

#### Giving Items to Players

Use the admin command:
```
/giveclothing [playerID] [itemName]
```

## API Reference

### Exports

#### Client Exports
```lua
-- Open the wardrobe UI
exports['clothing-system']:openWardrobe()

-- Wear a saved outfit
exports['clothing-system']:wearOutfit(outfitId)

-- Preview a clothing item
exports['clothing-system']:previewClothing(itemName, variation)

-- Reset player appearance
exports['clothing-system']:resetAppearance()

-- Get all currently worn items
exports['clothing-system']:getWornItems()

-- Check if an item is currently worn
exports['clothing-system']:isItemWorn(itemName)
```

#### Server Exports
```lua
-- Add a clothing item to a player
exports['clothing-system']:addClothingItem(playerId, itemName)

-- Remove a clothing item from a player
exports['clothing-system']:removeClothingItem(playerId, itemName)

-- Get all player's saved outfits
exports['clothing-system']:getPlayerOutfits(playerId)

-- Add item to a store's inventory
exports['clothing-system']:addShopItem(storeType, itemName, amount)

-- Remove item from a store's inventory
exports['clothing-system']:removeShopItem(storeType, itemName, amount)

-- Force restock a store
exports['clothing-system']:restockStore(storeType)
```

## Commands

- `/outfits` - Open your wardrobe
- `/try [itemName]` - Preview a clothing item you own
- `/washclothes` - Open the laundromat interface when near one
- `/repairclothes` - Open the tailor interface when near one

## Database Structure

The system uses the following database tables:
- `player_outfits` - Stores saved outfits
- `player_wishlist` - Stores wishlisted items
- `player_clothing_condition` - Tracks condition and wear history
- `clothing_stores` - Stores inventory data (optional if using live stock system)

## Dependencies

- QB-Core Framework
- oxmysql
- ox_inventory (optional but recommended)

## Credits

- Special thanks to the QB-Core & ox_inventory teams
- All icons and UI components created specifically for this resource

## Support

For support, please join our Discord at [discord.gg/vein-clothing](#)

## License

This resource is protected under proprietary license. You may not redistribute, share, or resell this resource without explicit permission. 