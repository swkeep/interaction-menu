return {
    client = function()
        local ESX = exports['es_extended']:getSharedObject()
        local playerData = ESX.GetPlayerData() or {}

        RegisterNetEvent('esx:playerLoaded', function(xPlayer)
            playerData = xPlayer
        end)

        RegisterNetEvent('esx:onPlayerLogout', function()
            playerData = {}
        end)

        RegisterNetEvent('esx:setJob', function(job)
            playerData.job = job
        end)

        return {
            ['getJob'] = function()
                local job = playerData['job']
                return job and job.name, job and job.grade
            end,
            ['getGang'] = function()
                return nil, nil
            end,
            ['hasItem'] = function(item_name, required_amount)
                required_amount = required_amount or 1

                local count = exports.ox_inventory:GetItemCount(item_name, nil, true)
                local has_item = count > 0
                local has_enough = count >= required_amount
                return has_item, has_enough
            end
        }
    end
}
