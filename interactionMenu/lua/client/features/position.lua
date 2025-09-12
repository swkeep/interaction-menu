local FADE_SPEED = 25.0
local MAX_ALPHA = 255
local MIN_ALPHA = 0

local state_manager = Util.StateManager()
local grid = Util.SpatialHashGrid:new("position", 100)
local current_active_menu_id
local visible_points = {}
local point_alphas = {}


-- functions

local function is_player_within_distance(max_distance)
    local player_distance = state_manager.get("playerDistance")
    max_distance = max_distance or 2

    return player_distance and player_distance < max_distance
end

local function can_interact(data, ...)
    return is_player_within_distance(data.maxDistance)
end

-- #TODO: switch to lerp
local function update_point_alpha(point_id)
    local key = tostring(point_id)
    local current_alpha = point_alphas[key] or MAX_ALPHA

    if key == tostring(current_active_menu_id) then
        current_alpha = math.max(MIN_ALPHA, current_alpha - FADE_SPEED)
    else
        current_alpha = math.min(MAX_ALPHA, current_alpha + FADE_SPEED)
    end

    point_alphas[key] = current_alpha
    return math.floor(current_alpha)
end

-- bindings

local function handle_create(user_data, instance)
    local id = instance.id
    instance.type = "position"
    instance.position = {
        id = id,
        x = user_data.position.x,
        y = user_data.position.y,
        z = user_data.position.z,
        max_distance = user_data.maxDistance
    }
    instance.rotation = user_data.rotation

    local is_occupied, found_item = grid:isPositionOccupied({
        x = user_data.position.x,
        y = user_data.position.y
    })

    if is_occupied then
        if not found_item.ids then
            local current_id = found_item.id
            found_item.id = nil
            found_item.ids = { current_id }
        end
        found_item.ids[#found_item.ids + 1] = id
    else
        grid:insert(instance.position)
    end
end

local function handle_detect(data)
    local near_points = grid:queryRange(data.player_position, 50)
    visible_points = Util.filterVisiblePointsWithinRange(data.player_position, near_points, 50)

    if visible_points and next(visible_points) then
        local found = false
        for index, value in ipairs(visible_points) do
            local max_distance = value.maxDistance or 2
            if max_distance > value.distance then
                found = true
            end
        end

        if found then
            return FEATURES_LIST.AT_POSITION
        end
    end
end

local function handle_detected(data)
    local max_distance = visible_points[1].max_distance or 3

    if visible_points[1].distance and visible_points[1].distance < max_distance then
        local ids = visible_points[1].point.ids or visible_points[1].id
        state_manager.set({
            id = ids,
            menuType = FEATURES_LIST.AT_POSITION,
            playerDistance = visible_points[1].distance
        })
    end
end

local function handle_render(render_data)
    local data
    local scaleform = Interact:getScaleform()
    local current_menu_id = render_data.current_menu_id

    -- table is used to detect stacked menus
    if type(current_menu_id) == "table" then
        data = Container.getMenu(nil, nil, nil, current_menu_id)
    else
        data = Container.getMenu(nil, nil, current_menu_id)
    end

    if not data or not can_interact(data) then return end

    local metadata = Container.constructMetadata(data)
    local position, rotation = data.position, data.rotation
    Render.generic(data, metadata, {
        onEnter = function()
            current_active_menu_id = current_menu_id
            state_manager.set("disableRayCast", true)
            scaleform.setPosition(position)

            if rotation then
                scaleform.setRotation(rotation)
                scaleform.set3d(true)
                scaleform.setScale(data.scale or 1)
            else
                scaleform.set3d(false)
            end

            return can_interact(data)
        end,
        validate = function()
            return can_interact(data) and state_manager.get("id") == current_menu_id
        end,
        onExit = function()
            state_manager.set("disableRayCast", false)
            current_active_menu_id = nil
        end
    })
end

local function handle_set(menu_data, set_data)
    if not menu_data.position then
        return warn("Menu is not position-based and its position cannot be updated")
    end

    if type(set_data.value) ~= "vector3" and type(set_data.value) ~= "vector4" then
        return warn("Position value must be a vector3 or vector4")
    end

    set_data.value = vec2(set_data.value.x, set_data.value.y)
    grid:update(menu_data.position, set_data.value)
end

local function handle_render_iIndicator(data)
    local n = #visible_points
    if n == 0 then return end

    local player_position = data.player_position

    for i = 2, n do
        DrawIndicator(visible_points[i].point, player_position, visible_points[i].icon)
    end

    local primary = visible_points[1]
    if primary then
        local id = primary.point.ids or primary.id
        if id then
            local alpha = update_point_alpha(id)
            if alpha > 0 then
                DrawIndicator(primary.point, player_position, primary.icon, alpha)
            end
        else
            DrawIndicator(primary.point, player_position, primary.icon)
        end
    end
end

Features.on("RenderIndicator", handle_render_iIndicator, { id = FEATURES_LIST["AT_POSITION"] })
Features.on("Create", handle_create, { id = "AT_POSITION" })
Features.on("Detect", handle_detect, { id = FEATURES_LIST.AT_POSITION })
Features.on("Detected", handle_detected, { id = FEATURES_LIST.AT_POSITION })
Features.on("Render", handle_render, { id = FEATURES_LIST.AT_POSITION })
Features.on("Set", handle_set, { id = FEATURES_LIST.AT_POSITION })
