if not Config.devMode then return end
if GetResourceState('qb-core') ~= 'started' then return end

local function AddBoxZone()
    local k = 1
    local v = {
        position = vector4(-2037.4, 3191.8, 32.81, 47.71),
        length = 1,
        width = 2
    }
    exports["qb-target"]:AddBoxZone("Bank_" .. k, v.position, v.length, v.width, {
        name = "Bank_" .. k,
        heading = v.heading,
        minZ = v.minZ,
        maxZ = v.maxZ,
        debugPoly = Config.debugPoly
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

local function AddCircleZone()
    local i = 1
    local v = vector3(-2036.28, 3191.27, 32.81)
    exports['qb-target']:AddCircleZone('PoliceDuty_' .. i, vector3(v.x, v.y, v.z), 0.5, {
        name = 'PoliceDuty_' .. i,
        useZ = true,
        debugPoly = Config.debugPoly,
    }, {
        options = {
            {
                type = 'client',
                event = 'qb-policejob:ToggleDuty',
                icon = 'fas fa-sign-in-alt',
                label = 'Sign In',
                jobType = 'leo',
            },
        },
        distance = 1.5
    })
    v = vector4(-2035.55, 3192.14, 32.81, 239.09)
    exports['qb-target']:AddCircleZone('PoliceTrash_' .. i, vector3(v.x, v.y, v.z), 0.5, {
        name = 'PoliceTrash_' .. i,
        useZ = true,
        debugPoly = Config.debugPoly,
    }, {
        options = {
            {
                type = 'server',
                event = 'qb-policejob:server:trash',
                icon = 'fas fa-trash',
                label = "Open Bin",
                jobType = 'leo',
            },
        },
        distance = 1.5
    })
end

local function AddTargetBone()
    local bones = {
        'platelight',
        'exhaust'
    }
    exports['qb-target']:AddTargetBone(bones, {
        options = {
            {
                num = 1,
                icon = 'fa-solid fa-car',
                label = 'Scan Plate',
                action = function(entity)
                    print("Plate Scan:", entity)
                end,
                job = 'police',
            }
        },
        distance = 4.0,
    })

    local wheels = {
        "wheel_lf",
        "wheel_rf",
        "wheel_lm1",
        "wheel_rm1",
        "wheel_lm2",
        "wheel_rm2",
        "wheel_lm3",
        "wheel_rm3",
        "wheel_lr",
        "wheel_rr",
    }
    exports['qb-target']:AddTargetBone(wheels, {
        options = {
            {
                event = "qb-target_test:client:wheel",
                icon = "fas fa-wrench",
                label = "Adjust",
                item = 'iron',
            },
        },
        distance = 1.5
    })

    Wait(5000)
    exports['qb-target']:RemoveTargetBone(wheels)
    AddEventHandler("qb-target_test:client:wheel", function(data)
        print('qb-target_test:client:wheel')
    end)
end

local function AddTargetEntity()
    local p1 = vector4(-2036.35, 3195.72, 31.81, 241.25)
    local p2 = vector4(-2035.67, 3196.93, 31.81, 274.3)
    local ped1 = Util.spawnPed(`g_m_y_famdnf_01`, p1)
    local ped2 = Util.spawnPed(`g_m_y_famdnf_01`, p2)
    exports['qb-target']:AddTargetEntity({
        ped1, ped2
    }, {
        options = {
            {
                label = "Ped",
                icon = "fas fa-eye",
                action = function(data)
                    Util.print_table(data)
                end,
            },
        }
    })

    -- Wait(5000)
    -- exports['qb-target']:RemoveTargetEntity(ped1)
    -- exports['qb-target']:RemoveTargetEntity(ped2)
end

local function AddTargetModel()
    Config.Dumpsters = { 218085040, 666561306, -58485588, -206690185, 1511880420, 682791951 }
    exports['qb-target']:AddTargetModel(Config.Dumpsters, {
        options = {
            {
                event = "qb-target_test:client:dumpster",
                icon = "fas fa-dumpster",
                label = "Search Dumpster",
            },
        },
        distance = 2
    })
    AddEventHandler('qb-target_test:client:dumpster', function(data)
        print("qb-target_test:client:dumpster")
    end)

    Wait(5000)

    exports['qb-target']:RemoveTargetModel(Config.Dumpsters)
end

local function AddGlobalPed()
    local options = {
        options = {
            {
                icon = 'fas fa-dumpster',
                label = 'Global ped test',
                canInteract = function(entity)
                    return true
                end,
                action = function()

                end
            },
            {
                icon = 'fas fa-dumpster',
                label = 'Global ped test 2',
                canInteract = function(entity)
                    return true
                end,
                action = function()

                end
            },
        },
        distance = 5,
    }

    exports['qb-target']:AddGlobalPed(options)

    Wait(5000)

    exports['qb-target']:RemoveGlobalPed('Global ped test 2')
    exports['qb-target']:RemoveGlobalPed({ 'Global ped test' })
end

local function Debug()
    CreateThread(function()
        Wait(1000)

        local currentResourceName = GetCurrentResourceName()
        local targeting = exports['qb-target']

        AddEventHandler(currentResourceName .. ':debug', function(data)
            local entity = data.entity
            local model = GetEntityModel(entity)
            local type = GetEntityType(entity)

            print('Entity: ' .. entity, 'Model: ' .. model, 'Type: ' .. type)
            if data.remove then
                targeting:RemoveTargetEntity(data.entity, 'Hello World')
            else
                targeting:AddTargetEntity(data.entity, {
                    options = {
                        {
                            type = "client",
                            event = currentResourceName .. ':debug',
                            icon = "fas fa-circle-check",
                            label = "Hello World",
                            remove = true
                        },
                    },
                    distance = 3.0
                })
            end
        end)

        targeting:AddGlobalPed({
            options = {
                {
                    type = "client",
                    event = currentResourceName .. ':debug',
                    icon = "fas fa-male",
                    label = "(Debug) Ped",
                },
            },
            distance = Config.MaxDistance
        })

        targeting:AddGlobalVehicle({
            options = {
                {
                    type = "client",
                    event = currentResourceName .. ':debug',
                    icon = "fas fa-car",
                    label = "(Debug) Vehicle",
                },
            },
            distance = Config.MaxDistance
        })

        targeting:AddGlobalObject({
            options = {
                {
                    type = "client",
                    event = currentResourceName .. ':debug',
                    icon = "fas fa-cube",
                    label = "(Debug) Object",
                },
            },
            distance = Config.MaxDistance
        })

        targeting:AddGlobalPlayer({
            options = {
                {
                    type = "client",
                    event = currentResourceName .. ':debug',
                    icon = "fas fa-cube",
                    label = "(Debug) Player",
                },
            },
            distance = Config.MaxDistance
        })
    end)
end

local function OptionsInnerProperties()
    local k = 'normal'
    local v = {
        coords = vector4(-1996.94, 3195.34, 32.81, 278.35),
        label = '24/7 Supermarket',
        targetIcon = 'fas fa-shopping-basket',
        targetLabel = 'Open Shop',
        requiredJob = 'police'
    }
    exports['qb-target']:AddCircleZone(k, vector3(v.coords.x, v.coords.y, v.coords.z), 0.5, {
        name = k,
        debugPoly = false,
        useZ = true
    }, {
        options = {
            {
                label = v.targetLabel,
                icon = v.targetIcon,
                item = v.requiredItem,
                shop = k,
                job = v.requiredJob,
                gang = v.requiredGang,
                action = function()
                    print('test')
                end
            }
        },
        distance = 2.0
    })
end

-- CreateThread(function()
-- Wait(1000)
-- print('Starting qb-target tests')

-- AddCircleZone()
-- AddBoxZone()
-- AddTargetBone()
-- AddTargetEntity()
-- AddTargetModel()
-- AddGlobalPed()
-- Debug()
-- OptionsInnerProperties()
-- exports['qb-target']:RaycastCamera()
-- end)
