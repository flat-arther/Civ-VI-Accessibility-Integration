-- CAIWidgetHelpers_PediaLookup.lua
-- Civilopedia lookup helper: extracts search terms from widgets or plots,
-- queries the Civilopedia search context, and presents results.

CAIWidgetHelpers_PediaLookup = {}
local P = CAIWidgetHelpers_PediaLookup

local MAX_RESULTS = 20

local function StripIconTokens(text)
    if not text or text == "" then return "" end
    return text:gsub("%[([^%]]-)%]", ""):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
end

local function IsGameWorldType(wType)
    return wType == "GameView" or wType == "InterfaceMode"
end

local function FindAncestorType(widget)
    local w = widget
    while w do
        if IsGameWorldType(w.Type) then return w.Type end
        w = w.Parent
    end
    return nil
end

--#region Section/group name lookup

local g_sectionNameCache = nil
local g_pageGroupCache = nil

local function BuildSectionNameCache()
    if g_sectionNameCache then return end
    g_sectionNameCache = {}
    if GameInfo.CivilopediaSections then
        for row in GameInfo.CivilopediaSections() do
            if row.Name then
                g_sectionNameCache[row.SectionId] = Locale.Lookup(row.Name)
            end
        end
    end
end

local function BuildPageGroupCache()
    if g_pageGroupCache then return end
    g_pageGroupCache = {}

    if GameInfo.CivilopediaPageGroups then
        for row in GameInfo.CivilopediaPageGroups() do
            if row.Name then
                local key = row.SectionId .. "|" .. row.PageGroupId
                g_pageGroupCache[key] = Locale.Lookup(row.Name)
            end
        end
    end

    if GameInfo.CivilopediaPageGroupQueries then
        for q in GameInfo.CivilopediaPageGroupQueries() do
            for _, row in ipairs(DB.Query(q.SQL)) do
                local pgId = q.PageGroupIdColumn and row[q.PageGroupIdColumn]
                local name = row[q.NameColumn]
                if pgId and name then
                    local key = q.SectionId .. "|" .. pgId
                    if not g_pageGroupCache[key] then
                        g_pageGroupCache[key] = Locale.Lookup(name)
                    end
                end
            end
        end
    end
end

local function GetSectionName(sectionId)
    BuildSectionNameCache()
    return g_sectionNameCache[sectionId]
end

local function GetPageGroupName(sectionId, pageId)
    BuildPageGroupCache()
    local pageGroupId = nil

    if GameInfo.CivilopediaPages then
        for row in GameInfo.CivilopediaPages() do
            if row.SectionId == sectionId and row.PageId == pageId and row.PageGroupId then
                pageGroupId = row.PageGroupId
                break
            end
        end
    end

    if not pageGroupId and GameInfo.CivilopediaPageQueries then
        for q in GameInfo.CivilopediaPageQueries() do
            for _, row in ipairs(DB.Query(q.SQL)) do
                if q.SectionId == sectionId and row[q.PageIdColumn] == pageId then
                    pageGroupId = q.PageGroupIdColumn and row[q.PageGroupIdColumn]
                    break
                end
            end
            if pageGroupId then break end
        end
    end

    if not pageGroupId then return nil end
    return g_pageGroupCache[sectionId .. "|" .. pageGroupId]
end

local function FormatResultLabel(pageTitle, sectionId, pageId)
    local parts = { pageTitle }
    local sectionName = GetSectionName(sectionId)
    if sectionName then
        parts[#parts + 1] = sectionName
    end
    local groupName = GetPageGroupName(sectionId, pageId)
    if groupName then
        parts[#parts + 1] = groupName
    end
    return table.concat(parts, ", ")
end

--#endregion

--#region Plot term collection

local function CollectPlotTerms(plot)
    if not plot then return {} end

    local info = ExposedMembers.CAIInfo

    local eObserverPlayerID = Game.GetLocalObserver()
    if eObserverPlayerID ~= PlayerTypes.OBSERVER then
        local vis = PlayersVisibility[eObserverPlayerID]
        if not vis or not vis:IsRevealed(plot:GetIndex()) then
            return {}
        end
    end

    local unitTerms = {}
    local ownerTerms = {}
    local districtTerms = {}
    local wonderTerms = {}
    local resourceTerms = {}
    local improvementTerms = {}
    local featureTerms = {}
    local terrainTerms = {}

    -- Units
    if info and info.RequestUnitNamesInPlot then
        local unitNames = info:RequestUnitNamesInPlot(plot:GetX(), plot:GetY())
        if unitNames then
            for _, name in ipairs(unitNames) do
                unitTerms[#unitTerms + 1] = name
            end
        end
    end

    -- Owner civ / city-state
    local ownerID = plot:GetOwner()
    if ownerID ~= -1 then
        local playerConfig = PlayerConfigurations[ownerID]
        if playerConfig then
            local player = Players[ownerID]
            if player and player.IsMinor and player:IsMinor() then
                local owningCity = Cities.GetPlotPurchaseCity(plot)
                if owningCity then
                    ownerTerms[#ownerTerms + 1] = Locale.Lookup(owningCity:GetName())
                end
            else
                local civDesc = playerConfig:GetCivilizationShortDescription()
                if civDesc then
                    ownerTerms[#ownerTerms + 1] = Locale.Lookup(civDesc)
                end
            end
        end
    end

    -- District
    local districtIdx = plot:GetDistrictType()
    if districtIdx ~= -1 then
        local districtInfo = GameInfo.Districts[districtIdx]
        if districtInfo and not districtInfo.InternalOnly then
            districtTerms[#districtTerms + 1] = Locale.Lookup(districtInfo.Name)
        end
    end

    -- Wonder
    local wonderIdx = plot:GetWonderType()
    if wonderIdx ~= -1 then
        local wonderInfo = GameInfo.Buildings[wonderIdx]
        if wonderInfo then
            wonderTerms[#wonderTerms + 1] = Locale.Lookup(wonderInfo.Name)
        end
    end

    -- Resource
    local resourceIdx = plot:GetResourceType()
    if resourceIdx ~= -1 then
        local resourceInfo = GameInfo.Resources[resourceIdx]
        if resourceInfo then
            local localPlayer = Players[Game.GetLocalPlayer()]
            if localPlayer then
                local playerResources = localPlayer:GetResources()
                if playerResources:IsResourceVisible(resourceInfo.Hash) then
                    resourceTerms[#resourceTerms + 1] = Locale.Lookup(resourceInfo.Name)
                end
            end
        end
    end

    -- Improvement
    local improvementIdx = plot:GetImprovementType()
    if improvementIdx ~= -1 then
        local improvementInfo = GameInfo.Improvements[improvementIdx]
        if improvementInfo then
            improvementTerms[#improvementTerms + 1] = Locale.Lookup(improvementInfo.Name)
        end
    end

    -- Feature
    local featureIdx = plot:GetFeatureType()
    if featureIdx ~= -1 then
        local featureInfo = GameInfo.Features[featureIdx]
        if featureInfo then
            featureTerms[#featureTerms + 1] = Locale.Lookup(featureInfo.Name)
        end
    end

    -- Terrain
    local terrainIdx = plot:GetTerrainType()
    if terrainIdx ~= -1 then
        local terrainInfo = GameInfo.Terrains[terrainIdx]
        if terrainInfo then
            terrainTerms[#terrainTerms + 1] = Locale.Lookup(terrainInfo.Name)
        end
    end

    -- Ordered: units, district, wonder, resource, improvement, owner/city-state, feature, terrain
    local terms = {}
    local function append(src)
        for _, v in ipairs(src) do terms[#terms + 1] = v end
    end
    append(unitTerms)
    append(districtTerms)
    append(wonderTerms)
    append(resourceTerms)
    append(improvementTerms)
    append(ownerTerms)
    append(featureTerms)
    append(terrainTerms)

    return terms
end

--#endregion

--#region Search

local function SearchPedia(terms)
    if not terms or #terms == 0 then return {} end

    local seen = {}
    local results = {}
    for _, term in ipairs(terms) do
        local raw = Search.Search("Civilopedia", term, MAX_RESULTS)
        if raw then
            for _, hit in ipairs(raw) do
                local key = hit[1]
                if not seen[key] then
                    seen[key] = true
                    local sectionId, pageId = string.match(key, "([^|]+)|([^|]+)")
                    if sectionId and pageId then
                        local pageTitle = Locale.Lookup(pageId)
                        if pageTitle == pageId then
                            pageTitle = StripIconTokens(hit[2] or key)
                        else
                            pageTitle = StripIconTokens(pageTitle)
                        end
                        if pageTitle == "" then pageTitle = pageId end

                        results[#results + 1] = {
                            sectionId = sectionId,
                            pageId = pageId,
                            label = FormatResultLabel(pageTitle, sectionId, pageId),
                        }
                    end
                end
                if #results >= MAX_RESULTS then return results end
            end
        end
    end
    return results
end

--#endregion

--#region Public API

function P.CollectTerms(widget)
    if FindAncestorType(widget) then
        local cursor = ExposedMembers.CAICursor
        if not cursor then return {} end
        local plotId = cursor:GetPlotId()
        if not plotId or plotId < 0 then return {} end
        local plot = Map.GetPlotByIndex(plotId)
        return CollectPlotTerms(plot)
    end

    local speech = widget:BuildSpeech({ "label" })
    if not speech or speech == "" then return {} end

    local terms = {}
    for raw in speech:gmatch("[^,]+") do
        local term = raw:match("^%s*(.-)%s*$")
        if term and term ~= "" then
            terms[#terms + 1] = StripIconTokens(term)
        end
    end
    return terms
end

local g_lookupOpen = false

function P.RunLookup(widget)
    if not Search or not Search.HasContext or not Search.HasContext("Civilopedia") then
        LogWarn("PediaLookup RunLookup aborted because Civilopedia search context is unavailable")
        return false
    end
    if g_lookupOpen then
        LogWarn("PediaLookup RunLookup ignored because lookup UI is already open")
        return false
    end

    local mgr = widget.Manager
    if not mgr then
        LogWarn("PediaLookup RunLookup called without manager")
        return false
    end

    local terms = P.CollectTerms(widget)
    if #terms == 0 then
        LogMessage("PediaLookup RunLookup found no lookup terms")
        Speak(Locale.Lookup("LOC_CAI_PEDIA_LOOKUP_NO_TERMS"))
        return true
    end

    local results = SearchPedia(terms)
    LogMessage("PediaLookup searched Civilopedia, terms=" .. tostring(#terms) .. ", results=" .. tostring(#results))

    if #results == 0 then
        Speak(Locale.Lookup("LOC_CAI_PEDIA_LOOKUP_NO_RESULTS"))
        return true
    end

    if #results == 1 then
        LogMessage("PediaLookup opening single result " .. tostring(results[1].sectionId) .. "|" .. tostring(results[1].pageId))
        LuaEvents.OpenCivilopedia(results[1].sectionId, results[1].pageId)
        return true
    end

    local root = mgr:GetTop()

    local panelId = mgr:GenerateWidgetId("CAI_PediaLookup")
    local panel = mgr:CreateWidget(panelId, "Panel", {
        Transparent = true,
        WrapAround = true,
        TrapInput = true
    })
    panel:On("focus_enter", function() Input.SetActiveContext(InputContext.Shell) end)
    local listId = panelId .. "_List"
    local list = mgr:CreateWidget(listId, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_PEDIA_LOOKUP_RESULTS") end,
    })

    local previousFocus = mgr:GetFocusedWidget()

    g_lookupOpen = true

    local function CloseLookup()
        g_lookupOpen = false
        panel:Destroy()
        if previousFocus then mgr:SetFocus(previousFocus) end
        LogMessage("PediaLookup closed lookup UI")
    end

    for _, r in ipairs(results) do
        local itemId = mgr:GenerateWidgetId("CAI_PediaLookupItem")
        local item = mgr:CreateWidget(itemId, "MenuItem", {
            Label = r.label,
        })
        item:On("activate", function()
            LuaEvents.OpenCivilopedia(r.sectionId, r.pageId)
            CloseLookup()
        end)
        list:AddChild(item)
    end

    panel:AddChild(list)
    panel:AddInputBindings({ {
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseLookup()
            return true
        end,
    },
        { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function() return true end },
        { Key = Keys.VK_UP,   MSG = KeyEvents.KeyDown, Action = function() return true end },
    })

    root:AddChild(panel)
    mgr:SetFocus(list)
    LogMessage("PediaLookup opened results list with " .. tostring(#results) .. " items")
    return true
end

--#endregion
