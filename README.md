# Vein Clothing System

A simple and powerful clothing system for your FiveM server that lets players buy, wear, and manage their clothes with ease.

## 🌟 Features

### Basic Features
- Buy clothes from different stores
- Save and load outfits
- Wash dirty clothes at laundromats
- Repair damaged clothes at tailors
- Simple UI that's easy to use
- Support for all types of clothing (GTA default and addon)

### Cool Extras
- Clothes get dirty and damaged over time
- Different stores have different prices
- Some clothes are rare and hard to find
- Stores restock their items automatically
- Preview clothes before buying
- Full addon clothing support

## 🚀 Quick Start Guide

### 1. Installation
1. Download the script
2. Put it in your server's `resources` folder
3. Add `ensure vein-clothing` to your `server.cfg`
4. Restart your server

### 2. Basic Setup
1. Open `config.lua` in the script folder
2. Set `Config.Debug = false` when you're done testing
3. Make sure you have these installed:
   - QB-Core
   - oxmysql
   - ox_lib
   - qb-target (optional)

### 3. Database Setup
Run this SQL command in your database:
```sql
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) DEFAULT NULL,
  `outfit` longtext DEFAULT NULL,
  `is_default` tinyint(1) DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `player_wishlist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## 🛍️ How to Use

### Buying Clothes
1. Go to any clothing store (marked on your map)
2. Press E to open the store menu
3. Browse through available clothes
4. Click on an item to preview it
5. Click "Buy" to purchase

### Managing Outfits
1. Use the `/wardrobe` command to open your wardrobe
2. Click "Save Outfit" to save what you're wearing
3. Click on a saved outfit to wear it
4. Use the trash icon to delete outfits you don't want

### Washing Clothes
1. Go to a laundromat (marked on your map)
2. Press E to open the menu
3. Select dirty clothes to wash
4. Pay the washing fee

### Repairing Clothes
1. Go to a tailor shop (marked on your map)
2. Press E to open the menu
3. Select damaged clothes to repair
4. Pay the repair cost

## 👕 Adding Custom Clothing

### Adding Default GTA Clothing
```lua
['tshirt_white'] = {
    name = 'tshirt_white',
    label = 'White T-Shirt',
    weight = 200,
    type = 'item',
    image = 'tshirt_white.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A simple white t-shirt',
    client = {
        category = 'torso',
        component = 11,
        drawable = 0,
        texture = 0,
        rarity = 'common'
    }
}
```

### Adding Addon Clothing
```lua
['addon_jacket_1'] = {
    name = 'addon_jacket_1',
    label = 'Addon Jacket 1',
    weight = 400,
    type = 'item',
    image = 'addon_jacket_1.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A cool addon jacket',
    client = {
        category = 'torso',
        component = 11,
        isAddon = true,
        model = 'addon_jacket_1',
        drawable = 0,
        texture = 0,
        rarity = 'rare'
    }
}
```

### Adding Addon Props (Hats, Glasses, etc.)
```lua
['addon_hat_1'] = {
    name = 'addon_hat_1',
    label = 'Addon Hat 1',
    weight = 200,
    type = 'item',
    image = 'addon_hat_1.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A cool addon hat',
    client = {
        category = 'hat',
        type = 'prop',
        isAddon = true,
        model = 'addon_hat_1',
        drawable = 0,
        texture = 0,
        rarity = 'uncommon'
    }
}
```

## 👕 Adding Clothes to Stores

### Component ID Reference Guide

When adding clothing items, you'll need to know which component ID to use. Here's a complete reference:

| Component ID | Category     | Description                          |
|--------------|--------------|--------------------------------------|
| 1            | mask         | Masks and face coverings             |
| 2            | hair         | Hairstyles and hair accessories      |
| 3            | torso        | Torso clothing (shirts, jackets)     |
| 4            | legs         | Pants, shorts, and leg wear          |
| 5            | bag          | Backpacks and bags                   |
| 6            | shoes        | Footwear                             |
| 7            | accessory    | Accessories like ties and scarves    |
| 8            | undershirt   | Undershirts and base layers          |
| 9            | kevlar       | Body armor and protective gear       |
| 10           | badge        | Badges and insignias                 |
| 11           | torso2       | Additional torso layers (coats, etc.)|

#### Example Usage:
```lua
-- For a mask
client = {
    category = 'mask',  -- Use the category name
    component = 1,      -- Use the component ID
    drawable = 0,
    texture = 0
}

-- For a jacket
client = {
    category = 'torso',  -- Use the category name
    component = 3,       -- Use the component ID
    drawable = 0,
    texture = 0
}
```

### Step 1: Prepare Your Clothing Items

#### For Default GTA Clothing
1. First, find the clothing item's drawable and texture IDs:
   - Use a tool like [GTA V Clothing ID Finder](https://gta5mod.net/gta-5-clothing-id-finder/)
   - Or use the in-game clothing store to find the IDs
   - Note down the component ID, drawable ID, and texture ID

2. Create the item in your QB-Core shared items:
```lua
['tshirt_white'] = {
    name = 'tshirt_white',
    label = 'White T-Shirt',
    weight = 200,
    type = 'item',
    image = 'tshirt_white.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A simple white t-shirt',
    client = {
        category = 'torso',  -- The category it belongs to
        component = 11,      -- The component ID (11 for torso)
        drawable = 0,        -- The drawable ID
        texture = 0,         -- The texture ID
        rarity = 'common'    -- The rarity level
    }
}
```

#### For Addon Streamed Clothing
1. Install your addon clothing pack:
   - Place the .yft and .ytd files in your server's stream folder
   - Ensure the resource is properly configured in your server.cfg
   - Test that the models load correctly in-game

2. Create the item in your QB-Core shared items:
```lua
['addon_jacket_1'] = {
    name = 'addon_jacket_1',
    label = 'Addon Jacket 1',
    weight = 400,
    type = 'item',
    image = 'addon_jacket_1.png',
    unique = true,
    useable = true,
    shouldClose = true,
    description = 'A cool addon jacket',
    client = {
        category = 'torso',      -- The category it belongs to
        component = 11,          -- The component ID
        isAddon = true,          -- Mark as addon clothing
        model = 'addon_jacket_1', -- The model name from your addon pack
        drawable = 0,            -- The drawable ID
        texture = 0,             -- The texture ID
        rarity = 'rare'          -- The rarity level
    }
}
```

### Step 2: Add Items to Store Inventory

1. Open your `config.lua` file
2. Find the `Config.Stores` section
3. Add your items to the store's inventory:

```lua
Config.Stores = {
    ['suburban'] = {
        label = "Suburban",
        blip = {
            sprite = 73,
            color = 3,
            scale = 0.7,
            label = "Suburban"
        },
        clerk = {
            model = "s_m_m_gentransport",
            scenario = "WORLD_HUMAN_STAND_IMPATIENT"
        },
        priceMultiplier = 1.0,
        locations = {
            vector4(127.02, -223.69, 54.56, 68.0)
        },
        inventory = {
            -- Default GTA clothing
            ['tshirt_white'] = {
                price = 100,
                stock = 10,
                variations = {
                    {texture = 0, label = "White"},
                    {texture = 1, label = "Black"}
                }
            },
            -- Addon clothing
            ['addon_jacket_1'] = {
                price = 500,
                stock = 5,
                variations = {
                    {texture = 0, label = "Red"},
                    {texture = 1, label = "Blue"}
                }
            }
        }
    }
}
```

### Step 3: Test Your Configuration

1. Restart your server
2. Visit the clothing store
3. Check that:
   - The items appear in the store inventory
   - The prices are correct
   - You can preview the items
   - You can purchase the items
   - The items appear correctly on your character

### Troubleshooting Common Issues

#### Default GTA Clothing Issues
- **Clothing doesn't appear**: Double-check the component, drawable, and texture IDs
- **Wrong appearance**: Verify the category matches the component ID
- **Missing textures**: Ensure the texture ID exists for that drawable

#### Addon Clothing Issues
- **Model doesn't load**: 
  - Check the model name matches your addon pack
  - Verify the addon resource is started before vein-clothing
  - Ensure the .yft and .ytd files are in the correct location
- **Texture issues**:
  - Verify the texture IDs exist in your addon pack
  - Check that the texture files are properly named
- **Performance issues**:
  - Optimize your addon models
  - Use proper LODs
  - Consider streaming distance

### Best Practices

1. **Organization**:
   - Group similar items together in the config
   - Use consistent naming conventions
   - Document your item IDs and variations

2. **Performance**:
   - Limit the number of variations per item
   - Use appropriate rarity levels
   - Set reasonable stock limits

3. **User Experience**:
   - Provide clear item labels
   - Add helpful descriptions
   - Set appropriate prices based on rarity

4. **Maintenance**:
   - Keep a backup of your configuration
   - Document any custom changes
   - Test thoroughly after updates

## ⚙️ Configuration

All settings are in `config.lua`. Here are the main things you can change:

### Store Locations
```lua
Config.Stores = {
    ['suburban'] = {
        label = "Suburban",
        locations = {
            vector4(127.02, -223.69, 54.56, 68.0),
            vector4(613.08, 2761.72, 42.09, 275.0)
        }
    }
}
```

### Prices and Rarity
```lua
Config.Rarity = {
    common = {
        maxStock = 15,
        priceMultiplier = 1.0
    },
    rare = {
        maxStock = 5,
        priceMultiplier = 2.5
    }
}
```

### Condition Settings
```lua
Config.Condition = {
    WornDegradationMin = 1,
    WornDegradationMax = 3,
    DirtyThreshold = 50,
    DamagedThreshold = 30
}
```

## 🎮 Commands

- `/wardrobe` - Open your wardrobe
- `/outfits` - Manage your saved outfits
- `/try [item]` - Try on a clothing item
- `/washclothes` - Open laundromat menu
- `/repairclothes` - Open tailor menu

## ❓ Common Questions

### Q: How do I add new clothes?
A: Add them to your QB-Core shared items and then add them to the store's inventory in `config.lua`

### Q: How do I add addon clothing?
A: Set `isAddon = true` in the item's client configuration and provide the model name

### Q: How do I change store locations?
A: Edit the `locations` in `config.lua` for each store

### Q: How do I make clothes more expensive?
A: Adjust the `priceMultiplier` in the store config or rarity settings

### Q: How do I add more stores?
A: Copy an existing store in `config.lua` and change its settings

## 🐛 Troubleshooting

### Problem: Clothes don't appear
- Make sure the items are in your QB-Core shared items
- Check that the store has the items in its inventory
- Verify the database tables are created
- For addon clothing, ensure the model is properly loaded

### Problem: Can't save outfits
- Check if the database tables are created
- Make sure you have less than 10 saved outfits
- Verify your database connection

### Problem: UI doesn't open
- Make sure all dependencies are installed
- Check if ox_lib is running
- Verify the resource is started in server.cfg

### Problem: Addon clothing doesn't work
- Verify the model name is correct
- Check if the addon resource is properly installed
- Ensure the addon resource is started before vein-clothing

## 📝 Support

If you need help:
1. Check the troubleshooting section
2. Look at the example configs
3. Ask in our Discord server
4. Create an issue on GitHub

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details. 