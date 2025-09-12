--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local positions = {
    vector4(794.00, -2997.10, -69.00, 0),
    vector4(799.00, -2997.10, -69.00, 0),
    vector4(806.50, -2997.10, -69.00, 0),

    vector4(794.54, -3002.94, -69.00, 180),
    vector4(801.04, -3002.94, -69.00, 180),
    vector4(806.04, -3002.94, -69.00, 180),
    vector4(808.54, -3002.94, -69.00, 180),

    vector4(794.00, -3008.70, -69.00, 180),
    vector4(799.00, -3008.70, -69.00, 180),
    vector4(804.00, -3008.70, -69.00, 180),
    vector4(809.00, -3008.70, -69.00, 180),
}

local menus = {}
local icons = {
    'fa fa-rectangle-ad', 'fa fa-circle', 'fa fa-square', 'fa fa-star', 'fa fa-heart',
    'fa fa-bell', 'fa fa-flag', 'fa fa-check', 'fa fa-times', 'fa fa-thumbs-up'
}

local gtaLabels = {
    "Start Heist", "Enter Vehicle", "Visit Ammu-Nation", "Call Lester", "Switch Character",
    "Start Mission", "Join Crew", "Enter Safehouse", "Buy Weapon", "Vehicle Mod",
    "Check Wanted Level", "Change Outfit", "Check Map", "Enter Casino", "Toggle Radio",
    "Buy Property", "Get Bounty", "Call Mechanic", "Request Helicopter", "Start Chase"
}

local function generateOptions()
    local options = {}
    for i = 1, 100 do
        local random_label = gtaLabels[math.random(#gtaLabels)]
        local randomColor = string.format("rgb(%d, %d, %d)", math.random(0, 255), math.random(0, 255), math.random(0, 255))
        local label = string.format('<div style="color:%s;">%s</div>', randomColor, random_label)

        options[#options + 1] = {
            label = label,
            icon = icons[math.random(#icons)],
            action = function(entity)
                print("Selected action: " .. random_label)
            end
        }
    end
    return options
end

local function init()
    for menuIndex = 1, #positions do
        local pos = positions[menuIndex]
        local rot = vector3(-20, 0, -90)

        menus[#menus + 1] = exports["interactionMenu"]:paginatedMenu({
            itemsPerPage = 10,
            position = pos,
            rotation = rot,
            scale = 1,
            width = '80%',
            zone = {
                type = "sphere",
                position = pos,
                radius = 1.5,
                useZ = true,
                debugPoly = Config.debugPoly
            },
            options = generateOptions()
        })
    end
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end

    menus = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "npaginated_menu", "Paginated Menu", "fa-solid fa-list-ol", "", {
        type = "violet",
        label = "Extends"
    })
end)
