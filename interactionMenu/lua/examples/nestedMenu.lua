--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local positions = {
    vector4(794.00, -2997.10, -69.00, 0),
    vector4(799.00, -2997.10, -69.00, 0),
    vector4(806.50, -2997.10, -69.00, 0),

    vector4(794.54, -3002.94, -69.00, 180),
    vector4(801.04, -3002.94, -69.00, 180),
    vector4(806.04, -3002.94, -69.00, 180),
    vector4(808.54, -3002.94, -69.00, 180),

    vector4(794.00, -3008.70, -69.00, 180),
    vector4(799.00, -3008.70, -69.00, 180),
    vector4(804.00, -3008.70, -69.00, 180),
    vector4(809.00, -3008.70, -69.00, 180),
}
local menus = {}

local function init()
    local options = {
        {
            label = "Title",
        },
        {
            label = "Bind (Root/1)",
            bind = function()
                return "Random Number: " .. math.random(0, 100)
            end
        },
        {
            label = "Option 1 (Root/1)",
            icon = "fa fa-cogs",
            action = function()
                print("Option 1 action (Root/1)")
            end
        },
        {
            label = "Option 2 (Root/2)",
            icon = "fa fa-play",
            action = function()
                print("Option 2 action (Root/2)")
            end,
            subMenu = {
                {
                    video = {
                        url = 'https://cdn.swkeep.com/interaction_menu_internal_tests/test_video.mp4',
                        volume = 0,
                        currentTime = 100,
                        progress = true,
                        autoplay = true,
                        loop = true,
                        -- percent = true,
                        timecycle = true,
                    }
                },
                {
                    label = "SubOption 1 (Root/2/1)",
                    action = function()
                        print("SubOption 1 action (Root/2/1)")
                    end
                },
                {
                    label = "SubOption 2 (Root/2/2)",
                    action = function()
                        print("SubOption 2 action (Root/2/2)")
                    end,
                    subMenu = {
                        {
                            picture = {
                                url = 'https://cdn.swkeep.com/interaction_menu/preview_1.jpg'
                            }
                        },
                        {
                            label = "SubSubOption 1 (Root/2/2/1)",
                            action = function()
                                print("SubSubOption 1 action (Root/2/2/1)")
                            end
                        },
                        {
                            label = "SubSubOption 2 (Root/2/2/2)",
                            action = function()
                                print("SubSubOption 2 action (Root/2/2/2)")
                            end
                        },
                        {
                            label = "SubSubOption 3 (Root/2/2/3)",
                            action = function()
                                print("SubSubOption 3 action (Root/2/2/3)")
                            end,
                            subMenu = {
                                {
                                    label = "Health",
                                    icon = "fas fa-heartbeat",
                                    progress = {
                                        type = "error",
                                        value = 50,
                                        percent = true
                                    }
                                },
                                {
                                    label = "DeepOption 1 (Root/2/2/3/1)",
                                    action = function()
                                        print("DeepOption 1 action (Root/2/2/3/1)")
                                    end
                                },
                                {
                                    label = "DeepOption 2 (Root/2/2/3/2)",
                                    action = function()
                                        print("DeepOption 2 action (Root/2/2/3/2)")
                                    end
                                }
                            }
                        }
                    }
                },
                {
                    label = "SubOption 3 (Root/2/3)",
                    action = function()
                        print("SubOption 3 action (Root/2/3)")
                    end
                }
            }
        },
        {
            label = "Option 3 (Root/3)",
            icon = "fa fa-info-circle",
            action = function()
                print("Option 3 action (Root/3)")
            end
        }
    }

    for menu_index = 1, #positions, 1 do
        local pos = positions[menu_index]
        local rot = vector3(-20, 0, -90)

        options[1].label = "Menu: " .. menu_index

        menus[#menus + 1] = exports["interactionMenu"]:nestedMenu({
            position = pos,
            rotation = rot,
            scale = 1,
            width = '80%',
            zone = {
                type = "sphere",
                position = pos,
                radius = 1.5,
                useZ = true,
                debugPoly = Config.debugPoly
            },
            options = options
        })
    end
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end

    menus = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "nested_menu", "Nested Menu", "fa-solid fa-network-wired")
end)
