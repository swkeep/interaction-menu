--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
if not DEVMODE then return end

local menus = {}
local centerPosition = vector4(-1977.17, 3170.62, 32.81, 60.87)
local names = { "Alice", "Bob", "Charlie", "David", "Eva", "Frank" }

CreateThread(function()
    Wait(500)

    for i = 1, 5, 1 do
        local options = {}

        for index = 1, math.random(2, 15), 1 do
            -- Select a random name from the list
            local randomName = names[math.random(1, #names)]
            options[#options + 1] = {
                icon   = "fas fa-sign-in-alt",
                label  = randomName,
                action = {
                    type = 'sync',
                    func = function()
                        Wait(5000)
                        print(randomName)
                    end
                }
            }
        end

        menus[#menus + 1] = {
            type = 'position',
            position = vec3(centerPosition.x - i, centerPosition.y + i, centerPosition.z),
            options = options,
            maxDistance = 2.0,
            syncedAction = true,
            extra = {
                onSeen = function()
                    print('seend')
                end
            }
        }
    end

    for key, value in pairs(menus) do
        exports['interactionMenu']:Create(value)
    end

    local controlPoint = vector4(-1986.96, 3179.94, 32.81, 242.64)
    local spawnedVehicles = {}

    local function DeleteAllSpawnedVehicles()
        for _, vehicle in ipairs(spawnedVehicles) do
            if DoesEntityExist(vehicle) then
                DeleteVehicle(vehicle)
                Wait(50)
            end
        end
        spawnedVehicles = {}
    end

    local spawnPoints = {}
    local numPoints = 20

    local centerPoint = vector3(-2000.4, 3194.12, 32.81)
    local radius = 12.0

    local function buildSpawnPoints(direction)
        -- Calculate spawn points in a circle
        spawnPoints = {}

        for i = 1, numPoints do
            local angle = (2 * math.pi / numPoints) * i
            local x = centerPoint.x + radius * math.cos(angle)
            local y = centerPoint.y + radius * math.sin(angle)
            local heading = math.deg(math.atan(centerPoint.y - y, centerPoint.x - x))
            if direction then
                heading = heading - 90
            else
                heading = heading + 90
            end
            if heading < 0 then
                heading = heading + 360
            end
            local spawnPoint = vector4(x, y, centerPoint.z, heading)
            table.insert(spawnPoints, spawnPoint)
        end
    end
    buildSpawnPoints(true)

    local vehicleList = {
        "adder",
        "bati",
        "comet2",
        "zentorno",
        "elegy2",
        "turismo2",
        "italigtb",
        "nero",
        "osiris",
        "tempesta",
        "t20",
        "voltic",
        "specter",
        "penetrator",
        "prototipo",
        "reaper",
        "xa21",
        "bullet",
        "infernus",
        "cheetah",
    }

    local function SpawnNextVehicle(point)
        local randomModel = vehicleList[math.random(1, #vehicleList)]

        local vehicle = Util.spawnVehicle(randomModel, point)
        table.insert(spawnedVehicles, vehicle)
        SetVehicleNumberPlateText(vehicle, 'swkeep')
    end

    local function SpawnVehiclesAtAllPoints()
        DeleteAllSpawnedVehicles()
        for _, point in ipairs(spawnPoints) do
            SpawnNextVehicle(point)
            Wait(0)
        end
    end

    local toggle = false
    CreateThread(function()
        while true do
            toggle = not toggle

            Wait(2000)
        end
    end)

    exports['interactionMenu']:Create {
        type = 'position',
        position = vector3(-1984.06, 3189.42, 32.81),
        maxDistance = 2.0,
        options = {
            {
                label = 'Delete All Vehicles',
                icon = 'fas fa-trash-alt',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        DeleteAllSpawnedVehicles()
                    end
                },
                canInteract = function()
                    return toggle
                end
            },
            {
                label = 'Vehicles Toward Center',
                icon = 'fas fa-long-arrow-alt-up',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        buildSpawnPoints(true)
                    end
                }
            },
            {
                label = 'Vehicles Outward from Center',
                icon = 'fas fa-long-arrow-alt-down',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        buildSpawnPoints(false)
                    end
                }
            }
        }
    }

    local id = exports['interactionMenu']:Create {
        type = 'position',
        position = vec3(controlPoint.x, controlPoint.y, controlPoint.z),
        maxDistance = 2.0,
        options = {
            {
                video = {
                    url = 'http://127.0.0.1:8080/AMV The Garden of Words Stay.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
            {
                label = 'Spawn Vehicles',
                icon = 'fas fa-car',
                canInteract = function()
                    return toggle
                end,
                action = {
                    type = 'sync',
                    func = function()
                        Wait(500)
                        SpawnVehiclesAtAllPoints()
                    end
                }
            },
            {
                label = 'Delete All Vehicles',
                icon = 'fas fa-trash-alt',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        DeleteAllSpawnedVehicles()
                    end
                }
            },
            {
                label = 'Vehicles Toward Center',
                icon = 'fas fa-long-arrow-alt-up',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        buildSpawnPoints(true)
                    end
                }
            },
            {
                label = 'Vehicles Outward from Center',
                icon = 'fas fa-long-arrow-alt-down',
                action = {
                    type = 'sync',
                    func = function()
                        Wait(1000)
                        buildSpawnPoints(false)
                    end
                }
            },
        }
    }

    SetTimeout(2000, function()
        exports['interactionMenu']:set {
            menuId = id,
            type = 'position',
            value = vector4(-1981.69, 3188.51, 32.81, 111.91)
        }
    end)

    -- SetTimeout(6000, function()
    --     exports['interactionMenu']:remove(id)
    -- end)
end)
