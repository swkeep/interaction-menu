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

author "Swkeep#7049"

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
     'lua/client/menuContainer.lua',
     'lua/client/interact.lua',

     -- examples / tests
     'lua/examples/*.lua'
}

server_script {}

lua54 'yes'
