--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local interactionAudio = Config.interactionAudio or {
    mouseWheel = {
        audioName = 'NAV_UP_DOWN',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    onSelect = {
        audioName = 'SELECT',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    }
}

local IsPedAPlayer = IsPedAPlayer
local GetPlayerServerId = GetPlayerServerId
local NetworkGetPlayerIndexFromPed = NetworkGetPlayerIndexFromPed
local SpatialHashGrid = Util.SpatialHashGrid
local grid = SpatialHashGrid:new('position', 100)
local zone_grid = SpatialHashGrid:new('zone', 100)
local StateManager = Util.StateManager()
local previous_daytime = false

-- enum: used in difference between OBJECTs, PEDs, VEHICLEs
local set = { "peds", "vehicles", "objects" }
EntityTypes = Util.ENUM { 'PED', 'VEHICLE', 'OBJECT' }

-- #TODO: make a err handler
local dupe_menu = 'Duplicate menu detected removing the old menu | invokingResource: %s -> MenuId: %s'

-- class: menu container
-- managing menus
Container = {
    total = 0,
    data = {},
    zones = {},
    indexes = {
        models = {},
        entities = {},
        netIds = {},
        players = {},
        bones = {},
        globals = {
            bones = {},
            objects = {},
            entities = {},
            peds = {},
            players = {},
            vehicles = {},
            zones = {}
        }
    },
    runningInteractions = {}
}

local function canCreateZone()
    return GetResourceState('PolyZone') == 'started'
end

--- Build interaction table for named interactions (canInteract, onSeen, onExit)
---@param data table 'raw menu data'
---@param interactions table 'interactions reference table to add interactions into it'
---@param key string 'interaction name (canInteract, onSeen, onExit)'
local function buildInteraction(data, interactions, key)
    if not data.extra or not data.extra[key] then return end

    interactions[key] = {
        [key] = true,
        func = data.extra[key]
    }
end

--- build interaction data to find interaction the menu
local function constructInteractionData(option, instance, index, formatted)
    local interaction = nil
    local interactionType

    if option.action or option.onSelect then
        interaction = {
            action = true,
            func = option.action or option.onSelect
        }
        interactionType = 'action'
    elseif option.event then
        interaction = {
            event = true,
            type = option.event.type or 'client',
            payload = option.event.payload,
            name = option.event.name
        }
        interactionType = 'event'
    elseif option.command then
        interaction = {
            event = true,
            type = 'command',
            name = option.command
        }
        -- #TODO: add proper `command` type
        interactionType = 'event'
    elseif option.update then
        interaction = {
            update = true,
            func = option.update
        }
        interactionType = 'update'
    elseif option.bind then
        interaction = {
            bind = true,
            func = option.bind
        }
        interactionType = 'bind'
    end

    if option.canInteract then
        local canInteract = {
            canInteract = true,
            func = option.canInteract
        }
        instance.interactions['canInteract|' .. index] = canInteract
        formatted.flags['canInteract'] = true
    end

    if interaction and interactionType then
        instance.interactions[index] = interaction
        formatted.flags[interactionType] = true
    end
end

---@class ProgressOption
---@field type string 'info - success - warning - error'
---@field value number "0 - 100%"
---@field percent boolean "Whether to show value as percent"

---@class PictureOption
---@field url string
---@field opacity? number "0 - 100%"
---@field width? number
---@field height? number

---@class VideoOption
---@field url string
---@field currentTime? number
---@field autoplay? boolean
---@field volume? number
---@field loop? boolean
---@field opacity? number

---@class InteractionOption
---@field id number 'id (option index)'
---@field vid number 'virtual id (option index in the current menu)'
---@field label string  "A label"
---@field picture? PictureOption
---@field video? VideoOption
---@field style? string "Style information"
---@field progress? ProgressOption
---@field icon? string "Icon name"
---@field dynamic? boolean "Whether the option's value is dynamically handled"
---@field disable boolean "Whether the option is disabled"
---@field action? function "Function to execute when the option is selected"
---@field event? string "Event name to trigger when the option is selected"
---@field hide boolean "Indicates whether the option should be hidden"

local function transformRestrictions(t)
    if not Bridge.active then return end
    if not t then return end
    if type(t) == 'string' then t = { t } end
    local transformed = {}

    for index, name in pairs(t) do
        if type(name) == 'string' then
            transformed[name] = {}
        elseif type(name) == 'table' then
            transformed[index] = {}
            for key, grade in pairs(name) do
                transformed[index][grade] = true
            end
        end
    end

    return transformed
end

local function buildOption(data, instance)
    for i, option in ipairs(data.options or {}) do
        local formatted = {
            -- visual information
            label = option.label,
            badge = option.badge,
            picture = option.picture,
            video = option.video,
            audio = option.audio,
            style = option.style,
            progress = option.progress,
            icon = option.icon,
            item = option.item,
            job = option.job and transformRestrictions(option.job),
            gang = option.gang and transformRestrictions(option.gang),

            flags = {
                dynamic = option.dynamic,
                disable = false,
                action = nil,
                event = nil,
                hide = option.hide or false,
                subMenu = option.subMenu or false,
            }
        }

        constructInteractionData(option, instance, i, formatted)
        instance.options[i] = formatted
    end
end

--- now that's a name to love,
--- organize menu instances for efficient access
---@param instance any
local function classifyMenuInstance(instance)
    local entity = instance.entity and instance.entity.handle
    local model = instance.model or instance.entity and instance.entity.model
    local bone = instance.bone
    local indexes = Container.indexes

    if bone and instance.vehicle then
        local bones = indexes.bones
        entity = instance.vehicle and instance.vehicle.handle
        model = instance.model or instance.vehicle and instance.vehicle.model

        bones[entity] = bones[entity] or {}
        bones[entity][bone] = bones[entity][bone] or {}

        table.insert(bones[entity][bone], instance.id)
    elseif model and entity then
        local entities = indexes.entities
        entities[entity] = entities[entity] or {}

        table.insert(entities[entity], instance.id)
    elseif model and not entity then
        local models = indexes.models
        models[model] = models[model] or {}

        table.insert(models[model], instance.id)
    elseif instance.type == 'netId' then
        local netIds = indexes.netIds
        local netId = instance.netId
        netIds[netId] = netIds[netId] or {}

        table.insert(netIds[netId], instance.id)
    elseif instance.player then
        local players = indexes.players
        players[instance.player] = players[instance.player] or {}

        table.insert(players[instance.player], instance.id)
    end
end

function Container.create(t)
    local invokingResource = GetInvokingResource() or 'interactionMenu'
    local id = t.id or Util.createUniqueId(Container.data)
    if Container.data[id] then
        warn(dupe_menu:format(invokingResource, id))
        Container.remove(id)
    end

    local instance = {
        id = id,
        type = nil,
        theme = t.theme,
        glow = t.glow,
        width = t.width,
        extra = t.extra or {},
        indicator = t.indicator,
        icon = t.icon,
        interactions = {},
        options = {},
        metadata = {
            invokingResource = invokingResource,
            offset = t.offset,
            maxDistance = t.maxDistance or 2
        },
        tracker = t.tracker or 'raycast',
        schemaType = t.schemaType or 'normal',
        flags = {
            deleted = false,
            disable = false,
            hide = false,
            suppressGlobals = t.suppressGlobals and true or false,
            static = t.static and true or false,
            alternativeMetadata = t.alternativeMetadata or false
        }
    }

    if t.position and not t.zone then
        instance.type = 'position'
        instance.position = { x = t.position.x, y = t.position.y, z = t.position.z, id = id, maxDistance = t.maxDistance }
        instance.rotation = t.rotation

        grid:insert(instance.position)
    elseif t.player then
        if type(t.player) ~= 'number' then
            warn('Player id must a integer value')
            return
        end
        instance.type = 'player'
        instance.player = t.player
    elseif t.entity then
        if not DoesEntityExist(t.entity) then
            local message = (
                "Menu creation failed:\n - Entity does not exist: %s\n - Invoking resource: %s"
            ):format(t.entity, instance.metadata.invokingResource)

            warn(message)
            return
        end

        instance.type = 'entity'
        instance.entity = {
            handle = t.entity,
            networked = NetworkGetEntityIsNetworked(t.entity) == 1,
            type = EntityTypes[GetEntityType(t.entity)],
            model = t.model or GetEntityModel(t.entity)
        }

        if instance.entity.networked then
            instance.entity.netId = NetworkGetNetworkIdFromEntity(t.entity)
        end

        if instance.tracker == 'boundingBox' then
            EntityDetector.watch(t.entity, {
                name = t.entity,
                useZ = true,
                dimensions = t.dimensions or { vec3(-1, -1, -1), vec3(1, 1, 1) }
            })
        end
    elseif t.model then
        instance.type = 'model'
        instance.model = t.model
    elseif t.netId then
        instance.type = 'netId'
        instance.netId = t.netId
    elseif t.bone then
        instance.type = 'bone'
        instance.bone = t.bone

        if t.vehicle then
            instance.vehicle = {
                handle = t.vehicle,
                networked = NetworkGetEntityIsNetworked(t.vehicle) == 1,
                type = EntityTypes[GetEntityType(t.vehicle)],
                model = t.model or GetEntityModel(t.vehicle)
            }

            if instance.vehicle.networked then
                instance.vehicle.netId = NetworkGetNetworkIdFromEntity(t.vehicle)
            end
        end
    elseif t.zone and t.position then
        if canCreateZone() then
            instance.type = 'zone'
            instance.position = {
                x = t.position.x,
                y = t.position.y,
                z = t.position.z,
                id = id
            }

            instance.rotation = t.rotation
            instance.zone = t.zone
            instance.scale = t.scale

            if instance.zone then
                t.zone.name = id
                Container.zones[id] = Util.addZone(t.zone)
                if not Container.zones[id] then
                    return
                end
            end
            zone_grid:insert(instance.position)
        else
            warn('Could not find `PolyZone`. Make sure it is started before interactionMenu.')
        end
    else
        warn('Could not determine menu type (failed to create interaction)')
        return
    end

    buildOption(t, instance)
    buildInteraction(t, instance.interactions, "onTrigger")
    buildInteraction(t, instance.interactions, "onSeen")
    buildInteraction(t, instance.interactions, "onExit")
    classifyMenuInstance(instance)

    Container.total = Container.total + 1
    Container.data[id] = instance
    return id
end

exports('create', Container.create)
exports('Create', Container.create)

function Container.createGlobal(t)
    local invokingResource = GetInvokingResource() or 'interactionMenu'
    local id = t.id or Util.createUniqueId(Container.data)
    if Container.data[id] then
        warn(dupe_menu:format(invokingResource, id))
        Container.remove(id)
    end

    local instance = {
        id = id,
        type = t.type,
        bone = t.bone,
        theme = t.theme,
        glow = t.glow,
        width = t.width,
        extra = t.extra or {},
        indicator = t.indicator,
        interactions = {},
        options = {},
        schemaType = t.schemaType or 'normal',
        metadata = {
            invokingResource = invokingResource,
            offset = t.offset,
            maxDistance = t.maxDistance or 2
        },
        flags = {
            deleted = false,
            disable = false,
            hide = false
        }
    }

    buildOption(t, instance)
    buildInteraction(t, instance.interactions, "onTrigger")
    buildInteraction(t, instance.interactions, "onSeen")
    buildInteraction(t, instance.interactions, "onExit")

    Container.data[id] = instance
    -- index global interaction
    if Container.indexes.globals[instance.type] and instance.type ~= 'bones' then
        table.insert(Container.indexes.globals[instance.type], id)
    elseif instance.type == 'bones' then
        if not instance.bone then
            warn('When using the global menu on bones, make sure to define the `bone`.')
            local s = [[exports["interactionMenu"]::createGlobal {
    type = "bones",
    bone = "platelight", -- <- here
    offset = vec3(0, 0, 0),]]
            print(s)
            return
        end
        Container.indexes.globals['bones'][instance.bone] = Container.indexes.globals['bones'][instance.bone] or {}
        table.insert(Container.indexes.globals['bones'][instance.bone], id)
    end

    return id
end

exports('CreateGlobal', Container.createGlobal)
exports('createGlobal', Container.createGlobal)

---comment
---@param entity any
---@return number "closestVehicleBone"
---@return unknown "closestBoneName"
---@return number "boneDistance"
function Container.boneCheck(entity)
    -- it's safer to use it only in vehicles
    if GetEntityType(entity) ~= 2 then
        return nil, nil, nil
    end

    local bones = Container.indexes.bones[entity] or Container.indexes.globals.bones
    local hitPosition = StateManager.get('hitPosition')

    if bones and hitPosition then
        local closestVehicleBone, closestBoneName, boneDistance = 0, false, 0

        closestVehicleBone, closestBoneName, boneDistance = Util.getClosestVehicleBone(hitPosition, entity,
            bones)

        if boneDistance < 0.65 then
            return closestVehicleBone, closestBoneName, boneDistance
        end
    end
end

--- assigns an id to a menu container based on its properties
---@param container any
---@param bones any
---@param closestBoneName any
---@param closestBoneId any
---@param model any
---@param entity any
---@param menuId any
---@return nil
local function assignId(container, bones, closestBoneName, closestBoneId, model, entity, menuId)
    local id

    if bones and closestBoneName then
        id = entity .. '|' .. closestBoneId
    elseif model and entity then
        id = model .. '|' .. entity
    elseif model and not entity then
        id = model
    elseif menuId then
        id = menuId
    end

    container.id = id
end

local function mergeGlobals(combinedIds, entity, model, closestBoneName)
    local entityType = GetEntityType(entity)
    local isPlayer = entityType == 1 and IsPedAPlayer(entity)

    if not entityType or entityType == 0 then return {} end
    local globals = Container.indexes.globals
    -- add globals on entities
    if next(globals.entities) then
        Util.table_merge(combinedIds, globals.entities or {})
    end

    -- add globals on, peds vehicles and objects
    local res = next(globals[set[entityType]])
    if res then
        Util.table_merge(combinedIds, globals[set[entityType]] or {})
    end

    if isPlayer and globals['players'] and next(globals['players']) then
        Util.table_merge(combinedIds, globals['players'] or {})
    end

    -- add globals on bones
    if closestBoneName then
        Util.table_merge(combinedIds, globals.bones[closestBoneName] or {})
    end

    -- on model and entity
    Util.table_merge(combinedIds, Container.indexes.models[model] or {})
    Util.table_merge(combinedIds, Container.indexes.entities[entity] or {})

    return combinedIds
end

local function populateMenus(container, combinedIds, id, bones, closestBoneName, closestBoneId, model, entity, menuId)
    local row_counter = 1

    for _, menu_id in ipairs(combinedIds) do
        local data = Container.data[menu_id]
        local deleted = data.flags.deleted

        if data and not deleted then
            local index = #container.menus + 1
            container.type = data.type and data.type or container.type
            container.offset = data.metadata and data.metadata.offset or container.offset
            container.indicator = data.indicator and data.indicator or container.indicator
            container.theme = data.theme and data.theme or container.theme
            container.glow = data.glow and data.glow or container.glow
            container.width = data.width and data.width or container.width
            container.maxDistance = data.metadata and data.metadata.maxDistance
            container.static = data.flags and data.flags.static
            container.zone = data.zone
            container.position = data.position and data.position or container.position
            container.rotation = data.rotation
            container.icon = data.icon
            container.scale = data.scale

            if data.flags.suppressGlobals then
                container.selected = {}
                container.menus = {}
                index = 1
                row_counter = 1
            end

            for optionIndex, option in ipairs(data.options) do
                option.id = optionIndex
                option.vid = row_counter
                container.selected[row_counter] = false

                row_counter = row_counter + 1
            end

            container.menus[index] = {
                id = menu_id,
                flags = data.flags,
                options = data.options,
                metadata = data.metadata
            }
        end
    end

    assignId(container, bones, closestBoneName, closestBoneId, model, entity, menuId)

    return container
end

local function IdentifyPlayerServerId(entityType, entity)
    return entityType == 1 and IsPedAPlayer(entity) and GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
end

local function isPedAPlayer(entityType, entity)
    return entityType == 1 and IsPedAPlayer(entity)
end

function Container.getMenu(model, entity, menuId)
    local is_deleted = false
    if menuId then
        is_deleted = Container.isDeleted(menuId)
        if is_deleted then return end
    end

    local id
    local combinedIds = {}
    local container = {
        id       = id, -- value is set in setId function
        menus    = {},
        selected = {},
        glow     = false,
        width    = 'fit-content',
        theme    = 'default'
    }

    local closestBoneId, closestBoneName = Container.boneCheck(entity)

    -- global priority
    if entity then
        combinedIds = mergeGlobals(combinedIds, entity, model, closestBoneName)
    else
        -- globals for zones
        if menuId then
            local menuRef = Container.get(menuId)
            if menuRef.type == 'zone' then
                combinedIds = Util.table_merge(combinedIds, Container.indexes.globals.zones or {})
            end
        end
        Util.table_merge(combinedIds, Container.indexes.models[model] or {})

        -- we're passsing menuId for position based menus
        if menuId then
            combinedIds[#combinedIds + 1] = menuId
        end
    end

    local playerId = IdentifyPlayerServerId(GetEntityType(entity), entity)

    if playerId then
        Util.table_merge(combinedIds, Container.indexes.players[playerId] or {})
    end

    local networked = NetworkGetEntityIsNetworked(entity)
    local netId

    if networked then
        netId = NetworkGetNetworkIdFromEntity(entity)
        Util.table_merge(combinedIds, Container.indexes.netIds[netId] or {})
    end

    -- bone
    local bones = Container.indexes.bones[entity]
    if bones and closestBoneName then
        Util.table_merge(combinedIds, Container.indexes.bones[entity][closestBoneName] or {})
    end

    container = populateMenus(container, combinedIds, id, bones, closestBoneName, closestBoneId, model, entity, menuId)

    return container, { model, entity, closestBoneId }
end

local function globalsExistsCheck(entity, entityType)
    if not entityType or entityType == 0 then return false end
    local globals = Container.indexes.globals
    local specificGlobals = globals[set[entityType]]
    local isPlayer = isPedAPlayer(entityType, entity)

    if isPlayer and globals['players'] and next(globals['players']) then
        return true
    end

    if globals.entities and next(globals.entities) then
        return true
    end

    if entityType == 2 and (globals.bones and next(globals.bones)) then
        return true
    end

    if specificGlobals and next(specificGlobals) then
        return true
    end

    return false
end

local entitiesIndex = Container.indexes.entities
local modelsIndex = Container.indexes.models
local playersIndex = Container.indexes.players
local netIdsIndex = Container.indexes.netIds
local globalsIndex = Container.indexes.globals
local bonesIndex = Container.indexes.bones

function Container.getMenuType(t)
    local model = t.model
    local entity = t.entity
    local entityType = t.entityType

    local playerId = IdentifyPlayerServerId(entityType, entity)
    local isNetworked = NetworkGetEntityIsNetworked(entity)
    local netId = isNetworked and NetworkGetNetworkIdFromEntity(entity) or nil

    -- ON_ZONE
    if t.zone then
        return MenuTypes['ON_ZONE']
    end

    -- ON_POSITION
    if t.closestPoint and next(t.closestPoint) then
        return MenuTypes['ON_POSITION']
    end

    -- ON_ENTITY
    local isEntityIndexed = false
    local hasGlobalEntry = globalsExistsCheck(entity, entityType)

    if entityType == 1 then
        -- PED
        -- ON_ENTITY -> ON_PED -> normal
        -- ON_ENTITY -> ON_PED -> player
        -- ON_ENTITY -> ON_PED -> netId
        isEntityIndexed = modelsIndex[model] or entitiesIndex[entity] or playersIndex[playerId] or netIdsIndex[netId]
        if isEntityIndexed or hasGlobalEntry then
            return MenuTypes['ON_ENTITY']
        end
    elseif entityType == 2 then
        -- VEHICLE
        -- ON_ENTITY -> ON_VEHICLE -> normal
        -- ON_ENTITY -> ON_VEHICLE -> bone
        -- ON_ENTITY -> ON_VEHICLE -> netId
        isEntityIndexed = modelsIndex[model] or entitiesIndex[entity] or netIdsIndex[netId]
        if isEntityIndexed or hasGlobalEntry then
            return MenuTypes['ON_ENTITY']
        else
            local _, closestBoneName = Container.boneCheck(entity)

            if bonesIndex[entity] and bonesIndex[entity][closestBoneName] then
                return MenuTypes['ON_ENTITY']
            end
        end
    elseif entityType == 3 then
        -- OBJECT
        -- ON_ENTITY -> ON_OBJECT -> normal
        -- ON_ENTITY -> ON_OBJECT -> netId
        isEntityIndexed = modelsIndex[model] or entitiesIndex[entity] or netIdsIndex[netId]
        if isEntityIndexed or hasGlobalEntry then
            return MenuTypes['ON_ENTITY']
        end
    end

    return MenuTypes['DISABLED']
end

function Container.get(id)
    return Container.data[id]
end

function Container.count()
    return Container.total
end

function Container.isDeleted(id)
    local menuRef = Container.get(id)
    if not menuRef then
        Util.print_debug('Could not find this menu')
        return true
    end

    return menuRef.flags and menuRef.flags.deleted
end

function Container.triggerInteraction(menuId, optionId, ...)
    if not Container.data[menuId] or not Container.data[menuId].interactions[optionId] then return end
    local func = Container.data[menuId].interactions[optionId].func
    if not func or type(func) ~= 'function' then return end
    return func(...)
end

local function isOptionValid(option)
    return not option.flags.hide and (option.flags.action or option.flags.event)
end

local function collectValidOptions(menuData, sortCon)
    local validOptions = {}

    for _, menu in ipairs(menuData.menus) do
        if not menu.flags.deleted then
            for _, option in ipairs(menu.options) do
                if isOptionValid(option) then
                    option.menu_id = menu.id
                    validOptions[#validOptions + 1] = option
                end
            end
        end
    end

    if sortCon then
        table.sort(validOptions, sortCon) -- sort by `vid`
    end

    return validOptions
end

local function hasValidMenuOption(menuData)
    local validOptions = collectValidOptions(menuData)
    return #validOptions > 0
end

-- Returns the first valid option
local function firstValidOption(menuData)
    local validOptions = collectValidOptions(menuData)
    return validOptions[1]
end

-- Returns the last valid option
local function lastValidOption(menuData)
    local validOptions = collectValidOptions(menuData)
    return validOptions[#validOptions]
end

--- scrolls through the valid options based on the wheel direction
---@param wheelDirection boolean
---@param menus any
---@param selected any
---@return number
---@return number
local function navigateMenu(wheelDirection, menus, selected)
    local validOptions = collectValidOptions({ menus = menus }, function(a, b) return a.vid < b.vid end)
    local validOptionCount = #validOptions
    -- no valid options (if this happens something is wrong!)
    if validOptionCount == 0 then return 1, 0 end
    -- find the `current selected index` and its `position`
    local currentIndex = nil
    for i, option in ipairs(validOptions) do
        if selected[option.vid] then
            currentIndex = i
            break
        end
    end

    -- default to first valid option if current selection is not found
    if currentIndex == nil then return validOptions[1].vid, validOptionCount end

    -- next index based on the scroll direction
    if wheelDirection then
        currentIndex = (currentIndex % validOptionCount) + 1     -- Go down
    else
        currentIndex = (currentIndex - 2) % validOptionCount + 1 -- Go up
    end

    return validOptions[currentIndex].vid, validOptionCount
end

local function updateSelectedItem(menus, selected, nextSelectedIndex)
    for _, menu in ipairs(menus) do
        for _, option in ipairs(menu.options) do
            selected[option.vid] = (option.vid == nextSelectedIndex)
        end
    end
end

function Container.changeMenuItem(scaleform, menuData, wheelDirection)
    if not hasValidMenuOption(menuData) then return end

    local selected = menuData.selected
    local menus = menuData.menus
    -- Ignore if list is empty, selected is not present, or menus are absent
    if not selected or not menus or not next(menus) then
        return
    end

    local nextSelectedIndex, validOptionCount = navigateMenu(wheelDirection, menus, selected)
    updateSelectedItem(menus, selected, nextSelectedIndex)

    if validOptionCount > 1 then
        PlaySoundFrontend(-1, interactionAudio.mouseWheel.audioName, interactionAudio.mouseWheel.audioRef, true)
    end
    scaleform.send("interactionMenu:menu:selectedUpdate", nextSelectedIndex)
end

local function findSelectedOption(menuData, selected)
    local validOptions = collectValidOptions(menuData, function(a, b)
        return a.vid < b.vid
    end)

    for _, option in pairs(validOptions) do
        if not option.hide and selected[option.vid] then
            return option.menu_id, option.id
        end
    end
end

--- generate metadata for triggers
---@param t table 'menuData (menu container)'
---@return table 'metadata'
function Container.constructMetadata(t)
    local metadata = {
        entity = nil,
        distance = StateManager.get('playerDistance'),
        coords = StateManager.get('playerPosition'),
        name = t.id,
        bone = nil
    }

    if t.type == 'entity' or t.type == 'model' or t.type == 'peds' then
        metadata.entity = t.entity
    elseif t.type == 'zone' then
        local pos = t.position
        pos = vec3(pos.x, pos.y, pos.z)
        metadata.distance = #(metadata.coords - pos)
    elseif t.type == 'bone' then
        metadata.entity = t.entity
        metadata.bone = t.boneId
    end

    return metadata
end

---@param params table
local function processData(params)
    local schemaType = params.schemaType
    local triggerType = params.triggerType
    local interaction = params.interaction
    local menuData = params.menuData
    local metadata = params.metadata
    local cb = params.cb

    local data, try_unpack

    if schemaType == "normal" then
        if triggerType == 'action' then
            data = {
                [1] = menuData.entity,
                [2] = menuData.distance,
                [3] = menuData.coords,
                [4] = menuData.name,
                [5] = menuData.bone
            }
            try_unpack = true
        elseif triggerType == 'event' then
            data = {
                interaction.payload or {},
                {
                    ["entity"] = menuData.entity,
                    ["distance"] = menuData.distance,
                    ["coords"] = menuData.coords,
                    ["name"] = menuData.name,
                    ["bone"] = menuData.bone
                }
            }
            try_unpack = true
        end
    elseif schemaType == "qbtarget" then
        if triggerType == 'action' then
            data = menuData.entity
            try_unpack = false
        elseif triggerType == 'event' then
            data = {
                entity = menuData.entity and menuData.entity,
                coords = menuData.coords,
                zone = menuData.zone,
                distance = menuData.distance
            }
            if interaction.payload then
                for key, value in pairs(interaction.payload) do
                    data[key] = value
                end
            end
            try_unpack = false
        end
    else
        error("Unsupported schema type: " .. tostring(schemaType))
    end

    if try_unpack then
        cb(table.unpack(data))
    else
        cb(data)
    end
end

function Container.keyPress(menuData)
    local metadata = Container.constructMetadata(menuData)

    for index, value in ipairs(menuData.menus) do
        Container.triggerInteraction(value.id, 'onTrigger', metadata)
    end

    local menuId, selectedOption = findSelectedOption(menuData, menuData.selected)
    if not selectedOption then return end
    local menuOriginalData = Container.get(menuId)
    local interaction = menuOriginalData.interactions[selectedOption]
    local schemaType = menuOriginalData.schemaType

    if interaction.action then
        if not Container.runningInteractions[interaction.func] then
            Container.runningInteractions[interaction.func] = true
            PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)

            CreateThread(function()
                if menuData.type == 'zone' then
                    processData {
                        schemaType = schemaType,
                        triggerType = 'zone',
                        interaction = interaction,
                        menuData = menuData,
                        metadata = metadata,
                        cb = function(...)
                            local success, result
                            success, result = pcall(interaction.func, ...)
                        end
                    }
                else
                    processData {
                        schemaType = schemaType,
                        triggerType = 'action',
                        interaction = interaction,
                        menuData = menuData,
                        metadata = metadata,
                        cb = function(...)
                            local success, result
                            success, result = pcall(interaction.func, ...)
                        end
                    }
                end

                Container.runningInteractions[interaction.func] = nil
            end)
        else
            Util.print_debug("Function is already running, ignoring additional calls to prevent spam.")
        end
    elseif interaction.event or interaction.command then
        PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)

        processData {
            schemaType = schemaType,
            triggerType = 'event',
            interaction = interaction,
            menuData = menuData,
            metadata = metadata,
            cb = function(...)
                if not interaction.name then
                    warn("event property doesn't have name attached to it")
                    return
                end
                if interaction.type == 'client' then
                    TriggerEvent(interaction.name, ...)
                elseif interaction.type == 'server' then
                    TriggerServerEvent(interaction.name, ...)
                elseif interaction.type == 'command' then
                    ExecuteCommand(interaction.name)
                end
            end
        }
    end
end

local function is_daytime()
    local hour = GetClockHours()
    return hour >= 6 and hour < 19
end

local function evaluateBindValue(option, optionIndex, menuOriginalData, pt)
    local value = menuOriginalData.interactions[optionIndex]

    local function callFunction()
        if value and value.func then
            return pcall(value.func, pt.entity, pt.distance, pt.coords, pt.name, pt.bone)
        end
        return false, nil
    end

    if option.flags.bind then
        -- Handle 'bind'
        local success, res = callFunction()

        if success then
            if option.progress and option.progress.value ~= res then
                option.progress.value = res
                return true
            elseif not option.progress and option.label ~= res then
                option.label = res
                return true
            end
        end
    elseif option.flags.dynamic then
        -- Handle 'dynamic'
        local success, res = callFunction()

        if success then
            if res ~= option.label then
                option.label = res
                return true
            end
        elseif option.label_cache ~= option.label then
            option.label_cache = option.label
            return true
        end
    else
        return false
    end
end

--- check canInteract passed by user and update option's visibility
---@param option any
---@param optionIndex any
---@param menuOriginalData any
---@param pt any "passThrough"
---@return boolean "modified"
local function updateOptionVisibility(option, optionIndex, menuOriginalData, pt)
    if not option.flags.canInteract then return false end

    local value = menuOriginalData.interactions['canInteract|' .. optionIndex]
    local success, res = pcall(value.func, pt.entity, pt.distance, pt.coords, pt.name, pt.bone)

    if success and res == nil then res = false end
    if success and type(res) == "boolean" then
        if option.flags.hide == not res then return false end
        option.flags.hide = not res
        return true
    else
        if option.flags.hide == false then return false end
        option.flags.hide = false
        return true
    end
end

local function check_restrictions(restrictions)
    if not Bridge.active then return true end

    local job, job_level = Bridge.getJob()
    local gang, gang_level = Bridge.getGang()

    if restrictions.job then
        local allowed_job_levels = restrictions.job[job]
        if allowed_job_levels and (next(allowed_job_levels) == nil or allowed_job_levels[job_level]) then
            return true, 'job'
        end
    end

    if restrictions.gang then
        local allowed_gang_levels = restrictions.gang[gang]
        if allowed_gang_levels and (next(allowed_gang_levels) == nil or allowed_gang_levels[gang_level]) then
            return true, 'gang'
        end
    end

    return false
end

local function frameworkOptionVisibilityRestrictions(updatedElements, menuId, option, optionIndex, menuOriginalData, pt)
    -- #TODO: refactor and add new restrictions
    if not Bridge.active then return false end
    if option.item == nil and option.job == nil and option.gang == nil then
        return false
    end

    local shouldHide = false
    if option.item then
        local res = Bridge.hasItem(option.item)
        shouldHide = type(res) == "boolean" and not res
    end

    if option.job or option.gang then
        local res = check_restrictions({
            job = option.job,
            gang = option.gang
        })
        shouldHide = type(res) == "boolean" and not res
    end

    option.flags.hide = shouldHide
    if option.flags.hide == shouldHide then
        return false
    else
        return true
    end
end

--- calculate canInteract and update values and refresh UI
---@param scaleform table
---@param menuData table
function Container.syncData(scaleform, menuData, refreshUI)
    local updatedElements = {}
    local passThrough = Container.constructMetadata(menuData)

    for _, menu in pairs(menuData.menus) do
        local menuId = menu.id
        local menuOriginalData = Container.get(menuId)

        if not menuOriginalData then
            -- What is this?
            -- If we delete the menu (garbage collection) while a player is using that menu, we have to close it.
            -- For example, if a player is looking at an entity that has a menu and two globals on it, the menu is still in use.
            -- However, we've literally garbage collected it XD, so we need to close the menu and get the new container.

            StateManager.reset()
            return
        end

        local deleted = menuOriginalData.flags.deleted

        if not deleted then
            for optionIndex, option in ipairs(menu.options) do
                local modified_something = false

                modified_something = modified_something or evaluateBindValue(option, optionIndex, menuOriginalData, passThrough)
                modified_something = modified_something or updateOptionVisibility(option, optionIndex, menuOriginalData, passThrough)
                modified_something = modified_something or frameworkOptionVisibilityRestrictions(updatedElements, menuId, option, optionIndex, menuOriginalData, passThrough)

                if modified_something or option.flags.previous_hide ~= option.flags.hide then
                    option.flags.previous_hide = option.flags.hide
                    table.insert(updatedElements, { menuId = menuId, option = option })
                end
            end
        elseif deleted and not menuOriginalData.flags.deletion_synced then
            menuOriginalData.flags.deletion_synced = true
            table.insert(updatedElements, { menuId = menuId, option = {} })
            Interact:deleteMenu(menuId)
        end
    end

    if refreshUI or #updatedElements > 0 then
        scaleform.send("interactionMenu:menu:batchUpdate", updatedElements)
    end

    if refreshUI and next(updatedElements) then
        -- merged from handleCheckedListUpdates(scaleform, menuData)
        -- If the player has selected the element that we want to hide, then we have to move their selected value to something
        -- that is valid
        Container.validateAndSyncSelected(scaleform, menuData)
    end

    if Config.features.timeBasedTheme and is_daytime() ~= previous_daytime then
        previous_daytime = is_daytime()
        Interact:setDarkMode(previous_daytime)
    end
end

function IsMenuVisible(menu_data)
    local is_visible = false
    for _, menu in pairs(menu_data.menus) do
        local menu_id = menu.id
        local original_menu_data = Container.get(menu_id)

        if original_menu_data and not original_menu_data.flags.deleted then
            for _, option in ipairs(menu.options) do
                if option.flags.hide == false then
                    is_visible = true
                end
            end
        end
    end

    return is_visible
end

-- Validate and synchronize the selected option. If it's the first encounter with the menu,
-- choose a valid option; otherwise, restore the state on top of revalidating it
---@param scaleform table
---@param menuData table
function Container.validateAndSyncSelected(scaleform, menuData)
    if not menuData then return end

    local selected = menuData.selected

    -- Early exit if no valid menu options are present
    if not hasValidMenuOption(menuData) then
        return
    end

    -- Find the current selected option
    local currentSelectedVid = nil
    for vid, isSelected in pairs(selected) do
        if isSelected then
            currentSelectedVid = vid
            break
        end
    end

    -- validate the current selected option
    if currentSelectedVid then
        local isValid = false
        local validOptions = collectValidOptions(menuData, function(a, b)
            return a.vid < b.vid
        end)

        for index, option in ipairs(validOptions) do
            if option.vid == currentSelectedVid then
                isValid = true
                break
            end
        end

        -- current selection is valid, no need to update
        if isValid then return end

        -- Current selection is not valid, reset all and select a new valid option
        for vid in pairs(selected) do
            selected[vid] = false
        end
    end

    -- find and select the first valid option
    local validOption = firstValidOption(menuData)
    local vid = validOption and validOption.vid

    if vid then
        selected[vid] = true
        scaleform.send("interactionMenu:menu:selectedUpdate", vid)
    else
        Util.print_debug('probably trigger only menu')
    end
end

local function setHideProperty(menuRef, option, value)
    if option then
        if not menuRef.options[option] then
            warn("Option does not exist!")
            return
        end
        menuRef.options[option].flags.hide = value
    else
        if type(value) ~= "boolean" then
            warn("'Hide' value must be a boolean")
            return
        end
        menuRef.flags.hide = value
        Interact:setVisibility(menuRef.id, not value)
    end
end

local function setLabelProperty(menuRef, option, value)
    if not menuRef.options[option].flags.dynamic then
        warn('Updating a static option. Set it as dynamic to update its value.')
        return
    end

    menuRef.options[option].label = value
end

local function setProgressProperty(menuRef, option, value)
    if not menuRef.options[option].flags.dynamic then
        warn("Updating a static option. Set it as dynamic to update its value.")
        return
    end

    menuRef.options[option].progress.value = value
end

local function setMenuPosition(menuRef, nPos)
    if not menuRef.position then
        warn("Menu is not position-based and its position cannot be updated")
        return
    end

    if type(nPos) ~= "vector3" and type(nPos) ~= "vector4" then
        warn("Position value must be a vector3 or vector4")
        return
    end

    nPos = vec2(nPos.x, nPos.y)
    grid:update(menuRef.position, nPos)
end

local function setMenuProperty(t)
    local menuId = t.menuId
    local menuRef = Container.get(menuId)

    if not menuRef then
        warn("Menu doesn't exists!")
        return
    end

    -- Handle specific property types
    if t.type == 'hide' then
        setHideProperty(menuRef, t.option, t.value)
    elseif t.type == 'position' then
        setMenuPosition(menuRef, t.value)
    elseif t.option then
        if not menuRef.options[t.option] then
            warn("Option doesn't exists!")
            return
        end

        if t.type == 'label' then
            setLabelProperty(menuRef, t.option, t.value)
        elseif t.type == 'progress' then
            setProgressProperty(menuRef, t.option, t.value)
        end
    else
        warn('Invalid property type: ' .. tostring(t.type))
    end
end

exports('set', setMenuProperty)
exports('setValue', setMenuProperty)
