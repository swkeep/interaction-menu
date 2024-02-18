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

local function exportHandler(exportName, func)
    AddEventHandler(('__cfx_export_qb-target_%s'):format(exportName), function(setCB)
        setCB(func)
    end)
end

exportHandler('AddTargetEntity', function(entities, data)
    local menu = {
        entity = entities,
        options = {},
        maxDistance = data.distance or 3
    }

    if type(entities) == 'table' then

    else
        for key, value in pairs(data.options) do
            local option = {}
            menu.options[#menu.options + 1] = option

            if value.canInteract then
                option['canInteract'] = value.canInteract
            end

            if value.action then
                option['action'] = {
                    type = 'sync',
                    func = value.action
                }
            end

            option['icon'] = value.icon
            option['label'] = value.label
        end
    end

    exports['interactionMenu']:Create(menu)
end)

exportHandler('AddBoxZone', function(name, center, length, width, options, targetoptions)
    local menu = {
        id = name,
        position = center,
        options = {},
        maxDistance = targetoptions.distance or 3
    }

    for key, value in pairs(targetoptions.options) do
        local option = {}
        menu.options[#menu.options + 1] = option

        if value.canInteract then
            option['canInteract'] = value.canInteract
        end

        if value.action then
            option['action'] = {
                type = 'sync',
                func = value.action
            }
        elseif value.event then
            option['event'] = {
                type = value['type'],
                name = value['event']
            }
        end

        option['icon'] = value.icon
        option['label'] = value.label
    end

    exports['interactionMenu']:Create(menu)
end)
