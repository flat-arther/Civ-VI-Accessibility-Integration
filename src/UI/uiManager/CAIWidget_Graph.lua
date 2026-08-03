-- CAIWidget_Graph.lua
-- Directed graph container. Screens provide arbitrary node widgets and edges;
-- the graph owns relationship navigation, grouping, and type-to-find.
-- Manager.CurrentPath remains the only source of truth for focused node.

local Search = CAIWidgetHelpers_Search

---@class GraphGroup
---@field key string|number Stable group identity.
---@field label string|fun():string Live localized group label.

---@class GraphNodeOptions
---@field group? string|number Optional GraphGroup key.

---@class GraphWidget : ContainerWidget
GraphWidget = setmetatable({}, { __index = ContainerWidget })
GraphWidget.__index = GraphWidget

local DEFAULT_GROUP_KEY = {}

---@param mgr UIScreenManager
---@param key string|number
---@param label string|fun():string
---@param transparent? boolean
---@return ContainerWidget
local function MakeGroup(mgr, key, label, transparent)
    local group = ContainerWidget.New(ContainerWidget)
    group.Manager = mgr
    group.Type = "GraphGroup"
    group.Role = "GraphGroup"
    group.GraphGroupKey = key
    group.WrapAround = false
    group.UseDirectionalEntry = false
    group.Transparent = transparent == true
    group.SpeechSettings = { Role = false, Position = false }
    group:SetLabel(label or "")
    return group
end

local function ResetGraphData(w)
    w._groupsByKey = {}
    w._nodesByKey = {}
    w._nodeKeyByWidget = {}
    w._nodeOrder = {}
    w._nodeOrdinal = {}
    w._incomingByKey = {}
    w._outgoingByKey = {}
    w._edgeSet = {}
    w._defaultNodeKey = nil
    w._contextKey = nil
    w._alternativeKeys = {}
    w._alternativeIndex = 0
end

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return GraphWidget
function GraphWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(GraphWidget)
    w.Id = id
    w.Type = "Graph"
    w.Role = "Graph"
    w.Manager = mgr
    w.WrapAround = true
    w.AllowSearch = true
    ResetGraphData(w)

    w:AddInputBindings({
        { Key = Keys.VK_UP,    MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_PREVIOUS_ALTERNATIVE", Action = function(self)
            return Search.NavigateResults(self, -1) or self:_NavigateAlternative(-1)
        end },
        { Key = Keys.VK_DOWN,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_NEXT_ALTERNATIVE", Action = function(self)
            return Search.NavigateResults(self, 1) or self:_NavigateAlternative(1)
        end },
        { Key = Keys.VK_LEFT,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_INCOMING", Action = function(self) return self:_NavigateEdge(-1) end },
        { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_OUTGOING", Action = function(self) return self:_NavigateEdge(1) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_FIRST_ALTERNATIVE", Action = function(self) return self:_NavigateAlternativeEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, Description = "LOC_CAI_KB_GRAPH_LAST_ALTERNATIVE", Action = function(self) return self:_NavigateAlternativeEdge(1) end },
        { Key = Keys.VK_HOME,  MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_GRAPH_FIRST_ROOT", Action = function(self) return self:_NavigateRootEdge(-1) end },
        { Key = Keys.VK_END,   MSG = KeyEvents.KeyDown, IsControl = true, Description = "LOC_CAI_KB_GRAPH_LAST_ROOT", Action = function(self) return self:_NavigateRootEdge(1) end },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

---@param group GraphGroup
---@return ContainerWidget
function GraphWidget:AddGroup(group)
    assert(type(group) == "table", "GraphWidget:AddGroup requires a group definition")
    assert(group.key ~= nil, "GraphWidget:AddGroup requires group.key")
    assert(self._groupsByKey[group.key] == nil, "GraphWidget:AddGroup duplicate key " .. tostring(group.key))
    local widget = MakeGroup(self.Manager, group.key, group.label, false)
    self._groupsByKey[group.key] = widget
    self:AddChild(widget)
    return widget
end

---@return ContainerWidget
function GraphWidget:_GetDefaultGroup()
    local group = self._groupsByKey[DEFAULT_GROUP_KEY]
    if group then return group end
    group = MakeGroup(self.Manager, DEFAULT_GROUP_KEY, "", true)
    self._groupsByKey[DEFAULT_GROUP_KEY] = group
    self:AddChild(group)
    return group
end

---@param key string|number
---@param widget UIWidget
---@param options? GraphNodeOptions
---@return UIWidget
function GraphWidget:AddNode(key, widget, options)
    assert(key ~= nil, "GraphWidget:AddNode requires a key")
    assert(widget ~= nil, "GraphWidget:AddNode requires a widget")
    assert(self._nodesByKey[key] == nil, "GraphWidget:AddNode duplicate key " .. tostring(key))

    options = options or {}
    local group
    if options.group ~= nil then
        group = self._groupsByKey[options.group]
        assert(group ~= nil, "GraphWidget:AddNode unknown group " .. tostring(options.group))
    else
        group = self:_GetDefaultGroup()
    end

    group:AddChild(widget)
    self._nodesByKey[key] = widget
    self._nodeKeyByWidget[widget] = key
    self._nodeOrder[#self._nodeOrder + 1] = key
    self._nodeOrdinal[key] = #self._nodeOrder
    self._incomingByKey[key] = {}
    self._outgoingByKey[key] = {}
    return widget
end

---@param fromKey string|number
---@param toKey string|number
function GraphWidget:AddEdge(fromKey, toKey)
    assert(self._nodesByKey[fromKey] ~= nil, "GraphWidget:AddEdge unknown source " .. tostring(fromKey))
    assert(self._nodesByKey[toKey] ~= nil, "GraphWidget:AddEdge unknown target " .. tostring(toKey))
    local targets = self._edgeSet[fromKey]
    if not targets then
        targets = {}
        self._edgeSet[fromKey] = targets
    end
    if targets[toKey] then return end
    targets[toKey] = true
    self._outgoingByKey[fromKey][#self._outgoingByKey[fromKey] + 1] = toKey
    self._incomingByKey[toKey][#self._incomingByKey[toKey] + 1] = fromKey
end

---@param keys (string|number)[]
---@param visibleOnly? boolean
---@return (string|number)[]
function GraphWidget:_OrderedKeys(keys, visibleOnly)
    local out = {}
    for _, key in ipairs(keys or {}) do
        local node = self._nodesByKey[key]
        if node and (not visibleOnly or not node:IsHidden()) then out[#out + 1] = key end
    end
    table.sort(out, function(a, b)
        return self._nodeOrdinal[a] < self._nodeOrdinal[b]
    end)
    return out
end

---@param key string|number
---@return (string|number)[]
function GraphWidget:GetIncoming(key)
    return self:_OrderedKeys(self._incomingByKey[key] or {}, false)
end

---@param key string|number
---@return (string|number)[]
function GraphWidget:GetOutgoing(key)
    return self:_OrderedKeys(self._outgoingByKey[key] or {}, false)
end

---@return (string|number)[]
function GraphWidget:GetRoots()
    local roots = {}
    for _, key in ipairs(self._nodeOrder) do
        if #(self._incomingByKey[key] or {}) == 0 then roots[#roots + 1] = key end
    end
    return roots
end

---@param key string|number
---@return UIWidget|nil
function GraphWidget:GetNode(key)
    return self._nodesByKey[key]
end

---@return string|number|nil
function GraphWidget:GetFocusedNodeKey()
    local node = self.Manager and self.Manager:GetFocusedWidget() or nil
    while node and node ~= self do
        local key = self._nodeKeyByWidget[node]
        if key ~= nil then return key end
        node = node.Parent
    end
    return nil
end

---@param key string|number
function GraphWidget:SetDefaultNode(key)
    assert(self._nodesByKey[key] ~= nil, "GraphWidget:SetDefaultNode unknown key " .. tostring(key))
    self._defaultNodeKey = key
end

---@param key string|number
---@param options? boolean|{ direction?: 1|-1, announce?: boolean }
---@return boolean
function GraphWidget:FocusNode(key, options)
    local node = self._nodesByKey[key]
    if not node or node:IsHidden() then return false end
    self:_ReseedAlternatives(key)
    return self.Manager:SetFocus(node, options)
end

---@param keys (string|number)[]
---@param key string|number
---@return integer
local function FindKey(keys, key)
    for i, candidate in ipairs(keys) do
        if candidate == key then return i end
    end
    return 0
end

---@param key string|number
function GraphWidget:_ReseedAlternatives(key)
    self._contextKey = key
    local incoming = self:_OrderedKeys(self._incomingByKey[key] or {}, true)
    local alternatives
    if #incoming == 0 then
        alternatives = self:_OrderedKeys(self:GetRoots(), true)
    else
        alternatives = self:_OrderedKeys(self._outgoingByKey[incoming[1]] or {}, true)
    end
    if FindKey(alternatives, key) == 0 then alternatives[#alternatives + 1] = key end
    self._alternativeKeys = alternatives
    self._alternativeIndex = FindKey(alternatives, key)
end

---@return string|number|nil
function GraphWidget:_SyncFocusedNode()
    local key = self:GetFocusedNodeKey()
    if key ~= nil and key ~= self._contextKey then self:_ReseedAlternatives(key) end
    return key
end

---Return the focused graph node's index in the live alternative set navigated
---by Up/Down. Only registered node widgets receive graph position speech;
---their internal descendants retain their own semantics.
---@param widget UIWidget
---@return string|nil
function GraphWidget:GetNodePositionString(widget)
    local key = self._nodeKeyByWidget[widget]
    if key == nil or widget:IsHidden() then return nil end
    if key ~= self._contextKey then self:_ReseedAlternatives(key) end
    local index = FindKey(self._alternativeKeys, key)
    if index == 0 or #self._alternativeKeys == 0 then return nil end
    return Locale.Lookup("LOC_UIWidget_Element_Pos", index, #self._alternativeKeys)
end

---@param targetKey string|number
---@param alternatives (string|number)[]
---@param direction 1|-1
---@return boolean
function GraphWidget:_MoveTo(targetKey, alternatives, direction)
    local node = self._nodesByKey[targetKey]
    if not node or node:IsHidden() then return false end
    self._contextKey = targetKey
    self._alternativeKeys = alternatives
    self._alternativeIndex = FindKey(alternatives, targetKey)
    return self.Manager:SetFocus(node, { direction = direction })
end

---@param direction 1|-1 -1 follows incoming edges; 1 follows outgoing edges.
---@return boolean
function GraphWidget:_NavigateEdge(direction)
    local focusedKey = self:_SyncFocusedNode()
    if focusedKey == nil then return false end
    local source = direction < 0 and self._incomingByKey or self._outgoingByKey
    local alternatives = self:_OrderedKeys(source[focusedKey] or {}, true)
    if #alternatives == 0 then return false end
    local targetKey = alternatives[1]
    -- Match Civ V's DAG cursor: ascending to a root changes the sibling
    -- context to the complete root set. Without this special case, returning
    -- from Writing to Pottery would leave Pottery as a one-item alternative
    -- set instead of allowing Up/Down to browse the other starting routes.
    if direction < 0 and #(self._incomingByKey[targetKey] or {}) == 0 then
        alternatives = self:_OrderedKeys(self:GetRoots(), true)
    end
    return self:_MoveTo(targetKey, alternatives, direction)
end

---@param direction 1|-1
---@return boolean
function GraphWidget:_NavigateAlternative(direction)
    if self:_SyncFocusedNode() == nil then return false end
    local alternatives = self._alternativeKeys
    if #alternatives < 2 then return false end
    local nextIndex = self._alternativeIndex + direction
    if nextIndex < 1 then
        if not self.WrapAround then return false end
        nextIndex = #alternatives
    elseif nextIndex > #alternatives then
        if not self.WrapAround then return false end
        nextIndex = 1
    end
    return self:_MoveTo(alternatives[nextIndex], alternatives, direction)
end

---@param direction 1|-1
---@return boolean
function GraphWidget:_NavigateAlternativeEdge(direction)
    local focusedKey = self:_SyncFocusedNode()
    if focusedKey == nil or #self._alternativeKeys == 0 then return false end
    local index = direction < 0 and 1 or #self._alternativeKeys
    local target = self._alternativeKeys[index]
    if target == focusedKey then return false end
    return self:_MoveTo(target, self._alternativeKeys, direction)
end

---@param direction 1|-1
---@return boolean
function GraphWidget:_NavigateRootEdge(direction)
    local roots = self:_OrderedKeys(self:GetRoots(), true)
    if #roots == 0 then return false end
    local target = direction < 0 and roots[1] or roots[#roots]
    if target == self:GetFocusedNodeKey() then return false end
    return self:_MoveTo(target, roots, direction)
end

---@return UIWidget|nil
function GraphWidget:GetDefaultChild()
    local key = self:GetFocusedNodeKey() or self._contextKey or self._defaultNodeKey
    local node = key and self._nodesByKey[key] or nil
    if node and not node:IsHidden() then
        local child = node
        while child.Parent and child.Parent ~= self do
            child.Parent._lastFocusedChild = child
            child.Parent._lastFocusedKey = child.FocusKey
            child = child.Parent
        end
        if child.Parent == self then return child end
    end
    return ContainerWidget.GetDefaultChild(self)
end

---@param includeTooltips boolean
---@return SearchCandidate[]
function GraphWidget:GetTypeToFindCandidates(includeTooltips)
    local candidates = {}
    local index = 1
    for _, key in ipairs(self._nodeOrder) do
        local node = self._nodesByKey[key]
        if node and not node:IsHidden() then
            local label = node:GetLabel()
            if label and label ~= "" then
                local tooltip = includeTooltips and (node:GetTooltip() or "") or ""
                candidates[#candidates + 1] = Search.MakeSearchCandidate(node, label, index, tooltip)
                index = index + 1
            end
        end
    end
    return candidates
end

---@param char string
---@return boolean
function GraphWidget:OnCharInput(char)
    return Search.HandleChar(self, char)
end

---@return boolean
function GraphWidget:OnSearchBackspace()
    return Search.HandleBackspace(self)
end

function GraphWidget:ClearGraph()
    UIWidget.ClearChildren(self)
    ResetGraphData(self)
end

function GraphWidget:ClearChildren()
    self:ClearGraph()
end

CAIWidgetRegistry.Register("Graph", GraphWidget.Create)
