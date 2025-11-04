lib.locale()
---------------------------------------------
-- Discord Webhook Utility
-- Handles all Discord webhook logging
---------------------------------------------

print('[rex-storage] Loading Discord webhook module...')

local function SendWebhook(webhook, title, description, color, fields)
    if not Config.Discord.enabled or not Config.Discord.webhook or Config.Discord.webhook == '' then
        return
    end

    local embed = {
        {
            ['title'] = title,
            ['description'] = description,
            ['color'] = color or Config.Discord.colors.access,
            ['fields'] = fields or {},
            ['footer'] = {
                ['text'] = locale('discord_footer', os.date('%Y-%m-%d %H:%M:%S')),
            },
        }
    }

    local payload = json.encode({
        username = Config.Discord.botName,
        avatar_url = Config.Discord.botAvatar,
        embeds = embed
    })

    PerformHttpRequest(Config.Discord.webhook, function(err, text, headers)
        -- 200 and 204 are both success codes from Discord
        if err ~= 200 and err ~= 204 then
            print('[rex-storage] Discord webhook error: ' .. tostring(err))
        end
    end, 'POST', payload, { ['Content-Type'] = 'application/json' })
end

---------------------------------------------
-- Storage Created Log
---------------------------------------------
function DiscordLog_StorageCreated(playerName, citizenid, steamid, storageId, coords)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.storageCreate then return end

    local fields = {
        { name = locale('discord_field_player'), value = playerName, inline = true },
        { name = locale('discord_field_citizenid'), value = citizenid, inline = true },
        { name = locale('discord_field_steamid'), value = steamid or locale('discord_na'), inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false },
        { name = locale('discord_field_location'), value = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z), inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_storage_created_title'),
        locale('discord_storage_created_desc'),
        Config.Discord.colors.create,
        fields
    )
end

---------------------------------------------
-- Storage Destroyed Log
---------------------------------------------
function DiscordLog_StorageDestroyed(playerName, citizenid, steamid, storageId, coords)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.storageDestroy then return end

    local fields = {
        { name = locale('discord_field_player'), value = playerName, inline = true },
        { name = locale('discord_field_citizenid'), value = citizenid, inline = true },
        { name = locale('discord_field_steamid'), value = steamid or locale('discord_na'), inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false },
        { name = locale('discord_field_location'), value = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z), inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_storage_destroyed_title'),
        locale('discord_storage_destroyed_desc'),
        Config.Discord.colors.destroy,
        fields
    )
end

---------------------------------------------
-- Storage Accessed Log
---------------------------------------------
function DiscordLog_StorageAccessed(playerName, citizenid, steamid, storageId, ownerName, isGuest)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.storageAccess then return end

    local accessType = isGuest and locale('discord_access_type_guest') or locale('discord_access_type_owner')
    local fields = {
        { name = locale('discord_field_player'), value = playerName, inline = true },
        { name = locale('discord_field_citizenid'), value = citizenid, inline = true },
        { name = locale('discord_field_steamid'), value = steamid or locale('discord_na'), inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false },
        { name = locale('discord_field_access_type'), value = accessType, inline = true }
    }

    if isGuest and ownerName then
        table.insert(fields, { name = locale('discord_field_storage_owner'), value = ownerName, inline = true })
    end

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_storage_accessed_title'),
        locale('discord_storage_accessed_desc'),
        Config.Discord.colors.access,
        fields
    )
end

---------------------------------------------
-- Guest Added Log
---------------------------------------------
function DiscordLog_GuestAdded(ownerName, ownerCitizenid, guestName, guestCitizenid, storageId)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.guestAdd then return end

    local fields = {
        { name = locale('discord_field_owner'), value = ownerName, inline = true },
        { name = locale('discord_field_owner_id'), value = ownerCitizenid, inline = true },
        { name = locale('discord_field_guest_added'), value = guestName, inline = true },
        { name = locale('discord_field_guest_id'), value = guestCitizenid, inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_guest_added_title'),
        locale('discord_guest_added_desc'),
        Config.Discord.colors.guest,
        fields
    )
end

---------------------------------------------
-- Guest Removed Log
---------------------------------------------
function DiscordLog_GuestRemoved(ownerName, ownerCitizenid, guestName, guestCitizenid, storageId)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.guestRemove then return end

    local fields = {
        { name = locale('discord_field_owner'), value = ownerName, inline = true },
        { name = locale('discord_field_owner_id'), value = ownerCitizenid, inline = true },
        { name = locale('discord_field_guest_removed'), value = guestName, inline = true },
        { name = locale('discord_field_guest_id'), value = guestCitizenid, inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_guest_removed_title'),
        locale('discord_guest_removed_desc'),
        Config.Discord.colors.guest,
        fields
    )
end

---------------------------------------------
-- Admin Delete Log
---------------------------------------------
function DiscordLog_AdminDelete(adminName, adminCitizenid, adminSteamid, ownerCitizenid, storageId)
    if not Config or not Config.Discord then return end
    if not Config.Discord.logEvents.adminDelete then return end

    local fields = {
        { name = locale('discord_field_admin'), value = adminName, inline = true },
        { name = locale('discord_field_admin_id'), value = adminCitizenid, inline = true },
        { name = locale('discord_field_steamid'), value = adminSteamid or locale('discord_na'), inline = true },
        { name = locale('discord_field_storage_owner_id'), value = ownerCitizenid, inline = true },
        { name = locale('discord_field_storageid'), value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        locale('discord_admin_delete_title'),
        locale('discord_admin_delete_desc'),
        Config.Discord.colors.admin,
        fields
    )
end

print('[rex-storage] Discord webhook functions loaded successfully')
