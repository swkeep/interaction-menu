--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local entity = nil
local sit = false
local menu_id = nil
local entities = {}

local function loadAnim(animation)
    RequestAnimDict(animation)
    while not HasAnimDictLoaded(animation) do
        Citizen.Wait(100)
    end
    return true
end

local function goThere(ped)
    local pos = vector3(815.74, -2991.26, -69.0)
    local intial_pos = GetEntityCoords(ped)

    TaskGoToCoordAnyMeans(ped, pos.x, pos.y, pos.z, 10.0, 0, 0, 0, 0)
    while true do
        local current_position = GetEntityCoords(ped)
        if #(current_position - pos) < 3 then
            break
        end

        Wait(100)
    end
    TaskGoToCoordAnyMeans(ped, intial_pos.x, intial_pos.y, intial_pos.z, 10.0, 0, 0, 0, 0)
    while true do
        local current_position = GetEntityCoords(ped)
        if #(current_position - intial_pos) < 3 then
            break
        end

        Wait(100)
    end
end

local function init()
    local max_health = 1000
    local start_pos = InternalGetTestSlot('front', 2)
    start_pos = vec4(start_pos.x, start_pos.y, start_pos.z - 0.5, start_pos.w)
    entity = Util.spawnPed(GetHashKey('u_m_y_juggernaut_01'), start_pos)
    SetEntityMaxHealth(entity, max_health)
    SetEntityHealth(entity, max_health)
    FreezeEntityPosition(entity, false)

    menu_id = exports['interactionMenu']:Create {
        tracker = 'boundingBox',
        dimensions = {
            vec3(-2, -2, -0.3),
            vec3(2, 2, 2)
        },
        entity = entity,
        offset = vector3(0, 0, 0.4),
        options = {
            {
                icon = 'fas fa-heart',
                label = "Health",
                progress = {
                    type = "info",
                    value = 0,
                    percent = true
                },
                bind = function(_entity, distance, coords, name, bone)
                    local max_hp = 100 - GetPedMaxHealth(entity)
                    local current_hp = 100 - GetEntityHealth(entity)

                    return math.floor((current_hp * 100) / max_hp)
                end
            },
            {
                icon = 'fas fa-map-marker-alt',
                label = 'Sit/Stand',
                action = function(entity)
                    -- local dict = 'creatures@retriever@amb@world_dog_sitting@idle_a'
                    -- local anim = 'idle_c'
                    local dict = 'anim@amb@business@bgen@bgen_no_work@'
                    local anim = 'sit_phone_phoneputdown_idle_nowork'

                    if not sit then
                        loadAnim(dict)
                        local flag = 0
                        TaskPlayAnim(entity, dict, anim, 8.0, 0, -1, flag or 1, 0, 0, 0, 0)
                        sit = true
                    else
                        StopAnimTask(entity, dict, anim, 1.0)
                        sit = false
                    end
                end
            },
            {
                icon = 'fas fa-map-marker-alt',
                label = 'Move',
                action = function(entity)
                    goThere(entity)
                end
            },
            {
                label = "Building Search (Police)",
                icon = 'fas fa-search',
                job = {
                    'police',
                    'k9'
                },
                action = function(entity)

                end
            },
            {
                label = "Apprehension (Police)",
                icon = 'fas fa-handcuffs',
                job = {
                    ['police'] = {},
                    'k9'
                },
                action = function(entity)

                end
            }
        }
    }
end

local function cleanup()
    DeleteEntity(entity)
    if not menu_id then return end
    exports['interactionMenu']:remove(menu_id)

    for index, entry in ipairs(entities) do
        DeleteEntity(entry.entity)
    end

    entities = {}
    menu_id = nil
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "entity_zone_test", "x Entity Zone", "fa-solid fa-cube")
end)
