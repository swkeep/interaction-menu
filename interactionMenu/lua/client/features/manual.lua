local state_manager = Util.StateManager()

-- bindings

local function handle_create(user_data, instance)
    local id = instance.id

    instance.type = "manual"
    instance.entity = {
        handle = user_data.entity,
        networked = NetworkGetEntityIsNetworked(user_data.entity) == 1,
        type = EntityTypes[GetEntityType(user_data.entity)],
        model = user_data.model or GetEntityModel(user_data.entity)
    }
    instance.rotation = user_data.rotation
    instance.scale = user_data.scale
    instance.manual_events = {
        [1] = AddEventHandler(user_data.triggers.open, function()
            if state_manager.get('active') then
                state_manager.reset()
                Wait(500) -- we've to wait until menu is closed
            end
            Container.current_manual_menu = id
            state_manager.set({
                id = id,
                menuType = FEATURES_LIST.OPENED_MANUALLY,
                entityModel = GetEntityModel(user_data.entity),
                entityHandle = user_data.entity,
                playerDistance = 0.0,
                disableRayCast = true
            })
        end),
        [2] = AddEventHandler(user_data.triggers.close, function()
            Container.current_manual_menu = nil
            state_manager.reset()
        end)
    }
end

local function handle_detect(data)
    if Container.current_manual_menu then
        return FEATURES_LIST.OPENED_MANUALLY
    end
end

local function handle_render(render_data)
    local current_menu_id = render_data.current_menu_id
    local data = Container.getMenu(nil, nil, current_menu_id)
    if not data then return end

    local entity = render_data.entity_handle
    local model = render_data.entity_model
    local scaleform = Interact:getScaleform()
    local offset = data.offset or vec3(0, 0, 0)

    data.model = model
    data.entity = entity
    local metadata = Container.constructMetadata(data)

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
            scaleform.attach { entity = entity, offset = offset, static = false }
            metadata.position = GetEntityCoords(entity)
            return true
        end,
        validate = function()
            return state_manager.get("id") == current_menu_id
        end,
        onExit = function()
            scaleform.dettach()
            scaleform.setForwardVectorLock(false)
            state_manager.reset()
        end
    })
end

Features.on("Create", handle_create, { id = "OPENED_MANUALLY" })
Features.on("Detect", handle_detect, { id = FEATURES_LIST.OPENED_MANUALLY })
Features.on("Render", handle_render, { id = FEATURES_LIST.OPENED_MANUALLY })
