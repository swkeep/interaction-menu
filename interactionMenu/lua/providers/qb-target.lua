if GetResourceState('qb-core') ~= 'started' then return end

local function replaceExport(exportName, func)
    Util.replaceExport('qb-target', exportName, func)
end

local function convertTargetOptions(targetOptions)
    targetOptions = targetOptions.options
    local menuOptions = {}

    for id, value in pairs(targetOptions) do
        local payload
        local option = {
            icon = value.icon,
            label = value.label,
            canInteract = value.canInteract,
            order = value.num,
            job = value.job,
            gang = value.gang
        }

        -- Move other properties to `payload`
        for key, val in pairs(value) do
            if not option[key] and key ~= "event" and key ~= "action" and key ~= 'type' then
                if not payload then payload = {} end
                payload[key] = val
            end
        end

        if value.action then
            option.action = value.action
        elseif value.event then
            option.event = {
                type = value.type,
                name = value.event,
                payload = payload
            }
        end

        menuOptions[#menuOptions + 1] = option
    end

    -- #TODO: sort by order/num

    return menuOptions
end

replaceExport('AddCircleZone', function(name, center, radius, options, targetoptions)
    local distance = targetoptions.distance or 3
    local menu = {
        id = name,
        position = center,
        options = convertTargetOptions(targetoptions),
        maxDistance = distance,
        schemaType = 'qbtarget'
    }

    return exports['interactionMenu']:Create(menu)
end)

replaceExport('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local distance = targetoptions.distance or 3
    local menu = {
        id = name,
        position = center,
        options = convertTargetOptions(targetoptions),
        maxDistance = distance,
        schemaType = 'qbtarget'
    }

    return exports['interactionMenu']:Create(menu)
end)

local function getCentroid(polygon)
    local centroid = vec3(0, 0, 0)
    local numPoints = #polygon

    for i = 1, numPoints do
        centroid = centroid + polygon[i]
    end

    return (centroid / numPoints)
end

replaceExport('AddPolyZone', function(name, points, options, targetoptions)
    -- #TODO: fix: or just set it to not supported export
    local newPoints = table.create(#points, 0)
    local thickness = math.abs(options.maxZ - options.minZ)
    local distance = targetoptions.distance or 3

    local menu = {
        id = name,
        position = vec3(0, 0, 0),
        options = convertTargetOptions(targetoptions),
        maxDistance = distance,
        schemaType = 'qbtarget'
    }

    for i = 1, #points do
        local point = points[i]
        newPoints[i] = vec3(point.x, point.y, options.maxZ - (thickness / 2))
    end

    menu.center = getCentroid(newPoints)
    return exports['interactionMenu']:Create(menu)
end)

replaceExport('RemoveZone', function(id)
    exports['interactionMenu']:remove(id)
end)

replaceExport('AddTargetBone', function(bones, options)
    bones = Util.ensureTable(bones)
    local invokingResource = GetInvokingResource()

    for _, bone in ipairs(bones) do
        local id = invokingResource .. '_' .. bone

        exports['interactionMenu']:createGlobal {
            id = id,
            type = 'bones',
            bone = bone,
            offset = vec3(0, 0, 0),
            maxDistance = 1.0,
            options = convertTargetOptions(options),
            schemaType = 'qbtarget'
        }
    end
end)

replaceExport('RemoveTargetBone', function(bones, labels)
    bones = Util.ensureTable(bones)
    local invokingResource = GetInvokingResource()

    for i = 1, #bones do
        local bone = bones[i]
        local id = invokingResource .. '_' .. bone

        exports['interactionMenu']:remove(id)
    end
end)

replaceExport('AddTargetEntity', function(entities, options)
    entities = Util.ensureTable(entities)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            local netId = NetworkGetNetworkIdFromEntity(entity)

            exports['interactionMenu']:Create {
                id = entity,
                netId = netId,
                options = convertTargetOptions(options),
                schemaType = 'qbtarget'
            }
        else
            exports['interactionMenu']:Create {
                id = entity,
                entity = entity,
                options = convertTargetOptions(options),
                schemaType = 'qbtarget'
            }
        end
    end
end)

replaceExport('RemoveTargetEntity', function(entities, labels)
    entities = Util.ensureTable(entities)

    for i = 1, #entities do
        local entity = entities[i]

        if NetworkGetEntityIsNetworked(entity) then
            local netId = NetworkGetNetworkIdFromEntity(entity)
            exports['interactionMenu']:remove(netId)
        else
            exports['interactionMenu']:remove(entity)
        end
    end
end)

replaceExport('AddTargetModel', function(models, options)
    models = Util.ensureTable(models)
    local distance = options.distance or 3
    local invokingResource = GetInvokingResource()

    for i = 1, #models do
        local model = models[i]
        local id = invokingResource .. '|' .. model
        local modelHash = type(model) == "number" and model or joaat(model)

        exports['interactionMenu']:Create {
            id = id,
            model = modelHash,
            maxDistance = distance,
            options = convertTargetOptions(options),
            schemaType = 'qbtarget'
        }
    end
end)

replaceExport('RemoveTargetModel', function(models, labels)
    models = Util.ensureTable(models)
    local invokingResource = GetInvokingResource()

    for i = 1, #models do
        local model = models[i]
        local id = invokingResource .. '|' .. model
        exports['interactionMenu']:remove(id)
    end
end)

local idTemplate = '%s_%s%s_%s'
local function handleGlobalEntity(action, entityType, options)
    local distance = options.distance or 3
    local invokingResource = GetInvokingResource()
    options = convertTargetOptions(options)

    for _, value in ipairs(options) do
        local label = value.label or value
        local id = idTemplate:format(invokingResource, action, entityType, Util.cleanString(label))

        if action == 'add' then
            exports['interactionMenu']:createGlobal {
                id = id,
                type = entityType,
                offset = vec3(0, 0, 0),
                maxDistance = distance,
                options = { value },
                schemaType = 'qbtarget'
            }
        elseif action == 'remove' then
            exports['interactionMenu']:remove(id)
        end
    end
end

replaceExport('AddGlobalPed', function(options)
    handleGlobalEntity('add', 'peds', options)
end)

replaceExport('RemoveGlobalPed', function(labels)
    handleGlobalEntity('remove', 'peds', Util.ensureTable(labels))
end)

replaceExport('AddGlobalVehicle', function(options)
    handleGlobalEntity('add', 'vehicles', options)
end)

replaceExport('RemoveGlobalVehicle', function(labels)
    handleGlobalEntity('remove', 'vehicles', Util.ensureTable(labels))
end)

replaceExport('AddGlobalObject', function(options)
    handleGlobalEntity('add', 'entities', options)
end)

replaceExport('RemoveGlobalObject', function(labels)
    handleGlobalEntity('remove', 'entities', Util.ensureTable(labels))
end)

replaceExport('AddGlobalPlayer', function(options)
    handleGlobalEntity('add', 'players', options)
end)

replaceExport('RemoveGlobalPlayer', function(labels)
    handleGlobalEntity('remove', 'players', Util.ensureTable(labels))
end)

-- might be possible!
replaceExport('AddEntityZone')
replaceExport('DisableTarget')
replaceExport('CheckEntity')
replaceExport('CheckBones')
-- mine is always active!?
replaceExport('IsTargetActive')
replaceExport('IsTargetSuccess')

-- bruh
replaceExport('RaycastCamera')
replaceExport('DisableNUI')
replaceExport('EnableNUI')
replaceExport('LeftTarget')
replaceExport('DrawOutlineEntity')
replaceExport('AddGlobalType')
replaceExport('RemoveGlobalType')
replaceExport('DeletePeds')
replaceExport('RemoveSpawnedPed')
replaceExport('SpawnPed')
replaceExport('GetGlobalTypeData')
replaceExport('GetZoneData')
replaceExport('GetTargetBoneData')
replaceExport('GetTargetEntityData')
replaceExport('GetTargetModelData')
replaceExport('GetGlobalPedData')
replaceExport('GetGlobalVehicleData')
replaceExport('GetGlobalObjectData')
replaceExport('GetGlobalPlayerData')
replaceExport('UpdateGlobalTypeData')
replaceExport('UpdateZoneData')
replaceExport('UpdateTargetBoneData')
replaceExport('UpdateTargetEntityData')
replaceExport('UpdateTargetModelData')
replaceExport('UpdateGlobalPedData')
replaceExport('UpdateGlobalVehicleData')
replaceExport('UpdateGlobalObjectData')
replaceExport('UpdateGlobalPlayerData')
replaceExport('GetPeds')
replaceExport('UpdatePedsData')
replaceExport('AllowTargeting')
