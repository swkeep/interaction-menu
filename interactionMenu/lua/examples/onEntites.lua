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
local positions = {}

for i = 1, 12, 1 do
    positions[#positions + 1] = vector4(-1990.08, 3148.54 + (i * 2), 31.81, 260)
end

-----------------------------
-- onEntity
-----------------------------

CreateThread(function()
    Wait(1000)

    local entity = Util.spawnObject(`prop_vend_snak_01`, positions[1])
    local id = exports['interactionMenu']:Create {
        entity = entity,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        icon = 'vending',
        indicator = {
            prompt   = 'F',
            keyPress = {
                -- https://docs.fivem.net/docs/game-references/controls/#controls
                padIndex = 0,
                control = 23
            },
        },
        extra = {
            onSeen = function()
                print('entity on seen')
            end,
            onExit = function()
                print('entity on exit')
            end,
            job = {
                police = { 1, 3, 2 }
            }
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
                action = {
                    type = 'sync',
                    func = function()
                        print('nothing')
                    end
                }
            }
        }
    }

    id = exports['interactionMenu']:Create {
        entity = entity,
        options = {
            {
                picture = {
                    url = 'http://127.0.0.1:8080/00235-990749447.png'
                }
            }
        }
    }

    entity = Util.spawnObject(`prop_vend_snak_01`, positions[2])

    exports['interactionMenu']:Create {
        suppressGlobals = true,
        theme = 'red',
        entity = entity,
        icon = 'vending',
        extra = {
            onSeen = function()
                print('seen')
            end
        },
        options = {
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
                label = 'Check Job Status'
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
                action = {
                    type = 'sync',
                    func = function()
                        print('Quitting current job...')
                    end
                }
            }
        }

    }

    entity = Util.spawnObject(`prop_vend_snak_01`, positions[3])

    exports['interactionMenu']:Create {
        suppressGlobals = true,
        theme = 'cyan',
        entity = entity,
        icon = 'vending',
        extra = {
            onExit = function()
                print('exit')
            end,
            onTrigger = function()
                print('on trigger test')
            end
        },
        indicator = {
            prompt = 'E'
        },
        options = {
            {
                label = 'On-Duty Tutorial',
                video = {
                    url = 'http://127.0.0.1:8080/Nevermore.mp4',
                    currentTime = 10,
                    autoplay = true,
                    volume = 0,
                    loop = true,
                    opacity = 0.5
                }
            },
            {
                label = 'Go On Duty',
                icon = 'fas fa-check-circle',
                event = {
                    name = 'GoOnDuty',
                    payload = {
                        dutyStatus = 'on'
                    }
                }
            },
            {
                label = 'Go Off Duty',
                icon = 'fas fa-times-circle',
                event = {
                    name = 'GoOffDuty',
                    payload = {
                        dutyStatus = 'off'
                    }
                }
            }
        }
    }

    entity = Util.spawnObject(`prop_vend_snak_01`, positions[4])

    exports['interactionMenu']:Create {
        suppressGlobals = true,
        theme = 'cyan',
        entity = entity,
        icon = 'vending',
        indicator = {
            prompt = 'Press Enter',
            glow = true
        },
        extra = {
            onTrigger = function()
                print('on trigger')
            end
        }
    }
    -----------------------------
    -- onEntity (close)
    -- to see if two entities of same type or different type effect interact menu
    -----------------------------

    local list = {
        {
            position = positions[5],
            model = 'p_rail_controller_s',
            options = {}
        },
        {
            position = positions[6],
            model = 'bkr_prop_fakeid_papercutter',
            options = {
                {
                    label = 'Just A Text'
                }
            }
        },
        {
            position = positions[7],
            model = 'bkr_prop_fakeid_papercutter',
            options = {
                {
                    label = 'Print Random Numbers',
                    action = {
                        type = 'sync',
                        func = function()
                            print(math.random(0, 100))
                        end
                    }
                },

            }
        },
        {
            position = positions[8],
            model = 'p_rail_controller_s',
            options = {
                {
                    picture = {
                        url = 'http://127.0.0.1:8080/00221-1775208258.png'
                    }
                }
            }
        },
        {
            position = positions[9],
            model = 'v_ret_fh_kitchtable',
            icon = 'stove',
            options = {
                {
                    video = {
                        url = 'http://127.0.0.1:8080/TEST VIDEO.mp4',
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
    }

    for index, value in ipairs(list) do
        local e = Util.spawnObject(joaat(value.model), value.position)

        exports['interactionMenu']:Create {
            type = 'entity',
            entity = e,
            offset = vec3(0, 0, 0),
            maxDistance = 2.0,
            options = value.options
        }
    end

    entity = Util.spawnObject(`v_ilev_ph_door002`, positions[10], true)

    exports['interactionMenu']:Create {
        entity = entity,
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
                action = {
                    type = 'sync',
                    func = function(e)
                        DeleteEntity(e)
                    end
                }
            }
        }
    }

    entity = Util.spawnObject(`prop_pile_dirt_02`, positions[12], false)

    exports['interactionMenu']:Create {
        entity = entity,
        offset = vec3(0, 0, 0.3),
        icon = 'glowingball',
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
                label = 'Inspect',
                icon = 'fas fa-search',
                action = {
                    type = 'sync',
                    func = function(data)
                    end
                }
            },
            {
                label = 'Dig',
                icon = 'fas fa-search',
                action = {
                    type = 'sync',
                    func = function(data)
                    end
                }
            },
        }
    }

    AddEventHandler('test', function(e)
        Util.print_table(e)
    end)

    AddEventHandler('cookItem', function(e)
        Util.print_table(e)
    end)

    local p = vector4(-1990, 3156.2, 33.8, 73.03)
    entity = Util.spawnObject(`prop_cs_cardbox_01`, p, false)
    SetEntityCoords(entity, p.x, p.y, p.z, false, false, false, false)

    local carryingBox = false
    local attachedBox = nil

    exports['interactionMenu']:Create {
        entity = entity,
        offset = vec3(0, 0, 0),
        icon = 'box',
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
                label = 'Pickup',
                action = {
                    type = 'sync',
                    func = function(data)
                        local playerPed = PlayerPedId()

                        if not carryingBox then
                            local boneIndex = GetPedBoneIndex(playerPed, 28422)
                            AttachEntityToEntity(entity, playerPed, boneIndex, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, true,
                                true, false, true, 1, true)

                            carryingBox = true
                            attachedBox = entity

                            RequestAnimDict("anim@heists@box_carry@")
                            while not HasAnimDictLoaded("anim@heists@box_carry@") do
                                Wait(50)
                            end

                            TaskPlayAnim(playerPed, "anim@heists@box_carry@", "idle", 8.0, -8.0, -1, 1, 0, false, false,
                                false)

                            Wait(2000)
                            -- Detach the box from the player
                            DetachEntity(attachedBox, true, true)
                            SetEntityCoords(entity, p.x, p.y, p.z, false, false, false, false)

                            carryingBox = false
                            attachedBox = nil

                            ClearPedTasks(playerPed)
                        end
                    end
                }
            }
        }
    }

    local p2 = vector4(-1996.67, 3155.48, 31.81, 95.07)
    local ent2 = Util.spawnObject(`prop_watercooler`, p2, false)

    local hideMenu_id = exports['interactionMenu']:Create {
        entity = ent2,
        offset = vec3(0, 0, 1),
        options = {
            {
                label = "Above Menu",
                icon = "fas fa-heartbeat",
            }
        }
    }

    local hideOption_id = exports['interactionMenu']:Create {
        entity = ent2,
        offset = vec3(0, 0, 1),
        glow = true,
        -- suppressGlobals = true,
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

    CreateThread(function()
        local toggle = false
        while true do
            Wait(2000)

            toggle = not toggle
            exports['interactionMenu']:set {
                menuId = hideOption_id,
                option = 2,
                type = 'hide',
                value = toggle
            }

            exports['interactionMenu']:set {
                menuId = hideMenu_id,
                type = 'hide',
                value = not toggle
            }
        end
    end)

    p2 = vector4(-1997.14, 3165.09, 31.81, 283.79)
    local we = Util.spawnObject(`prop_dumpster_3a`, p2, false)

    exports['interactionMenu']:Create {
        entity = we, -- entity handle
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
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
                action = {
                    type = 'sync',
                    func = function()
                        local position = vector4(-1996.36, 3165.28, 31.81, 150.71)
                        local ent      = Util.spawnObject('m23_1_prop_m31_ghostzombie_01a', position)

                        SetTimeout(2000, function()
                            DeleteEntity(ent)
                        end)
                    end
                }
            }
        }
    }

    p2 = vector4(-1998.25, 3169.23, 31.81, 272.54)
    local ent = Util.spawnObject(`prop_hobo_stove_01`, p2, false)

    exports['interactionMenu']:Create {
        entity = ent,
        offset = vec3(0, 0, 0),
        static = true,
        icon = "stove2",
        options = {
            {
                label = 'Cook',
                action = {
                    type = 'sync',
                    func = function(data)

                    end
                }
            }
        }
    }

    local ped_position = vector4(-1998.62, 3171.92, 31.81, 271.44)
    local ped_ = Util.spawnPed(GetHashKey('cs_brad'), ped_position)

    local remove_test = exports['interactionMenu']:Create {
        entity = ped_,
        options = {
            {
                label = 'Disabled After 4 Seconds',
                action = {
                    type = 'sync',
                    func = function(data)

                    end
                }
            }
        }
    }

    SetTimeout(4000, function()
        exports['interactionMenu']:remove(remove_test)
    end)
end)
