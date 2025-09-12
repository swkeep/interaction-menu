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
local selected_vehicle = nil

-- VEHICLE DATA
local vehicleCategories = {
    {
        category = "Sports",
        items = {
            { name = "reaper",  desc = "A high-performance supercar",             stats = { speed = 95, accel = 90, handling = 85 } },
            { name = "adder",   desc = "Luxury hypercar with immense speed",      stats = { speed = 100, accel = 92, handling = 80 } },
            { name = "comet",   desc = "Classic sports car with style and speed", stats = { speed = 88, accel = 85, handling = 83 } },
            { name = "feltzer", desc = "Luxury sports car with great handling",   stats = { speed = 90, accel = 87, handling = 88 } },
            { name = "ninef",   desc = "Agile German-engineered sports car",      stats = { speed = 89, accel = 86, handling = 87 } },
        }
    },
    {
        category = "Muscle",
        items = {
            { name = "dominator", desc = "Classic American muscle car",        stats = { speed = 85, accel = 82, handling = 70 } },
            { name = "gauntlet",  desc = "Powerful and stylish muscle car",    stats = { speed = 87, accel = 83, handling = 72 } },
            { name = "dukes",     desc = "Old-school muscle with raw power",   stats = { speed = 84, accel = 80, handling = 68 } },
            { name = "blade",     desc = "Compact and powerful muscle car",    stats = { speed = 82, accel = 78, handling = 65 } },
            { name = "vigero",    desc = "Retro muscle with aggressive looks", stats = { speed = 83, accel = 79, handling = 69 } },
        }
    },
    {
        category = "SUVs",
        items = {
            { name = "baller",      desc = "High-end luxury SUV",                  stats = { speed = 80, accel = 75, handling = 72 } },
            { name = "cavalcade",   desc = "Large and rugged SUV",                 stats = { speed = 77, accel = 70, handling = 68 } },
            { name = "granger",     desc = "Spacious SUV with off-road abilities", stats = { speed = 76, accel = 72, handling = 69 } },
            { name = "landstalker", desc = "Classic SUV with ample room",          stats = { speed = 75, accel = 71, handling = 67 } },
            { name = "huntley",     desc = "Luxury SUV with strong presence",      stats = { speed = 78, accel = 74, handling = 70 } },
        }
    },
    {
        category = "Super",
        items = {
            { name = "zentorno",  desc = "Aggressive styling and extreme speed",      stats = { speed = 99, accel = 94, handling = 88 } },
            { name = "osiris",    desc = "Stylish hypercar with incredible speed",    stats = { speed = 98, accel = 93, handling = 87 } },
            { name = "t20",       desc = "One of the fastest cars in GTA V",          stats = { speed = 100, accel = 95, handling = 89 } },
            { name = "entityxf",  desc = "Swedish hypercar with great control",       stats = { speed = 96, accel = 91, handling = 86 } },
            { name = "prototipo", desc = "Prototype hypercar with futuristic design", stats = { speed = 99, accel = 94, handling = 90 } },
        }
    },
    {
        category = "OffRoad",
        items = {
            { name = "bifta",       desc = "Lightweight dune buggy for off-road fun", stats = { speed = 74, accel = 82, handling = 80 } },
            { name = "rebel",       desc = "Rugged off-road truck",                   stats = { speed = 72, accel = 70, handling = 76 } },
            { name = "sandking",    desc = "Massive off-road truck",                  stats = { speed = 70, accel = 68, handling = 74 } },
            { name = "blazer",      desc = "Quad bike for exploration",               stats = { speed = 75, accel = 79, handling = 81 } },
            { name = "trophytruck", desc = "Racing truck made for desert",            stats = { speed = 78, accel = 80, handling = 82 } },
        }
    },
    {
        category = "Motorcycles",
        items = {
            { name = "bati801",  desc = "High-speed sports motorcycle",     stats = { speed = 96, accel = 92, handling = 86 } },
            { name = "daemon",   desc = "Classic chopper-style motorcycle", stats = { speed = 82, accel = 75, handling = 70 } },
            { name = "hakuchou", desc = "Superb speed and control",         stats = { speed = 97, accel = 93, handling = 88 } },
            { name = "sanchez",  desc = "Dirt bike for off-road action",    stats = { speed = 84, accel = 87, handling = 85 } },
            { name = "ruffian",  desc = "Sporty and reliable street bike",  stats = { speed = 90, accel = 88, handling = 82 } },
        }
    },
    {
        category = "Sedans",
        items = {
            { name = "asterope", desc = "Reliable mid-size sedan",                stats = { speed = 75, accel = 70, handling = 73 } },
            { name = "emperor",  desc = "Classic sedan with a spacious interior", stats = { speed = 70, accel = 65, handling = 68 } },
            { name = "fugitive", desc = "Four-door sedan with solid performance", stats = { speed = 78, accel = 72, handling = 74 } },
            { name = "intruder", desc = "Luxury sedan with a refined feel",       stats = { speed = 74, accel = 70, handling = 72 } },
            { name = "premier",  desc = "Budget sedan with decent handling",      stats = { speed = 73, accel = 68, handling = 71 } },
        }
    },
    {
        category = "Coupes",
        items = {
            { name = "cogcabrio", desc = "Luxury convertible coupe",         stats = { speed = 82, accel = 78, handling = 75 } },
            { name = "exemplar",  desc = "Sleek and stylish coupe",          stats = { speed = 84, accel = 80, handling = 76 } },
            { name = "oracle",    desc = "High-performance luxury coupe",    stats = { speed = 83, accel = 79, handling = 77 } },
            { name = "zion",      desc = "Sporty and compact coupe",         stats = { speed = 81, accel = 77, handling = 74 } },
            { name = "sentinel",  desc = "Reliable coupe with good balance", stats = { speed = 80, accel = 76, handling = 73 } },
        }
    },
    {
        category = "Compacts",
        items = {
            { name = "blista",     desc = "Compact car with decent performance",   stats = { speed = 72, accel = 70, handling = 75 } },
            { name = "brioso",     desc = "Small and nimble compact car",          stats = { speed = 73, accel = 72, handling = 74 } },
            { name = "issi",       desc = "Compact hatchback with quirky design",  stats = { speed = 71, accel = 70, handling = 73 } },
            { name = "panto",      desc = "Tiny city car that's easy to park",     stats = { speed = 70, accel = 69, handling = 72 } },
            { name = "dilettante", desc = "Hybrid compact with good fuel economy", stats = { speed = 69, accel = 67, handling = 71 } },
        }
    },
    {
        category = "Vans",
        items = {
            { name = "burrito",  desc = "Spacious van for group travel",        stats = { speed = 68, accel = 65, handling = 70 } },
            { name = "youga",    desc = "Classic van with a rugged look",       stats = { speed = 67, accel = 64, handling = 69 } },
            { name = "moonbeam", desc = "Retro-style van",                      stats = { speed = 66, accel = 63, handling = 68 } },
            { name = "speedo",   desc = "Commercial van with good cargo space", stats = { speed = 65, accel = 62, handling = 67 } },
            { name = "rumpo",    desc = "Utility van used for deliveries",      stats = { speed = 64, accel = 61, handling = 66 } },
        }
    }
}

local function spawnVehicle(model)
    if vehicle then
        DeleteEntity(vehicle)
        vehicle = nil
    end
    local spawn_p = InternalGetTestSlot("middle", 2)
    vehicle = Util.spawnVehicle(model, spawn_p)
    if vehicle then
        SetVehicleNumberPlateText(vehicle, "SWKEEP")
    end
end

local info_panel = {
    template = [[
<style>
.vehicle-info {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 20px;
  width: 100%;
}

.vehicle-info__preview-wrapper {
  display: flex;
  justify-content: center;
  width: 100%;
}

.vehicle-info__preview-img {
  width: 60%;
}

.vehicle-info__name {
  font-size: 1.8rem;
  font-weight: 700;
  color: #00ffcc;
  text-align: center;
}

.vehicle-info__desc {
  font-size: 1.2rem;
  color: #e0e0e0;
  text-align: center;
  line-height: 1.4;
}

.vehicle-info__stat {
  font-size: 1.1rem;
  color: #fff;
}

.vehicle-info__bar {
  display: inline-block;
  height: 12px;
  border-radius: 6px;
  background: rgba(255,255,255,0.1);
  width: 100%;
  margin-top: 4px;
  overflow: hidden;
}

.vehicle-info__bar-fill {
  height: 100%;
  background: linear-gradient(90deg, #00ffcc, #00ffaa);
  transition: width 0.4s ease;
}
</style>

<div class="vehicle-info">
  {{#if selected}}
    <div class="vehicle-info__preview-wrapper">
        <img class="vehicle-info__preview-img"
             src="https://docs.fivem.net/vehicles/{{name}}.webp" />
    </div>
  {{/if}}

  <div class="vehicle-info__name">{{name}}</div>
  <div class="vehicle-info__desc">{{desc}}</div>

  <div class="vehicle-info__stat">⚡ Speed
    <div class="vehicle-info__bar">
      <div class="vehicle-info__bar-fill" style="width: {{speed}}%;"></div>
    </div>
  </div>

  <div class="vehicle-info__stat">🚀 Acceleration
    <div class="vehicle-info__bar">
      <div class="vehicle-info__bar-fill" style="width: {{accel}}%;"></div>
    </div>
  </div>

  <div class="vehicle-info__stat">🚘 Handling
    <div class="vehicle-info__bar">
      <div class="vehicle-info__bar-fill" style="width: {{handling}}%;"></div>
    </div>
  </div>
</div>
]],
    bind = function()
        if not selected_vehicle then
            return { name = "Select a vehicle", desc = "Choose a car from the menu.", speed = 0, accel = 0, handling = 0, selected = false }
        end
        return {
            name = selected_vehicle.name,
            desc = selected_vehicle.desc,
            speed = selected_vehicle.stats.speed,
            accel = selected_vehicle.stats.accel,
            handling = selected_vehicle.stats.handling,
            selected = true
        }
    end
}

local options = { info_panel }

for _, entry in ipairs(vehicleCategories) do
    table.insert(options, {
        label = "📂 " .. entry.category,
        action = function()
            current_category = entry.category
            exports["interactionMenu"]:refresh()
        end,
        canInteract = function()
            return current_category == nil
        end
    })

    for _, v in ipairs(entry.items) do
        table.insert(options, {
            label = "🚘 " .. v.name,
            action = function()
                selected_vehicle = v
                spawnVehicle(v.name)
                exports["interactionMenu"]:refresh()
            end,
            canInteract = function()
                return current_category == entry.category
            end
        })
    end
end

table.insert(options, {
    label = "Back",
    icon = "fa fa-arrow-left",
    action = function()
        current_category = nil
        exports["interactionMenu"]:refresh()
    end,
    canInteract = function()
        return current_category ~= nil
    end
})

table.insert(options, {
    label = "Despawn Vehicle",
    icon = "fa fa-times",
    action = function()
        if vehicle and DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
            vehicle = nil
        end
        selected_vehicle = nil
        exports["interactionMenu"]:refresh()
    end,
    canInteract = function()
        return vehicle ~= nil
    end
})

local function init()
    menu_id = exports["interactionMenu"]:Create {
        rotation = vector3(-40, 0, 270),
        position = vector4(795.0, -3002.15, -69.41, 90.68),
        theme = "theme-2",
        width = "80%",
        skip_animation = true,
        zone = {
            type = "boxZone",
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
        exports["interactionMenu"]:remove(menu_id)
        menu_id = nil
    end
    if vehicle and DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
        vehicle = nil
    end
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "car_showroom", "Showroom", "fa-solid fa-car-side", "Preview each car's stats, speed, acceleration, and handling.", {
        type = "green",
        label = "Vehicle"
    })
end)
