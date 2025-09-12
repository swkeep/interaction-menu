local Util = Util
local StateManager = Util.StateManager()
local grid = Util.SpatialHashGrid:get('position')
local collectors = {}

GC = {
    marked = {},
    _pending = {},
    is_thread_active = false
}

local function _remove_by_value(array, value)
    for i = #array, 1, -1 do
        if array[i] == value then
            array[i] = array[#array]
            array[#array] = nil
            return true
        end
    end
    return false
end

local function _stable_remove_by_value(array, value)
    for i = 1, #array do
        if array[i] == value then
            table.remove(array, i)
            return true
        end
    end
    return false
end

local function _remove_from_list(array, value, preferStable)
    if preferStable then
        return _stable_remove_by_value(array, value)
    else
        return _remove_by_value(array, value) or _stable_remove_by_value(array, value)
    end
end

local function _remove_by_index(menuId, value, indexTable, idField)
    if not indexTable or not value or not idField then return false end
    local key = value[idField]
    if not key then return false end

    local list = indexTable[key]
    if not list then return false end

    if _remove_from_list(list, menuId, false) then
        if #list == 0 then
            indexTable[key] = nil
        end
        Container.data[menuId] = nil
        return true
    end
    return false
end

local function _safe_remove(menuId)
    if Container.data[menuId] then
        Container.data[menuId] = nil
        return true
    end
    return false
end

-- ===================== Collectors =====================

collectors.position = function(menuId, menu_instance)
    local pos = menu_instance.position
    local _, foundItem, cell = grid:isPositionOccupied({ x = pos.x, y = pos.y })
    if foundItem and foundItem.ids then
        local ids = foundItem.ids
        for index, value in ipairs(ids) do
            if value == menuId then
                table.remove(ids, index)
                break
            end
        end
        if #ids == 0 then grid:_raw_remove(cell.x, cell.y, cell.index) end
    else
        grid:remove(pos)
    end

    return _safe_remove(menuId)
end

collectors.zone = function(menuId, menu_instance)
    local zone = Container.zones[menuId]
    if zone then
        Container.zones[menuId] = nil
        if type(zone.destroy) == 'function' then
            pcall(zone.destroy, zone)
        end
        TriggerEvent("interactionMenu:client:gc:zone", menuId)
    end
    return _safe_remove(menuId)
end

collectors.entity = function(menuId, menu_instance)
    if menu_instance.entity and menu_instance.entity.handle and menu_instance.tracker == 'boundingBox' then
        pcall(function() BoundingBox.unwatch(menu_instance.entity.handle) end)
    end
    return _remove_by_index(menuId, menu_instance.entity, Container.indexes.entities, 'handle')
end

collectors.player = function(menuId, menu_instance)
    return _remove_by_index(menuId, menu_instance, Container.indexes.players, 'playerId')
end

collectors.model = function(menuId, menu_instance)
    return _remove_by_index(menuId, menu_instance, Container.indexes.models, 'model')
end

collectors.manual = function(menuId, menu_instance)
    for _, ev in pairs(menu_instance.manual_events) do
        pcall(function() RemoveEventHandler(ev) end)
    end
    return _safe_remove(menuId)
end

collectors.bone = function(menuId, menu_instance)
    if not menu_instance or not menu_instance.vehicle then return false end
    local vehicleHandle = menu_instance.vehicle.handle
    local vehicleBones = Container.indexes.bones[vehicleHandle]
    return _remove_by_index(menuId, menu_instance, vehicleBones, 'bone')
end

-- ===================== GC =====================

function GC._collect(id)
    if not id then return false end
    local menu_instance = Container.get(id)
    if not menu_instance then
        GC.marked[id] = nil
        Util.print_debug("GC.collect: no menu_instance for", id)
        return false
    end

    do
        local active = StateManager.get('active')
        if active then
            Interact:deleteMenu(id)
        end
    end

    local collector = collectors[menu_instance.type]
    if collector then
        pcall(collector, id, menu_instance)
    end

    -- Global index cleanup (bones/entities/zones/peds) -> fast removal
    do
        local t = menu_instance.type
        local globals = Container.indexes and Container.indexes.globals
        if globals and globals[t] then
            local list = globals[t]
            if _remove_from_list(list, id, false) then
                -- CleanNearbyObjects()
            end
        elseif globals and t == 'bones' and menu_instance.bone then
            local boneList = globals['bones'] and globals['bones'][menu_instance.bone]
            if boneList and _remove_from_list(boneList, id, false) then
                -- CleanNearbyObjects()
            end
        end
    end

    GC.marked[id] = nil
    Container.data[id] = nil
    Util.print_debug("GC.collect: finished collection for ", id)

    return true
end

local function find_menu_by_id(menus, id)
    for i, v in ipairs(menus) do
        if v.id == id then return i, v end
    end
end

function GC._remove_from_active_menus(id)
    if not (StateManager.get('active') and Container.current) then return false end
    local current = Container.current
    if not current.menus then return false end

    local idx = find_menu_by_id(current.menus, id)
    if not idx then return false end

    Interact:deleteMenu(id)
    Container.refresh()
    return true
end

function GC.flag(id)
    if not id then return end
    if not GC.marked[id] then
        local ts = GetGameTimer() / 1000
        GC.marked[id] = ts
        GC._remove_from_active_menus(id) -- with this it feel snappier
        table.insert(GC._pending, id)
        Container.total = math.max(0, (Container.total or 0) - 1)
        Util.print_debug("GC.flag:", id, ts)
    end
end

exports('remove', GC.flag)

function GC.isMarked(id) return GC.marked[id] ~= nil end

--- we call this if player has this menu active
--- if not an active thread will collect as soon as possible (when it's safe)
---@param arg any
---@return boolean
function GC.exec(arg)
    if not arg then return false end

    local menu_index = arg.menu_index
    local menus = arg.menus
    local id = arg.menu_id

    if menus and menu_index and menus[menu_index] then
        table.remove(menus, menu_index)
    end

    -- update UI only if visible
    if StateManager.get('active') then
        Interact:deleteMenu(id)
    end

    local ok = GC._collect(id)
    if ok then
        GC.marked[id] = nil
    end

    return ok
end

function GC._remove_by_invoking_resource(resource)
    if resource == GetCurrentResourceName() then return end

    for id, menu in pairs(Container.data) do
        if menu.metadata and menu.metadata.invokingResource == resource then
            GC.flag(id)
        end
    end
    StateManager.reset()
end

AddEventHandler('onResourceStop', GC._remove_by_invoking_resource)

function GC.collectAll()
    if #GC._pending == 0 then return end

    for i = #GC._pending, 1, -1 do
        local id = GC._pending[i]
        if GC.marked[id] then
            local ok = GC._collect(id)
            if ok then
                table.remove(GC._pending, i)
            end
        else
            table.remove(GC._pending, i)
        end
    end
end
