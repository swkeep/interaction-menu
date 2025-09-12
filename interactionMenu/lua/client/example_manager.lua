--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

local selected_test = 1
local test_refs = {}
local global_test_refs = {}
local global_status = ""
local active_template = '<span class="test-badge-active">%s</span>'
local inactive_template = '<span class="test-badge-inactive">%s</span>'

local function generate_slots(base, step, count)
    local slots = {}
    for i = 0, count - 1 do
        slots[#slots + 1] = base + vector4(0.0, step * i, 0.0, 0)
    end
    return slots
end

local test_slots = {
    front = generate_slots(vector4(795.23, -3008.43, -70.0, 0.0), 5.5, 4),
    middle = generate_slots(vector4(800.21, -3008.53, -70.0, 0.0), 5.5, 4),
    back = generate_slots(vector4(806.36, -3008.67, -70.0, 90.76), 5.5, 4)
}

local function execute_in_thread(fn)
    if type(fn) ~= "function" then return false end
    CreateThread(fn)
end

local function load_selected_test()
    if not selected_test then return false end
    execute_in_thread(test_refs[selected_test].init)
end

local function unload_selected_test()
    if not selected_test then return false end
    execute_in_thread(test_refs[selected_test].cleanup)
end

local function update_global_status()
    global_status = ""
    for index, ref in pairs(global_test_refs) do
        if ref.active then
            global_status = global_status .. active_template:format(index)
        else
            global_status = global_status .. inactive_template:format(index)
        end
    end
end

function InternalGetTestSlot(slot_name, index)
    return test_slots[slot_name] and test_slots[slot_name][index] or nil
end

function InternalRegisterTest(init_fn, cleanup_fn, name, display_name, icon, description, badge)
    test_refs[#test_refs + 1] = {
        name = name,
        display_name = display_name,
        description = description,
        badge = badge,
        init = init_fn,
        cleanup = cleanup_fn,
        icon = icon
    }
end

function InternalRegisterGlobalTest(init_fn, cleanup_fn, name, display_name, icon, description, badge)
    global_test_refs[#global_test_refs + 1] = {
        name = name,
        display_name = display_name,
        description = description,
        badge = badge,
        init = init_fn,
        cleanup = cleanup_fn,
        icon = icon
    }
end

CreateThread(function()
    if not DEVMODE then return end
    Wait(250) -- wait for other examples to register

    table.sort(test_refs, function(a, b) return a.name < b.name end)

    local test_menu_options = {
        {
            template = [[
<style>
.menu-cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 10px;
  gap: 12px;
  background: rgba(40,40,40,0.0);
  border-radius: 12px;
}

.menu-span2 {
  width: 100%;
}

.menu-label {
  font-weight: 700;
  color: #fff;
  font-size: 1.4rem;
}

.menu-value {
  color: #00ffcc;
  font-size: 2.6rem;
  text-align: center;
  line-height: 1.1;
  min-height: 2.2rem;
}

.center-column {
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}
</style>
<div class="menu-cell menu-span2 center-column">
  <div class="menu-label">Selected Test</div>
  <div class="menu-value">{{active_menu}}</div>
</div>
]],
            bind = function()
                return {
                    active_menu = test_refs[selected_test] and test_refs[selected_test].display_name or "None",
                }
            end
        }
    }

    for index, test in pairs(test_refs) do
        test_menu_options[#test_menu_options + 1] = {
            label = ("[%02d] %s"):format(index, test.display_name),
            description = test.description,
            badge = test.badge,
            icon = test.icon,
            action = function()
                if selected_test == index then
                    unload_selected_test()
                    return
                end
                unload_selected_test()
                selected_test = index
                load_selected_test()
                exports['interactionMenu']:refresh()
            end
        }
    end

    if selected_test then load_selected_test() end

    local global_menu_options = {
        {
            template = [[
<style>
.menu-status {
  display: flex;
  width: 100%;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 18px 20px;
  background: linear-gradient(145deg, rgba(20,20,20,0.95), rgba(45,45,45,0.95));
  border-radius: 16px;
  border: 1px solid rgba(255,255,255,0.08);
  box-shadow: 0 6px 14px rgba(0,0,0,0.45);
  transition: all 0.3s ease-in-out;
}

.menu-status:hover {
  transform: translateY(-2px);
  box-shadow: 0 10px 20px rgba(0,0,0,0.6);
}

.menu-status .menu-label {
  font-weight: 600;
  color: #eaeaea;
  font-size: 1.4rem;
  margin-bottom: 10px;
  letter-spacing: 0.6px;
  text-shadow: 0 0 6px rgba(0,0,0,0.7);
}

.menu-status .menu-value {
  font-size: 2.1rem;
  font-weight: 700;
  text-align: center;
  min-height: 2.6rem;
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: center;
}

.test-badge-active {
  color: #00ff88;
  background: rgba(0,255,150,0.15);
  font-weight: 700;
  padding: 5px 10px;
  border-radius: 8px;
  display: inline-block;
  border: 1px solid rgba(0,255,150,0.25);
  text-shadow: 0 0 6px rgba(0,255,150,0.4);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.test-badge-inactive {
  color: #ff6666;
  background: rgba(255,50,50,0.12);
  font-weight: 700;
  padding: 5px 10px;
  border-radius: 8px;
  display: inline-block;
  border: 1px solid rgba(255,80,80,0.2);
  opacity: 0.8;
  text-shadow: 0 0 6px rgba(255,60,60,0.4);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}
</style>
<div class="menu-cell menu-span2 menu-status">
  <div class="menu-label">Global Test Status</div>
  <div class="menu-value">{{{status}}}</div>
</div>

]],
            bind = function()
                return { status = global_status }
            end
        }
    }

    for index, global_ref in pairs(global_test_refs) do
        global_menu_options[#global_menu_options + 1] = {
            label = ("[%d] %s"):format(index, global_ref.display_name),
            description = global_ref.description,
            icon = global_ref.icon,
            action = function()
                global_ref.active = not global_ref.active
                if global_ref.active then
                    execute_in_thread(global_ref.init)
                else
                    execute_in_thread(global_ref.cleanup)
                end
                update_global_status()
                exports['interactionMenu']:refresh()
            end
        }
    end

    update_global_status()

    exports['interactionMenu']:paginatedMenu {
        itemsPerPage = 11,
        offset = vector3(0, 0, 0),
        rotation = vector3(-20, 0, -90),
        position = vector4(785.0, -2999.2, -68.5, 271.65),
        theme = 'theme-2',
        width = "90%",
        zone = {
            type = 'sphere',
            position = vector3(784.54, -2999.8, -69.0),
            radius = 2,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        suppressGlobals = true,
        options = test_menu_options
    }

    exports['interactionMenu']:paginatedMenu {
        itemsPerPage = 10,
        offset = vector3(0, 0, 0),
        rotation = vector3(-20, 0, -90),
        position = vector3(785.5, -2996.2, -69.0),
        theme = 'theme-2',
        width = "80%",
        zone = {
            type = 'sphere',
            position = vector3(784.54, -2996.85, -69.0),
            radius = 1.25,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        suppressGlobals = true,
        options = global_menu_options
    }

    AddEventHandler('onResourceStop', function(resource)
        if resource ~= GetCurrentResourceName() then return end
        if selected_test and test_refs[selected_test] and test_refs[selected_test].cleanup then
            test_refs[selected_test].cleanup()
        end
    end)
end)
