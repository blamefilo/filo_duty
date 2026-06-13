fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'filo_duty'
author 'filo studios.'
discord 'https://discord.gg/bErPEKvRXg'
description 'Duty interaction points creator script by filo studios.'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/sh-*.lua',
}

server_scripts {
    'server/sv-*.lua'
}

client_scripts {
    'client/cl-*.lua'
}

escrow_ignore {
    'data/*',
}

files {
    'data/*',
}

dependencies {
    'community_bridge',
}