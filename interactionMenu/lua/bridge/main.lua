local resource_name = GetCurrentResourceName()

local LoadResourceFile = LoadResourceFile
local context = IsDuplicityVersion() and 'server' or 'client'

string.split = function(str, pattern)
    pattern = pattern or "[^%s]+"
    if pattern:len() == 0 then
        pattern = "[^%s]+"
    end
    local parts = { __index = table.insert }
    setmetatable(parts, parts)
    str:gsub(pattern, parts)
    setmetatable(parts, nil)
    parts.__index = nil
    return parts
end

local function loadModule(module_name, dir)
    local chunk = LoadResourceFile(resource_name, ('%s.lua'):format(dir))

    if chunk then
        local fn, err = load(chunk)
        if not fn or err then
            return error(('\n^1Error (%s): %s^0'):format(dir, err), 3)
        end

        local result = fn()

        return result[context]()
    end
end

---comment
---@param module string
local function link(module)
    local sub = module:split('[^.]+')
    local dir = ('lua/bridge/%s'):format(sub[1])
    return loadModule(sub[1], dir)
end

Bridge = {
    active = false
}

if GetResourceState('qb-core') == 'started' then
    local bridge_link = link('qb')
    Bridge.hasItem = bridge_link.hasItem
    Bridge.getJob = bridge_link.getJob
    Bridge.getGang = bridge_link.getGang
    Bridge.active = true
end
