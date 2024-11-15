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
local menus    = {}
local position = vector4(795.27, -2996.99, -69.41, 89.63)

local function init()
    position          = vector4(795.27, -2996.99, -69.41, 89.63)
    menus[#menus + 1] = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 240),
        position = position,
        scale = 1,
        zone = {
            type = 'boxZone',
            position = position,
            heading = position.w,
            width = 4.0,
            length = 4.0,
            debugPoly = Config.debugPoly,
            minZ = position.z - 1,
            maxZ = position.z + 2,
        },
        options = {
            {
                video = {
                    url = 'https://cdn.swkeep.com//interaction_menu_internal_tests/test_video.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
            {
                label = 'Launch Trojan Horse',
                icon = 'fa fa-code',
                action = function(data)
                    print("Action 'Launch Trojan Horse'")
                end
            },
            {
                label = 'Disable Security Cameras',
                icon = 'fa fa-video-slash',
                action = function(data)
                    print("Action 'Disable Security Cameras'")
                end
            },
            {
                label = 'Override Access Control',
                icon = 'fa fa-key',
                action = function(data)
                    print("Action 'Override Access Control'")
                end
            },
            {
                label = 'Download Classified Files',
                icon = 'fa fa-download',
                action = function(data)
                    print("Action 'Download Classified Files'")
                end
            }
        }
    }

    position          = vector4(794.48, -3002.87, -69.41, 90.68)
    menus[#menus + 1] = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 270),
        position = position,
        scale = 1,
        zone = {
            type = 'circleZone',
            position = position,
            radius = 2.0,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        options = {
            {
                label = 'Menu on sphere zone',
                icon = 'fa fa-code',
                action = function(data)

                end
            },
            {
                video = {
                    url = 'https://cdn.swkeep.com//interaction_menu_internal_tests/test_video.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 240),
        position = vector3(796.56, -3008.69, -69.0),
        scale = 1,
        zone = {
            type = 'polyZone',
            points = {
                vector3(792.42, -3009.89, -69.0),
                vector3(792.26, -3007.18, -69.0),
                vector3(796.56, -3008.69, -69.0)
            },
            minZ = position.z - 1,
            maxZ = position.z + 1,
            debugPoly = Config.debugPoly,
        },
        options = {
            {
                label = 'Menu on poly zone',
                icon = 'fa fa-code',
                action = function(data)

                end
            },
            {
                video = {
                    url = 'https://cdn.swkeep.com//interaction_menu_internal_tests/test_video.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
        }
    }

    -- menus[#menus + 1] = exports['interactionMenu']:Create {
    --     rotation = vector3(0, 0, 180),
    --     position = vector4(808.0, -3011.99, -68.0, 2.82),
    --     scale = 2,
    --     zone = {
    --         type = 'comboZone',
    --         zones = {
    --             {
    --                 type = 'circleZone',
    --                 position = vector4(806.9, -3008.61, -69.41, 90.29),
    --                 radius = 1.0,
    --                 useZ = true,
    --                 debugPoly = Config.debugPoly
    --             },
    --             {
    --                 type = 'circleZone',
    --                 position = vector4(806.89, -3003.05, -69.41, 89.71),
    --                 radius = 1.0,
    --                 useZ = true,
    --                 debugPoly = Config.debugPoly
    --             },
    --         },
    --     },
    --     options = {
    --         {
    --             video = {
    --                 url = 'https://cdn.swkeep.com//interaction_menu_internal_tests/test_video.mp4',
    --                 loop = true,
    --                 autoplay = true,
    --                 volume = 0.1
    --             }
    --         },
    --     }
    -- }
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end

    menus = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "on_zone", "On Zones Test", "fa-solid fa-table-cells")
end)
