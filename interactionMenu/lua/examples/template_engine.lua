local menu_id = nil
local templates = {
    cash_register = [[
        <style>
        .menu-container { width:100%; padding: 20px; border-radius: 8px; box-shadow: 0 4px 15px rgba(0,0,0,0.3); font-family: sans-serif; }
        .menu-header { display: flex; align-items: center; margin-bottom: 15px; }
        .menu-icon { font-size: 1.8rem; margin-right: 10px; }
        .menu-title { font-weight: bold; font-size: 1.8rem; color: #ecf0f1; }
        .menu-subtitle { font-size: 1.6rem; color: #bdc3c7; }
        .menu-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
        .menu-cell { background: rgba(0,0,0,0.3); padding: 10px; border-radius: 6px; }
        .menu-label { font-size: 1.6rem; color: #bdc3c7; }
        .menu-value { font-weight: bold; font-size: 1.8rem; color: #fff; }
        .menu-span2 { grid-column: span 2; }
        </style>
        <div class="menu-container" style="background: linear-gradient(135deg, #2c3e50 0%, #3498db 100%);">
            <div class="menu-header">
                <span class="menu-icon">💰</span>
                <div>
                    <div class="menu-title">Cash Register</div>
                    <div class="menu-subtitle">Transaction #{{ transactionId }}</div>
                </div>
            </div>
            <div class="menu-grid">
                <div class="menu-cell">
                    <div class="menu-label">Subtotal</div>
                    <div class="menu-value">${{ subtotal }}</div>
                </div>
                <div class="menu-cell">
                    <div class="menu-label">Tax</div>
                    <div class="menu-value">${{ tax }}</div>
                </div>
                <div class="menu-cell menu-span2">
                    <div class="menu-label">Total</div>
                    <div class="menu-value">${{ total }}</div>
                </div>
                <div class="menu-cell menu-span2">
                    <div class="menu-label">Payment Method</div>
                    <div class="menu-value">{{ paymentMethod }}</div>
                </div>
            </div>
        </div>
    ]]
}

local function init()
    local spawnCoords = InternalGetTestSlot('front', 2)
    local options = {
        {
            label = 'New Transaction',
            icon = 'fa-solid fa-cash-register',
            description = 'Start a new sale transaction',
            action = function()
                print("Starting new transaction...")
            end,
            badge = { type = "green", label = "READY" }
        },
        {
            template = templates.cash_register,
            bind = function()
                local subtotal = math.random(100, 1000) / 10
                local tax = math.floor(subtotal * 0.08 * 100) / 100
                local total = subtotal + tax
                local paymentMethods = { "Cash", "Card", "Online" }

                return {
                    transactionId = math.random(1000, 9999),
                    subtotal = string.format("%.2f", subtotal),
                    tax = string.format("%.2f", tax),
                    total = string.format("%.2f", total),
                    paymentMethod = paymentMethods[math.random(1, #paymentMethods)]
                }
            end
        }
    }

    for i = 1, 25 do
        options[#options + 1] = {
            label = 'Options #' .. i,
            icon = 'fa-solid fa-lock',
            action = function() print("Locking register...") end,
            badge = { type = "red", label = "LOCK" }
        }
    end

    menu_id = exports['interactionMenu']:Create({
        id = 'cash_register',
        theme = 'theme-2',
        position = spawnCoords,
        zone = {
            type = 'boxZone',
            position = spawnCoords,
            heading = spawnCoords.w,
            width = 4.0,
            length = 4.0,
            debugPoly = Config.debugPoly,
            minZ = spawnCoords.z - 1,
            maxZ = spawnCoords.z + 2,
        },
        width = "100%",
        options = options
    })

    spawnCoords = InternalGetTestSlot('front', 3)

    local factory_status = {}
    local factory_refs = {}

    local active_template = '<span class="test-badge-active">%s</span>'
    local inactive_template = '<span class="test-badge-inactive">%s</span>'

    local function updateFactoryStatus()
        local status_text = ""
        for index, ref in pairs(factory_refs) do
            if ref.active then
                status_text = status_text .. active_template:format(ref.display_name)
            else
                status_text = status_text .. inactive_template:format(ref.display_name)
            end
        end
        factory_status = status_text
    end

    function RegisterFactorySystem(name, description, on_trigger, on_disable)
        factory_refs[#factory_refs + 1] = {
            display_name = name,
            description = description,
            init = on_trigger,
            cleanup = on_disable,
            active = false
        }
    end

    RegisterFactorySystem("Conveyor Belt", "Moves items along the line",
        function() print("Conveyor Belt Started") end,
        function() print("Conveyor Belt Stopped") end
    )
    RegisterFactorySystem("Assembler", "Assembles products",
        function() print("Assembler Activated") end,
        function() print("Assembler Deactivated") end
    )
    RegisterFactorySystem("Packaging", "Packages finished products",
        function() print("Packaging Machine On") end,
        function() print("Packaging Machine Off") end
    )

    local factory_menu_options = {
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
  <div class="menu-label">Factory Status</div>
  <div class="menu-value">{{{status}}}</div>
</div>
]],
            bind = function()
                updateFactoryStatus()
                return { status = factory_status }
            end
        }
    }

    for index, ref in pairs(factory_refs) do
        factory_menu_options[#factory_menu_options + 1] = {
            label = ref.display_name,
            description = ref.description,
            action = function()
                if ref.active then
                    ref.cleanup()
                else
                    ref.init()
                end
                ref.active = not ref.active
                updateFactoryStatus()
                exports['interactionMenu']:refresh()
            end
        }
    end

    exports['interactionMenu']:create {
        position = spawnCoords,
        theme = 'theme-2',
        width = "80%",
        zone = {
            type = 'boxZone',
            position = spawnCoords,
            heading = spawnCoords.w,
            width = 4.0,
            length = 4.0,
            debugPoly = Config.debugPoly,
            minZ = spawnCoords.z - 1,
            maxZ = spawnCoords.z + 2,
        },
        suppressGlobals = true,
        options = factory_menu_options
    }
end

local function cleanup()
    if menu_id then exports['interactionMenu']:remove(menu_id) end
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "template_test", "HTML Template Engine Test", "fa-solid fa-tv", "", {
        type = "dark-orange",
        label = "Feature"
    })
end)
