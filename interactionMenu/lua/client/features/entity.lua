local SetScriptGfxDrawBehindPausemenu = SetScriptGfxDrawBehindPausemenu

local state_manager                   = Util.StateManager()
local entity_sets                     = { "peds", "vehicles", "objects" }
local current_menu_id                 = nil
local nearby_objects                  = {}
local MAX_DISTANCE                    = 50.0
local CACHE_TTL_MS                    = 4000
local last_cleanup                    = 0
local outline_color                   = Config.indicator.outline_color

local indexes                         = Container.indexes
local entities_index                  = indexes.entities
local models_index                    = indexes.models
local players_index                   = indexes.players
local net_ids_index                   = indexes.netIds
local globals_index                   = indexes.globals

-- helpers
local function is_player_within_distance(max_distance)
    local dist = state_manager.get("playerDistance")
    return dist and dist < (max_distance or 2)
end

local function can_interact(data)
    return is_player_within_distance(data.maxDistance)
end

local function identify_player_server_id(entity_type, entity)
    return entity_type == 1 and IsPedAPlayer(entity) and GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
end

local function globals_exists_check(entity, entity_type)
    if not entity_type or entity_type == 0 then return false end

    if entity_type == 1 and globals_index.players and next(globals_index.players) then
        return true
    end
    if globals_index.entities and next(globals_index.entities) then
        return true
    end

    local specific = globals_index[entity_sets[entity_type]]
    return specific and next(specific) or false
end

local function is_matching_entity(model, entity)
    local state_id, handle = state_manager.get("id"), state_manager.get("entityHandle")
    return state_id and handle == state_id and state_id == entity
end

local function entity_is_indexed(entity_type, model, entity, player_id, net_id)
    if entity_type == 1 then
        return models_index[model] or entities_index[entity] or players_index[player_id] or net_ids_index[net_id]
    elseif entity_type == 3 then
        return models_index[model] or entities_index[entity] or net_ids_index[net_id]
    end
    return false
end

local function has_menu(model, entity)
    local entity_type = GetEntityType(entity)
    local player_id   = identify_player_server_id(entity_type, entity)
    local net_id      = NetworkGetEntityIsNetworked(entity) and NetworkGetNetworkIdFromEntity(entity)
    local indexed     = entity_is_indexed(entity_type, model, entity, player_id, net_id)
    return indexed or globals_exists_check(entity, entity_type)
end

local function DrawOutlineEntity(entity, enabled)
    if Config.indicator.outline_enabled and not IsEntityAPed(entity) then
        SetEntityDrawOutline(entity, enabled)
        SetEntityDrawOutlineColor(outline_color[1], outline_color[2], outline_color[3], outline_color[4])
    end
end
exports('DrawOutlineEntity', DrawOutlineEntity)

local function lerp(a, b, t)
    return a + (b - a) * t
end

local function update_alpha(ent_data, should_draw, frame_time, fade_speed)
    local target   = should_draw and 255 or 0
    local t        = math.min(1, frame_time * fade_speed)
    ent_data.alpha = lerp(ent_data.alpha, target, t)
    return math.floor(math.max(0, math.min(255, ent_data.alpha)))
end

local function process_entity(entity, coords, entity_handle, now)
    if not DoesEntityExist(entity) or entity == entity_handle then
        nearby_objects[entity] = nil
        return
    end

    local ent_coords = GetEntityCoords(entity)
    local dist       = #(coords - ent_coords)

    if dist < MAX_DISTANCE then
        local data = nearby_objects[entity]
        if not data then
            local model            = GetEntityModel(entity)
            local menu             = has_menu(model, entity) and Container.getMenu(model, entity)

            nearby_objects[entity] = {
                object       = entity,
                model        = model,
                has_menu     = menu ~= nil,
                coords       = ent_coords,
                distance     = dist,
                visible      = Util.isPointWithinScreenBounds(ent_coords.x, ent_coords.y),
                alpha        = 0,
                last_updated = now,
                icon         = menu and menu.icon,
            }
        else
            local retval      = GetScreenCoordFromWorldCoord(ent_coords.x, ent_coords.y, ent_coords.z)
            data.coords       = ent_coords
            data.distance     = dist
            data.last_updated = now
            data.visible      = retval
            data.has_menu     = has_menu(data.model, entity)
        end
    elseif nearby_objects[entity] then
        nearby_objects[entity].visible = false
    end
end

-- feature handlers
local function handle_create(user_data, instance)
    local e = user_data.entity
    if e then
        if not DoesEntityExist(e) then
            warn(("Menu creation failed:\n - Entity does not exist: %s\n - Invoking resource: %s")
                :format(e, instance.metadata.invokingResource))
            return
        end
        instance.type   = "entity"
        instance.entity = {
            handle    = e,
            networked = NetworkGetEntityIsNetworked(e) == 1,
            type      = EntityTypes[GetEntityType(e)],
            model     = user_data.model or GetEntityModel(e),
        }
        if instance.entity.networked then
            instance.entity.netId = NetworkGetNetworkIdFromEntity(e)
        end
        if instance.tracker == "boundingBox" then
            BoundingBox.watch(e, {
                name       = e,
                useZ       = true,
                dimensions = user_data.dimensions or { vec3(-1, -1, -1), vec3(1, 1, 1) }
            })
        end
        entities_index[e] = entities_index[e] or {}
        table.insert(entities_index[e], instance.id)
        return
    end

    if user_data.model then
        instance.type                = "model"
        instance.model               = user_data.model
        models_index[instance.model] = models_index[instance.model] or {}
        table.insert(models_index[instance.model], instance.id)
    elseif user_data.netId then
        instance.type                 = "netId"
        instance.netId                = user_data.netId
        net_ids_index[instance.netId] = net_ids_index[instance.netId] or {}
        table.insert(net_ids_index[instance.netId], instance.id)
    elseif user_data.player then
        players_index[user_data.player] = players_index[user_data.player] or {}
        table.insert(players_index[user_data.player], instance.id)
    end
end

local function handle_detect(data)
    if data.in_vehicle == 1 then return end
    if BoundingBox.lastClosest then return FEATURES_LIST.TARGETING_ENTITY end
    local target = data.target_entity
    if not target then return end

    local entity_type = GetEntityType(target)
    if entity_type == 0 then return end

    local model    = GetEntityModel(target)
    local playerId = identify_player_server_id(entity_type, target)
    local netId    = NetworkGetEntityIsNetworked(target) and NetworkGetNetworkIdFromEntity(target)
    if entity_is_indexed(entity_type, model, target, playerId, netId)
        or globals_exists_check(target, entity_type) then
        return FEATURES_LIST.TARGETING_ENTITY
    end
end

local function handle_detected(data)
    SetScriptGfxDrawBehindPausemenu(false)
    state_manager.set("menuType", FEATURES_LIST.TARGETING_ENTITY)

    local ent = BoundingBox.lastClosest and BoundingBox.lastClosest.entity or data.target_entity
    state_manager.set({
        id             = ent,
        entityHandle   = ent,
        entityModel    = GetEntityModel(ent),
        playerDistance = BoundingBox.lastClosest and 0.0 or data.distance_to_target,
    })
end

local function handle_render(render_data)
    local handle, model = render_data.entity_handle, render_data.entity_model
    local menu_data     = Container.getMenu(model, handle)
    if not menu_data or not can_interact(menu_data) then return end

    local scaleform  = Interact:getScaleform()
    menu_data.model  = model
    menu_data.entity = handle

    local offset     = menu_data.offset or vec3(0, 0, 0)
    local metadata   = Container.constructMetadata(menu_data)

    Render.generic(menu_data, metadata, {
        onEnter      = function()
            current_menu_id = menu_data.id
            scaleform.set3d(false)
            scaleform.attach { entity = handle, offset = offset, static = menu_data.static }
            metadata.position = GetEntityCoords(handle)
            DrawOutlineEntity(handle, true)
            return can_interact(menu_data)
        end,
        validate     = function()
            return is_matching_entity(model, handle)
        end,
        validateSlow = function()
            return can_interact(menu_data)
        end,
        onExit       = function()
            current_menu_id = nil
            state_manager.reset()
            scaleform.dettach()
            DrawOutlineEntity(handle, false)
        end
    })
end

local function handle_post_render()
    state_manager.reset()
end

local function handle_find_indicator(data)
    local now           = GetGameTimer()
    local entity_handle = state_manager.get("entityHandle")
    local player_ped    = PlayerPedId()
    local weapon        = GetCurrentPedWeaponEntityIndex(player_ped)

    -- filter objects
    for _, ent in ipairs(GetGamePool("CObject") or {}) do
        local skip = ent == weapon
        if not skip and weapon ~= 0 then
            local parent = GetEntityAttachedTo(ent)
            while parent ~= 0 do
                if parent == weapon then
                    skip = true
                    break
                end
                parent = GetEntityAttachedTo(parent)
            end
        end
        if not skip then
            process_entity(ent, data.player_position, entity_handle, now)
        end
    end

    -- filter peds (skip self)
    for _, ped in ipairs(GetGamePool("CPed") or {}) do
        if ped ~= player_ped then
            process_entity(ped, data.player_position, entity_handle, now)
        end
    end

    -- cleanup stale cache
    if now - last_cleanup >= CACHE_TTL_MS then
        last_cleanup = now
        for handle, obj in pairs(nearby_objects) do
            if now - (obj.last_updated or 0) >= CACHE_TTL_MS then
                nearby_objects[handle] = nil
            end
        end
    end
end

local function handle_render_indicator(data)
    local player_pos = data.player_position
    local frame_time = GetFrameTime()
    local fade_speed = 6.0

    for _, v in pairs(nearby_objects) do
        local draw = v.has_menu and v.visible
        if draw and current_menu_id ~= (v.model .. "|" .. v.object) then
            local alpha = update_alpha(v, true, frame_time, fade_speed)
            if alpha > 0 and v.coords then
                DrawIndicator(v.coords, player_pos, v.icon, alpha)
            end
        end
    end
end

-- bindings
Features.on("Create", handle_create, { id = "TARGETING_ENTITY" })
Features.on("Detect", handle_detect, { id = FEATURES_LIST.TARGETING_ENTITY })
Features.on("Detected", handle_detected, { id = FEATURES_LIST.TARGETING_ENTITY })
Features.on("Render", handle_render, { id = FEATURES_LIST.TARGETING_ENTITY })
Features.on("PostRender", handle_post_render, { id = FEATURES_LIST.TARGETING_ENTITY })
Features.on("FindIndicator", handle_find_indicator, { id = FEATURES_LIST.TARGETING_ENTITY })
Features.on("RenderIndicator", handle_render_indicator, { id = FEATURES_LIST.TARGETING_ENTITY })


--#region ENTITYZONE

local math_rad, math_cos, math_sin, math_huge = math.rad, math.cos, math.sin, math.huge
local vec3 = vector3
local grid_entities = Util.SpatialHashGrid:new('entities', 100)

BoundingBox = {
    hash = {},  -- entity -> id
    zones = {}, -- id -> instance
    lastClosest = nil
}

local function rotate_point(point, center, angle)
    local dx, dy = point.x - center.x, point.y - center.y
    local rad = math_rad(angle)
    local cosA, sinA = math_cos(rad), math_sin(rad)

    return vec3(
        dx * cosA - dy * sinA + center.x,
        dx * sinA + dy * cosA + center.y,
        point.z
    )
end

local function calc_min_max_z(entity, dims)
    local pos = GetEntityCoords(entity)
    return pos.z + dims[1].z, pos.z + dims[2].z
end

local function is_point_in_box(point, box, rotation)
    local center = (box.min + box.max) * 0.5
    local rotated = rotate_point(point, center, -rotation)

    return rotated.x >= box.min.x and rotated.x <= box.max.x
        and rotated.y >= box.min.y and rotated.y <= box.max.y
        and rotated.z >= box.min.z and rotated.z <= box.max.z
end

local function query_nearby(pos)
    return grid_entities:queryRange(pos, 25)
end

function BoundingBox.watch(entity, opts)
    if not DoesEntityExist(entity) then return nil end

    local id = #BoundingBox.zones + 1
    local model = GetEntityModel(entity)
    local min, max = GetModelDimensions(model)
    local pos = GetEntityCoords(entity)
    local dims = opts.dimensions or { vec3(min.x, min.y, min.z), vec3(max.x, max.y, max.z) }

    local instance = {
        id = id,
        entity = entity,
        dimensions = dims,
        use_z = opts.use_z or false,
        position = pos,
        rotation = GetEntityHeading(entity),
        pause = false,
        networked = NetworkGetEntityIsNetworked(entity),
        grid_ref = { id = id, x = pos.x, y = pos.y, z = pos.z }
    }

    if opts.use_z then
        instance.min_z, instance.max_z = calc_min_max_z(entity, dims)
    end

    BoundingBox.zones[id] = instance
    BoundingBox.hash[entity] = id
    grid_entities:insert(instance.grid_ref)

    return instance
end

function BoundingBox.unwatch(entity)
    local id = BoundingBox.hash[entity]
    if not id then return false end

    local inst = BoundingBox.zones[id]
    if inst then
        BoundingBox.hash[entity] = nil
        grid_entities:remove(inst.grid_ref)
        BoundingBox.zones[id] = nil
    end
    return true
end

local function detect(player_pos)
    local closest, closest_dist = nil, math_huge
    local results = query_nearby(player_pos)

    for i = 1, #results do
        local inst = BoundingBox.zones[results[i].id]
        if inst and not inst.pause then
            local box = {
                min = inst.position + inst.dimensions[1],
                max = inst.position + inst.dimensions[2]
            }

            if is_point_in_box(player_pos, box, inst.rotation) then
                local dist = #(player_pos - inst.position)
                if dist < closest_dist then
                    closest_dist = dist
                    closest = { entity = inst.entity, id = inst.id, dimensions = inst.dimensions }
                end
            end
        end
    end

    BoundingBox.lastClosest = closest
end

local function update_instance(inst)
    if not inst then return end
    local does_exist = DoesEntityExist(inst.entity)
    -- pause detetection if it's networked might gone out of scope
    -- if it's not then it's probably deleted
    if not does_exist and inst.networked then
        inst.pause = true
        return
    elseif not does_exist then
        BoundingBox.unwatch(inst.entity)
        return
    end
    inst.pause = false
    inst.position = GetEntityCoords(inst.entity)
    inst.rotation = GetEntityHeading(inst.entity)
    if inst.use_z then
        inst.min_z, inst.max_z = calc_min_max_z(inst.entity, inst.dimensions)
    end
end

local function update_nearby(player_pos)
    if BoundingBox.lastClosest then
        update_instance(BoundingBox.zones[BoundingBox.lastClosest.id])
        return
    end

    local results = query_nearby(player_pos)
    for i = 1, #results do
        update_instance(BoundingBox.zones[results[i].id])
    end
end

CreateThread(function()
    local playerPed = PlayerPedId()
    local playerPos = GetEntityCoords(playerPed)

    -- update entity info
    CreateThread(function()
        while true do
            update_nearby(playerPos)
            Wait(BoundingBox.lastClosest and 250 or 1000)
        end
    end)

    -- detect closest entity
    CreateThread(function()
        while true do
            playerPos = GetEntityCoords(playerPed)
            detect(playerPos)
            Wait(BoundingBox.lastClosest and 250 or 1000)
        end
    end)

    -- refresh grid in chunks
    CreateThread(function()
        local chunk_size = 100
        while true do
            local total = #BoundingBox.zones
            for start_i = 1, total, chunk_size do
                for i = start_i, math.min(start_i + chunk_size - 1, total) do
                    local inst = BoundingBox.zones[i]
                    if inst then
                        if DoesEntityExist(inst.entity) then
                            inst.pause = false
                            grid_entities:update(inst.grid_ref, GetEntityCoords(inst.entity))
                        else
                            inst.pause = true
                        end
                    end
                end
                Wait(100)
            end
            Wait(2000)
        end
    end)

    -- debug draw
    if Config.devMode and Config.debugPoly then
        local maxDrawDist = Config.debugMaxDrawDist or 150.0

        -- faces (for filled poly)
        local faces = {
            { 1, 2, 3, 4 }, { 5, 6, 7, 8 },                                -- top & bottom
            { 1, 2, 6, 5 }, { 2, 3, 7, 6 }, { 3, 4, 8, 7 }, { 4, 1, 5, 8 } -- sides
        }

        -- edges
        local edges = {
            { 1, 2 }, { 2, 3 }, { 3, 4 }, { 4, 1 },
            { 5, 6 }, { 6, 7 }, { 7, 8 }, { 8, 5 },
            { 1, 5 }, { 2, 6 }, { 3, 7 }, { 4, 8 }
        }

        local function is_on_screen(corners)
            for i = 1, #corners do
                local onScreen = World3dToScreen2d(corners[i].x, corners[i].y, corners[i].z)
                if onScreen then return true end
            end
            return false
        end

        local function draw_box(inst, playerPos)
            if not inst or not inst.position or not inst.rotation then return end

            local min, max, pos, heading = inst.dimensions[1], inst.dimensions[2], inst.position, inst.rotation
            local cos_h, sin_h = math_cos(math_rad(heading)), math_sin(math_rad(heading))

            -- cull by distance
            local dist = #(playerPos - pos)
            if dist > maxDrawDist then return end

            -- corners
            local offsets = {
                { min.x, min.y, min.z }, { max.x, min.y, min.z },
                { max.x, max.y, min.z }, { min.x, max.y, min.z },
                { min.x, min.y, max.z }, { max.x, min.y, max.z },
                { max.x, max.y, max.z }, { min.x, max.y, max.z }
            }

            local corners = {}
            for i, o in ipairs(offsets) do
                local rx, ry = o[1] * cos_h - o[2] * sin_h, o[1] * sin_h + o[2] * cos_h
                corners[i] = vec3(pos.x + rx, pos.y + ry, pos.z + o[3])
            end

            -- skip if not visible
            if not is_on_screen(corners) then return end

            -- base colors
            local faceR, faceG, faceB, faceA = 180, 180, 180, 50
            local edgeR, edgeG, edgeB, edgeA = 255, 0, 0, 255

            -- highlight if player inside
            local box = { min = pos + min, max = pos + max }
            if is_point_in_box(playerPos, box, inst.rotation) then
                edgeR, edgeG, edgeB = 0, 255, 0
            end

            -- draw filled faces
            for _, f in ipairs(faces) do
                local c1, c2, c3, c4 = corners[f[1]], corners[f[2]], corners[f[3]], corners[f[4]]
                DrawPoly(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, c3.x, c3.y, c3.z, faceR, faceG, faceB, faceA)
                DrawPoly(c1.x, c1.y, c1.z, c3.x, c3.y, c3.z, c4.x, c4.y, c4.z, faceR, faceG, faceB, faceA)
            end

            -- draw edges
            for _, e in ipairs(edges) do
                local c1, c2 = corners[e[1]], corners[e[2]]
                DrawLine(c1.x, c1.y, c1.z, c2.x, c2.y, c2.z, edgeR, edgeG, edgeB, edgeA)
            end
        end

        CreateThread(function()
            while true do
                for _, inst in pairs(BoundingBox.zones) do
                    if not inst.pause then
                        draw_box(inst, playerPos)
                    end
                end
                Wait(0)
            end
        end)
    end
end)

--#endregion ENTITYZONE
