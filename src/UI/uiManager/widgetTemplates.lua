-- I am putting all templates in this file for now because I don't want to have to add each one in the modinfo file.
        ---@class WidgetTemplate :UIWidget
        ---@field RegisterInputs InputBinding[]
        
--#Nav helpers
---Internal navigation helper. I am debating making this a global function, but I don't really see a reason to currently
---@param w UIWidget
---@param direction 1|-1
---@return boolean -- Returns true if navigation was successful, false if it failed (hit a boundary with no wrap around, or all candidates were hidden)
local function NavigateSimpleList(w, direction)
    local children = w.Children
    local numChildren = #children
    if not children or numChildren == 0 then return false end
    local startIdx = w:GetChildIndex(w.FocusedChild) or 0
local iterCount = (startIdx > 0 and numChildren - 1) or numChildren
    for i = 1, iterCount do
        local nextIdx = (startIdx + (i * direction) - 1) % numChildren + 1
        local candidate = children[nextIdx]

        local isHidden = candidate.IsHidden and candidate:IsHidden()
        if not isHidden then
            local crossedBoundary = false
            if direction > 0 then
                crossedBoundary = nextIdx < startIdx
            else
                crossedBoundary = nextIdx > startIdx
            end

            if crossedBoundary and not w.WrapAround then
                return false
            end

            w.Manager:SetFocus(candidate)
            return true
        end
    end

    return false
end

---Focuses the first child in a widget. 
------@deprecated To be replaced with the navigate function later
---@param w UIWidget
local function FocusFirstChild(w)
    if w.Children and #w.Children > 0 then
        
        w:SetFocusedChild(w.Children[1])
    end
end

---GetDefaultChild function for containers. Returns focused widget if any, otherwise it returns the first child of the container
---@param w UIWidget
function GetContainerDefChild(w)
    if not w.Children or #w.Children == 0 then return end
    if w.FocusedChild then return w.FocusedChild end
    return w.Children[1]
end

---@type table<string, WidgetTemplate>
WidgetTemplates = {
    Panel = {
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_TAB, IsShift = true, Action = function(w) return w:Navigate(-1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    List = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_UP, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_DOWN, Action = function(w) return w:Navigate(1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
        },
        HorizontalList = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, Action = function(w) return w:Navigate(1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
        },
        SubMenu = { --- Basically a list but with different nav behavior, and expand collapse actions
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = false,
        RegisterInputs = {
            { Key = Keys.VK_UP, Action = function(w) 
            if w.IsExpanded then 
                -- Attempt to navigate. If it returns false, we return true anyway to trap focus inside. 
                w:Navigate(-1) 
                return true 
            end
            return false 
        end },
        { Key = Keys.VK_DOWN, Action = function(w) 
            if w.IsExpanded then 
                w:Navigate(1) 
                return true 
            end
            return false 
        end },
            { Key = Keys.VK_RIGHT, Action = function(w)
            if not w.IsExpanded and w.Children and #w.Children > 0 then
                w.IsExpanded = true
                if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                w:Navigate(1)
                return true
            end
            return false
        end },
        { Key = Keys.VK_LEFT, Action = function(w)
            if w.IsExpanded then
                w.IsExpanded = false
                w.FocusedChild = nil
                w.Manager:SetFocus(w)
                if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                return true
            end
            return false
        end },
        },
        Navigate = NavigateSimpleList,
        OnFocus = nil, --No auto expanding for you
        },
    Button = {
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    Slider = {
        RegisterInputs = {
            { Key = Keys.VK_LEFT, Action = function(w)
                if w.Decrement then w:Decrement() end
                    return true
                end },
            { Key = Keys.VK_RIGHT, Action = function(w)
                if w.Increment then w:Increment() end
                    return true
                end },
        },
    },
    Checkbox = {
        RegisterInputs = {
            { Key = Keys.VK_SPACE, Action = function(w) 
                if w.Toggle then w:Toggle() end
                    return true
                end },
        },
    },
    EditBox = {
        RegisterInputs = {},
    },
    GameView = {
        GetLabel = function() return "Main game area" end,
        GetDefaultChild = GetContainerDefChild,
        RegisterInputs = {
            { Key = Keys.VK_UP, Action = function(w) 
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY+1)
                 return true

                 end },
            { Key = Keys.VK_DOWN, Action = function(w) 
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY-1)
                 return true end },
                 { Key = Keys.VK_RIGHT, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                    cursor:SetCoords(cursor.curX+1, cursor.curY)
                 return true end },
                 { Key = Keys.VK_LEFT, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX-1, cursor.curY)
                 return true end },
                 { Key = Keys.VK_NUMPAD1, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHWEST)
                 return true end },
                 { Key = Keys.VK_NUMPAD3, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHEAST)
                 return true end },
                 { Key = Keys.VK_NUMPAD4, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_WEST)
                 return true end },
                 { Key = Keys.VK_NUMPAD6, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_EAST)
                 return true end },
                 { Key = Keys.VK_NUMPAD7, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHWEST)
                 return true end },
                 { Key = Keys.VK_NUMPAD9, Action = function(w) 
                    local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHEAST)
                 return true end },
        },
    },
    InterfaceMode = {
        AnnounceRole = false,
    },
}
