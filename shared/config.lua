Config = Config or {}
Config.PlayerProps = {}

---------------------------------------------
-- deploy prop settings
---------------------------------------------
Config.ForwardDistance = 1.5
Config.PromptGroupName = 'Place Storage'
Config.PromptCancelName = 'Cancel'
Config.PromptPlaceName = 'Place'
Config.PromptRotateLeft = 'Rotate Left'
Config.PromptRotateRight = 'Rotate Right'

---------------------------------------------
-- settings
---------------------------------------------
Config.EnableVegModifier = true -- if set true clears vegetation
Config.StorageMaxWeight  = 4000000 -- max weight the storage can hold
Config.StorageMaxSlots   = 100 -- number of slots per storage
Config.DestroyTime       = 10000 -- how long for destroy proccess bar
Config.MaxStorageBoxes   = 4 -- amount of stashes a character can have
Config.StorageProp       = 's_re_rcboatbox01x' -- prop used for storage
Config.TownsNotAlowed    = false -- set to true if you want to restrict from plaing in towns

---------------------------------------------
-- blip settings
---------------------------------------------
Config.Blip = {
    blipName = 'Storage Box',
    blipSprite = 'blip_chest',
    blipScale = 0.2,
    blipColour = 'BLIP_MODIFIER_MP_COLOR_6'
}

---------------------------------------------
-- discord webhook settings
---------------------------------------------
Config.Discord = {
    enabled = true, -- enable/disable discord webhooks
    webhook = '', -- your discord webhook URL
    botName = 'REX Storage Logs',
    botAvatar = 'https://i.imgur.com/your-image.png', -- optional bot avatar URL
    logEvents = {
        storageCreate = true,   -- log when storage is created
        storageDestroy = true,  -- log when storage is destroyed
        storageAccess = true,   -- log when storage is accessed
        guestAdd = true,        -- log when guest is added
        guestRemove = true,     -- log when guest is removed
        adminDelete = true      -- log when admin deletes storage
    },
    colors = {
        create = 3066993,    -- green
        destroy = 15158332,  -- red
        access = 3447003,    -- blue
        guest = 10181046,    -- purple
        admin = 15105570     -- orange
    }
}
