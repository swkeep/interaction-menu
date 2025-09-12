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

local menus, entities = {}, {}

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
                label = "Open Crate",
                icon = "fas fa-box-open",
                action = function(e) print("Opened crate:", e) end
            },
            {
                label = "Check Contents",
                icon = "fas fa-search",
                action = function(e) print("Checking contents of:", e) end
            },
            {
                label = "Green Option",
                style = { color = { label = 'rgb(50,255,50)' } }
            },
            {
                label = "Red Option",
                style = { color = { label = 'rgb(250,0,50)' } }
            },
            {
                label = "Blue Option",
                icon = "fas fa-palette",
                style = { color = { label = 'rgb(0,0,250)', background = 'wheat' } }
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        maxDistance = 2.0,
        options = {
            {
                label = 'Info Screen',
                icon = 'fa fa-info-circle',
                action = function(e) print("Viewing info on:", e) end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_vend_snak_01`,
        maxDistance = 2.0,
        options = {
            {
                label = 'Purchase Item',
                icon = 'fa fa-shopping-cart',
                action = function(e) print("Buying from:", e) end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_paper_bag_01`,
        maxDistance = 3.0,
        options = {
            {
                label = 'Inspect Bag',
                icon = 'fa fa-search',
                action = function(e) print("Inspecting bag:", e) end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `prop_paper_bag_01`,
        maxDistance = 3.0,
        options = {
            {
                label = 'Pick Up',
                icon = 'fa fa-hand-paper',
                action = function(e) DeleteEntity(e) end
            }
        }
    }

    menus[#menus + 1] = exports['interactionMenu']:Create {
        type = 'model',
        model = `adder`,
        maxDistance = 2.0,
        indicator = { prompt = 'E' },
        options = {
            {
                label = "Enter Vehicle [Debug]",
                icon = 'fa fa-car',
                action = function(e) print("Interacted with vehicle:", e) end
            }
        }
    }
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    menus, entities = {}, {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "on_model", "On Models", "fa-solid fa-tent-arrows-down",
        "Example menus bound to models. Shows different features: styled options, entity deletion, and vehicle interaction.",
        { type = "dark-orange", label = "Feature" }
    )
end)
