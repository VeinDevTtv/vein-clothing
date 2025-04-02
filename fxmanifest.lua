fx_version 'cerulean'
game 'gta5'

author 'Your Name'
description 'Item-Based Clothing System for QB-Core'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'locales/*.lua',
    'config.lua'
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
    'html/fonts/*.ttf',
    'html/img/*.png',
    'html/img/*.jpg'
}

lua54 'yes'

dependency 'qb-core'
dependency 'oxmysql' 