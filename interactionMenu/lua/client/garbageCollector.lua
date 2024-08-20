local COLLECTOR_CONFIG = {
    INTERVAL = 1000
}

local GarbageCollector = {}
local grid = Util.SpatialHashGrid:get('position')
local zone_grid = Util.SpatialHashGrid:get('zone')

-- Helper to remove menu data
local function removeMenuData(key, value, indexTable, idField)
    local menus = indexTable[value[idField]]
    if not menus then return end

    for i, menuId in ipairs(menus) do
        if menuId == value.id then
            table.remove(menus, i)
            if #menus == 0 then
                indexTable[value[idField]] = nil
            end
            Container.data[key] = nil
            break
        end
    end
end

function GarbageCollector.position(key, value)
    local menu = Container.data[key]
    if menu and menu.position then
        Container.data[key] = nil
    end
end

function GarbageCollector.zone(menuId, value)
    local menu = Container.data[menuId]
    if menu then
        Container.data[menuId] = nil
    end
end

function GarbageCollector.entity(key, value)
    removeMenuData(key, value, Container.indexes.entities, 'handle')
end

function GarbageCollector.player(key, value)
    removeMenuData(key, value, Container.indexes.players, 'playerId')
end

function GarbageCollector.model(key, value)
    removeMenuData(key, value, Container.indexes.models, 'model')
end

function GarbageCollector.bone(key, value)
    local vehicleBones = Container.indexes.bones[value.vehicle.handle]
    if vehicleBones then
        removeMenuData(key, value, vehicleBones, 'bone')
    end
end

function Container.remove(id)
    local menuRef = Container.get(id)
    if not menuRef then
        Util.print_debug('Could not find this menu')
        return
    end

    if menuRef.type == 'zone' then
        local zone = Container.zones[id]
        Container.zones[id] = nil
        zone:destroy()
    elseif menuRef.type == 'position' then
        grid:remove(menuRef.position)
    end

    menuRef.flags.deleted = true
    menuRef.deletedAt = GetGameTimer() / 1000
    Container.total = Container.total - 1
end

exports('remove', Container.remove)

-- Garbage collection thread
CreateThread(function()
    while true do
        Wait(COLLECTOR_CONFIG.INTERVAL)

        local currentTime = GetGameTimer() / 1000
        local chunkSize = 5000
        local processed = 0

        for key, value in pairs(Container.data) do
            processed = processed + 1

            -- Check and remove deleted items if they have passed the delay period
            if value.flags.deleted and (currentTime - value.deletedAt) > 6 then
                local collector = GarbageCollector[value.type]
                if collector then
                    collector(key, value)
                end
            end

            -- Pause between chunks to avoid overwhelming the game
            if processed >= chunkSize then
                processed = 0
                Wait(250)
            end
        end
    end
end)
