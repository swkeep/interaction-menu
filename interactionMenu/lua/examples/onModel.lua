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
    vector4(796.54, -3002.94, -70.00, 180),
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
local entities = {}

local function init()
    local objects = {
        { model = `xm_prop_crates_sam_01a`, start = 1,  finish = 7 },
        { model = `prop_vend_snak_01`,      start = 8,  finish = 14 },
        { model = `prop_paper_bag_01`,      start = 15, finish = 19 }
    }

    for _, object in ipairs(objects) do
        for i = object.start, object.finish do
            entities[#entities + 1] = Util.spawnObject(object.model, positions[i])
        end
    end

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `xm_prop_crates_sam_01a`,
        offset = vec3(0, 0, 0.5),
        maxDistance = 2.0,
        options = {
            {
                label = "Open",
                action = function(e)

                end
            },
            {
                icon = "fas fa-spinner",
                label = "Spinner",
                action = function(e)

                end
            },
            {
                label = "rgb(50,100,50)",
                style = {
                    color = {
                        label = 'rgb(50,255,50)',
                    }
                }
            },
            {
                label = "rgb(250,0,50)",
                style = {
                    color = {
                        label = 'rgb(250,0,50)',
                    }
                }
            },
            {
                icon = "fas fa-spinner",
                label = "rgb(0,0,250)",
                style = {
                    color = {
                        background = 'wheat',
                        label = 'rgb(0,0,250)',
                    }
                },
                action = function(e)

                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        extra = {
            job = {
                ['police'] = { 1, 3, 2 }
            },
        },
        options = {
            {
                label = 'Job Access: Police',
                icon = 'fa fa-handcuffs',
                action = function()

                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        options = {
            {
                label = 'First On Model',
                icon = 'fa fa-book',
                action = function(e)
                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        options = {
            {
                label = 'Second On Model',
                icon = 'fa fa-book',
                action = function(e)
                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_paper_bag_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 3.0,
        options = {
            {
                label = 'Second On Model',
                icon = 'fa fa-book',
                action = function(e)
                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_paper_bag_01`,
        offset = vec3(0, 0, 0),
        maxDistance = 3.0,
        options = {
            {
                label = 'Pick',
                icon = 'fa fa-book',
                action = function(e)
                    DeleteEntity(e)
                end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `adder`,
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        indicator = {
            prompt = 'E',
        },
        options = {
            {
                label = "[Debug] On adder",
                icon = 'fa fa-car',
                action = function(e)
                    print(e)
                end
            }
        }
    }
end

local function cleanup()
    for index, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    for index, entity in ipairs(entities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    menus = {}
    entities = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "on_model", "On Models", "fa-solid fa-tent-arrows-down")
end)
