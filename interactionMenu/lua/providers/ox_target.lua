if not Config.provide.ox_target then return end

local Registry = {
    models = {},
    entities = {},
    local_entities = {},
    netIds = {},
    global_objects = {}
}

local function replaceExport(exportName, func)
    Util.replaceExport('ox_target', exportName, func)
end

local function make_id(prefix, owner, hash)
    return table.concat({ prefix, tostring(owner), tostring(hash), GetInvokingResource() }, "_")
end

local function joaat_safe(v)
    if type(v) ~= "string" then v = tostring(v) end
    return joaat(v)
end

local function convert_options(options)
    local resource = GetInvokingResource()
    local _options = {}

    for index, option in ipairs(options) do
        local opt = table.clone and table.clone(option) or {}

        if opt.event then
            opt.event = {
                type = opt.serverEvent and 'server' or 'client',
                name = opt.event,
            }
        end

        if (opt.action or opt.onSelect) and opt.export then
            local original_action = opt.action or opt.onSelect
            opt.action = function(...)
                if original_action then pcall(original_action, ...) end
                pcall(exports[resource][opt.export], nil, ...)
            end

            opt.onSelect = nil
        end

        if opt.anyItem then
            opt.has_any = true
        end

        _options[index] = opt
    end

    return _options
end

local function addLocalEntity(entities, options)
    entities = Util.ensureTable(entities)

    for i = 1, #entities do
        for index, value in ipairs(options) do
            if not Registry.local_entities[entities[i]] then
                Registry.local_entities[entities[i]] = {}
            end

            if value.label then
                Registry.local_entities[entities[i]][index] = joaat_safe(value.label)
                local id = make_id("entity_" .. entities[i], GetInvokingResource(), joaat_safe(value.label))

                Container.create({
                    id = id,
                    entity = entities[i],
                    options = convert_options {
                        value
                    },
                    maxDistance = value.distance,
                    schemaType = 'ox_target'
                })
            end
        end
    end
end

local function removeLocalEntity(entities, optionNames)
    entities = Util.ensureTable(entities)
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for i = 1, #entities do
        local ent = entities[i]

        if not optionNames then
            if Registry.local_entities[ent] then
                for _, label in pairs(Registry.local_entities[ent]) do
                    local id = make_id("entity_" .. ent, GetInvokingResource(), joaat_safe(label))
                    GC.flag(id)
                end
                Registry.local_entities[ent] = nil
            end
        else
            -- only specific options
            for _, name in ipairs(optionNames) do
                local label = joaat_safe(name)
                local id = make_id("entity_" .. ent, GetInvokingResource(), label)
                GC.flag(id)

                for index, stored in pairs(Registry.local_entities[ent] or {}) do
                    if stored == label then
                        Registry.local_entities[ent][index] = nil
                    end
                end
            end
        end
    end
end

local function addModel(models, options)
    models = Util.ensureTable(models)

    for i = 1, #models do
        for index, value in ipairs(options) do
            if not Registry.models[models[i]] then
                Registry.models[models[i]] = {}
            end

            if value.label then
                Registry.models[models[i]][index] = joaat_safe(value.label)
                local id = make_id("model_" .. models[i], GetInvokingResource(), joaat_safe(value.label))
                Container.create({
                    id = id,
                    model = models[i],
                    options = convert_options {
                        value
                    },
                    maxDistance = value.distance,
                    schemaType = 'ox_target'
                })
            end
        end
    end
end

local function removeModel(models, optionNames)
    models = Util.ensureTable(models)
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for i = 1, #models do
        local model = models[i]

        if not optionNames then
            if Registry.models[model] then
                for _, label in pairs(Registry.models[model]) do
                    local id = make_id("model_" .. model, GetInvokingResource(), label)
                    GC.flag(id)
                end
                Registry.models[model] = nil
            end
        else
            -- only specific options
            for _, name in ipairs(optionNames) do
                local label = joaat_safe(name)
                local id = make_id("model_" .. model, GetInvokingResource(), label)
                GC.flag(id)

                for index, stored in pairs(Registry.models[model] or {}) do
                    if stored == label then
                        Registry.models[model][index] = nil
                    end
                end
            end
        end
    end
end

local function addEntity(netIds, options)
    local resource = GetInvokingResource()
    netIds = Util.ensureTable(netIds)

    for i = 1, #netIds do
        local netId = netIds[i]

        if NetworkDoesNetworkIdExist(netId) then
            for index, value in ipairs(options) do
                if not Registry.netIds[netIds[i]] then
                    Registry.netIds[netIds[i]] = {}
                end
                Registry.netIds[netIds[i]][index] = joaat_safe(value.label)
                local id = make_id("netId", resource, joaat_safe(value.label))
                Container.create({
                    id = id,
                    netId = netId,
                    options = convert_options {
                        value
                    },
                    maxDistance = value.distance,
                    schemaType = 'ox_target'
                })
            end
        end
    end
end

local function removeEntity(netIds, optionNames)
    local resource = GetInvokingResource()
    netIds = Util.ensureTable(netIds)
    optionNames = Util.ensureTable(optionNames)

    for _, net_id in ipairs(netIds) do
        if not optionNames then

        else
            for _, name in ipairs(optionNames) do
                local label = joaat_safe(name)
                local id = make_id("netId", resource, label)
                GC.flag(id)

                for index, stored in pairs(Registry.netIds[net_id] or {}) do
                    if stored == label then
                        Registry.netIds[net_id][index] = nil
                    end
                end
            end
        end
    end
end

local function disableTargeting(state)
    Interact.pause(state)
end

local function addGlobalObject(options)
    local resource = GetInvokingResource()
    options = options and Util.ensureTable(options) or nil

    for index, option in ipairs(options) do
        local id = make_id("netId", resource, joaat_safe(option.label))

        Container.createGlobal {
            id = id,
            type = 'entities',
            offset = vec3(0, 0, 0),
            maxDistance = option.distance,
            options = convert_options {
                option
            },
            schemaType = 'ox_target'
        }
    end
end

local function removeGlobalObject(optionNames)
    local resource = GetInvokingResource()
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for index, label in ipairs(optionNames) do
        local id = make_id("netId", resource, joaat_safe(label))
        GC.flag(id)
    end
end

local function addGlobalPed(options)
    local resource = GetInvokingResource()
    options = options and Util.ensureTable(options) or nil

    for index, option in ipairs(options) do
        local id = make_id("netId", resource, joaat_safe(option.label))

        Container.createGlobal {
            id = id,
            type = 'peds',
            offset = vec3(0, 0, 0),
            maxDistance = option.distance,
            options = convert_options {
                option
            },
            schemaType = 'ox_target'
        }
    end
end

local function removeGlobalPed(optionNames)
    local resource = GetInvokingResource()
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for index, label in ipairs(optionNames) do
        local id = make_id("netId", resource, joaat_safe(label))
        GC.flag(id)
    end
end

local function addGlobalPlayer(options)
    local resource = GetInvokingResource()
    options = options and Util.ensureTable(options) or nil

    for index, option in ipairs(options) do
        local id = make_id("netId", resource, joaat_safe(option.label))

        Container.createGlobal {
            id = id,
            type = 'players',
            offset = vec3(0, 0, 0),
            maxDistance = option.distance,
            options = convert_options {
                option
            },
            schemaType = 'ox_target'
        }
    end
end

local function removeGlobalPlayer(optionNames)
    local resource = GetInvokingResource()
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for index, label in ipairs(optionNames) do
        local id = make_id("netId", resource, joaat_safe(label))
        GC.flag(id)
    end
end

local function addGlobalVehicle(options)
    local resource = GetInvokingResource()
    options = options and Util.ensureTable(options) or nil

    for index, option in ipairs(options) do
        local id = make_id("netId", resource, joaat_safe(option.label))

        Container.createGlobal {
            id = id,
            type = 'vehicles',
            offset = vec3(0, 0, 0),
            maxDistance = option.distance,
            options = convert_options {
                option
            },
            schemaType = 'ox_target'
        }
    end
end

local function removeGlobalVehicle(optionNames)
    local resource = GetInvokingResource()
    optionNames = optionNames and Util.ensureTable(optionNames) or nil

    for index, label in ipairs(optionNames) do
        local id = make_id("netId", resource, joaat_safe(label))
        GC.flag(id)
    end
end

local function addSphereZone(data)
    local menu = {
        position = data.coords,
        tracker = "hit",
        zone = {
            type = 'circleZone',
            position = data.coords,
            radius = data.radius,
            useZ = true,
            debugPoly = data.debug
        },
        options = convert_options(data.options),
        schemaType = 'ox_target'
    }

    return Container.create(menu)
end

local function addBoxZone(data)
    local size    = data.size or vec3(1, 1, 1)
    local length  = size.y
    local width   = size.x
    local minZ    = data.coords.z - size.z
    local maxZ    = data.coords.z + size.z
    local heading = data.rotation or data.coords.w or 0
    local options = data.options or {}

    local menu    = {
        position = data.coords,
        tracker = "hit",
        offset = vec3(0, 0, 0),
        zone = {
            type = 'boxZone',
            position = data.coords,
            heading = heading,
            width = width,
            length = length,
            debugPoly = data.debug or false,
            minZ = minZ,
            maxZ = maxZ,
        },
        options = convert_options(options),
        schemaType = 'ox_target'
    }

    return Container.create(menu)
end

local function getCentroid(polygon)
    local centroid = vec3(0, 0, 0)
    local numPoints = #polygon

    for i = 1, numPoints do
        centroid = centroid + polygon[i]
    end

    return (centroid / numPoints)
end

local function addPolyZone(data)
    local thickness = data.thickness or 5.0
    local debug = data.debug or false
    local options = data.options or {}

    local minZ, maxZ = data.points[1].z, data.points[1].z
    for i = 2, #data.points do
        local z = data.points[i].z
        if z < minZ then minZ = z end
        if z > maxZ then maxZ = z end
    end

    local centerZ = (minZ + maxZ) / 2
    minZ = centerZ - thickness / 2
    maxZ = centerZ + thickness / 2

    local newPoints = table.create(#data.points, 0)
    for i = 1, #data.points do
        local point = data.points[i]
        newPoints[i] = vec3(point.x, point.y, centerZ)
    end

    local center = getCentroid(newPoints)

    local menu = {
        position = center,
        tracker = "hit",
        zone = {
            type = 'polyZone',
            points = data.points,
            minZ = minZ,
            maxZ = maxZ,
            debugPoly = debug,
        },
        options = convert_options(options),
        schemaType = 'ox_target'
    }

    return Container.create(menu)
end

local function removeZone(id)
    GC.flag(id)
end

-- global
replaceExport('addGlobalObject', addGlobalObject)
replaceExport('removeGlobalObject', removeGlobalObject)
replaceExport('addGlobalPed', addGlobalPed)
replaceExport('removeGlobalPed', removeGlobalPed)
replaceExport('addGlobalPlayer', addGlobalPlayer)
replaceExport('removeGlobalPlayer', removeGlobalPlayer)
replaceExport('addGlobalVehicle', addGlobalVehicle)
replaceExport('removeGlobalVehicle', removeGlobalVehicle)

-- entity
replaceExport('addModel', addModel)
replaceExport('removeModel', removeModel)
replaceExport('addEntity', addEntity)
replaceExport('removeEntity', removeEntity)
replaceExport('addLocalEntity', addLocalEntity)
replaceExport('removeLocalEntity', removeLocalEntity)

-- zones
replaceExport('addSphereZone', addSphereZone)
replaceExport('addBoxZone', addBoxZone)
replaceExport('addPolyZone', addPolyZone)
replaceExport('removeZone', removeZone)

replaceExport('disableTargeting', disableTargeting)
