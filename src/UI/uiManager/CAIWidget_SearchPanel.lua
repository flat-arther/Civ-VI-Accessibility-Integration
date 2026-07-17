-- CAIWidget_SearchPanel.lua
-- Overlay search panel for container widgets. Ctrl+F on a container opens a
-- SearchPanel that indexes the container's descendants via the game's
-- Search.* API, presents results as a navigable list, and jumps to the
-- selected widget on activation.
--
-- Default term mode supports multi-term AND queries and term exclusion via
-- "--" prefix. Raw mode passes the complete edit-box query through once.
-- Per-context search history is navigable with PageUp/PageDown.

local SEARCH_CONTEXT = "CAI_SearchPanel"
local MAX_RESULTS = 50
local CUSTOM_MULTI_TERM_QUERY_MAX = 2000

---@class SearchPanelWidget : ContainerWidget
---@field _editBox EditBoxWidget
---@field _resultList ListWidget
---@field _targetContainer ContainerWidget
---@field _queryHandler? fun(query:string, maxResults:integer):table[]
---@field _queryMode "terms"|"raw"
---@field _contextReady boolean
---@field _historyContext string
---@field _historyIndex integer
SearchPanelWidget = setmetatable({}, { __index = PanelWidget })
SearchPanelWidget.__index = SearchPanelWidget

local Nav = CAIWidgetHelpers_Navigation
local SearchUtils = CAIWidgetHelpers_Search

local SEARCH_SPEECH_KEYS = { "label", "value", "tooltip" }

--#region Widget indexing (default mode)

local function CollectSearchableWidgets(root)
    local out = {}
    local function walk(w)
        if not w then return end
        local speech = w:BuildSpeech(SEARCH_SPEECH_KEYS)
        if speech and speech ~= "" then
            out[#out + 1] = { widget = w, text = speech }
        end
        if w.Children then
            for _, child in ipairs(w.Children) do walk(child) end
        end
    end
    if root.Children then
        for _, child in ipairs(root.Children) do walk(child) end
    end
    return out
end

local function BuildSearchContext(entries)
    Search.DestroyContext(SEARCH_CONTEXT)
    if not Search.CreateContext(SEARCH_CONTEXT, "", "", "...") then
        return false
    end
    for i, entry in ipairs(entries) do
        Search.AddData(SEARCH_CONTEXT, entry.widget.Id or tostring(i), entry.text, "", {})
    end
    Search.Optimize(SEARCH_CONTEXT)
    return true
end

local function DestroySearchContext()
    Search.DestroyContext(SEARCH_CONTEXT)
end

--#endregion

--#region Create

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return SearchPanelWidget
function SearchPanelWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(SearchPanelWidget)
    w.WrapAround = true
    w.Id = id
    w.Type = "SearchPanel"
    w.Role = "SearchPanel"
    w.Manager = mgr
    w.Transparent = true
    w._contextReady = false
    w._queryHandler = nil
    w._queryMode = "terms"
    w._widgetIndex = {}
    w._historyContext = "default"
    w._historyIndex = 0

    w._editBox = mgr:CreateWidget(id .. "_Edit", "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_SEARCH_EDIT") end,
        AlwaysEdit = true,
        EnterToCommit = false,
        CommitOnBufferChanged = true,
    })

    w._resultList = mgr:CreateWidget(id .. "_Results", "List", {
        Label = function() return Locale.Lookup("LOC_CAI_SEARCH_RESULTS") end,
    })
    w._resultList.AllowSearch = false
    w._resultList.OnCharInput = function() return false end

    w:AddChild(w._editBox)
    w:AddChild(w._resultList)

    w._editBox:On("text_changed", function(_, text)
        w:Emit("search_text_changed", text)
        w:_RunQuery(text)
    end)

    w:AddInputBindings({
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown,                Description = "LOC_CAI_KB_NEXT_CONTROL",            Action = function(self) return self:NavigateNext() end },
        { Key = Keys.VK_TAB, MSG = KeyEvents.KeyDown, IsShift = true, Description = "LOC_CAI_KB_PREVIOUS_CONTROL",        Action = function(self) return self:NavigatePrev() end },
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function(self) self:Close(); return true end,
        },
        {
            Key = Keys.VK_RETURN,
            Description = "LOC_CAI_KB_ACTIVATE_FIRST_RESULT",
            Action = function(self)
                if mgr:GetFocusedWidget() == self._editBox then
                    local firstChild = Nav.First(self._resultList)
                    if firstChild then
                        firstChild:Emit("activate")
                    else
                        Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_RESULTS"))
                    end
                    return true
                end
                return false
            end,
        },
        {
            Key = Keys.VK_PRIOR,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_SEARCH_HISTORY_PREV",
            Action = function(self)
                if mgr:GetFocusedWidget() ~= self._editBox then return false end
                return self:_HistoryNavigate(1)
            end,
        },
        {
            Key = Keys.VK_NEXT,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_SEARCH_HISTORY_NEXT",
            Action = function(self)
                if mgr:GetFocusedWidget() ~= self._editBox then return false end
                return self:_HistoryNavigate(-1)
            end,
        },
    })

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

--#endregion

--#region Open / Close

---@param container ContainerWidget
function SearchPanelWidget:Open(container)
    local mgr = self.Manager
    self._targetContainer = container
    self._previousFocus = mgr and mgr:GetFocusedWidget() or nil

    local root = container
    while root.Parent do root = root.Parent end
    self._stackRoot = root

    self._editBox:SetText("", true)
    self._resultList:ClearChildren()
    self._historyIndex = 0

    if not self._queryHandler then
        local entries = CollectSearchableWidgets(container)
        self._widgetIndex = {}
        for _, entry in ipairs(entries) do
            self._widgetIndex[entry.widget.Id or ""] = entry.widget
        end
        self._contextReady = BuildSearchContext(entries)
    else
        self._contextReady = true
    end

    root:AddChild(self)
    self:SetResults({})
    mgr:SetFocus(self._editBox)
    self:Emit("search_open", container)
end

function SearchPanelWidget:Close(skipFocusRestore)
    local mgr = self.Manager
    local restoreTarget = self._previousFocus
    DestroySearchContext()
    self._contextReady = false
    self._widgetIndex = {}
    self._queryHandler = nil
    self._targetContainer = nil
    self._previousFocus = nil
    if mgr then mgr._searchPanel = nil end
    self:Emit("search_close")
    self:Destroy()
    if not skipFocusRestore and restoreTarget and mgr then
        mgr:SetFocus(restoreTarget)
    end
end

--#endregion

--#region Query handler

---@param handler fun(query:string, maxResults:integer):table[]
function SearchPanelWidget:SetQueryHandler(handler)
    self._queryHandler = handler
end

---@param mode "terms"|"raw"
function SearchPanelWidget:SetQueryMode(mode)
    self._queryMode = mode == "raw" and "raw" or "terms"
end

---@param context string
function SearchPanelWidget:SetHistoryContext(context)
    self._historyContext = context or "default"
end

---@param query string
function SearchPanelWidget:AddHistoryItem(query)
    SearchUtils.AddHistory(self._historyContext, query)
end

---@param results table[]
function SearchPanelWidget:SetResults(results)
    local mgr = self.Manager

    self._resultList:ClearChildren()
    if not results or #results == 0 then
        local empty = mgr:CreateWidget(
            mgr:GenerateWidgetId("searchEmpty"),
            "StaticText",
            {
                Label = function()
                    if self._editBox:GetText() == "" then
                        return Locale.Lookup("LOC_CAI_SEARCH_TYPE_TO_SEARCH")
                    end
                    return Locale.Lookup("LOC_CAI_SEARCH_NO_RESULTS")
                end,
            }
        )
        self._resultList:AddChild(empty)
        return
    else
        for _, entry in ipairs(results) do
            local btn = mgr:CreateWidget(
                mgr:GenerateWidgetId("searchResult"),
                "MenuItem",
                {
                    Label = function() return entry.label end,
                    Tooltip = entry.tooltip and function() return entry.tooltip end or nil,
                    FocusKey = entry.key,
                }
            )
            btn:On("activate", function()
                local query = self._editBox:GetText()
                if query and query ~= "" then
                    SearchUtils.AddHistory(self._historyContext, query)
                end
                if entry.onActivate then
                    self:Close(true)
                    entry.onActivate()
                elseif entry.widget then
                    self:Close(true)
                    mgr:SetFocus(entry.widget)
                end
            end)
            self._resultList:AddChild(btn)
        end
    end

    local first = Nav.First(self._resultList)
    if first and CAISettings.GetBool("AutoFocusFirstSearchResult") then
        mgr:SetFocus(first, { direction = 1 })
    end
end

--#endregion

--#region Query execution

---Map raw MultiTermSearch results back to widget-enriched entries.
---@param raw table[]
---@return table[]
function SearchPanelWidget:_ResolveWidgetResults(raw)
    local results = {}
    for _, hit in ipairs(raw) do
        local w = self._widgetIndex[hit.key]
        if w then
            results[#results + 1] = {
                key = hit.key,
                label = hit.highlighted ~= "" and hit.highlighted or (w:GetLabel() or hit.key),
                widget = w,
            }
        end
    end
    return results
end

---Run a single-term query through the handler or default widget index.
---@param query string
---@return table[] results with key field
function SearchPanelWidget:_SingleQuery(query)
    if self._queryHandler then
        return self._queryHandler(query, MAX_RESULTS * 3) or {}
    end

    if not self._contextReady then return {} end
    return self:_ResolveWidgetResults(SearchUtils.MultiTermSearch(SEARCH_CONTEXT, { query }, {}, MAX_RESULTS))
end

---Intersect/subtract multi-term results by key, with custom handler support.
---@param whitelist string[]
---@param blacklist string[]
---@return table[]
function SearchPanelWidget:_MultiTermQuery(whitelist, blacklist)
    if not self._queryHandler then
        if not self._contextReady then return {} end
        return self:_ResolveWidgetResults(SearchUtils.MultiTermSearch(SEARCH_CONTEXT, whitelist, blacklist, MAX_RESULTS))
    end

    local hitCounts = {}
    local resultsByKey = {}

    for _, term in ipairs(whitelist) do
        local hits = self._queryHandler(term, CUSTOM_MULTI_TERM_QUERY_MAX) or {}
        if #hits == 0 then return {} end
        for rank, r in ipairs(hits) do
            local k = r.key
            hitCounts[k] = (hitCounts[k] or 0) + 1
            local existing = resultsByKey[k]
            if not existing then
                resultsByKey[k] = r
                r._multiRank = rank
            elseif existing.useFirstTooltip
                and (not existing.tooltip or existing.tooltip == "")
                and r.tooltip and r.tooltip ~= "" then
                existing.tooltip = r.tooltip
            end
            if existing then existing._multiRank = (existing._multiRank or 0) + rank end
        end
    end

    for _, term in ipairs(blacklist) do
        local hits = self._queryHandler(term, CUSTOM_MULTI_TERM_QUERY_MAX) or {}
        for _, r in ipairs(hits) do
            hitCounts[r.key] = -1
        end
    end

    local needed = #whitelist
    local results = {}
    for k, count in pairs(hitCounts) do
        if count >= needed and resultsByKey[k] then
            results[#results + 1] = resultsByKey[k]
        end
    end

    local fullQuery = string.lower(table.concat(whitelist, " "))
    local function titleTier(result)
        local title = result.searchTitle and string.lower(result.searchTitle) or ""
        if title == fullQuery then return 0 end
        if fullQuery ~= "" and string.find(title, fullQuery, 1, true) == 1 then return 1 end
        if fullQuery ~= "" and string.find(title, fullQuery, 1, true) then return 2 end
        return 3
    end
    table.sort(results, function(a, b)
        local aTier, bTier = titleTier(a), titleTier(b)
        if aTier ~= bTier then return aTier < bTier end
        local aRank, bRank = a._multiRank or math.huge, b._multiRank or math.huge
        if aRank ~= bRank then return aRank < bRank end
        return Locale.Compare(a.label or a.key, b.label or b.key) == -1
    end)
    while #results > MAX_RESULTS do table.remove(results) end
    return results
end

---@param rawQuery string
function SearchPanelWidget:_RunQuery(rawQuery)
    if not self._queryHandler and not self._contextReady then return end
    if not rawQuery or rawQuery == "" then
        self:SetResults({})
        return
    end

    if self._queryMode == "raw" then
        if self._queryHandler then
            self:SetResults(self._queryHandler(rawQuery, MAX_RESULTS) or {})
        else
            local raw = Search.Search(SEARCH_CONTEXT, rawQuery, MAX_RESULTS) or {}
            self:SetResults(self:_ResolveWidgetResults(raw))
        end
        return
    end

    local whitelist, blacklist = SearchUtils.ParseQuery(rawQuery)
    if #whitelist == 0 then
        self:SetResults({})
        return
    end

    if #whitelist == 1 and #blacklist == 0 then
        self:SetResults(self:_SingleQuery(whitelist[1]))
    else
        self:SetResults(self:_MultiTermQuery(whitelist, blacklist))
    end
end

--#endregion

--#region History navigation

---@param direction integer 1=older, -1=newer
---@return boolean
function SearchPanelWidget:_HistoryNavigate(direction)
    local history = SearchUtils.GetHistory(self._historyContext)
    if #history == 0 then
        Speak(Locale.Lookup("LOC_CAI_SEARCH_HISTORY_EMPTY"))
        return true
    end

    local newIndex, entry = SearchUtils.NavigateHistory(self._historyContext, self._historyIndex, direction)
    if newIndex == self._historyIndex then return true end
    self._historyIndex = newIndex

    if entry == nil then
        self._editBox:SetText("", true)
        self:_RunQuery("")
        Speak(Locale.Lookup("LOC_CAI_SEARCH_EDIT"))
    else
        self._editBox:SetText(entry, true)
        self:_RunQuery(entry)
        Speak(entry)
    end
    return true
end

--#endregion

--#region Input forwarding

---Forward printable characters and Backspace from the result list to the edit box.
---Keep normal edit speech so typing while reviewing results is still echoed.
---@param char string
---@return boolean
function SearchPanelWidget:OnCharInput(char)
    local mgr = self.Manager
    local focused = mgr:GetFocusedWidget()
    if focused == self._editBox then return false end
    return self._editBox:OnCharInput(char)
end

---@param input InputStruct
---@return boolean
function SearchPanelWidget:OnHandleInput(input)
    local mgr = self.Manager
    local focused = mgr:GetFocusedWidget()
    if focused ~= self._editBox then
        local key = input:GetKey()
        local msg = input:GetMessageType()
        if key == Keys.VK_BACK and msg == KeyEvents.KeyDown then
            local handled = self._editBox:OnHandleInput(input)
            if handled then return true end
        end
    end
    return UIWidget.OnHandleInput(self, input)
end

--#endregion

CAIWidgetRegistry.Register("SearchPanel", SearchPanelWidget.Create)
