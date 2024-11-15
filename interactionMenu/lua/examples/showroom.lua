--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local menu_id = nil
local p = vector4(794.48, -3002.87, -69.41, 90.68)
local vehicle = nil
local current_category = nil
local vehicleCategories = {
    {
        category = "Sports",
        items = {
            { name = "reaper",  desb = "A high-performance supercar" },
            { name = "adder",   desb = "Luxury hypercar with immense speed" },
            { name = "comet",   desb = "Classic sports car with style and speed" },
            { name = "feltzer", desb = "Luxury sports car with great handling" },
        }
    },
    {
        category = "Muscle",
        items = {
            { name = "dominator", desb = "Classic American muscle car" },
            { name = "gauntlet",  desb = "Powerful and stylish muscle car" },
            { name = "dukes",     desb = "Old-school muscle with raw power" },
            { name = "blade",     desb = "Compact and powerful muscle car" },
        }
    },
    {
        category = "SUVs",
        items = {
            { name = "baller",      desb = "High-end luxury SUV" },
            { name = "cavalcade",   desb = "Large and rugged SUV" },
            { name = "granger",     desb = "Spacious SUV with off-road capabilities" },
            { name = "landstalker", desb = "Classic SUV with ample room" },
        }
    },
    {
        category = "Super",
        items = {
            { name = "zentorno", desb = "Aggressive styling and extreme speed" },
            { name = "osiris",   desb = "Stylish hypercar with incredible performance" },
            { name = "t20",      desb = "One of the fastest cars in GTA V" },
            { name = "entityxf", desb = "Swedish hypercar with great control" },
        }
    },
    {
        category = "OffRoad",
        items = {
            { name = "bifta",    desb = "Lightweight dune buggy for off-road fun" },
            { name = "rebel",    desb = "Rugged off-road truck" },
            { name = "sandking", desb = "Massive off-road truck" },
            { name = "blazer",   desb = "Quad bike for off-road exploration" },
        }
    },
    {
        category = "Motorcycles",
        items = {
            { name = "bati801",  desb = "High-speed sports motorcycle" },
            { name = "daemon",   desb = "Classic chopper-style motorcycle" },
            { name = "hakuchou", desb = "Superb speed and control" },
            { name = "sanchez",  desb = "Dirt bike for off-road action" },
        }
    },
    {
        category = "Sedans",
        items = {
            { name = "asterope", desb = "Reliable mid-size sedan" },
            { name = "emperor",  desb = "Classic sedan with a spacious interior" },
            { name = "fugitive", desb = "Four-door sedan with solid performance" },
            { name = "intruder", desb = "Luxury sedan with a refined feel" },
        }
    },
    {
        category = "Coupes",
        items = {
            { name = "cogcabrio", desb = "Luxury convertible coupe" },
            { name = "exemplar",  desb = "Sleek and stylish coupe" },
            { name = "oracle",    desb = "High-performance luxury coupe" },
            { name = "zion",      desb = "Sporty and compact coupe" },
        }
    },
    {
        category = "Compacts",
        items = {
            { name = "blista", desb = "Compact car with decent performance" },
            { name = "brioso", desb = "Small and nimble compact car" },
            { name = "issi",   desb = "Compact hatchback with quirky design" },
            { name = "panto",  desb = "Tiny city car that's easy to park" },
        }
    },
    {
        category = "Vans",
        items = {
            { name = "burrito",  desb = "Spacious van for group travel" },
            { name = "youga",    desb = "Classic van with a rugged look" },
            { name = "moonbeam", desb = "Retro-style van" },
            { name = "speedo",   desb = "Commercial van with good cargo space" },
        }
    },
    {
        category = "Industrial",
        items = {
            { name = "bulldozer", desb = "Powerful earthmoving vehicle" },
            { name = "dump",      desb = "Massive dump truck" },
            { name = "handler",   desb = "Heavy-duty forklift" },
            { name = "tiptruck",  desb = "Small dump truck" },
        }
    },
    {
        category = "Service",
        items = {
            { name = "taxi",        desb = "Standard taxi cab" },
            { name = "towtruck",    desb = "Vehicle for towing other cars" },
            { name = "trashmaster", desb = "Garbage truck used for waste collection" },
            { name = "ambulance",   desb = "Emergency medical vehicle" },
        }
    },
    {
        category = "Emergency",
        items = {
            { name = "police",    desb = "Standard police cruiser" },
            { name = "firetruk",  desb = "Fire truck used for emergencies" },
            { name = "ambulance", desb = "Medical emergency vehicle" },
            { name = "fbi2",      desb = "Undercover FBI SUV" },
        }
    },
    {
        category = "Military",
        items = {
            { name = "barracks",  desb = "Large military transport truck" },
            { name = "crusader",  desb = "All-terrain military vehicle" },
            { name = "rhino",     desb = "Heavily armored tank" },
            { name = "insurgent", desb = "Armored off-road vehicle" },
        }
    },
    {
        category = "Boats",
        items = {
            { name = "dinghy",  desb = "Lightweight boat with a motor" },
            { name = "jetmax",  desb = "High-speed boat" },
            { name = "marquis", desb = "Luxury yacht" },
            { name = "speeder", desb = "Sport boat with excellent speed" },
        }
    },
    {
        category = "Planes",
        items = {
            { name = "dodo",     desb = "Amphibious plane for air and water" },
            { name = "luxor",    desb = "Luxury private jet" },
            { name = "mammatus", desb = "Small, single-engine plane" },
            { name = "velum",    desb = "Light aircraft with good range" },
        }
    },
    {
        category = "Helicopters",
        items = {
            { name = "buzzard",  desb = "Light attack helicopter" },
            { name = "frogger",  desb = "Compact civilian helicopter" },
            { name = "maverick", desb = "Standard civilian helicopter" },
            { name = "savage",   desb = "Heavy-duty military helicopter" },
        }
    },
    {
        category = "Cycles",
        items = {
            { name = "bmx",      desb = "Light and versatile BMX bike" },
            { name = "cruiser",  desb = "Casual bicycle for city travel" },
            { name = "fixter",   desb = "Fixed-gear bike for city rides" },
            { name = "scorcher", desb = "Mountain bike for off-road" },
        }
    }
}

local function spawnVehicle(model)
    if vehicle then
        print("Vehicle already spawned!")
        return
    end
    local spawn_p = InternalGetTestSlot('middle', 2)
    vehicle = Util.spawnVehicle(model, spawn_p)
    if vehicle then
        SetVehicleNumberPlateText(vehicle, 'swkeep')
    else
        print("Failed to spawn vehicle.")
    end
end

local itemsPerPage = 6
local currentPage = 1
local pages = math.floor(#vehicleCategories / itemsPerPage)
if #vehicleCategories % itemsPerPage > 0 then
    pages = pages + 1
end

local options = {
    {
        label = "Page: #1 | Tottal: 6",
        bind = function()
            local text = "Page: #%s | Tottal: %s"
            return text:format(currentPage, pages)
        end
    }
}

table.insert(options, {
    label = "Back",
    icon = 'fa fa-arrow-left',
    action = function()
        current_category = nil
        exports['interactionMenu']:refresh()
    end,
    canInteract = function()
        return current_category ~= nil
    end
})

for index, entry in pairs(vehicleCategories) do
    local page = math.ceil(index / itemsPerPage)

    table.insert(options, {
        label = entry.category,
        icon = 'fa fa-circle',
        action = function()
            current_category = entry.category
            exports['interactionMenu']:refresh()
        end,
        canInteract = function()
            return current_category == nil and currentPage == page
        end
    })

    for _, v in ipairs(entry.items) do
        table.insert(options, {
            label = v.name,
            icon = 'fa fa-circle',
            description = v.desb,
            action = function()
                spawnVehicle(v.name)
                exports['interactionMenu']:refresh()
            end,
            canInteract = function()
                return current_category == entry.category
            end
        })
    end
end

table.insert(options, {
    label = 'Perv Page',
    icon = 'fa fa-arrow-left',
    action = function()
        currentPage = currentPage - 1
        if currentPage <= 0 then
            currentPage = 1
        end
        exports['interactionMenu']:refresh()
    end,
    canInteract = function()
        return current_category == nil
    end
})

table.insert(options, {
    label = 'Next Page',
    icon = 'fa fa-arrow-right',
    action = function()
        currentPage = currentPage + 1
        if currentPage >= pages then
            currentPage = pages
        end
        exports['interactionMenu']:refresh()
    end,
    canInteract = function()
        return current_category == nil
    end
})

table.insert(options, {
    label = 'Despawn',
    icon = 'fa fa-x',
    action = function()
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            vehicle = nil
        else
            print("No vehicle to despawn.")
        end
        exports['interactionMenu']:refresh()
    end,
    canInteract = function()
        return vehicle ~= nil
    end
})

local function init()
    menu_id = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 270),
        position = vector4(795.0, -3002.15, -69.41, 90.68),
        scale = 1,
        theme = 'box',
        width = '80%',
        zone = {
            type = 'boxZone',
            position = p,
            heading = p.w,
            width = 4.0,
            length = 4.0,
            debugPoly = Config.debugPoly or false,
            minZ = p.z - 1,
            maxZ = p.z + 2,
        },
        options = options
    }
end

local function cleanup()
    if menu_id then
        exports['interactionMenu']:remove(menu_id)
        menu_id = nil
    end
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        vehicle = nil
    end
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "car_showroom", "Showroom", "fa-solid fa-car-side")
end)
