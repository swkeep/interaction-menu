local scaleform
local text_color = { 255, 255, 255 }

local function Draw2DText(content, font, colour, scale, x, y)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(colour[1], colour[2], colour[3], 255)
    SetTextEntry("STRING")
    SetTextDropShadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextEdge(4, 0, 0, 0, 255)
    SetTextOutline()
    AddTextComponentString(content)
    DrawText(x, y)
end

local function handleArrowInput(center)
    local rot = GetGameplayCamRot(2)
    local heading = rot.z
    local delta = 0.05
    DisableControlAction(0, 36, true)
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
        delta = 0.01
    end

    DisableControlAction(0, 27, true)
    if IsDisabledControlPressed(0, 27) then -- arrow up
        local newCenter = PolyZone.rotate(center.xy, vector2(center.x, center.y + delta), heading)
        return vector3(newCenter.x, newCenter.y, center.z)
    end
    if IsControlPressed(0, 173) then -- arrow down
        local newCenter = PolyZone.rotate(center.xy, vector2(center.x, center.y - delta), heading)
        return vector3(newCenter.x, newCenter.y, center.z)
    end
    if IsControlPressed(0, 174) then -- arrow left
        local newCenter = PolyZone.rotate(center.xy, vector2(center.x - delta, center.y), heading)
        return vector3(newCenter.x, newCenter.y, center.z)
    end
    if IsControlPressed(0, 175) then -- arrow right
        local newCenter = PolyZone.rotate(center.xy, vector2(center.x + delta, center.y), heading)
        return vector3(newCenter.x, newCenter.y, center.z)
    end

    return center
end

local function handle_rotation(r, _type)
    local x, y, z = r.x, r.y, r.z
    local delta = 1.0

    DisableControlAction(0, 36, true)
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
        delta = 0.1
    end

    if _type == 'x' then
        -- Rotation around X-axis
        DisableControlAction(0, 174, true)
        if IsDisabledControlPressed(0, 174) then
            x = x + delta
        end
        DisableControlAction(0, 175, true)
        if IsDisabledControlPressed(0, 175) then
            x = x - delta
        end
    elseif _type == 'y' then
        -- Rotation around Y-axis
        DisableControlAction(0, 174, true)
        if IsDisabledControlPressed(0, 174) then
            y = y + delta
        end
        DisableControlAction(0, 175, true)
        if IsDisabledControlPressed(0, 175) then
            y = y - delta
        end
    elseif _type == 'z' then
        -- Rotation around Z-axis
        DisableControlAction(0, 174, true)
        if IsDisabledControlPressed(0, 174) then
            z = z + delta
        end
        DisableControlAction(0, 175, true)
        if IsDisabledControlPressed(0, 175) then
            z = z - delta
        end
    end


    return vec3(x, y, z)
end

local function handle_height(p)
    local delta = 0.05
    DisableControlAction(0, 36, true)
    if IsDisabledControlPressed(0, 36) then -- ctrl held down
        delta = 0.01
    end

    DisableControlAction(0, 27, true)
    if IsDisabledControlPressed(0, 27) then
        p = vector3(p.x, p.y, p.z + delta)
    end

    DisableControlAction(0, 173, true)
    if IsDisabledControlPressed(0, 173) then
        p = vector3(p.x, p.y, p.z - delta)
    end

    return p
end

CreateThread(function()
    Util.preloadSharedTextureDict()

    local timeout = 5000
    local startTime = GetGameTimer()

    repeat
        Wait(1000)
    until GetResourceState('interactionDUI') == 'started' or (GetGameTimer() - startTime >= timeout)

    if GetResourceState('interactionDUI') == 'started' then
        scaleform = exports['interactionDUI']:Get()
        scaleform.setPosition(vector3(0, 0, 0))
        scaleform.dettach()
        scaleform.setStatus(false)
    else
        print('ResourceState:', GetResourceState('interactionDUI'))
        error("interactionDUI resource did not start within the timeout period")
    end
end)

local function drawText(state)
    -- Display instructions
    Draw2DText("Press ~g~ENTER~w~ to Save | Press ~g~ESC~w~ to Exit | ~g~X~w~ to Reset", 4,
        text_color, 0.4, 0.43, 0.863)

    Draw2DText("Change Rotation Axis: ~g~E~w~ | Change Arrow: ~g~Q~w~ | Precision Mode: Hold ~g~Ctrl~w~", 4,
        text_color, 0.4, 0.43, 0.883)

    -- Display current settings
    Draw2DText(("Rotation Axis: ~g~%s~w~ | Movement Type: ~g~%s~w~"):format(
            string.upper(state.mousewheel),
            string.upper(state.arrow)), 4,
        text_color, 0.4, 0.43, 0.903)
end

local menuData = {
    id = '1231',
    loading = false,
    menus = {
        {
            id = 1,
            flags = {
                hide = false
            },
            options = {
                {
                    label = 'https',
                    picture = {
                        url =
                        'https://cdn.discordapp.com/attachments/1059914360887193711/1128867024827863121/photo-1610824224972-db9878a2fe2c.jpg',
                    },
                    flags = {
                        hide = false
                    },
                }
            }
        }
    },
    selected = { false }
}

local function showDemoInteraction(position, rotation)
    scaleform.setPosition(position)
    scaleform.setRotation(rotation)
    scaleform.set3d(true)
    scaleform.setScale(1)
    scaleform.setStatus(true)

    scaleform.send("interactionMenu:loading:hide")
    scaleform.send("interactionMenu:menu:show", {
        menus = menuData.menus,
        selected = 1
    })
end

local controls = {
    mousewheel = { 'x', 'y', 'z' },
    arrow = { 'position', 'height', 'rotation' }
}

local function hideScaleform()
    if not scaleform then return end
    scaleform.send("interactionMenu:hideMenu")
    scaleform.send("interactionMenu:loading:hide")
    exports['interactionMenu']:pause(false)
    scaleform.setStatus(false)
end

function Util.start(p, r)
    exports['interactionMenu']:pause(true)
    local ped = PlayerPedId()
    local state = {
        mousewheel = 'x',
        imousewheel = 1,
        arrow = 'position',
        iarrow = 1,
    }

    local position = p or GetEntityCoords(ped)
    local rotation = r or vec3(0, 0, 0)
    showDemoInteraction(position, rotation)

    while true do
        drawText(state)

        if state.arrow == 'position' then
            position = handleArrowInput(position)
            scaleform.setPosition(position)
        elseif state.arrow == 'height' then
            position = handle_height(position)
            scaleform.setPosition(position)
        elseif state.arrow == 'rotation' then
            rotation = handle_rotation(rotation, state.mousewheel)
            scaleform.setRotation(rotation)
        end

        if IsControlJustReleased(0, 38) then
            state.iarrow = state.iarrow % #controls.arrow + 1
            state.arrow = controls.arrow[state.iarrow]
        end

        DisableControlAction(0, 44, true)
        if IsDisabledControlJustPressed(0, 44) then
            state.imousewheel = state.imousewheel % #controls.mousewheel + 1
            state.mousewheel = controls.mousewheel[state.imousewheel]
        end

        if IsControlJustReleased(0, 154) then
            position = GetEntityCoords(ped)
            rotation = vec3(0, 0, 0)
        end

        if IsControlJustReleased(0, 191) then
            hideScaleform()
            return {
                ['position'] = position,
                ['rotation'] = rotation
            }
        end

        if IsDisabledControlPressed(0, 200) then
            hideScaleform()
            return 'exit'
        end

        Wait(0)
    end
end

RegisterNetEvent('interaction-menu:client:helper', function()
    Util.print_table(Util.start())
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then return end

    hideScaleform()
end)
