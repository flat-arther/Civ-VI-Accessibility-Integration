-- CAIWidget_Tree.lua
-- Container that owns flat navigation over its TreeItem descendants.
-- WrapAround is false because tree boundaries are meaningful.

---@class TreeWidget : ContainerWidget
---@field SearchDepth integer
TreeWidget = setmetatable({}, { __index = ContainerWidget })
TreeWidget.__index = TreeWidget

local Tree = CAIWidgetHelpers_Tree
local Search = CAIWidgetHelpers_Search

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return TreeWidget
function TreeWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(TreeWidget)
    w.Id = id
    w.Type = "Tree"
    w.Role = "Tree"
    w.Manager = mgr
    w.WrapAround = false
    w.SearchDepth = 3

    w.AllowSearch = true

    w:AddInputBindings({
        { Key = Keys.VK_UP,     MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigateFlat(self, -1) end },
        { Key = Keys.VK_DOWN,   MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigateFlat(self,  1) end },
        { Key = Keys.VK_RIGHT,  MSG = KeyEvents.KeyDown, Action = function(self) return Tree.ExpandOrDescend(self) end },
        { Key = Keys.VK_LEFT,   MSG = KeyEvents.KeyDown, Action = function(self) return Tree.CollapseOrAscend(self) end },
        { Key = Keys.VK_HOME,   MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigateFirst(self) end },
        { Key = Keys.VK_END,    MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigateLast(self) end },
        { Key = Keys.VK_PRIOR,  MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigatePage(self, -1, self.PageSize) end },
        { Key = Keys.VK_NEXT,   MSG = KeyEvents.KeyDown, Action = function(self) return Tree.NavigatePage(self, 1, self.PageSize) end },
        { Key = Keys.VK_RETURN,                          Action = function(self) return Tree.ToggleFocused(self) end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param char string
---@return boolean
function TreeWidget:OnCharInput(char)
    -- Type-to-find can match a TreeItem that still has a stale descent cache
    -- from a previous visit. Clear every tree item in the subtree before
    -- search so the matched item lands as the focus leaf rather than
    -- redirecting into a cached child.
    local function clearAll(node)
        if node.IsTreeItem then Tree.ClearDescent(node) end
        if node.Children then
            for _, c in ipairs(node.Children) do clearAll(c) end
        end
    end
    clearAll(self)
    return Search.HandleChar(self, char, self.SearchDepth)
end

CAIWidgetRegistry.Register("Tree", TreeWidget.Create)
