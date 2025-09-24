fx_version 'cerulean'
game 'gta5'

name 'enge-pedmenu'
author 'Engetsu'
description 'Per-player ped whitelist via Discord ID for illenium-appearance (QBCore + ox_lib menu + okokNotify)'
version '1.1.1'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    '@ox_lib/init.lua',
    'config.lua',
    'peds.lua'
}

server_scripts {
    'server.lua'
}

client_scripts {
    'client.lua'
}
