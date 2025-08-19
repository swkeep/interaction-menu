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
    'ON_ZONE',
    'MANUAL'
}

local Wait = Wait
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords
local SetScriptGfxDrawBehindPausemenu = SetScriptGfxDrawBehindPausemenu

-- init
local pause = false
local scaleform_initialized = false
local scaleform
local SpatialHashGrid = Util.SpatialHashGrid
--
local closestEntity -- entity detector
local closestZoneId
local grid_position = SpatialHashGrid:new('position', 100)
local visiblePoints = {}
ActiveManualMenu = nil
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

    local timeout = 15000
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
        width = menuData.width,
        menus = menuData.menus,
        selected = Interact:getSelectedIndex(menuData),
    })
end

--- set menu visibility
---@param id number
---@param value boolean
function Interact:setVisibility(id, value)
    if not StateManager.get('id') then return end
    if not scaleform then return end
    scaleform.send("interactionMenu:menu:setVisibility", { id = id, visibility = value })
end

--- set menu visibility
---@param id number|table
function Interact:deleteMenu(id)
    if not StateManager.get('id') then return end
    if not scaleform then return end
    scaleform.send("interactionMenu:menu:delete", Util.ensureTable(id))
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

function Interact:scroll(menuData, direction)
    Container.changeMenuItem(scaleform, menuData, direction)
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
    StateManager.set('isOpen', true)
    Interact:scaleformUpdate(menuData)
    scaleform.setStatus(true)

    Util.print_debug(('Menu Id [%s] '):format(menuData.id)) -- #DEBUG
end

local function setClose()
    Interact:Hide()
    Wait(100) -- to show fade animatnion
    StateManager.set('isOpen', false)
    scaleform.setStatus(false)
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
    else
        StateManager.set('id', nil)
        StateManager.set('menuType', nil)
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
    -- We could bump it up to 1000 for better performance, but it looks better with 500/600 ms
    local interval = Config.intervals.detection or 500
    local pid = PlayerId()

    -- give client sometime to load
    repeat Wait(1000) until NetworkIsPlayerActive(pid) == 1

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
            if not closestEntity then
                local model = 0
                local entityType = 0
                local playerPosition = GetEntityCoords(playerPed)
                -- #TODO: Give onPosition priority?!
                -- It's going to lower resource usage, BUT if we have two colliding menus, we might not be able to detect them.
                -- reason: when the player is inside the `entity detector`, we won't be able to use rayCast to detect other menus.

                local hitPosition, playerDistance, entity
                if not StateManager.get("disableRayCast") and isInVehicle == false then
                    hitPosition, entity, playerDistance = Util.rayCast(10, playerPed)

                    if hitPosition and not StateManager.get("disableZoneRayCast") then
                        for key, value in pairs(Container.zones) do
                            if value.tracker == "hit" and value:isPointInside(hitPosition) then
                                closestZoneId = value.name
                                break
                            end
                        end
                    end

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
                -- we're ingoring `max distance`
                local model = GetEntityModel(closestEntity)
                handleEntityInteraction(1.0, model, closestEntity)
            end
        else
            StateManager.reset()
        end

        Wait(interval)
    end
end)

AddEventHandler("interactionMenu:zoneTracker", function(zone_name, state)
    if zone_name and state then
        StateManager.set("disableZoneRayCast", true)
        closestZoneId = zone_name
    else
        StateManager.set("disableZoneRayCast", false)
        closestZoneId = nil
    end
end)

AddEventHandler('interactionMenu:client:entityZone:exited', function()
    closestEntity = nil
end)

AddEventHandler('interactionMenu:client:entityZone:entered', function(data)
    closestEntity = data.entity
end)

-- #endregion

-- #region Render Threads
local activeMenuRef
local function refresh()
    Container.syncData(scaleform, activeMenuRef, true)
end

exports("Refresh", refresh)
exports("refresh", refresh)

function Render.generic(data, metadata, callbacks)
    if not data then return end
    if not IsMenuVisible(data) then return end

    StateManager.set('active', true)
    -- onEnter callback
    if callbacks.onEnter then
        if not callbacks.onEnter(data, metadata) then return end
    end

    -- afterStart callback
    if callbacks.afterStart then callbacks.afterStart(data, metadata) end

    setOpen(data)
    Container.validateAndSyncSelected(scaleform, data)
    triggers.onSeen(data, metadata)

    local running = true
    activeMenuRef = data

    CreateThread(function()
        while running do
            Container.syncData(scaleform, data, true)
            Wait(1000)
        end
    end)

    if callbacks.validateSlow then
        CreateThread(function()
            while running do
                running = callbacks.validateSlow(data)
                Wait(250)
            end
        end)
    end

    -- Handle validation loop
    if Config.controls.enforce then
        UserInputManager:setMenuData(data)
        while running and callbacks.validate and callbacks.validate(data) do
            Wait(250)
        end
        UserInputManager:clearMenuData()
    else
        local handleMouseWheel = UserInputManager.defaultMouseWheel
        local handleKeyPress = UserInputManager.defaultKeyHandler
        while running and (callbacks.validate and callbacks.validate(data)) do
            Wait(0)
            handleMouseWheel(data)
            handleKeyPress(data)
        end
    end

    running = false
    activeMenuRef = nil
    setClose()
    triggers.onExit(data, metadata)

    --onExit callback
    if callbacks.onExit then callbacks.onExit(data, metadata) end
    StateManager.set('active', false)
end

function Render.onEntity(model, entity)
    local data = Container.getMenu(model, entity)
    if not data then return end
    if not canInteract(data, nil) then return end

    local closestVehicleBone = Container.boneCheck(entity)
    local offset = data.offset or vec3(0, 0, 0)

    data.model = model
    data.entity = entity

    local metadata = Container.constructMetadata(data)
    local isVehicle = GetEntityType(entity) == 2
    local validateSlow
    if isVehicle then
        validateSlow = function()
            local currentClosestBone = Container.boneCheck(entity)
            return closestVehicleBone == currentClosestBone and canInteract(data, nil)
        end
    else
        validateSlow = function()
            return canInteract(data, nil)
        end
    end

    Render.generic(data, metadata, {
        onEnter = function()
            scaleform.set3d(false)
            scaleform.attach { entity = entity, offset = offset, bone = closestVehicleBone, static = data.static }
            metadata.position = GetEntityCoords(entity)
            UpdateNearbyObjects()
            return canInteract(data, nil)
        end,
        validate = function()
            return isMatchingEntity(model, entity)
        end,
        validateSlow = validateSlow,
        onExit = function()
            StateManager.set('entityModel', nil)
            StateManager.set('entityHandle', nil)
            scaleform.dettach()
        end
    })
end

function Render.onPosition(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end
    if not canInteract(data, nil) then return end

    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation

    Render.generic(data, metadata, {
        onEnter = function()
            StateManager.set('disableRayCast', true)
            scaleform.setPosition(position)
            if rotation then
                scaleform.setRotation(rotation)
                scaleform.set3d(true)
                scaleform.setScale(data.scale or 1)
            else
                scaleform.set3d(false)
            end

            return canInteract(data, nil)
        end,
        validate = function()
            return canInteract(data, nil) and StateManager.get('id') == currentMenuId
        end,
        onExit = function()
            StateManager.set('disableRayCast', false)
        end
    })

    metadata.distance = StateManager.get('playerDistance')
end

function Render.onZone(currentMenuId)
    local data = Container.getMenu(nil, nil, currentMenuId)
    if not data then return end

    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation
    if not position then return end

    local validateSlow
    if data.tracker == "hit" then
        validateSlow = function()
            local hitPosition, entity, playerDistance = Util.rayCast(10, PlayerPedId())
            return Container.zones[currentMenuId]:isPointInside(hitPosition)
        end
    end

    Render.generic(data, metadata, {
        onEnter = function()
            StateManager.set('disableRayCast', true)
            scaleform.setForwardVectorLock(false)
            scaleform.setPosition(position)

            if rotation then
                scaleform.set3d(true)
                scaleform.setRotation(rotation)
                scaleform.setScale(data.scale or 1)
            else
                scaleform.set3d(false)
            end
            return true
        end,
        validate = function()
            return StateManager.get('id') == currentMenuId
        end,
        validateSlow = validateSlow,
        onExit = function()
            StateManager.set('disableRayCast', false)
        end
    })
end

function Render.manual(id, model, entity)
    local data = Container.getMenu(nil, nil, id)
    if not data then return end
    if not canInteract(data, nil) then return end

    local closestVehicleBone = Container.boneCheck(entity)
    local offset = data.offset or vec3(0, 0, 0)

    data.model = model
    data.entity = entity

    local metadata = Container.constructMetadata(data)
    local isVehicle = GetEntityType(entity) == 2
    local validateSlow
    if isVehicle then
        validateSlow = function()
            local currentClosestBone = Container.boneCheck(entity)
            return closestVehicleBone == currentClosestBone and canInteract(data, nil)
        end
    else
        validateSlow = function()
            return canInteract(data, nil)
        end
    end

    Render.generic(data, metadata, {
        onEnter = function()
            local rotation = data.rotation
            if rotation then
                scaleform.setRotation(rotation)
                scaleform.set3d(true)
                scaleform.setScale(data.scale or 1)
            else
                scaleform.set3d(false)
            end
            scaleform.setForwardVectorLock(true)
            scaleform.attach { entity = entity, offset = offset, bone = closestVehicleBone, static = data.static }
            metadata.position = GetEntityCoords(entity)
            UpdateNearbyObjects()
            return canInteract(data, nil)
        end,
        validate = function()
            return ActiveManualMenu == id
        end,
        validateSlow = validateSlow,
        onExit = function()
            StateManager.set('entityModel', nil)
            StateManager.set('entityHandle', nil)
            scaleform.dettach()
            scaleform.setForwardVectorLock(false)
        end
    })
end

local function RenderMenu()
    if pause then return end
    if StateManager.get('isNuiFocused') == 1 then return end
    if StateManager.get('isPauseMenuState') ~= 0 then return end

    local currentMenuId = StateManager.get('id')
    if not currentMenuId then return end

    local menuType = StateManager.get('menuType')
    if not menuType then
        print("interactionMenu: Invalid menuType")
        return
    end

    if menuType == MenuTypes['ON_ENTITY'] then
        local entityHandle = StateManager.get('entityHandle')
        local entityModel = StateManager.get('entityModel')

        if entityHandle and entityModel then
            Render.onEntity(entityModel, entityHandle)
        else
            print("interactionMenu: Missing entity data")
        end
    elseif menuType == MenuTypes['ON_POSITION'] then
        Render.onPosition(currentMenuId)
    elseif menuType == MenuTypes['ON_ZONE'] then
        Render.onZone(currentMenuId)
    elseif menuType == MenuTypes['MANUAL'] then
        local id = StateManager.get('id')
        local entityHandle = StateManager.get('entityHandle')
        local entityModel = StateManager.get('entityModel')

        if entityHandle and entityModel then
            Render.manual(id, entityModel, entityHandle)
        else
            print("interactionMenu: Missing entity data")
        end
    else
        print("interactionMenu: Unknown menuType")
    end
end

CreateThread(function()
    if not waitForScaleform() then return end

    while true do
        RenderMenu()
        Wait(closestEntity and 100 or 500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    scaleform = exports['interactionDUI']:Get()
    if scaleform then
        scaleform.setPosition(vector3(0, 0, 0))
        scaleform.dettach()
        scaleform.setStatus(false)
    end
end)

-- #endregion
