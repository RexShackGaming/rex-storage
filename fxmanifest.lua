fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

description 'rex-storage'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/client.lua',
    'client/placeprop.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/discord.lua',
    'server/server.lua'
}

dependencies {
    'rsg-core',
    'ox_lib',
}

files {
  'locales/*.json'
}

lua54 'yes'
