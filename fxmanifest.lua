fx_version 'cerulean'
game 'gta5'

name 'clothing-system'
description 'Advanced Item-Based Clothing System for FiveM (QB-Core) with Multi-Store Support & React UI'
author 'Your Name'
version '1.0.0'

ui_page 'web-ui/build/index.html'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'config.lua'
}

client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/CircleZone.lua',
    'client/main.lua',
    'client/events.lua',
    'client/commands.lua',
    'client/functions.lua',
    'client/stores.lua',
    'client/wardrobe.lua',
    'client/laundromats.lua',
    'client/tailors.lua',
    'client/nui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua',
    'server/commands.lua',
    'server/functions.lua',
    'server/stores.lua',
    'server/wardrobe.lua',
    'server/laundromats.lua',
    'server/tailors.lua'
}

files {
    'web-ui/build/index.html',
    'web-ui/build/**/*'
}

dependencies {
    'qb-core',
    'oxmysql',
    'ox_inventory'
}

lua54 'yes' 