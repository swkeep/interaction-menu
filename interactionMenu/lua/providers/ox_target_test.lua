if not Config.provide.ox_target then return end
if not Config.devMode then return end
if not Config.provide.ox_target_test then return end

local zones = {}

local function on_zones()
    local pos = InternalGetTestSlot("front", 1)

    zones[#zones + 1] = exports.ox_target:addBoxZone({
        coords = pos,
        size = vec3(2, 2, 2),
        rotation = 0,
        debug = true,
        options = {
            {
                label = 'Open Box Storage',
                icon = 'fas fa-box',
                onSelect = function()
                    print('Box Storage opened!')
                end
            }
        }
    })

    pos = InternalGetTestSlot("front", 2)
    zones[#zones + 1] = exports.ox_target:addSphereZone({
        coords = pos,
        radius = 2.0,
        debug = true,
        options = {
            {
                label = 'Search Area',
                icon = 'fas fa-search',
                onSelect = function()
                    print('Sphere zone searched!')
                end
            }
        }
    })

    pos = InternalGetTestSlot("front", 3)
    zones[#zones + 1] = exports.ox_target:addPolyZone({
        points = {
            pos + vec4(2, 0, 0, 0),
            pos + vec4(4, 0, 0, 0),
            pos + vec4(2, 2, 0, 0),
            pos + vec4(-4, 2, 0, 0),
        },
        thickness = 2.0,
        debug = true,
        options = {
            {
                label = 'Restricted Area',
                icon = 'fas fa-exclamation-triangle',
                onSelect = function()
                    print('Entered poly zone!')
                end
            }
        }
    })
end

CreateThread(function()
    Wait(1000)
    print('Starting ox-target tests')

    on_zones()

    local net_pos = vector4(788.43, -3000.04, -70.0, 90.0)
    local ball_pos = vector4(816.15, -3000.19, -70.0, 0.0)

    local entity2 = Util.spawnObject(`prop_basketball_net`, net_pos, false, true)
    local entity = Util.spawnObject(`vw_prop_casino_art_basketball_02a`, ball_pos, false, true)
    local net_id = NetworkGetNetworkIdFromEntity(entity)
    FreezeEntityPosition(entity, false)
    SetObjectPhysicsParams(entity, 15.5, 1.0, 0.08, 0.0, 0.0, 0.08, 0.0, 0.0, false, 1.0, 0.0)

    exports.ox_target:addEntity(net_id, {
        {
            label = 'Kick Ball',
            icon = 'fas fa-futbol',
            onSelect = function(data)
                print('Ball kicked!')
                local kickForce = vec3(-13.6, 0.0, 11.5)

                ApplyForceToEntity(
                    entity,      -- Entity to apply force to
                    1,           -- Force flags (1 = apply at center of mass)
                    kickForce.x, -- X force
                    kickForce.y, -- Y force
                    kickForce.z, -- Z force
                    0.0,         -- X offset (0 for center)
                    0.0,         -- Y offset (0 for center)
                    0.0,         -- Z offset (0 for center)
                    0,           -- Bone index (0 for no bone)
                    true,        -- Is direction relative to world?
                    false,       -- Ignore up force?
                    true,        -- Apply to velocity?
                    false,       -- Apply to rotation?
                    true         -- Apply to center of mass?
                )
            end
        },
        {
            label = '1234 1234 1234',
            icon = 'fas fa-arrows-alt',
            onSelect = function()

            end
        },
    })

    SetTimeout(5000, function(threadId)
        exports.ox_target:removeEntity(net_id, '1234 1234 1234')
    end)

    local pos = InternalGetTestSlot("back", 1)
    local prop_still = Util.spawnObject(`prop_still`, pos, false, true)

    exports.ox_target:addLocalEntity(prop_still, {
        {
            label = 'Open',
            icon = 'fas fa-arrows-alt',
            onSelect = function()

            end
        },
        {
            label = 'Move Barrier',
            icon = 'fas fa-arrows-alt',
            onSelect = function()
                print('Barrier moved!')
            end,
            export = "test:export"
        },
        {
            label = 'Remove this',
            icon = 'fas fa-arrows-alt',
            onSelect = function()

            end
        },
    })

    SetTimeout(5000, function(threadId)
        exports.ox_target:removeLocalEntity(prop_still, 'Remove this')
    end)

    exports("test:export", function(...)
        print("export:-> ", ...)
    end)

    exports.ox_target:addModel(`prop_still`, {
        {
            label = 'Use It',
            icon = 'fas fa-credit-card',
            onSelect = function()
                print('used!')
            end
        }
    })

    exports.ox_target:addModel(`prop_still`, {
        {
            label = '1 (on model)',
            icon = 'fas fa-credit-card',
            onSelect = function()
                print('1 used!')
            end
        },
        {
            label = '2 (on model)',
            icon = 'fas fa-credit-card',
            onSelect = function()
                print('2 used!')
            end
        },
    })

    exports.ox_target:addGlobalObject({
        {
            label = 'All entities',
            icon = 'fas fa-credit-card',
            onSelect = function()
                print('All used!')
            end,
            distance = 3
        },
        {
            label = 'All entities 2',
            icon = 'fas fa-credit-card',
            onSelect = function()
                print('All used!')
            end,
            distance = 3
        },
    })

    SetTimeout(5000, function(threadId)
        exports.ox_target:removeGlobalObject('All entities 2')
    end)

    exports.ox_target:addGlobalPed({
        {
            label = 'Talk to Ped',
            icon = 'fas fa-comments',
            onSelect = function()
                print('Talking to ped!')
            end
        }
    })

    exports.ox_target:addGlobalVehicle({
        {
            label = 'Hotwire Vehicle',
            icon = 'fas fa-car',
            onSelect = function()
                print('Hotwiring vehicle!')
            end
        }
    })

    exports.ox_target:addGlobalPlayer({
        {
            label = 'Check Player ID',
            icon = 'fas fa-id-card',
            onSelect = function(data)
                print(('Checked player: %s'):format(data.entity))
            end
        }
    })
end)
