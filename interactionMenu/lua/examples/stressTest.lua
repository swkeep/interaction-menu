if not DEVMODE then return end
if true then return end
-- local function test()
--     local centerPoint = vector3(-2002.83, 3222.66, 32.81)
--     local positions = {}
--     local ids = {}
--     local numPoints = 20
--     local radius = 5.0
--     local direction = false

--     for i = 1, numPoints do
--         local angle = (2 * math.pi / numPoints) * i
--         local x = centerPoint.x + radius * math.cos(angle)
--         local y = centerPoint.y + radius * math.sin(angle)
--         local heading = math.deg(math.atan(centerPoint.y - y, centerPoint.x - x))
--         if direction then
--             heading = heading - 90
--         else
--             heading = heading + 90
--         end
--         if heading < 0 then
--             heading = heading + 360
--         end
--         local spawnPoint = vector4(x, y, centerPoint.z, heading)
--         table.insert(positions, spawnPoint)
--     end

--     for i = 1, numPoints, 1 do
--         local point = positions[i]
--         ids[#ids + 1] = exports['interactionMenu']:Create {
--             type = 'position',
--             position = vec3(point.x, point.y, point.z),
--             maxDistance = 2.0,
--             options = {
--                 {
--                     label = 'Menu|' .. i,
--                     icon = 'fas fa-car',
--                     action = {
--                         type = 'sync',
--                         func = function()
--                         end
--                     }
--                 },
--             }
--         }
--     end

--     Wait(50)

--     for index, value in ipairs(ids) do
--         exports['interactionMenu']:remove(value)
--     end
-- end

-- local function test_zone()
--     local centerPoint = vector3(-2002.83, 3222.66, 32.81)
--     local positions = {}
--     local ids = {}
--     local numPoints = 100
--     local radius = 5.0
--     local direction = false

--     for i = 1, numPoints do
--         local angle = (2 * math.pi / numPoints) * i
--         local x = centerPoint.x + radius * math.cos(angle)
--         local y = centerPoint.y + radius * math.sin(angle)
--         local heading = math.deg(math.atan(centerPoint.y - y, centerPoint.x - x))
--         if direction then
--             heading = heading - 90
--         else
--             heading = heading + 90
--         end
--         if heading < 0 then
--             heading = heading + 360
--         end
--         local spawnPoint = vector4(x, y, centerPoint.z, heading)
--         table.insert(positions, spawnPoint)
--     end

--     for i = 1, numPoints, 1 do
--         local point = positions[i]
--         ids[#ids + 1] = exports['interactionMenu']:Create {
--             position = point,
--             zone = {
--                 type = 'boxZone', -- entityZone/circleZone/polyZone/comboZone
--                 name = "onZoneTest" .. i,
--                 position = point,
--                 heading = point.w,
--                 width = 4.0,
--                 length = 6.0,
--                 debugPoly = true,
--                 minZ = point.z - 1,
--                 maxZ = point.z + 1,
--             },
--             maxDistance = 2.0,
--             options = {
--                 {
--                     label = 'Menu|' .. i,
--                     icon = 'fas fa-car',
--                     action = {
--                         type = 'sync',
--                         func = function()
--                         end
--                     }
--                 },
--             }
--         }
--     end

--     Wait(50)

--     for index, value in ipairs(ids) do
--         exports['interactionMenu']:remove(value)
--     end
-- end

-- local function test_onPlayer()
--     local ids = {}
--     local numPoints = 100

--     for i = 1, numPoints, 1 do
--         ids[#ids + 1] = exports['interactionMenu']:create {
--             player = i,
--             offset = vec3(0, 0, 0),
--             maxDistance = 1.0,
--             options = {
--                 {
--                     label = 'Just On Player Id: ' .. i,
--                     icon = 'fa fa-person',
--                     action = {
--                         type = 'sync',
--                         func = function(data)
--                             Util.print_table(data)
--                         end
--                     }
--                 }
--             }
--         }
--     end

--     Wait(50)

--     for index, value in ipairs(ids) do
--         exports['interactionMenu']:remove(value)
--     end
-- end

-- local function test_entity()
--     local centerPoint = vector3(-2002.83, 3222.66, 32.81)
--     local positions = {}
--     local ids = {}
--     local entities = {}
--     local numPoints = 30
--     local radius = 5.0
--     local direction = false

--     for i = 1, numPoints do
--         local angle = (2 * math.pi / numPoints) * i
--         local x = centerPoint.x + radius * math.cos(angle)
--         local y = centerPoint.y + radius * math.sin(angle)
--         local heading = math.deg(math.atan(centerPoint.y - y, centerPoint.x - x))
--         if direction then
--             heading = heading - 90
--         else
--             heading = heading + 90
--         end
--         if heading < 0 then
--             heading = heading + 360
--         end
--         local spawnPoint = vector4(x, y, centerPoint.z, heading)
--         table.insert(positions, spawnPoint)
--     end

--     for i = 1, numPoints, 1 do
--         entities[i] = Util.spawnObject(`prop_vend_snak_01`, positions[i])

--         ids[#ids + 1] = exports['interactionMenu']:Create {
--             entity = entities[i],
--             maxDistance = 2.0,
--             options = {
--                 {
--                     label = 'Menu|' .. i,
--                     icon = 'fas fa-car',
--                     action = {
--                         type = 'sync',
--                         func = function()
--                         end
--                     }
--                 },
--             }
--         }
--     end

--     Wait(500)

--     for index, value in ipairs(ids) do
--         exports['interactionMenu']:remove(value)
--     end
--     for index, value in ipairs(entities) do
--         DeleteEntity(value)
--     end
-- end

-- CreateThread(function()
--     Wait(1000)

--     while true do
--         test()
--         print(Container.count())
--         Wait(500)
--     end
-- end)

-- CreateThread(function()
--     Wait(1000)
--     local numPoints = 10000

--     for i = 1, 10, 1 do
--         for ij = 1, numPoints, 1 do
--             exports['interactionMenu']:Create {
--                 type = 'position',
--                 position = vec3(math.random(0, 5000), math.random(0, 5000), math.random(0, 5000)),
--                 maxDistance = 2.0,
--                 options = {
--                     {
--                         label = 'Menu|' .. ij,
--                         icon = 'fas fa-car',
--                         action = {
--                             type = 'sync',
--                             func = function()
--                             end
--                         }
--                     },
--                 }
--             }
--         end
--         Wait(500)
--     end
-- end)

-- CreateThread(function()
--     local veh_pos = vector4(-1974.9, 3178.76, 32.81, 59.65)
--     local vehicle = Util.spawnVehicle('adder', veh_pos)

--     while true do
--         for i = 1, 100, 1 do
--             local id = exports['interactionMenu']:Create {
--                 bone = 'platelight',
--                 vehicle = vehicle,
--                 offset = vec3(0, 0, 0),
--                 maxDistance = 2.0,
--                 indicator = {
--                     prompt   = 'E',
--                     keyPress = {
--                         -- https://docs.fivem.net/docs/game-references/controls/#controls
--                         padIndex = 0,
--                         control = 38
--                     }
--                 },
--                 options = {}
--             }

--             exports['interactionMenu']:remove(id)
--         end
--         Wait(50)
--     end
-- end)
