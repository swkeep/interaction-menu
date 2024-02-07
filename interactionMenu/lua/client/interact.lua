--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

MenuTypes = Util.ENUM {
    'DISABLED',
    'ON_POSITION',
    'ON_ENTITY',
}

local Wait = Wait
local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local SetScriptGfxDrawBehindPausemenu = SetScriptGfxDrawBehindPausemenu
local IsControlJustReleased = IsControlJustReleased

-- init
local scaleform = {}
local SpatialHashGrid = Util.SpatialHashGrid
local grid = SpatialHashGrid:new(100)
local visiblePoints = {}
local visiblePointCount = 0
-- Render
local isTargetSpritesActive = false
local isSpriteThreadRunning = false
local PersistentData = Util.PersistentData()
local StateManager = Util.StateManager()

local Render = {}
Interact = {
    data = {},
    bones = {}
}

-- init
CreateThread(function()
    Util.preloadSharedTextureDict()
    scaleform = exports['interactionDUI']:Get()
    scaleform.setPosition(vector3(0, 0, 0))
end)

function Interact:getSelectedIndex(menuData)
    local data = PersistentData.get(menuData.id)
    for index, value in ipairs(data.selected) do
        if value then return index end
    end
    return 1
end

function Interact:scaleformUpdate(menuData, persistentData)
    if persistentData.loading then
        scaleform.send("interactionMenu:loading:show")
        scaleform.send("interactionMenu:hideMenu")
    else
        scaleform.send("interactionMenu:loading:hide")
        scaleform.send("interactionMenu:menu:show", {
            indicator = {
                prompt = menuData.indicator and menuData.indicator.prompt,
                active = menuData.indicator and true or false,
                glow = menuData.indicator and menuData.indicator.glow and true
            },
            theme = menuData.theme,
            glow = menuData.glow,
            menus = menuData.menus,
            selected = Interact:getSelectedIndex(menuData)
        })
    end
end

function Interact:setVisibility(menuId, hide_value)
    -- #TODO: it should check we actually looking at the same menu and update it
    if not StateManager.get('id') then return end
    -- #TODO: add a better type check
    scaleform.send("interactionMenu:menu:setVisibility", {
        id = menuId,
        hide = hide_value
    })
end

function Interact:SetDarkMode(value)
    scaleform.send("interactionMenu:darkMode", value)
end

function Interact:Hide()
    scaleform.send("interactionMenu:hideMenu")
    scaleform.send("interactionMenu:loading:hide")
end

local function handleMouseWheel(menuData)
    -- not the best way to do it but it works if we add new options on runtime
    HideHudComponentThisFrame(19)

    if IsDisabledControlJustReleased(0, 14) then -- Mouse Wheel Down
        Container.changeMenuItem(scaleform, menuData, true)
        Wait(60)
    elseif IsDisabledControlJustReleased(0, 15) then -- Mouse Wheel Up
        Container.changeMenuItem(scaleform, menuData, false)
        Wait(60)
    end
end

local function handleKeyPress(menuData, passThrough)
    -- E
    local padIndex = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.padIndex or 0
    local control = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.control or 38

    if not IsControlJustReleased(padIndex, control) then return end

    Container.keyPress(scaleform, menuData, passThrough)
end

local function isPlayerWithinDistance(maxDistance)
    maxDistance = maxDistance or 2

    return StateManager.get('playerDistance') and StateManager.get('playerDistance') < maxDistance
end

local function isMatchingEntity(model, entity)
    local stateId = StateManager.get('id')
    local stateEntityHandle = StateManager.get('entityHandle')
    local matched = stateEntityHandle == stateId

    return stateId and matched and stateId == entity
end

local function setOpen(menuData, persistentData)
    Wait(150) -- a lazy fix flicker issue
    StateManager.set('isOpen', true)
    scaleform.setStatus(true)
    Interact:scaleformUpdate(menuData, persistentData)

    Util.print_debug(('Menu Id [%s] '):format(menuData.id)) -- #DEBUG
end

local function setClose()
    Interact:Hide()
    Wait(300)
    scaleform.setStatus(false)
    StateManager.set('isOpen', false)
end

--- Checks if interaction is allowed or not
---@param data any
---@param ... unknown
---@return boolean
local function canInteract(data, ...)
    if not isPlayerWithinDistance(data.maxDistance) then return false end
    return true
end

local triggers = {
    onSeen = function(data, ...)
        for key, value in pairs(data.menus) do
            Container.triggerInteraction(value.id, 'onSeen', ...)
        end
    end,
    onExit = function(data, ...)
        for key, value in pairs(data.menus) do
            Container.triggerInteraction(value.id, 'onExit', ...)
        end
    end
}

-- #region Show sprite while holding alt

local function drawSprite(p)
    if not p then return end
    SetDrawOrigin(p.x, p.y, p.z, 0)
    DrawSprite("shared", "emptydot_32", 0, 0, 0.02, 0.035, 0, 255, 255, 255, 255)
    ClearDrawOrigin()
end

local function StartSpriteThread()
    if isSpriteThreadRunning then return end
    isSpriteThreadRunning = true

    CreateThread(function()
        while isTargetSpritesActive do
            if visiblePointCount > 0 then
                for _, value in ipairs(visiblePoints.inView) do
                    drawSprite(value.point)
                end

                if visiblePoints.closest.id ~= StateManager.get('id') then
                    drawSprite(visiblePoints.closest.point)
                end
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

-- #region process data
-- detect the menu type and set menu data and pass rest to render thread

local function handlePositionBasedInteraction()
    if visiblePoints.closest.distance and visiblePoints.closest.distance < 3 then
        StateManager.set('id', visiblePoints.closest.id)
        StateManager.set('menuType', MenuTypes['ON_POSITION'])
        StateManager.set('playerDistance', visiblePoints.closest.distance)
    end
end

local function handleEntityInteraction(playerDistance, model, entity, hitPosition)
    SetScriptGfxDrawBehindPausemenu(false)

    StateManager.set('id', entity)
    StateManager.set('menuType', MenuTypes['ON_ENTITY'])
    StateManager.set('entityModel', model)
    StateManager.set('entityHandle', entity)
    StateManager.set('playerDistance', playerDistance)
    StateManager.set('hitPosition', hitPosition)
end

CreateThread(function()
    -- We can bump it up to 1000 for better performance, but it looks better with 500/600 ms
    local interval = 600
    local pid = PlayerId()

    -- give client sometime to actually load
    repeat
        Wait(1000)
    until NetworkIsPlayerActive(pid) == 1
    Wait(500)

    while true do
        local playerPed = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(playerPed, true)
        local nuiFocused = IsNuiFocused() ~= 1
        local pauseMenuState = GetPauseMenuState() == 0

        StateManager.set({
            playerIsInVehicle = isInVehicle,
            IsNuiFocused = nuiFocused
        }, true, true)

        if pauseMenuState and nuiFocused and not isInVehicle then
            local playerPosition = GetEntityCoords(playerPed)
            local model = 0
            local entityType = 0

            local hitPosition, playerDistance, entity
            if not StateManager.get("disableRayCast") then
                hitPosition, entity, playerDistance = Util.rayCast(10, playerPed)

                if entity then
                    entityType = GetEntityType(entity)
                    if entityType ~= 0 then
                        model = GetEntityModel(entity)
                    end
                end
            end

            StateManager.set({
                playerPed = playerPed,
                playerPosition = playerPosition
            }, true, true)

            local nearPoints, totalNearPoints = grid:queryRange(playerPosition, 100)
            visiblePoints, visiblePointCount  = Util.filterVisiblePointsWithinRange(playerPosition, nearPoints)

            local menuType                    = Container.getMenuType {
                model = model,
                entity = entity,
                entityType = entityType,
                closestPoint = visiblePoints.closest
            }

            if menuType == MenuTypes['ON_ENTITY'] then
                handleEntityInteraction(playerDistance, model, entity, hitPosition)
            elseif menuType == MenuTypes['ON_POSITION'] then
                handlePositionBasedInteraction()
            elseif menuType == MenuTypes['DISABLED'] then
                StateManager.reset()
            end
        else
            StateManager.reset()
        end

        Wait(interval)
    end
end)

-- #endregion

-- #region Render Threads

local function METADATA(t)
    local metadata = {
        entity = t.entity,
        playerPosition = t.playerPosition,
        distance = StateManager.get('playerDistance'),
        boneId = t.boneId,
        boneName = t.boneName,
        boneDist = t.boneDist,
        gameTimer = GetGameTimer()
    }

    metadata.entityDetail = {
        handle = t.entity,
        networked = NetworkGetEntityIsNetworked(t.entity) == 1,
        model = t.model,
        position = GetEntityCoords(t.entity),
        rotation = GetEntityRotation(t.entity),
    }

    metadata.entityDetail.typeInt = GetEntityType(t.entity)
    metadata.entityDetail.type = EntityTypes[metadata.entityDetail.typeInt]

    if metadata.entityDetail.networked then
        metadata.entityDetail.netId = NetworkGetNetworkIdFromEntity(t.entity)
    end

    local isPlayer = metadata.entityDetail.typeInt == 1 and IsPedAPlayer(t.entity)

    if isPlayer then
        metadata.player = {
            playerPedId = t.entity,
            playerIndex = NetworkGetPlayerIndexFromPed(t.entity),
        }

        metadata.player.serverId = GetPlayerServerId(metadata.player.playerIndex)
    end

    return metadata
end

-- we can try to merge these two functions to render both in a Render function
--  but i want to have two seperated functions for position and entites
function Render.onEntity(model, entity)
    local data = Container.getMenu(model, entity)
    if not data then return end

    if not canInteract(data, nil) then return end

    local running = true
    local persistentData = PersistentData.get(data.id)
    local closestVehicleBone, closestBoneName, boneDistance = Container.boneCheck(entity)
    local offset = data.offset or vec3(0, 0, 0)

    local metadata = METADATA {
        playerPosition = GetEntityCoords(PlayerPedId()),
        model = model,
        entity = entity,
        boneId = closestVehicleBone,
        boneName = closestBoneName,
        boneDist = boneDistance
    }

    scaleform.attach { entity = entity, offset = offset, bone = closestVehicleBone, static = data.static }
    setOpen(data, persistentData)
    Container.validateAndSyncSelected(scaleform, data)
    triggers.onSeen(data, metadata)

    CreateThread(function()
        while running do
            Container.syncData(scaleform, data, true, metadata)
            Wait(1000)
        end
    end)

    CreateThread(function()
        while running do
            local nclosestVehicleBone = Container.boneCheck(entity)
            Container.loadingState(scaleform, data)

            if closestVehicleBone ~= nclosestVehicleBone then
                running = false
            end

            running = running and canInteract(data, nil)

            Wait(250)
        end
    end)

    while running and isMatchingEntity(model, entity) do
        Wait(30)

        handleMouseWheel(data)
        handleKeyPress(data, metadata)
    end

    running = false
    persistentData.showingLoading = nil
    setClose()
    scaleform.dettach()
    metadata.position = GetEntityCoords(entity)
    triggers.onExit(data, metadata)
end

function Render.onPosition(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end
    local persistentData = PersistentData.get(currentMenuId)

    if not canInteract(data, nil) then return end

    local running = true
    local metadata = {
        id = currentMenuId,
        distance = StateManager.get('playerDistance')
    }

    StateManager.set('disableRayCast', true)
    scaleform.setPosition(data.position)
    setOpen(data, persistentData)
    Container.validateAndSyncSelected(scaleform, data)
    triggers.onSeen(data, metadata)

    CreateThread(function()
        while running do
            Container.syncData(scaleform, data, true)
            Wait(1000)
        end
    end)

    CreateThread(function()
        while running do
            Container.loadingState(scaleform, data)
            Wait(250)
        end
    end)

    while canInteract(data, nil) and StateManager.get('id') == currentMenuId do
        Wait(30)
        handleMouseWheel(data)
        handleKeyPress(data, {
            metadata = metadata
        })
    end

    running = false
    persistentData.showingLoading = nil
    setClose()
    StateManager.set('disableRayCast', false)
    metadata.distance = StateManager.get('playerDistance')
    triggers.onExit(data, metadata)
end

-- Handle the rendering logic based on the current state
local function RenderMenu()
    if StateManager.get('playerIsInVehicle') then return end

    local currentMenuId = StateManager.get('id')
    if not currentMenuId then return end

    local menuType = StateManager.get('menuType')

    if menuType == MenuTypes['ON_ENTITY'] then
        local entityHandle = StateManager.get('entityHandle')
        local entityModel = StateManager.get('entityModel')

        Render.onEntity(entityModel, entityHandle)
    elseif menuType == MenuTypes['ON_POSITION'] then
        Render.onPosition(currentMenuId)
    end
end

CreateThread(function()
    while true do
        RenderMenu()
        Wait(500)
    end
end)

-- #endregion

-- 472
