include("caiUtils")
include("HistoricMoments")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID     = "CAITimeline_Panel"
local TREE_ID      = "CAITimeline_Tree"
local HOVER_SOUND  = "Main_Menu_Mouse_Over"

local MIN_INTEREST_LEVEL_CAI = 1

local m_panel = nil
local m_tree  = nil

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[,%s]+,", ",")
    text = string.gsub(text, "^[,%s]+", "")
    text = string.gsub(text, "[,%s]+$", "")
    return text
end

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, p in ipairs(parts) do
        if p and p ~= "" then
            table.insert(out, p)
        end
    end
    return table.concat(out, sep)
end

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeLeaf(focusKey, labelFn)
    local w = mgr:CreateWidget(MakeId("CAITl_"), "StaticText", {
        FocusKey = focusKey,
        Label = labelFn,
    })
    w:SetFocusSound(HOVER_SOUND)
    return w
end

local function MakeNode(focusKey, labelFn)
    local w = mgr:CreateWidget(MakeId("CAITl_"), "TreeItem", {
        FocusKey = focusKey,
        Label = labelFn,
    })
    w:SetFocusSound(HOVER_SOUND)
    return w
end

local function FormatMomentLabel(momentData)
    local parts = {}
    table.insert(parts, Locale.Lookup("LOC_CAI_TIMELINE_TURN", momentData.Turn))
    local momentInfo = GameInfo.Moments[momentData.Type]
    if momentInfo then
        local genDesc = Locale.Lookup(momentInfo.Description)
        if genDesc and genDesc ~= "" then
            table.insert(parts, NormalizeText(genDesc))
        end
    end
    return JoinNonEmpty(parts, ", ")
end

local function FormatMomentTooltip(momentData)
    local parts = {}

    local score = momentData.EraScore or 0
    if score > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_TIMELINE_ERA_SCORE", score))
    end

    if momentData.HasEverBeenCommemorated then
        table.insert(parts, Locale.Lookup("LOC_CAI_TIMELINE_COMMEMORATED"))
    end

    table.insert(parts, Calendar.MakeYearStr(momentData.Turn))

    local desc = momentData.InstanceDescription
    if not desc or desc == "" then
        local momentInfo = GameInfo.Moments[momentData.Type]
        desc = momentInfo and Locale.Lookup(momentInfo.Name) or ""
    end
    table.insert(parts, NormalizeText(desc))

    return JoinNonEmpty(parts, ", ")
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tree  = nil
end

local function BuildPanel()
    if not mgr then return end
    PopPanel()

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then return end

    local allMoments = Game.GetHistoryManager():GetAllMomentsData(localPlayerID, MIN_INTEREST_LEVEL_CAI)
    local momentCount = allMoments and #allMoments or 0

    m_tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function()
            if momentCount > 0 then
                return Locale.Lookup("LOC_CAI_TIMELINE_COUNT", momentCount)
            end
            return Locale.Lookup("LOC_CAI_TIMELINE_TITLE")
        end,
    })

    if momentCount == 0 then
        local emptyLeaf = MakeLeaf("timeline:empty", function()
            return Controls.EmptyTimelineMessage:GetText()
                or Locale.Lookup("LOC_MOMENT_NO_MOMENTS_TO_SHOW")
        end)
        m_tree:AddChild(emptyLeaf)
    else
        local eraGroups = {}
        local eraOrder  = {}

        for i = #allMoments, 1, -1 do
            local md = allMoments[i]
            local eraIdx = md.GameEra
            if not eraGroups[eraIdx] then
                eraGroups[eraIdx] = {}
                table.insert(eraOrder, eraIdx)
            end
            table.insert(eraGroups[eraIdx], md)
        end

        for _, eraIdx in ipairs(eraOrder) do
            local eraMoments = eraGroups[eraIdx]
            local eraData = GameInfo.Eras[eraIdx]
            local eraName = eraData and Locale.Lookup(eraData.Name) or tostring(eraIdx)
            local eraCount = #eraMoments

            local eraNode = MakeNode("timeline:era:" .. eraIdx, function()
                return eraName .. ", " .. Locale.Lookup("LOC_CAI_TIMELINE_COUNT", eraCount)
            end)

            local majorMoments = {}
            local minorMoments = {}
            for _, md in ipairs(eraMoments) do
                local momentInfo = GameInfo.Moments[md.Type]
                if momentInfo and momentInfo.InterestLevel > MIN_INTEREST_LEVEL_CAI then
                    table.insert(majorMoments, md)
                else
                    table.insert(minorMoments, md)
                end
            end

            if #majorMoments > 0 then
                local majorNode = MakeNode("timeline:era:" .. eraIdx .. ":major", function()
                    return Locale.Lookup("LOC_PEDIA_MOMENTS_PAGEGROUP_MAJOR_NAME") .. ", " .. Locale.Lookup("LOC_CAI_TIMELINE_COUNT", #majorMoments)
                end)
                for _, md in ipairs(majorMoments) do
                    local capturedMD = md
                    local leaf = MakeLeaf("timeline:moment:" .. md.ID, function()
                        return FormatMomentLabel(capturedMD)
                    end)
                    leaf:SetTooltip(function() return FormatMomentTooltip(capturedMD) end)
                    majorNode:AddChild(leaf)
                end
                eraNode:AddChild(majorNode)
            end

            if #minorMoments > 0 then
                local minorNode = MakeNode("timeline:era:" .. eraIdx .. ":minor", function()
                    return Locale.Lookup("LOC_PEDIA_MOMENTS_PAGEGROUP_MINOR_NAME") .. ", " .. Locale.Lookup("LOC_CAI_TIMELINE_COUNT", #minorMoments)
                end)
                for _, md in ipairs(minorMoments) do
                    local capturedMD = md
                    local leaf = MakeLeaf("timeline:moment:" .. md.ID, function()
                        return FormatMomentLabel(capturedMD)
                    end)
                    leaf:SetTooltip(function() return FormatMomentTooltip(capturedMD) end)
                    minorNode:AddChild(leaf)
                end
                eraNode:AddChild(minorNode)
            end

            m_tree:AddChild(eraNode)
        end
    end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local title = Controls.ModalScreenTitle:GetText()
            if not title or title == "" then
                title = Locale.Lookup("LOC_CAI_TIMELINE_TITLE")
            end
            return title
        end,
    })
    m_panel:AddChild(m_tree)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Action = function()
                Close()
                return true
            end,
        },
    })
end

local function PushPanel()
    if not mgr then return end
    if not m_panel then BuildPanel() end
    if not m_panel then return end
    mgr:Push(m_panel, GetPopupPriority())
end

local function OnShow()
    if mgr then
        PushPanel()
    end
end

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

local function HandleInput(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return false
end
ContextPtr:SetInputHandler(HandleInput, true)
ContextPtr:SetShowHandler(OnShow)
