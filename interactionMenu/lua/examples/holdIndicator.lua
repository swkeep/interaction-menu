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

function GetPlayerMoney()
    if GetResourceState('es_extended') == 'started' then
        local ESX = exports["es_extended"]:getSharedObject()
        local playerData = ESX.GetPlayerData()
        local cash = playerData.money or playerData.accounts?.money
        local bank = playerData.accounts?.bank
        return cash, bank
    elseif GetResourceState('qb-core') == 'started' then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local playerData = QBCore.Functions.GetPlayerData()
        return playerData.money["cash"], playerData.money["bank"]
    else
        return math.random(0, 1000000), math.random(0, 1000000)
    end
end

local function shorten(a)
    return a >= 1e6 and ("$%.1fM"):format(a / 1e6)
        or a >= 1e3 and ("$%.1fK"):format(a / 1e3)
        or "$" .. a
end

function GetFormattedMoney()
    local cash, bank = GetPlayerMoney()
    if not cash or not bank then return "N/A" end

    return ("%s | %s"):format(shorten(cash), shorten(bank))
end

local function init()
    menu_id = exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 270),
        position = vector4(795.0, -3002.15, -69.41, 90.68),
        scale = 1,
        indicator = {
            prompt = 'Press "E" to access options',
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
                label = 'Active Test: [####] ',
                bind = function()
                    return GetFormattedMoney()
                end
            },
            {
                label = '💵 Deposit Cash',
                description = 'Deposit money into your account',
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
                label = '💳 Check Balance',
                description = 'View your current balance',
                action = function()
                end
            },
            {
                label = '🔐 Safe Deposit Box',
                description = 'Access your private storage',
                action = function()
                end
            },
            {
                label = '📤 Transfer Money',
                description = 'Send money to another account',
                action = function()
                end
            },
            {
                label = '🏦 Loan Services',
                description = 'Apply for a bank loan',
                action = function()
                end
            }
        }
    }
end

local function cleanup()
    if not menu_id then return end
    exports['interactionMenu']:remove(menu_id)
end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "hold_indicator", "Hold Action Indicator", "fa-solid fa-stopwatch-20", "Test the hold action progress indicator UI element and its timing accuracy", {
        type = "blue",
        label = "UI"
    })
end)
