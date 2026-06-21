-- CAIWidget_Container.lua
-- ContainerWidget: navigable parent for child widgets.

---@class ContainerWidget : UIWidget
---@field WrapAround boolean
---@field DefaultIndex integer
---@field PageSize integer
---@field AllowSearch boolean
---@field _searchQueryHandler? fun(query:string, maxResults:integer):table[]
---@field _searchHistoryContext? string
ContainerWidget = setmetatable({}, { __index = UIWidget })
ContainerWidget.__index = ContainerWidget

local Nav = CAIWidgetHelpers_Navigation

---Subclass constructor entry point.
---@param class table
---@return ContainerWidget
function ContainerWidget.New(class)
    local w = UIWidget.New(class)
    w.WrapAround = true
    w.DefaultIndex = 1
    w.PageSize = 10
    w.AllowSearch = false
    w._searchQueryHandler = nil
    w._searchHistoryContext = nil
    w:AddInputBinding({
        Key = Keys.F, IsControl = true,
        Action = function(self)
            if not self.AllowSearch then return false end
            if self.Manager then self.Manager:OpenSearch(self) end
            return true
        end,
    })
    return w
end

---@param b boolean
function ContainerWidget:SetWrapAround(b) self.WrapAround = b and true or false end

---@param n integer
function ContainerWidget:SetPageSize(n) self.PageSize = n end

---@param b boolean
function ContainerWidget:SetAllowSearch(b) self.AllowSearch = b and true or false end

function ContainerWidget:EnableSearch() self.AllowSearch = true end
function ContainerWidget:DisableSearch() self.AllowSearch = false end

---@param handler fun(query:string, maxResults:integer):table[]
function ContainerWidget:SetSearchQueryHandler(handler)
    self._searchQueryHandler = handler
    if handler then self.AllowSearch = true end
end

---@return fun(query:string, maxResults:integer):table[]|nil
function ContainerWidget:GetSearchQueryHandler()
    return self._searchQueryHandler
end

---@param context string
function ContainerWidget:SetSearchHistoryContext(context)
    self._searchHistoryContext = context
end

---@return string|nil
function ContainerWidget:GetSearchHistoryContext()
    return self._searchHistoryContext
end

---@param results table[]
function ContainerWidget:SetSearchResults(results)
    local mgr = self.Manager
    if not mgr then return end
    local panel = mgr:GetSearchPanel()
    if panel and panel._targetContainer == self then
        panel:SetResults(results)
    end
end

---@return SearchPanelWidget|nil
function ContainerWidget:GetSearchPanel()
    local mgr = self.Manager
    if not mgr then return nil end
    local panel = mgr:GetSearchPanel()
    if panel and panel._targetContainer == self then
        return panel
    end
    return nil
end

---Resolve the child this container should focus when entered.
---@return UIWidget|nil
function ContainerWidget:GetDefaultChild()
    return Nav.DefaultChild(self)
end

---Direction-aware entry: forward (1) lands on the first visible child,
---backward (-1) on the last, neutral (nil/0) on the cached default.
---@param direction 1|-1|0|nil
---@return UIWidget|nil
function ContainerWidget:GetEntryChild(direction)
    return Nav.EntryChild(self, direction)
end

---@param direction 1|-1
---@return boolean
function ContainerWidget:Navigate(direction) return Nav.Navigate(self, direction) end

function ContainerWidget:NavigateNext() return Nav.Navigate(self, 1) end
function ContainerWidget:NavigatePrev() return Nav.Navigate(self, -1) end
function ContainerWidget:NavigateToFirst() return Nav.NavigateToFirst(self) end
function ContainerWidget:NavigateToLast() return Nav.NavigateToLast(self) end

---@param direction 1|-1
---@return boolean
function ContainerWidget:NavigatePage(direction) return Nav.NavigatePage(self, direction, self.PageSize) end
