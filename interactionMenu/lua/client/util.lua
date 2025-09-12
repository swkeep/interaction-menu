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
local table_remove = table.remove
local math_floor = math.floor
local math_abs = math.abs
local string_char = string.char
local math_random = math.random
local GetShapeTestResultIncludingMaterial = GetShapeTestResultIncludingMaterial
local StartShapeTestLosProbe = StartShapeTestLosProbe
local GetEntityCoords = GetEntityCoords
local glm_sincos = glm.sincos
local glm_rad = glm.rad
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

function Util.isPointWithinScreen(screenX, screenY)
    return screenX ~= -1.0 or screenY ~= -1.0
end

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

local function InitIsPointWithinScreenBounds()
    if not Config.screenBoundaryShape then return shapeCheckFunctions.none end
    return shapeCheckFunctions[Config.screenBoundaryShape] or shapeCheckFunctions.none
end

Util.isPointWithinScreenBounds = InitIsPointWithinScreenBounds()

function Util.filterVisiblePointsWithinRange(playerPosition, inputPoints, max_distance)
    if not playerPosition or not inputPoints or #inputPoints == 0 then
        return {}, 0
    end

    local visiblePoints = {}
    for i, inputPoint in ipairs(inputPoints) do
        local pointVector = vector3(inputPoint.x, inputPoint.y, inputPoint.z)
        local pointDistance = #(playerPosition - pointVector)

        if pointDistance <= (max_distance or 15) then
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

---@enum TraceFlags
TraceFlags = {
    None = 0,
    IntersectWorld = 1,
    IntersectVehicles = 2,
    IntersectPeds = 4,
    IntersectRagdolls = 8,
    IntersectObjects = 16,
    IntersectPickup = 32,
    IntersectGlass = 64,
    IntersectRiver = 128,
    IntersectFoliage = 256,
    IntersectEverything = 511
}

---@enum TraceOptionFlags
TraceOptionFlags = {
    None = 0,
    OptionIgnoreGlass = 1,
    OptionIgnoreSeeThrough = 2,
    OptionIgnoreNoCollision = 4,
    OptionDefault = 7 -- 1 + 2 + 4 =7 (Glass + SeeThrough + NoCollision)
}

---@param trace_flags TraceFlags
---@param player_ped any
---@param trace_option_flags TraceOptionFlags|nil
---@param ray_length any
---@return boolean|nil hit
---@return integer|nil target_entity
---@return vector3|nil ray_hit_position
---@return vector3|nil surface_normal
---@return integer|nil material_hash
function Util.rayCast(trace_flags, player_ped, trace_option_flags, ray_length)
    if not player_ped then return end

    local origin = GetFinalRenderedCamCoord()
    local cam_rot = GetFinalRenderedCamRot(2)
    local rot_rad = glm_rad(cam_rot)
    local sin, cos = glm_sincos(rot_rad)
    local forward = vec3(-sin.z * math_abs(cos.x), cos.z * math_abs(cos.x), sin.x)
    local destination = origin + forward * (ray_length or 10)

    local ray_handle = StartShapeTestLosProbe(
        origin.x, origin.y, origin.z,
        destination.x, destination.y, destination.z,
        trace_flags or 511,
        player_ped,
        trace_option_flags or 4
    )

    for _ = 1, 3 do
        local status, hit, ray_hit_position, surface_normal, material_hash, target_entity =
            GetShapeTestResultIncludingMaterial(ray_handle)

        if status ~= 1 then
            return hit, target_entity, ray_hit_position, surface_normal, material_hash
        end

        Wait(0)
    end
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

function StateManager.set(key_or_table, value)
    if type(key_or_table) == "table" then
        for k, v in pairs(key_or_table) do
            if StateManager[k] ~= v then
                StateManager[k] = v
            end
        end
    else
        if StateManager[key_or_table] ~= value then
            StateManager[key_or_table] = value
        end
    end
end

function StateManager.reset()
    StateManager.id = nil
    StateManager.menuType = nil
    StateManager.entityHandle = nil
    StateManager.entityModel = nil
    StateManager.disableRayCast = false
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

---comment
---@param table any
---@param len any
---@return string
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

local function reqmodel(objectModel, timeout)
    timeout = timeout or 5000
    local start = GetGameTimer()

    RequestModel(objectModel)
    while not HasModelLoaded(objectModel) do
        if GetGameTimer() - start > timeout then
            print(("⚠️ Model %s failed to load in %d ms"):format(objectModel, timeout))
            return false
        end
        Wait(0)
        RequestModel(objectModel)
    end

    return true
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
--             Wait(0)
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
