if not Config.features.drawIndicator.active then
    return
end

-- #region Show sprite while holding alt

local SpatialHashGrid = Util.SpatialHashGrid
local isTargetSpritesActive = false
local isSpriteThreadRunning = false
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

-- Function to draw the sprite with scaling based on distance
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


local function getNearbyObjects(coords)
    local objects = GetGamePool('CObject')
    local nearby = {}
    local count = 0

    for i = 1, #objects do
        local object = objects[i]

        local objectCoords = GetEntityCoords(object)
        local distance = #(coords - objectCoords)

        if distance < maxDistance then
            local entity_type = GetEntityType(object)
            local model = GetEntityModel(object)

            local menuType = Container.getMenuType {
                model = model,
                entity = object,
                entityType = entity_type
            }

            local menu = Container.getMenu(model, object, nil)
            local id = StateManager.get('id')
            local menuId

            if id then
                menuId = StateManager.get('entityModel') .. "|" .. StateManager.get('id')
            end

            if menuType ~= 1 and not menuId or menuId ~= menu.id then
                count += 1

                nearby[count] = {
                    object = object,
                    coords = objectCoords,
                    type = entity_type,
                    icon = menu and menu.icon
                }
            end
        end
    end

    return nearby
end

local entities = {}

local function StartSpriteThread()
    if isSpriteThreadRunning then return end
    isSpriteThreadRunning = true
    local player          = PlayerPedId()
    local playerPosition  = StateManager.get('playerPosition')
    local currentMenu     = StateManager.get('id')
    local isActive        = StateManager.get('active')

    CreateThread(function()
        while isSpriteThreadRunning do
            isActive                          = StateManager.get('active')
            currentMenu                       = StateManager.get('id')
            entities                          = getNearbyObjects(playerPosition)
            local nearPoints, totalNearPoints = grid_position:queryRange(playerPosition, 20)
            visiblePoints, visiblePointCount  = Util.filterVisiblePointsWithinRange(playerPosition, nearPoints)

            Wait(1000)
        end
    end)

    CreateThread(function()
        while isTargetSpritesActive do
            playerPosition = GetEntityCoords(player)

            if visiblePointCount > 0 then
                for _, value in ipairs(visiblePoints.inView) do
                    if value.id ~= currentMenu then
                        drawSprite(value.point, playerPosition, visiblePoints.closest.icon)
                    end
                end

                if visiblePoints.closest.id ~= currentMenu and not isActive then
                    drawSprite(visiblePoints.closest.point, playerPosition, visiblePoints.closest.icon)
                end
            end

            for index, value in ipairs(entities) do
                drawSprite(value.coords, playerPosition, value.icon)
            end

            Wait(10)
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
end, false)

RegisterKeyMapping('+toggleTargetSprites', 'Toggle Target Sprites', 'keyboard', 'LMENU')
RegisterKeyMapping('~!+toggleTargetSprites', 'Toggle Target Sprites - Alternate Key', 'keyboard', 'RMENU')

-- #endregion