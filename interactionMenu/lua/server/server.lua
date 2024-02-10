if not Config.devMode then return end
local function print_table(t)
    print(json.encode(t, { indent = true, sort_keys = true }))
end

RegisterNetEvent('interaction-menu:server:syncAnimation', function(target)
    local src = source

    TriggerClientEvent('interaction-menu:client:syncAnimation', target)
end)

RegisterCommand("interactionMenu", function(source, args, rawCommand)
    TriggerClientEvent('interaction-menu:client:helper', source)
end, false)

RegisterNetEvent('testEvent:server', function(payload, information)
    print_table(information)
end)
