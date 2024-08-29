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

DUI                          = {
    scaleform = nil,
    status = 1
}

local function render_sprite(scaleform)
    -- DrawInteractiveSprite(txdName, txnName, 0.5, 0.5, 0.21, 0.55, 0.0, 255, 255, 255, 255)
    -- DrawSprite(txdName, txnName, 0.5, 0.5, 0.21, 0.55, 0.0, 255, 255, 255, 255) --draw in middle of screen
    SetDrawOrigin(scaleform.position.x, scaleform.position.y, scaleform.position.z, 0)
    DrawSprite(txdName, txnName, 0.0, 0.0, 0.21, 0.55, 0.0, 255, 255, 255, 255)
    ClearDrawOrigin()
end

local function cache3dScale(scale)
    cachedSx = scalex * (scale or 1)
    cachedSy = scaley * (scale or 1)
    cachedSz = scalez * (scale or 1)
end

local function render_3d(scaleform)
    DrawScaleformMovie_3dSolid(scaleform.sfHandle, scaleform.position.x, scaleform.position.y,
        scaleform.position.z + 1, scaleform.rotation.x, scaleform.rotation.y, scaleform.rotation.z, 2.0, 2.0, 1.0,
        cachedSx, cachedSy, cachedSz, 2)
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

local function set3d(value)
    DUI.scaleform['3d'] = value
end

local function setScale(value)
    DUI.scaleform['scale'] = value
    cache3dScale(value)
end

local function setStatus(status)
    local ref = DUI.scaleform.attached
    if status then
        localRender = render_sprite
        if DUI.scaleform['3d'] then
            localRender = render_3d
        end
    else
        localRender = nil
    end

    if ref and status == true then
        calculateWorldPosition(ref)
    end
    renderingIsActive = status
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
        pos = GetWorldPositionOfEntityBone(entity, ref.bone)
        setPosition(pos)
        return pos
    else
        pos = calculatePosition(entity, offset)
        -- setPosition(pos)
        return pos
    end
end

calculateWorldPosition = function(ref)
    if not DoesEntityExist(ref.entity) then
        renderingIsActive = false
        return
    end

    local entity = ref.entity
    local offset = ref.offset

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
    DUI:Create()

    local render = DUI.Render

    -- Tracking Thread
    CreateThread(function()
        local ref = DUI.scaleform.attached
        while true do
            if renderingIsActive and ref.entity then
                calculateWorldPosition(ref)
                Wait(tracking_interval)
            else
                Wait(500)
            end
        end
    end)

    while true do
        if renderingIsActive then
            render()
            Wait(0)
        else
            Wait(500)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= thisResource then return end

    DUI.Destroy()
end)
