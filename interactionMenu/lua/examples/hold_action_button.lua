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
local position = vector4(794.48, -3002.87, -69.41, 90.68)

local function get_player_money()
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports["es_extended"]:getSharedObject()
        local player_data = ESX.GetPlayerData()
        local cash = player_data.money or player_data.accounts?.money
        local bank = player_data.accounts?.bank
        return cash, bank
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local player_data = QBCore.Functions.GetPlayerData()
        return player_data.money["cash"], player_data.money["bank"]
    else
        return math.random(0, 1000000), math.random(0, 1000000)
    end
end

local function shorten_money(amount)
    if amount >= 1e6 then
        return ("$%.1fM"):format(amount / 1e6)
    elseif amount >= 1e3 then
        return ("$%.1fK"):format(amount / 1e3)
    else
        return "$" .. amount
    end
end

local function init_banking_menu()
    menu_id = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 270),
        position = vector4(795.0, -3002.15, -69.41, 90.68),
        indicator = {
            prompt = 'Press & Hold "E"',
            hold = 500,
        },
        zone = {
            type = 'boxZone',
            position = position,
            heading = position.w,
            width = 4.0,
            length = 4.0,
            debugPoly = Config.debugPoly,
            minZ = position.z - 1,
            maxZ = position.z + 2,
        },
        options = {
            {
                template = [[
<style>
.bank_info {
    padding: 20px;
    border-radius: 12px;
    background: linear-gradient(180deg, rgba(10,10,12,0.95), rgba(20,20,28,0.95));
    color: #e6eef3;
}
.bank_info__header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 14px;
}
.bank_info__title {
    font-size: 2.2rem;
    font-weight: 700;
    color: #00ffd6;
}
.bank_info__balance {
    font-size: 1.1rem;
    color: #cfe9e6;
    font-weight: 600;
}
.bank_info__section {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin-top: 12px;
}
.bank_info__label {
    font-size: 2rem;
    color: #bfeee0;
    margin-bottom: 4px;
}
.bank_info__value {
    font-size: 1.5rem;
    font-weight: 600;
    color: #00ffd6;
}
.bank_info__footer {
    margin-top: 16px;
    font-size: 0.9rem;
    color: #9fbfb8;
    text-align: center;
}
</style>

<div class="bank_info">
    <div class="bank_info__header">
        <div class="bank_info__title">Bank Account</div>
    </div>

    <div class="bank_info__section">
        <div class="bank_info__label">Cash</div>
        <div class="bank_info__value">{{cash}}</div>
    </div>

    <div class="bank_info__section">
        <div class="bank_info__label">Bank</div>
        <div class="bank_info__value">{{bank}}</div>
    </div>

    <div class="bank_info__footer">
        Your balances are updated in real-time. Manage your money wisely!
    </div>
</div>
]],
                bind = function()
                    local cash_amount, bank_amount = get_player_money()
                    return {
                        cash = shorten_money(cash_amount),
                        bank = shorten_money(bank_amount),
                    }
                end
            },
            {
                label = '💵 Deposit Cash',
                description = 'Deposit cash into your bank account',
                action = function()
                end
            },
            {
                label = '🏧 Withdraw Cash',
                description = 'Withdraw money from your account',
                action = function()
                end
            },
            {
                label = '📤 Transfer Money',
                description = 'Send money to another player',
                action = function()
                end
            },
        }
    }
end

local function cleanup_banking_menu()
    if menu_id then
        exports['interactionMenu']:remove(menu_id)
    end
end

CreateThread(function()
    InternalRegisterTest(init_banking_menu, cleanup_banking_menu, "hold_indicator", "Bank Interaction Menu (Hold action)", "fa-solid fa-piggy-bank",
        "Test the hold-to-interact banking UI element with real-time money display", {
            type = "blue",
            label = "UI"
        })
end)
