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
local vehicle
local isMenuOpen = false

local VEHICLE_CLASS_NAMES = {
    [0] = "Compact",
    [1] = "Sedan",
    [2] = "SUV",
    [3] = "Coupe",
    [4] = "Muscle",
    -- [5] to [21] omitted for brevity
}

local LIGHT_STATUS = {
    [0] = "Off",
    [1] = "Low Beams",
    [2] = "High Beams"
}

local FOB_CONFIG = {
    defaultVehicle = `elegy`,
    fobOffset = vector3(0, 1.5, 0),
    fobRotation = vector3(0, 40, 330)
}

local vehicleInfo = {
    data = {}
}

local function spawnVehicleAtCoords(model, coords)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        print("Invalid vehicle model")
        return nil
    end

    RequestModel(model)
    local loadAttempts = 0
    while not HasModelLoaded(model) and loadAttempts < 100 do
        Wait(10)
        loadAttempts = loadAttempts + 1
    end

    if not HasModelLoaded(model) then
        print("Failed to load vehicle model")
        return nil
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
    SetModelAsNoLongerNeeded(model)

    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleDoorsLocked(vehicle, 1)
    SetVehicleEngineOn(vehicle, false, true, false)

    return vehicle
end

local function getVehicleDetails()
    if not DoesEntityExist(vehicle) then return {} end

    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local makeName = GetMakeNameFromVehicleModel(model)
    local class = GetVehicleClass(vehicle)

    -- Condition info
    local engineHealth = math.max(0, math.min(1000, GetVehicleEngineHealth(vehicle))) / 10
    local bodyHealth = math.max(0, math.min(1000, GetVehicleBodyHealth(vehicle))) / 10
    local fuelLevel = math.floor(GetVehicleFuelLevel(vehicle))
    local dirtLevel = math.floor(GetVehicleDirtLevel(vehicle) * 100 / 15)

    -- Status info
    local isLocked = GetVehicleDoorLockStatus(vehicle) > 1
    local isEngineOn = GetIsVehicleEngineRunning(vehicle)
    local lightStatusText = LIGHT_STATUS[IsVehicleInteriorLightOn(vehicle) and 2 or GetVehicleLightsState(vehicle)]

    -- Performance info
    local maxSpeed = GetVehicleModelMaxSpeed(model) * 3.6 -- Convert to km/h
    local acceleration = GetVehicleModelAcceleration(model)
    local handling = GetVehicleModelMaxBraking(model)

    -- Format the data
    vehicleInfo.data = {
        basic = {
            make = makeName,
            model = displayName,
            class = VEHICLE_CLASS_NAMES[class] or "Unknown",
            plate = GetVehicleNumberPlateText(vehicle)
        },
        condition = {
            engine = engineHealth,
            body = bodyHealth,
            fuel = fuelLevel,
            dirt = dirtLevel,
            color = GetVehicleCustomPrimaryColour(vehicle)
        },
        status = {
            locked = isLocked,
            engine = isEngineOn,
            lights = lightStatusText,
            doors = {}
        },
        performance = {
            topSpeed = maxSpeed,
            acceleration = acceleration,
            braking = handling
        }
    }

    -- Check door status
    for i = 0, 5 do
        if DoesVehicleHaveDoor(vehicle, i) then
            vehicleInfo.data.status.doors[i] = GetVehicleDoorAngleRatio(vehicle, i) > 0.0 and "Open" or "Closed"
        end
    end

    return vehicleInfo.data
end

local function formatVehicleDetails(details)
    if not details then return "No vehicle information available" end

    local function getConditionColor(value)
        return value > 70 and "#4CAF50" or value > 30 and "#FFC107" or "#F44336"
    end

    return string.format([[
<div style='width: 100%%; text-align: left; padding: 5px;'>
    <h3 style='margin-bottom: 10px; border-bottom: 1px solid #444; padding-bottom: 5px;'>
    <span style='color: %s;'>⬤</span> %s %s</h3>
    <p><strong>Class:</strong> %s</p>
    <p><strong>Plate:</strong> %s</p>
    <div style='display: flex; justify-content: space-between; margin-top: 15px;'>
        <div style='width: 48%%;'>
            <h4 style='margin-bottom: 5px;'>Condition</h4>
            <p><strong>Engine:</strong> <span style='color: %s;'>%d%%</span></p>
            <p><strong>Body:</strong> <span style='color: %s;'>%d%%</span></p>
            <p><strong>Fuel:</strong> %d%%</p>
            <p><strong>Cleanliness:</strong> %d%%</p>
        </div>
        <div style='width: 48%%;'>
            <h4 style='margin-bottom: 5px;'>Status</h4>
            <p><strong>Engine:</strong> <span style='color: %s;'>%s</span></p>
            <p><strong>Locks:</strong> <span style='color: %s;'>%s</span></p>
            <p><strong>Lights:</strong> %s</p>
            <p><strong>Color:</strong> <span style='color: %s;'>■</span> Custom</p>
        </div>
    </div>
    <div style='margin-top: 15px;'>
        <h4 style='margin-bottom: 5px;'>Performance</h4>
        <p><strong>Top Speed:</strong> %.1f km/h</p>
        <p><strong>Acceleration:</strong> %.2f</p>
        <p><strong>Braking:</strong> %.2f</p>
    </div>
</div>]],
        "#4CAF50",
        details.basic.make,
        details.basic.model,
        details.basic.class,
        details.basic.plate,
        getConditionColor(details.condition.engine),
        details.condition.engine,
        getConditionColor(details.condition.body),
        details.condition.body,
        details.condition.fuel,
        details.condition.dirt,
        details.status.engine and "#4CAF50" or "#F44336",
        details.status.engine and "Running" or "Off",
        details.status.locked and "#F44336" or "#4CAF50",
        details.status.locked and "Locked" or "Unlocked",
        details.status.lights,
        "#4CAF50",
        details.performance.topSpeed,
        details.performance.acceleration,
        details.performance.braking
    )
end

local function toggleDoor(doorIndex)
    if GetVehicleDoorAngleRatio(vehicle, doorIndex) > 0.0 then
        SetVehicleDoorShut(vehicle, doorIndex, false)
    else
        SetVehicleDoorOpen(vehicle, doorIndex, false, false)
    end
    vehicleInfo.lastUpdate = 0
end

local function toggleVehicleLocks()
    local currentStatus = GetVehicleDoorLockStatus(vehicle)
    if currentStatus == 1 then
        SetVehicleDoorsLocked(vehicle, 2)
    else
        SetVehicleDoorsLocked(vehicle, 1)
    end
    vehicleInfo.lastUpdate = 0
end

local function toggleEngine()
    local currentState = GetIsVehicleEngineRunning(vehicle)
    SetVehicleEngineOn(vehicle, not currentState, true, true)
    vehicleInfo.lastUpdate = 0
end

local function init()
    local start_pos = InternalGetTestSlot('front', 2)
    start_pos = vec4(start_pos.x, start_pos.y, start_pos.z - 0.5, start_pos.w)
    vehicle = spawnVehicleAtCoords(FOB_CONFIG.defaultVehicle, start_pos)

    if not vehicle then
        print("Failed to spawn vehicle")
        return
    end

    menu_id = exports['interactionMenu']:Create({
        id = 'vehicle_fob',
        type = 'manual',
        theme = 'theme-2',
        entity = PlayerPedId(),
        offset = FOB_CONFIG.fobOffset,
        rotation = FOB_CONFIG.fobRotation,
        triggers = {
            open = "vehicle:open_fob",
            close = "vehicle:close_fob"
        },
        options = {
            {
                label = '🚗 Vehicle Information',
                description = 'Detailed vehicle status',
                dynamic = true,
                bind = function()
                    return formatVehicleDetails(getVehicleDetails())
                end
            },
            {
                label = '🔒 Lock/Unlock',
                icon = 'fa-solid fa-key',
                description = 'Toggle vehicle locks',
                action = toggleVehicleLocks
            },
            {
                label = '🚪 Toggle Doors',
                icon = 'fa-solid fa-car-side',
                description = 'Open/close vehicle doors',
            },
            {
                label = 'Driver Door',
                action = function()
                    toggleDoor(0)
                end
            },
            {
                label = 'Passenger Door',
                action = function()
                    toggleDoor(1)
                end
            },
            {
                label = 'Toggle Engine',
                action = toggleEngine
            }
        }
    })

    RegisterKeyMapping('+togglevehfob', 'Toggle Vehicle FOB Menu', 'keyboard', 'F5')
    RegisterCommand('+togglevehfob', function()
        isMenuOpen = not isMenuOpen
        TriggerEvent(isMenuOpen and "vehicle:open_fob" or "vehicle:close_fob")
    end, false)
end

local function cleanup()
    if DoesEntityExist(vehicle) then
        DeleteEntity(vehicle)
    end

    if menu_id then
        exports['interactionMenu']:remove(menu_id)
    end
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "manual_menu", "Manual Menu Toggle", "fa-solid fa-cube",
        "Press 'F5' to open/close, press the key out side of green zones (polyzones)", {
            type = "dark-red",
            label = "F5"
        })
end)
