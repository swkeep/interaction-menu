if not DEVMODE then return end
local active = false
local particleEffect = "scr_agencyheistb"
local particleName = "scr_agency3b_blding_smoke"
local particles = {}
local particlePositions = {
    -- vector4(794.00, -2991.52, -70.0, 0),
    -- vector4(796.50, -2991.52, -70.0, 0),
    -- vector4(799.00, -2991.52, -70.0, 0),
    -- vector4(801.50, -2991.52, -70.0, 0),
    -- vector4(804.00, -2991.52, -70.0, 0),
    -- vector4(806.50, -2991.52, -70.0, 0),
    -- vector4(809.00, -2991.52, -70.0, 0),

    vector4(794.00, -2997.10, -70.00, 180),
    -- vector4(796.50, -2997.10, -70.00, 180),
    vector4(799.00, -2997.10, -70.00, 180),
    -- vector4(801.50, -2997.10, -70.00, 180),
    vector4(804.00, -2997.10, -70.00, 180),
    -- vector4(806.50, -2997.10, -70.00, 180),
    vector4(809.00, -2997.10, -70.00, 180),

    -- vector4(794.54, -3002.94, -70.00, 0),
    -- vector4(798.54, -3002.94, -70.00, 0),
    -- vector4(801.04, -3002.94, -70.00, 0),
    -- vector4(803.54, -3002.94, -70.00, 0),
    -- vector4(806.04, -3002.94, -70.00, 0),
    -- vector4(808.54, -3002.94, -70.00, 0),

    -- vector4(794.00, -3008.70, -70.00, 180),
    -- vector4(796.50, -3008.70, -70.00, 180),
    -- vector4(799.00, -3008.70, -70.00, 180),
    -- vector4(801.50, -3008.70, -70.00, 180),
    -- vector4(804.00, -3008.70, -70.00, 180),
    -- vector4(806.50, -3008.70, -70.00, 180),
    -- vector4(809.00, -3008.70, -70.00, 180),
}

local function requestParticleAsset(asset)
    RequestNamedPtfxAsset(asset)
    while not HasNamedPtfxAssetLoaded(asset) do
        Citizen.Wait(0)
    end
end

local function init()
    if active then return end
    active = true

    requestParticleAsset(particleEffect)

    for _, position in pairs(particlePositions) do
        UseParticleFxAsset(particleEffect)
        particles[#particles + 1] = StartParticleFxLoopedAtCoord(
            particleName,
            position.x,
            position.y,
            position.z,
            0.0, -2.0, 0.8, 0.5, true, false, true, false
        )
        Wait(100)
    end
end

local function cleanup()
    for index, value in ipairs(particles) do
        StopParticleFxLooped(value, true)
        RemoveParticleFx(value, true)
    end

    particles = {}
    active = false
end

CreateThread(function()
    InternalRegisterGlobalTest(init, cleanup, "particle", "Toggle Particle")
end)
