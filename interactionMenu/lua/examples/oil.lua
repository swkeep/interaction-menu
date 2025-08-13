--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

-- Oil Well Management System
local menu_id = nil
local menu_positions = {
    main = vector4(794.48, -3002.87, -69.41, 90.68),
    extraction = vector4(794.48, -3005.87, -69.41, 90.68),
    refinement = vector4(797.48, -3002.87, -69.41, 90.68),
    storage = vector4(797.48, -3005.87, -69.41, 90.68),
    distribution = vector4(800.48, -3002.87, -69.41, 90.68),
    security = vector4(800.48, -3005.87, -69.41, 90.68)
}

local function create_menu(menu_type)
    local menus = {
        main = {
            rotation = vector3(-40, 0, 270),
            scale = 1,
            indicator = { prompt = 'Press "E" to manage oil wells', hold = 500 },
            options = {
                {
                    label = '🛢️ Oil Well Management',
                    description = 'Manage your oil operations',
                    dynamic = true,
                    bind = function()
                        local production = math.random(500, 2500)
                        local quality = math.random(70, 98)
                        local statuses = {
                            { name = "Operational",      color = "#4CAF50" },
                            { name = "Maintenance",      color = "#FFC107" },
                            { name = "High Yield",       color = "#8BC34A" },
                            { name = "Low Pressure",     color = "#FF9800" },
                            { name = "Needs Inspection", color = "#F44336" }
                        }
                        local status = statuses[math.random(1, #statuses)]

                        return ("<span style='width: 100%%;text-align:left;'>Production: <span style='color: #2196F3; font-weight: bold;'>%d bbl/day</span> </br> " ..
                            "Quality: <span style='color: #9C27B0; font-weight: bold;'>%d%%</span> </br> " ..
                            "Status: <span style='color: %s; font-weight: bold;'>%s</span></span>"):format(
                            production,
                            quality,
                            status.color,
                            status.name
                        )
                    end
                },
                {
                    label = '⛏️ Extraction Operations',
                    description = 'Manage oil extraction sites',
                    action = function() create_menu('extraction') end
                },
                {
                    label = '⚗️ Refinement Process',
                    description = 'Control oil refinement',
                    action = function() create_menu('refinement') end
                },
                {
                    label = '🗄️ Storage Facilities',
                    description = 'Access oil storage units',
                    action = function() create_menu('storage') end
                },
                {
                    label = '🚚 Distribution Network',
                    description = 'Manage oil distribution',
                    action = function() create_menu('distribution') end
                }
            }
        },
        extraction = {
            rotation = vector3(-40, 0, 270),
            scale = 1,
            indicator = { prompt = 'Press "E" to manage extraction', hold = 500 },
            options = {
                {
                    label = '⛏️ Active Extraction Sites',
                    description = 'View all active oil pumps',
                    dynamic = true,
                    bind = function() return ("Status: %s"):format(math.random() > 0.5 and "Operational" or "Maintenance") end
                },
                { label = '🔄 Start Extraction', description = 'Begin pumping oil', action = function() end },
                { label = '⏹️ Stop Extraction', description = 'Halt operations', action = function() end },
                { label = '🔧 Maintenance Mode', description = 'Routine maintenance', action = function() end },
                { label = '📊 Efficiency Report', description = 'Performance metrics', action = function() end },
                { label = '⬅️ Back to Main', action = function() create_menu('main') end }
            }
        },
        refinement = {
            rotation = vector3(-40, 0, 270),
            scale = 1,
            indicator = { prompt = 'Press "E" to manage refinement', hold = 500 },
            options = {
                {
                    label = '⚗️ Refinement Status',
                    description = 'Current operations',
                    dynamic = true,
                    bind = function()
                        return ("Quality: %d%% | Output: %dL"):format(math.random(70, 100), math.random(500, 2000))
                    end
                },
                { label = '🛢️ Process Crude Oil', description = 'Begin refinement', action = function() end },
                { label = '🛢️➡️⛽ Convert to Fuel', description = 'Produce gasoline', action = function() end },
                { label = '🧪 Quality Control', description = 'Adjust parameters', action = function() end },
                { label = '📦 Package Products', description = 'Prepare for distribution', action = function() end },
                { label = '⬅️ Back to Main', action = function() create_menu('main') end }
            }
        },
        storage = {
            rotation = vector3(-40, 0, 270),
            scale = 1,
            indicator = { prompt = 'Press "E" to access storage', hold = 500 },
            options = {
                {
                    label = '🗄️ Storage Capacity',
                    description = 'Current inventory',
                    dynamic = true,
                    bind = function()
                        return ("Crude: %dL | Fuel: %dL"):format(math.random(0, 50000), math.random(0, 30000))
                    end
                },
                { label = '📥 Deposit Oil', description = 'Add to storage', action = function() end },
                { label = '📤 Withdraw Oil', description = 'Remove from storage', action = function() end },
                { label = '🔒 Secure Storage', description = 'Manage security', action = function() end },
                { label = '🚨 Emergency Dump', description = 'Empty storage', action = function() end },
                { label = '⬅️ Back to Main', action = function() create_menu('main') end }
            }
        },
        distribution = {
            rotation = vector3(-40, 0, 270),
            scale = 1,
            indicator = { prompt = 'Press "E" to manage distribution', hold = 500 },
            options = {
                {
                    label = '🚚 Distribution Network',
                    description = 'Manage shipments',
                    dynamic = true,
                    bind = function()
                        return ("Active: %d | Completed: %d"):format(math.random(0, 5), math.random(5, 20))
                    end
                },
                { label = '📦 Schedule Delivery', description = 'Arrange transport', action = function() end },
                { label = '💰 Sell to Buyers', description = 'Negotiate sales', action = function() end },
                { label = '🛒 Local Market', description = 'Sell to stations', action = function() end },
                { label = '🌎 Export Options', description = 'International sales', action = function() end },
                { label = '⬅️ Back to Main', action = function() create_menu('main') end }
            }
        }
    }

    if menu_id then
        exports['interactionMenu']:remove(menu_id)
        menu_id = nil
    end

    local menu_config = menus[menu_type]
    menu_config.position = menu_positions[menu_type]
    menu_config.zone = {
        type = 'boxZone',
        position = menu_positions[menu_type],
        heading = menu_positions[menu_type].w,
        width = 2.5,
        length = 2.5,
        debugPoly = Config.debugPoly,
        minZ = menu_positions[menu_type].z - 1,
        maxZ = menu_positions[menu_type].z + 2
    }

    menu_id = exports['interactionMenu']:Create(menu_config)
end

local function init()
    create_menu('main')
end

local function cleanup()
    if menu_id then
        exports['interactionMenu']:remove(menu_id)
        menu_id = nil
    end
end

-- Register the test system
CreateThread(function()
    InternalRegisterTest(init, cleanup, "oil_management", "Oil Well Management", "fa-solid fa-oil-well")
end)
