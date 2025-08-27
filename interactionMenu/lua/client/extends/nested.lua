--                _
--               | |
--   _____      _| | _____  ___ _ __
--  / __\ \ /\ / / |/ / _ \/ _ \ '_ \
--  \__ \\ V  V /|   <  __/  __/ |_) |
--  |___/ \_/\_/ |_|\_\___|\___| .__/
--                             | |
--                             |_|
-- https://github.com/swkeep
local __export = exports['interactionMenu']
local refresh = __export.refresh
local NestedMenuBuilder = {}
NestedMenuBuilder.__index = NestedMenuBuilder

function string:split(delimiter)
    local result = {}
    local pattern = string.format("([^%s]+)", delimiter)
    for part in self:gmatch(pattern) do
        table.insert(result, part)
    end

    return result
end

function NestedMenuBuilder:addHeader()
    table.insert(self.options, {
        label = 'Back',
        icon = 'fa fa-arrow-left',
        action = function()
            local t = self.current_menu:split('/')
            table.remove(t)
            self.current_menu = (#t > 0 and table.concat(t, '/') .. '/') or "/"

            self:updateMenuVisibility(#self.current_menu:split("/") + 1)
            refresh()
        end,
        canInteract = function()
            return self.current_menu ~= "/"
        end
    })
end

function NestedMenuBuilder:updateMenuVisibility(depth)
    for i = 2, #self.options do
        local isVisible = #self.options[i].path:split('/') == depth
        __export:set {
            menuId = self.menu_id,
            type = 'hide',
            option = i,
            value = not isVisible
        }
    end
end

-- this is kind of recursive!
function NestedMenuBuilder:generateOptions(options, full_list, parentPath)
    for index, option in ipairs(options) do
        local path = parentPath and (parentPath .. '/' .. index) or '/' .. tostring(index)
        local isMainMenu = not path:find('/', 2)
        local hasSubMenu = option.subMenu ~= nil

        local action = hasSubMenu and function()
            self.current_menu = path .. "/"
            self:updateMenuVisibility(#self.current_menu:split("/") + 1)
            if option.action then option.action() end
            refresh()
        end or option.action

        table.insert(full_list, {
            path = path,
            label = option.label,
            icon = option.icon,
            action = action,
            bind = option.bind,
            template = option.template,
            event = option.event,
            command = option.command,
            canInteract = option.canInteract,
            progress = option.progress,
            style = option.style,
            video = option.video,
            picture = option.picture,
            hide = not isMainMenu,
            subMenu = hasSubMenu
        })

        if hasSubMenu then
            self:generateOptions(option.subMenu, full_list, path)
        end
    end
end

function NestedMenuBuilder:create(t)
    self = setmetatable({}, NestedMenuBuilder)
    self.itemsPerPage = t.itemsPerPage or 6
    self.current_menu = "/"
    self.menu_id = nil
    self.options = {}
    self.user_options = t.options or {}

    self:addHeader()
    self:generateOptions(self.user_options, self.options, nil)

    t.options = self.options
    self.menu_id = __export:Create(t)

    return self.menu_id
end

local function interface(t)
    return NestedMenuBuilder:create(t)
end

exports("nestedMenu", interface)
