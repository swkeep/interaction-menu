if not Config.indicator.enabled then return end

-- #region Show sprite while holding alt

local RED = 255
local GREEN = 255
local BLUE = 255
local ALPHA = 255
local MIN_SCALE_X = 0.02 / 3
local MAX_SCALE_X = MIN_SCALE_X * 5
local MIN_SCALE_Y = 0.035 / 3
local MAX_SCALE_Y = MIN_SCALE_Y * 5
local MIN_DISTANCE = 1.0
local MAX_DISTANCE = 20.0

local current_sprite_finder_thread_id = nil
local current_sprite_renderer_thread_id = nil
local is_sprite_thread_running = false
local is_target_sprites_active = false
local state_manager = Util.StateManager()
local current_menu_type

CreateThread(function()
    local txd = CreateRuntimeTxd('interaction_txd_indicator')
    CreateRuntimeTextureFromImage(txd, 'indicator', "lua/client/icons/indicator.png")
    for index, value in ipairs(Config.icons) do
        CreateRuntimeTextureFromImage(txd, value, ("lua/client/icons/%s.png"):format(value))
    end
end)

function DrawIndicator(point, player_position, icon, alpha)
    if not point then return end
    local distance = #(vec3(point.x, point.y, point.z) - player_position)
    local clamped_distance = math.max(MIN_DISTANCE, math.min(MAX_DISTANCE, distance))

    local scale_range_x = MAX_SCALE_X - MIN_SCALE_X
    local scale_range_y = MAX_SCALE_Y - MIN_SCALE_Y
    local distance_range = MAX_DISTANCE - MIN_DISTANCE
    local normalized_distance = (clamped_distance - MIN_DISTANCE) / distance_range

    local scale_x = MIN_SCALE_X + scale_range_x * (1 - normalized_distance)
    local scale_y = MIN_SCALE_Y + scale_range_y * (1 - normalized_distance)

    SetDrawOrigin(point.x, point.y, point.z, 0)
    DrawSprite('interaction_txd_indicator', icon or 'indicator', 0, 0, scale_x, scale_y, 0, RED, GREEN, BLUE, alpha or ALPHA)
    ClearDrawOrigin()
end

local function start_sprite_thread()
    if is_sprite_thread_running then return end
    is_sprite_thread_running = true

    local player = PlayerPedId()
    local player_position = state_manager.get("playerPosition")
    local current_menu_id = state_manager.get("id")
    local is_active = state_manager.get("active")
    current_menu_type = state_manager.get("menuType")

    CreateThread(function(thread_id)
        current_sprite_finder_thread_id = thread_id

        while is_sprite_thread_running and current_sprite_finder_thread_id == thread_id do
            is_active = state_manager.get("active")
            current_menu_id = state_manager.get("id")
            current_menu_type = state_manager.get("menuType")

            Features.resolveAll("FindIndicator", {
                is_active = is_active,
                current_menu_id = current_menu_id,
                current_menu_type = current_menu_type,
                player_position = player_position,
                player_ped_id = player
            })

            Wait(500)
        end

        if current_sprite_finder_thread_id == thread_id then
            current_sprite_finder_thread_id = nil
        end
    end)

    CreateThread(function(thread_id)
        current_sprite_renderer_thread_id = thread_id

        while is_target_sprites_active and current_sprite_renderer_thread_id == thread_id do
            player_position = GetEntityCoords(player)

            Features.resolveAll("RenderIndicator", {
                is_active = is_active,
                current_menu_id = current_menu_id,
                current_menu_type = current_menu_type,
                player_position = player_position,
                player_ped_id = player
            })

            Wait(0)
        end

        is_sprite_thread_running = false
        if current_sprite_renderer_thread_id == thread_id then
            current_sprite_renderer_thread_id = nil
        end
    end)
end

RegisterCommand('+toggle_target_sprites', function()
    is_target_sprites_active = true
    start_sprite_thread()

    if Config.indicator.eye_enabled then
        local scaleform = Interact.getScaleform()
        if scaleform then
            scaleform.send_nui("interactionMenu:eye:visible", true)
        end
    end
end, false)

RegisterCommand('-toggle_target_sprites', function()
    is_target_sprites_active = false
    is_sprite_thread_running = false

    if Config.indicator.eye_enabled then
        local scaleform = Interact.getScaleform()
        if scaleform then
            scaleform.send_nui("interactionMenu:eye:visible", false)
        end
    end
end, false)

RegisterKeyMapping('+toggle_target_sprites', 'Toggle Target Sprites', 'keyboard', 'LMENU')
RegisterKeyMapping('~!+toggle_target_sprites', 'Toggle Target Sprites - Alternate Key', 'keyboard', 'RMENU')

-- #endregion
