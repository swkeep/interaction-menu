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

local menus, entities = {}, {}

local function init()
    local pos = InternalGetTestSlot("front", 2)
    entities[1] = Util.spawnObject(`xm_prop_xm_gunlocker_01a`, pos)

    menus[#menus + 1] = exports['interactionMenu']:Create {
        entity = entities[1],
        options = {
            -- Police
            {
                label = "Police: Evidence Locker",
                icon = "fa-solid fa-box-archive",
                job = { police = { 0, 1, 2, 3, 4 } },
                action = function()
                    print("Police accessed evidence locker")
                end
            },
            {
                label = "Police: Armory",
                icon = "fa-solid fa-gun",
                job = { police = { 2, 3, 4 } },
                action = function()
                    print("Police opened armory")
                end
            },

            -- EMS
            {
                label = "EMS: Medical Supplies",
                icon = "fa-solid fa-briefcase-medical",
                job = { ambulance = { 0, 1, 2 } },
                action = function()
                    print("EMS accessed medical supplies")
                end
            },
            {
                label = "EMS: Drug Cabinet",
                icon = "fa-solid fa-capsules",
                job = { ambulance = { 1, 2 } },
                action = function()
                    print("EMS opened drug cabinet")
                end
            },

            -- Mechanic
            {
                label = "Mechanic: Workshop Tools",
                icon = "fa-solid fa-wrench",
                job = { mechanic = { 0, 1, 2, 3, 4 } },
                action = function()
                    print("Mechanic accessed tools")
                end
            },
            {
                label = "Mechanic: Import Parts",
                icon = "fa-solid fa-car-burst",
                job = { mechanic = { 2, 3, 4 } },
                action = function()
                    print("Mechanic ordered import parts")
                end
            },

            -- Taxi
            {
                label = "Taxi: Dispatch Terminal",
                icon = "fa-solid fa-taxi",
                job = { taxi = { 0, 1, 2, 3 } },
                action = function()
                    print("Taxi driver checked dispatch terminal")
                end
            },

            -- Government
            {
                label = "Mayor’s Office: Vault Access",
                icon = "fa-solid fa-landmark",
                job = { government = { 3, 4 } },
                action = function()
                    print("Government official accessed vault")
                end
            }
        }
    }
end

local function cleanup()
    for _, menu_id in ipairs(menus) do
        exports['interactionMenu']:remove(menu_id)
    end
    for _, entity in ipairs(entities) do
        if DoesEntityExist(entity) then DeleteEntity(entity) end
    end
    menus, entities = {}, {}
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "job_restricted", "Job Restricted Menus", "fa-solid fa-briefcase", "job-restricted access demo", {
        type = "dark-orange",
        label = "Feature"
    })
end)
