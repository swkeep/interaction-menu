if not DEVMODE then return end

exports['interactionMenu']:createGlobal {
    type = 'entities',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Entities',
            icon = 'fa fa-bug',
            action = {
                type = 'sync',
                func = function(data)
                    Util.print_table(data)
                end
            }
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'peds',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Peds',
            icon = 'fa fa-person',
            action = {
                type = 'sync',
                func = function(data)
                    Util.print_table(data)
                end
            }
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'vehicles',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Vehicles',
            icon = 'fa fa-car',
            action = {
                type = 'sync',
                func = function(data)
                    Util.print_table(data)
                end
            }
        }
    }
}

exports['interactionMenu']:createGlobal {
    type = 'bones',
    bone = 'platelight',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All plates',
            icon = 'fa fa-rectangle-ad',
            action = {
                type = 'sync',
                func = function(data)
                    print('Plate:', GetVehicleNumberPlateText(data.entity))
                end
            }
        }
    }
}


exports['interactionMenu']:createGlobal {
    type = 'players',
    offset = vec3(0, 0, 0),
    maxDistance = 1.0,
    options = {
        {
            label = '[Debug] On All Players',
            icon = 'fa fa-person',
            action = {
                type = 'sync',
                func = function(data)
                    if not data.player then return end

                    local player = data.player

                    Util.print_table(player)
                    TriggerServerEvent('interaction-menu:server:syncAnimation', player.serverId)
                end
            }
        }
    }
}

local function playAnimation(ped, dict, name)
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Wait(50)
    end
    TaskPlayAnim(ped, dict, name, 8.0, -8.0, -1, 0, 0, false, false, false)
end

RegisterNetEvent('interaction-menu:client:syncAnimation', function()
    playAnimation(PlayerPedId(), "random@mugging3", "handsup_standing_base")
    Wait(4000)
    ClearPedTasks(PlayerPedId())
end)
