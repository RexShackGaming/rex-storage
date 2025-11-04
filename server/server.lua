local RSGCore = exports['rsg-core']:GetCoreObject()
local PropsLoaded = false
lib.locale()

---------------------------------------------
-- use storage box item
---------------------------------------------
RSGCore.Functions.CreateUseableItem('storage_box', function(source, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    -- Check current storage count
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_storage WHERE citizenid = ? AND proptype = ?", { citizenid, 'playerstorage' })
    
    if result >= Config.MaxStorageBoxes then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('storage_limit_reached'),
            description = locale('storage_limit_reached_desc', Config.MaxStorageBoxes),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('place_storage'),
        description = locale('place_storage_desc'),
        type = 'inform',
        duration = 5000
    })
    TriggerClientEvent('rex-storage:client:createstorage', src, 'playerstorage', Config.StorageProp)
end)

---------------------------------------------
-- add guest event (for menu system)
---------------------------------------------
RegisterServerEvent('rex-storage:server:addGuest')
AddEventHandler('rex-storage:server:addGuest', function(storageid, targetId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Verify ownership
    local isOwner = false
    for _, prop in pairs(Config.PlayerProps) do
        if prop.id == storageid and prop.builder == Player.PlayerData.citizenid then
            isOwner = true
            break
        end
    end
    
    if not isOwner then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('access_denied'),
            description = locale('access_denied_not_owner'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('player_not_found'),
            description = locale('player_not_found_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Check if guest already added
    local checkResult = MySQL.query.await('SELECT * FROM rex_storage_guests WHERE propid = ? AND guest_citizenid = ?', 
        {storageid, TargetPlayer.PlayerData.citizenid})
    
    if checkResult and checkResult[1] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('already_guest'),
            description = locale('already_guest_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Add guest
    MySQL.Async.execute('INSERT INTO rex_storage_guests (propid, owner_citizenid, guest_citizenid) VALUES (?, ?, ?)',
        {storageid, Player.PlayerData.citizenid, TargetPlayer.PlayerData.citizenid})
    
    -- Discord Log
    DiscordLog_GuestAdded(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        TargetPlayer.PlayerData.charinfo.firstname .. ' ' .. TargetPlayer.PlayerData.charinfo.lastname,
        TargetPlayer.PlayerData.citizenid,
        storageid
    )
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('guest_added'),
        description = locale('guest_added_desc', TargetPlayer.PlayerData.charinfo.firstname..' '..TargetPlayer.PlayerData.charinfo.lastname),
        type = 'success',
        duration = 5000
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = locale('storage_access'),
        description = locale('storage_access_desc', Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname),
        type = 'success',
        duration = 5000
    })
end)

---------------------------------------------
-- remove guest event (for menu system)
---------------------------------------------
RegisterServerEvent('rex-storage:server:removeGuest')
AddEventHandler('rex-storage:server:removeGuest', function(storageid, guestCitizenId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Verify ownership
    local isOwner = false
    for _, prop in pairs(Config.PlayerProps) do
        if prop.id == storageid and prop.builder == Player.PlayerData.citizenid then
            isOwner = true
            break
        end
    end
    
    if not isOwner then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('access_denied'),
            description = locale('access_denied_not_owner'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Get guest name
    local guestName = 'Player'
    local Players = RSGCore.Functions.GetPlayers()
    for _, playerId in pairs(Players) do
        local GuestPlayer = RSGCore.Functions.GetPlayer(playerId)
        if GuestPlayer and GuestPlayer.PlayerData.citizenid == guestCitizenId then
            guestName = GuestPlayer.PlayerData.charinfo.firstname .. ' ' .. GuestPlayer.PlayerData.charinfo.lastname
            
            -- Notify guest
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('storage_access_revoked'),
                description = locale('storage_access_revoked_desc', Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname),
                type = 'inform',
                duration = 5000
            })
            break
        end
    end
    
    -- Remove guest
    MySQL.Async.execute('DELETE FROM rex_storage_guests WHERE propid = ? AND guest_citizenid = ?',
        {storageid, guestCitizenId})
    
    -- Discord Log
    DiscordLog_GuestRemoved(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        guestName,
        guestCitizenId,
        storageid
    )
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('guest_removed'),
        description = locale('guest_removed_desc', guestName),
        type = 'success',
        duration = 5000
    })
end)

---------------------------------------------
-- add guest to storage command (LEGACY - kept for backwards compatibility)
---------------------------------------------
RSGCore.Commands.Add("addstoraguest", "add a guest to your storage", {{name = "id", help = "Player ID"}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('invalid_input'),
            description = locale('invalid_input_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('player_not_found'),
            description = locale('player_not_found_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Get nearby storage
    local nearbyStorage = nil
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    for _, prop in pairs(Config.PlayerProps) do
        if prop.builder == Player.PlayerData.citizenid then
            local propCoords = vector3(prop.x, prop.y, prop.z)
            local distance = #(playerCoords - propCoords)
            if distance < 5.0 then
                nearbyStorage = prop
                break
            end
        end
    end
    
    if not nearbyStorage then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('no_storage_nearby'),
            description = locale('no_storage_nearby_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Check if guest already added
    local checkResult = MySQL.query.await('SELECT * FROM rex_storage_guests WHERE propid = ? AND guest_citizenid = ?', 
        {nearbyStorage.id, TargetPlayer.PlayerData.citizenid})
    
    if checkResult and checkResult[1] then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('already_guest'),
            description = locale('already_guest_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Add guest
    MySQL.Async.execute('INSERT INTO rex_storage_guests (propid, owner_citizenid, guest_citizenid) VALUES (?, ?, ?)',
        {nearbyStorage.id, Player.PlayerData.citizenid, TargetPlayer.PlayerData.citizenid})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('guest_added'),
        description = locale('guest_added_desc', TargetPlayer.PlayerData.charinfo.firstname..' '..TargetPlayer.PlayerData.charinfo.lastname),
        type = 'success',
        duration = 5000
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = locale('storage_access'),
        description = locale('storage_access_desc', Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname),
        type = 'success',
        duration = 5000
    })
end)

---------------------------------------------
-- admin delete storage command
---------------------------------------------
RSGCore.Commands.Add("admindeletestorage", "Admin: Delete any storage box", {}, false, function(source)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Check if player is admin
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('access_denied'),
            description = locale('admin_required'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('admin_mode'),
        description = locale('admin_mode_desc'),
        type = 'inform',
        duration = 5000
    })
    
    TriggerClientEvent('rex-storage:client:adminDeleteMode', src)
end)

---------------------------------------------
-- admin delete storage handler
---------------------------------------------
RegisterServerEvent('rex-storage:server:adminDeleteStorage')
AddEventHandler('rex-storage:server:adminDeleteStorage', function(storageid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    -- Verify admin permission
    if not RSGCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('access_denied'),
            description = locale('admin_required'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Find storage owner
    local ownerCitizenId = nil
    for _, v in pairs(Config.PlayerProps) do
        if v.id == storageid then
            ownerCitizenId = v.builder
            break
        end
    end
    
    if not ownerCitizenId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('error'),
            description = locale('storage_not_found'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Remove from Config.PlayerProps
    for k, v in pairs(Config.PlayerProps) do
        if v.id == storageid then
            table.remove(Config.PlayerProps, k)
            break
        end
    end
    
    -- Clear inventory
    local storageName = 'storage'..tostring(storageid)
    TriggerEvent('rsg-inventory:server:ClearInventory', storageName)
    
    -- Notify admin
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('storage_deleted'),
        description = locale('storage_deleted_desc'),
        type = 'success',
        duration = 5000
    })
    
    -- Notify owner if online
    local Players = RSGCore.Functions.GetPlayers()
    for _, playerId in pairs(Players) do
        local OwnerPlayer = RSGCore.Functions.GetPlayer(playerId)
        if OwnerPlayer and OwnerPlayer.PlayerData.citizenid == ownerCitizenId then
            TriggerClientEvent('ox_lib:notify', playerId, {
                title = locale('storage_removed'),
                description = locale('storage_removed_desc'),
                type = 'inform',
                duration = 7000
            })
            break
        end
    end
    
    -- Discord Log
    local steamid = GetPlayerIdentifierByType(src, 'steam') or 'Unknown'
    DiscordLog_AdminDelete(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        Player.PlayerData.citizenid,
        steamid,
        ownerCitizenId,
        storageid
    )
    
    -- Trigger cleanup
    TriggerClientEvent('rex-storage:client:removePropObject', -1, storageid)
    TriggerEvent('rex-storage:server:PropRemoved', storageid)
    TriggerEvent('rex-storage:server:updateProps')
    
    print('[rex-storage] Admin '..Player.PlayerData.name..' (ID: '..src..') deleted storage '..storageid..' owned by '..ownerCitizenId)
end)

---------------------------------------------
-- remove guest from storage command
---------------------------------------------
RSGCore.Commands.Add("removestorguest", "remove a guest from your storage", {{name = "id", help = "Player ID"}}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local targetId = tonumber(args[1])
    if not targetId then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('invalid_input'),
            description = locale('invalid_input_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    local TargetPlayer = RSGCore.Functions.GetPlayer(targetId)
    if not TargetPlayer then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('player_not_found'),
            description = locale('player_not_found_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Get nearby storage
    local nearbyStorage = nil
    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    
    for _, prop in pairs(Config.PlayerProps) do
        if prop.builder == Player.PlayerData.citizenid then
            local propCoords = vector3(prop.x, prop.y, prop.z)
            local distance = #(playerCoords - propCoords)
            if distance < 5.0 then
                nearbyStorage = prop
                break
            end
        end
    end
    
    if not nearbyStorage then
        TriggerClientEvent('ox_lib:notify', src, {
            title = locale('no_storage_nearby'),
            description = locale('no_storage_nearby_remove_desc'),
            type = 'error',
            duration = 5000
        })
        return
    end
    
    -- Remove guest
    local result = MySQL.Async.execute('DELETE FROM rex_storage_guests WHERE propid = ? AND owner_citizenid = ? AND guest_citizenid = ?',
        {nearbyStorage.id, Player.PlayerData.citizenid, TargetPlayer.PlayerData.citizenid})
    
    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('guest_removed'),
        description = locale('guest_removed_desc', TargetPlayer.PlayerData.charinfo.firstname..' '..TargetPlayer.PlayerData.charinfo.lastname),
        type = 'success',
        duration = 5000
    })
    
    TriggerClientEvent('ox_lib:notify', targetId, {
        title = locale('storage_access_revoked'),
        description = locale('storage_access_revoked_desc', Player.PlayerData.charinfo.firstname..' '..Player.PlayerData.charinfo.lastname),
        type = 'inform',
        duration = 5000
    })
end)

---------------------------------------------
-- get all prop data
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-storage:server:getallpropdata', function(source, cb, propid)
    MySQL.query('SELECT * FROM rex_storage WHERE propid = ?', {propid}, function(result)
        if result[1] then
            cb(result)
        else
            cb(nil)
        end
    end)
end)

---------------------------------------------
-- check storage ownership and get guest list
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-storage:server:isStorageOwner', function(source, cb, storageid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then 
        cb(false, {})
        return 
    end
    
    local citizenid = Player.PlayerData.citizenid
    local isOwner = false
    
    -- Check if player is owner
    for _, v in pairs(Config.PlayerProps) do
        if v.id == storageid and v.builder == citizenid then
            isOwner = true
            break
        end
    end
    
    -- Get guest list if owner
    local guestList = {}
    if isOwner then
        local result = MySQL.query.await('SELECT guest_citizenid FROM rex_storage_guests WHERE propid = ?', {storageid})
        if result then
            for _, row in ipairs(result) do
                local guestCitizenId = row.guest_citizenid
                -- Try to get guest name from online players first
                local guestName = nil
                local Players = RSGCore.Functions.GetPlayers()
                for _, playerId in pairs(Players) do
                    local GuestPlayer = RSGCore.Functions.GetPlayer(playerId)
                    if GuestPlayer and GuestPlayer.PlayerData.citizenid == guestCitizenId then
                        guestName = GuestPlayer.PlayerData.charinfo.firstname .. ' ' .. GuestPlayer.PlayerData.charinfo.lastname
                        break
                    end
                end
                
                -- If not online, query database
                if not guestName then
                    local charResult = MySQL.query.await('SELECT charinfo FROM players WHERE citizenid = ?', {guestCitizenId})
                    if charResult and charResult[1] then
                        local charinfo = json.decode(charResult[1].charinfo)
                        guestName = charinfo.firstname .. ' ' .. charinfo.lastname
                    else
                        guestName = 'Unknown Player'
                    end
                end
                
                table.insert(guestList, {
                    citizenid = guestCitizenId,
                    name = guestName
                })
            end
        end
    end
    
    cb(isOwner, guestList)
end)

---------------------------------------------
-- count props
---------------------------------------------
RSGCore.Functions.CreateCallback('rex-storage:server:countprop', function(source, cb, proptype)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid
    local result = MySQL.prepare.await("SELECT COUNT(*) as count FROM rex_storage WHERE citizenid = ? AND proptype = ?", { citizenid, proptype })
    if result then
        cb(result)
    else
        cb(nil)
    end
end)

---------------------------------------------
-- update prop data
---------------------------------------------
CreateThread(function()
    while true do
        Wait(5000)

        if PropsLoaded then
            -- Send only nearby props to each player instead of broadcasting all
            local Players = RSGCore.Functions.GetPlayers()
            for _, playerId in pairs(Players) do
                local playerPed = GetPlayerPed(playerId)
                if playerPed > 0 then
                    local playerCoords = GetEntityCoords(playerPed)
                    local nearbyProps = {}
                    for _, prop in pairs(Config.PlayerProps) do
                        local propCoords = vector3(prop.x, prop.y, prop.z)
                        local distance = #(playerCoords - propCoords)
                        if distance < 100.0 then -- Only send props within 100 units
                            table.insert(nearbyProps, prop)
                        end
                    end
                    TriggerClientEvent('rex-storage:client:updatePropData', playerId, nearbyProps)
                end
            end
        end
    end
end)

---------------------------------------------
-- get props
---------------------------------------------
CreateThread(function()
    TriggerEvent('rex-storage:server:getProps')
    PropsLoaded = true
end)

---------------------------------------------
-- save props
---------------------------------------------
RegisterServerEvent('rex-storage:server:saveProp')
AddEventHandler('rex-storage:server:saveProp', function(data, propId, citizenid, proptype)
    local datas = json.encode(data)

    MySQL.Async.execute('INSERT INTO rex_storage (properties, propid, citizenid, proptype) VALUES (@properties, @propid, @citizenid, @proptype)',
    {
        ['@properties'] = datas,
        ['@propid'] = propId,
        ['@citizenid'] = citizenid,
        ['@proptype'] = proptype
    }, function()
        -- Get source from citizenid to send notification
        local Players = RSGCore.Functions.GetPlayers()
        for _, playerId in pairs(Players) do
            local Player = RSGCore.Functions.GetPlayer(playerId)
            if Player and Player.PlayerData.citizenid == citizenid then
                TriggerClientEvent('ox_lib:notify', playerId, {
                    title = locale('storage_created'),
                    description = locale('storage_created_desc'),
                    type = 'success',
                    duration = 4000
                })
                break
            end
        end
    end)
end)

---------------------------------------------
-- generate secure unique ID
---------------------------------------------
local function GenerateSecureID()
    local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    local id = ''
    for i = 1, 16 do
        local rand = math.random(1, #charset)
        id = id .. string.sub(charset, rand, rand)
    end
    return id .. '-' .. os.time() .. '-' .. math.random(10000, 99999)
end

---------------------------------------------
-- new prop
---------------------------------------------
RegisterServerEvent('rex-storage:server:newProp')
AddEventHandler('rex-storage:server:newProp', function(proptype, location, heading, hash)
    local src = source
    local propId = GenerateSecureID()
    local Player = RSGCore.Functions.GetPlayer(src)
    local citizenid = Player.PlayerData.citizenid

    local PropData =
    {
        id = propId,
        proptype = proptype,
        x = location.x,
        y = location.y,
        z = location.z,
        h = heading,
        hash = hash,
        builder = Player.PlayerData.citizenid,
        buildttime = os.time()
    }

    table.insert(Config.PlayerProps, PropData)
    TriggerEvent('rex-storage:server:saveProp', PropData, propId, citizenid, proptype)
    TriggerEvent('rex-storage:server:updateProps')
    
    -- Remove the storage_box item from inventory
    if Player.Functions.RemoveItem('storage_box', 1) then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['storage_box'], 'remove', 1)
    end
    
    -- Discord Log
    local steamid = GetPlayerIdentifierByType(src, 'steam') or 'Unknown'
    DiscordLog_StorageCreated(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid,
        steamid,
        propId,
        location
    )

end)

---------------------------------------------
-- distory prop
---------------------------------------------
RegisterServerEvent('rex-storage:server:destroyProp')
AddEventHandler('rex-storage:server:destroyProp', function(propid, item)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    
    local citizenid = Player.PlayerData.citizenid
    local canDestroy = false
    local propIndex = nil

    -- Validate ownership before destroying
    for k, v in pairs(Config.PlayerProps) do
        if v.id == propid then
            if v.builder == citizenid then
                canDestroy = true
                propIndex = k
                break
            end
        end
    end

    if not canDestroy then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('access_denied'), description = locale('access_denied_not_owner'), type = 'error', duration = 5000})
        return
    end

    -- Remove from table
    if propIndex then
        table.remove(Config.PlayerProps, propIndex)
    end

    -- Clear the inventory contents before destroying
    local storageName = 'storage'..tostring(propid)
    TriggerEvent('rsg-inventory:server:ClearInventory', storageName)

    -- Return the storage_box item to the player's inventory
    Player.Functions.AddItem('storage_box', 1)
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items['storage_box'], 'add', 1)

    TriggerClientEvent('ox_lib:notify', src, {
        title = locale('storage_destroyed'),
        description = locale('storage_destroyed_desc'),
        type = 'success',
        duration = 4000
    })
    
    -- Discord Log
    local playerPed = GetPlayerPed(src)
    local coords = GetEntityCoords(playerPed)
    local steamid = GetPlayerIdentifierByType(src, 'steam') or 'Unknown'
    DiscordLog_StorageDestroyed(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid,
        steamid,
        propid,
        coords
    )

    TriggerClientEvent('rex-storage:client:removePropObject', src, propid)
    TriggerEvent('rex-storage:server:PropRemoved', propid)
    TriggerEvent('rex-storage:server:updateProps')
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterServerEvent('rex-storage:server:updateProps')
AddEventHandler('rex-storage:server:updateProps', function()
    local src = source
    TriggerClientEvent('rex-storage:client:updatePropData', src, Config.PlayerProps)
end)

RegisterServerEvent('rex-storage:server:updateCampProps')
AddEventHandler('rex-storage:server:updateCampProps', function(id, data)
    local result = MySQL.query.await('SELECT * FROM rex_storage WHERE propid = @propid',
    {
        ['@propid'] = id
    })

    if not result[1] then return end

    local newData = json.encode(data)

    MySQL.Async.execute('UPDATE rex_storage SET properties = @properties WHERE propid = @id',
    {
        ['@properties'] = newData,
        ['@id'] = id
    })
end)

---------------------------------------------
-- remove props
---------------------------------------------
RegisterServerEvent('rex-storage:server:PropRemoved')
AddEventHandler('rex-storage:server:PropRemoved', function(propId)
    -- Optimized: Only query the specific storage record we need
    local result = MySQL.query.await('SELECT * FROM rex_storage WHERE propid = @propid', { ['@propid'] = propId })

    if not result or not result[1] then return end

    local storageRecord = result[1]
    local storageName = 'storage'..tostring(storageRecord.propid)

    -- Delete the storage record from rex_storage table
    MySQL.Async.execute('DELETE FROM rex_storage WHERE propid = @propid', { ['@propid'] = storageRecord.propid })
    MySQL.Async.execute('DELETE FROM inventories WHERE identifier = @identifier', { ['@identifier'] = storageName })
    -- Delete all guest access records for this storage
    MySQL.Async.execute('DELETE FROM rex_storage_guests WHERE propid = @propid', { ['@propid'] = propId })

    -- Remove from Config.PlayerProps if still present
    for k, v in pairs(Config.PlayerProps) do
        if v.id == propId then
            table.remove(Config.PlayerProps, k)
            break
        end
    end
    
    print('[rex-storage] Removed storage '..propId..' and cleared inventory '..storageName)
end)

---------------------------------------------
-- get props
---------------------------------------------
RegisterServerEvent('rex-storage:server:getProps')
AddEventHandler('rex-storage:server:getProps', function()
    local result = MySQL.query.await('SELECT * FROM rex_storage')

    if not result[1] then return end

    for i = 1, #result do
        local propData = json.decode(result[i].properties)
        print('loading '..propData.proptype..' prop with ID: '..propData.id)
        table.insert(Config.PlayerProps, propData)
    end
end)

---------------------------------------------
-- remove item
---------------------------------------------
RegisterServerEvent('rex-storage:server:removeitem')
AddEventHandler('rex-storage:server:removeitem', function(item, amount)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    Player.Functions.RemoveItem(item, amount)
    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item], "remove")
end)

-----------------------
-- open stash
-----------------------
RegisterNetEvent('rex-storage:server:openstorage', function(storageid)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or not storageid then return end
    
    local citizenid = Player.PlayerData.citizenid
    local hasAccess = false
    
    -- Validate ownership or guest access before opening
    for _, v in pairs(Config.PlayerProps) do
        if v.id == storageid then
            if v.builder == citizenid then
                hasAccess = true
                break
            end
        end
    end
    
    -- Check if player is a guest
    if not hasAccess then
        local guestResult = MySQL.query.await('SELECT * FROM rex_storage_guests WHERE propid = ? AND guest_citizenid = ?', 
            {storageid, citizenid})
        if guestResult and guestResult[1] then
            hasAccess = true
        end
    end
    
    if not hasAccess then
        TriggerClientEvent('ox_lib:notify', src, {title = locale('access_denied'), description = locale('access_denied_no_access'), type = 'error', duration = 5000})
        return
    end
    
    -- Discord Log for storage access
    local isGuest = false
    local ownerName = nil
    for _, v in pairs(Config.PlayerProps) do
        if v.id == storageid then
            if v.builder ~= citizenid then
                isGuest = true
                -- Get owner name
                local Players = RSGCore.Functions.GetPlayers()
                for _, playerId in pairs(Players) do
                    local OwnerPlayer = RSGCore.Functions.GetPlayer(playerId)
                    if OwnerPlayer and OwnerPlayer.PlayerData.citizenid == v.builder then
                        ownerName = OwnerPlayer.PlayerData.charinfo.firstname .. ' ' .. OwnerPlayer.PlayerData.charinfo.lastname
                        break
                    end
                end
            end
            break
        end
    end
    
    local steamid = GetPlayerIdentifierByType(src, 'steam') or 'Unknown'
    DiscordLog_StorageAccessed(
        Player.PlayerData.charinfo.firstname .. ' ' .. Player.PlayerData.charinfo.lastname,
        citizenid,
        steamid,
        storageid,
        ownerName,
        isGuest
    )
    
    local storagedata = { label = 'Player Storage Box', maxweight = Config.StorageMaxWeight, slots = Config.StorageMaxSlots }
    local storageName = 'storage'..tostring(storageid)
    exports['rsg-inventory']:OpenInventory(src, storageName, storagedata)
end)
