if not DEVMODE then return end

-- -- isPointInside
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
        scale = 1,
        zone = {
            type = 'boxZone', -- entityZone/circleZone/polyZone/comboZone
            name = "onZoneTest",
            position = p,
            heading = p.w,
            width = 4.0,
            length = 6.0,
            debugPoly = true,
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
                label = 'Display On-Duty Officers',
                icon = 'fa fa-user-shield',
                event = {
                    name = 'interaction-menu:server:police:refresh',
                    type = 'server'
                }
            },
            {
                label = 'Launch Trojan Horse',
                icon = 'fa fa-code',
                action = {
                    type = 'async',
                    func = function(data)
                    end
                }
            },
            {
                label = 'Disable Security Cameras',
                icon = 'fa fa-video-slash',
                action = {
                    type = 'async',
                    func = function(data)
                    end
                }
            },
            {
                label = 'Override Access Control',
                icon = 'fa fa-key',
                action = {
                    type = 'async',
                    func = function(data)
                    end
                }
            },
            {
                label = 'Download Classified Files',
                icon = 'fa fa-download',
                action = {
                    type = 'async',
                    func = function(data)
                    end
                }
            }
        }
    }
end)
