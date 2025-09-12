if not Config.devMode then return end
if not Config.provide.qb_target then return end
if not Config.provide.qb_target_test then return end

local function AddBoxZone()
    local k = 1
    local v = {
        position = vector4(796.09, -2997.78, -69.0, 269.31),
        length = 1,
        width = 2
    }

    exports["qb-target"]:AddBoxZone("Bank_" .. k, v.position, v.length, v.width, {
        name = "Bank_" .. k,
        heading = v.position.w,
        minZ = v.position.z - 1,
        maxZ = v.position.z + 2,
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
    local v = vector4(798.61, -3000.12, -69.0, 278.18)
    exports['qb-target']:AddCircleZone('PoliceDuty_' .. i, vector3(v.x, v.y, v.z), 1.5, {
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
    v = vector4(798.76, -2997.1, -69.0, 347.06)
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

    SetTimeout(4000, function(threadId)
        exports['qb-target']:RemoveZone("PoliceTrash_1")
    end)
end

local function AddPolyZone()
    exports['qb-target']:AddPolyZone("police_station", {
        vector3(791.79, -2998.97, -69.0),
        vector3(791.56, -3002.16, -69.0),
        vector3(794.63, -3003.07, -69.0),
        vector3(799.23, -2996.85, -69.01)
    }, {
        name = "police_station",
        minZ = -70.0,
        maxZ = -68,
        debugPoly = true, -- set to false when done testing
    }, {
        options = {
            {
                type = "client", -- can also be "server"
                event = "police:openArmory",
                icon = "fas fa-warehouse",
                label = "Open Armory",
            },
            {
                type = "client",
                event = "police:openEvidence",
                icon = "fas fa-box",
                label = "Open Evidence Locker",
            },
        },
        distance = 2.5
    })
end

local function AddEntityZone()
    local p1 = vector4(796.46, -3002.63, -70.0, 86.75)
    local ped1 = Util.spawnPed(`g_m_y_famdnf_01`, p1)

    exports['qb-target']:AddEntityZone("shopkeeper", ped1, {
        name = "shopkeeper_zone",
        debugPoly = true,
    }, {
        options = {
            {
                type = "client",
                event = "shops:openMenu",
                icon = "fas fa-shopping-basket",
                label = "Browse Shop",
            },
            {
                type = "client",
                event = "shops:robNPC",
                icon = "fas fa-gun",
                label = "Rob Shopkeeper",
            },
        },
        distance = 2.0
    })
end

local function AddTargetBone()
    local veh_pos = vector4(797.19, -2999.71, -69.05, 264.59)
    local veh = Util.spawnVehicle('adder', veh_pos)

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

    -- Wait(5000)
    -- exports['qb-target']:RemoveTargetBone(wheels)
    -- AddEventHandler("qb-target_test:client:wheel", function(data)
    --     print('qb-target_test:client:wheel')
    -- end)
end

local function AddTargetEntity()
    local p1 = vector4(796.46, -3002.63, -70.0, 86.75)
    local p2 = vector4(796.44, -3000.11, -70.0, 26.54)

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
    exports['qb-target']:AddTargetModel({ 218085040, 666561306, -58485588, -206690185, 1511880420, 682791951, -329415894 }, {
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

    -- Wait(5000)

    -- exports['qb-target']:RemoveTargetModel(Config.Dumpsters)
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

CreateThread(function()
    Wait(1000)
    print('Starting qb-target tests')

    -- AddBoxZone()
    -- AddCircleZone()
    -- AddPolyZone()
    -- AddEntityZone()
    -- AddTargetBone()
    -- AddTargetEntity()
    -- AddTargetModel()
    -- AddGlobalPed()
    Debug()
end)
