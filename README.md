# Advanced Item-Based Clothing System for FiveM (QB-Core)

An immersive, realistic clothing system for FiveM built on QB-Core framework with multiple store support and a modern React UI.

![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)
![Framework](https://img.shields.io/badge/Framework-QB--Core-red.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## Features

- **Item-Based Clothing System**: Each clothing piece exists as a separate inventory item
- **Multi-Store Support**: Different stores sell different clothing items (affordable, luxury, rare, etc.)
- **Dynamic Store Inventory**: Easily configure which stores sell which items via config file
- **Modern React UI**: Sleek, responsive interface with category filtering and search
- **Clothing Variations**: Support for multiple colors/styles of the same clothing item
- **Clothing Condition System**: Items degrade over time (New, Good, Worn, Damaged, Poor)
- **Rarity System**: Common, Uncommon, Rare, Exclusive, and Limited edition clothing
- **Outfit Management**: Save, load, and wear complete outfits
- **Wishlist System**: Save items to purchase later
- **Full ox_inventory Integration**: Seamless inventory management

## Requirements

- [QB-Core Framework](https://github.com/qbcore-framework/qb-core)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [oxmysql](https://github.com/overextended/oxmysql)
- [qb-target](https://github.com/qbcore-framework/qb-target) (Optional but recommended)

## Installation

1. **Download the Resource**
   ```bash
   cd resources
   git clone https://github.com/yourusername/clothing-system [clothing-system]
   ```

2. **Import Database**
   ```bash
   mysql -u root -p < clothing-system/database/install.sql
   ```

3. **Add to Server.cfg**
   ```
   ensure oxmysql
   ensure ox_inventory
   ensure qb-target # Optional
   ensure clothing-system
   ```

4. **Configure Items in ox_inventory**
   - Add all clothing items to your `ox_inventory/data/items.lua` file
   - Example structure provided in `clothing-system/examples/items_example.lua`

## Configuration

### Store Setup

1. Edit the `config.lua` file to configure stores:

```lua
Config = {}

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
            vec3(127.02, -223.69, 54.56),
            vec3(613.08, 2761.72, 42.09),
            -- Add more locations for this store
        },
        inventory = {
            "tshirt_white", "tshirt_black", "jeans_blue",
            "sneakers_white", "cap_black"
            -- Add more items available at this store
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
            vec3(-708.72, -152.13, 37.42),
            vec3(-165.12, -302.94, 39.73),
            -- Add more locations for this store
        },
        inventory = {
            "suit_black", "dress_red", "luxury_shoes",
            "designer_watch", "luxury_sunglasses"
            -- Add more items available at this store
        }
    },
    -- Add more stores as needed
}

-- Clothing categories
Config.Categories = {
    "tops", "pants", "shoes", "hats", "glasses", "accessories"
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
    degradePerUse = 0.5, -- How much condition is lost per use
    washCost = 25,      -- Cost to wash/clean clothing
    repairCosts = {
        common = 50,
        uncommon = 100,
        rare = 250,
        exclusive = 500,
        limited = 1000
    }
}
```

### Item Setup

Each clothing item should be structured like this in your ox_inventory items:

```lua
['tshirt_white'] = {
    label = 'White T-Shirt',
    weight = 250,
    stack = false,
    close = true,
    description = 'A simple white t-shirt',
    client = {
        category = 'tops',
        variation = 0,
        drawable = 5,
        texture = 0,
        gender = 'male',
        rarity = 'common',
        condition = 100,
        component = 11, -- PED component ID
        event = 'clothing-system:client:wearItem'
    }
}
```

## Usage

### For Players

1. **Visit Clothing Stores**
   - Locate clothing stores on the map (marked with clothing blips)
   - Approach the store and press E to interact (or use target)

2. **Try On Clothing**
   - Browse available items by category
   - Click "Try On" to preview before purchasing
   - Use color variations when available

3. **Purchase Items**
   - Buy items to add them to your inventory
   - Items will be stored in ox_inventory

4. **Manage Your Wardrobe**
   - Use `/wardrobe` command to access your clothing collection
   - Create, save, and load outfits
   - Add favorite items to your wishlist

5. **Maintain Your Clothing**
   - Visit laundromats to wash dirty clothes
   - Repair damaged items at tailor shops

### For Server Owners

1. **Adding New Clothing Items**
   - Add items to ox_inventory
   - Assign them to stores in the config.lua

2. **Creating New Stores**
   - Add new store entries to the Config.Stores table
   - Configure locations, inventory, and other settings

3. **Customizing Prices**
   - Adjust pricing in the Config.Rarity table
   - Each rarity level has min/max price ranges

## Commands

- `/wardrobe` - Open personal wardrobe
- `/outfit [name]` - Quickly wear a saved outfit
- `/washclothes` - Wash clothes at a laundromat
- `/repairclothes` - Repair damaged clothes at a tailor

## API for Developers

The resource provides exports for other resources to interact with:

```lua
-- Server exports
exports['clothing-system']:addClothingItem(source, itemName)
exports['clothing-system']:removeClothingItem(source, itemName)
exports['clothing-system']:getPlayerOutfits(source)

-- Client exports
exports['clothing-system']:openWardrobe()
exports['clothing-system']:wearOutfit(outfitId)
exports['clothing-system']:previewClothing(itemName, variation)
```

## Troubleshooting

### Common Issues

1. **Items not appearing in stores**
   - Ensure items are properly defined in ox_inventory
   - Check they are added to the store's inventory in config.lua

2. **Clothing not applying to character**
   - Verify the component, drawable, and texture IDs are correct
   - Check if the item is for the correct gender

3. **Database errors**
   - Make sure you've imported the SQL file
   - Check that oxmysql is running properly

## Support and Contributions

- Report issues on GitHub
- Pull requests are welcome
- Join our Discord for support

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

- Created by [Your Name/Team]
- UI Design inspired by modern e-commerce platforms
- Special thanks to the QB-Core & ox_inventory teams 