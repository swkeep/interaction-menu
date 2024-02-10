RegisterNetEvent('interaction-menu:server:syncAnimation', function(target)
    local src = source

    TriggerClientEvent('interaction-menu:client:syncAnimation', target)
end)

local QBCore = exports['qb-core']:GetCoreObject()
local jobNamesToCheck = { 'police', 'sheriff', 'detective' }

local function print_table(t)
    print(json.encode(t, { indent = true, sort_keys = true }))
end

local function getPlayerData(playerSrc)
    return QBCore.Functions.GetPlayer(playerSrc)
end

local function isPoliceOnDuty(playerData)
    local job = playerData.PlayerData.job
    for _, name in ipairs(jobNamesToCheck) do
        if job.name == name and job.onduty then
            return true
        end
    end
    return false
end

local function extractPlayerInfo(playerData)
    local charinfo = playerData.PlayerData.charinfo
    local metadata = playerData.PlayerData.metadata

    return {
        src = playerData.source,
        name = charinfo.firstname .. " " .. charinfo.lastname,
        grade = playerData.PlayerData.job.grade.name,
        callsign = metadata['callsign']
    }
end

-- Function to gather police player data
local function gatherPolicePlayerData()
    local data = {}
    local players = QBCore.Functions.GetPlayers()

    for _, player_src in pairs(players) do
        local playerData = getPlayerData(player_src)
        if playerData and isPoliceOnDuty(playerData) then
            data[player_src] = extractPlayerInfo(playerData)
        end
    end

    for i = 1, 10 do
        data[#data + 1] = {
            src = "fake_src_" .. i,
            name = "Fake Player " .. i,
            grade = "Detective",
            callsign = "FAKE-" .. i,
        }
    end

    return data
end

-- Main event handler
RegisterServerEvent("interaction-menu:server:police:refresh", function(ch, information)
    local src = source
    local policeData = gatherPolicePlayerData()

    print_table(information)

    TriggerClientEvent('interaction-menu:client:police:set', src, policeData)
end)

RegisterCommand("interactionMenu", function(source, args, rawCommand)
    TriggerClientEvent('interaction-menu:client:helper', source)
end, false)
