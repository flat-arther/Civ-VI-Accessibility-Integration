-- CAIWidget_HorizontalList.lua

---@class HorizontalListWidget : ContainerWidget
HorizontalListWidget = setmetatable({}, { __index = ContainerWidget })
HorizontalListWidget.__index = HorizontalListWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return HorizontalListWidget
function HorizontalListWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(HorizontalListWidget)
    w.Id = id
    w.Type = "HorizontalList"
    w.Role = "HorizontalList"
    w.Manager = mgr
    w:AddInputBindings({
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_LEFT",    Action = function(self) return self:NavigatePrev() end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_RIGHT",   Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_FIRST", Action = function(self) return self:NavigateToFirst() end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_MOVE_TO_LAST", Action = function(self) return self:NavigateToLast() end },
        { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_UP",      Action = function(self) return self:NavigatePage(-1) end },
        { Key = Keys.VK_NEXT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_PAGE_DOWN",    Action = function(self) return self:NavigatePage(1) end },
    })
    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

CAIWidgetRegistry.Register("HorizontalList", HorizontalListWidget.Create)
