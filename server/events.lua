local QBCore = exports['qb-core']:GetCoreObject()

-- Add this function at the top of the file
local outfitColumnName = 'outfit' -- Default column name

-- Function to get the correct outfit column name 
local function GetOutfitColumnName(callback)
    -- If we already know the column name, use it
    if outfitColumnName ~= 'outfit' then
        callback(outfitColumnName)
        return
    end
    
    -- Otherwise, determine the column name
    MySQL.Async.fetchAll('SHOW COLUMNS FROM player_outfits', {}, function(columns)
        for i=1, #columns do
            local column = columns[i].Field
            if column == 'outfit' or column == 'outfitdata' or column == 'outfit_data' or column == 'data' then
                outfitColumnName = column
                callback(outfitColumnName)
                return
            end
        end
        callback('outfit') -- Default if no match found
    end)
end

-- Get outfit by ID callback
QBCore.Functions.CreateCallback('vein-clothing:server:getOutfitById', function(source, cb, outfitId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(nil)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE id = ? AND citizenid = ?', {outfitId, citizenid}, function(results)
        if not results or #results == 0 then
            cb(nil)
            return
        end
        
        local outfit = {
            id = results[1].id,
            name = results[1].outfitname,
            items = json.decode(results[1].outfit)
        }
        
        cb(outfit)
    end)
end)

-- Get default outfit callback (outfit that should be applied on player spawn)
QBCore.Functions.CreateCallback('vein-clothing:server:getDefaultOutfit', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb(nil)
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check if player has a default outfit set
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ? AND outfitname = ?', {citizenid, "default"}, function(results)
        if results and #results > 0 then
            -- Player has a default outfit
            cb(json.decode(results[1].outfit))
        else
            -- No default outfit, get last worn items from player_clothing_condition
            MySQL.Async.fetchAll('SELECT * FROM player_clothing_condition WHERE citizenid = ? ORDER BY last_worn DESC', {citizenid}, function(clothingResults)
                if not clothingResults or #clothingResults == 0 then
                    -- No clothing data found
                    cb({})
                    return
                end
                
                local outfitItems = {}
                local usedComponents = {}
                
                -- Process items, using only the most recently worn item for each component
                for _, clothingItem in ipairs(clothingResults) do
                    local itemName = clothingItem.item
                    local item = QBCore.Shared.Items[itemName]
                    
                    if item and item.client and item.client.component then
                        local component = item.client.component
                        
                        -- Only add if this component hasn't been added yet
                        if not usedComponents[component] then
                            local texture = item.client.texture
                            local variation = 0
                            
                            -- Check inventory for this specific item to get metadata (like variation)
                            local foundItem = Player.Functions.GetItemByName(itemName)
                            if foundItem and foundItem.info then
                                if foundItem.info.texture then
                                    texture = foundItem.info.texture
                                end
                                
                                if foundItem.info.variation then
                                    variation = foundItem.info.variation
                                end
                            end
                            
                            table.insert(outfitItems, {
                                name = itemName,
                                component = component,
                                drawable = item.client.drawable,
                                texture = texture,
                                variation = variation,
                                event = item.client.event
                            })
                            
                            -- Mark this component as used
                            usedComponents[component] = true
                        end
                    end
                end
                
                cb(outfitItems)
            end)
        end
    end)
end)

-- Get synced clothing callback (used when player respawns)
QBCore.Functions.CreateCallback('vein-clothing:server:getSyncedClothing', function(source, cb)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then
        cb({})
        return
    end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get all clothing items from player's inventory that have been worn
    MySQL.Async.fetchAll('SELECT * FROM player_clothing_condition WHERE citizenid = ? ORDER BY last_worn DESC', {citizenid}, function(results)
        if not results or #results == 0 then
            cb({})
            return
        end
        
        local clothingItems = {}
        local usedComponents = {}
        
        for _, clothingData in ipairs(results) do
            local itemName = clothingData.item
            local item = QBCore.Shared.Items[itemName]
            
            -- Check if player still has this item in inventory
            if Player.Functions.HasItem(itemName) and item and item.client then
                local component = item.client.component
                
                -- Only include the most recently worn item for each component
                if not usedComponents[component] then
                    local texture = item.client.texture
                    local variation = 0
                    
                    -- Get metadata from inventory
                    local invItem = Player.Functions.GetItemByName(itemName)
                    if invItem and invItem.info then
                        if invItem.info.texture then
                            texture = invItem.info.texture
                        end
                        
                        if invItem.info.variation then
                            variation = invItem.info.variation
                        end
                    end
                    
                    table.insert(clothingItems, {
                        name = itemName,
                        component = component,
                        drawable = item.client.drawable,
                        texture = texture,
                        variation = variation,
                        event = item.client.event
                    })
                    
                    usedComponents[component] = true
                end
            end
        end
        
        cb(clothingItems)
    end)
end)

-- Delete outfit event
RegisterNetEvent('vein-clothing:server:deleteOutfit', function(outfitId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE id = ? AND citizenid = ?', {outfitId, citizenid}, function(results)
        if not results or #results == 0 then
            TriggerClientEvent('QBCore:Notify', src, "Outfit not found", "error")
            return
        end
        
        local outfitName = results[1].outfitname
        
        MySQL.Async.execute('DELETE FROM player_outfits WHERE id = ? AND citizenid = ?', {outfitId, citizenid}, function()
            TriggerClientEvent('QBCore:Notify', src, "Deleted outfit: " .. outfitName, "success")
        end)
    end)
end)

-- Set default outfit event
RegisterNetEvent('vein-clothing:server:setDefaultOutfit', function(outfitId)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Get the correct column name
    GetOutfitColumnName(function(columnName)
        -- Reset all outfits to non-default
        MySQL.Async.execute('UPDATE player_outfits SET is_default = 0 WHERE citizenid = ?', {citizenid})
        
        -- Set the selected outfit as default
        MySQL.Async.execute('UPDATE player_outfits SET is_default = 1 WHERE id = ? AND citizenid = ?', 
            {outfitId, citizenid})
        
        -- Get outfit details
        local query = string.format('SELECT outfitname, %s FROM player_outfits WHERE id = ? AND citizenid = ?', columnName)
        MySQL.Async.fetchAll(query, {outfitId, citizenid}, function(results)
            if not results or #results == 0 then
                TriggerClientEvent('QBCore:Notify', src, "Outfit not found", "error")
                return
            end
            
            local outfitName = results[1].outfitname
            local outfitData = results[1][columnName]
            
            -- Check if a default outfit already exists
            MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ? AND outfitname = ?', 
                {citizenid, "default"}, function(defaultResults)
                
                if defaultResults and #defaultResults > 0 then
                    -- Update existing default outfit
                    local defaultQuery = string.format('UPDATE player_outfits SET %s = ? WHERE citizenid = ? AND outfitname = ?', columnName)
                    MySQL.Async.execute(defaultQuery, {outfitData, citizenid, "default"})
                else
                    -- Create new default outfit
                    local defaultInsertQuery = string.format('INSERT INTO player_outfits (citizenid, outfitname, %s) VALUES (?, ?, ?)', columnName)
                    MySQL.Async.execute(defaultInsertQuery, {citizenid, "default", outfitData})
                end
                
                TriggerClientEvent('QBCore:Notify', src, "Set " .. outfitName .. " as default outfit", "success")
            end)
        end)
    end)
end)

-- Trade clothing item to another player
RegisterNetEvent('vein-clothing:server:tradeItem', function(targetId, itemName, slot)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then
        TriggerClientEvent('QBCore:Notify', src, "Invalid player", "error")
        return
    end
    
    -- Get the item from player's inventory
    local item = Player.Functions.GetItemBySlot(slot)
    
    if not item or item.name ~= itemName then
        TriggerClientEvent('QBCore:Notify', src, "Item not found", "error")
        return
    end
    
    -- Check if the item is being worn
    TriggerClientEvent('vein-clothing:client:checkIfWorn', src, itemName, function(isWorn)
        if isWorn then
            TriggerClientEvent('QBCore:Notify', src, "You can't trade an item you're wearing", "error")
            return
        end
        
        -- Remove from source player
        if Player.Functions.RemoveItem(itemName, 1, slot) then
            -- Add to target player (with the same metadata)
            if Target.Functions.AddItem(itemName, 1, nil, item.info) then
                TriggerClientEvent('QBCore:Notify', src, "Item given to " .. Target.PlayerData.charinfo.firstname, "success")
                TriggerClientEvent('QBCore:Notify', targetId, "Received " .. QBCore.Shared.Items[itemName].label .. " from " .. Player.PlayerData.charinfo.firstname, "success")
            else
                -- Failed to add to target, give back to source
                Player.Functions.AddItem(itemName, 1, slot, item.info)
                TriggerClientEvent('QBCore:Notify', src, "Trading failed - inventory full", "error")
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Failed to remove item", "error")
        end
    end)
end)

-- Sell clothing to another player
RegisterNetEvent('vein-clothing:server:sellItem', function(targetId, itemName, slot, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    local Target = QBCore.Functions.GetPlayer(targetId)
    
    if not Player or not Target then
        TriggerClientEvent('QBCore:Notify', src, "Invalid player", "error")
        return
    end
    
    -- Validate price
    if not price or price <= 0 then
        TriggerClientEvent('QBCore:Notify', src, "Invalid price", "error")
        return
    end
    
    -- Get the item from player's inventory
    local item = Player.Functions.GetItemBySlot(slot)
    
    if not item or item.name ~= itemName then
        TriggerClientEvent('QBCore:Notify', src, "Item not found", "error")
        return
    end
    
    -- Check if target has enough money
    if Target.PlayerData.money["cash"] < price then
        TriggerClientEvent('QBCore:Notify', src, "Buyer doesn't have enough money", "error")
        TriggerClientEvent('QBCore:Notify', targetId, "You don't have enough money", "error")
        return
    end
    
    -- Send offer to target player
    TriggerClientEvent('vein-clothing:client:receiveOfferRequest', targetId, src, itemName, price, function(accepted)
        if accepted then
            -- Remove item from seller
            if Player.Functions.RemoveItem(itemName, 1, slot) then
                -- Remove money from buyer
                if Target.Functions.RemoveMoney("cash", price) then
                    -- Add money to seller
                    Player.Functions.AddMoney("cash", price)
                    
                    -- Add item to buyer
                    if Target.Functions.AddItem(itemName, 1, nil, item.info) then
                        TriggerClientEvent('QBCore:Notify', src, "Sold " .. QBCore.Shared.Items[itemName].label .. " for $" .. price, "success")
                        TriggerClientEvent('QBCore:Notify', targetId, "Bought " .. QBCore.Shared.Items[itemName].label .. " for $" .. price, "success")
                    else
                        -- Failed to add to buyer, refund everything
                        Player.Functions.AddItem(itemName, 1, slot, item.info)
                        Target.Functions.AddMoney("cash", price)
                        TriggerClientEvent('QBCore:Notify', src, "Sale failed - buyer's inventory is full", "error")
                        TriggerClientEvent('QBCore:Notify', targetId, "Purchase failed - inventory full", "error")
                    end
                else
                    -- Failed to remove money, give item back
                    Player.Functions.AddItem(itemName, 1, slot, item.info)
                    TriggerClientEvent('QBCore:Notify', src, "Sale failed - money transaction failed", "error")
                    TriggerClientEvent('QBCore:Notify', targetId, "Purchase failed - money transaction failed", "error")
                end
            else
                TriggerClientEvent('QBCore:Notify', src, "Failed to remove item from inventory", "error")
            end
        else
            TriggerClientEvent('QBCore:Notify', src, "Offer declined", "error")
        end
    end)
end)

-- Rename outfit event
RegisterNetEvent('vein-clothing:server:renameOutfit', function(outfitId, newName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Validate new name
    if not newName or newName == "" or newName:len() > 50 then
        TriggerClientEvent('QBCore:Notify', src, "Invalid outfit name", "error")
        return
    end
    
    -- Check if outfit exists
    MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE id = ? AND citizenid = ?', {outfitId, citizenid}, function(results)
        if not results or #results == 0 then
            TriggerClientEvent('QBCore:Notify', src, "Outfit not found", "error")
            return
        end
        
        local oldName = results[1].outfitname
        
        -- Update outfit name
        MySQL.Async.execute('UPDATE player_outfits SET outfitname = ? WHERE id = ? AND citizenid = ?', 
            {newName, outfitId, citizenid}, function()
            TriggerClientEvent('QBCore:Notify', src, "Renamed outfit: " .. oldName .. " -> " .. newName, "success")
        end)
    end)
end)

-- Update the save outfit event handler
RegisterNetEvent('vein-clothing:server:saveOutfit', function(name, outfitData)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Validate input
    if not name or not outfitData then
        TriggerClientEvent('QBCore:Notify', src, "Invalid outfit data", "error")
        return
    end
    
    -- Get the correct column name
    GetOutfitColumnName(function(columnName)
        -- Check if outfit name already exists
        MySQL.Async.fetchAll('SELECT * FROM player_outfits WHERE citizenid = ? AND outfitname = ?', 
            {citizenid, name}, function(results)
            
            if results and #results > 0 then
                -- Update existing outfit
                local query = string.format('UPDATE player_outfits SET %s = ? WHERE citizenid = ? AND outfitname = ?', columnName)
                MySQL.Async.execute(query, {json.encode(outfitData), citizenid, name})
                TriggerClientEvent('QBCore:Notify', src, "Updated outfit: " .. name, "success")
            else
                -- Count existing outfits
                MySQL.Async.fetchScalar('SELECT COUNT(*) FROM player_outfits WHERE citizenid = ?', {citizenid}, function(count)
                    if count >= Config.Outfits.MaxOutfits then
                        TriggerClientEvent('QBCore:Notify', src, "You can only save up to " .. Config.Outfits.MaxOutfits .. " outfits", "error")
                        return
                    end
                    
                    -- Create new outfit
                    local query = string.format('INSERT INTO player_outfits (citizenid, outfitname, %s) VALUES (?, ?, ?)', columnName)
                    MySQL.Async.execute(query, {citizenid, name, json.encode(outfitData)})
                    TriggerClientEvent('QBCore:Notify', src, "Saved new outfit: " .. name, "success")
                end)
            end
        end)
    end)
end) 