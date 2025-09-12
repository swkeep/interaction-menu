--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local Wait = Wait
local PlayerPedId = PlayerPedId
local GetEntityCoords = GetEntityCoords

local paused = false
local scaleform_initialized = false
local scaleform
local state_manager = Util.StateManager()
local last_trigger_time = 0
local trigger_interval = 100

---@alias FEATURES_LIST
---| '"NONE"'
---| '"TRIGGER_ZONE"'
---| '"AT_POSITION"'
---| '"TARGETING_ENTITY"'
---| '"TARGETING_PED"'
---| '"TARGETING_VEHICLE"'
---| '"TARGETING_PLAYER"'
---| '"ON_VEHICLE_BONE"'
---| '"ON_ENTITY_BONE"'
---| '"OPENED_MANUALLY"'

FEATURES_LIST = Util.ENUM {
    'NONE',
    'OPENED_MANUALLY',
    'TRIGGER_ZONE',
    'AT_POSITION',
    'TARGETING_ENTITY',
    'TARGETING_PED',
    'TARGETING_VEHICLE',
    'TARGETING_PLAYER',
    'ON_VEHICLE_BONE',
    'ON_ENTITY_BONE',
}

Features = {
    _handlers = {
        Create = {},
        Set = {},
        Detected = {},   -- non-blocking
        PreRender = {},  -- non-blocking
        Render = {},     -- blocking
        PostRender = {}, -- non-blocking
    },
}

Render = {
    interval = 500
}

Interact = {
    data = {},
    bones = {}
}

-- init
CreateThread(function()
    local timeout = 15000
    local start_time = GetGameTimer()

    repeat
        scaleform_initialized = false
        Wait(1000)
    until GetResourceState('interactionDUI') == 'started' or (GetGameTimer() - start_time >= timeout)

    while not HasStreamedTextureDictLoaded("shared") do
        Wait(10)
        RequestStreamedTextureDict("shared", true)
    end

    if GetResourceState('interactionDUI') == 'started' then
        scaleform = exports['interactionDUI']:Get()
        scaleform.setPosition(vector3(0, 0, 0))
        scaleform.dettach()
        scaleform.setStatus(false)
        scaleform_initialized = true
    else
        print('ResourceState:', GetResourceState('interactionDUI'))
        error("interactionDUI resource did not start within the timeout period")
    end
end)

function Features.on(event, fn, opts)
    assert(type(event) == "string", "event must be string")
    assert(type(fn) == "function", "fn must be function")
    opts = opts or {}

    Features._handlers[event] = Features._handlers[event] or {}
    local id
    if not opts.id then
        id = #Features._handlers[event] + 1
    else
        id = opts.id
    end

    local handlerObj = {
        id = id,
        fn = fn,
        menu_type = opts.menu_type,
    }

    Features._handlers[event][id] = handlerObj
end

function Features.resolveAll(event, ...)
    local handlers = Features._handlers[event]
    if not handlers then return end

    for index, handler in pairs(handlers) do
        pcall(handler.fn, ...)
    end
end

function Features.resolve(event, ...)
    local handlers = Features._handlers[event]
    if not handlers then return end

    local args = { ... }
    local id = args[1]
    local id_type = type(id)

    if id_type == "string" or id_type == "number" then
        local handler = handlers[id]
        table.remove(args, 1)
        if handler then
            return handler.fn(table.unpack(args))
        end
    elseif id_type == "table" then
        for index, value in ipairs(FEATURES_LIST) do
            local handler = handlers[index]
            if handler then
                local ok, res = pcall(handler.fn, ...)
                if res then return res end
            end
        end
        return false
    end
end

function Interact.pause(value)
    paused = value and true or false
end

exports('pause', Interact.pause)

function Interact.getScaleform()
    return scaleform
end

function Interact:scaleformUpdate(menu_data)
    local function find_selected_index()
        for index, value in ipairs(menu_data.selected) do
            if value then return index end
        end
        return 1
    end

    scaleform.send("interactionMenu:menu:show", {
        indicator = menu_data.indicator,
        theme = menu_data.theme,
        glow = menu_data.glow,
        width = menu_data.width,
        menus = menu_data.menus,
        selected = find_selected_index(),
    })
end

--- set menu visibility
---@param id number
---@param value boolean
function Interact:setVisibility(id, value)
    if not state_manager.get('id') then return end
    if not scaleform then return end
    scaleform.send("interactionMenu:menu:setVisibility", { id = id, visibility = value })
end

--- set menu visibility
---@param id number|table
function Interact:deleteMenu(id)
    if not state_manager.get('id') then return end
    if not scaleform then return end
    scaleform.send("interactionMenu:menu:delete", Util.ensureTable(id))
end

function Interact:setDarkMode(value)
    scaleform.send("interactionMenu:darkMode", value)
end

function Interact:fillIndicator(menuData, percent)
    local currentTime = GetGameTimer()

    -- skip when we set it to zero
    if percent == 0 or currentTime - last_trigger_time >= trigger_interval then
        last_trigger_time = currentTime
        scaleform.send("interactionMenu:indicatorFill", percent)
    end
end

function Interact:indicatorStatus(menuData, status)
    scaleform.send("interactionMenu:indicatorStatus", status)
end

function Interact:scroll(menuData, direction)
    Container.changeMenuItem(scaleform, menuData, direction)
end

-- #region process data
-- detect the menu type and set menu data and pass rest to render thread

local function waitForScaleform()
    local timeout = 10000
    local startTime = GetGameTimer()

    repeat
        Wait(500)
    until scaleform_initialized or (GetGameTimer() - startTime >= timeout)

    return scaleform_initialized
end

---@class DetectionContext
---@field player_ped_id number
---@field player_position vector3
---@field in_vehicle boolean
---@field is_nui_focused boolean
---@field has_line_of_sight boolean
---@field is_pause_menu integer
---@field ray_hit_position vector3|nil
---@field target_entity number|nil
---@field target_entity_type number|nil
---@field distance_to_target number

CreateThread(function()
    if not waitForScaleform() then return end
    -- We could bump it up to 1000 for better performance, but it looks better with 500/600 ms
    local interval = Config.intervals.detection or 500
    local pid = PlayerId()
    local last_entity = nil
    local hit, ray_hit_position, distance_to_target, target_entity, target_entity_type, has_line_of_sight = false, nil, nil, 0, 0, false

    -- give client sometime to load
    repeat Wait(1000) until NetworkIsPlayerActive(pid) == 1

    local function reset_ray_cast_info()
        hit, ray_hit_position, distance_to_target, target_entity, target_entity_type, has_line_of_sight = false, nil, nil, 0, 0, false
    end

    while true do
        local player_ped_id = PlayerPedId()
        local in_vehicle = IsPedInAnyVehicle(player_ped_id, true)
        local is_nui_focused = IsNuiFocused()
        local is_pause_menu = GetPauseMenuState()
        local player_position = GetEntityCoords(player_ped_id)

        state_manager.set({
            playerIsInVehicle = in_vehicle,
            isNuiFocused = is_nui_focused,
            isPauseMenuState = is_pause_menu,
            playerPed = player_ped_id,
            playerPosition = player_position
        })

        if is_pause_menu == 0 and is_nui_focused ~= 1 then
            if not state_manager.get("disableRayCast") and not in_vehicle then
                hit, target_entity, ray_hit_position = Util.rayCast(511, player_ped_id)
                distance_to_target = ray_hit_position and #(player_position - ray_hit_position) or nil

                if target_entity ~= 0 then
                    if last_entity ~= target_entity then
                        local success, result = pcall(GetEntityType, target_entity)
                        target_entity_type = success and result or 0
                        last_entity = target_entity
                    end

                    if target_entity_type ~= 0 then
                        has_line_of_sight = HasEntityClearLosToEntity(target_entity, player_ped_id, 7)
                    end
                else
                    reset_ray_cast_info()
                end
            end

            state_manager.set({
                ray_hit_position = ray_hit_position,
                hitPosition = ray_hit_position,
            })

            ---@type DetectionContext
            local data      = {
                player_ped_id      = player_ped_id,
                player_position    = player_position,
                in_vehicle         = in_vehicle,
                is_nui_focused     = is_nui_focused,
                is_pause_menu      = is_pause_menu,
                ray_hit_position   = ray_hit_position,
                target_entity      = target_entity,
                target_entity_type = target_entity_type,
                distance_to_target = distance_to_target,
                has_line_of_sight  = has_line_of_sight
            }

            local menu_type = Features.resolve("Detect", data)
            if not menu_type then
                state_manager.reset()
                if Config.indicator.eye_enabled then
                    scaleform.send_nui("interactionMenu:eye:toggle", false)
                end
            else
                if Config.indicator.eye_enabled then
                    scaleform.send_nui("interactionMenu:eye:toggle", true)
                end
                Features.resolve("Detected", menu_type, data)
            end
        else
            state_manager.reset()
        end

        GC.collectAll()
        Wait(interval)
    end
end)

-- #endregion

-- #region Render Threads

function Render.generic(data, metadata, callbacks)
    if not data then return end
    Container.syncData(scaleform, data, false)
    if not IsMenuVisible(data) then return end

    state_manager.set('active', true)
    if callbacks.onEnter then if not callbacks.onEnter(data, metadata) then return end end

    Wait(0)
    state_manager.set('isOpen', true)
    Interact:scaleformUpdate(data)
    scaleform.setStatus(true)
    Container.validateAndSyncSelected(scaleform, data)

    -- Trigger onOeen
    for _, menu in pairs(data.menus) do
        Container.triggerInteraction(menu.id, 'onSeen', metadata)
    end

    if callbacks.afterStart then callbacks.afterStart(data, metadata) end
    Util.print_debug(('Menu Id [%s] '):format(data.id)) -- #DEBUG

    local running = true
    Container.current = data

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
                Wait(200)
            end
        end)
    end

    if Config.controls.enforce then
        UserInputManager:setMenuData(data)
        while running and callbacks.validate and callbacks.validate(data) do
            Wait(200)
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
    scaleform.send("interactionMenu:hideMenu")
    Wait(100) -- wait until fade animatnion is finished
    state_manager.set('isOpen', false)
    scaleform.setStatus(false)

    -- Trigger onExit
    for _, menu in pairs(data.menus) do
        Container.triggerInteraction(menu.id, 'onExit', metadata)
    end

    if callbacks.onExit then callbacks.onExit(data, metadata) end
    Container.current = nil
    state_manager.set('active', false)
end

function Render.setInterval(new_interval)
    Render.interval = new_interval
end

---@class MenuRenderData
---@field current_menu_id string|number
---@field menu_type string
---@field pause boolean
---@field is_nui_focused boolean
---@field is_pause_menu boolean
---@field entity_handle? number
---@field entity_model? number

local function render_menu()
    if paused then return end

    local nui_focused   = state_manager.get("isNuiFocused")
    local is_pause_menu = state_manager.get("isPauseMenuState")
    local current_id    = state_manager.get("id")
    local menu_type     = state_manager.get("menuType")
    local entity_handle = state_manager.get("entityHandle")
    local entity_model  = state_manager.get("entityModel")

    if nui_focused == 1 or is_pause_menu ~= 0 or not current_id then return end
    if not menu_type then
        return print("interactionMenu: Invalid menuType")
    end

    local data = {
        current_menu_id = current_id,
        menu_type       = menu_type,
        paused          = paused,
        is_nui_focused  = nui_focused,
        is_pause_menu   = is_pause_menu,
        entity_handle   = entity_handle,
        entity_model    = entity_model,
    }

    Features.resolve("PreRender", menu_type, data)
    Features.resolve("Render", menu_type, data)
    Features.resolve("PostRender", menu_type, data)
end

CreateThread(function()
    if not waitForScaleform() then return end

    while true do
        render_menu()
        Wait(Render.interval or 500)
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end

    if not scaleform then return end
    scaleform.setPosition(vector3(0, 0, 0))
    scaleform.dettach()
    scaleform.setStatus(false)
end)

-- #endregion
