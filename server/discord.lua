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
                ['text'] = 'REX Storage System • ' .. os.date('%Y-%m-%d %H:%M:%S'),
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
        { name = '👤 Player', value = playerName, inline = true },
        { name = '🆔 Citizen ID', value = citizenid, inline = true },
        { name = '💻 Steam ID', value = steamid or 'N/A', inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false },
        { name = '📍 Location', value = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z), inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        '🟢 Storage Created',
        'A player has created a new storage box',
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
        { name = '👤 Player', value = playerName, inline = true },
        { name = '🆔 Citizen ID', value = citizenid, inline = true },
        { name = '💻 Steam ID', value = steamid or 'N/A', inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false },
        { name = '📍 Location', value = string.format('X: %.2f, Y: %.2f, Z: %.2f', coords.x, coords.y, coords.z), inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        '🔴 Storage Destroyed',
        'A player has destroyed their storage box',
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

    local accessType = isGuest and '(Guest Access)' or '(Owner)'
    local fields = {
        { name = '👤 Player', value = playerName, inline = true },
        { name = '🆔 Citizen ID', value = citizenid, inline = true },
        { name = '💻 Steam ID', value = steamid or 'N/A', inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false },
        { name = '👥 Access Type', value = accessType, inline = true }
    }

    if isGuest and ownerName then
        table.insert(fields, { name = '🏠 Storage Owner', value = ownerName, inline = true })
    end

    SendWebhook(
        Config.Discord.webhook,
        '🔵 Storage Accessed',
        'A player has opened a storage box',
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
        { name = '🏠 Owner', value = ownerName, inline = true },
        { name = '🆔 Owner ID', value = ownerCitizenid, inline = true },
        { name = '👤 Guest Added', value = guestName, inline = true },
        { name = '🆔 Guest ID', value = guestCitizenid, inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        '🟣 Guest Added',
        'A player has been granted access to a storage box',
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
        { name = '🏠 Owner', value = ownerName, inline = true },
        { name = '🆔 Owner ID', value = ownerCitizenid, inline = true },
        { name = '👤 Guest Removed', value = guestName, inline = true },
        { name = '🆔 Guest ID', value = guestCitizenid, inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        '🟠 Guest Removed',
        'A player has been removed from storage access',
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
        { name = '⚠️ Admin', value = adminName, inline = true },
        { name = '🆔 Admin ID', value = adminCitizenid, inline = true },
        { name = '💻 Steam ID', value = adminSteamid or 'N/A', inline = true },
        { name = '🏠 Storage Owner ID', value = ownerCitizenid, inline = true },
        { name = '📦 Storage ID', value = storageId, inline = false }
    }

    SendWebhook(
        Config.Discord.webhook,
        '🟠 Admin Storage Delete',
        '⚠️ An administrator has deleted a storage box',
        Config.Discord.colors.admin,
        fields
    )
end

print('[rex-storage] Discord webhook functions loaded successfully')
