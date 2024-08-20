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

Config.devMode = true

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

Config.intervals = {
    detection = 500
}

Config.features = {
    positionCorrection = true,
    timeBasedTheme = true,
    drawIndicator = {
        active = true
    }
}

Config.icons = {
    'stove',
    'stove2',
    'glowingball',
    'box',
    'wrench',
    'vending'
}
