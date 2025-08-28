if not Config.features.drawIndicator.active then return end

-- #region Show sprite while holding alt

local RED = 255
local GREEN = 255
local BLUE = 255
local ALPHA = 255
local MIN_SCALE_X = 0.02 / 4
local MAX_SCALE_X = MIN_SCALE_X * 5
local MIN_SCALE_Y = 0.035 / 4
local MAX_SCALE_Y = MIN_SCALE_Y * 5
local MIN_DISTANCE = 2.0
local MAX_DISTANCE = 20.0
local MAX_ENTITIES = 10

local spatial_hash_grid = Util.SpatialHashGrid
local current_sprite_thread_hash = nil
local is_sprite_thread_running = false
local is_target_sprites_active = false
local state_manager = Util.StateManager()
local grid_position = spatial_hash_grid:new('position', 100)
local visible_points = {}
local visible_point_count = 0
local current_menu_type
local nearby_objects = {}
local nearby_objects_limited = {}
local current_vehicle_menu
local closest_vehicle_menus = {}
local center_of_zones = {}

CreateThread(function()
    local txd = CreateRuntimeTxd('interaction_txd_indicator')
    CreateRuntimeTextureFromImage(txd, 'indicator', "lua/client/icons/indicator.png")
    for index, value in ipairs(Config.icons) do
        CreateRuntimeTextureFromImage(txd, value, ("lua/client/icons/%s.png"):format(value))
    end
end)

local function _draw_sprite(point, player_position, icon)
    if not point then return end
    local distance = #(vec3(point.x, point.y, point.z) - player_position)
    local clamped_distance = math.max(MIN_DISTANCE, math.min(MAX_DISTANCE, distance))

    local scale_range_x = MAX_SCALE_X - MIN_SCALE_X
    local scale_range_y = MAX_SCALE_Y - MIN_SCALE_Y
    local distance_range = MAX_DISTANCE - MIN_DISTANCE
    local normalized_distance = (clamped_distance - MIN_DISTANCE) / distance_range

    local scale_x = MIN_SCALE_X + scale_range_x * (1 - normalized_distance)
    local scale_y = MIN_SCALE_Y + scale_range_y * (1 - normalized_distance)

    SetDrawOrigin(point.x, point.y, point.z, 0)
    DrawSprite('interaction_txd_indicator', icon or 'indicator', 0, 0, scale_x, scale_y, 0, RED, GREEN, BLUE, ALPHA)
    ClearDrawOrigin()
end

local function _get_nearby_objects(is_active, current_menu, coords)
    local objects = GetGamePool('CObject')
    local entity_handle = state_manager.get('entityHandle')
    nearby_objects_limited = {}

    for i = 1, #objects do
        local object = objects[i]
        local object_coords = GetEntityCoords(object)
        local distance = #(coords - object_coords)

        if distance < MAX_DISTANCE then
            local existing_data = nearby_objects[object]
            local entity_type = GetEntityType(object)
            local model = GetEntityModel(object)

            local menu_type = Container.getMenuType {
                model = model,
                entity = object,
                entityType = entity_type
            }

            if menu_type > 1 and entity_handle ~= object then
                if not existing_data then
                    local menu = Container.getMenu(model, object, nil)
                    nearby_objects[object] = {
                        object = object,
                        coords = object_coords,
                        type = entity_type,
                        icon = menu and menu.icon,
                        distance = distance,
                        menu = menu
                    }
                else
                    existing_data.coords = object_coords
                    existing_data.distance = distance
                end
            end
        else
            nearby_objects[object] = nil
        end
    end

    for object, data in pairs(nearby_objects) do
        if is_active == false or (data and entity_handle ~= data.object) then
            nearby_objects_limited[#nearby_objects_limited + 1] = data
        end
    end

    table.sort(nearby_objects_limited, function(a, b)
        return a.distance < b.distance
    end)
end

local function _get_closest_vehicle()
    local ped = PlayerPedId()
    local vehicles = GetGamePool('CVehicle')
    local closest_distance = -1
    local closest_vehicle = -1
    local coords = GetEntityCoords(ped)

    for i = 1, #vehicles, 1 do
        local vehicle_coords = GetEntityCoords(vehicles[i])
        local distance = #(vehicle_coords - coords)

        if closest_distance == -1 or closest_distance > distance then
            closest_vehicle = vehicles[i]
            closest_distance = distance
        end
    end

    return closest_vehicle, closest_distance
end

local function _get_vehicle_bone_menus()
    local closest_vehicle = _get_closest_vehicle()
    local bone_list = Container.indexes.bones[closest_vehicle] or Container.indexes.globals.bones
    local closest_vehicle_menus = {}

    if bone_list then
        local closest_distance = 10000
        local is_hood_open = GetVehicleDoorAngleRatio(closest_vehicle, 4) > 0.9
        local is_hood_damaged = IsVehicleDoorDamaged(closest_vehicle, 4)
        local coords = GetEntityCoords(closest_vehicle)

        for bone_name, bone_menus in pairs(bone_list) do
            local bone_id = GetEntityBoneIndexByName(closest_vehicle, bone_name)
            if bone_id ~= -1 then
                if bone_name == "engine" and (is_hood_damaged == false and not is_hood_open) then
                    goto continue
                end

                if bone_name == "bonnet" and is_hood_damaged then
                    goto continue
                end

                local menu = Container.get(bone_menus[1])
                local bone_position = GetEntityBonePosition_2(closest_vehicle, bone_id)
                local distance = #(coords - bone_position)

                if distance <= closest_distance then
                    closest_vehicle_menus[bone_name] = {
                        distance = distance,
                        bone_id = bone_id,
                        position = bone_position,
                        icon = menu and menu.icon
                    }
                end
            end
            ::continue::
        end
    end

    return closest_vehicle_menus, closest_vehicle
end

local function _start_sprite_thread()
    if is_sprite_thread_running then return end
    is_sprite_thread_running = true
    local player = PlayerPedId()
    local player_position = state_manager.get('playerPosition')
    local current_menu = state_manager.get('id')
    local is_active = state_manager.get('active')
    local closest_vehicle
    local thread_hash = math.random(1000000)
    current_sprite_thread_hash = thread_hash

    closest_vehicle_menus = _get_vehicle_bone_menus()

    CreateThread(function()
        while is_sprite_thread_running and current_sprite_thread_hash == thread_hash do
            is_active = state_manager.get('active')
            current_menu = state_manager.get('id')
            current_menu_type = state_manager.get('menuType')
            _get_nearby_objects(is_active, current_menu, player_position)
            local near_points, total_near_points = grid_position:queryRange(player_position, 20)
            visible_points, visible_point_count = Util.filterVisiblePointsWithinRange(player_position, near_points)
            closest_vehicle = _get_closest_vehicle()
            closest_vehicle_menus = _get_vehicle_bone_menus()

            if not (is_active and current_menu_type == 4) then
                for key, value in pairs(Container.zones) do
                    local pos = value.center or value.coords
                    if type(pos) == "vector3" then
                        center_of_zones[key] = {
                            coords = pos,
                            icon = value.icon
                        }
                    else
                        center_of_zones[key] = {
                            coords = vec3(pos.x, pos.y, (value.minZ + value.maxZ) / 2),
                            icon = value.icon
                        }
                    end
                end
            else
                center_of_zones = {}
            end

            Wait(500)
        end
    end)

    CreateThread(function()
        while is_target_sprites_active and current_sprite_thread_hash == thread_hash do
            player_position = GetEntityCoords(player)

            if visible_point_count > 0 then
                for i = 2, #visible_points, 1 do
                    if visible_points[i].id ~= current_menu then
                        _draw_sprite(visible_points[i].point, player_position, visible_points[i].icon)
                    end
                end

                if visible_points[1].point.ids then
                    if not is_active then
                        _draw_sprite(visible_points[1].point, player_position, visible_points[1].icon)
                    end
                else
                    if visible_points[1].id ~= current_menu and not is_active then
                        _draw_sprite(visible_points[1].point, player_position, visible_points[1].icon)
                    end
                end
            end

            for index, value in pairs(nearby_objects_limited) do
                if index > MAX_ENTITIES then break end
                _draw_sprite(value.coords, player_position, value.icon)
            end

            for index, value in pairs(center_of_zones) do
                _draw_sprite(value.coords, player_position, value.icon)
            end

            if closest_vehicle ~= current_vehicle_menu then
                for key, value in pairs(closest_vehicle_menus) do
                    _draw_sprite(value.position, player_position, value.icon)
                end
            end

            Wait(0)
        end
        is_sprite_thread_running = false
    end)
end

function UpdateNearbyObjects()
    local player_position = state_manager.get('playerPosition')
    local current_menu = state_manager.get('id')
    local is_active = state_manager.get('active')
    _get_nearby_objects(is_active, current_menu, player_position)
end

function CleanNearbyObjects()
    nearby_objects = {}
    nearby_objects_limited = {}
end

AddEventHandler("interactionMenu:client:set_vehicle", function(veh)
    if veh == nil then
        current_vehicle_menu = nil
        closest_vehicle_menus = {}
    else
        current_vehicle_menu = veh
        closest_vehicle_menus = _get_vehicle_bone_menus()
    end
end)

RegisterCommand('+toggle_target_sprites', function()
    is_target_sprites_active = true
    _start_sprite_thread()
end, false)

RegisterCommand('-toggle_target_sprites', function()
    is_target_sprites_active = false
    is_sprite_thread_running = false
end, false)

RegisterKeyMapping('+toggle_target_sprites', 'Toggle Target Sprites', 'keyboard', 'LMENU')
RegisterKeyMapping('~!+toggle_target_sprites', 'Toggle Target Sprites - Alternate Key', 'keyboard', 'RMENU')

-- #endregion
