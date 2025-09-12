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
local StateManager = Util.StateManager()

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
    runningInteractions = {},
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
---@field disable boolean "Whether the option is disabled"
---@field action? function "Function to execute when the option is selected"
---@field event? string "Event name to trigger when the option is selected"
---@field hide boolean "Indicates whether the option should be hidden"

---@class MenuInstance
---@field id string|number
---@field type string|nil
---@field theme string
---@field glow boolean
---@field width number|string
---@field extra table<string, any>
---@field indicator string|boolean
---@field icon string
---@field interactions table
---@field options InteractionOption[]
---@field metadata MenuInstanceMetadata
---@field tracker '"raycast"'|'"proximity"'|string
---@field schemaType '"normal"'|'"qbtarget"'|string
---@field flags MenuInstanceFlags

---@class MenuInstanceMetadata
---@field invokingResource string
---@field offset vector3
---@field maxDistance number

---@class MenuInstanceFlags
---@field disable boolean
---@field hide boolean
---@field suppressGlobals boolean
---@field static boolean
---@field skip_animation boolean
---@field alternativeMetadata boolean

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
            label = option.label,
            description = option.description,
            badge = option.badge,
            template = option.template,
            picture = option.picture,
            video = option.video,
            audio = option.audio,
            style = option.style,
            progress = option.progress,
            icon = option.icon,
            item = option.item,
            items = option.items,
            has_any = option.has_any,
            job = option.job and transformRestrictions(option.job),
            gang = option.gang and transformRestrictions(option.gang),

            tts_api = option.tts_api,
            tts_voice = option.tts_voice,

            flags = {
                disable = false,
                action = nil,
                event = nil,
                hide = option.hide or false,
                subMenu = option.subMenu or false,
                dialogue = option.dialogue or false,
            }
        }

        constructInteractionData(option, instance, i, formatted)
        instance.options[i] = formatted
    end
end

---@alias GTAVBoneName
---| '"SKEL_Head"'
---| '"SKEL_Neck_1"'
---| '"SKEL_Spine3"'                    -- Upper Spine
---| '"SKEL_Spine2"'                    -- Middle Spine
---| '"SKEL_Spine1"'                    -- Lower Spine
---| '"SKEL_Spine0"'                    -- Root Spine
---| '"SKEL_L_Clavicle"'
---| '"SKEL_R_Clavicle"'
---| '"SKEL_L_UpperArm"'
---| '"SKEL_R_UpperArm"'
---| '"SKEL_L_Forearm"'
---| '"SKEL_R_Forearm"'
---| '"SKEL_L_Hand"'
---| '"SKEL_R_Hand"'
---| '"SKEL_L_Thigh"'
---| '"SKEL_R_Thigh"'
---| '"SKEL_L_Calf"'
---| '"SKEL_R_Calf"'
---| '"SKEL_L_Foot"'
---| '"SKEL_R_Foot"'
---| '"SKEL_L_Toe0"'
---| '"SKEL_R_Toe0"'
---| '"SKEL_Pelvis"'
---| '"SKEL_Spine_Root"'
-- Vehicle bones
---| '"chassis"'
---| '"windscreen"'
---| '"bonnet"'
---| '"boot"'
---| '"door_dside_f"'
---| '"door_dside_r"'
---| '"door_pside_f"'
---| '"door_pside_r"'
---| '"wheel_lf"'
---| '"wheel_rf"'
---| '"wheel_lr"'
---| '"wheel_rr"'
---| string

---@class ManualTriggers
---@field open string
---@field close string

---@class UserCreateData
---@field id? number|string
---@field vehicle? number
---@field entity? number
---@field zone? number
---@field position? number
---@field options? table
---@field bone? GTAVBoneName
---@field tracker? string
---@field dimensions? table
---@field offset? table
---@field rotation? table
---@field triggers? ManualTriggers
---@field scale? number
---@field theme? string
---@field type? string
---@field glow? boolean
---@field maxDistance? number
---@field indicator? table
---@field extra? table
---@field player? number
---@field model? number
---@field netId? number
---@field width? number|string
---@field icon? string
---@field schemaType? string
---@field suppressGlobals? boolean
---@field static? boolean
---@field skip_animation? boolean
---@field alternativeMetadata? boolean

---@param t UserCreateData
---@return string|number?
function Container.create(t)
    local invokingResource = GetInvokingResource() or 'interactionMenu'
    local id = t.id or Util.createUniqueId(Container.data)
    if Container.data[id] then
        warn(dupe_menu:format(invokingResource, id))
        GC.flag(id)
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
            disable = false,
            hide = false,
            suppressGlobals = t.suppressGlobals and true or false,
            static = t.static and true or false,
            skip_animation = t.skip_animation and true or false,
            alternativeMetadata = t.alternativeMetadata or false
        }
    }

    if t.type == "manual" then
        Features.resolve("Create", "OPENED_MANUALLY", t, instance)
    elseif t.position and not t.zone then
        Features.resolve("Create", "AT_POSITION", t, instance)
    elseif t.player then
        if type(t.player) ~= 'number' then
            warn('Player id must a integer value')
            return
        end
        instance.type = 'player'
        instance.player = t.player
    elseif t.entity or t.model or t.netId then
        Features.resolve("Create", "TARGETING_ENTITY", t, instance)
    elseif t.bone then
        Features.resolve("Create", "ON_VEHICLE_BONE", t, instance)
    elseif t.zone and t.position then
        Features.resolve("Create", "TRIGGER_ZONE", t, instance)
    else
        warn('Could not determine menu type (failed to create interaction)')
        return
    end

    buildOption(t, instance)
    buildInteraction(t, instance.interactions, "onTrigger")
    buildInteraction(t, instance.interactions, "onSeen")
    buildInteraction(t, instance.interactions, "onExit")

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
            disable = false,
            hide = false,
            skip_animation = t.skip_animation and true or false,
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
function Container.boneCheck(ray_hit_position, entity)
    -- it's safer to use it only in vehicles
    if not ray_hit_position then return nil, nil, nil end
    if GetEntityType(entity) ~= 2 then return nil, nil, nil end

    local bones = Container.indexes.bones[entity] or Container.indexes.globals.bones
    if bones then
        local closestVehicleBone, closestBoneName, boneDistance = 0, false, 0
        closestVehicleBone, closestBoneName, boneDistance = Util.getClosestVehicleBone(ray_hit_position, entity, bones)

        if boneDistance <= 1 then
            return closestVehicleBone, closestBoneName, boneDistance
        end
    end

    return nil, nil, nil
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

        if data and not GC.isMarked(menu_id) then
            local index = #container.menus + 1
            local flags = data.flags
            container.type = data.type and data.type or container.type
            container.offset = data.metadata and data.metadata.offset or container.offset
            container.indicator = data.indicator and data.indicator or container.indicator
            container.theme = data.theme and data.theme or container.theme
            container.glow = data.glow and data.glow or container.glow
            container.width = data.width and data.width or container.width
            container.maxDistance = data.metadata and data.metadata.maxDistance
            container.static = flags and flags.static
            container.skip_animation = flags and flags.skip_animation
            container.zone = data.zone
            container.position = data.position and data.position or container.position
            container.rotation = data.rotation
            container.icon = data.icon
            container.scale = data.scale

            if flags.suppressGlobals then
                container.selected = {}
                container.menus = {}
                index = 1
                row_counter = 1
            end

            for option_index, option in ipairs(data.options) do
                row_counter = row_counter + 1
                option.id = option_index
                option.vid = row_counter
                container.selected[row_counter] = false
            end

            container.menus[index] = {
                id = menu_id,
                flags = flags,
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

function Container.getMenu(model, entity, menuId, list_of_id)
    if menuId then
        local menuRef = Container.get(menuId)
        if not menuRef then return end
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

    if list_of_id then
        combinedIds = list_of_id
    end

    local ray_hit_position = StateManager.get("hitPosition")
    local closestBoneId, closestBoneName = Container.boneCheck(ray_hit_position, entity)

    -- global priority
    if entity then
        combinedIds = mergeGlobals(combinedIds, entity, model, closestBoneName)
    else
        -- globals for zones
        if menuId then
            local menuRef = Container.get(menuId)
            if menuRef.type == 'zone' then
                container.tracker = menuRef.tracker
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

function Container.get(id)
    return Container.data[id]
end

function Container.count()
    return Container.total
end

function Container.triggerInteraction(menuId, optionId, ...)
    if not Container.data[menuId] or not Container.data[menuId].interactions[optionId] then return end
    local func = Container.data[menuId].interactions[optionId].func

    if not func and func["__cfx_functionReference"] then return end
    return pcall(func, ...)
end

local function isOptionValid(option)
    return not option.flags.hide and (option.flags.action or option.flags.event)
end

local function collectValidOptions(menuData, sortCon)
    local validOptions = {}

    for _, menu in ipairs(menuData.menus) do
        for _, option in ipairs(menu.options) do
            if isOptionValid(option) then
                option.menu_id = menu.id
                validOptions[#validOptions + 1] = option
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
    elseif schemaType == "ox_target" then
        data = {
            entity = menuData.entity,
            coords = menuData.coords,
            distance = menuData.distance,
            zone = menuData.name,
            bone = menuData.bone
        }
        try_unpack = false
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

    local function processInteraction(triggerType, cb)
        PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)

        processData {
            schemaType = schemaType,
            triggerType = triggerType,
            interaction = interaction,
            menuData = menuData,
            metadata = metadata,
            cb = cb
        }
    end

    local function actionCallback(...)
        local success, result = pcall(interaction.func, ...)
    end

    local function eventCallback(...)
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

    if interaction.action then
        if not Container.runningInteractions[interaction.func] then
            Container.runningInteractions[interaction.func] = true
            PlaySoundFrontend(-1, 'Highlight_Cancel', 'DLC_HEIST_PLANNING_BOARD_SOUNDS', true)

            CreateThread(function()
                local triggerType = menuData.type == 'zone' and 'zone' or 'action'
                processInteraction(triggerType, actionCallback)
                Container.runningInteractions[interaction.func] = nil
            end)
        else
            Util.print_debug("Function is already running, ignoring additional calls to prevent spam.")
        end
    elseif interaction.event or interaction.command then
        processInteraction('event', eventCallback)
    end
end

function Container.refresh()
    if not Container.current then return end
    local scaleform = Interact.getScaleform()
    Container.syncData(scaleform, Container.current, true)
end

exports("Refresh", Container.refresh)
exports("refresh", Container.refresh)

local function is_daytime()
    local hour = GetClockHours()
    return hour >= 6 and hour < 19
end

local function update_field(changes, option, field, new_value)
    if new_value ~= nil and option[field] ~= new_value then
        option[field] = new_value
        changes[field] = new_value
        return true
    end
    return false
end

function table.eq(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or table.eq(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

local function apply_bind_result(option, option_index, menu_data, pt, changes)
    if not (option.flags and option.flags.bind) then return false end

    local interaction = menu_data.interactions[option_index]
    if not interaction then return false end

    local ok, res = pcall(interaction.func, pt.entity, pt.distance, pt.coords, pt.name, pt.bone)
    if not ok or not res then return false end

    local modified = false
    local res_type = type(res)
    if res_type == "string" then
        modified = update_field(changes, option, "label", res) or modified
    elseif res_type == "table" then
        if option.template and next(res) then
            modified = update_field(changes, option, "template_data", res) or modified
        else
            modified = update_field(changes, option, "label", res.label) or modified
            modified = update_field(changes, option, "description", res.description) or modified
            if res.progress and option.progress then
                modified = update_field(changes, option, "progress", res.progress) or modified
            end
        end
    end

    return modified
end

local function apply_visibility_rule(option, option_index, menu_data, pt, changes)
    if not (option.flags and option.flags.canInteract) then return false end

    local interaction = menu_data.interactions['canInteract|' .. option_index]
    if not interaction then return false end

    local ok, res = pcall(interaction.func, pt.entity, pt.distance, pt.coords, pt.name, pt.bone)
    if ok and res == nil then res = false end

    local newHide = (ok and type(res) == "boolean") and not res or false
    return update_field(changes, option.flags, "hide", newHide)
end

local function _validate_restrictions(restrictions)
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

local function apply_framework_restrictions(updatedElements, menuId, option, optionIndex, menuOriginalData, pt, changes)
    if not Bridge.active then return false end
    if not (option.item or option.items or option.job or option.gang) then return false end

    local shouldHide = false
    if option.item then
        local ok = Bridge.hasItem(option.item)
        shouldHide = type(ok) == "boolean" and not ok or false
    end

    if option.items then
        if option.has_any then
            -- only needs one of the items
            shouldHide = true
            for _, item in pairs(option.items) do
                if Bridge.hasItem(item) then
                    shouldHide = false
                    break
                end
            end
        else
            -- must have all items
            shouldHide = false
            for _, item in pairs(option.items) do
                if not Bridge.hasItem(item) then
                    shouldHide = true
                    break
                end
            end
        end
    end

    if option.job or option.gang then
        local allowed = _validate_restrictions({ job = option.job, gang = option.gang })
        shouldHide = type(allowed) == "boolean" and not allowed or shouldHide
    end

    return update_field(changes, option.flags, "hide", shouldHide)
end

--- calculate canInteract and update values and refresh UI
---@param scaleform table
---@param menuData table
function Container.syncData(scaleform, menuData, refreshUI)
    local updated_elements = {}
    local metadata = Container.constructMetadata(menuData)

    for menu_index, menu in pairs(menuData.menus) do
        local menu_id   = menu.id
        local menu_data = Container.get(menu_id)

        if menu_data then
            local flags = menu_data.flags

            if not GC.isMarked(menu_id) then
                for option_index, option in ipairs(menu.options) do
                    local changes  = {}
                    local modified = false
                    local _flags   = option.flags

                    modified       = apply_bind_result(option, option_index, menu_data, metadata, changes) or modified
                    modified       = apply_visibility_rule(option, option_index, menu_data, metadata, changes) or modified
                    modified       = apply_framework_restrictions(updated_elements, menu_id, option, option_index, menu_data, metadata, changes) or modified

                    if _flags.previous_hide ~= _flags.hide then
                        _flags.previous_hide = _flags.hide
                        changes.flags = _flags
                        modified = true
                    end

                    if modified then
                        changes.vid = option.vid
                        table.insert(updated_elements, { menuId = menu_id, option = changes })
                    end
                end
            else
                GC.exec {
                    menu_index = menu_index,
                    menus = menuData.menus,
                    menu_id = menu_id,
                    menu = menu
                }
                -- to trigger an update
                updated_elements[#updated_elements + 1] = {}
            end
        end
    end

    if refreshUI and next(updated_elements) then
        scaleform.send("interactionMenu:menu:batchUpdate", updated_elements)
    end

    if refreshUI and next(updated_elements) then
        -- merged from handleCheckedListUpdates(scaleform, menuData)
        -- If the player has selected the element that we want to hide, then we have to move their selected value to something
        -- that is valid
        Container.validateAndSyncSelected(scaleform, menuData)
    end

    local now = is_daytime()
    if now ~= StateManager.get("daytime") then
        StateManager.set("daytime", now)
        Interact:setDarkMode(now)
    end
end

function IsMenuVisible(menu_data)
    local is_visible = false
    for _, menu in pairs(menu_data.menus) do
        local menu_id = menu.id
        local original_menu_data = Container.get(menu_id)

        if original_menu_data and not GC.isMarked(menu_id) then
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
    if not hasValidMenuOption(menuData) then return end

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
        Features.resolve("Set", menuRef.type, menuRef, t)
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
