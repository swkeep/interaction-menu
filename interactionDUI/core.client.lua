--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local thisResource     = GetCurrentResourceName()
local duiUrl           = ("nui://%s/dui/index.html"):format(thisResource)
local width            = 1000
local height           = 1480
local txdName          = 'keep_interaction' -- texture dictionary
local txnName          = "interaction_txn"  -- texture name

local SetDrawOrigin    = SetDrawOrigin
local DrawSprite       = DrawSprite
local ClearDrawOrigin  = ClearDrawOrigin
local math_rad         = math.rad
local math_sin         = math.sin
local math_cos         = math.cos

local rederingIsActive = false

DUI                    = {
    scaleform = nil,
    status = 1
}

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

local function setStatus(status)
    rederingIsActive = status
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
    scaleform.send = send
    scaleform.setStatus = setStatus
    scaleform.attach = attach
    scaleform.dettach = dettach

    DUI.scaleform = scaleform
end

function DUI.Render()
    local scaleform = DUI.scaleform
    if not scaleform then return end

    SetDrawOrigin(scaleform.position.x, scaleform.position.y, scaleform.position.z, 0)
    DrawSprite(txdName, txnName, 0.0, 0.0, 0.21, 0.55, 0.0, 255, 255, 255, 255)
    ClearDrawOrigin()
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

local function calculateWorldPosition(ref)
    if not DoesEntityExist(ref.entity) then
        rederingIsActive = false
        return
    end

    local entity = ref.entity
    local offset = ref.offset

    if ref.static and not ref.positionCalculated then
        local ePos, eRotation = GetEntityCoords(entity), GetEntityHeading(entity)

        local ro_x, ro_y, ro_z = getRotatedOffset(eRotation, offset)
        local pos = vec3(ePos.x + offset.x, ePos.y + offset.y, ePos.z + offset.z)
        pos = vector3(ePos.x + ro_x, ePos.y + ro_y, ePos.z + ro_z)
        setPosition(pos)

        ref.positionCalculated = pos
    end

    if ref.static then
        return
    elseif ref.bone then
        local bonePos = GetWorldPositionOfEntityBone(entity, ref.bone)

        setPosition(bonePos)
    else
        local ePos, eRotation = GetEntityCoords(entity), GetEntityHeading(entity)

        local ro_x, ro_y, ro_z = getRotatedOffset(eRotation, offset)
        local pos = vec3(ePos.x + offset.x, ePos.y + offset.y, ePos.z + offset.z)
        pos = vector3(ePos.x + ro_x, ePos.y + ro_y, ePos.z + ro_z)
        setPosition(pos)
    end
end

CreateThread(function()
    DUI:Create()

    local render = DUI.Render

    -- Tracking Thread
    CreateThread(function()
        local ref = DUI.scaleform.attached
        while true do
            if rederingIsActive and ref.entity then
                calculateWorldPosition(ref)
                Wait(30)
            else
                Wait(350)
            end
        end
    end)

    while true do
        if rederingIsActive then
            render()
            Wait(0)
        else
            Wait(350)
        end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= thisResource then return end

    DUI.Destroy()
end)
