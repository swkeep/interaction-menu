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
    'ON_ZONE'
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
local pause = false
local scaleform_initialized = false
local scaleform
local SpatialHashGrid = Util.SpatialHashGrid

local grid_zone = SpatialHashGrid:new('zone', 100)
local grid_position = SpatialHashGrid:new('position', 100)

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

function Interact.pause(value)
    pause = value and true or false
end

exports('pause', Interact.pause)

-- init
CreateThread(function()
    Util.preloadSharedTextureDict()

    local timeout = 5000
    local startTime = GetGameTimer()

    repeat
        scaleform_initialized = false
        Wait(1000)
    until GetResourceState('interactionDUI') == 'started' or (GetGameTimer() - startTime >= timeout)

    if GetResourceState('interactionDUI') == 'started' then
        scaleform_initialized = true

        scaleform = exports['interactionDUI']:Get()
        scaleform.setPosition(vector3(0, 0, 0))
        scaleform.dettach()
        scaleform.setStatus(false)
    else
        print('ResourceState:', GetResourceState('interactionDUI'))
        error("interactionDUI resource did not start within the timeout period")
    end
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

--- set menu visibility
---@param id number
---@param value boolean
function Interact:setVisibility(id, value)
    -- #TODO: it should check we actually looking at the same menu and update it
    if not StateManager.get('id') then return end
    if not scaleform then return end
    -- #TODO: add a better type check
    scaleform.send("interactionMenu:menu:setVisibility", { id = id, visibility = value })
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

    -- Mouse Wheel Down / Arrow Down
    if IsDisabledControlJustReleased(0, 14) or IsControlJustReleased(0, 173) then
        Container.changeMenuItem(scaleform, menuData, true)
        -- Mouse Wheel Up / Arrow Up
    elseif IsDisabledControlJustReleased(0, 15) or IsControlJustReleased(0, 172) then
        Container.changeMenuItem(scaleform, menuData, false)
    end
end

local function handleKeyPress(menuData)
    -- E
    local padIndex = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.padIndex or 0
    local control = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.control or 38

    if not IsControlJustReleased(padIndex, control) then return end

    Container.keyPress(menuData)
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

                if visiblePoints.closest.id ~= StateManager.get('id') and not StateManager.get('active') then
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

local function handleZoneBasedInteraction(closestZoneMenuId)
    StateManager.set('id', closestZoneMenuId)
    StateManager.set('menuType', MenuTypes['ON_ZONE'])
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

local function waitForScaleform()
    local timeout = 7000
    local startTime = GetGameTimer()

    repeat
        Wait(500)
    until scaleform_initialized or (GetGameTimer() - startTime >= timeout)

    return scaleform_initialized
end

local function findClosestZone(playerPosition, range)
    local zonesInRange = grid_zone:queryRange(playerPosition, 100)

    for index, value in ipairs(zonesInRange) do
        if Container.zones[value.id] and Container.zones[value.id]:isPointInside(playerPosition) then
            return value.id
        end
    end

    return nil
end

CreateThread(function()
    if not waitForScaleform() then return end
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

            local nearPoints, totalNearPoints = grid_position:queryRange(playerPosition, 100)
            visiblePoints, visiblePointCount  = Util.filterVisiblePointsWithinRange(playerPosition, nearPoints)
            -- onZone
            local closestZoneMenuId           = findClosestZone(playerPosition)

            local menuType                    = Container.getMenuType {
                model = model,
                entity = entity,
                entityType = entityType,
                closestPoint = visiblePoints.closest,
                zone = closestZoneMenuId
            }

            if menuType == MenuTypes['ON_ENTITY'] then
                handleEntityInteraction(playerDistance, model, entity, hitPosition)
            elseif menuType == MenuTypes['ON_POSITION'] then
                handlePositionBasedInteraction()
            elseif menuType == MenuTypes['ON_ZONE'] then
                handleZoneBasedInteraction(closestZoneMenuId)
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

    -- Add entity, model into menu data container
    data.model = model
    data.entity = entity

    StateManager.set('active', true)
    local metadata = Container.constructMetadata(data)

    scaleform.set3d(false)
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
        Wait(0)

        handleMouseWheel(data)
        handleKeyPress(data)
    end

    running = false
    persistentData.showingLoading = nil
    setClose()
    scaleform.dettach()
    metadata.position = GetEntityCoords(entity)
    triggers.onExit(data, metadata)
    StateManager.set('active', false)
end

function Render.onPosition(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end
    local persistentData = PersistentData.get(currentMenuId)

    if not canInteract(data, nil) then return end
    StateManager.set('active', true)
    StateManager.set('disableRayCast', true)

    local running = true
    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation

    scaleform.setPosition(position)

    if rotation then
        scaleform.setRotation(rotation)
        scaleform.set3d(true)
        scaleform.setScale(data.scale or 1)
    else
        scaleform.set3d(false)
    end

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
        Wait(0)
        handleMouseWheel(data)
        handleKeyPress(data)
    end

    running = false
    persistentData.showingLoading = nil
    setClose()
    StateManager.set('disableRayCast', false)
    StateManager.set('active', false)
    metadata.distance = StateManager.get('playerDistance')
    triggers.onExit(data, metadata)
end

function Render.onZone(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end
    local persistentData = PersistentData.get(currentMenuId)

    local running = true
    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation

    scaleform.setPosition(position)

    if rotation then
        scaleform.setRotation(rotation)
        scaleform.set3d(true)
        scaleform.setScale(data.scale or 1)
    end

    StateManager.set('active', true)
    StateManager.set('disableRayCast', true)

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

    while StateManager.get('id') == currentMenuId do
        Wait(0)
        handleMouseWheel(data)
        handleKeyPress(data)
    end

    running = false
    persistentData.showingLoading = nil
    StateManager.set('disableRayCast', false)
    StateManager.set('active', false)
    triggers.onExit(data, metadata)

    setClose()
end

-- Handle the rendering logic based on the current state
local function RenderMenu()
    if pause then return end
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
    elseif menuType == MenuTypes['ON_ZONE'] then
        Render.onZone(currentMenuId)
    end
end

CreateThread(function()
    if not waitForScaleform() then return end

    while true do
        RenderMenu()
        Wait(500)
    end
end)

-- #endregion

-- 472
