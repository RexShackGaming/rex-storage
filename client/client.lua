local RSGCore = exports['rsg-core']:GetCoreObject()
local SpawnedProps = {}
local isBusy = false
local fx_group = "scr_dm_ftb"
local fx_name = "scr_mp_chest_spawn_smoke"
local fx_scale = 1.0
lib.locale()

---------------------------------------------
-- spawn props
---------------------------------------------
Citizen.CreateThread(function()
    while true do
        Wait(150)

        local pos = GetEntityCoords(cache.ped)
        local InRange = false

        for i = 1, #Config.PlayerProps do
            local prop = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
            local dist = #(pos - prop)
            if dist >= 50.0 then goto continue end

            local hasSpawned = false
            InRange = true

            for z = 1, #SpawnedProps do
                local p = SpawnedProps[z]

                if p.id == Config.PlayerProps[i].id then
                    hasSpawned = true
                end
            end

            if hasSpawned then goto continue end

            local modelHash = Config.PlayerProps[i].hash
            local data = {}
            
            if not HasModelLoaded(modelHash) then
                RequestModel(modelHash)
                while not HasModelLoaded(modelHash) do
                    Wait(1)
                end
            end
            
            data.id = Config.PlayerProps[i].id
            data.obj = CreateObject(modelHash, Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z -1.2, false, false, false)
            SetEntityHeading(data.obj, Config.PlayerProps[i].h)
            SetEntityAsMissionEntity(data.obj, true)
            PlaceObjectOnGroundProperly(data.obj)
            Wait(1000)
            FreezeEntityPosition(data.obj, true)
            SetModelAsNoLongerNeeded(data.obj)

            if Config.EnableVegModifier then
                -- veg modifiy
                local veg_modifier_sphere = 0
                
                if veg_modifier_sphere == nil or veg_modifier_sphere == 0 then
                    local veg_radius = 3.0
                    local veg_Flags =  1 + 2 + 4 + 8 + 16 + 32 + 64 + 128 + 256
                    local veg_ModType = 1
                    
                    veg_modifier_sphere = AddVegModifierSphere(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z, veg_radius, veg_ModType, veg_Flags, 0)
                    
                else
                    RemoveVegModifierSphere(Citizen.PointerValueIntInitialized(veg_modifier_sphere), 0)
                    veg_modifier_sphere = 0
                end
            end

            SpawnedProps[#SpawnedProps + 1] = data
            hasSpawned = false

            -- create target for the entity
            exports.ox_target:addLocalEntity(data.obj, {
                {
                    name = 'storage_menu', 
                    icon = 'fas fa-box',
                    label = locale('storage_options'),
                    iconColor = '#4CAF50',
                    onSelect = function()
                        TriggerEvent('rex-storage:client:openStorageMenu', data.id, data.obj)
                    end,
                    distance = 2.0
                },
            })
            -- end of target

            ::continue::
        end

        if not InRange then
            Wait(5000)
        end
    end
end)

---------------------------------------------
-- admin delete mode
---------------------------------------------
RegisterNetEvent('rex-storage:client:adminDeleteMode', function()
    local adminMode = true
    
    lib.notify({
        title = locale('admin_delete_mode'),
        description = locale('admin_delete_desc'),
        type = 'inform',
        duration = 5000
    })
    
    -- Add temporary admin delete option to all spawned storage boxes
    for i = 1, #SpawnedProps do
        local data = SpawnedProps[i]
        
        exports.ox_target:addLocalEntity(data.obj, {
            {
                name = 'admin_delete_storage',
                icon = 'fas fa-trash',
                label = locale('admin_delete_storage'),
                iconColor = '#ff0000',
                onSelect = function()
                    local alert = lib.alertDialog({
                        header = locale('admin_delete_confirm_header'),
                        content = locale('admin_delete_confirm_content'),
                        centered = true,
                        cancel = true,
                        labels = {
                            confirm = locale('delete'),
                            cancel = locale('cancel')
                        }
                    })
                    
                    if alert == 'confirm' then
                        TriggerServerEvent('rex-storage:server:adminDeleteStorage', data.id)
                    end
                end,
                distance = 2.0
            },
        })
    end
end)

---------------------------------------------
-- open storage menu
---------------------------------------------
RegisterNetEvent('rex-storage:client:openStorageMenu', function(storageid, storageobj)
    RSGCore.Functions.TriggerCallback('rex-storage:server:isStorageOwner', function(isOwner, guestList)
        local menuOptions = {
            {
                title = locale('open_storage'),
                description = locale('open_storage_desc'),
                icon = 'box-open',
                iconColor = '#4CAF50',
                onSelect = function()
                    TriggerServerEvent('rex-storage:server:openstorage', storageid)
                end
            }
        }
        
        if isOwner then
            table.insert(menuOptions, {
                title = locale('manage_guests'),
                description = locale('manage_guests_desc'),
                icon = 'users',
                iconColor = '#2196F3',
                onSelect = function()
                    TriggerEvent('rex-storage:client:manageGuests', storageid, guestList)
                end
            })
            
            table.insert(menuOptions, {
                title = locale('destroy_storage'),
                description = locale('destroy_storage_desc'),
                icon = 'trash-alt',
                iconColor = '#f44336',
                disabled = isBusy,
                onSelect = function()
                    TriggerEvent('rex-storage:client:destroystorage', storageobj, storageid)
                end
            })
        end
        
        lib.registerContext({
            id = 'storage_main_menu',
            title = locale('storage_box'),
            options = menuOptions
        })
        
        lib.showContext('storage_main_menu')
    end, storageid)
end)

---------------------------------------------
-- manage guests menu
---------------------------------------------
RegisterNetEvent('rex-storage:client:manageGuests', function(storageid, guestList)
    local menuOptions = {
        {
            title = locale('add_guest'),
            description = locale('add_guest_desc'),
            icon = 'user-plus',
            iconColor = '#4CAF50',
            onSelect = function()
                local input = lib.inputDialog(locale('add_guest_dialog'), {
                    {type = 'number', label = locale('player_id'), description = locale('player_id_desc'), required = true, min = 1}
                })
                
                if input then
                    TriggerServerEvent('rex-storage:server:addGuest', storageid, input[1])
                end
            end
        },
        {
            title = locale('remove_guest'),
            description = locale('remove_guest_desc'),
            icon = 'user-minus',
            iconColor = '#f44336',
            onSelect = function()
                if not guestList or #guestList == 0 then
                    lib.notify({title = locale('no_guests'), description = locale('no_guests_desc'), type = 'error', duration = 3000})
                    return
                end
                
                local removeOptions = {}
                for i, guest in ipairs(guestList) do
                    table.insert(removeOptions, {
                        title = guest.name,
                        description = locale('remove_access_desc'),
                        icon = 'user',
                        onSelect = function()
                            TriggerServerEvent('rex-storage:server:removeGuest', storageid, guest.citizenid)
                        end
                    })
                end
                
                lib.registerContext({
                    id = 'remove_guest_menu',
                    title = locale('remove_guest'),
                    menu = 'guest_management_menu',
                    options = removeOptions
                })
                
                lib.showContext('remove_guest_menu')
            end
        },
        {
            title = locale('view_guest_list'),
            description = locale('view_guest_list_desc'),
            icon = 'list',
            iconColor = '#2196F3',
            onSelect = function()
                if not guestList or #guestList == 0 then
                    lib.notify({title = locale('no_guests'), description = locale('no_guests_desc'), type = 'inform', duration = 3000})
                    return
                end
                
                local viewOptions = {}
                for i, guest in ipairs(guestList) do
                    table.insert(viewOptions, {
                        title = guest.name,
                        description = locale('guest'),
                        icon = 'user',
                        iconColor = '#4CAF50'
                    })
                end
                
                lib.registerContext({
                    id = 'view_guests_menu',
                    title = locale('guest_list')..' ('..#guestList..')',
                    menu = 'guest_management_menu',
                    options = viewOptions
                })
                
                lib.showContext('view_guests_menu')
            end
        }
    }
    
    lib.registerContext({
        id = 'guest_management_menu',
        title = locale('manage_guests'),
        menu = 'storage_main_menu',
        options = menuOptions
    })
    
    lib.showContext('guest_management_menu')
end)

---------------------------------------------
-- destroy storage
---------------------------------------------
RegisterNetEvent('rex-storage:client:destroystorage', function(storageentity, storageid)
    if isBusy then
        lib.notify({ title = locale('busy'), description = locale('busy_desc'), type = 'error', duration = 3000 })
        return
    end
    
    -- confirm destroy
    local alert = lib.alertDialog({
        header = locale('destroy_storage_confirm_header'),
        content = locale('destroy_storage_confirm_content'),
        centered = true,
        cancel = true,
        labels = {
            confirm = locale('destroy'),
            cancel = locale('cancel')
        }
    })

    if alert ~= 'confirm' then
        return
    end
    
    isBusy = true

    -- progress bar with animation
    local anim = `WORLD_HUMAN_CROUCH_INSPECT`
    TaskStartScenarioInPlace(cache.ped, anim, 0, true)
    
    local success = lib.progressBar({
        duration = Config.DestroyTime,
        position = 'bottom',
        useWhileDead = false,
        canCancel = true,
        disableControl = true,
        label = locale('dismantling_storage'),
    })
    
    ClearPedTasks(cache.ped)
    
    if not success then
        isBusy = false
        lib.notify({ title = locale('cancelled'), description = locale('storage_destruction_cancelled'), type = 'error', duration = 3000 })
        return
    end

    local storagecoords = GetEntityCoords(storageentity)
    local fxcoords = vector3(storagecoords.x, storagecoords.y, storagecoords.z)
    
    RequestNamedPtfxAsset(fx_group)
    while not HasNamedPtfxAssetLoaded(fx_group) do
        Wait(1)
    end
    
    UseParticleFxAsset(fx_group)
    local smoke = StartParticleFxNonLoopedAtCoord(fx_name, fxcoords, 0.0, 0.0, 0.0, fx_scale, false, false, false, true)
    
    TriggerServerEvent('rex-storage:server:destroyProp', storageid)
    isBusy = false
end)

---------------------------------------------
-- remove prop object
---------------------------------------------
RegisterNetEvent('rex-storage:client:removePropObject')
AddEventHandler('rex-storage:client:removePropObject', function(prop)
    for i = 1, #SpawnedProps do
        local o = SpawnedProps[i]

        if o.id == prop then
            SetEntityAsMissionEntity(o.obj, false)
            FreezeEntityPosition(o.obj, false)
            DeleteObject(o.obj)
        end
    end
end)

---------------------------------------------
-- update props
---------------------------------------------
RegisterNetEvent('rex-storage:client:updatePropData')
AddEventHandler('rex-storage:client:updatePropData', function(data)
    Config.PlayerProps = data
end)

---------------------------------------------
-- place prop
---------------------------------------------
RegisterNetEvent('rex-storage:client:placeNewProp')
AddEventHandler('rex-storage:client:placeNewProp', function(proptype, pHash, pos, heading)
    RSGCore.Functions.TriggerCallback('rex-storage:server:countprop', function(result)

        if result >= Config.MaxStorageBoxes then
            lib.notify({ 
                title = locale('limit_reached'), 
                description = locale('limit_reached_desc', Config.MaxStorageBoxes),
                type = 'error', 
                duration = 5000 
            })
            return
        end

        if CanPlacePropHere(pos) and not IsPedInAnyVehicle(PlayerPedId(), false) and not isBusy then
            isBusy = true
            local anim1 = `WORLD_HUMAN_CROUCH_INSPECT`
            FreezeEntityPosition(cache.ped, true)
            TaskStartScenarioInPlace(cache.ped, anim1, 0, true)
            
            lib.notify({ 
                title = locale('placing_storage'), 
                description = locale('placing_storage_desc'),
                type = 'inform', 
                duration = 3000 
            })
            
            local success = lib.progressBar({
                duration = 10000,
                position = 'bottom',
                useWhileDead = false,
                canCancel = true,
                disableControl = true,
                label = locale('setting_up_storage'),
            })
            
            ClearPedTasks(cache.ped)
            FreezeEntityPosition(cache.ped, false)
            isBusy = false
            
            if success then
                TriggerServerEvent('rex-storage:server:newProp', proptype, pos, heading, pHash)
            else
                lib.notify({ title = locale('cancelled'), description = locale('storage_placement_cancelled'), type = 'error', duration = 3000 })
            end
            return
        else
            lib.notify({ 
                title = locale('invalid_location'), 
                description = locale('invalid_location_desc'),
                type = 'error', 
                duration = 5000 
            })
        end

    end, proptype)

end)

---------------------------------------------
-- check to see if prop can be place here
---------------------------------------------
function CanPlacePropHere(pos)
    local canPlace = true

    if Config.TownsNotAlowed then
        local ZoneTypeId = 1
        local x,y,z =  table.unpack(GetEntityCoords(cache.ped))
        local town = Citizen.InvokeNative(0x43AD8FC02B429D33, x,y,z, ZoneTypeId)
        if town ~= false then
            canPlace = false
        end
    end

    for i = 1, #Config.PlayerProps do
        local checkprops = vector3(Config.PlayerProps[i].x, Config.PlayerProps[i].y, Config.PlayerProps[i].z)
        local dist = #(pos - checkprops)
        if dist < 1.3 then
            canPlace = false
        end
    end
    return canPlace
end

---------------------------------------------
-- clean up
---------------------------------------------
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for i = 1, #SpawnedProps do
        local props = SpawnedProps[i].obj
        SetEntityAsMissionEntity(props, false)
        FreezeEntityPosition(props, false)
        DeleteObject(props)
    end
end)
