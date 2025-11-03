# Discord Webhook Setup Guide

## Overview
The rex-storage script now includes a comprehensive Discord webhook logging system that tracks storage-related activities on your RedM server.

## Features
The Discord webhook system logs the following events:
- 🟢 **Storage Creation** - When players create new storage boxes
- 🔴 **Storage Destruction** - When players destroy their storage boxes
- 🔵 **Storage Access** - When players open storage boxes (owner or guest)
- 🟣 **Guest Management** - When guests are added or removed from storage
- 🟠 **Admin Actions** - When admins delete storage boxes

## Configuration

### Step 1: Create a Discord Webhook
1. Open your Discord server
2. Go to Server Settings → Integrations → Webhooks
3. Click "New Webhook"
4. Name it (e.g., "REX Storage Logs")
5. Select the channel where logs should be posted
6. Copy the webhook URL

### Step 2: Configure rex-storage
Open `config.lua` and find the Discord settings section:

```lua
Config.Discord = {
    enabled = true, -- enable/disable discord webhooks
    webhook = '', -- paste your discord webhook URL here
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
```

### Step 3: Paste Your Webhook URL
Replace the empty `webhook` value with your Discord webhook URL:

```lua
webhook = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN',
```

### Step 4: Customize Settings (Optional)

#### Enable/Disable Logging
Set `enabled = false` to disable all Discord logging:
```lua
enabled = false,
```

#### Toggle Individual Events
Disable specific events by setting them to `false`:
```lua
logEvents = {
    storageCreate = true,
    storageDestroy = true,
    storageAccess = false,  -- Disable access logs
    guestAdd = true,
    guestRemove = true,
    adminDelete = true
}
```

#### Customize Bot Appearance
Change the bot name and avatar:
```lua
botName = 'My Custom Logger',
botAvatar = 'https://i.imgur.com/my-custom-image.png',
```

#### Customize Embed Colors
Modify the color values (decimal color codes):
```lua
colors = {
    create = 3066993,    -- green
    destroy = 15158332,  -- red
    access = 3447003,    -- blue
    guest = 10181046,    -- purple
    admin = 15105570     -- orange
}
```

## Log Information

Each webhook message includes detailed information:

### Storage Creation
- Player name
- Citizen ID
- Steam ID
- Storage ID
- Location coordinates

### Storage Destruction
- Player name
- Citizen ID
- Steam ID
- Storage ID
- Location coordinates

### Storage Access
- Player name
- Citizen ID
- Steam ID
- Storage ID
- Access type (Owner/Guest)
- Owner name (if guest access)

### Guest Management
- Owner name and ID
- Guest name and ID
- Storage ID

### Admin Actions
- Admin name and IDs
- Storage owner ID
- Storage ID

## Troubleshooting

### Webhooks Not Sending
1. Verify `enabled = true` in config.lua
2. Check that the webhook URL is correct
3. Ensure the Discord channel exists and webhook is active
4. Check server console for error messages

### Selective Logging
If you only want certain events logged, set unwanted events to `false` in the `logEvents` table.

### Testing
To test the webhook:
1. Start your server
2. Create a storage box in-game
3. Check your Discord channel for the log message

## Security Note
⚠️ **Never share your webhook URL publicly** - anyone with the URL can send messages to your Discord channel.

## Support
If you encounter issues with the Discord webhook system, check your server console for error messages starting with `[rex-storage]`.
