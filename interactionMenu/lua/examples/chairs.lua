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
local positions      = {
    vector4(794.00, -2991.52, -70.0, 0),
    vector4(796.50, -2991.52, -70.0, 0),
    vector4(799.00, -2991.52, -70.0, 0),
    vector4(801.50, -2991.52, -70.0, 0),
    vector4(804.00, -2991.52, -70.0, 0),
    vector4(806.50, -2991.52, -70.0, 0),
    vector4(809.00, -2991.52, -70.0, 0),

    vector4(794.00, -2997.10, -70.00, 180),
    vector4(796.50, -2997.10, -70.00, 180),
    vector4(799.00, -2997.10, -70.00, 180),
    vector4(801.50, -2997.10, -70.00, 180),
    vector4(804.00, -2997.10, -70.00, 180),
    vector4(806.50, -2997.10, -70.00, 180),
    vector4(809.00, -2997.10, -70.00, 180),

    vector4(794.54, -3002.94, -70.00, 0),
    vector4(798.54, -3002.94, -70.00, 0),
    vector4(801.04, -3002.94, -70.00, 0),
    vector4(803.54, -3002.94, -70.00, 0),
    vector4(806.04, -3002.94, -70.00, 0),
    vector4(808.54, -3002.94, -70.00, 0),

    vector4(794.00, -3008.70, -70.00, 180),
    vector4(796.50, -3008.70, -70.00, 180),
    vector4(799.00, -3008.70, -70.00, 180),
    vector4(801.50, -3008.70, -70.00, 180),
    vector4(804.00, -3008.70, -70.00, 180),
    vector4(806.50, -3008.70, -70.00, 180),
    vector4(809.00, -3008.70, -70.00, 180),
}

local chairs         = {
    "prop_table_02_chr",
    "prop_table_03_chr",
    "prop_table_03b_chr",
    "prop_table_04_chr",
    "apa_mp_h_stn_chairarm_01",
    "apa_mp_h_stn_chairarm_02",
    "apa_mp_h_stn_chairarm_03",
    "apa_mp_h_stn_chairarm_11",
    "apa_mp_h_stn_chairarm_12",
    "apa_mp_h_stn_chairarm_13",
    "apa_mp_h_stn_chairarm_23",
    "apa_mp_h_stn_chairarm_24",
    "apa_mp_h_stn_chairarm_25",
    "apa_mp_h_yacht_strip_chair_01",
    "bkr_prop_biker_boardchair01",
    "bkr_prop_biker_chair_01",
    "bkr_prop_clubhouse_armchair_01a",
    "bkr_prop_clubhouse_chair_01",
    "bkr_prop_clubhouse_offchair_01a",
    "bkr_prop_weed_chair_01a",
    "ex_mp_h_din_chair_04",
    "ex_mp_h_din_chair_08",
    "ex_mp_h_din_chair_09",
    "ex_mp_h_din_chair_12",
    "ex_prop_offchair_exec_01",
    "ex_prop_offchair_exec_02",
    "ex_prop_offchair_exec_03",
    "ex_prop_offchair_exec_04",
    "gr_prop_gr_chair02_ped",
    "gr_prop_gr_offchair_01a",
    "gr_prop_highendchair_gr_01a",
    "hei_heist_din_chair_01",
    "hei_heist_stn_chairarm_06",
    "hei_prop_hei_skid_chair",
    "imp_prop_impexp_offchair_01a",
    "p_armchair_01_s",
    "p_clb_officechair_s",
    "p_ilev_p_easychair_s",
    "p_soloffchair_s",
    "p_yacht_chair_01_s",
    "prop_armchair_01",
    "prop_chateau_chair_01",
    "prop_clown_chair",
    "prop_cs_office_chair",
    "prop_gc_chair02",
    "prop_old_deck_chair",
    "prop_old_wood_chair",
    "prop_old_wood_chair_lod",
    "prop_rock_chair_01",
    "prop_skid_chair_01",
    "prop_skid_chair_02",
    "prop_skid_chair_03",
    "prop_sol_chair",
    "prop_wheelchair_01",
}
local menus          = {}
local spawned_models = {}
local entities       = {}
local sitting        = false
local current_chair  = nil

local function stand_up()
    if not sitting then return end

    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)
    TaskStartScenarioInPlace(playerPed, "WORLD_HUMAN_STAND_IDLE", 0, true)
    FreezeEntityPosition(current_chair, true)
    Wait(500)
    sitting = false
    current_chair = nil
end

local function sit(entity)
    if sitting then return end
    sitting = true
    current_chair = entity
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local entityCoords = GetEntityCoords(entity)
    local heading = GetEntityHeading(entity) + 180.0

    FreezeEntityPosition(entity, true)
    TaskStartScenarioAtPosition(playerPed, "PROP_HUMAN_SEAT_BENCH", entityCoords.x, entityCoords.y, playerCoords.z - 0.5, heading, 0, true, true)
end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if not onScreen then return end
    local camCoords = GetGameplayCamCoord()
    local scale = 150 / (GetGameplayCamFov() * #(camCoords - vec3(x, y, z)))
    SetTextScale(scale or 0.35, scale or 0.35)
    SetTextFont(4)
    SetTextEntry("STRING")
    SetTextCentre(true)

    AddTextComponentString(text)
    DrawText(_x, _y)
end

local function init()
    for _, value in ipairs(positions) do
        local index = #entities + 1
        local model = chairs[math.random(1, #chairs)]
        entities[index] = Util.spawnObject(joaat(model), value)
        spawned_models[index] = { model, value }

        menus[#menus + 1] = exports['interactionMenu']:Create {
            tracker = 'boundingBox',
            entity = entities[index],
            dimensions = {
                vec3(-1, -1.5, -0.3),
                vec3(1, 1.5, 2)
            },
            options = {
                {
                    label = 'Sit',
                    action = function()
                        sit(entities[index])
                    end,
                    canInteract = function()
                        return not sitting
                    end
                },
                {
                    label = 'Stand Up',
                    action = stand_up,
                    canInteract = function()
                        return sitting
                    end
                },
            }
        }
        Wait(30)
    end

    CreateThread(function()
        while #spawned_models > 0 do
            for _, value in ipairs(spawned_models) do
                DrawText3D(value[2].x, value[2].y, value[2].z + 0.5, value[1])
            end
            Wait(0)
        end
    end)
end

local function cleanup()
    stand_up()

    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end

    entities = {}
    menus = {}
    spawned_models = {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "chair_test", "Lots of Chairs", "fa-solid fa-chair")
end)
