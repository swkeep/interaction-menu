-- placeholder

Bridge = {}
local QBCore = exports['qb-core']:GetCoreObject()

local playerData = QBCore.Functions.GetPlayerData() or {}

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    playerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
    playerData = val
end)

function Bridge.getJob()
    local job = playerData['job']
    return job.name, job.grade.level
end

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()

end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)

end)

RegisterNetEvent('QBCore:Client:OnGangUpdate', function(GangInfo)

end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)

end)
