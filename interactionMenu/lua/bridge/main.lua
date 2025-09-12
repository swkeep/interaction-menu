local resource_name = GetCurrentResourceName()
local context = IsDuplicityVersion() and 'server' or 'client'

Bridge = {
    active = false,
    modules = {}
}

function string.split(str, pattern)
    pattern = pattern or "[^%s]+"
    local parts = {}
    for part in str:gmatch(pattern) do
        table.insert(parts, part)
    end
    return parts
end

local function load_module(module_name, dir)
    local path = ('%s.lua'):format(dir)
    local chunk = LoadResourceFile(resource_name, path)
    if not chunk then
        print(('[interactionMenu->bridge] ^1module not found: %s^0'):format(path))
        return nil
    end

    local fn, err = load(chunk)
    if not fn or err then
        print(('[interactionMenu->bridge] ^1error loading module %s: %s^0'):format(path, err))
        return nil
    end

    local result = fn()
    if result[context] then
        return result[context]()
    else
        return result
    end
end

local function link_module(module)
    local sub = module:split('[^.]+')
    local dir = ('lua/bridge/%s'):format(sub[1])
    return load_module(sub[1], dir)
end

local function load_bridge_modules(modules)
    for _, module_name in ipairs(modules) do
        local bridge_link = link_module(module_name)
        if bridge_link then
            Bridge.modules[module_name] = bridge_link
            print(('[interactionMenu->bridge] module loaded: %s'):format(module_name))
        else
            print(('[interactionMenu->bridge] ^1failed to load module: %s^0'):format(module_name))
        end
    end

    for _, key in ipairs({ "hasItem", "getJob", "getGang" }) do
        for _, mod in pairs(Bridge.modules) do
            if mod[key] then
                Bridge[key] = mod[key]
                break
            end
        end
    end

    Bridge.active = next(Bridge.modules) ~= nil
end

if GetResourceState('qb-core') == 'started' then
    load_bridge_modules({ "qb" })
end

if GetResourceState('es_extended') == 'started' then
    load_bridge_modules({ "esx" })
end
