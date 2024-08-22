--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

if not DEVMODE then return end

CreateThread(function()
    exports['interactionMenu']:create {
        player = 2,
        offset = vec3(0, 0, 0),
        maxDistance = 1.0,
        options = {
            {
                label = 'Just On Player Id: 2',
                icon = 'fa fa-person',
                action = function(entity)
                    print(entity)
                end
            }
        }
    }
end)
