-- CONSTS
local A = assert
local TRACKER_HIT <const> = "hit"
local TRACKER_COLLISION <const> = "collision"

local state_manager = Util.StateManager()
local zone_grid = Util.SpatialHashGrid:new("zone", 100)
local near_zone = nil
local current_zone = nil
local zone_factory = {}
local TYPE_MAP = {
    sphere = { "circle", "circle_zone", "circlezone", "circlezone", "sphere" },
    box    = { "box", "box_zone", "boxzone", "rectangle" },
    poly   = { "poly", "poly_zone", "polyzone", "polyzone" },
    combo  = { "combo", "combo_zone", "combozone" },
}
local center_of_zones = {}
local zone_alphas = {}
local FADE_SPEED = 20.0
local MAX_ALPHA = 255
local MIN_ALPHA = 0

-- functions

local function build_type_alias_map()
    local m = {}
    for canon, variants in pairs(TYPE_MAP) do
        for _, v in ipairs(variants) do
            local cleaned = string.lower(v):gsub("[^%w]", "")
            m[cleaned] = canon
        end
    end

    -- canonical keys cleaned
    for k, _ in pairs(TYPE_MAP) do
        m[string.lower(k):gsub("[^%w]", "")] = k
    end
    return m
end

local TYPE_ALIAS_MAP = build_type_alias_map()

local function canonical_type(type_str)
    if type(type_str) ~= "string" then return nil end
    local cleaned = string.lower(type_str):gsub("[^%w]", "")
    return TYPE_ALIAS_MAP[cleaned]
end

local function is_vector_like(v)
    local t = type(v)
    if t == "vector3" or t == "vector4" then return true end
    if t == "table" then
        return type(v.x) == "number" and type(v.y) == "number" and type(v.z) == "number"
    end
    return false
end

local function assert_number_field(tbl, name, required)
    if required then
        A(type(tbl[name]) == "number", ("%s must be a number"):format(name))
    else
        A(tbl[name] == nil or type(tbl[name]) == "number", ("%s must be a number if provided"):format(name))
    end
end

local function to_snake_case_key(k)
    -- common simple camelCase -> snake_case conversion
    if type(k) ~= "string" then return k end
    -- replace capitals with _ + lower
    local s = k:gsub("([A-Z])", "_%1"):gsub("^_", ""):gsub("%s+", "_")
    s = s:gsub("%W", "_")
    s = s:lower()
    s = s:gsub("__+", "_")
    return s
end

local function normalize_zone_data(o)
    local normalized = {}
    for k, v in pairs(o) do
        local nk = to_snake_case_key(k)
        normalized[nk] = v
    end
    -- normalize type into canonical category (sphere, box, poly, combo)
    if normalized.type then
        local canon = canonical_type(normalized.type)
        if canon then
            -- keep original string but store canonical category for quick use
            normalized._category = canon
            -- also store canonical normalized type string if you want
            normalized.type = canon
        else
            -- try also using the snake_case form of provided type
            local alt = to_snake_case_key(normalized.type)
            local alt_canon = canonical_type(alt)
            if alt_canon then
                normalized._category = alt_canon
                normalized.type = alt_canon
            end
        end
    end
    return normalized
end

local function validate_zone(o)
    A(type(o) == "table", "Zone data must be a table")
    A(type(o.type) == "string", "Zone type must be a string")

    local category = o._category or canonical_type(o.type)
    A(category, "Unsupported zone type: " .. tostring(o.type))

    if category == "sphere" or category == "box" then
        A(o.position, "Position is required for zone type " .. tostring(o.type))
        A(is_vector_like(o.position), "Position must be a vector3/vector4 or table with numeric x,y,z")
    end

    if category == "sphere" then
        assert_number_field(o, "radius", true)
    elseif category == "box" then
        assert_number_field(o, "length", true)
        assert_number_field(o, "width", true)
        assert_number_field(o, "heading", false)
        assert_number_field(o, "min_z", false)
        assert_number_field(o, "max_z", false)
    elseif category == "poly" then
        A(type(o.points) == "table", "Points must be a table of coordinates")
        for i, p in ipairs(o.points) do
            A(type(p.x) == "number" and type(p.y) == "number" and type(p.z) == "number",
                ("Each point must have numeric x, y, z coordinates (point #%d)"):format(i))
        end
    elseif category == "combo" then
        A(type(o.zones) == "table", "Zones must be a table of zone definitions")
        for _, zone_data in ipairs(o.zones) do
            -- normalize nested zone_data as well before validation
            local normalized_child = normalize_zone_data(zone_data)
            validate_zone(normalized_child)
        end
    end
end

local function on_player_in(name)
    TriggerEvent('interactionMenu:client:zones:state_change', name, true)
end

local function on_player_out(name)
    TriggerEvent('interactionMenu:client:zones:state_change', name, false)
end

local function attach_handlers(zone, name, engine)
    if not zone then return end
    if engine == "ox_lib" then
        zone.onEnter = function() on_player_in(name) end
        zone.onExit  = function() on_player_out(name) end
        zone.name    = name
    elseif engine == "polyzone" then
        zone:onPlayerInOut(function(is_inside)
            if is_inside then
                on_player_in(name)
            else
                on_player_out(name)
            end
        end)
    end
end

local ox_lib_strategy = {
    create = function(o_raw)
        local o = normalize_zone_data(o_raw)
        A(lib, "ox_lib is not loaded. Uncomment '-- @ox_lib/init.lua' in fxmanifest.lua")
        validate_zone(o)

        local category = o._category or canonical_type(o.type)
        local zone

        if category == "sphere" then
            zone = lib.zones.sphere({
                coords = vec3(o.position.x, o.position.y, o.position.z),
                radius = o.radius or 2,
                debug  = o.debug_poly,
                inside = o.inside,
            })
        elseif category == "box" then
            o.min_z = o.min_z or 0
            o.max_z = o.max_z or 1
            local use_z = o.use_z or not o.max_z
            local size_z = use_z and o.position.z or math.abs(o.max_z - o.min_z)
            zone = lib.zones.box({
                coords   = vec3(o.position.x, o.position.y, o.position.z),
                size     = o.size or vec3(o.length, o.width, size_z),
                rotation = o.heading or 0,
                debug    = o.debug_poly,
                inside   = o.inside,
            })
        elseif category == "poly" then
            zone = lib.zones.poly({
                points    = o.points,
                thickness = o.thickness or 4,
                debug     = o.debug_poly,
                inside    = o.inside,
            })
        elseif category == "combo" then
            warn("Unsupported combo zone in ox_lib")
        end

        attach_handlers(zone, o.name, "ox_lib")
        return zone
    end
}

local polyzone_strategy = {
    create = function(o_raw)
        local tracker = o_raw.tracker
        local o = normalize_zone_data(o_raw)
        validate_zone(o)

        local category = o._category or canonical_type(o.type)
        local zone

        if category == "sphere" then
            A(CircleZone, "PolyZone CircleZone not loaded. Uncomment '@PolyZone/CircleZone.lua' in fxmanifest.lua")
            zone = CircleZone:Create(vec3(o.position.x, o.position.y, o.position.z), o.radius or 1.0, {
                name      = o.name,
                debugPoly = o.debug_poly,
                useZ      = o.use_z or false,
            })
        elseif category == "box" then
            A(BoxZone, "PolyZone BoxZone not loaded. Uncomment '@PolyZone/BoxZone.lua' in fxmanifest.lua")
            zone = BoxZone:Create(vec3(o.position.x, o.position.y, o.position.z), o.length or 1.0, o.width or 1.0, {
                name      = o.name,
                heading   = o.heading,
                debugPoly = o.debug_poly,
                minZ      = o.min_z,
                maxZ      = o.max_z,
            })
        elseif category == "poly" then
            A(PolyZone, "PolyZone not loaded. Uncomment '@PolyZone/client.lua' in fxmanifest.lua")
            zone = PolyZone:Create(o.points, {
                name      = o.name,
                minZ      = o.min_z,
                maxZ      = o.max_z,
                debugPoly = o.debug_poly,
            })
        elseif category == "combo" then
            A(ComboZone, "PolyZone ComboZone not loaded. Uncomment '@PolyZone/ComboZone.lua' in fxmanifest.lua")
            local zones = {}
            for _, zone_data in ipairs(o.zones) do
                local normalized_child = normalize_zone_data(zone_data)
                if normalized_child and normalized_child.type ~= "combo" then
                    table.insert(zones, zone_factory:create(normalized_child))
                end
            end
            zone = ComboZone:Create(zones, {
                name      = o.name,
                debugPoly = o.debug_poly,
            })
        end

        if tracker ~= "hit" then
            attach_handlers(zone, o.name, "polyzone")
        end
        return zone
    end
}

local none_strategy = {
    create = function(_) return nil end
}

zone_factory = {
    strategies = {
        ox_lib   = ox_lib_strategy,
        polyzone = polyzone_strategy,
        none     = none_strategy,
    },

    detect = function(self)
        if GetResourceState("ox_lib") == "started" and lib then
            Config.trigger_zone_script = "ox_lib"
        elseif GetResourceState("PolyZone") == "started" then
            Config.trigger_zone_script = "polyzone"
        else
            Config.trigger_zone_script = "none"
        end
    end,

    create = function(self, o)
        self:detect()
        local strategy = self.strategies[Config.trigger_zone_script] or none_strategy
        return strategy.create(o)
    end
}

local function can_create_zone()
    return GetResourceState("PolyZone") == "started" or (GetResourceState("ox_lib") == "started" and lib ~= nil)
end

local function is_point_inside_zone(zone, position)
    if not zone or not position then return false end

    -- PolyZone -> :isPointInside
    if zone.isPointInside then
        if type(zone.isPointInside) == "function" then
            local ok, res = pcall(function() return zone:isPointInside(position) end)
            return ok and res or false
        end
    end

    -- ox_lib -> contains
    if zone.contains then
        if type(zone.contains) == "function" then
            local ok, res = pcall(function() return zone:contains(position) end)
            return ok and res or false
        end
    end

    return false
end

local function update_zone_alpha(zone_id, isActive)
    local current_alpha = zone_alphas[zone_id] or MAX_ALPHA

    if isActive then
        current_alpha = math.max(MIN_ALPHA, current_alpha - FADE_SPEED)
    else
        current_alpha = math.min(MAX_ALPHA, current_alpha + FADE_SPEED)
    end

    zone_alphas[zone_id] = current_alpha
    return math.floor(current_alpha)
end

-- bindings

---@param user_data UserCreateData
---@param instance BoneMenuInstance
local function handle_create(user_data, instance)
    local id = instance.id
    if not can_create_zone() then
        warn("Could not find `PolyZone`. Make sure it is started before interactionMenu.")
        return
    end

    instance.type = "zone"
    instance.position = {
        x = user_data.position.x,
        y = user_data.position.y,
        z = user_data.position.z,
        id = id
    }
    instance.rotation = user_data.rotation
    instance.zone = user_data.zone
    instance.scale = user_data.scale
    instance.tracker = user_data.tracker or TRACKER_COLLISION -- (presence or collision), hit

    if instance.zone then
        user_data.zone.name = id
        user_data.zone.tracker = instance.tracker
        Container.zones[id] = zone_factory:create(user_data.zone)

        if instance.tracker == TRACKER_HIT and Container.zones[id] then
            Container.zones[id].tracker = instance.tracker
        end

        if not Container.zones[id] then return end
    end

    zone_grid:insert(instance.position)
end

local function handle_detect(data)
    if near_zone or current_zone then return FEATURES_LIST["TRIGGER_ZONE"] end
    if not data.ray_hit_position then return end
    local ray_hit_position = data.ray_hit_position

    for _, zone in pairs(Container.zones) do
        if zone.tracker == TRACKER_HIT and is_point_inside_zone(zone, ray_hit_position) then
            current_zone = zone.name
            return FEATURES_LIST["TRIGGER_ZONE"]
        end
    end
end

local function handle_detected()
    local selected_zone = near_zone or current_zone
    if not selected_zone then return end

    state_manager.set({
        id = selected_zone,
        menuType = FEATURES_LIST.TRIGGER_ZONE
    })
end

local function handle_render(render_data)
    local current_menu_id = render_data.current_menu_id
    local data = Container.getMenu(nil, nil, current_menu_id)
    if not data then return end
    if not data.position then return end

    local scaleform = Interact:getScaleform()
    local metadata = Container.constructMetadata(data)
    local position = data.position
    local rotation = data.rotation
    local validate_slow = nil

    if data.tracker == TRACKER_HIT then
        validate_slow = function()
            local hit, target_entity, ray_hit_position = Util.rayCast(511, PlayerPedId())
            return is_point_inside_zone(Container.zones[current_menu_id], ray_hit_position)
        end
    end

    Render.generic(data, metadata, {
        onEnter = function()
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
            return state_manager.get("id") == current_menu_id
        end,
        validateSlow = validate_slow,
        onExit = function()
            if data.tracker == TRACKER_HIT then
                current_zone = nil
                state_manager.reset()
            else
                state_manager.reset()
            end
        end
    })
end

local function handle_zone_tracker(zone_name, state)
    if GetInvokingResource() ~= GetCurrentResourceName() then return end

    if zone_name and state then
        near_zone = zone_name
    else
        near_zone = nil
    end
end

local function handle_gc_zone(menu_id)
    if GetInvokingResource() ~= GetCurrentResourceName() then return end

    if near_zone == menu_id then
        near_zone = nil
    elseif current_zone == menu_id then
        current_zone = nil
    end
end

local function handle_find_indicator()
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
end

local function handle_render_indicator(data)
    local player_position = data.player_position
    for id, value in pairs(center_of_zones) do
        local isActive = id == near_zone or id == current_zone
        local alpha = update_zone_alpha(id, isActive)
        if alpha > 0 then
            DrawIndicator(value.coords, player_position, value.icon, alpha)
        end
    end
end

Features.on("Create", handle_create, { id = "TRIGGER_ZONE" })
Features.on("Detect", handle_detect, { id = FEATURES_LIST["TRIGGER_ZONE"] })
Features.on("Detected", handle_detected, { id = FEATURES_LIST["TRIGGER_ZONE"] })
Features.on("Render", handle_render, { id = FEATURES_LIST["TRIGGER_ZONE"] })
Features.on("FindIndicator", handle_find_indicator, { id = FEATURES_LIST["TRIGGER_ZONE"] })
Features.on("RenderIndicator", handle_render_indicator, { id = FEATURES_LIST["TRIGGER_ZONE"] })

AddEventHandler("interactionMenu:client:zones:state_change", handle_zone_tracker)
AddEventHandler("interactionMenu:client:gc:zone", handle_gc_zone)
