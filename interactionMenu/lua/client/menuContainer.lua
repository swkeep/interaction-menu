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

    if option.action then
        interaction = {
            action = true,
            func = option.action
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

local function buildOption(data, instance)
    for i, option in ipairs(data.options or {}) do
        local formatted = {
            -- visual information
            label = option.label,
            picture = option.picture,
            video = option.video,
            audio = option.audio,
            style = option.style,
            progress = option.progress,
            icon = option.icon,

            flags = {
                dynamic = option.dynamic,
                disable = false,
                action = nil,
                event = nil,
                hide = false
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

local function transformJobData(data)
    if not (data.extra and data.extra.job) then return end

    for job_name, raw_grades in pairs(data.extra.job) do
        local job_grades = {}

        for _, grade in pairs(raw_grades) do
            job_grades[grade] = true
        end
        data.extra.job[job_name] = job_grades
    end
end

function Container.create(t)
    local invokingResource = GetInvokingResource() or 'interactionMenu'
    local id = t.id or Util.createUniqueId(Container.data)

    local instance = {
        id = id,
        type = nil,
        theme = t.theme,
        glow = t.glow,
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
    transformJobData(instance)

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

    local instance = {
        id = id,
        type = t.type,
        bone = t.bone,
        theme = t.theme,
        glow = t.glow,
        extra = t.extra or {},
        indicator = t.indicator,
        interactions = {},
        options = {},

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
    transformJobData(instance)

    buildInteraction(t, instance.interactions, "onTrigger")
    buildInteraction(t, instance.interactions, "onSeen")
    buildInteraction(t, instance.interactions, "onExit")

    Container.data[id] = instance
    -- index global interaction
    if Container.indexes.globals[instance.type] and instance.type ~= 'bones' then
        table.insert(Container.indexes.globals[instance.type], id)
    elseif instance.type == 'bones' then
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

local function setId(container, bones, closestBoneName, closestBoneId, model, entity, menuId)
    local id

    if bones and closestBoneName then
        id = entity .. '|' .. closestBoneId
        container.id = id
    elseif model and entity then
        id = model .. '|' .. entity
        container.id = id
    elseif model and not entity then
        id = model
        container.id = id
    elseif menuId then
        id = menuId
        container.id = id
    end

    return id
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
            container.position = data.position and data.position or container.position
            container.offset = data.metadata and data.metadata.offset or container.offset
            container.indicator = data.indicator and data.indicator or container.indicator
            container.theme = data.theme and data.theme or container.theme
            container.glow = data.glow and data.glow or container.glow
            container.maxDistance = data.metadata and data.metadata.maxDistance
            container.static = data.flags and data.flags.static
            container.zone = data.zone
            container.rotation = data.rotation
            container.icon = data.icon

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
                options = data.options
            }
        end
    end

    id = setId(container, bones, closestBoneName, closestBoneId, model, entity, menuId)

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

function Container.getMenuType(t)
    local model = t.model
    local entity = t.entity
    local entityType = t.entityType
    local entities = Container.indexes.entities
    local models = Container.indexes.models
    local players = Container.indexes.players
    local netIds = Container.indexes.netIds
    local playerId = IdentifyPlayerServerId(entityType, entity)
    local networked = NetworkGetEntityIsNetworked(entity)
    local netId

    if networked then
        netId = NetworkGetNetworkIdFromEntity(entity)
    end

    if t.zone then
        return MenuTypes['ON_ZONE']
    elseif t.closestPoint and next(t.closestPoint) then
        -- onPosition
        return MenuTypes['ON_POSITION']
    elseif (entityType == 3 or entityType == 2) and models[model] or entities[entity] or players[playerId] or globalsExistsCheck(entity, entityType) or netIds[netId] then
        -- onModel / onEntity / onBone
        if entityType == 2 and globalsExistsCheck(entity, entityType) then
            local _, closestBoneName = Container.boneCheck(entity)
            local globals = Container.indexes.globals
            local bones = Container.indexes.bones

            if bones[entity] and bones[entity][closestBoneName] then
                return MenuTypes['ON_ENTITY']
            end
            if not globals.bones[closestBoneName] then
                return 1
            end
        end
        return MenuTypes['ON_ENTITY']
    else
        return 1
    end
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
    return Container.data[menuId].interactions[optionId].func(...)
end

local function isOptionValid(option)
    return not option.flags.hide and option.flags.action or option.flags.event
end

local function hasValidMenuOption(menuData)
    for _, menu in ipairs(menuData.menus) do
        for _, option in ipairs(menu.options) do
            if isOptionValid(option) then return true end
        end
    end

    return false
end

local function firstValidOption(menuData)
    for _, menu in ipairs(menuData.menus) do
        for _, option in ipairs(menu.options) do
            if isOptionValid(option) then
                return option
            end
        end
    end
end

local function lastValidOption(menuData)
    local lastOption = nil

    for _, menu in ipairs(menuData.menus) do
        for _, option in ipairs(menu.options) do
            if isOptionValid(option) then
                lastOption = option
            end
        end
    end

    return lastOption
end

local function scrollMenu(wheelDirection, menus, currentSelectedIndex)
    local nextSelectedIndex

    if wheelDirection then
        -- Go down
        for _, menu in pairs(menus) do
            for _, option in pairs(menu.options) do
                if option.vid > currentSelectedIndex and isOptionValid(option) then
                    nextSelectedIndex = option.vid
                    break
                end
            end
            if nextSelectedIndex then break end
        end
    else
        -- Go up
        for i = #menus, 1, -1 do
            for j = #menus[i].options, 1, -1 do
                local option = menus[i].options[j]
                if option.vid < currentSelectedIndex and isOptionValid(option) then
                    nextSelectedIndex = option.vid
                    break
                end
            end
            if nextSelectedIndex then break end
        end
    end

    return nextSelectedIndex
end

local function findCurrentSelectedIndex(menus, selected)
    local currentSelectedIndex
    for _, menu in pairs(menus) do
        for _, option in pairs(menu.options) do
            if selected[option.vid] then
                currentSelectedIndex = option.vid
                break
            end
        end
        if currentSelectedIndex then break end
    end

    -- selected first one if we don't total have selected anything
    return currentSelectedIndex or 1
end

-- i know we can do it with less code but i don't want to think about that right now!
function Container.changeMenuItem(scaleform, menuData, wheelDirection)
    if not hasValidMenuOption(menuData) then
        return
    end

    local selected = menuData.selected
    local menus = menuData.menus

    -- Ignore if list is empty, selected is not present, or menus are absent
    if not selected or not menus or not next(menus) then
        return
    end

    local currentSelectedIndex = findCurrentSelectedIndex(menus, selected)
    local nextSelectedIndex = scrollMenu(wheelDirection, menus, currentSelectedIndex)

    -- Handle wrapping around
    if not nextSelectedIndex then
        if wheelDirection then
            nextSelectedIndex = firstValidOption(menuData).vid
        else
            nextSelectedIndex = lastValidOption(menuData).vid
        end
    end

    -- Deselect the current option and select the new one
    for _, menu in pairs(menus) do
        for _, option in pairs(menu.options) do
            selected[option.vid] = option.vid == nextSelectedIndex
        end
    end

    PlaySoundFrontend(-1, interactionAudio.mouseWheel.audioName, interactionAudio.mouseWheel.audioRef, true)
    scaleform.send("interactionMenu:menu:selectedUpdate", nextSelectedIndex)
end

local function findSelectedOption(menuData, selected)
    for _, menu in pairs(menuData.menus) do
        for _, option in pairs(menu.options) do
            if not option.hide and selected[option.vid] then
                return menu.id, option.id
            end
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
    elseif t.type == 'bone' then
        metadata.entity = t.entity
        metadata.bone = t.boneId
    end

    return metadata
end

function Container.keyPress(menuData)
    local metadata = Container.constructMetadata(menuData)

    for index, value in ipairs(menuData.menus) do
        Container.triggerInteraction(value.id, 'onTrigger', metadata)
    end

    local menuId, selectedOption = findSelectedOption(menuData, menuData.selected)
    if not selectedOption then return end
    local interaction = Container.data[menuId].interactions[selectedOption]

    if interaction.action then
        if not Container.runningInteractions[interaction.func] then
            Container.runningInteractions[interaction.func] = true
            PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)

            CreateThread(function()
                local success, result
                if menuData.type == 'zone' then
                    success, result = pcall(interaction.func, menuData.zone)
                else
                    success, result = pcall(interaction.func, menuData.entity, menuData.distance, menuData.coords,
                        menuData.name, menuData.bone)
                end

                Container.runningInteractions[interaction.func] = nil
            end)
        else
            Util.print_debug("Function is already running, ignoring additional calls to prevent spam.")
        end
    elseif interaction.event then
        if interaction.type == 'client' then
            TriggerEvent(interaction.name, interaction.payload, metadata)
        elseif interaction.type == 'server' then
            TriggerServerEvent(interaction.name, interaction.payload, metadata)
        end
    end
end

local function is_daytime()
    local hour = GetClockHours()
    return hour >= 6 and hour < 19
end

local function evaluateDynamicValue(updatedElements, menuId, option, optionIndex, menuOriginalData, passThrough)
    if not option.flags.dynamic then return false end

    local updated = false
    local value = menuOriginalData.interactions[optionIndex]
    if value and value.func then
        local success, res = pcall(value.func, passThrough.entity, passThrough.distance, passThrough.coords,
            passThrough.name, passThrough.bone)

        if success and res ~= option.label_cache then
            option.label_cache = res
            option.label = res
            updated = true
        end
    end
    if option.progress and option.progress.value ~= option.cached_value then
        option.cached_value = option.progress.value
        updated = true
    end
    if option.label_cache ~= option.label then
        option.label_cache = option.label
        updated = true
    end
    if updated then
        table.insert(updatedElements, { menuId = menuId, option = option })
    end

    return updated
end

local function evaluateBindValue(updatedElements, menuId, option, optionIndex, menuOriginalData, passThrough)
    if not option.flags.bind then return false end

    local value = menuOriginalData.interactions[optionIndex]
    local success, res = pcall(value.func, passThrough.entity, passThrough.distance, passThrough.coords, passThrough
        .name, passThrough.bone)

    if success and option.progress and option.progress.value ~= res then
        option.cached_value = option.progress.value
        option.progress.value = res
        table.insert(updatedElements, { menuId = menuId, option = option })
        return true
    end

    return false
end

--- check canInteract passed by user and update option's visibility
---@param updatedElements any
---@param menuId any
---@param option any
---@param optionIndex any
---@param menuOriginalData any
---@param pt any "passThrough"
---@return boolean
local function updateOptionVisibility(updatedElements, menuId, option, optionIndex, menuOriginalData, pt)
    if not option.flags.canInteract then return false end

    local value = menuOriginalData.interactions['canInteract|' .. optionIndex]
    local success, res = pcall(value.func, pt.entity, pt.distance, pt.coords, pt.name, pt.bone)

    if success and type(res) == "boolean" then
        option.flags.hide = not res
    else
        option.flags.hide = false
    end

    return false
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
            -- menuOriginalData.flags.hide = Container.triggerInteraction(menuId, 'canInteract') or false

            for optionIndex, option in ipairs(menu.options) do
                local already_inserted = false

                already_inserted = evaluateDynamicValue(updatedElements, menuId, option, optionIndex, menuOriginalData,
                    passThrough)
                already_inserted = evaluateBindValue(updatedElements, menuId, option, optionIndex, menuOriginalData,
                    passThrough)
                already_inserted = updateOptionVisibility(updatedElements, menuId, option, optionIndex, menuOriginalData,
                    passThrough)

                -- to hide option if its canInteract value has been changed
                if not already_inserted and option.flags.hide ~= nil and option.flags.hide ~= option.flags.previous_hide then
                    already_inserted = true
                    option.flags.previous_hide = option.flags.hide

                    table.insert(updatedElements, { menuId = menuId, option = option })
                end
            end
        elseif deleted and not menuOriginalData.flags.deletion_synced then
            menuOriginalData.flags.deletion_synced = true
            Interact:setVisibility(menuId, false)
        end
    end

    if refreshUI and #updatedElements > 0 then
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

-- Validate and synchronize the selected option. If it's the first encounter with the menu,
-- choose a valid option; otherwise, restore the state on top of revalidating it
---@param scaleform table
---@param menuData table
function Container.validateAndSyncSelected(scaleform, menuData)
    if not menuData then return end

    -- find the first selected option
    local current_selected = nil
    for i = 1, #menuData.selected do
        if menuData.selected[i] then
            current_selected = i
            break
        end
    end

    -- can we use current selected option
    if current_selected then
        for _, menu in pairs(menuData.menus) do
            for _, option in pairs(menu.options) do
                if option.vid == current_selected and isOptionValid(option) then
                    -- means it's still valid and we don't need to do anything
                    return
                end
            end
        end

        -- we can't use it, so we reset all and choose first valid one ourself
        for i = 1, #menuData.selected do
            menuData.selected[i] = false
        end
    end

    -- find something valid
    local validOption = firstValidOption(menuData)
    local vid = validOption and validOption.vid

    if vid then
        menuData.selected[vid] = true
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

function Container.removeByInvokingResource(i_r)
    for key, menu in pairs(Container.data) do
        if menu.metadata.invokingResource == i_r then
            Container.data[key].flags.deleted = true

            if Container.data[key].type == 'position' then
                grid:remove(Container.data[key].position)
            end
        end
    end

    StateManager.reset()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end

    Container.removeByInvokingResource(resource)
end)
