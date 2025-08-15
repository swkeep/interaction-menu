--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local spawn = vector4(795.25, -3002.85, -69.41, 269.61)
local out = vector4(781.83, -2973.24, 5.39, 248.68)
local gate = vector3(816.53, -3001.47, -69.0)

local positions = {
    vector4(794.00, -2997.10, -70.00, -140),
    -- vector4(796.50, -2997.10, -70.00, 0),
    vector4(799.00, -2997.10, -70.00, -140),
    -- vector4(801.50, -2997.10, -70.00, 0),
    vector4(804.00, -2997.10, -70.00, -140),
    -- vector4(807.00, -2997.10, -70.00, 0),
    vector4(809.00, -2997.10, -70.00, -140),

    vector4(794.00, -3008.70, -70.00, -40),
    -- vector4(796.50, -3008.70, -70.00, 140),
    vector4(799.00, -3008.70, -70.00, -40),
    -- vector4(801.50, -3008.70, -70.00, 140),
    vector4(804.00, -3008.70, -70.00, -40),
    -- vector4(806.50, -3008.70, -70.00, 140),
    vector4(809.00, -3008.70, -70.00, -40),
}

local vehicle_models = { "adder", "zentorno", "t20", "infernus", "banshee", "turismor", "entityxf", "cheetah", "osiris" }
local entities = {}
local menus = {}

local function handleVehicleAction(index, position, target)
    DoScreenFadeOut(500)
    Wait(500)
    local playerped = PlayerPedId()
    TaskWarpPedIntoVehicle(playerped, entities[index], -1)
    SetEntityCoordsNoOffset(entities[index], target.x, target.y, target.z, false, false, false)
    SetEntityHeading(entities[index], target.w)
    FreezeEntityPosition(entities[index], false)
    DoScreenFadeIn(500)
end

local function returnVehicle(index, position)
    DoScreenFadeOut(500)
    Wait(500)
    local playerped = PlayerPedId()
    local pos = GetEntityCoords(playerped)
    SetEntityCoordsNoOffset(playerped, pos.x, pos.y, pos.z, false, false, false)
    SetEntityHeading(playerped, 0)
    SetEntityCoordsNoOffset(entities[index], position.x, position.y, position.z, false, false, false)
    SetEntityHeading(entities[index], position.w)
    DoScreenFadeIn(500)
end

local function canInteractAtDistance(index, position, distanceCheck)
    local pos = GetEntityCoords(entities[index])
    local distance = #(pos - vec3(position.x, position.y, position.z))
    return distanceCheck == "less" and distance < 2 or distanceCheck == "greater" and distance > 2
end

local function createMenu(index, position)
    return exports['interactionMenu']:Create {
        entity = entities[index],
        options = {
            {
                icon = "fa-solid fa-car",
                label = "Enter",
                canInteract = function()
                    return canInteractAtDistance(index, position, "less")
                end,
                action = function()
                    handleVehicleAction(index, position, spawn)
                end
            },
            {
                icon = "fa-solid fa-sign-out-alt",
                label = "Take Out",
                canInteract = function()
                    return canInteractAtDistance(index, position, "less")
                end,
                action = function()
                    handleVehicleAction(index, position, out)
                end
            },
            {
                icon = "fa-solid fa-arrow-alt-circle-left",
                label = "Return",
                canInteract = function()
                    return canInteractAtDistance(index, position, "greater")
                end,
                action = function()
                    returnVehicle(index, position)
                end
            },
        }
    }
end

local function init()
    for _, position in ipairs(positions) do
        local index = #entities + 1
        local randomVehicle = vehicle_models[math.random(#vehicle_models)]
        entities[index] = Util.spawnVehicle(randomVehicle, position)
        FreezeEntityPosition(entities[index], true)

        menus[#menus + 1] = createMenu(index, position)
        Wait(100)
    end
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    menus = {}
    entities = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "garage_example", "Garage System", "fa-solid fa-warehouse",
        "Spawns random vehicles that can be taken out and returned to their designated parking slots", {
            type = "green",
            label = "Vehicle"
        })
end)
