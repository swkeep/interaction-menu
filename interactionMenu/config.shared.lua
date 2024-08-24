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

Config.triggerZoneScript = 'PolyZone' -- ox_lib/PolyZone
Config.screenBoundaryShape = 'none'   -- circle/rectangle/none
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
