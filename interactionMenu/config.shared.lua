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

Config.devMode = false
Config.debugPoly = false

Config.provide = {
    ox_target = false,
    ox_target_test = false,
    qb_target = false,
    qb_target_test = false
}

Config.indicator = {
    enabled = true,
    eye_enabled = false,

    outline_enabled = false,
    outline_color = { 255, 255, 255, 255 },
}

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
    detection = 400
}

Config.icons = {
    'glowingball',
}

Config.screenBoundaryShape = 'none' -- circle/rectangle/none
Config.controls = {
    -- Note: Player have to to reset their key bindings to default for changes to take effect.

    -- What is this?
    -- This setting allows us to define controls for all menus.
    -- Enabling this feature, significantly improves performance (0.04ms to 0.01ms).
    enforce = true,
    interact = {
        -- https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
        defaultMapper    = 'KEYBOARD',
        defaultParameter = 'E'
    }
}
