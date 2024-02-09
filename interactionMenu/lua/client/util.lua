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
    -- print('[Interaction]:', ...)
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
    local closestDistance = math.huge
    local closestBoneName
    local closestBonePosition

    for boneName, isEnabled in pairs(boneList) do
        if isEnabled then
            local boneId = GetEntityBoneIndexByName(vehicle, boneName)
            if boneId ~= -1 then
                local bonePosition = GetWorldPositionOfEntityBone(vehicle, boneId)
                local distance = #(coords - bonePosition)

                if distance < closestDistance then
                    closestDistance = distance
                    closestBoneId = boneId
                    closestBoneName = boneName
                    closestBonePosition = bonePosition
                end
            end
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

-- rectangle probably faster!?
-- local function isPointWithinScreenBounds(screenX, screenY)
--     return isPointWithinScreen(screenX, screenY) and screenX < 0.6 and screenY < 0.6 and screenX > 0.3 and screenY > 0.3
-- end

function Util.isPointWithinScreenBounds(screenX, screenY)
    local squaredDistance = (screenX - centerX) ^ 2 + (screenY - centerY) ^ 2

    return Util.isPointWithinScreen(screenX, screenY) and squaredDistance <= radius
end

function Util.filterVisiblePointsWithinRange(playerPosition, inputPoints)
    local closestPointDistance = 15
    local closestPointIndex
    local visiblePointCount = 0
    local visiblePoints = {
        inView = {},
        closest = {}
    }
    if not playerPosition or not inputPoints or #inputPoints == 0 then return visiblePoints, 0 end

    for _, inputPoint in pairs(inputPoints) do
        local pointDistance = #(playerPosition - vector3(inputPoint.x, inputPoint.y, inputPoint.z))
        local _, screenX, screenY = GetScreenCoordFromWorldCoord(inputPoint.x, inputPoint.y, inputPoint.z)
        local isPointVisible = Util.isPointWithinScreen(screenX, screenY)

        if isPointVisible then
            local visiblePointIndex = #visiblePoints.inView + 1
            visiblePoints.inView[visiblePointIndex] = {
                id = inputPoint.id,
                point = inputPoint
            }
            visiblePointCount = visiblePointCount + 1

            if Util.isPointWithinScreenBounds(screenX, screenY) and pointDistance < closestPointDistance then
                closestPointDistance = pointDistance
                closestPointIndex = visiblePointIndex
            end
        end
    end

    if closestPointIndex then
        visiblePoints.closest = {
            id = visiblePoints.inView[closestPointIndex].id,
            point = visiblePoints.inView[closestPointIndex].point,
            distance = closestPointDistance
        }

        table.remove(visiblePoints.inView, closestPointIndex)
    end

    return visiblePoints, visiblePointCount
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

    return uniqueId
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
