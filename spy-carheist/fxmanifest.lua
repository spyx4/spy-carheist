-- fxmanifest.lua
fx_version 'cerulean'
game 'gta5'

author 'spy5919'
description 'Car Theft Mission Script'
version '1.2.0'

server_scripts {
    '@qb-core/shared/locale.lua',
    '@mysql-async/lib/MySQL.lua',
    'server.lua'
}

client_scripts {
    '@qb-core/shared/locale.lua',
    'client.lua'
}

dependencies {
    'qb-core',
    'qb-target'
}
