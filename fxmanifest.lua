fx_version 'cerulean'
game 'gta5'

author 'Vein Development'
description 'Advanced Item-Based Clothing System for QB-Core with Condition System, Multi-Store Support, and Modern UI'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/*.lua',
    'config.lua',
    'shared/items.lua'
}

client_scripts {
    'client/main.lua',
    'client/events.lua',
    'client/nui.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/events.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    -- 'html/fonts/*.ttf',
    'html/img/*.png',
    'html/img/*.jpg',
    'html/img/*.svg'
}

lua54 'yes'

dependencies {
    'qb-core',
    'oxmysql',
    'ox_lib',
    'qb-target'
}

escrow_ignore {
    'config.lua',
    'locales/*.lua',
    'client/*.lua',
    'server/*.lua',
    'html/*'
} 