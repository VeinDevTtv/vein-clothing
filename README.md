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

## Configuration

The `config.lua` file allows you to customize various aspects of the system:

- Store locations, inventory, and pricing
- Condition degradation rates
- Laundromat and tailor locations
- Stock system parameters
- UI settings

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