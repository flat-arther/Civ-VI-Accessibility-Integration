-- GovernorPanel_CAI.lua
--
-- Accessibility layer for the Governor Panel.
-- Replaces the vanilla GovernorPanel LuaContext. Re-includes the correct
-- expansion version, then wraps Open/Close/Refresh to overlay a single
-- CAI browsing surface: a governor Tree with a sibling promotions view.

include("caiUtils")
include("GameCapabilities")
include("GovernorPanel")

local mgr = ExposedMembers.CAI_UIManager
if not HasCapability("CAPABILITY_GOVERNORS") then return end

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID                        = "CAIGovernorPanel_Panel"
local TREE_ID                         = "CAIGovernorPanel_Tree"
local PROMO_TABLE_ID                  = "CAIGovernorPanel_PromoTable"
local PROMO_LIST_ID                   = "CAIGovernorPanel_PromoList"

local HOVER_SOUND                     = "Main_Menu_Mouse_Over"

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui                            = {
    panel      = nil,
    tree       = nil,
    promoTable = nil,
    promoList  = nil,
}

local m_focusedGovernorIndex          = -1
local m_isReadOnly                    = false
local m_cityBannerPlayerID            = -1
local m_cityBannerCityID              = -1
local m_liveGovernorRows              = {}
local m_pendingPromotionFocusKey      = nil
local m_pendingPromotionGovernorIndex = -1

-- ===========================================================================
-- Helpers
-- ===========================================================================

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
end

local function NormalizeText(text)
    if not text then return "" end
    local s = tostring(text)
    s = s:gsub("%[NEWLINE%]", " ")
    s = s:gsub("%[ICON_[^%]]*%]", "")
    s = s:gsub("  +", " ")
    return s:match("^%s*(.-)%s*$") or ""
end

local function AppendIfNonEmpty(parts, value)
    local normalized = NormalizeText(value)
    if normalized ~= "" then parts[#parts + 1] = normalized end
end

local function ControlText(control)
    if not control then return "" end
    return tostring(control:GetText() or "")
end

local function ControlTooltip(control)
    if not control then return "" end
    return tostring(control:GetToolTipString() or "")
end

local function TooltipWithValue(control, valueControl, fallbackLabel)
    local label = ControlTooltip(control)
    if label == "" and fallbackLabel then
        label = Locale.Lookup(fallbackLabel)
    end

    local value = ControlText(valueControl)
    if label ~= "" and value ~= "" then
        return label .. ": " .. value
    end
    if value ~= "" then return value end
    return label
end

local function GetPanelTitle()
    return Locale.Lookup("LOC_GOVERNORS_TITLE")
end

local function GetGovernerTitleCounts()
    local localPlayerID = Game.GetLocalPlayer()
    local pPlayer = Players[localPlayerID]
    local playerGovernors = pPlayer:GetGovernors()
    if not playerGovernors then
        return nil, nil
    end

    local governorPointsObtained = playerGovernors:GetGovernorPoints()
    local governorPointsSpent = playerGovernors:GetGovernorPointsSpent()
    local capturedAvailable = governorPointsObtained - governorPointsSpent
    local capturedSpent = governorPointsSpent
    return capturedAvailable, capturedSpent
end

local function GetTitleCountsText(fallbackAvailable, fallbackSpent)
    local parts = {}
    AppendIfNonEmpty(parts, ControlText(Controls.GovernorTitlesAvailable))
    AppendIfNonEmpty(parts, ControlText(Controls.GovernorTitlesSpent))

    if #parts == 0 and fallbackAvailable and fallbackSpent then
        AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_GOVERNOR_SUMMARY", fallbackAvailable, fallbackSpent))
    end

    return JoinNonEmpty(parts, ", ")
end

local function CaptureLiveGovernorRow(governorDef, row)
    if governorDef and row then
        m_liveGovernorRows[governorDef.Index] = row
    end
end

local function GetLiveGovernorRow(governorIndex)
    return m_liveGovernorRows[governorIndex]
end

local function GetGovernorName(governorIndex)
    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef then return "" end
    return Locale.Lookup(governorDef.Name)
end

local function GetPromotionName(promotionIndex)
    local promoDef = GameInfo.GovernorPromotions[promotionIndex]
    if not promoDef then return "" end
    return Locale.Lookup(promoDef.Name)
end

local function GetHiddenPromotionLabel()
    return Locale.Lookup("LOC_CAI_TECH_STATUS_UNREVEALED")
end

local function GetPromotionNameAndDescription(promoDef, localPlayerID, governorIndex)
    if IsPromotionHidden(promoDef.Hash, localPlayerID, governorIndex) then
        return GetHiddenPromotionLabel(), GetPromotionHiddenDescription(promoDef.Hash)
    end

    return Locale.Lookup(promoDef.Name), Locale.Lookup(promoDef.Description)
end

-- ===========================================================================
-- Data readers
-- ===========================================================================

local function GetGovernorRowLabel(governorDef, governor, playerGovernors)
    local liveRow = GetLiveGovernorRow(governorDef.Index)
    if liveRow then
        local parts = {}
        AppendIfNonEmpty(parts, ControlText(liveRow.GovernorName))
        AppendIfNonEmpty(parts, ControlText(liveRow.GovernorStatus))
        AppendIfNonEmpty(parts, ControlText(liveRow.GovernorStatusDetails))

        if governor and playerGovernors:CanPromoteGovernor(governorDef.Hash) then
            AppendIfNonEmpty(parts, Locale.Lookup("LOC_CAI_GOVERNOR_CAN_PROMOTE"))
        end

        local liveLabel = JoinNonEmpty(parts, ", ")
        if liveLabel ~= "" then return liveLabel end
    end

    local parts = {}
    parts[#parts + 1] = Locale.Lookup(governorDef.Name)

    local status, statusDetails = GetGovernorStatus(governorDef, governor)
    local statusText = NormalizeText(status)
    if statusDetails and statusDetails ~= "" then
        statusText = statusText .. " " .. NormalizeText(statusDetails)
    end
    parts[#parts + 1] = statusText

    if governor and playerGovernors:CanPromoteGovernor(governorDef.Hash) then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_CAN_PROMOTE")
    end

    return JoinNonEmpty(parts, ", ")
end

local function GetGovernorRowTooltip(governorDef, governor, playerGovernors, localPlayerID)
    local parts = {}
    local isSecret = IsCannotAssign(governorDef)
    local liveRow = GetLiveGovernorRow(governorDef.Index)

    if liveRow then
        AppendIfNonEmpty(parts, ControlText(liveRow.GovernorTitle))
        if not isSecret then
            AppendIfNonEmpty(parts,
                TooltipWithValue(liveRow.TransitionStrengthLabel, liveRow.TransitionStrengthLabel,
                    "LOC_GOVERNOR_TRANSITION_STRENGTH_TOOLTIP"))
            AppendIfNonEmpty(parts,
                TooltipWithValue(liveRow.IdentityPressureLabel, liveRow.IdentityPressureLabel,
                    "LOC_GOVERNOR_IDENTITY_PRESSURE_TOOLTIP"))
        end
        AppendIfNonEmpty(parts, ControlTooltip(liveRow.AssignButton))
        AppendIfNonEmpty(parts, ControlTooltip(liveRow.AppointButton))
    end

    if #parts == 0 then
        parts[#parts + 1] = Locale.Lookup(governorDef.Title)
    end

    if governor then
        local neutralized = governor:GetNeutralizedTurns()
        if neutralized > 0 then
            parts[#parts + 1] = NormalizeText(Locale.Lookup("LOC_GOVERNORS_GOVERNOR_NEUTRALIZED"))
            parts[#parts + 1] = Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_TRANSITION_TURNS", neutralized)
        end
    end

    if not isSecret and not liveRow then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_IDENTITY_PRESSURE", governorDef.IdentityPressure)
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_ESTABLISH_TURNS",
            playerGovernors:GetTurnsToEstablish(governorDef.Hash))
    end

    local earnedNames = {}
    for promotionSet in GameInfo.GovernorPromotionSets() do
        if promotionSet.GovernorType == governorDef.GovernorType then
            local promoDef = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion]
            if promoDef then
                if governor and governor:HasPromotion(promoDef.Hash) then
                    local name = GetPromotionNameAndDescription(promoDef, localPlayerID, governorDef.Index)
                    AppendIfNonEmpty(earnedNames, name)
                end
            end
        end
    end
    if #earnedNames > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_EARNED_PROMOS", table.concat(earnedNames, ", "))
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function GetPromotionCellTooltip(promoDef, governorDef, localPlayerID)
    if IsPromotionHidden(promoDef.Hash, localPlayerID, governorDef.Index) then
        return GetPromotionHiddenDescription(promoDef.Hash)
    end

    local parts = {}
    parts[#parts + 1] = Locale.Lookup(promoDef.Description)

    if IsCannotAssign(governorDef) then
        return JoinNonEmpty(parts, ", ")
    end

    local prereqNames = {}
    for row in GameInfo.GovernorPromotionPrereqs() do
        if row.GovernorPromotionType == promoDef.GovernorPromotionType then
            local prereqDef = GameInfo.GovernorPromotions[row.PrereqGovernorPromotion]
            if prereqDef then
                prereqNames[#prereqNames + 1] = Locale.Lookup(prereqDef.Name)
            end
        end
    end
    if #prereqNames > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_REQUIRES", table.concat(prereqNames, ", "))
    end

    local leadsToNames = {}
    for row in GameInfo.GovernorPromotionPrereqs() do
        if row.PrereqGovernorPromotion == promoDef.GovernorPromotionType then
            local targetDef = GameInfo.GovernorPromotions[row.GovernorPromotionType]
            if targetDef then
                leadsToNames[#leadsToNames + 1] = Locale.Lookup(targetDef.Name)
            end
        end
    end
    if #leadsToNames > 0 then
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_LEADS_TO", table.concat(leadsToNames, ", "))
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

-- ===========================================================================
-- Promote dialog
-- ===========================================================================

local function ShowPromoteDialog(governorIndex, promotionIndex)
    if not mgr then return end

    local governorDef = GameInfo.Governors[governorIndex]
    local promoDef = GameInfo.GovernorPromotions[promotionIndex]
    if not governorDef or not promoDef then return end
    local promotionFocusKey = "promo:" .. tostring(governorIndex) .. ":" .. promoDef.GovernorPromotionType

    local titleFn = function()
        return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTE_TITLE",
            Locale.Lookup(governorDef.Name), Locale.Lookup(promoDef.Name))
    end

    local descWidget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovDlg_Desc"), "StaticText", {
        Label = function()
            return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTE_DESC",
                Locale.Lookup(promoDef.Name), Locale.Lookup(promoDef.Description))
        end,
    })

    local confirmBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovDlg_Confirm"), "Button", {
        Label = function() return Locale.Lookup("LOC_CONFIRM") end,
    })
    confirmBtn:On("activate", function()
        local localPlayerID = Game.GetLocalPlayer()
        local pPlayer = Players[localPlayerID]
        local playerGovernors = pPlayer and pPlayer:GetGovernors()
        if not playerGovernors or m_isReadOnly or not playerGovernors:CanEarnPromotion(governorDef.Hash, promoDef.Hash) then
            return
        end

        m_pendingPromotionFocusKey = promotionFocusKey
        m_pendingPromotionGovernorIndex = governorIndex
        local kParameters = {}
        kParameters[PlayerOperations.PARAM_GOVERNOR_TYPE] = governorIndex
        kParameters[PlayerOperations.PARAM_GOVERNOR_PROMOTION_TYPE] = promotionIndex
        Speak(Locale.Lookup("LOC_CAI_GOVERNOR_FEEDBACK_PROMOTED",
            Locale.Lookup(governorDef.Name), Locale.Lookup(promoDef.Name)))
        UI.RequestPlayerOperation(localPlayerID, PlayerOperations.PROMOTE_GOVERNOR, kParameters)
        mgr:Pop()
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovDlg_Cancel"), "Button", {
        Label = function() return Locale.Lookup("LOC_CANCEL") end,
    })
    cancelBtn:On("activate", function()
        mgr:Pop()
    end)

    local dialog = mgr.WidgetHelpers.MakeGeneralDialog(titleFn, { confirmBtn, cancelBtn }, { descWidget }, 1)
    if dialog then
        mgr:Push(dialog)
    end
end

-- ===========================================================================
-- Promotion cell creation (shared by table and list)
-- ===========================================================================

local function CreatePromotionCell(promoDef, governor, governorDef, playerGovernors, localPlayerID, showHidden)
    local capturedPromoDef = promoDef
    local capturedGovDef = governorDef
    local capturedGovIndex = governorDef.Index
    local capturedPromoIndex = promoDef.Index
    local capturedHash = promoDef.Hash
    local capturedGovHash = governorDef.Hash

    local isHidden = IsPromotionHidden(capturedHash, localPlayerID, capturedGovIndex)
    if isHidden then
        local cell = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_Promo"), "MenuItem", {
            Label = function()
                return GetHiddenPromotionLabel() .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_UNREVEALED")
            end,
            Tooltip = function() return GetPromotionHiddenDescription(capturedHash) end,
            HiddenPredicate = function() return not showHidden end,
            DisabledPredicate = function() return true end,
            FocusKey = "promo:" .. tostring(capturedGovIndex) .. ":" .. capturedPromoDef.GovernorPromotionType,
        })
        cell:SetFocusSound(HOVER_SOUND)
        return cell
    end

    local function HasPromotion()
        return governor and governor:HasPromotion(capturedHash) or false
    end

    local function CanEarnPromotion()
        return playerGovernors:CanEarnPromotion(capturedGovHash, capturedHash)
    end

    local function IsPromotionDisabled()
        return capturedPromoDef.BaseAbility or m_isReadOnly or HasPromotion() or not CanEarnPromotion()
    end

    local cell = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_Promo"), "MenuItem", {
        Label = function()
            local name = Locale.Lookup(capturedPromoDef.Name)
            if capturedPromoDef.BaseAbility then
                return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_BASE_ABILITY")
            elseif HasPromotion() then
                return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_EARNED")
            elseif m_isReadOnly and CanEarnPromotion() then
                return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_READONLY_STATUS")
            elseif CanEarnPromotion() then
                return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_AVAILABLE")
            end
            return name .. ", " .. Locale.Lookup("LOC_CAI_GOVERNOR_LOCKED")
        end,
        Tooltip = function()
            return GetPromotionCellTooltip(capturedPromoDef, capturedGovDef, localPlayerID)
        end,
        DisabledPredicate = IsPromotionDisabled,
        FocusKey = "promo:" .. tostring(capturedGovIndex) .. ":" .. capturedPromoDef.GovernorPromotionType,
    })
    cell:SetFocusSound(HOVER_SOUND)

    cell:On("activate", function()
        if IsPromotionDisabled() then
            return
        end
        ShowPromoteDialog(capturedGovIndex, capturedPromoIndex)
    end)

    return cell
end

-- ===========================================================================
-- Promotion geometry — precompute max level/column across all governors
-- ===========================================================================

local m_maxLevel = 0
local m_maxColumn = 0
for promoSet in GameInfo.GovernorPromotionSets() do
    local promoDef = GameInfo.GovernorPromotions[promoSet.GovernorPromotion]
    if promoDef and not promoDef.BaseAbility and promoDef.Level and promoDef.Level > 0 then
        if promoDef.Level > m_maxLevel then m_maxLevel = promoDef.Level end
        if (promoDef.Column or 0) > m_maxColumn then m_maxColumn = promoDef.Column end
    end
end

-- ===========================================================================
-- Promotion view helpers — persistent Table + List, swapped via HiddenPredicate
-- ===========================================================================

local function IsFocusedGovernorSecret()
    if m_focusedGovernorIndex < 0 then return false end
    local def = GameInfo.Governors[m_focusedGovernorIndex]
    return def and IsCannotAssign(def)
end

local function ClearFocusMemory(widget)
    if not widget then return end
    widget._lastFocusedKey = nil
    widget._lastFocusedChild = nil
    if widget.Children then
        for _, child in ipairs(widget.Children) do
            ClearFocusMemory(child)
        end
    end
end

local function FocusFirstPromotion(root)
    if not root then return false end
    if root.Type == "Table" then
        return mgr:RestoreFocus(root, { path = { 1, 1, 1 } })
    end
    return mgr:RestoreFocus(root, { path = { 1 } })
end

local function BuildPromoWidgets()
    m_ui.promoTable = mgr:CreateWidget(PROMO_TABLE_ID, "Table", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTIONS") end,
        HiddenPredicate = function() return m_focusedGovernorIndex < 0 or IsFocusedGovernorSecret() end,
    })
    m_ui.promoTable:AddColumn({
        header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_BASE_ABILITY") end,
    })
    for level = 1, m_maxLevel do
        local capturedLevel = level
        m_ui.promoTable:AddColumn({
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_TIER", capturedLevel) end,
        })
    end

    m_ui.promoList = mgr:CreateWidget(PROMO_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTIONS") end,
        HiddenPredicate = function() return m_focusedGovernorIndex < 0 or not IsFocusedGovernorSecret() end,
    })
end

local function PopulatePromotionTable(governorIndex)
    if not m_ui.promoTable then return end
    m_ui.promoTable:ClearRows()

    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef then return end

    local localPlayerID = Game.GetLocalPlayer()
    local pPlayer = Players[localPlayerID]
    local playerGovernors = pPlayer:GetGovernors()
    local governor = GetAppointedGovernor(localPlayerID, governorIndex)

    local basePromo = nil
    local promosByLevel = {}
    for promoSet in GameInfo.GovernorPromotionSets() do
        if promoSet.GovernorType == governorDef.GovernorType then
            local promoDef = GameInfo.GovernorPromotions[promoSet.GovernorPromotion]
            if promoDef then
                if promoDef.BaseAbility then
                    basePromo = promoDef
                elseif promoDef.Level and promoDef.Level > 0 then
                    local level = promoDef.Level
                    local col = promoDef.Column or 0
                    if not promosByLevel[level] then promosByLevel[level] = {} end
                    promosByLevel[level][col] = promoDef
                end
            end
        end
    end

    -- Column 1: Base Ability
    if basePromo then
        local cell = CreatePromotionCell(basePromo, governor, governorDef, playerGovernors, localPlayerID)
        m_ui.promoTable:AddItem(1, 1, cell)
    end

    -- Columns 2..N: progression tiers
    for level = 1, m_maxLevel do
        local colIdx = level + 1
        local levelPromos = promosByLevel[level] or {}
        for column = 0, m_maxColumn do
            local promoDef = levelPromos[column]
            if promoDef then
                local cell = CreatePromotionCell(promoDef, governor, governorDef, playerGovernors, localPlayerID, false)
                m_ui.promoTable:AddItem(colIdx, 1, cell)
            else
                local spacer = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_Spacer"), "StaticText", {
                    HiddenPredicate = function() return true end,
                })
                m_ui.promoTable:AddItem(colIdx, 1, spacer)
            end
        end
    end
end

local function PopulatePromotionList(governorIndex)
    if not m_ui.promoList then return end
    m_ui.promoList:ClearChildren()

    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef then return end

    local localPlayerID = Game.GetLocalPlayer()
    local pPlayer = Players[localPlayerID]
    local playerGovernors = pPlayer:GetGovernors()
    local governor = GetAppointedGovernor(localPlayerID, governorIndex)

    for promoSet in GameInfo.GovernorPromotionSets() do
        if promoSet.GovernorType == governorDef.GovernorType then
            local promoDef = GameInfo.GovernorPromotions[promoSet.GovernorPromotion]
            if promoDef then
                local cell = CreatePromotionCell(promoDef, governor, governorDef, playerGovernors, localPlayerID, true)
                m_ui.promoList:AddChild(cell)
            end
        end
    end
end

local function RefreshPromotionsView(governorIndex, resetFocus)
    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef then return end
    local root = IsCannotAssign(governorDef) and m_ui.promoList or m_ui.promoTable
    local capture = root and mgr:CaptureFocusKey(root) or nil

    if IsCannotAssign(governorDef) then
        PopulatePromotionList(governorIndex)
    else
        PopulatePromotionTable(governorIndex)
    end

    if not root then return end
    if resetFocus then
        ClearFocusMemory(root)
        if capture then FocusFirstPromotion(root) end
    else
        mgr:RestoreFocus(root, capture)
    end
end

local function RestorePendingPromotionFocus(governorIndex)
    if not m_pendingPromotionFocusKey then return end
    if governorIndex ~= m_pendingPromotionGovernorIndex then return end
    if not mgr or not m_ui.panel then return end

    m_focusedGovernorIndex = governorIndex
    RefreshPromotionsView(governorIndex, false)

    local governorDef = GameInfo.Governors[governorIndex]
    local root = governorDef and IsCannotAssign(governorDef) and m_ui.promoList or m_ui.promoTable
    local target = root and mgr:FindByFocusKey(root, m_pendingPromotionFocusKey)
    if target then
        mgr:SetFocus(target, { announce = false })
    end

    m_pendingPromotionFocusKey = nil
    m_pendingPromotionGovernorIndex = -1
end

AddGovernorShared = WrapFunc(AddGovernorShared, function(orig, governorDef)
    local row = orig(governorDef)
    CaptureLiveGovernorRow(governorDef, row)
    return row
end)

AddSecretGovernorShared = WrapFunc(AddSecretGovernorShared, function(orig, governorDef)
    local row = orig(governorDef)
    CaptureLiveGovernorRow(governorDef, row)
    return row
end)

-- ===========================================================================
-- Governor tree building
-- ===========================================================================

local function CreateGovernorRow(governorDef, governor, playerGovernors, canAppoint, localPlayerID)
    local isSecret = IsCannotAssign(governorDef)
    local govIndex = governorDef.Index

    local function CanActivateGovernorRow()
        if m_isReadOnly then return false end

        local player = Players[localPlayerID]
        if not player then return false end

        local pg = player:GetGovernors()
        if not pg then return false end

        local gov = GetAppointedGovernor(localPlayerID, govIndex)
        if not gov then
            return pg:CanAppoint()
        end

        if isSecret then
            return false
        end

        return gov:GetNeutralizedTurns() == 0
    end

    local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_Row"), "TreeItem", {
        Label = function()
            local gov = GetAppointedGovernor(localPlayerID, govIndex)
            local pg = Players[localPlayerID]:GetGovernors()
            return GetGovernorRowLabel(governorDef, gov, pg)
        end,
        Tooltip = function()
            local gov = GetAppointedGovernor(localPlayerID, govIndex)
            local pg = Players[localPlayerID]:GetGovernors()
            return GetGovernorRowTooltip(governorDef, gov, pg, localPlayerID)
        end,
        DisabledPredicate = function() return not CanActivateGovernorRow() end,
        FocusKey = "gov:" .. tostring(govIndex),
    })
    row:SetFocusSound(HOVER_SOUND)

    row:On("focus_enter", function(w)
        if w:IsFocused() and govIndex ~= m_focusedGovernorIndex then
            local previousGovernorIndex = m_focusedGovernorIndex
            m_focusedGovernorIndex = govIndex
            RefreshPromotionsView(govIndex, previousGovernorIndex ~= govIndex)
        end
    end)

    row:On("activate", function()
        if not CanActivateGovernorRow() then return end
        local gov = GetAppointedGovernor(localPlayerID, govIndex)
        if not gov then
            OnAppointGovernor(govIndex)
        elseif not isSecret then
            OnAssignButton(govIndex, m_cityBannerPlayerID, m_cityBannerCityID)
        end
    end)

    if governor then
        for promotionSet in GameInfo.GovernorPromotionSets() do
            if promotionSet.GovernorType == governorDef.GovernorType then
                local promoDef = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion]
                if promoDef and governor:HasPromotion(promoDef.Hash) then
                    local isHidden = IsPromotionHidden(promoDef.Hash, localPlayerID, govIndex)
                    local capturedPromoDef = promoDef
                    local capturedHash = promoDef.Hash
                    local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_EarnedPromo"), "TreeItem", {
                        Label = function()
                            if isHidden then return GetHiddenPromotionLabel() end
                            return Locale.Lookup(capturedPromoDef.Name)
                        end,
                        Tooltip = function()
                            if isHidden then return GetPromotionHiddenDescription(capturedHash) end
                            return Locale.Lookup(capturedPromoDef.Description)
                        end,
                    })
                    row:AddChild(child)
                end
            end
        end
    end

    return row
end

local function RebuildTree()
    if not m_ui.tree then return end
    if ContextPtr:IsHidden() then return end

    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or localPlayerID == PlayerTypes.NONE then
        mgr:RestoreFocus(m_ui.tree, capture)
        return
    end

    local pPlayer = Players[localPlayerID]
    if not pPlayer then
        mgr:RestoreFocus(m_ui.tree, capture)
        return
    end

    local playerGovernors = pPlayer:GetGovernors()
    if not playerGovernors then
        mgr:RestoreFocus(m_ui.tree, capture)
        return
    end

    local governorPointsObtained = playerGovernors:GetGovernorPoints()
    local governorPointsSpent = playerGovernors:GetGovernorPointsSpent()
    local canAppoint = playerGovernors:CanAppoint()
    local bHasGovernors, tGovernorList = playerGovernors:GetGovernorList()

    m_isReadOnly = IsReadOnly()

    local capturedAvailable = governorPointsObtained - governorPointsSpent
    local capturedSpent = governorPointsSpent

    -- Secret society governors: appointed first, then candidates
    if tGovernorList then
        for _, pGovernor in ipairs(tGovernorList) do
            local eGovernorType = pGovernor:GetType()
            local kGovernorDef = GameInfo.Governors[eGovernorType]
            if kGovernorDef and IsCannotAssign(kGovernorDef) then
                m_ui.tree:AddChild(CreateGovernorRow(kGovernorDef, pGovernor, playerGovernors, false, localPlayerID))
            end
        end
    end

    for kGovernorDef in GameInfo.Governors() do
        if not playerGovernors:HasGovernor(kGovernorDef.Hash) then
            if playerGovernors:CanEverAppointGovernor(kGovernorDef.Hash) then
                if IsCannotAssign(kGovernorDef) then
                    m_ui.tree:AddChild(CreateGovernorRow(kGovernorDef, nil, playerGovernors, canAppoint, localPlayerID))
                end
            end
        end
    end

    -- Normal governors: appointed first, then candidates
    if tGovernorList then
        for _, pGovernor in ipairs(tGovernorList) do
            local eGovernorType = pGovernor:GetType()
            local kGovernorDef = GameInfo.Governors[eGovernorType]
            if kGovernorDef and not IsCannotAssign(kGovernorDef) then
                m_ui.tree:AddChild(CreateGovernorRow(kGovernorDef, pGovernor, playerGovernors, false, localPlayerID))
            end
        end
    end

    for kGovernorDef in GameInfo.Governors() do
        if not playerGovernors:HasGovernor(kGovernorDef.Hash) then
            if playerGovernors:CanEverAppointGovernor(kGovernorDef.Hash) then
                if not IsCannotAssign(kGovernorDef) then
                    m_ui.tree:AddChild(CreateGovernorRow(kGovernorDef, nil, playerGovernors, canAppoint, localPlayerID))
                end
            end
        end
    end

    mgr:RestoreFocus(m_ui.tree, capture)
end

-- ===========================================================================
-- Panel construction and lifecycle
-- ===========================================================================

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = GetPanelTitle,
    })

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return GetTitleCountsText(GetGovernerTitleCounts()) end,
    })
    m_ui.panel:AddChild(m_ui.tree)

    BuildPromoWidgets()
    m_ui.panel:AddChild(m_ui.promoTable)
    m_ui.panel:AddChild(m_ui.promoList)
end

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    RebuildTree()
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil,
        tree = nil,
        promoTable = nil,
        promoList = nil,
    }
    m_focusedGovernorIndex = -1
    m_liveGovernorRows = {}
end

-- ===========================================================================
-- Vanilla function wraps
-- ===========================================================================

Open = WrapFunc(Open, function(orig, playerID, cityID)
    if playerID ~= nil and cityID ~= nil then
        m_cityBannerPlayerID = playerID
        m_cityBannerCityID = cityID
    else
        m_cityBannerPlayerID = -1
        m_cityBannerCityID = -1
    end
    orig(playerID, cityID)
    if not ContextPtr:IsHidden() then
        PushPanel()
        m_isReadOnly = IsReadOnly()
        if m_isReadOnly then
            Speak(Locale.Lookup("LOC_CAI_GOVERNOR_READONLY"))
        end
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

Refresh = WrapFunc(Refresh, function(orig)
    m_liveGovernorRows = {}
    orig()
    m_isReadOnly = IsReadOnly()
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        RebuildTree()
    end
end)

local function OnCAIGovernorAppointed(playerID, governorID)
    if playerID ~= Game.GetLocalPlayer() then return end

    local governorDef = GameInfo.Governors[governorID]
    local governorName = GetGovernorName(governorID)
    if governorName ~= "" then
        if governorDef and IsCannotAssign(governorDef) then
            Speak(Locale.Lookup("LOC_CAI_GOVERNOR_FEEDBACK_JOINED", governorName))
        else
            Speak(Locale.Lookup("LOC_CAI_GOVERNOR_FEEDBACK_APPOINTED", governorName))
        end
    end
end

local function OnCAIGovernorPromoted(playerID, governorID, promotionID)
    if playerID ~= Game.GetLocalPlayer() then return end
    if ContextPtr:IsHidden() then return end

    RestorePendingPromotionFocus(governorID)
end

local function SpeakGovTitles()
    Speak(GetTitleCountsText(GetGovernerTitleCounts()))
end

local function OnInputActionTriggered(actionId)
    if actionId == Input.GetActionId("CAI_SpeakGovernerTitles") then SpeakGovTitles() end
end

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then return true end
    end
    return orig(input)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
    Events.InputActionTriggered.Remove(OnInputActionTriggered)
    Events.GovernorAppointed.Remove(OnCAIGovernorAppointed)
    Events.GovernorPromoted.Remove(OnCAIGovernorPromoted)
end)

-- Re-register callbacks: vanilla Initialize() captured old function references
-- before our WrapFunc reassigned the globals.
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetShutdown(OnShutdown)
Events.InputActionTriggered.Add(OnInputActionTriggered)
Events.GovernorAppointed.Add(OnCAIGovernorAppointed)
Events.GovernorPromoted.Add(OnCAIGovernorPromoted)
