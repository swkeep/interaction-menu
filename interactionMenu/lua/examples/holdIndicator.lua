--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local menu_id = nil
local position = vector4(794.48, -3002.87, -69.41, 90.68)

local function init()
    menu_id = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 270),
        position = vector4(795.0, -3002.15, -69.41, 90.68),
        scale = 1,
        -- theme = 'box',
        indicator = {
            prompt = 'Hold "E"',
            hold = 1000,
        },
        zone = {
            type = 'boxZone',
            position = position,
            heading = position.w,
            width = 2.0,
            length = 2.0,
            debugPoly = Config.debugPoly,
            minZ = position.z - 1,
            maxZ = position.z + 2,
        },
        options = {
            {
                label = 'Back',
                icon = 'fa fa-arrow-left',
                action = function()
                end
            },
            {
                label = 'Stop',
                icon = 'fa fa-stop',
                action = function()
                end
            }
        }
    }
end

local function cleanup()
    if not menu_id then return end
    exports['interactionMenu']:remove(menu_id)
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "hold_indicator", "Hold Indicator", "fa-solid fa-stopwatch-20")
end)
