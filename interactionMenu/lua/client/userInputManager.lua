local holdStart = nil
local lastHoldTrigger = nil
local DisableControlAction = DisableControlAction
local IsControlJustReleased = IsControlJustReleased
local IsDisabledControlJustReleased = IsDisabledControlJustReleased
local HOLD_COOLDOWN_MS = 1000

-- UserInputManager Class
UserInputManager = {}
UserInputManager.__index = UserInputManager

function UserInputManager:new()
    local instance = setmetatable({}, self)
    instance.currentMenuData = nil
    instance.holdStart = nil
    instance.lastHoldTrigger = nil
    instance.holding = false
    return instance
end

function UserInputManager:setMenuData(menuData)
    self.currentMenuData = menuData
end

function UserInputManager:clearMenuData()
    self.currentMenuData = nil
end

function UserInputManager:handleMouseWheel(direction)
    if not self.currentMenuData then return end
    Interact:scroll(self.currentMenuData, direction)
end

function UserInputManager:holdKey()
    if not (self.currentMenuData and self.currentMenuData.indicator and self.currentMenuData.indicator.hold) then
        return false
    end

    local current_time = GetGameTimer()
    if self.lastHoldTrigger and (current_time - self.lastHoldTrigger) < HOLD_COOLDOWN_MS then
        return false
    end

    if not self.holdStart then
        self.holdStart = current_time
    end

    -- hold progress
    local hold_duration = self.currentMenuData.indicator.hold
    local elapsed_time = current_time - self.holdStart
    local percentage = (elapsed_time / hold_duration) * 100
    Interact:fillIndicator(self.currentMenuData, percentage)

    if elapsed_time >= hold_duration then
        self.holdStart = nil
        self.lastHoldTrigger = current_time
        self:pressKey()
        Interact:indicatorStatus(self.currentMenuData, 'success')
        Interact:fillIndicator(self.currentMenuData, 0)
        return true
    end

    return false
end

function UserInputManager:pressKey()
    if not self.currentMenuData then return end
    Container.keyPress(self.currentMenuData)
end

function UserInputManager:leftEarly()
    if not self.currentMenuData then return end

    self.holdStart = nil
    Interact:indicatorStatus(self.currentMenuData, 'fail')
    Interact:fillIndicator(self.currentMenuData, 0)
    Util.print_debug("Player stopped holding the key early")
end

function UserInputManager:startHoldDetection()
    if not self.currentMenuData or self.holding then
        return
    end

    self.holding = true

    -- input -> hold or press
    if self.currentMenuData.indicator and self.currentMenuData.indicator.hold then
        CreateThread(function()
            while self.holding do
                if not self.currentMenuData or self:holdKey() then
                    self.holding = false
                    return
                end
                Wait(0)
            end

            self:leftEarly()
            self.holding = false
        end)
    else
        self:pressKey()
    end
end

function UserInputManager:stopHoldDetection()
    self.holding = false
end

function UserInputManager.defaultMouseWheel(menuData)
    -- not the best way to do it but it works if we add new options on runtime
    -- HideHudComponentThisFrame(19)

    -- Mouse Wheel Down / Arrow Down
    DisableControlAction(0, 85, true) -- INPUT_VEH_RADIO_WHEEL (Mouse scroll wheel)
    DisableControlAction(0, 86, true) -- INPUT_VEH_NEXT_RADIO (Mouse wheel up)
    DisableControlAction(0, 81, true) -- INPUT_VEH_PREV_RADIO (Mouse wheel down)
    -- DisableControlAction(0, 82, true) -- INPUT_VEH_SELECT_NEXT_WEAPON (Keyboard R)
    -- DisableControlAction(0, 83, true) -- INPUT_VEH_SELECT_PREV_WEAPON (Keyboard E)

    DisableControlAction(0, 14, true)
    DisableControlAction(0, 15, true)
    if IsDisabledControlJustReleased(0, 14) or IsControlJustReleased(0, 173) then
        Interact:scroll(menuData, true)
        -- Mouse Wheel Up / Arrow Up
    elseif IsDisabledControlJustReleased(0, 15) or IsControlJustReleased(0, 172) then
        Interact:scroll(menuData, false)
    end
end

function UserInputManager.defaultKeyHandler(menuData)
    -- E
    local padIndex = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.padIndex or 0
    local control = (menuData.indicator and menuData.indicator.keyPress) and menuData.indicator.keyPress.control or 38

    if menuData.indicator and menuData.indicator.hold then
        if IsControlPressed(padIndex, control) then
            local currentTime = GetGameTimer()
            if lastHoldTrigger then
                if (currentTime - lastHoldTrigger) >= 1000 then
                    lastHoldTrigger = nil
                else
                    return
                end
            end
            if not holdStart then
                holdStart = currentTime
            end
            local holdDuration = menuData.indicator.hold
            local elapsedTime = currentTime - holdStart
            local percentage = (elapsedTime / holdDuration) * 100
            Interact:fillIndicator(menuData, percentage)

            if elapsedTime >= holdDuration then
                holdStart = nil
                lastHoldTrigger = currentTime
                Container.keyPress(menuData)
                Interact:indicatorStatus(menuData, 'success')
                Interact:fillIndicator(menuData, 0)
            end
        else
            if holdStart then
                Util.print_debug("Player stopped holding the key early")
                Interact:indicatorStatus(menuData, 'fail')
                Interact:fillIndicator(menuData, 0)
                holdStart = nil
            end
        end
    else
        if not IsControlJustReleased(padIndex, control) then return end
        Container.keyPress(menuData)
    end
end

-- Instantiate UserInputManager
local UserInputManager = UserInputManager:new()

-- Register Commands for Mouse Wheel
RegisterCommand('+interaction:wheel_up', function()
    UserInputManager:handleMouseWheel(false)
end, false)

RegisterCommand('+interaction:wheel_down', function()
    UserInputManager:handleMouseWheel(true)
end, false)

RegisterKeyMapping('+interaction:wheel_up', 'Interaction MouseWheel (up)', 'MOUSE_WHEEL', "IOM_WHEEL_UP")
RegisterKeyMapping('+interaction:wheel_down', 'Interaction MouseWheel (down)', 'MOUSE_WHEEL', "IOM_WHEEL_DOWN")
TriggerEvent('chat:removeSuggestion', '/+interaction:wheel_up')
TriggerEvent('chat:removeSuggestion', '/+interaction:wheel_down')

-- Register Commands for Key Hold
if Config.controls.enforce then
    local controls = Config.controls.interact

    RegisterCommand('+interaction_interact', function()
        UserInputManager:startHoldDetection()
    end, false)

    RegisterCommand('-interaction_interact', function()
        UserInputManager:stopHoldDetection()
    end, false)

    RegisterKeyMapping('+interaction_interact', 'Trigger selected interaction option', controls.defaultMapper,
        controls.defaultParameter)
    TriggerEvent('chat:removeSuggestion', '/+interaction:interact')
    TriggerEvent('chat:removeSuggestion', '/-interaction:interact')
end
