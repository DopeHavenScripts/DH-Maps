fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'DH Scripts'
name 'dh-maps'
description 'Custom map marker system with paper map item, configurable markers, and UI integration.'
version '1.0.0'

shared_scripts {'shared/config.lua'}
client_scripts {'client/main.lua'}
server_scripts {'server/main.lua'}

ui_page 'html/index.html'

files {
    'html/index.html'
}

escrow_ignore { 
    'shared/config.lua',
    'html/index.html'
} 