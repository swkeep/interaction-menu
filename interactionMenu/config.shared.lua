--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep

Config = {}

Config.framework = 'qb'

Config.interactionAudio = {
    mouseWheel = {
        audioName = 'NAV_UP_DOWN',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    },
    onSelect = {
        audioName = 'SELECT',
        audioRef = 'HUD_FRONTEND_DEFAULT_SOUNDSET'
    }
}

Config.features = {
    positionCorrection = true,
    time_based_theme_switch = true
}
