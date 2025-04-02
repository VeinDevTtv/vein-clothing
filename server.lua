-- This is a compatibility file to ensure scripts that import the resource directly still work
-- All functionality is organized in the server/ folder

-- Expose any callback functions that might be called from other resources
local QBCore = exports['qb-core']:GetCoreObject()

-- Register server export functions
exports('addClothingItem', function(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    local item = QBCore.Shared.Items[itemName]
    if not item then return false end
    
    -- Add item with default metadata
    local metadata = {
        condition = 100
    }
    
    return Player.Functions.AddItem(itemName, 1, nil, metadata)
end)

exports('removeClothingItem', function(source, itemName)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    
    return Player.Functions.RemoveItem(itemName, 1)
end)

exports('getPlayerOutfits', function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return {} end
    
    local citizenid = Player.PlayerData.citizenid
    local outfits = {}
    
    local results = MySQL.Sync.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ?', {citizenid})
    
    if results then
        for _, outfit in ipairs(results) do
            table.insert(outfits, {
                id = outfit.id,
                name = outfit.outfitname,
                items = json.decode(outfit.outfit)
            })
        end
    end
    
    return outfits
end)

-- Get player name callback (used by NUI)
QBCore.Functions.CreateCallback('clothing-system:server:getPlayerName', function(source, cb, targetId)
    local Player = QBCore.Functions.GetPlayer(targetId)
    
    if not Player then
        cb("Unknown")
        return
    end
    
    local firstName = Player.PlayerData.charinfo.firstname or ""
    local lastName = Player.PlayerData.charinfo.lastname or ""
    
    cb(firstName .. " " .. lastName)
end)

-- Check if item is wishlisted
QBCore.Functions.CreateCallback('clothing-system:server:isItemWishlisted', function(source, cb, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(false)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_wishlist WHERE citizenid = ? AND item = ?', {citizenid, itemName}, function(count)
        cb(count > 0)
    end)
end)

-- Remove from wishlist
RegisterNetEvent('clothing-system:server:removeFromWishlist', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.execute('DELETE FROM player_wishlist WHERE citizenid = ? AND item = ?', {citizenid, itemName})
end)

-- Add to wishlist
RegisterNetEvent('clothing-system:server:addToWishlist', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.execute('INSERT INTO player_wishlist (citizenid, item) VALUES (?, ?)', {citizenid, itemName})
end)

-- Get item details callback
QBCore.Functions.CreateCallback('clothing-system:server:getItemDetails', function(source, cb, itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(nil)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchAll('SELECT * FROM player_clothing_condition WHERE citizenid = ? AND item = ?', {citizenid, itemName}, function(results)
        if not results or #results == 0 then
            cb(nil)
            return
        end
        
        cb({
            condition = results[1].condition,
            lastWorn = results[1].last_worn
        })
    end)
end)

CreateThread(function()
    -- Wait for resource to fully start
    Wait(500)
    
    -- Log message indicating that this file is deprecated
    print('^3[clothing-system]^7 Warning: Loading from root server.lua is deprecated. Please use the new folder structure.')
end)
