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
    -- vector4(794.00, -2991.52, -70.0, 0),
    -- vector4(796.50, -2991.52, -70.0, 0),
    -- vector4(799.00, -2991.52, -70.0, 0),
    -- vector4(801.50, -2991.52, -70.0, 0),
    -- vector4(804.00, -2991.52, -70.0, 0),
    -- vector4(806.50, -2991.52, -70.0, 0),
    -- vector4(809.00, -2991.52, -70.0, 0),

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

-----------------------------
-- onEntity
-----------------------------

local menu_ids = {}
local entities = {}

-- variables
local carryingBox = false
local isDigging = false
--

local menus = {
    {
        model = "prop_vend_snak_01",
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        icon = 'vending',
        extra = {
            onSeen = function()
                print('entity on seen')
            end,
            onExit = function()
                print('entity on exit')
            end
        },
        options = {
            {
                label = 'Using Event (client)',
                icon = 'fa fa-server',
                event = {
                    type = 'client',
                    name = 'testEvent:client',
                    payload = { 1, 2, 3 }
                }
            },
            {
                label = 'Using Event (server)',
                icon = 'fa fa-server',
                event = {
                    type = 'server',
                    name = 'testEvent:server',
                    payload = { 1, 2, 3 }
                }
            },
            {
                label = 'Using Action',
                icon = 'fa fa-cogs',
                action = function(e)
                    print(e, 'nothing')
                end
            },
        }
    },
    {
        model = "h4_prop_h4_board_01a",
        suppressGlobals = true,
        icon = 'vending',
        offset = vec3(0, 0, 1),
        options = {
            {
                label = 'Check Job Status'
            },
            {
                label = 'Start Job',
                event = {
                    name = 'startJob',
                    payload = {
                        jobType = 'delivery',
                        location = 'Los Santos',
                        difficulty = 'normal'
                    }
                }
            },
            {
                label = 'Cancel Job',
                event = {
                    name = 'cancelJob',
                    payload = {
                        jobID = 12345
                    }
                }
            },
            {
                label = 'Report Issue',
                event = {
                    name = 'reportIssue',
                    payload = {
                        issueType = 'bug',
                        description = 'I encountered a problem during the job.'
                    }
                }
            },
            {
                label = 'Job Completed',
                event = {
                    name = 'jobCompleted',
                    payload = {
                        reward = '$10,000',
                        experience = 150
                    }
                }
            },
            {
                label = 'Request Support',
                event = {
                    name = 'requestSupport',
                    payload = 'I need assistance with my current job.'
                }
            },
            {
                label = 'Pause/Resume Job',
                event = {
                    name = 'pauseResumeJob',
                    payload = 'pause'
                }
            },
            {
                label = 'Quit Job',
                action = function()
                    print('Quitting current job...')
                end
            }
        }
    },
    {
        model = "prop_washer_02",
        suppressGlobals = true,
        options = {
            {
                label = 'Money Wash Tutorial',
                video = {
                    url = 'https://cdn.swkeep.com/interaction_menu_internal_tests/test_video.mp4',
                    currentTime = 0,
                    autoplay = true,
                    volume = 0.0,
                    loop = false,
                    opacity = 0.6
                }
            },
            {
                label = 'Start Money Wash',
                icon = 'fas fa-money-bill-wave',
                event = {
                    name = 'StartMoneyWash',
                    payload = {
                        amount = 1000
                    }
                }
            },
            {
                label = 'Check Money Wash Progress',
                icon = 'fas fa-spinner',
                event = {
                    name = 'CheckWashProgress'
                }
            },
            {
                label = 'Cancel Money Wash',
                icon = 'fas fa-ban',
                event = {
                    name = 'CancelMoneyWash'
                }
            }
        }
    },
    {
        model = "prop_vend_snak_01",
        suppressGlobals = true,
        icon = 'vending',
        indicator = {
            prompt = 'Press E',
            glow = true
        },
        extra = {
            onTrigger = function()
                print('on trigger')
            end
        }
    },
    {
        model = 'p_rail_controller_s',
        width = "100%",
        options = {
            {
                label = 'Width Test',
            },
            {
                label = 'Increase Speed',
                icon = 'fas fa-angle-double-up',
                event = {
                    name = 'AdjustRailSpeed',
                    payload = {
                        adjustment = 'increase',
                        increment = 5
                    }
                }
            },
            {
                label = 'Decrease Speed',
                icon = 'fas fa-angle-double-down',
                event = {
                    name = 'AdjustRailSpeed',
                    payload = {
                        adjustment = 'decrease',
                        increment = 5
                    }
                }
            },
            {
                label = 'Emergency Stop',
                icon = 'fas fa-exclamation-triangle',
                event = {
                    name = 'EmergencyStopRail',
                    payload = {
                        immediate = true
                    }
                }
            }
        }
    },
    {
        model = 'bkr_prop_fakeid_papercutter',
        options = {
            {
                label = 'Just A Text'
            }
        }
    },
    {
        model = 'bkr_prop_fakeid_papercutter',
        options = {
            {
                label = 'Print Random Numbers',
                action = function()
                    print(math.random(0, 100))
                end
            },

        }
    },
    {
        model = 'p_rail_controller_s',
        options = {
            {
                picture = {
                    url = 'https://cdn.swkeep.com/interaction_menu/preview_2.jpg'
                }
            }
        }
    },
    {
        model = 'v_ret_fh_kitchtable',
        icon = 'stove',
        options = {
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
            -- ensure to verify the payload server-side
            {
                label = 'Burger',
                icon = 'fas fa-hamburger',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Burger',
                        ingredients = { 'Beef Patty', 'Lettuce', 'Tomato', 'Bun' },
                        cookTime = 10, -- in seconds
                        price = 15
                    }
                }
            },
            {
                label = 'Pizza',
                icon = 'fas fa-pizza-slice',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Pizza',
                        ingredients = { 'Dough', 'Tomato Sauce', 'Cheese', 'Pepperoni' },
                        cookTime = 15, -- in seconds
                        price = 20
                    }
                }
            },
            {
                label = 'Salad',
                icon = 'fas fa-leaf',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Salad',
                        ingredients = { 'Lettuce', 'Tomato', 'Cucumber', 'Dressing' },
                        cookTime = 8, -- in seconds
                        price = 10
                    }
                }
            },
            {
                label = 'Sushi',
                icon = 'fas fa-fish',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Sushi',
                        ingredients = { 'Rice', 'Fish', 'Seaweed', 'Soy Sauce' },
                        cookTime = 12, -- in seconds
                        price = 25
                    }
                }
            },
            {
                label = 'Pasta',
                icon = 'fas fa-utensils',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Pasta',
                        ingredients = { 'Pasta', 'Tomato Sauce', 'Parmesan', 'Basil' },
                        cookTime = 18, -- in seconds
                        price = 18
                    }
                }
            },
            {
                label = 'Cupcake',
                icon = 'fas fa-birthday-cake',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Cupcake',
                        ingredients = { 'Flour', 'Sugar', 'Egg', 'Frosting' },
                        cookTime = 8, -- in seconds
                        price = 12
                    }
                }
            },
            {
                label = 'Omelette',
                icon = 'fas fa-egg',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Omelette',
                        ingredients = { 'Eggs', 'Cheese', 'Mushrooms', 'Spinach' },
                        cookTime = 10, -- in seconds
                        price = 14
                    }
                }
            },
            -- #TODO: Ahmm it might be usefull to have a picture as icon!
            {
                label = 'Steak',
                icon = 'fas fa-drumstick-bite',
                picture = {
                    url = 'http://127.0.0.1:8080/steak_PNG4.png',
                    width = '5rem'
                },
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Steak',
                        ingredients = { 'Beef Steak', 'Salt', 'Pepper', 'Rosemary' },
                        cookTime = 15, -- in seconds
                        price = 30
                    }
                }
            },
            {
                label = 'Smoothie',
                icon = 'fas fa-blender',
                event = {
                    name = 'cookItem',
                    payload = {
                        itemName = 'Smoothie',
                        ingredients = { 'Banana', 'Strawberry', 'Yogurt', 'Honey' },
                        cookTime = 5, -- in seconds
                        price = 8
                    }
                }
            }
        }
    },
    {
        door = true,
        model = "v_ilev_ph_door002",
        offset = vec3(-0.6, 0, 0),
        static = true,
        extra = {
            onExit = function()
                print('exit')
            end,
            onTrigger = function()
                print('on trigger test')
            end
        },
        options = {
            {
                label = 'Delete Door',
                action = function(e)
                    DeleteEntity(e)
                end
            }
        }
    },
    {
        model = "prop_pot_plant_05b",
        offset = vec3(0, 0, 0.3),
        icon = 'glowingball',
        theme = 'nopixel',
        indicator = {
            prompt = 'E'
        },
        suppressGlobals = true,
        extra = {
            onExit = function()
                print('exit')
            end,
            onTrigger = function()
                print('on trigger test')
            end
        },
        options = {
            {
                label = 'Inspect The Pile',
                action = function(data)
                end
            },
            {
                label = 'Dig',
                action = function(data)
                end
            },
        }
    },
    {
        model = "prop_cs_cardbox_01",
        offset = vec3(0, 0, 0),
        icon = 'box',
        options = {
            {
                label = 'Pickup',
                action = function(entity)
                    if carryingBox then return end

                    local playerPed = PlayerPedId()
                    local pos = GetEntityCoords(entity)
                    local rot = GetEntityRotation(entity)
                    local boneIndex = GetPedBoneIndex(playerPed, 28422)
                    AttachEntityToEntity(entity, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true,
                        true, false, true, 1, true)

                    carryingBox = true

                    RequestAnimDict("anim@heists@box_carry@")
                    while not HasAnimDictLoaded("anim@heists@box_carry@") do
                        Wait(50)
                    end

                    TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 1, 0, false, false,
                        false)

                    Wait(2000)
                    -- Detach the box from the player
                    DetachEntity(entity, true, true)
                    Wait(0)
                    SetEntityCoordsNoOffset(entity, pos.x, pos.y, pos.z, false, false, false)
                    SetEntityRotation(entity, rot.x, rot.y, rot.z, 2, false)

                    carryingBox = false

                    ClearPedTasks(playerPed)
                end
            }
        }
    },
    {
        model = "prop_hobo_stove_01",
        offset = vec3(0, 0, 0),
        static = true,
        icon = "stove2",
        options = {
            {
                label = 'Cook',
                action = function(data)

                end
            }
        }
    },
    {
        model = "m23_1_prop_m31_gravestones_01a",
        options = {
            {
                icon = "fa-solid fa-trowel",
                label = "Dig Grave",
                action = function()
                    if isDigging == false then
                        isDigging = true
                        exports["rpemotes"]:EmoteCommandStart("dig")
                    else
                        isDigging = false
                        exports["rpemotes"]:EmoteCancel()
                    end
                end
            }
        }
    },
    {
        model = "m24_1_prop_m41_camera_01a",
        offset = vec3(0, 0, 1.2),
        options = {
            {
                label = 'Activate Camera',
                icon = 'fas fa-video',
                event = {
                    name = 'ActivateCamera',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        mode = 'active'
                    }
                }
            },
            {
                label = 'Zoom In',
                icon = 'fas fa-search-plus',
                event = {
                    name = 'AdjustCameraZoom',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        adjustment = 'zoom_in',
                        increment = 5
                    }
                }
            },
            {
                label = 'Zoom Out',
                icon = 'fas fa-search-minus',
                event = {
                    name = 'AdjustCameraZoom',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        adjustment = 'zoom_out',
                        increment = 5
                    }
                }
            },
            {
                label = 'Rotate Left',
                icon = 'fas fa-arrow-left',
                event = {
                    name = 'RotateCamera',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        direction = 'left',
                        angle = 15
                    }
                }
            },
            {
                label = 'Rotate Right',
                icon = 'fas fa-arrow-right',
                event = {
                    name = 'RotateCamera',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        direction = 'right',
                        angle = 15
                    }
                }
            },
            {
                label = 'Deactivate Camera',
                icon = 'fas fa-power-off',
                event = {
                    name = 'DeactivateCamera',
                    payload = {
                        cameraId = 'm24_1_prop_m41_camera_01a',
                        mode = 'inactive'
                    }
                }
            }
        }
    }
}

local function init()
    for index, menu in ipairs(menus) do
        if menu.model then
            menu.entity = Util.spawnObject(joaat(menu.model), positions[index], menu.door)
            entities[#entities + 1] = menu.entity
        end

        menu.static = true
        menu_ids[#menu_ids + 1] = exports['interactionMenu']:Create(menu)
    end

    local start = #menus + 1
    local ent_watercooler = Util.spawnObject(`prop_watercooler`, positions[start], false)
    entities[#entities + 1] = ent_watercooler

    menu_ids[#menu_ids + 1] = exports['interactionMenu']:Create {
        entity = ent_watercooler,
        offset = vec3(0, 0, 1),
        options = {
            {
                label = "Above Menu",
                icon = "fas fa-heartbeat",
            }
        }
    }

    menu_ids[#menu_ids + 1] = exports['interactionMenu']:Create {
        entity = ent_watercooler,
        offset = vec3(0, 0, 1),
        glow = true,
        options = {
            {
                label = "Up",
                icon = "fas fa-heartbeat",
            },
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
                label = "Down",
                icon = "fas fa-heartbeat",
            },
        }
    }

    local on_ped = Util.spawnPed(GetHashKey('cs_brad'), positions[start + 1])
    menu_ids[#menu_ids + 1] = exports['interactionMenu']:Create {
        entity = on_ped,
        indicator = {
            prompt = "Hey"
        },
        options = {
            {
                label = 'Disabled After 4 Seconds',
                action = function(data)

                end
            }
        }
    }
    entities[#entities + 1] = on_ped
end

local function cleanup()
    for index, menu_id in ipairs(menu_ids) do
        exports['interactionMenu']:remove(menu_id)
    end
    for index, entity in ipairs(entities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    entities = {}
    menu_ids = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "on_entities", "On Entities", "fa-solid fa-diagram-project")
end)

AddEventHandler('testEvent:client', function(e)
    Util.print_table(e)
end)

AddEventHandler('cookItem', function(e)
    Util.print_table(e)
end)

-- obj = Util.spawnObject(GetHashKey('m24_1_prop_m41_jammer_01a'), positions[15])
-- obj = Util.spawnObject(GetHashKey('m24_1_prop_m41_militarytech_01a'), positions[16])
-- obj = Util.spawnObject(GetHashKey('m23_2_prop_m32_jammer_01a'), positions[17])
-- obj = Util.spawnObject(GetHashKey('m23_2_prop_m32_sub_console_01a'), positions[18])
