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