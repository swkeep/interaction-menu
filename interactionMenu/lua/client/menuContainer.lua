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
local StateManager = Util.StateManager()
local PersistentData = Util.PersistentData()
local previous_daytime = false

-- enum: used in difference between OBJECTs, PEDs, VEHICLEs
EntityTypes = Util.ENUM {
    'PED',
    'VEHICLE',
    'OBJECT'
}
local set = {
    "peds",
    "vehicles",
    "objects"
}

-- class: PersistentData
-- managing menus
Container = {
    data = {},
    zones = {},
    indexes = {
        models = {},
        entities = {},
        players = {},
        bones = {},
        globals = {
            bones = {},
            entities = {},
            objects = {},
            peds = {},
            players = {},
            vehicles = {}
        }
    }
}

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
            type = option.action.type,
            func = option.action.func
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
            func = option.update.func
        }
        interactionType = 'update'
    elseif option.bind then
        interaction = {
            bind = true,
            func = option.bind.func
        }

        interactionType = 'bind'
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

local zone_grid = SpatialHashGrid:new('zone', 100)

local function AddBoxZone(o)
    local z = BoxZone:Create(vec3(o.position.x, o.position.y, o.position.z), o.length or 1.0, o.width or 1.0, {
        name = o.name,
        heading = o.heading,
        debugPoly = o.debugPoly,
        minZ = o.minZ,
        maxZ = o.maxZ,
    })

    return z
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
            static = t.static and true or false
        }
    }

    if t.position and not t.zone then
        instance.position = { x = t.position.x, y = t.position.y, z = t.position.z, id = id }
        grid:insert(instance.position)
    elseif t.player then
        if type(t.player) ~= 'number' then
            warn('Player id must a integer value')
            return
        end
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
        instance.position = {
            x = t.position.x,
            y = t.position.y,
            z = t.position.z,
            id = id
        }
        instance.rotation = t.rotation
        instance.zone = t.zone
        Container.zones[id] = AddBoxZone(t.zone)
        zone_grid:insert(instance.position)
    end

    buildOption(t, instance)
    transformJobData(instance)

    buildInteraction(t, instance.interactions, "onTrigger")
    buildInteraction(t, instance.interactions, "onSeen")
    buildInteraction(t, instance.interactions, "onExit")
    classifyMenuInstance(instance)

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

function Container.boneCheck(entity)
    -- it's safer to use it only in vehicles
    if GetEntityType(entity) ~= 2 then
        return
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
            container.position = data.position and data.position or container.position
            container.offset = data.metadata and data.metadata.offset or container.offset
            container.indicator = data.indicator and data.indicator or container.indicator
            container.theme = data.theme and data.theme or container.theme
            container.glow = data.glow and data.glow or container.glow
            container.maxDistance = data.metadata and data.metadata.maxDistance
            container.static = data.flags and data.flags.static
            container.zone = data.zone
            container.rotation = data.rotation

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

    if not PersistentData.hasBeenSet(id) then
        PersistentData.set(id, { selected = container.selected, loading = false })
    end

    return container
end

local function IdentifyPlayerServerId(entityType, entity)
    return entityType == 1 and IsPedAPlayer(entity) and GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity))
end

local function isPedAPlayer(entityType, entity)
    return entityType == 1 and IsPedAPlayer(entity)
end

function Container.getMenu(model, entity, menuId)
    local id
    local combinedIds = {}
    local container = {
        id, -- value is set in setId function
        menus = {},
        selected = {},
        glow = false,
        theme = 'default',
        loading = false
    }

    local closestBoneId, closestBoneName = Container.boneCheck(entity)

    -- global priority
    if entity then
        combinedIds = mergeGlobals(combinedIds, entity, model, closestBoneName)
    else
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
    local playerId = IdentifyPlayerServerId(entityType, entity)

    if t.zone then
        return MenuTypes['ON_ZONE']
    elseif t.closestPoint and next(t.closestPoint) then
        -- onPosition
        return MenuTypes['ON_POSITION']
    elseif (entityType == 3 or entityType == 2) and models[model] or entities[entity] or players[playerId] or globalsExistsCheck(entity, entityType) then
        -- onModel / onEntity / onBone
        return MenuTypes['ON_ENTITY']
    else
        return 1
    end
end

function Container.get(id)
    return Container.data[id]
end

function Container.remove(id)
    local menuRef = Container.get(id)

    menuRef.flags.deleted = true
    menuRef.deletedAt = GetGameTimer()
end

exports('remove', Container.remove)

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
    for _, menu in ipairs(menuData.menus) do -- Use ipairs for ordered traversal
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

    -- selected first one if we have not selected anything
    return currentSelectedIndex or 1
end

-- belive me i know we can do it with less interactions but i don't want to think about that right now!
function Container.changeMenuItem(scaleform, menuData, wheelDirection)
    if not hasValidMenuOption(menuData) then
        return
    end

    local data = PersistentData.get(menuData.id)
    local selected = data.selected
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

--- Checks the player's job
---@param data table
---@return boolean
local function jobCheck(data)
    if not data.extra or not data.extra.job then return true end
    local job_name, current_grade = Bridge.getJob()
    if not data.extra.job[job_name] then return false end
    return data.extra.job and data.extra.job[job_name] and data.extra.job[job_name][current_grade]
end

function Container.keyPress(scaleform, menuData, passThrough)
    local data = PersistentData.get(menuData.id)
    -- skip when already loading
    if data.loading then return end

    for index, value in ipairs(menuData.menus) do
        Container.triggerInteraction(value.id, 'onTrigger', passThrough)
    end

    local menuId, selectedOption = findSelectedOption(menuData, data.selected)
    if not selectedOption then return end
    local interaction = Container.data[menuId].interactions[selectedOption]

    local function refresh()
        PersistentData.clear(menuData.id)
        StateManager.reset()
    end

    CreateThread(function()
        if interaction.action then
            if interaction.type == "sync" then
                data.loading = true
            end
            local success, result = pcall(interaction.func, passThrough, refresh)

            if interaction.type == "sync" then
                data.loading = false
            end
        elseif interaction.event then
            if interaction.type == 'client' then
                TriggerEvent(interaction.name, interaction.payload)
            elseif interaction.type == 'server' then
                TriggerServerEvent(interaction.name, interaction.payload)
            end
        end
    end)
end

local function is_daytime()
    local hour = GetClockHours()
    return hour >= 6 and hour < 19
end

--- calculate canInteract and update values and refresh UI
---@param scaleform table
---@param menuData table
function Container.syncData(scaleform, menuData, refreshUI, passThrough)
    local updatedElements = {}

    for _, menu in pairs(menuData.menus) do
        local menuId = menu.id
        local menuOriginalData = Container.get(menuId)
        local deleted = menuOriginalData.flags.deleted

        if not deleted then
            for optionIndex, option in ipairs(menu.options) do
                local already_inserted = false

                -- to get the dynamic values
                if option.flags.dynamic then
                    if option.progress and option.progress.value ~= option.cached_value then
                        already_inserted = true
                        option.cached_value = option.progress.value
                        table.insert(updatedElements, { menuId = menuId, option = option })
                    elseif option.label_cache ~= option.label then
                        already_inserted = true
                        option.label_cache = option.label
                        table.insert(updatedElements, { menuId = menuId, option = option })
                    end
                end

                -- #FIX: this can crash game if menu deleted
                if option.flags.bind then
                    local value = menuOriginalData.interactions[optionIndex]
                    local sucess, res = pcall(value.func, passThrough)

                    if option.progress and option.progress.value ~= res then
                        option.cached_value = option.progress.value
                        option.progress.value = res
                        table.insert(updatedElements, { menuId = menuId, option = option })
                    end
                end

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

    if Config.features.time_based_theme_switch and is_daytime() ~= previous_daytime then
        previous_daytime = is_daytime()
        Interact:SetDarkMode(previous_daytime)
    end
end

-- Validate and synchronize the selected option. If it's the first encounter with the menu,
-- choose a valid option; otherwise, restore the state on top of revalidating it
---@param scaleform table
---@param menuData table
function Container.validateAndSyncSelected(scaleform, menuData)
    local data = PersistentData.get(menuData.id)
    if not data then return end

    for menuId, menu in pairs(menuData.menus) do
        for _, option in pairs(menu.options) do
            if data.selected[option.vid] and isOptionValid(option) then
                scaleform.send("interactionMenu:menu:selectedUpdate", option.vid)
                return
            end
        end
    end

    local validOption = firstValidOption(menuData)
    local vid = validOption and validOption.vid

    if vid then
        data.selected[vid] = true
        scaleform.send("interactionMenu:menu:selectedUpdate", vid)
    else
        Util.print_debug('probably trigger only menu')
    end
end

function Container.loadingState(scaleform, menuData)
    local data = PersistentData.get(menuData.id)

    if not data then return end
    if data.showingLoading == nil then data.showingLoading = false end

    if data.loading and not data.showingLoading then
        data.showingLoading = true
        Interact:scaleformUpdate(menuData, { loading = true })
    elseif not data.loading and data.showingLoading then
        Interact:scaleformUpdate(menuData, { loading = false })

        data.showingLoading = false
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
        end
    end

    StateManager.reset()
end

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end

    Container.removeByInvokingResource(resource)
end)

-- CreateThread(function()
--     Wait(1000)

--     Util.print_table(Container.indexes)
-- end)
