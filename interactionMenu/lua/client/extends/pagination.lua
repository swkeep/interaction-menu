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
local PaginationBuilder = {}
PaginationBuilder.__index = PaginationBuilder

function PaginationBuilder:calculatePages()
    self.pages = math.ceil(#self.user_options / self.itemsPerPage)
end

function PaginationBuilder:addHeader()
    self.options = {
        {
            label = "Page: #1 | Total: " .. tostring(self.pages),
            bind = function()
                return ("Page: #%d | Total: %d"):format(self.currentPage, self.pages)
            end,
            canInteract = function()
                return self.pages > 1
            end
        },
    }
end

function PaginationBuilder:addFooter()
    local function updatePage(direction)
        self.currentPage = (self.currentPage - 1 + direction + self.pages) % self.pages + 1

        for i = 2, #self.options - 2 do
            local option = self.options[i]
            __export:set {
                menuId = self.menu_id,
                type = 'hide',
                option = i,
                value = option.page ~= self.currentPage
            }
        end

        refresh()
    end

    -- Pagination controls
    if self.pages > 1 then
        table.insert(self.options, {
            label = 'Prev Page',
            icon = 'fa fa-arrow-left',
            action = function() updatePage(-1) end
        })

        table.insert(self.options, {
            label = 'Next Page',
            icon = 'fa fa-arrow-right',
            action = function() updatePage(1) end
        })
    end
end

function PaginationBuilder:generateOptions()
    for index, option in ipairs(self.user_options) do
        local page = math.ceil(index / self.itemsPerPage)
        table.insert(self.options, {
            label = option.label,
            description = option.description,
            badge = option.badge,
            icon = option.icon,
            action = option.action,
            bind = option.bind,
            event = option.event,
            command = option.command,
            canInteract = option.canInteract,
            progress = option.progress,
            dynamic = option.dynamic,
            style = option.style,
            video = option.video,
            picture = option.picture,
            page = page,
            hide = page ~= 1,
        })
    end
end

function PaginationBuilder:create(t)
    self = setmetatable({}, PaginationBuilder)
    self.itemsPerPage = t.itemsPerPage or 6
    self.currentPage = 1
    self.menu_id = nil
    self.options = {}
    self.user_options = t.options or {}

    self:addHeader()
    self:calculatePages()
    self:generateOptions()
    self:addFooter()

    t.options = self.options
    self.menu_id = __export:Create(t)

    return self.menu_id
end

local function interface(t)
    return PaginationBuilder:create(t)
end

exports("paginatedMenu", interface)
exports("paginateMenu", interface)
