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
        width = "100%",
        options = options
    })
end

local function cleanup()
    if menu_id then exports['interactionMenu']:remove(menu_id) end
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "template_test", "Template test", "fa-solid fa-tv",
        "Press 'F6' to open/close the TV menu", { type = "blue", label = "TV Control" })
end)
