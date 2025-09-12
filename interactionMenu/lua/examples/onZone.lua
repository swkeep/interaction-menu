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
                    url = 'http://127.0.0.1:8080/cdn/TEST%20VIDEO.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
            {
                label = '(collision) Launch Trojan Horse',
                icon = 'fa fa-code',
                action = function(data)
                    print("Action 'Launch Trojan Horse'")
                end
            },
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
                label = '(collision) Menu on sphere zone',
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
                label = '(collision) Menu on poly zone',
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

    local locations   = {
        vector3(787.51, -2993.77, -68.04),
        vector3(787.37, -2993.8, -68.67),
        vector3(787.37, -2993.8, -69.63)
    }

    for index, value in ipairs(locations) do
        exports['interactionMenu']:Create {
            position = value,
            tracker = "hit",
            zone = {
                type = 'circleZone',
                position = value,
                radius = 0.5,
                useZ = true,
                debugPoly = Config.debugPoly
            },
            options = {
                {
                    label = '(hit) Menu - > ' .. index,
                    icon = 'fa fa-code',
                    action = function(data)

                    end
                },

            }
        }
    end

    local locations_2 = {
        vector3(791.01, -2990.25, -69.59),
        vector3(791.03, -2990.25, -68.75),
        vector3(791.05, -2990.25, -67.97)
    }

    for index, value in ipairs(locations_2) do
        exports['interactionMenu']:Create {
            position = value,
            tracker = "hit",
            zone = {
                type = 'boxZone',
                position = value,
                heading = 0,
                width = 0.5,
                length = 0.5,
                debugPoly = Config.debugPoly,
                minZ = value.z - 0.3,
                maxZ = value.z + 0.3,
            },
            options = {
                {
                    label = '(hit) Test ->' .. index,
                    icon = 'fa fa-download',
                    action = function(data)
                        print("Action 'Download Classified Files'")
                    end
                }
            }
        }
    end

    exports['interactionMenu']:Create {
        position = vector3(796.38, -2998.15, -69.0),
        tracker = "hit",
        zone = {
            type = 'boxZone',
            position = vector3(796.38, -2998.15, -69.0),
            heading = 0,
            width = 0.5,
            length = 0.5,
            debugPoly = Config.debugPoly,
            minZ = vector3(796.38, -2998.15, -69.0).z - 1,
            maxZ = vector3(796.38, -2998.15, -69.0).z + 0.3,
        },
        options = {
            {
                label = 'Zone Confilict test',
                icon = 'fa fa-download',
                action = function(data)
                    print("Action 'Download Classified Files'")
                end
            }
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
    InternalRegisterTest(init, cleanup, "on_zone", "On Zones Test", "fa-solid fa-table-cells", "", {
        type = "dark-orange",
        label = "Feature"
    })
end)
