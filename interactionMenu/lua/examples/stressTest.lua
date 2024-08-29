-- Ensure DEVMODE is enabled to run tests
if not DEVMODE then return end
if true then return end
-- calculate positions in a circle
local function calculateCirclePositions(centerPoint, numPoints, radius, direction)
    local positions = {}
    for i = 1, numPoints do
        local angle = (2 * math.pi / numPoints) * i
        local x = centerPoint.x + radius * math.cos(angle)
        local y = centerPoint.y + radius * math.sin(angle)
        local heading = math.deg(math.atan(centerPoint.y - y, centerPoint.x - x))
        if direction then
            heading = heading - 90
        else
            heading = heading + 90
        end
        if heading < 0 then
            heading = heading + 360
        end
        local spawnPoint = vector4(x, y, centerPoint.z, heading)
        table.insert(positions, spawnPoint)
    end
    return positions
end

-- Test for position menu creation
local function test_position_menu()
    local centerPoint = vector3(-2002.83, 3222.66, 32.81)
    local numPoints = 20
    local radius = 5.0
    local direction = false
    local positions = calculateCirclePositions(centerPoint, numPoints, radius, direction)
    local ids = {}

    for i, point in ipairs(positions) do
        ids[#ids + 1] = exports['interactionMenu']:Create {
            type = 'position',
            position = vec3(point.x, point.y, point.z),
            maxDistance = 2.0,
            options = {
                {
                    label = 'Menu|' .. i .. " Test",
                    icon = 'fas fa-car',
                    action = {
                        type = 'sync',
                        func = function()
                            print("Menu " .. i .. " triggered.")
                        end
                    }
                },
            }
        }
    end

    -- Wait and remove menus
    Wait(1500)
    for _, id in ipairs(ids) do
        exports['interactionMenu']:remove(id)
    end
end

-- Test for zone menu creation
local function test_zone_menu()
    local centerPoint = vector3(-2002.83, 3222.66, 32.81)
    local numPoints = 10
    local radius = 5.0
    local direction = false
    local positions = calculateCirclePositions(centerPoint, numPoints, radius, direction)
    local ids = {}

    for i, point in ipairs(positions) do
        ids[#ids + 1] = exports['interactionMenu']:Create {
            position = point,
            id = "zoneTest" .. i,
            zone = {
                type = 'boxZone',
                name = "zoneTest" .. i,
                position = point,
                heading = point.w,
                width = 4.0,
                length = 6.0,
                debugPoly = Config.debugPoly,
                minZ = point.z - 1,
                maxZ = point.z + 1,
            },
            maxDistance = 2.0,
            options = {
                {
                    label = 'Zone Menu|' .. i,
                    icon = 'fas fa-car',
                    action = function()
                        print("Zone " .. i .. " triggered.")
                    end,
                    canInteract = function()
                        return true
                    end
                },
            }
        }
    end

    -- Wait and remove zones
    Wait(4000)
    for _, id in ipairs(ids) do
        exports['interactionMenu']:remove(id)
    end
end

-- Test for entity menu creation
local function test_entity_menu()
    local centerPoint = vector3(-2002.83, 3222.66, 31.81)
    local numPoints = 25
    local radius = 5.0
    local direction = false
    local positions = calculateCirclePositions(centerPoint, numPoints, radius, direction)
    local entities = {}
    local ids = {}

    for i, point in ipairs(positions) do
        entities[i] = Util.spawnObject(`prop_vend_snak_01`, point)

        ids[#ids + 1] = exports['interactionMenu']:Create {
            entity = entities[i],
            maxDistance = 2.0,
            options = {
                {
                    label = 'Entity Menu|' .. i,
                    icon = 'fas fa-car',
                    action = {
                        type = 'sync',
                        func = function()
                            print("Entity " .. i .. " triggered.")
                        end
                    }
                },
            }
        }
    end

    Wait(1000)
    for _, id in ipairs(ids) do
        exports['interactionMenu']:remove(id)
    end
    for _, entity in ipairs(entities) do
        DeleteEntity(entity)
    end
end

CreateThread(function()
    Wait(1000)
    while true do
        test_position_menu()
        Wait(2000)
    end
end)

CreateThread(function()
    Wait(1000)
    while true do
        test_zone_menu()
        Wait(2000)
    end
end)

CreateThread(function()
    Wait(1000)
    while true do
        test_entity_menu()
        Wait(2000)
    end
end)
