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
-- pastebin.com/D7JMnX1g

if not DEVMODE then return end

local progress = 0
local Zones = {}

local function toggle_door(vehicle, doorId)
    if GetVehicleDoorAngleRatio(vehicle, doorId) > 0.0 then
        SetVehicleDoorShut(vehicle, doorId, false)
    else
        SetVehicleDoorOpen(vehicle, doorId, false, false)
    end
    Wait(650)
end

CreateThread(function()
    while true do
        progress = progress + 1

        if progress >= 100 then
            progress = 0
        end
        Wait(1000)
    end
end)

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
                SetVehicleEngineOn(entity, true, false)
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

local vehicle

CreateThread(function()
    Wait(50)

    local veh_pos = vector4(-1974.9, 3178.76, 32.81, 59.65)
    local veh_pos2 = vector4(-1973.78, 3180.58, 32.4, 58.78)

    vehicle = Util.spawnVehicle('adder', veh_pos)
    Util.spawnVehicle('adder', veh_pos2)

    SetVehicleNumberPlateText(vehicle, 'swkeep')

    for boneName, bone in pairs(bones) do
        -- for key, value in pairs(bone) do
        --     if value.label then
        --         value.label = ('%s (%s)'):format(value.label, veh)
        --     end
        -- end
        exports['interactionMenu']:Create {
            bone = boneName,
            vehicle = vehicle,
            offset = vec3(0, 0, 0),
            maxDistance = 2.0,
            indicator = {
                prompt   = 'E',
                keyPress = {
                    -- https://docs.fivem.net/docs/game-references/controls/#controls
                    padIndex = 0,
                    control = 38
                }
            },
            options = bone or {}
        }
    end
end)
