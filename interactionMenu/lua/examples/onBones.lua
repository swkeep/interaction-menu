--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
-- https://docs.fivem.net/natives/?_0xFB71170B7E76ACBA
-- Bone indices -> pastebin.com/D7JMnX1g

if not DEVMODE then return end
local positions = {
    vector4(794.00, -2997.10, -70.00, 0),
    vector4(796.50, -2997.10, -70.00, 0),
    vector4(799.00, -2997.10, -70.00, 0),
    vector4(801.50, -2997.10, -70.00, 0),
    vector4(804.00, -2997.10, -70.00, 0),
    vector4(807.00, -2997.10, -70.00, 0),

    vector4(794.54, -3002.94, -70.00, 180),
    vector4(798.54, -3002.94, -70.00, 180),
    vector4(801.04, -3002.94, -70.00, 180),
    vector4(803.54, -3002.94, -70.00, 180),
    vector4(806.04, -3002.94, -70.00, 180),
    vector4(808.54, -3002.94, -70.00, 180),
}

local function toggle_door(vehicle, doorId)
    if GetVehicleDoorAngleRatio(vehicle, doorId) > 0.0 then
        SetVehicleDoorShut(vehicle, doorId, false)
    else
        SetVehicleDoorOpen(vehicle, doorId, false, false)
    end
    Wait(650)
end

local function createWheelAction(wheelIndex)
    return function(entity)
        SetVehicleTyreBurst(entity, wheelIndex, true, 1000.0)
    end
end

local bones = {
    platelight   = {
        {
            label = "Switch Plate",
            icon = "fas fa-toggle-on",
            action = function(entity)
                Wait(1000)
                SetVehicleNumberPlateText(entity, 'swkeep' .. math.random(0, 9))
                Wait(500)
            end
        },
    },

    wheel_lf     = {
        {
            label = "Front Left Wheel (Remove)",
            icon = "fas fa-truck-monster",
            action = createWheelAction(0),
        },
    },
    wheel_rf     = {
        {
            label = "Front Right Wheel (Remove)",
            icon = "fas fa-truck-monster",
            action = createWheelAction(1),
        },
    },
    wheel_lr     = {
        {
            label = "Rear Left Wheel (Remove)",
            icon = "fas fa-truck-monster",
            action = createWheelAction(4),
        }
    },
    wheel_rr     = {
        {
            label = "Rear Right Wheel (Remove)",
            icon = "fas fa-truck-monster",
            action = createWheelAction(5),
        }
    },

    seat_dside_f = {
        {
            label = "Driver Seat",
            icon = "fas fa-user",
            action = function(e)
            end
        },
        {
            label = "Passenger Seat",
            icon = "fas fa-user",
            action = function(entity)
                TaskEnterVehicle(PlayerPedId(), entity, 2000, 0, 2.0, 1, 0)
            end
        },
    },

    seat_pside_f = {
        {
            label = "Passenger Seat",
            icon = "fas fa-user",
            action = function(entity)
                TaskEnterVehicle(PlayerPedId(), entity, 2000, 0, 2.0, 1, 0)
            end
        },
        {
            label = "Driver Seat",
            icon = "fas fa-user",
            action = function(entity)
                TaskEnterVehicle(PlayerPedId(), entity, 2000, -1, 1.0, 16, 0)
            end
        },
    },

    door_dside_f = {
        {
            label = "Front Left Door",
            icon = "fas fa-door-open",
            action = function(entity)
                toggle_door(entity, 0)
            end
        },
    },

    window_lf    = {
        {
            label = "Front Left Window",
            icon = "fas fa-window-close",
            action = function(entity)
                toggle_door(entity, 0)
            end
        }
    },


    engine  = {
        {
            label = "Engine Health",
            icon = "fas fa-heartbeat",
            progress = {
                type = "info",
                value = 30,
                percent = true
            },
            bind = function(entity)
                return GetVehicleEngineHealth(entity) / 10
            end
        },
        {
            label = "Body Health",
            icon = "fas fa-hard-hat",
            progress = {
                type = "info",
                value = 70
            },
            bind = function(entity)
                return GetVehicleBodyHealth(entity) / 10
            end
        },
        {
            label = "Engine Status",
            icon = "fas fa-cogs",
            action = function(entity)
                SetVehicleEngineOn(entity, true, false, false)
            end
        }
    },

    bonnet  = {
        {
            label = "Hood",
            icon = "fas fa-car",
            action = function(entity)
                toggle_door(entity, 4)
            end
        }
    },

    exhaust = {
        {
            label = "Exhaust",
            icon = "fas fa-smog",
            action = function()
            end
        }
    },

    boot    = {
        {
            label = "Trunk",
            action = function(entity)
                toggle_door(entity, 5)
            end
        }
    },
}

local menus = {}
local entities = {}

local function init()
    entities[#entities + 1] = Util.spawnVehicle('adder', positions[1])
    entities[#entities + 1] = Util.spawnVehicle('adder', positions[2])
    entities[#entities + 1] = Util.spawnVehicle('adder', positions[7])
    entities[#entities + 1] = Util.spawnVehicle('adder', positions[8])
    entities[#entities + 1] = Util.spawnVehicle('adder', positions[9])

    for index, vehicle in ipairs(entities) do
        SetVehicleNumberPlateText(vehicle, 'swkeep-' .. index)

        for boneName, bone in pairs(bones) do
            menus[#menus + 1] = exports['interactionMenu']:Create {
                bone = boneName,
                vehicle = vehicle,
                offset = vec3(0, 0, 0),
                maxDistance = 2.0,
                indicator = {
                    prompt = 'E',
                },
                options = bone or {}
            }
        end
    end

    local index = #entities + 1
    entities[index] = Util.spawnVehicle('adder', positions[3])
    SetVehicleNumberPlateText(entities[index], 'no menu')
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
    InternalRegisterTest(init, cleanup, "on_bones", "On Vehicle Boens", "fa-solid fa-border-none")
end)
