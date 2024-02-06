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

name 'interactionDUI'
description 'Dui helper of interacion menu'
version '1.0.0'
author "swkeep"
repository 'https://github.com/swkeep/interaction-menu'

shared_scripts {}

client_script {
     'core.client.lua'
}

files {
     "dui/*.*",
}

lua54 'yes'
