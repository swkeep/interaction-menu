--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local selected = 1
local refs = {}  -- rooms
local refs2 = {} -- these are globals and effect all test rooms
local status = ""
local active_emoji = '|<span style="filter: hue-rotate(300deg);">%s</span>'
local disable_emoji = '|<span style="filter: hue-rotate(150deg);">%s</span>'
local emoji_numbers = {
    "1️⃣",
    "2️⃣",
    "3️⃣",
    "4️⃣",
    "5️⃣",
    "6️⃣",
    "7️⃣",
    "8️⃣",
    "9️⃣"
}
local test_slots = {
    front = {
        vector4(795.23, -3008.43, -69.41, 89.31),
        vector4(795.2, -3002.94, -69.41, 89.9),
        vector4(795.17, -2996.87, -69.41, 89.18)
    },
    middle = {
        vector4(800.21, -3008.53, -69.41, 90.93),
        vector4(800.93, -3003.08, -69.41, 89.2),
        vector4(800.55, -2996.81, -69.41, 90.42)
    },
    back = {
        vector4(806.36, -3008.67, -69.41, 90.76),
        vector4(806.75, -3002.84, -69.41, 90.15),
        vector4(806.96, -2997.04, -69.41, 89.18),
    }
}

local function execute_callback(fn)
    if type(fn) ~= "function" then return false end
    CreateThread(fn)
end

local function load()
    if not selected then return false end
    execute_callback(refs[selected].init)
end

local function unload()
    if not selected then return false end
    execute_callback(refs[selected].cleanup)
end

local function setStatus()
    status = ''
    for index, value in pairs(refs2) do
        if value.active then
            status = status .. active_emoji:format(emoji_numbers[index])
        else
            status = status .. disable_emoji:format(emoji_numbers[index])
        end
    end
    status = status .. "|"
end

function InternalGetTestSlot(name, index)
    return test_slots[name][index]
end

function InternalRegisterTest(init_func, cleanup_func, name, desb, icon)
    refs[#refs + 1] = {
        name = name,
        desb = desb,
        init = init_func,
        cleanup = cleanup_func,
        icon = icon
    }
end

function InternalRegisterGlobalTest(init_func, cleanup_func, name, desb, icon)
    refs2[#refs2 + 1] = {
        name = name,
        desb = desb,
        init = init_func,
        cleanup = cleanup_func,
        icon = icon
    }
end

CreateThread(function()
    Wait(250)

    local options = {
        {
            label = 'Active Test: [####] ',
            dynamic = true,
            bind = function()
                return ('Active Test [%s]'):format(refs[selected].desb)
            end
        }
    }

    table.sort(refs, function(a, b)
        return a.desb < b.desb
    end)

    for index, menu in pairs(refs) do
        options[#options + 1] = {
            label = ("[%02d] %s"):format(index, menu.desb),
            icon = menu.icon,
            action = function(data)
                if selected == index then
                    warn('already selected')
                    return
                end
                unload()
                selected = index
                load()
            end
        }
    end

    if selected then
        load()
    end

    local options2 = {
        {
            label = "",
            bind = function()
                return status
            end
        },
    }

    for index, ref in pairs(refs2) do
        options2[#options2 + 1] = {
            label = ref.desb,
            icon = ref.icon,
            action = function(data)
                if not ref.active then
                    ref.active = true
                    execute_callback(ref.init)
                else
                    ref.active = false
                    execute_callback(ref.cleanup)
                end
                setStatus()
                exports['interactionMenu']:refresh()
            end
        }
    end

    setStatus()

    exports['interactionMenu']:paginatedMenu {
        itemsPerPage = 10,
        offset = vector3(0, 0, 0),
        rotation = vector3(-20, 0, -90),
        position = vector4(785.6, -2999.2, -68.5, 271.65),
        scale = 1,
        width = "100%",
        zone = {
            type = 'sphere',
            position = vector3(784.54, -2999.8, -69.0),
            radius = 1.25,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        suppressGlobals = true,
        options = options
    }

    exports['interactionMenu']:paginatedMenu {
        itemsPerPage = 10,
        offset = vector3(0, 0, 0),
        rotation = vector3(-20, 0, -90),
        position = vector3(785.5, -2996.2, -69.0),
        scale = 1,
        width = "100%",
        zone = {
            type = 'sphere',
            position = vector3(784.54, -2996.85, -69.0),
            radius = 1.25,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        suppressGlobals = true,
        options = options2
    }

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        if not selected then return false end
        local ref = refs[selected]
        ref.cleanup()
    end)
end)
