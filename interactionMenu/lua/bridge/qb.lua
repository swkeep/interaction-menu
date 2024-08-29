local function updatePlayerItems(playerData, qb_items)
    for _, itemData in pairs(playerData.items or {}) do
        if qb_items[itemData.name] then
            qb_items[itemData.name] = qb_items[itemData.name] + itemData.amount
        else
            qb_items[itemData.name] = itemData.amount
        end
    end
end

local function reset(t) table.wipe(t) end

return {
    client = function()
        local QBCore = exports['qb-core']:GetCoreObject()
        local playerData = QBCore.Functions.GetPlayerData() or {}
        local qb_items = {}

        AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
            playerData = QBCore.Functions.GetPlayerData()
            reset(qb_items)
            updatePlayerItems(playerData, qb_items)
        end)

        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            playerData = {}
            reset(qb_items)
        end)

        RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
            playerData = QBCore.Functions.GetPlayerData()
            reset(qb_items)
            updatePlayerItems(playerData, qb_items)
        end)

        RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
            playerData = QBCore.Functions.GetPlayerData()
            reset(qb_items)
            updatePlayerItems(playerData, qb_items)
        end)

        RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)
            playerData = QBCore.Functions.GetPlayerData()
            reset(qb_items)
            updatePlayerItems(playerData, qb_items)
        end)

        local function init()
            playerData = QBCore.Functions.GetPlayerData()
            reset(qb_items)
            updatePlayerItems(playerData, qb_items)
        end

        init()

        return {
            ['getJob'] = function()
                local job = playerData['job']
                return job.name, job.grade.level
            end,
            ['getGang'] = function()
                local gang = playerData['gang']
                return gang.name, gang.grade.level
            end,
            ['hasItem'] = function(itemName, requiredAmount)
                if not requiredAmount then requiredAmount = 1 end
                local hasItem = qb_items[itemName] ~= nil
                local hasEnough = hasItem and qb_items[itemName] >= requiredAmount or false
                return hasItem, hasEnough
            end,
            ['hasItems'] = function(itemNames, requiredAmount)
                if not requiredAmount then requiredAmount = 1 end

                for _, itemName in pairs(itemNames) do
                    local hasItem = qb_items[itemName] ~= nil
                    local hasEnough = hasItem and qb_items[itemName] >= requiredAmount or false

                    if not hasEnough then
                        return false, itemName
                    end
                end

                return true
            end
        }
    end,
    server = function()

    end
}
