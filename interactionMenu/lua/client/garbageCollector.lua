local COLLECTOR_CONFIG = {
    INTERVAL = 1000 * 60
}

local StateManager = Util.StateManager()
local GarbageCollector = {}
local grid = Util.SpatialHashGrid:get('position')

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

local function removeMenuSimple(key)
    if Container.data[key] then
        Container.data[key] = nil
    end
end

function GarbageCollector.position(menuId, value)
    removeMenuSimple(menuId)
end

function GarbageCollector.zone(menuId, value)
    removeMenuSimple(menuId)
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

    -- remove zone and position triggers early
    if menuRef.type == 'zone' then
        local zone = Container.zones[id]
        Container.zones[id] = nil
        zone:destroy()
        TriggerEvent("interactionMenu:zoneTracker")
    elseif menuRef.type == 'position' then
        grid:remove(menuRef.position)
    elseif menuRef.type == 'entity' and menuRef.tracker == 'boundingBox' then
        EntityDetector.unwatch(menuRef.entity.handle)
    elseif menuRef.type == "manual" then
        for index, value in pairs(menuRef.manual_events) do
            -- #TODO: finish up the collector code
            RemoveEventHandler(value)
        end
    end

    if menuRef.type == "bones" or menuRef.type == "entities" or menuRef.type == "zones" or menuRef.type == 'peds' then
        if menuRef.type == 'bones' then
            for index, value in ipairs(Container.indexes.globals['bones'][menuRef.bone]) do
                if value == id then
                    table.remove(Container.indexes.globals['bones'][menuRef.bone], index)
                    CleanNearbyObjects()
                    break
                end
            end
        else
            for index, value in pairs(Container.indexes.globals[menuRef.type]) do
                if value == id then
                    table.remove(Container.indexes.globals[menuRef.type], index)
                    CleanNearbyObjects()
                    break
                end
            end
        end
    end

    menuRef.flags.deleted = true
    menuRef.deletedAt = GetGameTimer() / 1000
    Container.total = Container.total - 1
end

exports('remove', Container.remove)

function Container.removeByInvokingResource(i_r)
    for id, menu in pairs(Container.data) do
        if menu.metadata.invokingResource == i_r then
            Container.remove(id)
        end
    end

    StateManager.reset()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end

    Container.removeByInvokingResource(resource)
end)

-- Garbage collection thread
CreateThread(function()
    while true do
        Wait(COLLECTOR_CONFIG.INTERVAL)

        local currentTime = GetGameTimer() / 1000
        local chunkSize = 500
        local processed = 0

        for key, value in pairs(Container.data) do
            processed = processed + 1

            if value.flags.deleted and not value.deletedAt then
                value.deletedAt = GetGameTimer() / 1000
            end

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
