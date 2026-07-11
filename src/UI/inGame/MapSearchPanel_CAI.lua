-- MapSearchPanel_CAI.lua
-- Wildcard-included by vanilla's include("MapSearchPanel_", true).
-- Runs in the MapSearchPanel Lua context after base + expansion overrides.
-- Bridges vanilla map search to the CAI SearchPanel via LuaEvents.
--
-- Since vanilla's state variables (m_Search, m_ResultPlots, m_ResultGroups,
-- m_nLastPlotSearched, etc.) are all local, this file maintains its own
-- parallel state and overrides the key global functions.

include("caiUtils")
include("hexCoordUtils_CAI")

local mgr = ExposedMembers.CAI_UIManager
local HexCoordUtils = CAIHexCoordUtils
local CAICursor = ExposedMembers.CAICursor

local CAI_PLOTS_PER_FRAME = 35
local DEBOUNCE_FRAMES = 20
local PROGRESS_THRESHOLD = 0.10

local CAI_PANEL_ID = "CAIMapSearch_Panel"
local CAI_CONTAINER_ID = "CAIMapSearch_Container"

local m_container = nil ---@type ContainerWidget|nil
local m_searchPanel = nil ---@type SearchPanelWidget|nil
local m_debounceCounter = -1
local m_pendingQuery = ""
local m_lastSpokenPercent = -1
local m_isSearching = false

local m_caiSearch = { Whitelist = {}, Blacklist = {} }
local m_caiLastPlotSearched = -1
local m_caiResultPlots = {}
local m_caiFocusedResult = 0
local m_historySeeded = false
--#endregion

--#region Debounce

local function StopDebounce()
    m_debounceCounter = -1
end

local function OnDebounceUpdate()
    if m_debounceCounter < 0 then
        ContextPtr:ClearUpdate()
        return
    end
    m_debounceCounter = m_debounceCounter - 1
    if m_debounceCounter <= 0 then
        m_debounceCounter = -1
        if m_pendingQuery == "" then
            OnClearSearchButton()
            if m_searchPanel then
                m_searchPanel:SetResults({})
            end
            return
        end

        local whitelist = {}
        local blacklist = {}
        for term in m_pendingQuery:gmatch("%S+") do
            if term:sub(1, 2) == "--" and #term > 2 then
                blacklist[#blacklist + 1] = term:sub(3)
            else
                whitelist[#whitelist + 1] = term
            end
        end

        local searchText = table.concat(whitelist, " ")
        local filterText = table.concat(blacklist, " ")
        Controls.MapSearchBox:SetText(searchText)
        Controls.MapSearchFilterBox:SetText(filterText)
        OnSearchCommit()
    end
end

local function StartDebounce(query)
    if m_isSearching then
        ClearSearch(true)
        m_isSearching = false
    end
    m_pendingQuery = query or ""
    if m_pendingQuery == "" then
        StopDebounce()
        OnClearSearchButton()
        if m_searchPanel then
            m_searchPanel:SetResults({})
        end
        return
    end
    m_debounceCounter = DEBOUNCE_FRAMES
    ContextPtr:SetUpdate(OnDebounceUpdate)
end

--#endregion

--#region Search completion → populate CAI results

local function GetPlotLabel(plotIndex)
    local plot = Map.GetPlotByIndex(plotIndex)
    local parts = {}

    if CAICursor and CAICursor.curX and CAICursor.curY and plot then
        local dir = HexCoordUtils.directionString(CAICursor.curX, CAICursor.curY, plot:GetX(), plot:GetY())
        if dir ~= "" then
            parts[#parts + 1] = dir
        end
    end

    local plotInfo = ExposedMembers.CAIInfo
    if plotInfo and plotInfo.RequestCursorMovePlotInfo then
        local infoParts = plotInfo:RequestCursorMovePlotInfo(nil, plotIndex)
        if infoParts then
            for _, v in ipairs(infoParts) do
                parts[#parts + 1] = v
            end
        end
    end

    if #parts > 0 then
        return table.concat(parts, ", ")
    end

    if plot then
        return Locale.Lookup("LOC_CAI_VALID_TARGET_PLOT", plot:GetX(), plot:GetY())
    end
    return tostring(plotIndex)
end

local function OnSearchComplete()
    if not mgr or not m_searchPanel then return end

    local totalPlots = #m_caiResultPlots

    if totalPlots == 0 then
        m_searchPanel:SetResults({})
        Speak(Locale.Lookup("LOC_CAI_SEARCH_NO_RESULTS"))
        return
    end

    Speak(Locale.Lookup("LOC_CAI_MAP_SEARCH_COMPLETE", totalPlots))

    if CAICursor and CAICursor.curX and CAICursor.curY then
        local cx, cy = CAICursor.curX, CAICursor.curY
        table.sort(m_caiResultPlots, function(a, b)
            local pa = Map.GetPlotByIndex(a)
            local pb = Map.GetPlotByIndex(b)
            if not pa or not pb then return false end
            return Map.GetPlotDistance(cx, cy, pa:GetX(), pa:GetY())
                < Map.GetPlotDistance(cx, cy, pb:GetX(), pb:GetY())
        end)
    end

    local results = {}
    for i, iPlot in ipairs(m_caiResultPlots) do
        local plot = Map.GetPlotByIndex(iPlot)
        local label = GetPlotLabel(iPlot)
        results[#results + 1] = {
            key = "mapplot_" .. iPlot,
            label = label,
            onActivate = function()
                if plot then
                    LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
                end
            end,
        }
    end
    m_searchPanel:SetResults(results)
end

--#endregion

--#region Override CheckForMatches (uses CAI-owned result state)

function CheckForMatches()
    Search.Optimize(SEARCHCONTEXT_MAPSEARCH)

    local kResultCounters = {}
    local nRequiredCount = 0

    for _, key in pairs(m_caiSearch.Whitelist) do
        local kResults = Search.Search(SEARCHCONTEXT_MAPSEARCH, key, CAI_PLOTS_PER_FRAME)
        if kResults == nil or #kResults == 0 then
            return
        end

        nRequiredCount = nRequiredCount + 1
        for _, result in pairs(kResults) do
            local iPlot = tonumber(result[1])
            if kResultCounters[iPlot] == nil then
                kResultCounters[iPlot] = 1
            else
                kResultCounters[iPlot] = kResultCounters[iPlot] + 1
            end
        end
    end

    for _, key in pairs(m_caiSearch.Blacklist) do
        local kResults = Search.Search(SEARCHCONTEXT_MAPSEARCH, key, CAI_PLOTS_PER_FRAME)
        if kResults ~= nil and #kResults > 0 then
            for _, result in pairs(kResults) do
                local iPlot = tonumber(result[1])
                kResultCounters[iPlot] = -1
            end
        end
    end

    for iPlot, nCount in pairs(kResultCounters) do
        if nCount >= nRequiredCount then
            table.insert(m_caiResultPlots, iPlot)
        end
    end
end

--#endregion

--#region Override ClearSearch (uses CAI-owned state)

function ClearSearch(bFullClear)
    StopSearch()
    m_isSearching = false

    if bFullClear then
        local pOverlay = UILens.GetOverlay("MapSearch")
        if pOverlay ~= nil then
            pOverlay:ClearAll()
        end
        m_caiSearch.Whitelist = {}
        m_caiSearch.Blacklist = {}
    end

    Controls.NextResultButton:SetDisabled(true)
    Controls.PrevResultButton:SetDisabled(true)

    m_caiResultPlots = {}
    m_caiFocusedResult = 0
    m_caiLastPlotSearched = -1
    m_lastSpokenPercent = -1
end

--#endregion

--#region Override IncrementalSearch (uses CAI-owned state + progress speech)

function IncrementalSearch()
    m_isSearching = true

    local eObserverID = Game.GetLocalObserver()
    local pPlayerVis = PlayersVisibility[eObserverID]
    local nPlotsCheckedThisFrame = 0

    Search.ClearData(SEARCHCONTEXT_MAPSEARCH)

    local nPlots = Map.GetPlotCount()
    for iPlot = m_caiLastPlotSearched + 1, nPlots - 1 do
        if pPlayerVis:IsRevealed(iPlot) then
            local szPlotString = tostring(iPlot)
            local pInfo = GetPlotInfo(iPlot)
            if pInfo then
                Search.AddData(SEARCHCONTEXT_MAPSEARCH, szPlotString, "", "", pInfo)
            end

            nPlotsCheckedThisFrame = nPlotsCheckedThisFrame + 1
            if nPlotsCheckedThisFrame == CAI_PLOTS_PER_FRAME then
                CheckForMatches()
                local percent = iPlot / (nPlots - 1)
                Controls.ProgressBar:SetPercent(percent)
                m_caiLastPlotSearched = iPlot

                if percent - m_lastSpokenPercent >= PROGRESS_THRESHOLD then
                    m_lastSpokenPercent = math.floor(percent / PROGRESS_THRESHOLD) * PROGRESS_THRESHOLD
                    local pct = math.floor(m_lastSpokenPercent * 100)
                    Speak(pct .. "%")
                end
                return
            end
        end
    end

    CheckForMatches()

    local pOverlay = UILens.GetOverlay("MapSearch")
    if pOverlay ~= nil then
        pOverlay:ClearAll()
        pOverlay:SetPlotChannel(m_caiResultPlots, 0)
    end

    Controls.ProgressBar:SetPercent(1.0)
    Controls.ResultsLabel:SetText(Locale.Lookup("LOC_HUD_MAP_SEARCH_RESULTS", #m_caiResultPlots))

    local bDisableButtons = not (#m_caiResultPlots > 0)
    Controls.NextResultButton:SetDisabled(bDisableButtons)
    Controls.PrevResultButton:SetDisabled(bDisableButtons)

    StopSearch()
    m_isSearching = false

    UI.MapSearch_LogEnd("Complete with " .. tostring(#m_caiResultPlots) .. " results")

    OnSearchComplete()
end

--#endregion

--#region Override OnSearchCommit (uses CAI-owned state)

function OnSearchCommit()
    ClearSearch(true)

    local szSearchString = Controls.MapSearchBox:GetText()
    local szFilterString = Controls.MapSearchFilterBox:GetText()

    m_caiSearch.Whitelist = szSearchString and Locale.SplitString(szSearchString) or {}
    m_caiSearch.Blacklist = szFilterString and Locale.SplitString(szFilterString) or {}
    Controls.MapSearchBox:DropFocus()
    Controls.MapSearchFilterBox:DropFocus()

    if ValidateSearchTerms_CAI() and g_bMapSearchInitialized then
        if m_searchPanel then
            local combined = szSearchString or ""
            if szFilterString and szFilterString ~= "" then
                for term in szFilterString:gmatch("%S+") do
                    combined = combined .. " --" .. term
                end
            end
            m_searchPanel:AddHistoryItem(combined)
        end

        m_lastSpokenPercent = -1
        Controls.ProgressBar:SetPercent(0.0)
        Controls.ResultsLabel:SetText(Locale.Lookup("LOC_HUD_MAP_SEARCH_IN_PROGRESS"))
        Speak(Locale.Lookup("LOC_CAI_MAP_SEARCH_SEARCHING"))
        UI.MapSearch_LogBegin(m_caiSearch.Whitelist, m_caiSearch.Blacklist)
        ContextPtr:SetUpdate(IncrementalSearch)

        local pOverlay = UILens.GetOverlay("MapSearch")
        if pOverlay ~= nil then
            pOverlay:SetVisible(true)
            pOverlay:ShowHighlights(true)
            local COLOR_WHITE = UI.GetColorValueFromHexLiteral(0xFFFFFFFF)
            local COLOR_GREEN = UI.GetColorValueFromHexLiteral(0x2800FF00)
            pOverlay:SetBorderColors(0, COLOR_WHITE, COLOR_WHITE)
            pOverlay:SetHighlightColor(0, COLOR_GREEN)
        end
    end
end

-- CAI-owned validation since m_Search is local to the base file
function ValidateSearchTerms_CAI()
    for _, pTermWL in ipairs(m_caiSearch.Whitelist) do
        for i, pTermBL in ipairs(m_caiSearch.Blacklist) do
            local pLowerWL = Locale.ToLower(pTermWL)
            local pLowerBL = Locale.ToLower(pTermBL)
            if Locale.Compare(pLowerWL, pLowerBL) == 0 then
                m_caiSearch.Blacklist[i] = ""
            end
        end
    end

    if #m_caiSearch.Whitelist > 0 then
        return true
    end
    return false
end

--#endregion

--#region Override OnNextResult / OnPrevResult (uses CAI-owned state)

function OnNextResult()
    if #m_caiResultPlots == 0 then return end
    m_caiFocusedResult = m_caiFocusedResult + 1
    if m_caiFocusedResult > #m_caiResultPlots then
        m_caiFocusedResult = 1
    end
    local plotIndex = m_caiResultPlots[m_caiFocusedResult]
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot then
        LuaEvents.CAICursorMoveTo(plotIndex, "jump")
    end
end

function OnPrevResult()
    if #m_caiResultPlots == 0 then return end
    m_caiFocusedResult = m_caiFocusedResult - 1
    if m_caiFocusedResult <= 0 then
        m_caiFocusedResult = #m_caiResultPlots
    end
    local plotIndex = m_caiResultPlots[m_caiFocusedResult]
    local plot = Map.GetPlotByIndex(plotIndex)
    if plot then
        LuaEvents.CAICursorMoveTo(plotIndex, "jump")
    end
end

--#endregion

--#region Override OnClearSearchButton

function OnClearSearchButton()
    ClearSearch(true)
    Controls.MapSearchBox:ClearString()
    Controls.MapSearchFilterBox:ClearString()
    Controls.ResultsLabel:SetText("")
end

--#endregion

--#region Override RefreshMapSearchResults (turn-change re-search)

function RefreshMapSearchResults()
    if ValidateSearchTerms_CAI() and g_bMapSearchInitialized then
        LogMessage("CAI MapSearchPanel refreshing search results")
        ClearSearch(false)
        Controls.ProgressBar:SetPercent(0.0)
        Controls.ResultsLabel:SetText(Locale.Lookup("LOC_HUD_MAP_SEARCH_UPDATING"))
        m_lastSpokenPercent = -1
        UI.MapSearch_LogBegin(m_caiSearch.Whitelist, m_caiSearch.Blacklist)
        ContextPtr:SetUpdate(IncrementalSearch)
    end
end

--#endregion

--#region CAI SearchPanel lifecycle

local function CloseSearchPanel()
    StopDebounce()
    if m_isSearching then
        ClearSearch(true)
        m_isSearching = false
    end
    if m_searchPanel then
        m_searchPanel:Close(true)
        m_searchPanel = nil
    end
    if m_container then
        mgr:RemoveFromStack(m_container.Id)
        m_container:Destroy()
        m_container = nil
    end
end

local function OpenSearchPanel()
    LogMessage("CAI MapSearchPanel OpenSearchPanel mgr="
        .. tostring(mgr) .. " existingPanel=" .. tostring(m_searchPanel))
    if not mgr then return end
    if m_searchPanel then return end

    local container = mgr:CreateWidget(mgr:GenerateWidgetId(CAI_CONTAINER_ID), "Panel", {
        Label = function() return Locale.Lookup("LOC_HUD_MAP_SEARCH") end,
    })
    if not container then return end

    local panel = mgr:CreateWidget(mgr:GenerateWidgetId(CAI_PANEL_ID), "SearchPanel")
    if not panel then
        container:Destroy()
        return
    end

    panel:SetHistoryContext("MapSearch")

    if not m_historySeeded then
        m_historySeeded = true
        panel:AddHistoryItem(Locale.Lookup("LOC_RESOURCE_ANTIQUITY_SITE_NAME"))
        panel:AddHistoryItem(Locale.Lookup("LOC_IMPROVEMENT_GOODY_HUT_NAME"))
        panel:AddHistoryItem(Locale.Lookup("LOC_TOOLTIP_LUXURY_RESOURCE"))
        panel:AddHistoryItem(Locale.Lookup("LOC_TOOLTIP_STRATEGIC_RESOURCE"))
    end

    panel:On("search_text_changed", function(_, text)
        StartDebounce(text)
    end)

    panel:On("search_close", function()
        StopDebounce()
        if m_isSearching then
            ClearSearch(true)
            m_isSearching = false
        end
        m_searchPanel = nil
        if m_container then
            mgr:RemoveFromStack(m_container.Id)
            m_container:Destroy()
            m_container = nil
        end
        LuaEvents.CAIMapSearch_RequestClose()
    end)

    container:AddChild(panel)
    m_searchPanel = panel
    m_container = container
    mgr._searchPanel = panel

    mgr:Push(container, { focus = panel._editBox })
end

--#endregion

--#region Vanilla panel open/close hooks

OnMapSearchPanelOpened = WrapFunc(OnMapSearchPanelOpened, function(orig)
    LogMessage("CAI MapSearchPanel opened")
    orig()
    Controls.MapSearchBox:DropFocus()
    Controls.MapSearchFilterBox:DropFocus()
    OpenSearchPanel()
end)

OnMapSearchPanelClosed = WrapFunc(OnMapSearchPanelClosed, function(orig)
    LogMessage("CAI MapSearchPanel closed")
    orig()
    CloseSearchPanel()
end)

--#endregion

--#region Override OnInputHandler to route through mgr

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_searchPanel then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return true end
    end
    return orig(pInputStruct)
end)

--#endregion
