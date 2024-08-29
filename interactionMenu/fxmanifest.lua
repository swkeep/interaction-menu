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
description 'A standalone raycast and world based interaction menu for FiveM'
version '1.0.0'
author "swkeep"
repository 'https://github.com/swkeep/interaction-menu'

shared_scripts {
     'config.shared.lua',
}

client_script {
     -- ox_lib
     -- '@ox_lib/init.lua',
     -- PolyZone
     '@PolyZone/client.lua',
     '@PolyZone/BoxZone.lua',
     '@PolyZone/CircleZone.lua',
     '@PolyZone/ComboZone.lua',

     -- bridges
     'lua/bridge/main.lua',

     -- core
     'lua/client/util.lua',
     'lua/client/3dDuiMaker.lua',
     'lua/client/menuContainer.lua',
     'lua/client/userInputManager.lua',
     'lua/client/interact.lua',
     'lua/client/drawIndicator.lua',
     'lua/client/garbageCollector.lua',

     -- providers
     'lua/providers/qb-target.lua',
     'lua/providers/qb-target_test.lua',

     -- examples / tests
     'lua/examples/*.lua',
}

server_script {
     'lua/server/server.lua'
}

files {
     'lua/client/icons/*.*',
     'lua/bridge/qb.lua',
}

provide 'qb-target'

lua54 'yes'
