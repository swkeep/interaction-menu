if not Config.features.drawIndicator.active then
    return
end

-- #region Show sprite while holding alt

local SpatialHashGrid = Util.SpatialHashGrid
local currentSpriteThreadHash = nil
local isSpriteThreadRunning = false
local isTargetSpritesActive = false
local StateManager = Util.StateManager()
local grid_position = SpatialHashGrid:new('position', 100)
local visiblePoints = {}
local visiblePointCount = 0

CreateThread(function()
    local txd = CreateRuntimeTxd('interaction_txd_indicator')
    CreateRuntimeTextureFromImage(txd, 'indicator', "lua/client/icons/indicator.png")
    for index, value in ipairs(Config.icons) do
        CreateRuntimeTextureFromImage(txd, value, ("lua/client/icons/%s.png"):format(value))
    end
end)

-- even tho we can set it using the menu's data i use a const white color
-- sprite colors
local red = 255
local green = 255
local blue = 255
local alpha = 255

-- minimum and maximum scale factors for x and y
local minScaleX = 0.02 / 4
local maxScaleX = minScaleX * 5
local minScaleY = 0.035 / 4
local maxScaleY = minScaleY * 5

-- Distance thresholds
local minDistance = 2.0
local maxDistance = 20.0
local maxEntities = 10

-- draw the sprite with scaling based on distance
local function drawSprite(p, player_position, icon)
    if not p then return end
    -- Calculate the distance between the player and the point
    local distance = #(vec3(p.x, p.y, p.z) - player_position)
    local clampedDistance = math.max(minDistance, math.min(maxDistance, distance))

    -- Pre-calculate the scale factor range
    local scaleRangeX = maxScaleX - minScaleX
    local scaleRangeY = maxScaleY - minScaleY
    local distanceRange = maxDistance - minDistance
    local normalizedDistance = (clampedDistance - minDistance) / distanceRange

    -- Calculate the scale factors based on the clamped distance
    local scaleX = minScaleX + scaleRangeX * (1 - normalizedDistance)
    local scaleY = minScaleY + scaleRangeY * (1 - normalizedDistance)

    -- Set the draw origin to the point's coordinates
    SetDrawOrigin(p.x, p.y, p.z, 0)

    -- Draw the sprite with the calculated scales
    DrawSprite('interaction_txd_indicator', icon or 'indicator', 0, 0, scaleX, scaleY, 0, red, green, blue, alpha)
    ClearDrawOrigin()
end

local nearby_objects = {}
local nearby_objects_limited = {}

local function getNearbyObjects(isActive, currentMenu, coords)
    local objects = GetGamePool('CObject')
    local entityHandle = StateManager.get('entityHandle')
    nearby_objects_limited = {}

    for i = 1, #objects do
        local object = objects[i]
        local objectCoords = GetEntityCoords(object)
        local distance = #(coords - objectCoords)

        if distance < maxDistance then
            local existingData = nearby_objects[object]
            local entity_type = GetEntityType(object)
            local model = GetEntityModel(object)

            local menuType = Container.getMenuType {
                model = model,
                entity = object,
                entityType = entity_type
            }

            if menuType > 1 and entityHandle ~= object then
                if not existingData then
                    local menu = Container.getMenu(model, object, nil)
                    nearby_objects[object] = {
                        object = object,
                        coords = objectCoords,
                        type = entity_type,
                        icon = menu and menu.icon,
                        distance = distance,
                        menu = menu
                    }
                else
                    existingData.coords = objectCoords
                    existingData.distance = distance
                end
            end
        else
            nearby_objects[object] = nil
        end
    end

    for object, data in pairs(nearby_objects) do
        if isActive == false or data and entityHandle ~= data.object then
            nearby_objects_limited[#nearby_objects_limited + 1] = data
        end
    end

    table.sort(nearby_objects_limited, function(a, b)
        return a.distance < b.distance
    end)
end

function UpdateNearbyObjects()
    local playerPosition = StateManager.get('playerPosition')
    local currentMenu = StateManager.get('id')
    local isActive = StateManager.get('active')
    getNearbyObjects(isActive, currentMenu, playerPosition)
end

function CleanNearbyObjects()
    nearby_objects = {}
    nearby_objects_limited = {}
end

local function GetClosestVehicle()
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closestDistance = -1
    local closestVehicle = -1
    local coords = GetEntityCoords(ped)

    for i = 1, #vehicles, 1 do
        local vehicleCoords = GetEntityCoords(vehicles[i])
        local distance = #(vehicleCoords - coords)

        if closestDistance == -1 or closestDistance > distance then
            closestVehicle = vehicles[i]
            closestDistance = distance
        end
    end

    return closestVehicle, closestDistance
end

local function GetVehicleBoneMenus()
    local closestVehicle = GetClosestVehicle()
    local boneList = Container.indexes.bones[closestVehicle] or Container.indexes.globals.bones
    local closestVehicleMenus = {}

    if boneList then
        local closestDistance = 10000
        local isHoodOpen = GetVehicleDoorAngleRatio(closestVehicle, 4) > 0.9
        local isHoodDamaged = IsVehicleDoorDamaged(closestVehicle, 4)
        local coords = GetEntityCoords(closestVehicle)

        for boneName, bone_menus in pairs(boneList) do
            local boneId = GetEntityBoneIndexByName(closestVehicle, boneName)
            if boneId ~= -1 then
                if boneName == "engine" and (isHoodDamaged == false and not isHoodOpen) then
                    goto continue
                end

                if boneName == "bonnet" and isHoodDamaged then
                    goto continue
                end

                local menu = Container.get(bone_menus[1])
                local bonePosition = GetEntityBonePosition_2(closestVehicle, boneId)
                local distance = #(coords - bonePosition)

                if distance <= closestDistance then
                    closestVehicleMenus[boneName] = {
                        distance = distance,
                        boneId = boneId,
                        position = bonePosition,
                        icon = menu and menu.icon
                    }
                end
            end
            ::continue::
        end
    end

    return closestVehicleMenus, closestVehicle
end

local currentVehicleMenu
local closestVehicleMenus = {}

AddEventHandler("interactionMenu:client:set_vehicle", function(veh)
    if veh == nil then
        currentVehicleMenu = nil
        closestVehicleMenus = {}
    else
        currentVehicleMenu = veh
        closestVehicleMenus = GetVehicleBoneMenus()
    end
end)

local function StartSpriteThread()
    if isSpriteThreadRunning then return end
    isSpriteThreadRunning = true
    local player = PlayerPedId()
    local playerPosition = StateManager.get('playerPosition')
    local currentMenu = StateManager.get('id')
    local isActive = StateManager.get('active')
    local closestVehicle
    -- This is kinda overkill, but in my testing, sometimes one of these threads would stay alive,
    -- causing flickering and performance drops.
    local threadHash = math.random(1000000)
    currentSpriteThreadHash = threadHash

    closestVehicleMenus = GetVehicleBoneMenus()

    CreateThread(function()
        while isSpriteThreadRunning and currentSpriteThreadHash == threadHash do
            isActive = StateManager.get('active')
            currentMenu = StateManager.get('id')
            getNearbyObjects(isActive, currentMenu, playerPosition)
            local nearPoints, totalNearPoints = grid_position:queryRange(playerPosition, 20)
            visiblePoints, visiblePointCount = Util.filterVisiblePointsWithinRange(playerPosition, nearPoints)
            closestVehicle = GetClosestVehicle()
            closestVehicleMenus = GetVehicleBoneMenus()
            Wait(1000)
        end
    end)

    CreateThread(function()
        while isTargetSpritesActive and currentSpriteThreadHash == threadHash do
            playerPosition = GetEntityCoords(player)

            if visiblePointCount > 0 then
                for i = 2, #visiblePoints, 1 do
                    if visiblePoints[i].id ~= currentMenu then
                        drawSprite(visiblePoints[i].point, playerPosition, visiblePoints[i].icon)
                    end
                end

                if visiblePoints[1].point.ids then
                    if not isActive then
                        drawSprite(visiblePoints[1].point, playerPosition, visiblePoints[1].icon)
                    end
                else
                    if visiblePoints[1].id ~= currentMenu and not isActive then
                        drawSprite(visiblePoints[1].point, playerPosition, visiblePoints[1].icon)
                    end
                end
            end

            for index, value in pairs(nearby_objects_limited) do
                if index > maxEntities then break end
                drawSprite(value.coords, playerPosition, value.icon)
            end

            if closestVehicle ~= currentVehicleMenu then
                for key, value in pairs(closestVehicleMenus) do
                    drawSprite(value.position, playerPosition, value.icon)
                end
            end

            Wait(0)
        end
        isSpriteThreadRunning = false
    end)
end

RegisterCommand('+toggleTargetSprites', function()
    isTargetSpritesActive = true
    StartSpriteThread()
end, false)

RegisterCommand('-toggleTargetSprites', function()
    isTargetSpritesActive = false
    isSpriteThreadRunning = false
end, false)

RegisterKeyMapping('+toggleTargetSprites', 'Toggle Target Sprites', 'keyboard', 'LMENU')
RegisterKeyMapping('~!+toggleTargetSprites', 'Toggle Target Sprites - Alternate Key', 'keyboard', 'RMENU')

-- #endregion
