if true then
    return
end

CreateThread(function()
    local veh_pos = vector4(-1974.9, 3178.76, 32.81, 59.65)
    local vehicle = Util.spawnVehicle('adder', veh_pos)

    SetVehicleNumberPlateText(vehicle, 'swkeep')

    exports['interactionMenu']:createGlobal {
        type = 'bones',
        bone = 'platelight',
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        options = {
            {
                label = '[Debug] On All plates',
                icon = 'fa fa-rectangle-ad',
                action = {
                    type = 'sync',
                    func = function(entity)
                        print('Plate:', GetVehicleNumberPlateText(entity))
                    end
                }
            }
        }
    }

    local pos = vector4(-1973.31, 3181.98, 32.81, 249.84)
    local ped_ = Util.spawnPed(GetHashKey('cs_brad'), pos)

    exports['interactionMenu']:createGlobal {
        type = 'peds',
        offset = vec3(0, 0, 0),
        maxDistance = 2.0,
        options = {
            {
                label = '[Debug] On All peds',
                icon = 'fa fa-rectangle-ad',
                action = {
                    type = 'sync',
                    func = function(entity)
                        print('Plate:', GetVehicleNumberPlateText(entity))
                    end
                }
            }
        }
    }
end)

local coords = vector4(-1996.28, 3161.06, 31.81, 103.8)
Util.spawnObject(`xm_prop_crates_sam_01a`, coords)

exports['interactionMenu']:Create {
    type = 'model',
    id = 'on_mode_test',
    model = `xm_prop_crates_sam_01a`,
    offset = vec3(0, 0, 0.5),
    maxDistance = 2.0,
    theme = 'box',
    indicator = {
        prompt   = 'F',
        keyPress = {
            -- https://docs.fivem.net/docs/game-references/controls/#controls
            padIndex = 0,
            control = 23
        },
    },
    options = {
        {
            label = "Open",
            action = function(e)
                print('Health')
            end,
            canInteract = function()
                return false
            end
        },
        {
            icon = "fas fa-spinner",
            label = "Spinner",
            action = function(e)
                Wait(1000)
                print('HEY')
            end
        },
        {
            label = "Health",
            progress = {
                type = "info",
                value = 0,
                percent = true
            },
            bind = function(entity, distance, coords, name, bone)
                local max_hp = 100 - GetEntityMaxHealth(entity)
                local current_hp = 100 - GetEntityHealth(entity)
                return math.floor(current_hp * 100 / max_hp)
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
                print('HEY')
            end
        }
    }
}
