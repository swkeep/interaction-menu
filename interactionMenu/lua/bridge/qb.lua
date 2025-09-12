return {
    client = function()
        local QBCore = exports['qb-core']:GetCoreObject()
        local player_data = QBCore.Functions.GetPlayerData() or {}
        local qb_items = {}
        local use_ox = GetResourceState('ox_inventory') == 'started'

        local function update_player_items()
            Wait(100)

            player_data = QBCore.Functions.GetPlayerData()
            qb_items = {}

            for _, item_data in pairs(player_data.items or {}) do
                local name = item_data.name
                local amount = item_data.amount or 0
                local isWeapon = item_data.type == "weapon" or false

                if name then
                    if not qb_items[name] then
                        qb_items[name] = { amount = 0, isWeapon = isWeapon }
                    end
                    qb_items[name].amount = qb_items[name].amount + amount
                end
            end
        end

        AddEventHandler('QBCore:Client:OnPlayerLoaded', update_player_items)
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
            player_data = {}
        end)

        RegisterNetEvent('QBCore:Player:SetPlayerData', update_player_items)
        RegisterNetEvent('QBCore:Client:OnJobUpdate', update_player_items)
        RegisterNetEvent('QBCore:Client:OnGangUpdate', update_player_items)

        SetTimeout(1000, update_player_items)

        return {
            ['getJob'] = function()
                local job = player_data['job']
                return job.name, job.grade.level
            end,
            ['getGang'] = function()
                local gang = player_data['gang']
                return gang.name, gang.grade.level
            end,
            ['hasItem'] = function(item_name, required_amount)
                required_amount = required_amount or 1

                if use_ox then
                    local count = exports.ox_inventory:GetItemCount(item_name, nil, true)
                    local has_item = count > 0
                    local has_enough = count >= required_amount
                    return has_item, has_enough
                else
                    -- qb-core inventory
                    local item = qb_items[item_name]
                    local has_item = item ~= nil
                    local has_enough = has_item and item.amount >= required_amount or false
                    return has_item, has_enough
                end
            end
        }
    end
}
