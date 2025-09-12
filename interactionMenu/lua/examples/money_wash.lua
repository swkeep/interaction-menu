--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

local washingMachine = nil
local isWashing = false
local washProgress = 0
local washTime = 0
local dirtyAmount = 0
local cleanAmount = 0
local isMenuOpen = false
local menu_id = nil

local WASHING_MACHINE_MODEL = `prop_washer_01`
local WASHING_MACHINE_OFFSET = vector3(0, 0, 0.0)
local WASH_TIME_MIN = 1000 -- 30 seconds
local WASH_TIME_MAX = 5000 -- 60 seconds
local WASH_ANIM_DICT = "anim@amb@business@meth@meth_monitoring_cooking@monitoring@"
local WASH_ANIM_NAME = "look_around_v5_monitor"

local BUSINESS_NAMES = {
    "Blue Sky Laundry",
    "Crystal Clean Wash",
    "Ocean Breeze Cleaners",
    "Golden Suds Laundromat",
    "Prestige Wash & Fold",
    "Luxury Bubble Clean",
    "Executive Wash House",
    "Platinum Laundry Co."
}

local CLIENT_NAMES = {
    "James Wilson", "Maria Garcia", "Robert Johnson", "Sarah Lee",
    "Michael Brown", "Emily Davis", "David Miller", "Jessica Wilson",
    "Christopher Moore", "Amanda Taylor", "Matthew Anderson", "Ashley Thomas"
}

local TRANSACTION_TYPES = {
    "Standard Wash", "Delicate Cycle", "Heavy Duty", "Express Service",
    "Eco Wash", "Premium Treatment", "Executive Package", "VIP Service"
}

local function generateTransactionDetails()
    local business = BUSINESS_NAMES[math.random(1, #BUSINESS_NAMES)]
    local client = CLIENT_NAMES[math.random(1, #CLIENT_NAMES)]
    local transactionType = TRANSACTION_TYPES[math.random(1, #TRANSACTION_TYPES)]
    local amount = math.random(500, 2500)
    local fee = math.floor(amount * (math.random(10, 30) / 100))

    return {
        business = business,
        client = client,
        type = transactionType,
        amount = amount,
        fee = fee,
        timestamp = "%H:%M:%S"
    }
end

local recentTransactions = {}
local function addTransaction()
    table.insert(recentTransactions, 1, generateTransactionDetails())
    if #recentTransactions > 5 then
        table.remove(recentTransactions, 6)
    end
end

local function formatTransaction(transaction)
    return string.format([[
        <div style="margin-bottom: 10px; padding: 5px; background-color: rgba(0,0,0,0.2); border-radius: 3px;">
            <p style="margin: 0; font-size: 0.9em;"><strong>%s</strong> - %s</p>
            <p style="margin: 0; font-size: 0.8em;">Client: %s</p>
            <p style="margin: 0; font-size: 0.8em;">Amount: $%d | Fee: $%d</p>
            <p style="margin: 0; font-size: 0.7em; color: #aaa;">%s</p>
        </div>
    ]], transaction.business, transaction.type, transaction.client, transaction.amount, transaction.fee, transaction.timestamp)
end

local function formatAllTransactions()
    if #recentTransactions == 0 then
        return "<div style='text-align: center; padding: 10px; color: #aaa;'>No recent transactions</div>"
    end

    local html = ""
    for i, transaction in ipairs(recentTransactions) do
        html = html .. formatTransaction(transaction)
    end
    return html
end

local function startWashing()
    if isWashing then return end
    washTime = math.random(WASH_TIME_MIN, WASH_TIME_MAX)
    washProgress = 0
    isWashing = true

    RequestAnimDict(WASH_ANIM_DICT)
    while not HasAnimDictLoaded(WASH_ANIM_DICT) do
        Wait(10)
    end

    TaskPlayAnim(PlayerPedId(), WASH_ANIM_DICT, WASH_ANIM_NAME, 8.0, -8.0, -1, 1, 0, false, false, false)

    CreateThread(function()
        while isWashing and washProgress < 100 do
            washProgress = math.min(100, washProgress + (100 / (washTime / 1000)) * 0.1)
            Wait(100)
        end

        if washProgress >= 100 then
            isWashing = false
            dirtyAmount = 0
            cleanAmount = cleanAmount + math.random(5000, 15000)

            for i = 1, math.random(1, 3) do
                addTransaction()
            end

            print("success", "Money washing complete!", 3000)
        end

        StopAnimTask(PlayerPedId(), WASH_ANIM_DICT, WASH_ANIM_NAME, 1.0)
    end)
end

local function spawnWashingMachine()
    local spawnCoords = InternalGetTestSlot('front', 2)

    RequestModel(WASHING_MACHINE_MODEL)
    while not HasModelLoaded(WASHING_MACHINE_MODEL) do
        Wait(10)
    end

    washingMachine = CreateObject(WASHING_MACHINE_MODEL, spawnCoords.x, spawnCoords.y, spawnCoords.z, true, true, false)
    PlaceObjectOnGroundProperly(washingMachine)
    FreezeEntityPosition(washingMachine, true)
end

local function collectCleanMoney()
    if cleanAmount <= 0 then return end

    print("success", string.format("Collected $%d in clean money!", cleanAmount), 3000)
    cleanAmount = 0
    exports['interactionMenu']:refresh()
end

local function addDirtyMoney()
    local amountToAdd = math.random(1000, 5000)
    dirtyAmount = dirtyAmount + amountToAdd

    print("info", string.format("Added $%d in dirty money to wash", amountToAdd), 3000)
    exports['interactionMenu']:refresh()
end

local function init()
    spawnWashingMachine()

    menu_id = exports['interactionMenu']:Create({
        id = 'money_washing',
        theme = 'theme-2',
        entity = washingMachine,
        offset = WASHING_MACHINE_OFFSET,
        options = {
            {
                label = '💰 Money Laundering',
                description = 'Wash your dirty money clean',
                dynamic = true,
                bind = function()
                    return string.format([[
                        <div style='width: 100%%; text-align: left; padding: 5px;'>
                            <h3 style='margin-bottom: 10px; border-bottom: 1px solid #444; padding-bottom: 5px;'>
                            Money Washing Machine</h3>

                            <div style='margin-bottom: 15px;'>
                                <p><strong>Dirty Money:</strong> $%d</p>
                                <p><strong>Clean Money:</strong> $%d</p>
                            </div>

                            <div style='margin-bottom: 15px;'>
                                <p><strong>Wash Progress:</strong></p>
                                <div style='width: 100%%; background-color: rgba(0,0,0,0.3); height: 10px; border-radius: 5px;'>
                                    <div style='width: %d%%; background-color: %s; height: 100%%; border-radius: 5px;'></div>
                                </div>
                                <p style='text-align: center; font-size: 0.8em; margin-top: 3px;'>%d%%</p>
                            </div>

                            <div>
                                <h4 style='margin-bottom: 5px;'>Recent Transactions</h4>
                                %s
                            </div>
                        </div>
                    ]], dirtyAmount, cleanAmount, math.floor(washProgress),
                        isWashing and "#F44336" or "#4CAF50", math.floor(washProgress),
                        formatAllTransactions())
                end
            },
            {
                label = isWashing and '🛑 Stop Washing' or '🌀 Start Washing',
                icon = isWashing and 'fa-solid fa-stop' or 'fa-solid fa-play',
                description = isWashing and 'Stop the washing process' or 'Start washing dirty money',
                action = function()
                    if isWashing then
                        isWashing = false
                        washProgress = 0
                        print("info", "Washing stopped", 2000)
                    else
                        if dirtyAmount > 0 then
                            startWashing()
                        else
                            print("error", "No dirty money to wash!", 2000)
                        end
                    end
                end
            },
            {
                label = '💵 Add Dirty Money',
                icon = 'fa-solid fa-money-bill-wave',
                description = 'Add dirty money to the washing machine',
                action = addDirtyMoney
            },
            {
                label = '💰 Collect Clean Money',
                icon = 'fa-solid fa-hand-holding-usd',
                description = 'Collect your clean, laundered money',
                action = collectCleanMoney,
                disabled = cleanAmount <= 0
            }
        }
    })
end

local function cleanup()
    if DoesEntityExist(washingMachine) then
        DeleteEntity(washingMachine)
    end

    if menu_id then
        exports['interactionMenu']:remove(menu_id)
    end

    isWashing = false
    StopAnimTask(PlayerPedId(), WASH_ANIM_DICT, WASH_ANIM_NAME, 1.0)
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "money_washing", "Money Washing Machine", "fa-solid fa-money-bill-wave",
        "Press 'F6' to open/close the money washing menu", {
            type = "green",
            label = "Progress"
        })
end)
