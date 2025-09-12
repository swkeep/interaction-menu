local MAX_ALPHA = 255
local MIN_ALPHA = 0
local CHECK_VEHICLE_LOS = true
local CHECK_VEHICLE_MAX_DIST = true
local MAX_VEHICLE_DISTANCE = 10.0

local state_manager = Util.StateManager()
local distance_to_target
local entities_index = Container.indexes.entities
local models_index = Container.indexes.models
local bones_index = Container.indexes.bones
local net_ids_index = Container.indexes.netIds
local globals = Container.indexes.globals
local current_active_menu_id
local vehicle_point_alphas = {}
local closest_vehicle
local closest_vehicle_menus = {}
local has_global_entry = false

---@class BoneMenuInstance: MenuInstance
---@field bone GTAVBoneName
---@field vehicle? MenuInstanceVehicle

---@class MenuInstanceVehicle
---@field handle number
---@field networked boolean
---@field type string "entity type (from EntityType)"
---@field model number|string
---@field netId? number

-- functions

local function globals_exists_check(entity, entity_type)
    if not entity_type or entity_type == 0 then return false end
    local specific_globals = globals["vehicles"]

    if globals.entities and next(globals.entities) then
        return true
    end

    if entity_type == 2 and globals.bones and next(globals.bones) then
        return true
    end

    if specific_globals and next(specific_globals) then
        return true
    end

    return false
end

local function can_interact(data)
    local max_distance = data.maxDistance or 2
    return distance_to_target and distance_to_target < max_distance
end

local function is_matching_entity(model, entity)
    local state_id = state_manager.get("id")
    local state_entity_handle = state_manager.get("entityHandle")
    local matched = state_entity_handle == state_id

    return state_id and matched and state_id == entity
end

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function update_vehicle_point_alpha(key, is_active, frame_time, fade_speed)
    key = tostring(key)
    local current_alpha = vehicle_point_alphas[key] or MAX_ALPHA
    local target_alpha

    if key == tostring(current_active_menu_id) then
        target_alpha = MIN_ALPHA
    else
        target_alpha = MAX_ALPHA
    end

    local t = math.min(1, frame_time * fade_speed)
    current_alpha = lerp(current_alpha, target_alpha, t)

    vehicle_point_alphas[key] = current_alpha
    return math.floor(current_alpha)
end

local function get_closest_vehicle(player_ped_id, player_position)
    local vehicles = GetGamePool("CVehicle")
    local closest, closest_distance = nil, -1

    for i = 1, #vehicles do
        local vehicle = vehicles[i]
        local vehicle_coords = GetEntityCoords(vehicle)
        local distance = #(vehicle_coords - player_position)

        if not CHECK_VEHICLE_MAX_DIST or distance <= MAX_VEHICLE_DISTANCE then
            if not CHECK_VEHICLE_LOS or HasEntityClearLosToEntity(player_ped_id, vehicle, 17) then
                if closest_distance == -1 or distance < closest_distance then
                    closest = vehicle
                    closest_distance = distance
                end
            end
        end
    end

    return closest, closest_distance
end

local function get_vehicle_bone_menus(vehicle)
    if not vehicle then return {} end

    local bone_list = Container.indexes.bones[vehicle] or Container.indexes.globals.bones
    if not bone_list then return {} end

    local menus = {}
    local coords = GetEntityCoords(vehicle)
    local closest_distance = 1000
    local is_hood_open = GetVehicleDoorAngleRatio(vehicle, 4) > 0.9
    local is_hood_damaged = IsVehicleDoorDamaged(vehicle, 4)

    for bone_name, bone_menus in pairs(bone_list) do
        if (bone_name == "engine" and not is_hood_damaged and not is_hood_open) or
            (bone_name == "bonnet" and is_hood_damaged) then
            goto continue
        end

        local bone_id = GetEntityBoneIndexByName(vehicle, bone_name)
        if bone_id ~= -1 then
            local menu = Container.get(bone_menus[1])
            local bone_pos = GetEntityBonePosition_2(vehicle, bone_id)
            local dist = #(coords - bone_pos)

            if dist <= closest_distance then
                menus[bone_name] = {
                    distance = dist,
                    bone_id = bone_id,
                    position = bone_pos,
                    icon = menu and menu.icon,
                }
            end
        end

        ::continue::
    end

    return menus
end

-- bindings

---@param user_data UserCreateData
---@param instance BoneMenuInstance
local function handle_create(user_data, instance)
    instance.type = 'bone'
    instance.bone = user_data.bone

    if user_data.vehicle then
        instance.vehicle = {
            handle = user_data.vehicle,
            networked = NetworkGetEntityIsNetworked(user_data.vehicle) == 1,
            type = EntityTypes[GetEntityType(user_data.vehicle)],
            model = user_data.model or GetEntityModel(user_data.vehicle)
        }

        if instance.vehicle.networked then
            instance.vehicle.netId = NetworkGetNetworkIdFromEntity(user_data.vehicle)
        end
    end

    -- classify menu
    local indexes = Container.indexes
    local bones = indexes.bones
    local entity = instance.vehicle and instance.vehicle.handle
    local model = instance.vehicle and instance.vehicle.model

    bones[entity] = bones[entity] or {}
    bones[entity][instance.bone] = bones[entity][instance.bone] or {}

    table.insert(bones[entity][instance.bone], instance.id)
end

---@param data DetectionContext
---@return FEATURES_LIST?
local function handle_detect(data)
    if data.in_vehicle == 1 then return end

    local target_entity = data.target_entity
    local entity_type = data.target_entity_type
    if not target_entity or entity_type ~= 2 then return end

    local ray_hit_position = data.ray_hit_position
    local entity_model = GetEntityModel(target_entity)
    local is_networked = NetworkGetEntityIsNetworked(target_entity)
    local net_id = is_networked and NetworkGetNetworkIdFromEntity(target_entity) or nil
    local has_global_entry = globals_exists_check(target_entity, entity_type)

    local is_indexed = models_index[entity_model] or entities_index[target_entity] or net_ids_index[net_id]
    if is_indexed or has_global_entry then
        return FEATURES_LIST.ON_VEHICLE_BONE
    else
        local _, closestBoneName = Container.boneCheck(ray_hit_position, target_entity)
        if bones_index[target_entity] and bones_index[target_entity][closestBoneName] then
            return FEATURES_LIST.ON_VEHICLE_BONE
        end
    end
end

local function handle_detected(data)
    distance_to_target = data.distance_to_target

    state_manager.set({
        id = data.target_entity,
        menuType = FEATURES_LIST.ON_VEHICLE_BONE,
        entityHandle = data.target_entity,
        entityModel = data.target_model,
        playerDistance = data.distance_to_target
    })
end

---@param render_data MenuRenderData
local function handle_render(render_data)
    local entity_handle = render_data.entity_handle
    local entity_model = render_data.entity_model
    local is_vehicle = GetEntityType(entity_handle) == 2
    if not is_vehicle then return end -- shouldn't happen

    local data = Container.getMenu(entity_model, entity_handle)
    if not data then return end
    if not can_interact(data) then return end

    data.model = entity_model
    data.entity = entity_handle

    local scaleform = Interact:getScaleform()
    local ray_hit_position = state_manager.get("ray_hit_position")
    local closest_vehicle_bone = Container.boneCheck(ray_hit_position, entity_handle)
    local metadata = Container.constructMetadata(data)

    Render.generic(data, metadata, {
        onEnter = function()
            local offset = data.offset or vec3(0, 0, 0)

            scaleform.set3d(false)
            scaleform.attach {
                entity = entity_handle,
                offset = offset,
                bone = closest_vehicle_bone,
                static = data.static
            }
            metadata.position = GetEntityCoords(entity_handle)

            current_active_menu_id = data.id
            return can_interact(data)
        end,
        validate = function()
            return is_matching_entity(entity_model, entity_handle)
        end,
        validateSlow = function()
            ray_hit_position = state_manager.get("ray_hit_position")
            local current_closest_bone = Container.boneCheck(ray_hit_position, entity_handle)
            return closest_vehicle_bone == current_closest_bone and can_interact(data)
        end,
        onExit = function()
            current_active_menu_id = nil
            scaleform.dettach()
        end
    })
end

local function handle_post_render()
    state_manager.reset()
end

local function handle_find_indicator(data)
    local player_ped_id = data.player_ped_id
    local player_position = data.player_position

    closest_vehicle = get_closest_vehicle(player_ped_id, player_position)
    closest_vehicle_menus = get_vehicle_bone_menus(closest_vehicle)
    has_global_entry = globals_exists_check(closest_vehicle, 2)
end

local function handle_render_indicator(data)
    local player_pos = data.player_position
    local frame_time = GetFrameTime() or 0.016
    local fade_speed = 6.0

    for _, value in pairs(closest_vehicle_menus) do
        local key = tostring(closest_vehicle) .. "|" .. tostring(value.bone_id)
        local alpha = update_vehicle_point_alpha(key, true, frame_time, fade_speed)

        if alpha > 0 and key ~= tostring(current_active_menu_id) then
            DrawIndicator(value.position, player_pos, value.icon, alpha)
        end
    end

    if has_global_entry and data.current_menu_id ~= closest_vehicle then
        local alpha = update_vehicle_point_alpha(closest_vehicle, true, frame_time, fade_speed)
        local position = GetEntityCoords(closest_vehicle)
        if alpha > 0 and closest_vehicle ~= data.current_menu_id and closest_vehicle ~= current_active_menu_id then
            DrawIndicator(position, player_pos, nil, alpha)
        end
    end
end

Features.on("Create", handle_create, { id = "ON_VEHICLE_BONE" })
Features.on("Detect", handle_detect, { id = FEATURES_LIST.ON_VEHICLE_BONE })
Features.on("Detected", handle_detected, { id = FEATURES_LIST.ON_VEHICLE_BONE })
Features.on("Render", handle_render, { id = FEATURES_LIST.ON_VEHICLE_BONE })
Features.on("PostRender", handle_post_render, { id = FEATURES_LIST.ON_VEHICLE_BONE })
Features.on("FindIndicator", handle_find_indicator, { id = FEATURES_LIST.ON_VEHICLE_BONE })
Features.on("RenderIndicator", handle_render_indicator, { id = FEATURES_LIST.ON_VEHICLE_BONE })
