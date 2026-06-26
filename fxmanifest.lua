fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'filo_bolt'
author 'filo studios.'
discord 'https://discord.gg/bErPEKvRXg'
description 'A bolt minigame'
version '1.0.1'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/sh-config.lua'
}

server_scripts {
    "server/sv-version.lua",
}

client_scripts {
    "client/cl-init.lua",
    "client/cl-raycast.lua",
    "client/cl-camera.lua",
    "client/cl-sound.lua",
    "client/cl-bolt.lua",
    "client/cl-main.lua",
}

files {
    'data/filo_bolt_data_sounds.dat54.rel',
    'audiodirectory/filo_bolt_sounds.awc'
}

data_file 'AUDIO_WAVEPACK' 'audiodirectory'
data_file 'AUDIO_SOUNDDATA' 'data/filo_bolt_data_sounds.dat'
data_file 'DLC_ITYP_REQUEST' 'stream/filo_bolt.ytyp'
