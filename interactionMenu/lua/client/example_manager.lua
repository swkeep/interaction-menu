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

local test_slots = {
    front = {
        vector4(795.23, -3008.43, -69.41, 89.31),
        vector4(795.2, -3002.94, -69.41, 89.9),
        vector4(795.17, -2996.87, -69.41, 89.18)
    },
    middle = {
        vector4(800.21, -3008.53, -69.41, 90.93),
        vector4(800.93, -3003.08, -69.41, 89.2),
        vector4(800.55, -2996.81, -69.41, 90.42)
    },
    back = {
        vector4(806.36, -3008.67, -69.41, 90.76),
        vector4(806.75, -3002.84, -69.41, 90.15),
        vector4(806.96, -2997.04, -69.41, 89.18)
    }
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
  padding: 16px 20px;
  background: rgba(30,30,30,0.95);
  border-radius: 12px;
  border: 2px solid #666;
  box-shadow: 0 4px 8px rgba(0,0,0,0.4);
}

.menu-status .menu-label {
  font-weight: 700;
  color: #fff;
  font-size: 1.6rem;
  margin-bottom: 12px;
  text-shadow: 1px 1px 2px #000;
}

.menu-status .menu-value {
  font-size: 2.4rem;
  font-weight: 700;
  text-align: center;
  line-height: 2.4rem;
  min-height: 3rem;
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.test-badge-active {
  color: #00ff00;
  background: rgba(0,255,0,0.15);
  font-weight: bold;
  padding: 4px 8px;
  border-radius: 6px;
  display: inline-block;
  transition: transform 0.2s ease;
}

.test-badge-active:hover {
  transform: scale(1.2);
}

.test-badge-inactive {
  color: #ff5555;
  background: rgba(255,0,0,0.1);
  font-weight: bold;
  padding: 4px 8px;
  border-radius: 6px;
  display: inline-block;
  opacity: 0.7;
  transition: transform 0.2s ease;
}

.test-badge-inactive:hover {
  transform: scale(1.1);
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
        position = vector4(785.6, -2999.2, -68.5, 271.65),
        theme = 'theme-2',
        width = "100%",
        zone = {
            type = 'sphere',
            position = vector3(784.54, -2999.8, -69.0),
            radius = 1.25,
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
        width = "100%",
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
