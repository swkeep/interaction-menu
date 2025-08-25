local __export = exports['interactionMenu']

local DialogueSystem = {}
DialogueSystem.__index = DialogueSystem

local function loadAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        RequestAnimDict(dict)
        Wait(0)
    end
end

function DialogueSystem:updateMenuVisibility()
    for i = 2, #self.options do
        local shouldShow = self.options[i].conversationIndex == self.current_conversation_index
        __export:set {
            menuId = self.menu_id,
            type = 'hide',
            option = i,
            value = not shouldShow
        }
    end
end

function DialogueSystem:refresh()
    self:updateMenuVisibility()
    __export:refresh(self.menu_id)
end

function DialogueSystem:destroy()
    if self.menu_id then
        __export:remove(self.menu_id)
        self.menu_id = nil
    end
end

function DialogueSystem:close()
    self:destroy()
end

function DialogueSystem:get_dialogue(message)
    if type(message) == "table" then
        return message[math.random(1, #message)]
    else
        return message
    end
end

local function handleInteraction(interactionData, entity)
    if not interactionData then return end

    local animation = interactionData.animation
    local voice = interactionData.voice
    local action = interactionData.action

    if animation then
        ClearPedTasks(entity)
        loadAnimDict(animation.dict)
        TaskPlayAnim(
            entity,
            animation.dict,
            animation.anim,
            animation.blendIn or 8.0,
            animation.blendOut or -8.0,
            animation.flags or -1,
            0, 0, false, false, false
        )
    end

    if voice then
        PlayPedAmbientSpeechNative(entity, voice.speech, voice.params or "Speech_Params_Force")
    end

    if action then
        return pcall(action)
    end
end

function DialogueSystem:create(data)
    local instance = setmetatable({}, DialogueSystem)
    instance.current_conversation_index = 1
    instance.current_conversation = self:get_dialogue(data.conversations[1].message)
    instance.options = {}
    instance.conversation_map = {}

    -- just a single dialogue using bind
    table.insert(instance.options, {
        label = "placeholder",
        icon = data.conversations[1].icon,
        tts_api = data.conversations[1].tts_api or "streamelements",
        tts_voice = data.conversations[1].tts_voice,
        dialogue = data.conversations[1].tts_voice and true or false,
        bind = function() return instance.current_conversation end
    })

    for conversation_index, conversation in ipairs(data.conversations) do
        for _, response in ipairs(conversation.responses) do
            local option = {
                label = response.label,
                icon = response.icon,
                description = response.description,
                animation = response.animation,
                template = response.template,
                voice = response.voice,
                conversationIndex = conversation_index,
            }

            -- setting up the action based on response type
            if response.next then
                option.action = function()
                    for index, conv in ipairs(data.conversations) do
                        if response.next == conv.name then
                            local meet_condition = true
                            if response.requirement and response.requirement.check then
                                meet_condition = response.requirement.check()
                            end
                            if meet_condition then
                                instance.current_conversation = self:get_dialogue(conv.message)
                                instance.current_conversation_index = index
                                instance:refresh()
                                if response.requirement and response.requirement.notify then
                                    response.requirement.notify("success")
                                end
                            else
                                if response.requirement and response.requirement.notify then
                                    response.requirement.notify("fail")
                                end
                            end
                            return
                        end
                    end
                end
                if response.requirement and response.requirement.hint then
                    option.badge = {
                        type = response.requirement.type and response.requirement.type or "red",
                        label = response.requirement.hint
                    }
                end
            else
                option.action = function()
                    option.action = response.action
                    handleInteraction(option, data.entity)

                    instance.current_conversation_index = 1
                    instance.current_conversation = self:get_dialogue(data.conversations[1].message)
                    instance:refresh()
                end
            end

            instance.conversation_map[response.label] = {
                from = conversation.name,
                to = response.next or "action"
            }

            table.insert(instance.options, option)
        end
    end

    if data.voice then
        SetAmbientVoiceName(data.entity, data.voice)
    end

    local function local_onSeen()
        handleInteraction(data.onSeen, data.entity)
    end

    local function local_onExit()
        handleInteraction(data.onExit, data.entity)
    end

    instance.menu_id = __export:Create({
        entity = data.entity,
        position = data.position,
        rotation = data.rotation,
        indicator = data.indicator,
        theme = data.theme,
        width = "100%",
        extra = {
            onSeen = local_onSeen,
            onExit = local_onExit
        },
        options = instance.options
    })

    instance:updateMenuVisibility()
    return instance
end

local function interface(t)
    return DialogueSystem:create(t)
end

exports("dialogue", interface)
