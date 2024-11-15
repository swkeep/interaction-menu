--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

local function init()

end

local function cleanup()

end

CreateThread(function()
    InternalRegisterTest(init, cleanup, "1", "! Empty", "fa-solid fa-warehouse")
end)
