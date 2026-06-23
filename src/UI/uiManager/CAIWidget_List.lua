-- CAIWidget_List.lua

---@class ListWidget : ContainerWidget
---@field SearchDepth integer
ListWidget = setmetatable({}, { __index = ContainerWidget })
ListWidget.__index = ListWidget

local Search = CAIWidgetHelpers_Search

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return ListWidget
function ListWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(ListWidget)
    w.Id = id
    w.Type = "List"
    w.Role = "List"
    w.Manager = mgr
    w.AllowSearch = true
    w.SearchDepth = 2
    w:AddInputBindings({
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_UP",       Action = function(self) return self:NavigatePrev() end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_DOWN",     Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_FIRST", Action = function(self) return self:NavigateToFirst() end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_LAST",  Action = function(self) return self:NavigateToLast() end },
        { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_UP",       Action = function(self) return self:NavigatePage(-1) end },
        { Key = Keys.VK_NEXT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_DOWN",     Action = function(self) return self:NavigatePage(1) end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param char string
---@return boolean
function ListWidget:OnCharInput(char)
    return Search.HandleChar(self, char, self.SearchDepth)
end

CAIWidgetRegistry.Register("List", ListWidget.Create)
