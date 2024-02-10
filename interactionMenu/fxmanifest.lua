--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

fx_version 'cerulean'
games { 'gta5' }

name 'interactionMenu'
description 'A standalone raycast-based interaction menu for FiveM'
version '0.1.4'
author "swkeep"
repository 'https://github.com/swkeep/interaction-menu'

shared_scripts {
     'config.shared.lua'
}

client_script {
     '@PolyZone/client.lua',
     '@PolyZone/BoxZone.lua',
     '@PolyZone/EntityZone.lua',
     '@PolyZone/CircleZone.lua',
     '@PolyZone/ComboZone.lua',

     --
     'lua/frameworks/qb/client.lua',
     --

     'lua/client/util.lua',
     'lua/client/3dDuiMaker.lua',
     'lua/client/menuContainer.lua',
     'lua/client/interact.lua',

     -- examples / tests
     'lua/examples/*.lua'
}

server_script {
     'lua/server/server.lua'
}

lua54 'yes'
