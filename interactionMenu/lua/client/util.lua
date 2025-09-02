--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
DEVMODE = Config.devMode or false

-- cache
local glm = require 'glm'
local GetScreenCoordFromWorldCoord = GetScreenCoordFromWorldCoord
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetWorldPositionOfEntityBone = GetWorldPositionOfEntityBone
local table_remove = table.remove
local math_floor = math.floor
local math_cos = math.cos
local math_rad = math.rad
local math_sin = math.sin
local string_char = string.char
local math_random = math.random

local upVector = glm.up()
local forwardVector = glm.forward()
local getCamCoord = GetFinalRenderedCamCoord
local getCamRot = GetFinalRenderedCamRot
local toRadians = glm.rad
local createQuaternion = glm.quatEulerAngleZYX
local rayPicking = glm.rayPicking
local HasEntityClearLosToEntity = HasEntityClearLosToEntity
local GetShapeTestResult = GetShapeTestResult
local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetFinalRenderedCamFov = GetFinalRenderedCamFov
local GetAspectRatio = GetAspectRatio
local GetEntityCoords = GetEntityCoords

local object = {}
-- center of the screen!
local centerX, centerY = 0.45, 0.45
local radius = 0.2 ^ 2


Util = {}

function Util.print_debug(...)
    if not DEVMODE then return end
    print('[Interaction]:', ...)
end

--- Function to find the closest bone on a vehicle based on a list of bone names
---@param coords vector3|vector4 "The position, likely the rayCast hitPosition"
---@param vehicle number "The entity handle"
---@param boneList table "A table containing bone names"
---@return number "boneId"
---@return unknown "boneName"
---@return number "The distance from hitPosition to the closest bone on the vehicle"
---@return unknown|vector3 "The world position of the closest bone on the vehicle"
function Util.getClosestVehicleBone(coords, vehicle, boneList)
    local closestBoneId = -1
    local closestDistance = 10000
    local closestBoneName
    local closestBonePosition
    local isHoodOpen = GetVehicleDoorAngleRatio(vehicle, 4) > 0.9
    local isHoodDamaged = IsVehicleDoorDamaged(vehicle, 4)

    for boneName, isEnabled in pairs(boneList) do
        if isEnabled then
            local boneId = GetEntityBoneIndexByName(vehicle, boneName)
            if boneId ~= -1 then
                if boneName == "engine" and (isHoodDamaged == false and not isHoodOpen) then
                    goto continue
                end

                if boneName == "bonnet" and isHoodDamaged then
                    goto continue
                end

                local bonePosition = GetEntityBonePosition_2(vehicle, boneId)
                local distance = #(coords - bonePosition)

                if distance <= closestDistance then
                    closestDistance = distance
                    closestBoneId = boneId
                    closestBoneName = boneName
                    closestBonePosition = bonePosition
                end
            end
            ::continue::
        end
    end

    return closestBoneId, closestBoneName, closestDistance, closestBonePosition
end

function Util.getRotatedOffset(rotation, offset)
    rotation = math_rad(rotation)
    local sin_r = math_sin(rotation)
    local cos_r = math_cos(rotation)

    local x = offset.x * cos_r - offset.y * sin_r
    local y = offset.x * sin_r + offset.y * cos_r
    return x, y, offset.z
end

function Util.isPointWithinScreen(screenX, screenY)
    return screenX ~= -1.0 or screenY ~= -1.0
end

local function InitIsPointWithinScreenBounds()
    local shapeCheckFunctions = {
        rectangle = function(x, y)
            return x < 0.6 and y < 0.6 and x > 0.3 and y > 0.3
        end,
        circle = function(x, y)
            local squaredDistance = (x - centerX) ^ 2 + (y - centerY) ^ 2
            -- return squaredDistance <= radius^2
            return squaredDistance <= radius
        end,
        none = function()
            return true
        end
    }

    if not Config.screenBoundaryShape then return shapeCheckFunctions.none end
    return shapeCheckFunctions[Config.screenBoundaryShape] or shapeCheckFunctions.none
end

Util.isPointWithinScreenBounds = InitIsPointWithinScreenBounds()

function Util.filterVisiblePointsWithinRange(playerPosition, inputPoints)
    if not playerPosition or not inputPoints or #inputPoints == 0 then
        return {}, 0
    end

    local visiblePoints = {}
    for i, inputPoint in ipairs(inputPoints) do
        local pointVector = vector3(inputPoint.x, inputPoint.y, inputPoint.z)
        local pointDistance = #(playerPosition - pointVector)

        if pointDistance <= 15 then
            local _, screenX, screenY = GetScreenCoordFromWorldCoord(inputPoint.x, inputPoint.y, inputPoint.z)

            if Util.isPointWithinScreen(screenX, screenY) and Util.isPointWithinScreenBounds(screenX, screenY) then
                visiblePoints[#visiblePoints + 1] = {
                    id = inputPoint.id,
                    point = inputPoint,
                    distance = pointDistance,
                    screenX = screenX,
                    screenY = screenY
                }
            end
        end
    end

    if #visiblePoints > 1 then
        table.sort(visiblePoints, function(a, b)
            return a.distance < b.distance
        end)
    end

    return visiblePoints, #visiblePoints
end

local nearClip = 0.1
local farClip = 10000.0

local function screenPositionToCameraRay(fieldOfView, aspectRatio)
    local camPos = getCamCoord()
    local camRot = toRadians(getCamRot(2))
    local quaternion = createQuaternion(camRot.z, camRot.y, camRot.x)
    local camForward = quaternion * forwardVector
    local camUp = quaternion * upVector

    return camPos, rayPicking(camForward, camUp, fieldOfView, aspectRatio, nearClip, farClip, 0, 0)
end

function DotProduct3D(x1, y1, z1, x2, y2, z2)
    return x1 * x2 + y1 * y2 + z1 * z2
end

function Util.rayCast(maxDist, playerPed)
    if not playerPed then return end

    local aspectRatio = GetAspectRatio(true)
    local fieldOfView = toRadians(GetFinalRenderedCamFov())
    local losProbeFlags = 23
    local rayLength = 16 -- or rayscale?

    local playerCoords = GetEntityCoords(playerPed)
    if not playerCoords then return end

    local rayPos, rayDir = screenPositionToCameraRay(fieldOfView, aspectRatio)
    local dest = rayPos + (rayLength * rayDir)
    local rayHandle = StartShapeTestLosProbe(rayPos.x, rayPos.y, rayPos.z, dest.x, dest.y, dest.z, losProbeFlags,
        playerPed, 4)

    -- endCoords: The resulting coordinates where the shape test hit a collision
    -- surfaceNormal: The surface normal of the hit position
    local status, hit, endCoords, surfaceNormal, entityHit, distance

    -- in some of my tests 2 was working fine but sometimes sometimes it just didn't work
    for i = 1, 3, 1 do
        status, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)

        if status == 2 and hit then
            distance = #(playerCoords - endCoords)
            if maxDist < distance then return nil, nil, nil end

            -- #TEST: seems to works fine without it!?
            -- hasClearSight = HasEntityClearLosToEntity(entityHit, playerPed, 7)
            break
        end
        Wait(0)
    end

    return endCoords, entityHit, distance
end

local SpatialHashGrid = {
    data = {}
}

---@class Item
---@field x number
---@field y number
---@field id number|string

--- Creates a new SpatialHashGrid instance.
---@param cellSize number "The size of each grid cell"
---@return table "A new SpatialHashGrid instance"
function SpatialHashGrid:new(name, cellSize)
    if SpatialHashGrid.data[name] then return SpatialHashGrid.data[name] end

    local t = {}

    t.name = name
    t.cellSize = cellSize
    t.cells = {}

    SpatialHashGrid.data[name] = t

    setmetatable(t, self)
    self.__index = self

    return t
end

--- Inserts an item into the grid
---@param item Item "The item to insert. The item must have 'x' and 'y' properties"
function SpatialHashGrid:insert(item)
    local x, y = item.x, item.y
    local cellX, cellY = math_floor(x / self.cellSize), math_floor(y / self.cellSize)

    self.cells[cellX] = self.cells[cellX] or {}
    local cell = self.cells[cellX][cellY]
    if not cell then
        cell = {}
        self.cells[cellX][cellY] = cell
    end

    cell[#cell + 1] = item
end

function SpatialHashGrid:isPositionOccupied(position, _radius, excludeId)
    _radius = _radius or 1
    local radiusSquared = _radius * _radius

    -- Determine cells within the query range
    local minCellX = math_floor((position.x - _radius) / self.cellSize)
    local maxCellX = math_floor((position.x + _radius) / self.cellSize)
    local minCellY = math_floor((position.y - _radius) / self.cellSize)
    local maxCellY = math_floor((position.y + _radius) / self.cellSize)

    for i = minCellX, maxCellX do
        for j = minCellY, maxCellY do
            local cell = self.cells[i] and self.cells[i][j]
            if cell then
                for cell_index, item in ipairs(cell) do
                    -- Skip excluded item if specified
                    if not excludeId or item.id ~= excludeId then
                        local dx = item.x - position.x
                        local dy = item.y - position.y
                        if dx * dx + dy * dy <= radiusSquared then
                            return true, item, { x = i, y = j, index = cell_index }
                        end
                    end
                end
            end
        end
    end

    return false, nil
end

function SpatialHashGrid:_raw_remove(cellX, cellY, index)
    local cell = self.cells[cellX] and self.cells[cellX][cellY]

    if cell then
        table_remove(cell, index)
    end
end

--- Removes an item from the grid
---@param item Item "The item to remove"
function SpatialHashGrid:remove(item)
    local x, y = item.x, item.y
    local cellX, cellY = math_floor(x / self.cellSize), math_floor(y / self.cellSize)

    local cell = self.cells[cellX] and self.cells[cellX][cellY]

    if cell then
        for i, v in ipairs(cell) do
            if v == item then
                table_remove(cell, i)
                break
            end
        end
    end
end

--- Updates the position of an item within the grid
---@param item Item "item ref"
function SpatialHashGrid:update(item, pos)
    local newX, newY = pos.x, pos.y

    -- Remove from old cell
    local oldCellX, oldCellY = math_floor(item.x / self.cellSize), math_floor(item.y / self.cellSize)
    local oldCell = self.cells[oldCellX] and self.cells[oldCellX][oldCellY]
    if oldCell then
        for i, v in ipairs(oldCell) do
            if v == item then
                table_remove(oldCell, i)
                break
            end
        end
    end

    self:insert(item)
    item.x = newX
    item.y = newY
end

--- Queries for items within a circular range around a given position
---@param position vector2|vector3|vector4 "The center position"
---@param rangeRadius number "The radius of the query range"
---@return table "A table containing items within the range"
---@return number "Results count "
function SpatialHashGrid:queryRange(position, rangeRadius)
    local results = {}

    -- Determine cells within the query range
    local minCellX = math_floor((position.x - rangeRadius) / self.cellSize)
    local maxCellX = math_floor((position.x + rangeRadius) / self.cellSize)
    local minCellY = math_floor((position.y - rangeRadius) / self.cellSize)
    local maxCellY = math_floor((position.y + rangeRadius) / self.cellSize)

    -- Iterate through relevant cells and check items within range
    for i = minCellX, maxCellX do
        for j = minCellY, maxCellY do
            local cell = self.cells[i] and self.cells[i][j]
            if cell then
                for _, item in ipairs(cell) do
                    local dx = item.x - position.x
                    local dy = item.y - position.y
                    if dx * dx + dy * dy <= rangeRadius * rangeRadius then
                        results[#results + 1] = item
                    end
                end
            end
        end
    end


    return results, #results
end

function SpatialHashGrid:get(name)
    return self.data[name]
end

Util.SpatialHashGrid = SpatialHashGrid

-- #region PersistentData

-- Helpers

-- class: PersistentData
-- managing persistent data storage of menus
local PersistentData = { data = {} }

function PersistentData.set(id, data)
    PersistentData.data[id] = data
    return PersistentData.data[id]
end

function PersistentData.clear(id)
    PersistentData.data[id] = nil
end

function PersistentData.hasBeenSet(id)
    return PersistentData.data[id] and true or false
end

function PersistentData.get(id)
    return PersistentData.data[id]
end

function Util.PersistentData()
    return PersistentData
end

-- #endregion

-- #region StateManager

-- class: StateManager
local StateManager = {
    id = 0,
    playerPed = 0,
    playerPosition = vec3(0, 0, 0),
    playerIsInVehicle = false,
    menuType = 0,
    entityModel = 0,
    entityHandle = 0
}

function StateManager.set(t, value, batch)
    if StateManager[t] == value then return end

    if not batch then
        StateManager[t] = value
    else
        local data = t
        for i, v in pairs(data) do
            StateManager[i] = v
        end
    end
end

function StateManager.reset()
    StateManager.id = nil
    StateManager.menuType = nil
    StateManager.entityHandle = nil
    StateManager.entityModel = nil
end

function StateManager.get(t)
    return (not t) and StateManager or StateManager[t]
end

function Util.StateManager()
    return StateManager
end

-- #endregion

-- #region Helpers

local function randomId(length)
    local string = ''
    for i = 1, length do
        local str = string_char(math_random(97, 122))
        if math_random(1, 2) == 1 then
            if math_random(1, 2) == 1 then str = str:upper() else str = str:lower() end
        else
            str = tostring(math_random(0, 9))
        end
        string = string .. str
    end
    return string
end

function Util.createUniqueId(table, len)
    len = len or 13
    local hash = randomId(len)
    local uniqueId = hash

    while table[uniqueId] do
        -- bruh
        uniqueId = randomId(len)
    end

    return GetGameTimer() .. uniqueId
end

--- Checks the job data
---@param data table
---@return boolean
function Util.isJobAllowed(data)
    if not data.extra or not data.extra.job then return true end
    local job_name, current_grade = Bridge.getJob()
    return data.extra.job and data.extra.job[job_name] and data.extra.job[job_name][current_grade]
end

function Util.table_merge(t1, t2)
    for k, v in pairs(t2) do t1[#t1 + 1] = v end
    return t1
end

-- fake enum
function Util.ENUM(t)
    for index, value in ipairs(t) do t[value] = index end
    return t
end

function Util.print_table(t)
    print(json.encode(t, { indent = true, sort_keys = true }))
end

function Util.preloadSharedTextureDict()
    while not HasStreamedTextureDictLoaded("shared") do
        Wait(10)
        RequestStreamedTextureDict("shared", true)
    end
end

local function reqmodel(objectModel)
    RequestModel(objectModel)
    while not HasModelLoaded(objectModel) do
        RequestModel(objectModel)
        Wait(0)
    end
end

function Util.spawnObject(objectModel, c, door, net)
    reqmodel(objectModel)

    local id = #object + 1
    object[id] = CreateObject(objectModel, c.x, c.y, c.z, net or false, net or false, door or false)

    if not door then
        FreezeEntityPosition(object[id], true)
    else
        -- no gravity door to test offset rotation
        SetEntityHasGravity(object[id], false)
    end
    SetEntityHeading(object[id], c.w or 0)

    SetModelAsNoLongerNeeded(objectModel)
    return object[id]
end

function Util.spawnVehicle(vehicleModel, spawnPoint)
    reqmodel(vehicleModel)

    local id = #object + 1
    object[id] = CreateVehicle(vehicleModel, spawnPoint.x, spawnPoint.y, spawnPoint.z, spawnPoint.w, false, false)

    SetModelAsNoLongerNeeded(vehicleModel)
    return object[id]
end

function Util.spawnPed(hash, pos)
    reqmodel(hash)

    local id   = #object + 1
    object[id] = CreatePed(5, hash, pos.x, pos.y, pos.z, 0.0, false, true)
    while not DoesEntityExist(object[id]) do Wait(10) end

    SetEntityHeading(object[id], pos.w)
    SetBlockingOfNonTemporaryEvents(object[id], true)
    SetPedFleeAttributes(object[id], 0, false)
    SetPedCombatAttributes(object[id], 46, true)
    SetPedAlertness(object[id], 3)
    SetModelAsNoLongerNeeded(object[id])
    FreezeEntityPosition(object[id], true)

    return object[id]
end

-- validation zone data (it still needs more work it wrote it for PolyZone only ox have some differences)
local function validateZoneData(o)
    if type(o) ~= "table" then
        error("Zone data must be a table")
    end

    -- common
    assert(type(o.type) == "string", "Zone type must be a string")

    -- validate position
    if o.position then
        local t = type(o.position)
        if not (t == 'vector3' or t == 'vector4') then
            assert(type(o.position) == "table" and o.position.x and o.position.y and o.position.z,
                "Position must be a table with x, y, z coordinates")
            assert(type(o.position.x) == "number" and type(o.position.y) == "number" and type(o.position.z) == "number",
                "Position coordinates must be numbers")
        end
    end

    -- type things
    if o.type == 'circleZone' or o.type == 'circle' or o.type == 'sphere' then
        assert(type(o.radius) == "number", "Radius must be a number")
    elseif o.type == 'boxZone' or o.type == 'box' or o.type == 'rectangle' then
        assert(type(o.length) == "number", "Length must be a number")
        assert(type(o.width) == "number", "Width must be a number")
        assert(o.heading == nil or type(o.heading) == "number", "Heading must be a number if provided")
        assert(o.minZ == nil or type(o.minZ) == "number", "minZ must be a number if provided")
        assert(o.maxZ == nil or type(o.maxZ) == "number", "maxZ must be a number if provided")
    elseif o.type == 'polyZone' or o.type == 'poly' then
        assert(type(o.points) == "table", "Points must be a table of coordinates")
        for _, point in ipairs(o.points) do
            assert(type(point.x) == "number" and type(point.y) == "number" and type(point.z) == "number",
                "Each point must have numeric x, y, z coordinates")
        end
    elseif o.type == 'comboZone' or o.type == 'combo' then
        assert(type(o.zones) == "table", "Zones must be a table of zone definitions")
        for _, zoneData in ipairs(o.zones) do
            validateZoneData(zoneData) -- recursive
        end
    else
        error("Unsupported zone type: " .. tostring(o.type))
    end
end

local onPlayerIn = function(name)
    TriggerEvent('interactionMenu:zoneTracker', name, true)
end

local onPlayerOut = function(name)
    TriggerEvent('interactionMenu:zoneTracker', name, false)
end

local function InitAddZone()
    -- auto detect
    if GetResourceState('ox_lib') == 'started' and lib then
        Config.triggerZoneScript = 'ox_lib'
    elseif GetResourceState('PolyZone') == 'started' then
        Config.triggerZoneScript = 'PolyZone'
    end

    local zoneFunctions = {
        ox_lib = function(o)
            assert(lib, "ox_lib is not loaded. Uncomment '-- @ox_lib/init.lua' in fxmanifest.lua")
            validateZoneData(o)

            local z
            if o.type == 'circleZone' or o.type == 'circle' or o.type == 'sphere' then
                z = lib.zones.sphere({
                    coords = vec3(o.position.x, o.position.y, o.position.z),
                    radius = o.radius or 2,
                    debug = o.debugPoly,
                    inside = o.inside,
                })
            elseif o.type == 'boxZone' or o.type == 'box' or o.type == 'rectangle' then
                o.minZ = o.minZ or 0
                o.maxZ = o.maxZ or 1
                local useZ = o.useZ or not o.maxZ
                local sizeZ = useZ and o.position.z or math.abs(o.maxZ - o.minZ)

                z = lib.zones.box({
                    coords = vec3(o.position.x, o.position.y, o.position.z),
                    size = o.size or vec3(o.length, o.width, sizeZ),
                    rotation = o.heading or 0,
                    debug = o.debugPoly,
                    inside = o.inside,
                })
            elseif o.type == 'polyZone' or o.type == 'poly' then
                z = lib.zones.poly({
                    points = o.points,
                    thickness = o.thickness or 4,
                    debug = o.debugPoly,
                    inside = o.inside,
                })
            elseif o.type == 'comboZone' or o.type == 'combo' then
                warn("Unsupported zone type with ox_lib: " .. tostring(o.type))
            else
                error("Unsupported zone type: " .. tostring(o.type))
            end
            if z then
                z.onEnter = function() onPlayerIn(o.name) end
                z.onExit = function() onPlayerOut(o.name) end
            end
            z.name = o.name

            return z
        end,
        PolyZone = function(o)
            validateZoneData(o)
            local z
            -- Using PolyZone for zone creation
            if o.type == 'circleZone' or o.type == 'circle' or o.type == 'sphere' then
                assert(CircleZone,
                    "PolyZone CircleZone is not loaded. Uncomment '@PolyZone/CircleZone.lua' in fxmanifest.lua")
                z = CircleZone:Create(vec3(o.position.x, o.position.y, o.position.z), o.radius or 1.0, {
                    name = o.name,
                    debugPoly = o.debugPoly,
                    useZ = o.useZ or false,
                })
            elseif o.type == 'boxZone' or o.type == 'box' or o.type == 'rectangle' then
                assert(BoxZone,
                    "PolyZone BoxZone is not loaded. Uncomment '@PolyZone/BoxZone.lua' in fxmanifest.lua")
                z = BoxZone:Create(vec3(o.position.x, o.position.y, o.position.z), o.length or 1.0, o.width or 1.0, {
                    name = o.name,
                    heading = o.heading,
                    debugPoly = o.debugPoly,
                    minZ = o.minZ,
                    maxZ = o.maxZ,
                })
            elseif o.type == 'polyZone' or o.type == 'poly' then
                assert(PolyZone,
                    "PolyZone is not loaded. Uncomment '@PolyZone/client.lua' in fxmanifest.lua")
                z = PolyZone:Create(o.points, {
                    name = o.name,
                    minZ = o.minZ,
                    maxZ = o.maxZ,
                    debugPoly = o.debugPoly,
                })
            elseif o.type == 'comboZone' or o.type == 'combo' then
                assert(ComboZone,
                    "PolyZone ComboZone is not loaded. Uncomment '@PolyZone/ComboZone.lua' in fxmanifest.lua")
                local zones = {}
                for _, zoneData in ipairs(o.zones) do
                    if zoneData.type ~= 'comboZone' then
                        table.insert(zones, Util.addZone(zoneData))
                    end
                end
                z = ComboZone:Create(zones, {
                    name = o.name,
                    debugPoly = o.debugPoly,
                })
            else
                error("Unsupported zone type: " .. tostring(o.type))
            end

            if z then
                z:onPlayerInOut(function(isPointInside)
                    if isPointInside then
                        onPlayerIn(o.name)
                    else
                        onPlayerOut(o.name)
                    end
                end)
            end
            return z
        end,
        none = function() return end
    }

    return zoneFunctions[Config.triggerZoneScript]
end

Util.addZone = InitAddZone()

-- #endregion

-- DEVMODE raycast hit marker
-- CreateThread(function()
--     if not DEVMODE then return end

--     local sphereRadius = 0.09
--     while true do
--         local sphereCenter = StateManager.get('hitPosition')
--         local active = StateManager.get('id')

--         if active and sphereCenter and type(sphereCenter) == 'vector3' then
--             DrawMarker(28, sphereCenter.x, sphereCenter.y, sphereCenter.z, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, sphereRadius
--                 , sphereRadius,
--                 sphereRadius, 255, 128, 0, 50, false, true, 2, nil, nil, false)
--             Wait(10)
--         else
--             Wait(1000)
--         end
--     end
-- end)

function AddEntityToCollection(obj)
    object[#object + 1] = obj
end

-- Garbage collection
AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    for key, value in pairs(object) do
        if DoesEntityExist(value) then DeleteEntity(value) end
    end
end)

Util.ensureTable = function(input)
    if type(input) ~= 'table' then return { input } end
    return input
end

Util.cleanString = function(str)
    return str:gsub("[%s%p]", "")
end

local function not_supported(name)
    warn(("interactionMenu doesn't support %s"):format(name))
end

local eventNameTemplate = '__cfx_export_%s_%s'
Util.replaceExport = function(resourceName, exportName, func)
    if func and type(func) ~= 'function' then
        warn('replaceExport: The provided func must be a function or nil')
        func = nil
    end

    local eventName = eventNameTemplate:format(resourceName, exportName)
    local cb = func or function() not_supported(exportName) end

    AddEventHandler(eventName, function(setCB)
        setCB(cb)
    end)
end

-- Standalone `BoundingBox` handler

local grid_entitites = SpatialHashGrid:new('entities', 100)

EntityDetector = {
    hash = {},
    zones = {},
    lastClosestEntity = nil
}

local function rotatePoint(point, center, angle)
    local x = point.x - center.x
    local y = point.y - center.y
    local cosAngle = math.cos(math.rad(angle))
    local sinAngle = math.sin(math.rad(angle))
    local rotatedX = x * cosAngle - y * sinAngle
    local rotatedY = x * sinAngle + y * cosAngle
    return vector3(rotatedX + center.x, rotatedY + center.y, point.z)
end

local function calculateMinAndMaxZ(entity, dimensions)
    local min, max = dimensions[1], dimensions[2]

    local entityPos = GetEntityCoords(entity)
    local entityMinZ = entityPos.z + min.z
    local entityMaxZ = entityPos.z + max.z

    return entityMinZ, entityMaxZ
end

function EntityDetector.watch(entity, options)
    assert(DoesEntityExist(entity), "Entity does not exist")

    local id = #EntityDetector.zones + 1
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local dimensions = options.dimensions or { vec3(min.x, min.y, min.z), vec3(max.x, max.y, max.z) }

    local instance = {}
    instance.entity = entity
    instance.dimensions = dimensions
    instance.useZ = options.useZ

    if options.useZ then
        instance.minZ, instance.maxZ = calculateMinAndMaxZ(entity, dimensions)
    end

    instance.id                 = id
    EntityDetector.zones[id]    = instance
    EntityDetector.hash[entity] = id
    -- init spatial hash grid ref/item
    local entityPos             = GetEntityCoords(entity)
    instance.grid_ref           = {
        id = id,
        x = entityPos.x,
        y = entityPos.y,
        z = entityPos.z,
    }
    grid_entitites:insert(instance.grid_ref)
    return instance
end

function EntityDetector.unwatch(entity)
    local index = EntityDetector.hash[entity]
    if not index then return false end
    local instance = EntityDetector.zones[index]
    EntityDetector.hash[entity] = nil
    -- remove from grid
    grid_entitites:remove(instance.grid_ref)
    -- #TODO: it does use memory, we can deal with it later
    table.wipe(EntityDetector.zones[instance.id])
end

local function isPointInBoundingBox(point, box, rotation)
    local rotatedPoint = rotatePoint(point, box.min + (box.max - box.min) / 2, -rotation)

    return rotatedPoint.x >= box.min.x and rotatedPoint.x <= box.max.x and
        rotatedPoint.y >= box.min.y and rotatedPoint.y <= box.max.y and
        rotatedPoint.z >= box.min.z and rotatedPoint.z <= box.max.z
end

local function detectorQueryRange(p)
    p = p or GetEntityCoords(PlayerPedId(), false)
    return grid_entitites:queryRange(p, 25)
end

local function detectorDetect(playerPos)
    local closestEntity = nil
    local closestDistance = math.huge

    for _, grid_ref in ipairs(detectorQueryRange(playerPos)) do
        local instance = EntityDetector.zones[grid_ref.id]
        local entity = instance.entity
        local entityHeading = instance.rotation
        local entityPos = instance.position

        if not instance.pause and entityHeading and entityPos then
            local minCorner = instance.dimensions[1]
            local maxCorner = instance.dimensions[2]
            local entityBox = {
                min = entityPos + minCorner,
                max = entityPos + maxCorner
            }

            if isPointInBoundingBox(playerPos, entityBox, entityHeading) then
                -- this way we can detect coliding zones
                local distance = #(playerPos - entityPos)

                if distance < closestDistance then
                    closestDistance = distance
                    closestEntity = {
                        entity = entity,
                        id = instance.id,
                        dimensions = instance.dimensions
                    }
                end
            end
        end
    end

    -- Trigger events if the closest entity has changed
    if closestEntity then
        if EntityDetector.lastClosestEntity then
            if closestEntity.entity ~= EntityDetector.lastClosestEntity.entity then
                TriggerEvent('interactionMenu:client:entityZone:exited', EntityDetector.lastClosestEntity)
                Wait(0)
                TriggerEvent('interactionMenu:client:entityZone:entered', closestEntity)
            end
        else
            TriggerEvent('interactionMenu:client:entityZone:entered', closestEntity)
        end

        EntityDetector.lastClosestEntity = closestEntity
    elseif EntityDetector.lastClosestEntity then
        TriggerEvent('interactionMenu:client:entityZone:exited', EntityDetector.lastClosestEntity)
        EntityDetector.lastClosestEntity = nil
    end
end

local function detectorUpdateEntityInfo(playerPos)
    if EntityDetector.lastClosestEntity then
        -- just update what is active
        local instance = EntityDetector.zones[EntityDetector.lastClosestEntity.id]
        if instance and instance.entity then
            if DoesEntityExist(instance.entity) then
                instance.position = GetEntityCoords(instance.entity)
                instance.rotation = GetEntityHeading(instance.entity)
                if instance.useZ then
                    instance.minZ, instance.maxZ = calculateMinAndMaxZ(instance.entity, instance.dimensions)
                end
            end
        end
        return
    end

    for index, grid_ref in ipairs(detectorQueryRange(playerPos)) do
        local instance = EntityDetector.zones[grid_ref.id]
        if instance and instance.entity then
            if DoesEntityExist(instance.entity) then
                instance.position = GetEntityCoords(instance.entity)
                instance.rotation = GetEntityHeading(instance.entity)
                if instance.useZ then
                    instance.minZ, instance.maxZ = calculateMinAndMaxZ(instance.entity, instance.dimensions)
                end
            end
        end
    end
end

CreateThread(function()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    -- update information of entity
    CreateThread(function()
        while true do
            local interval = EntityDetector.lastClosestEntity and 250 or 1000
            playerPed = PlayerPedId()
            detectorUpdateEntityInfo(playerPos)
            Wait(interval)
        end
    end)

    -- detection tread
    CreateThread(function()
        while true do
            local interval = EntityDetector.lastClosestEntity and 250 or 1000

            playerPos = GetEntityCoords(playerPed)
            detectorDetect(playerPos)
            Wait(interval)
        end
    end)

    -- update position of entities in hash grid
    CreateThread(function()
        local size = #EntityDetector.zones
        local chunkSize = 100
        local startIndex = 1

        while true do
            while startIndex <= size do
                local endIndex = math.min(startIndex + chunkSize - 1, size)
                for index = startIndex, endIndex do
                    local instance = EntityDetector.zones[index]
                    if DoesEntityExist(instance.entity) then
                        instance.pause = false
                        local position = GetEntityCoords(instance.entity)
                        grid_entitites:update(instance.grid_ref, position)
                    else
                        instance.pause = true
                    end
                end

                Wait(1000)
                startIndex = endIndex + 1
            end

            Wait(2000)
            startIndex = 1
            size = #EntityDetector.zones
        end
    end)

    if Config.devMode and Config.debugPoly then
        -- AddEventHandler('entityZone:client:exited', function(data)
        --     print("Exit", data.entity)
        -- end)

        -- AddEventHandler('entityZone:client:entered', function(data)
        --     print("Enter", data.entity)
        -- end)

        -- draw a line between two points
        local function drawLineBetweenPoints(p1, p2, r, g, b, a)
            DrawLine(p1.x, p1.y, p1.z, p2.x, p2.y, p2.z, r, g, b, a)
        end

        -- draw a 3D box around an entity
        local function drawBoundingBox(instance)
            if instance and (instance.entity and not DoesEntityExist(instance.entity)) then return end
            local entityPos = instance.position
            local entityHeading = instance.rotation
            if not entityPos or not entityHeading then return end
            local dimensions = instance.dimensions
            local min = dimensions[1]
            local max = dimensions[2]

            -- Calculate rotated corners
            local corners = {
                -- Bottom rectangle
                entityPos + vector3(min.x, min.y, min.z),
                entityPos + vector3(max.x, min.y, min.z),
                entityPos + vector3(max.x, max.y, min.z),
                entityPos + vector3(min.x, max.y, min.z),

                -- Top rectangle
                entityPos + vector3(min.x, min.y, max.z),
                entityPos + vector3(max.x, min.y, max.z),
                entityPos + vector3(max.x, max.y, max.z),
                entityPos + vector3(min.x, max.y, max.z),
            }

            -- rotate corners
            local cosHeading, sinHeading = math.cos(math.rad(entityHeading)), math.sin(math.rad(entityHeading))
            for i, corner in ipairs(corners) do
                local x, y = corner.x - entityPos.x, corner.y - entityPos.y
                local rotatedX = x * cosHeading - y * sinHeading
                local rotatedY = x * sinHeading + y * cosHeading
                corners[i] = vector3(rotatedX + entityPos.x, rotatedY + entityPos.y, corner.z)
            end

            -- Bottom
            drawLineBetweenPoints(corners[1], corners[2], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[2], corners[3], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[3], corners[4], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[4], corners[1], 255, 0, 0, 255)

            -- Top
            drawLineBetweenPoints(corners[5], corners[6], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[6], corners[7], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[7], corners[8], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[8], corners[5], 255, 0, 0, 255)

            -- Vertical lines
            drawLineBetweenPoints(corners[1], corners[5], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[2], corners[6], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[3], corners[7], 255, 0, 0, 255)
            drawLineBetweenPoints(corners[4], corners[8], 255, 0, 0, 255)
        end

        CreateThread(function()
            local size = 1.0
            while true do
                if EntityDetector.lastClosestEntity and EntityDetector.lastClosestEntity.entity then
                    local instance = EntityDetector.zones[EntityDetector.lastClosestEntity.id]
                    local entityCoords = GetEntityCoords(instance.entity)

                    if entityCoords then
                        DrawMarker(1, entityCoords.x, entityCoords.y, entityCoords.z - 0.5, 0.0, 0.0, 0.0, 0.0, 0.0,
                            0.0,
                            size
                            , size,
                            size, 255, 128, 0, 150, false, true, 2, nil, nil, false, false)
                    end
                end
                Wait(0)
            end
        end)
        CreateThread(function()
            while true do
                for _, instance in ipairs(EntityDetector.zones) do
                    drawBoundingBox(instance)
                end
                Wait(0)
            end
        end)
    end
end)
