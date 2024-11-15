--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
if not DEVMODE then return end
local menus = {}

local function create_debug_global(type, label, icon, action)
    menus[#menus + 1] = exports['interactionMenu']:createGlobal {
        type = type,
        offset = vec3(0, 0, 0),
        maxDistance = 1.0,
        options = {
            {
                label = label,
                icon = icon,
                action = action
            }
        }
    }
end

local function init()
    create_debug_global('entities', '[Debug] On All Entities', 'fa fa-bug', function(entity)
        print(entity)
    end)
    create_debug_global('peds', '[Debug] On All Peds', 'fa fa-person', function(entity)
        print(entity)
    end)
    create_debug_global('vehicles', '[Debug] On All Vehicles', 'fa fa-car', function(entity)
        print(entity)
    end)
    create_debug_global('players', '[Debug] On All Players', 'fa fa-person', function(entity)
        print(entity)
    end)

    menus[#menus + 1] = exports['interactionMenu']:createGlobal {
        type = 'bones',
        bone = 'platelight',
        options = {
            {
                label = '[Debug] On All plates',
                icon = 'fa fa-rectangle-ad',
                action = function(entity)
                    print('Plate:', GetVehicleNumberPlateText(entity))
                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:createGlobal {
        type = 'zones',
        options = {
            {
                label = '[Debug] On All Zones',
                icon = 'fa fa-person',
                action = function(data)
                    Util.print_table(data)
                end
            }
        }
    }
end

local function cleanup()
    for index, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    menus = {}
end

CreateThread(function()
    InternalRegisterGlobalTest(init, cleanup, "global_menus", "Toggle Global Menus")
end)
