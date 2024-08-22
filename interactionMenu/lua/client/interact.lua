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
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local SetScriptGfxDrawBehindPausemenu = SetScriptGfxDrawBehindPausemenu
local IsControlJustReleased = IsControlJustReleased

-- init
local pause = false
local scaleform_initialized = false
local scaleform
local SpatialHashGrid = Util.SpatialHashGrid
--
local closestZoneId
local grid_position = SpatialHashGrid:new('position', 100)

local visiblePoints = {}
-- Render
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
    for index, value in ipairs(menuData.selected) do
        if value then return index end
    end
    return 1
end

function Interact:scaleformUpdate(menuData)
    scaleform.send("interactionMenu:loading:hide")
    scaleform.send("interactionMenu:menu:show", {
        indicator = menuData.indicator,
        theme = menuData.theme,
        glow = menuData.glow,
        menus = menuData.menus,
        selected = Interact:getSelectedIndex(menuData)
    })
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

function Interact:setDarkMode(value)
    scaleform.send("interactionMenu:darkMode", value)
end

function Interact:Hide()
    scaleform.send("interactionMenu:hideMenu")
    scaleform.send("interactionMenu:loading:hide")
end

local lastTriggerTime = 0
local triggerInterval = 100

function Interact:fillIndicator(menuData, percent)
    local currentTime = GetGameTimer()

    -- skip when we set it to zero
    if percent == 0 or currentTime - lastTriggerTime >= triggerInterval then
        lastTriggerTime = currentTime
        scaleform.send("interactionMenu:indicatorFill", percent)
    end
end

function Interact:indicatorStatus(menuData, status)
    scaleform.send("interactionMenu:indicatorStatus", status)
end

local function handleMouseWheel(menuData)
    -- not the best way to do it but it works if we add new options on runtime
    -- HideHudComponentThisFrame(19)

    -- Mouse Wheel Down / Arrow Down
    DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL (Mouse scroll wheel)
    DisableControlAction(0, 86, true) -- INPUT_VEH_NEXT_RADIO (Mouse wheel up)
    DisableControlAction(0, 81, true) -- INPUT_VEH_PREV_RADIO (Mouse wheel down)
    -- DisableControlAction(0, 82, true) -- INPUT_VEH_SELECT_NEXT_WEAPON (Keyboard R)
    -- DisableControlAction(0, 83, true) -- INPUT_VEH_SELECT_PREV_WEAPON (Keyboard E)

    DisableControlAction(0, 14, true)
    DisableControlAction(0, 15, true)
    if IsDisabledControlJustReleased(0, 14) or IsControlJustReleased(0, 173) then
        Container.changeMenuItem(scaleform, menuData, true)
        -- Mouse Wheel Up / Arrow Up
    elseif IsDisabledControlJustReleased(0, 15) or IsControlJustReleased(0, 172) then
        Container.changeMenuItem(scaleform, menuData, false)
    end
end

local holdStart = nil
local lastHoldTrigger = nil

local function handleKeyPress(menuData)
    -- E
    local padIndex = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.padIndex or 0
    local control = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.control or 38

    if menuData.indicator.hold then
        if IsControlPressed(padIndex, control) then
            local currentTime = GetGameTimer()
            if lastHoldTrigger then
                if (currentTime - lastHoldTrigger) >= 1000 then
                    lastHoldTrigger = nil
                else
                    return
                end
            end
            if not holdStart then
                holdStart = currentTime
            end
            local holdDuration = menuData.indicator.hold
            local elapsedTime = currentTime - holdStart
            local percentage = (elapsedTime / holdDuration) * 100
            Interact:fillIndicator(menuData, percentage)

            if elapsedTime >= holdDuration then
                holdStart = nil
                lastHoldTrigger = currentTime
                Container.keyPress(menuData)
                Interact:indicatorStatus(menuData, 'success')
                Interact:fillIndicator(menuData, 0)
            end
        else
            if holdStart then
                Util.print_debug("Player stopped holding the key early")
                Interact:indicatorStatus(menuData, 'fail')
                Interact:fillIndicator(menuData, 0)
                holdStart = nil
            end
        end
    else
        if not IsControlJustReleased(padIndex, control) then return end
        Container.keyPress(menuData)
    end
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

local function setOpen(menuData)
    Wait(0)
    scaleform.setStatus(true)
    Interact:scaleformUpdate(menuData)
    StateManager.set('isOpen', true)

    Util.print_debug(('Menu Id [%s] '):format(menuData.id)) -- #DEBUG
end

local function setClose()
    Interact:Hide()
    Wait(150)
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

-- #region process data
-- detect the menu type and set menu data and pass rest to render thread

local function handlePositionBasedInteraction()
    local maxDistance = visiblePoints.closest.maxDistance or 3

    if visiblePoints.closest.distance and visiblePoints.closest.distance < maxDistance then
        StateManager.set('id', visiblePoints.closest.id)
        StateManager.set('menuType', MenuTypes['ON_POSITION'])
        StateManager.set('playerDistance', visiblePoints.closest.distance)
    end
end

local function handleZoneBasedInteraction(closestZoneMenuId)
    StateManager.set('id', closestZoneMenuId)
    StateManager.set('menuType', MenuTypes['ON_ZONE'])
end

local function handleEntityInteraction(playerDistance, model, entity)
    SetScriptGfxDrawBehindPausemenu(false)

    StateManager.set('id', entity)
    StateManager.set('menuType', MenuTypes['ON_ENTITY'])
    StateManager.set('entityModel', model)
    StateManager.set('entityHandle', entity)
    StateManager.set('playerDistance', playerDistance)
end

local function waitForScaleform()
    local timeout = 7000
    local startTime = GetGameTimer()

    repeat
        Wait(500)
    until scaleform_initialized or (GetGameTimer() - startTime >= timeout)

    return scaleform_initialized
end

CreateThread(function()
    if not waitForScaleform() then return end
    -- We can bump it up to 1000 for better performance, but it looks better with 500/600 ms
    local interval = Config.intervals.detection or 500
    local pid = PlayerId()

    -- give client sometime to load
    repeat
        Wait(1000)
    until NetworkIsPlayerActive(pid) == 1

    while true do
        local playerPed = PlayerPedId()
        local isInVehicle = IsPedInAnyVehicle(playerPed, true)
        local isNuiFocused = IsNuiFocused()
        local isPauseMenuState = GetPauseMenuState()

        StateManager.set({
            playerIsInVehicle = isInVehicle,
            isNuiFocused = isNuiFocused,
            isPauseMenuState = isPauseMenuState
        }, true, true)

        if isPauseMenuState == 0 and isNuiFocused ~= 1 then
            local playerPosition = GetEntityCoords(playerPed)
            local model = 0
            local entityType = 0

            local hitPosition, playerDistance, entity
            if closestZoneId == nil and (not StateManager.get("disableRayCast") or isInVehicle ~= 1) then
                hitPosition, entity, playerDistance = Util.rayCast(10, playerPed)

                if entity then
                    entityType = GetEntityType(entity)
                    if entityType ~= 0 then
                        model = GetEntityModel(entity)
                    end
                end
            end
            StateManager.set('hitPosition', hitPosition)
            StateManager.set({
                playerPed = playerPed,
                playerPosition = playerPosition
            }, true, true)

            local nearPoints = grid_position:queryRange(playerPosition, 25)
            visiblePoints    = Util.filterVisiblePointsWithinRange(playerPosition, nearPoints)
            local menuType   = Container.getMenuType {
                model = model,
                entity = entity,
                entityType = entityType,
                closestPoint = visiblePoints.closest,
                zone = closestZoneId
            }

            if menuType == MenuTypes['ON_ENTITY'] then
                handleEntityInteraction(playerDistance, model, entity)
            elseif menuType == MenuTypes['ON_POSITION'] then
                handlePositionBasedInteraction()
            elseif menuType == MenuTypes['ON_ZONE'] then
                handleZoneBasedInteraction(closestZoneId)
            elseif menuType == MenuTypes['DISABLED'] then
                StateManager.reset()
            end
        else
            StateManager.reset()
        end

        Wait(interval)
    end
end)

AddEventHandler("interactionMenu:zoneTracker", function(zone_name, state)
    print(zone_name, state)
    if zone_name and state then
        closestZoneId = zone_name
    else
        closestZoneId = nil
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
    local closestVehicleBone = Container.boneCheck(entity)
    local offset = data.offset or vec3(0, 0, 0)

    -- Add entity, model into menu data container
    data.model = model
    data.entity = entity

    StateManager.set('active', true)
    local metadata = Container.constructMetadata(data)

    scaleform.set3d(false)
    scaleform.attach { entity = entity, offset = offset, bone = closestVehicleBone, static = data.static }
    setOpen(data)
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
            local nclosestVehicleBone = Container.boneCheck(entity)

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
    setClose()
    scaleform.dettach()
    metadata.position = GetEntityCoords(entity)
    triggers.onExit(data, metadata)
    StateManager.set('active', false)
end

function Render.onPosition(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end

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

    setOpen(data)
    Container.validateAndSyncSelected(scaleform, data)
    triggers.onSeen(data, metadata)

    CreateThread(function()
        while running do
            Container.syncData(scaleform, data, true)
            Wait(1000)
        end
    end)

    while canInteract(data, nil) and StateManager.get('id') == currentMenuId do
        Wait(0)
        handleMouseWheel(data)
        handleKeyPress(data)
    end

    running = false
    setClose()
    StateManager.set('disableRayCast', false)
    StateManager.set('active', false)
    metadata.distance = StateManager.get('playerDistance')
    triggers.onExit(data, metadata)
end

function Render.onZone(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end

    local running = true
    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation
    if not position then return end -- probably deleted or just missing position

    scaleform.setPosition(position)

    if rotation then
        scaleform.setRotation(rotation)
        scaleform.set3d(true)
        scaleform.setScale(data.scale or 1)
    end

    StateManager.set('active', true)
    StateManager.set('disableRayCast', true)

    setOpen(data)
    Container.validateAndSyncSelected(scaleform, data)
    triggers.onSeen(data, metadata)

    CreateThread(function()
        while running do
            Container.syncData(scaleform, data, true)
            Wait(250)
        end
    end)

    while StateManager.get('id') == currentMenuId do
        Wait(0)
        handleMouseWheel(data)
        handleKeyPress(data)
    end

    running = false
    StateManager.set('disableRayCast', false)
    StateManager.set('active', false)
    triggers.onExit(data, metadata)

    setClose()
end

-- Handle the rendering logic based on the current state
local function RenderMenu()
    if pause then return end
    if StateManager.get('isNuiFocused') == 1 then return end
    if StateManager.get('isPauseMenuState') ~= 0 then return end

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
