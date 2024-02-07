RegisterNetEvent('interaction-menu:server:syncAnimation', function(target)
    local src = source

    TriggerClientEvent('interaction-menu:client:syncAnimation', target)
end)
