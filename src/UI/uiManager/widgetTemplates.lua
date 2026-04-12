-- I am putting all templates in this file for now because I don't want to have to add each one in the modinfo file.
        ---@class WidgetTemplate :UIWidget
        ---@field RegisterInputs InputBinding[]
        
--#Nav helpers

---Finds the first visible child in a widget's Children list, searching from startIdx in the given direction.
---Returns the child and its index, or nil if none found.
---@param w UIWidget
---@param startIdx integer -- 1-based index to start searching from
---@param direction 1|-1
---@param allowWrap boolean -- whether to wrap around past the boundary
---@return UIWidget|nil, integer|nil
function FindVisibleChild(w, startIdx, direction, allowWrap)
    local children = w.Children
    if not children then return nil, nil end
    local numChildren = #children
    if numChildren == 0 then return nil, nil end

    for i = 1, numChildren do
        local idx = (startIdx + (i * direction) - 1) % numChildren + 1
        local candidate = children[idx]
        local isHidden = candidate.IsHidden and candidate:IsHidden()
        if not isHidden then
            -- Check if we crossed a boundary
            if not allowWrap then
                local crossedBoundary = false
                if direction > 0 then
                    crossedBoundary = idx < startIdx
                else
                    crossedBoundary = idx > startIdx
                end
                if crossedBoundary then return nil, nil end
            end
            return candidate, idx
        end
    end
    return nil, nil
end

---Finds the first visible child scanning forward from index 1
---@param w UIWidget
---@return UIWidget|nil
function FindFirstVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for _, child in ipairs(w.Children) do
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---Finds the last visible child scanning backward from the end
---@param w UIWidget
---@return UIWidget|nil
function FindLastVisibleChild(w)
    if not w.Children or #w.Children == 0 then return nil end
    for i = #w.Children, 1, -1 do
        local child = w.Children[i]
        local isHidden = child.IsHidden and child:IsHidden()
        if not isHidden then return child end
    end
    return nil
end

---Internal navigation helper using FindVisibleChild
---@param w UIWidget
---@param direction 1|-1
---@return boolean
local function NavigateSimpleList(w, direction)
    local children = w.Children
    if not children or #children == 0 then return false end
    local startIdx = w:GetChildIndex(w.FocusedChild) or 0
    local candidate = FindVisibleChild(w, startIdx, direction, w.WrapAround)
    if candidate then
        w.Manager:SetFocus(candidate)
        return true
    end
    return false
end

---Navigates to the first visible child
---@param w UIWidget
---@return boolean
local function NavigateToFirst(w)
    local child = FindFirstVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---Navigates to the last visible child
---@param w UIWidget
---@return boolean
local function NavigateToLast(w)
    local child = FindLastVisibleChild(w)
    if child then
        w.Manager:SetFocus(child)
        return true
    end
    return false
end

---GetDefaultChild function for containers. Returns focused widget if any, otherwise the first visible child
---@param w UIWidget
function GetContainerDefChild(w)
    if not w.Children or #w.Children == 0 then return end
    if w.FocusedChild then return w.FocusedChild end
    return FindFirstVisibleChild(w)
end

---@type table<string, WidgetTemplate>
WidgetTemplates = {
    Panel = {
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w) return w:Navigate(-1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    List = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    HorizontalList = {
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    SubMenu = { --- Basically a list but with different nav behavior, and expand collapse actions
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = false,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w:Navigate(-1)
                    return true
                end
                return false
            end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w:Navigate(1)
                    return true
                end
                return false
            end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                if not w.IsExpanded and w.Children and #w.Children > 0 then
                    w.IsExpanded = true
                    if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                    w:Navigate(1)
                    return true
                end
                return false
            end },
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then
                    w.IsExpanded = false
                    w.FocusedChild = nil
                    w.Manager:SetFocus(w)
                    if w.OnToggleExpanded then w:OnToggleExpanded(w.IsExpanded) end
                    return true
                end
                return false
            end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then return NavigateToFirst(w) end
                return false
            end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.IsExpanded then return NavigateToLast(w) end
                return false
            end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = function(w)
            if w.IsExpanded and w.FocusedChild then return w.FocusedChild end
            return nil
        end,
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
    DropdownMenu = {
        Role = "DropdownMenu",
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    Slider = {
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.Decrement then w:Decrement() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                if w.Increment then w:Increment() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_PRIOR, MSG = KeyEvents.KeyDown, Action = function(w)
                for i = 1, 10 do
                    if w.Increment then w:Increment() end
                end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
            { Key = Keys.VK_NEXT, MSG = KeyEvents.KeyDown, Action = function(w)
                for i = 1, 10 do
                    if w.Decrement then w:Decrement() end
                end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
        },
    },
    Checkbox = {
        RegisterInputs = {
            { Key = Keys.VK_SPACE, Action = function(w)
                if w.Toggle then w:Toggle() end
                w:SetValue(w.GetValue and w:GetValue() or "")
                return true
            end },
        },
    },
    Edit = {
        Role = "Edit",
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    Dialog = {
        Role = "Dialog",
        DefaultIndex = 1,
        WrapAround = true,
        RegisterInputs = {
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Action = function(w) return w:Navigate(-1) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    Tab = {
        Role = "Tab",
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    TabBar = {
        Role = "TabBar",
        DefaultIndex = 1,
        WrapAround = true,
        IsExpanded = true,
        RegisterInputs = {
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
            { Key = Keys.VK_HOME, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToFirst(w) end },
            { Key = Keys.VK_END, MSG = KeyEvents.KeyDown, Action = function(w) return NavigateToLast(w) end },
        },
        Navigate = NavigateSimpleList,
        GetDefaultChild = GetContainerDefChild
    },
    MenuItem = {
        Role = "MenuItem",
        SpeechSettings = { Role = false },
        RegisterInputs = {
            { Key = Keys.VK_RETURN, Action = function(w)
                if w.OnClick then w:OnClick() end
                return true
             end },
        },
    },
    StaticText = {
        Role = "StaticText",
        SpeechSettings = { Role = false },
        RegisterInputs = {},
    },
    GameView = {
        GetLabel = function() return Locale.Lookup("LOC_CAI_ROLE_GAME_VIEW") end,
        GetDefaultChild = GetContainerDefChild,
        RegisterInputs = {
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY+1)
                return true
            end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX, cursor.curY-1)
                return true
            end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX+1, cursor.curY)
                return true
            end },
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:SetCoords(cursor.curX-1, cursor.curY)
                return true
            end },
            { Key = Keys.VK_NUMPAD1, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHWEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD3, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_SOUTHEAST)
                return true
            end },
            { Key = Keys.VK_NUMPAD4, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_WEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD6, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_EAST)
                return true
            end },
            { Key = Keys.VK_NUMPAD7, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHWEST)
                return true
            end },
            { Key = Keys.VK_NUMPAD9, MSG = KeyEvents.KeyDown, Action = function(w)
                local cursor = ExposedMembers.CAICursor
                cursor:MoveToNextPlot(DirectionTypes.DIRECTION_NORTHEAST)
                return true
            end },
        },
    },
    InterfaceMode = {
        AnnounceRole = false,
    },
}
