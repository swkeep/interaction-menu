--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local thisResource           = GetCurrentResourceName()
local duiUrl                 = ("nui://%s/dui/index.html"):format(thisResource)
local width                  = 1000
local height                 = 1480
local txdName                = "keep_interaction" -- texture dictionary
local txnName                = "interaction_txn"  -- texture name

local SetDrawOrigin          = SetDrawOrigin
local DrawSprite             = DrawSprite
local ClearDrawOrigin        = ClearDrawOrigin
local GetEntityCoords        = GetEntityCoords
local Wait                   = Wait
local math_rad               = math.rad
local math_sin               = math.sin
local math_cos               = math.cos
local localRender
local calculateWorldPosition

local previousPosition       = vec3(0, 0, 0)
local tracking_interval      = 0
local scalex, scaley, scalez = 0.07, 0.04, 1
local renderingIsActive      = false
local cachedSx, cachedSy, cachedSz

local uiScale                = 1.0
local currentW, currentH
local scaled_width, scaled_height

DUI                          = {
    scaleform = nil,
    status = 1
}

local function render_sprite(scaleform)
    -- DrawInteractiveSprite(txdName, txnName, 0.5, 0.5, 0.21, 0.55, 0.0, 255, 255, 255, 255)
    -- DrawSprite(txdName, txnName, 0.5, 0.5, 0.21, 0.55, 0.0, 255, 255, 255, 255) --draw in middle of screen
    SetDrawOrigin(scaleform.position.x, scaleform.position.y, scaleform.position.z, 0)
    DrawSprite(txdName, txnName, 0.0, 0.0, scaled_width * uiScale, scaled_height * uiScale, 0.0, 255, 255, 255, 255)
    ClearDrawOrigin()
end

local function calculate_ui_scale(w, h)
    local aspect_ratio = w / h
    local width_scale = 0.375 / aspect_ratio
    local height_scale = 0.55

    if aspect_ratio > 1.7 then -- 16:9 ish and wider
        width_scale = math.max(0.16, width_scale)
    end

    if h >= 1440 then
        height_scale = 0.60
    elseif h >= 1200 then
        height_scale = 0.58
    elseif h <= 768 then
        height_scale = 0.55
    end

    width_scale = math.floor(width_scale * 100 + 0.5) / 100
    height_scale = math.floor(height_scale * 100 + 0.5) / 100

    return width_scale, height_scale
end

local function cache3dScale(scale)
    cachedSx = scalex * (scale or 1)
    cachedSy = scaley * (scale or 1)
    cachedSz = scalez * (scale or 1)
end

local function get_rotation_from_entity(entity)
    if not DoesEntityExist(entity) then return vector3(0, 0, 0) end

    local forwardVector = GetEntityForwardVector(entity)
    local pitch = -math.deg(math.asin(forwardVector.z))
    local yaw = math.deg(math.atan2(forwardVector.x, forwardVector.y))

    local finalRotation = vector3(
        pitch + DUI.scaleform.rotation.x,
        DUI.scaleform.rotation.y,
        yaw + DUI.scaleform.rotation.z
    )

    return finalRotation
end

local function render_3d(scaleform)
    if DUI.scaleform.lockToForward then
        local rotation = get_rotation_from_entity(scaleform.attached.entity)
        DrawScaleformMovie_3dSolid(scaleform.sfHandle, scaleform.position.x, scaleform.position.y,
            scaleform.position.z + 1, rotation.x, rotation.y, rotation.z, 2.0, 2.0, 1.0,
            cachedSx, cachedSy, cachedSz, 2)
    else
        DrawScaleformMovie_3dSolid(scaleform.sfHandle, scaleform.position.x, scaleform.position.y,
            scaleform.position.z + 1, scaleform.rotation.x, scaleform.rotation.y, scaleform.rotation.z, 2.0, 2.0, 1.0,
            cachedSx, cachedSy, cachedSz, 2)
    end
end

local function loadScaleform(scaleformName, timeout)
    local scaleformHandle = RequestScaleformMovie(scaleformName)
    timeout = timeout or 5000
    local startTime = GetGameTimer()

    while not HasScaleformMovieLoaded(scaleformHandle) and GetGameTimer() < startTime + timeout do
        Wait(0)
    end

    local loaded = HasScaleformMovieLoaded(scaleformHandle)
    if not loaded then warn('Scaleform failed to load: ' .. scaleformName) end

    return scaleformHandle, loaded
end

local function createTexture(duiHandle)
    local txd = CreateRuntimeTxd(txdName)
    local txn = CreateRuntimeTextureFromDuiHandle(txd, txnName, duiHandle)
    return txdName, txnName, txd, txn
end

local function enableScaleform(name)
    local sfHandle, loaded = loadScaleform(name)
    if not loaded then return end

    BeginScaleformMovieMethod(sfHandle, "SET_TEXTURE")
    -- 3d
    ScaleformMovieMethodAddParamTextureNameString(txdName)
    ScaleformMovieMethodAddParamTextureNameString(txnName)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(0)
    ScaleformMovieMethodAddParamInt(width)
    ScaleformMovieMethodAddParamInt(height)

    EndScaleformMovieMethod()
    return sfHandle
end

local function send(event, data)
    SendDuiMessage(DUI.scaleform.duiObject, json.encode({ action = event, data = data }))
end

local function setPosition(position)
    if DUI.scaleform.position == position then return end
    DUI.scaleform.position = vec3(position.x, position.y, position.z)
end

local function setRotation(rotation)
    if DUI.scaleform.rotation == rotation then return end
    DUI.scaleform.rotation = vec3(rotation.x, rotation.y, rotation.z)
end

local function setForwardVectorLock(value)
    DUI.scaleform['lockToForward'] = value
end

local function set3d(value)
    DUI.scaleform['3d'] = value
end

local function setScale(value)
    DUI.scaleform['scale'] = value
    cache3dScale(value)
end

local function setStatus(status)
    if not status then
        localRender = nil
        TriggerEvent("interaction_menu:stop_render")
        return
    end

    -- set render function type
    localRender = DUI.scaleform['3d'] and render_3d or render_sprite

    local ref = DUI.scaleform.attached
    if ref then
        calculateWorldPosition(ref)
    end

    TriggerEvent("interaction_menu:start_render")
end

local function attach(t)
    local dui = DUI.scaleform.attached

    if t.static then
        dui.static = true
        dui.offset = t.offset
        dui.entity = t.entity
    elseif t.entity and t.bone then
        dui.entity = t.entity
        dui.bone = t.bone
        dui.offset = t.offset
    else
        dui.entity = t.entity
        dui.bone = nil
        dui.offset = t.offset
    end
end

local function dettach()
    local dui = DUI.scaleform.attached

    dui.positionCalculated = nil
    dui.static = nil
    dui.entity = nil
    dui.bone = nil
end

local function Get()
    return DUI.scaleform
end
exports('Get', Get)

function DUI:Create()
    if self.scaleform then return self.scaleform end

    local scaleform = {
        name = 'interaction_renderer',
        occupied = false,
        duiObject = nil,
        duiHandle = nil,
        txdName = nil,
        txnName = nil,
        txd = nil,
        txn = nil,
        sfHandle = nil,
        position = vector3(0, 0, 0),
        rotation = vector3(0, 0, 0),
        lockToForward = false,
        attached = {
            entity = false,
            bone = false,
            offset = vec3(0, 0, 0)
        }
    }

    scaleform.duiObject = CreateDui(duiUrl, width, height)
    scaleform.duiHandle = GetDuiHandle(scaleform.duiObject)

    -- wait till dui is available or it's gonna show `!img`
    while not IsDuiAvailable(scaleform.duiObject) do Wait(0) end

    scaleform.txdName, scaleform.txnName, scaleform.txd, scaleform.txn = createTexture(scaleform.duiHandle)
    scaleform.sfHandle = enableScaleform(scaleform.name)

    scaleform.setPosition = setPosition
    scaleform.setRotation = setRotation
    scaleform.set3d = set3d
    scaleform.setScale = setScale
    scaleform.send = send
    scaleform.setStatus = setStatus
    scaleform.attach = attach
    scaleform.dettach = dettach
    scaleform.setForwardVectorLock = setForwardVectorLock

    DUI.scaleform = scaleform
end

function DUI.Render()
    local scaleform = DUI.scaleform
    if scaleform and localRender then
        localRender(scaleform)
    end
end

function DUI.Destroy()
    if not DUI.scaleform or not DUI.scaleform.duiObject then return end

    SetStreamedTextureDictAsNoLongerNeeded(txdName)
    RemoveReplaceTexture(txdName, txnName)
    DestroyDui(DUI.scaleform.duiObject)
end

local function getRotatedOffset(rotation, offset)
    rotation = math_rad(rotation)
    local sin_r = math_sin(rotation)
    local cos_r = math_cos(rotation)

    local x = offset.x * cos_r - offset.y * sin_r
    local y = offset.x * sin_r + offset.y * cos_r
    return x, y, offset.z
end

local function calculatePosition(entity, offset)
    local eRotation = GetEntityHeading(entity)
    local ro_x, ro_y, ro_z = getRotatedOffset(eRotation, offset)
    local currentPosition = GetEntityCoords(entity)
    local pos = vector3(currentPosition.x + ro_x, currentPosition.y + ro_y, currentPosition.z + ro_z)
    setPosition(pos)
    return pos
end

local function preCalculatePosition(ref, entity, offset)
    local pos

    if ref.bone then
        pos = GetEntityBonePosition_2(entity, ref.bone)
    else
        pos = calculatePosition(entity, offset)
    end

    -- Only apply rotation offset if there's actually an offset to apply
    if ref.offset and (ref.offset.x ~= 0 or ref.offset.y ~= 0 or ref.offset.z ~= 0) then
        local vehicleRotation = GetEntityHeading(entity)
        local ro_x, ro_y, ro_z = getRotatedOffset(vehicleRotation, ref.offset)
        pos = pos + vec3(ro_x, ro_y, ro_z)
    end

    setPosition(pos)
    return pos
end

calculateWorldPosition = function(ref)
    if not DoesEntityExist(ref.entity) then
        renderingIsActive = false
        return
    end

    local entity = ref.entity
    local offset = ref.offset or vec3(0, 0, 0)

    local currentPosition = GetEntityCoords(entity)

    -- Detect if the entity is static and set dynamic interval
    if previousPosition == vec3(0, 0, 0) then
        previousPosition = currentPosition
    elseif currentPosition == previousPosition then
        ref.static = true
        tracking_interval = 500
    else
        ref.static = false
        previousPosition = currentPosition
        tracking_interval = 0
    end

    if DUI.scaleform.lockToForward then
        ref.static = false
        tracking_interval = 0
    end

    -- If the entity is static and position not calculated yet -> update the position
    if ref.static and not ref.positionCalculated then
        ref.positionCalculated = preCalculatePosition(ref, entity, offset)
    end

    -- If the entity is not static -> update the position
    if not ref.static then
        ref.positionCalculated = preCalculatePosition(ref, entity, offset)
    end
end

CreateThread(function()
    -- for ref
    local RESOLUTION_TABLE = {
        -- Format: {w, h, scale, base_width, base_height}
        { w = 3840, h = 2160, scale = 1.2, width = 0.16, height = 0.60 },
        { w = 2560, h = 1440, scale = 1.1, width = 0.2,  height = 0.58 },
        { w = 1920, h = 1080, scale = 1.2, width = 0.21, height = 0.55 },
        { w = 1720, h = 1400, scale = 1.1, width = 0.28, height = 0.55 },
        { w = 1600, h = 1200, scale = 1.1, width = 0.28, height = 0.58 },
        { w = 1600, h = 900,  scale = 1.1, width = 0.21, height = 0.58 },
        { w = 1400, h = 900,  scale = 1.2, width = 0.23, height = 0.58 },
        { w = 1366, h = 768,  scale = 1.0, width = 0.21, height = 0.55 },
        { w = 1280, h = 720,  scale = 1.1, width = 0.21, height = 0.55 },
        { w = 1024, h = 768,  scale = 1.2, width = 0.27, height = 0.55 },
        { w = 800,  h = 600,  scale = 1.3, width = 0.27, height = 0.55 }
    }

    local savedScale       = GetResourceKvpFloat("ui_scale")
    if savedScale and savedScale >= 0.5 and savedScale <= 2.0 then
        uiScale = savedScale
    end
    print(("[InteractionDUI] Loaded scale: %.2f"):format(uiScale))

    currentW, currentH          = GetActiveScreenResolution()
    scaled_width, scaled_height = calculate_ui_scale(currentW, currentH)
    DUI:Create()
end)

AddEventHandler('interaction_menu:stop_render', function()
    -- just to be sure it's called internaly (for now!)
    if GetInvokingResource() ~= thisResource then return end
    renderingIsActive = false
end)

AddEventHandler('interaction_menu:start_render', function()
    -- just to be sure it's called internaly (for now!)
    if GetInvokingResource() ~= thisResource then return end
    if renderingIsActive then return end
    renderingIsActive = true

    local ref = DUI.scaleform.attached
    local render = DUI.Render

    -- update the scaleform resolution before render
    local newW, newH = GetActiveScreenResolution()
    scaled_width, scaled_height = calculate_ui_scale(newW, newH)

    -- Tracking Thread
    CreateThread(function()
        while renderingIsActive and ref.entity do
            calculateWorldPosition(ref)
            Wait(tracking_interval or 0)
        end
    end)

    -- Render Thread
    CreateThread(function()
        while renderingIsActive do
            render()
            Wait(0)
        end
    end)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= thisResource then return end

    DUI.Destroy()
end)

-- Commands
RegisterCommand("interaction_menu", function(source, args)
    TriggerEvent('chat:addSuggestion', '/interaction_menu', 'Adjust interaction menu settings', {
        { name = "action", help = "Available actions: 'scale'" },
        { name = "value",  help = "For scale: 0.5-2.0" }
    })

    if #args == 0 then
        TriggerEvent('chat:addMessage', {
            color = { 255, 255, 255 },
            multiline = true,
            args = { "Interaction Menu", "Usage:\n/interaction_menu scale [0.5-2.0] - Adjust UI scale" }
        })
        return
    end

    local subCommand = args[1]:lower()

    if subCommand == "scale" then
        local newScale = tonumber(args[2])

        if not newScale or newScale < 0.5 or newScale > 2.0 then
            TriggerEvent('chat:addMessage', {
                color = { 255, 0, 0 },
                args = { "Interaction Menu", "Invalid scale! Must be between 0.5 and 2.0" }
            })
            return
        end

        uiScale = newScale
        SetResourceKvpFloat("ui_scale", uiScale)
        TriggerEvent('chat:addMessage', {
            color = { 0, 255, 0 },
            args = { "Interaction Menu", string.format("UI scale set to %.2f", uiScale) }
        })
        TriggerEvent("InteractionDUI:client:update:ui_scale", uiScale)
    else
        TriggerEvent('chat:addMessage', {
            color = { 255, 0, 0 },
            args = { "Interaction Menu", "Unknown command. Use '/interaction_menu scale [0.5-2.0]'" }
        })
    end
end, false)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        TriggerEvent('chat:removeSuggestion', '/interaction_menu')
    end
end)
