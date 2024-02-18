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
if true then return end

CreateThread(function()
    Wait(1000)

    local ped_position = vector4(-2037.74, 3179.25, 31.81, 241.19)
    local ped_ = Util.spawnPed(GetHashKey('cs_brad'), ped_position)

    -- keep-hunting
    exports['qb-target']:AddTargetEntity(ped_, {
        options = {
            {
                icon = "fas fa-sack-dollar",
                label = "slaughter",
                canInteract = function(entity, distance, coords, name, bone)
                    print(entity, distance, coords, name, bone)
                    return IsEntityDead(entity)
                end,
                action = function(entity, distance)
                    if IsEntityDead(entity) == false then
                        return false
                    end
                    TriggerEvent('keep-hunting:client:slaughterAnimal', entity)
                    return true
                end
            }
        },
        distance = 1.5
    })

    -- qb-banking
    Zones = {
        [1] = {
            position = vector4(154.52, -1035.78, 29.3, 250.43),
            length = 6.2,
            width = 2.0,
            heading = 250,
            minZ = 27.17,
            maxZ = 31.17
        },
        [2] = {
            position = vector4(154.52, -1035.78, 29.3, 250.43),
            length = 6.6,
            width = 2.0,
            heading = 250,
            minZ = 51.97,
            maxZ = 55.97
        },
    }

    for k, v in pairs(Config.Zones) do
        exports["qb-target"]:AddBoxZone("Bank_" .. k, v.position, v.length, v.width, {
            name = "Bank_" .. k,
            heading = v.heading,
            minZ = v.minZ,
            maxZ = v.maxZ
        }, {
            options = {
                {
                    type = "client",
                    event = "qb-banking:openBankScreen",
                    icon = "fas fa-university",
                    label = "Access Bank",
                }
            },
            distance = 1.5
        })
    end
end)
