CreateThread(function()
    local p = vector4(-1997.21, 3233.45, 32.81, 149.18)
    local prop_p = vector4(-2007.36, 3237.11, 31.81, 222.27)
    Util.spawnObject(`prop_speaker_01`, prop_p)

    local options = {
        {
            label = 'Back',
            icon = 'fa fa-arrow-left',
            action = function()
            end
        },
        {
            label = 'Stop',
            icon = 'fa fa-stop',
            action = function()
            end
        },
    }

    exports['interactionMenu']:Create {
        rotation = vector3(-40, 0, 120),
        position = vector4(-1998.86, 3233.18, 32.81, 331.04),
        scale = 1,
        -- theme = 'box',
        indicator = {
            prompt = 'Hold E',
            hold = 1000,
            -- Enter
            -- keyPress = {
            --     -- https://docs.fivem.net/docs/game-references/controls/#controls
            --     padIndex = 0,
            --     control = 18
            -- },
        },
        zone = {
            type = 'boxZone',
            position = p,
            heading = p.w,
            width = 10.0,
            length = 6.0,
            debugPoly = true,
            minZ = p.z - 1,
            maxZ = p.z + 8,
        },
        options = options
    }
end)
