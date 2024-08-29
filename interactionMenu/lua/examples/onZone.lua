if not DEVMODE then return end

CreateThread(function()
    local position = vector4(-1967.13, 3188.71, 31.81, 58.08)
    local ent      = Util.spawnObject('sf_prop_sf_desk_laptop_01a', position)

    position       = vector4(-1967.13, 3188.71, 32.565, 240.0)
    ent            = Util.spawnObject('xm_prop_x17_laptop_lester_01', position)

    local p        = vector4(-1966.06, 3188.1, 32.81, 54.91)

    exports['interactionMenu']:Create {
        id = 'ZoneTest',
        rotation = vector3(-40, 0, 240),
        position = vector4(-1965.7, 3188.65, 32.81, 58.08),
        scale = 2,
        zone = {
            type = 'boxZone', -- entityZone/circleZone/polyZone/comboZone
            position = p,
            heading = p.w,
            width = 4.0,
            length = 6.0,
            debugPoly = Config.debugPoly,
            minZ = p.z - 1,
            maxZ = p.z + 1,
        },
        options = {
            {
                video = {
                    url = 'http://127.0.0.1:8080/1.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
            {
                label = 'Launch Trojan Horse',
                icon = 'fa fa-code',
                action = function(data)
                    print("Action 'Launch Trojan Horse'")
                end
            },
            {
                label = 'Disable Security Cameras',
                icon = 'fa fa-video-slash',
                action = function(data)
                    print("Action 'Disable Security Cameras'")
                end
            },
            {
                label = 'Override Access Control',
                icon = 'fa fa-key',
                action = function(data)
                    print("Action 'Override Access Control'")
                end
            },
            {
                label = 'Download Classified Files',
                icon = 'fa fa-download',
                action = function(data)
                    print("Action 'Download Classified Files'")
                end
            }
        }
    }

    exports['interactionMenu']:Create {
        id = 'ZoneTestCircleZone',
        rotation = vector3(-40, 0, 240),
        position = vector4(-1963.68, 3197.94, 32.81, 229.39),
        scale = 1,
        zone = {
            type = 'circleZone', -- entityZone/circleZone/polyZone/comboZone
            position = vector4(-1963.68, 3197.94, 32.81, 229.39),
            radius = 4.0,
            useZ = true,
            debugPoly = Config.debugPoly
        },
        options = {
            {
                video = {
                    url = 'http://127.0.0.1:8080/1.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
            {
                label = 'Launch Trojan Horse',
                icon = 'fa fa-code',
                action = function(data)
                    print("Action 'Launch Trojan Horse'")
                end
            },
            {
                label = 'Disable Security Cameras',
                icon = 'fa fa-video-slash',
                action = function(data)
                    print("Action 'Disable Security Cameras'")
                end
            },
            {
                label = 'Override Access Control',
                icon = 'fa fa-key',
                action = function(data)
                    print("Action 'Override Access Control'")
                end
            },
            {
                label = 'Download Classified Files',
                icon = 'fa fa-download',
                action = function(data)
                    print("Action 'Download Classified Files'")
                end
            }
        }
    }

    exports['interactionMenu']:Create {
        id = 'ZoneTestPoly',
        rotation = vector3(-40, 0, 240),
        position = vector4(-1959.3, 3204.88, 32.81, 136.58),
        scale = 1,
        zone = {
            type = 'polyZone', -- entityZone/circleZone/polyZone/comboZone
            points = {
                vector3(-1957.97, 3201.98, 32.81),
                vector3(-1962.4, 3204.19, 32.81),
                vector3(-1955.5, 3209.88, 32.81)
            },
            minZ = p.z - 1,
            maxZ = p.z + 1,
            debugPoly = Config.debugPoly,
        },
        options = {
            {
                video = {
                    url = 'http://127.0.0.1:8080/1.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
        }
    }

    local id = exports['interactionMenu']:Create {
        id = 'ZoneTestCombo',
        rotation = vector3(-40, 0, 240),
        position = vector4(-1968.99, 3211.78, 32.81, 329.05),
        scale = 1,
        zone = {
            type = 'comboZone', -- entityZone/circleZone/polyZone/comboZone
            zones = {
                {
                    type = 'boxZone',
                    position = vector4(-1970.6, 3208.92, 32.81, 327.89),
                    length = 2.0,
                    width = 2.0,
                    debugPoly = Config.debugPoly
                },
                {
                    type = 'circleZone',
                    position = vector4(-1965.52, 3212.53, 32.81, 61.94),
                    radius = 2.0,
                    useZ = true,
                    debugPoly = Config.debugPoly
                },
                {
                    type = 'circleZone',
                    position = vector4(-1970.43, 3215.39, 32.81, 57.17),
                    radius = 2.0,
                    useZ = true,
                    debugPoly = Config.debugPoly
                },
            },
        },
        options = {
            {
                video = {
                    url = 'http://127.0.0.1:8080/1.mp4',
                    loop = true,
                    autoplay = true,
                    volume = 0.1
                }
            },
        }
    }
end)
