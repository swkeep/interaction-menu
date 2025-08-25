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
local positions = {
    vector4(794.00, -2997.10, -70.00, 0),
    vector4(796.50, -2997.10, -70.00, 0),
    vector4(799.00, -2997.10, -70.00, 0),
    vector4(801.50, -2997.10, -70.00, 0),
    vector4(804.00, -2997.10, -70.00, 0),
    vector4(806.50, -2997.10, -70.00, 0),
    vector4(809.00, -2997.10, -70.00, 0),

    vector4(794.54, -3002.94, -70.00, 180),
    vector4(798.54, -3002.94, -70.00, 180),
    vector4(801.04, -3002.94, -70.00, 180),
    vector4(803.54, -3002.94, -70.00, 180),
    vector4(806.04, -3002.94, -70.00, 180),
    vector4(808.54, -3002.94, -70.00, 180),

    vector4(794.00, -3008.70, -70.00, 180),
    vector4(796.50, -3008.70, -70.00, 180),
    vector4(799.00, -3008.70, -70.00, 180),
    vector4(801.50, -3008.70, -70.00, 180),
    vector4(804.00, -3008.70, -70.00, 180),
    vector4(806.50, -3008.70, -70.00, 180),
    vector4(809.00, -3008.70, -70.00, 180),
}

local menus = {}
local function init()
    local names = { "Alice", "Bob", "Charlie", "David", "Eva", "Frank" }

    for i = 1, 10, 1 do
        local options = {}

        for index = 1, math.random(2, 15), 1 do
            -- Select a random name from the list
            local randomName = names[math.random(1, #names)]
            options[#options + 1] = {
                icon   = "fas fa-sign-in-alt",
                label  = randomName,
                action = function()
                    Wait(5000)
                    print(randomName)
                end
            }
        end

        menus[#menus + 1] = exports['interactionMenu']:Create {
            type = 'position',
            position = positions[i],
            options = options,
            maxDistance = 2.0,
            extra = {
                onSeen = function()
                    print('seen')
                end
            }
        }
    end

    for i = 1, 15, 1 do
        menus[i] = exports['interactionMenu']:Create({
            theme = 'theme-2',
            position = vector3(794.58, -3009.07, -69.0),
            extra = {
                onSeen = function()
                    print(('seen menu id [%s]'):format(menus[i]))
                end
            },
            options = {
                {
                    label = ('Menu #[%s]'):format(i),
                    action = function()
                        exports['interactionMenu']:remove(menus[i])
                    end
                }
            }
        })
    end

    -- SetTimeout(4000, function()
    --     exports['interactionMenu']:set {
    --         menuId = menus[1],
    --         type = 'position',
    --         value = positions[11]
    --     }
    -- end)
end

local function cleanup()
    for index, value in ipairs(menus) do
        exports['interactionMenu']:remove(value)
    end

    menus = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "on_position", "On Locations", "fa-solid fa-location-dot")
end)
