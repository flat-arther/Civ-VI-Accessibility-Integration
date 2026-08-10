-- GovernorPanel_CAI.lua
--
-- Accessibility layer for the Governor Panel.
-- Replaces the vanilla GovernorPanel LuaContext. Re-includes the correct
-- expansion version, then wraps Open/Close/Refresh to overlay a single
-- CAI browsing surface: a sortable governor table or detailed Tree with a
-- sibling promotions view.

include("caiUtils")
include("GameCapabilities")
include("GovernorPanel")

local mgr = ExposedMembers.CAI_UIManager
if not HasCapability("CAPABILITY_GOVERNORS") then return end

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID         = "CAIGovernorPanel_Panel"
local TABLE_ID         = "CAIGovernorPanel_Table"
local TREE_SORT_ID     = "CAIGovernorPanel_TreeSort"
local TREE_ID          = "CAIGovernorPanel_Tree"
local PROMO_GRID_ID    = "CAIGovernorPanel_PromoGrid"
local PROMO_LIST_ID    = "CAIGovernorPanel_PromoList"
local SWITCH_VIEW_ID   = "CAIGovernorPanel_SwitchView"
local VIEW_SETTING_SECTION = "UI"
local VIEW_SETTING_ID      = "GovernorPanelViewMode"


local HOVER_SOUND                     = "Main_Menu_Mouse_Over"

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui                            = {
    panel              = nil,
    tableView          = nil,
    treeSort           = nil,
    tree               = nil,
    promoGrid         = nil,
    promoList          = nil,
    promoConfirmDialog = nil,
    switchView         = nil,
}

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    if stored ~= "table" then
        LogWarn("Governors ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("Governors failed to save view mode " .. tostring(viewMode))
    end
end

local m_focusedGovernorIndex          = -1
local m_isReadOnly                    = false
local m_cityBannerPlayerID            = -1
local m_cityBannerCityID              = -1
local m_liveGovernorRows              = {}
local m_pendingPromotionFocusKey      = nil
local m_pendingPromotionGovernorIndex = -1
local m_governorIndices               = {}
local m_governorColumns               = {}
local m_treeSortOptions               = {}
local m_treeSortColumn                = nil
local m_treeSortAscending             = false
local m_viewMode                      = LoadViewModeSetting()

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

local function FormatPromotionList(names, conjunctionTag)
    if #names <= 1 then return table.concat(names) end

    local finalName = table.remove(names)
    return table.concat(names, "[NEWLINE]") .. ", " .. Locale.Lookup(conjunctionTag) .. " " .. finalName
end

local function NormalizeText(text)
    -- Tags and whitespace are filtered centrally in Speak()/ProcessText; keep
    -- only nil-safety here so composed strings never concatenate a nil.
    if not text then return "" end
    return tostring(text)
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

local function GetLiveGovernorStatHeader(controlName, fallbackTag)
    for _, liveRow in pairs(m_liveGovernorRows) do
        local control = liveRow and liveRow[controlName]
        local tooltip = ControlTooltip(control)
        if tooltip ~= "" then return NormalizeText(tooltip) end
    end
    return NormalizeText(Locale.Lookup(fallbackTag))
end

local function GetEstablishSpeedHeader()
    return GetLiveGovernorStatHeader(
        "TransitionStrengthLabel", "LOC_GOVERNOR_TRANSITION_STRENGTH_TOOLTIP")
end

local function GetLoyaltyPressureHeader()
    return GetLiveGovernorStatHeader(
        "IdentityPressureLabel", "LOC_GOVERNOR_IDENTITY_PRESSURE_TOOLTIP")
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

local function GetGovernorData(governorIndex)
    local governorDef = GameInfo.Governors[governorIndex]
    local localPlayerID = Game.GetLocalPlayer()
    local player = Players[localPlayerID]
    local playerGovernors = player and player:GetGovernors()
    local governor = governorDef and GetAppointedGovernor(localPlayerID, governorIndex) or nil
    return governorDef, governor, playerGovernors, localPlayerID
end

local function GetGovernorBaseAbilityTooltip(governorDef, localPlayerID)
    local abilities = {}
    for promotionSet in GameInfo.GovernorPromotionSets() do
        if promotionSet.GovernorType == governorDef.GovernorType then
            local promoDef = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion]
            if promoDef and promoDef.BaseAbility then
                local name, description = GetPromotionNameAndDescription(
                    promoDef, localPlayerID, governorDef.Index)
                abilities[#abilities + 1] = JoinNonEmpty({ name, description }, ": ")
            end
        end
    end
    if #abilities == 0 then return "" end
    return Locale.Lookup("LOC_CAI_GOVERNOR_BASE_ABILITY") .. "[NEWLINE]"
        .. table.concat(abilities, "[NEWLINE]")
end

local function GetGovernorNameTooltip(governorIndex)
    local governorDef, _, _, localPlayerID = GetGovernorData(governorIndex)
    if not governorDef then return "" end
    return JoinNonEmpty({
        Locale.Lookup(governorDef.Title),
        Locale.Lookup(governorDef.Description),
        GetGovernorBaseAbilityTooltip(governorDef, localPlayerID),
    }, "[NEWLINE]")
end

local function GetEarnedPromotions(governorIndex)
    local governorDef, governor, _, localPlayerID = GetGovernorData(governorIndex)
    local earned = {}
    if not governorDef or not governor then return earned end

    for promotionSet in GameInfo.GovernorPromotionSets() do
        if promotionSet.GovernorType == governorDef.GovernorType then
            local promoDef = GameInfo.GovernorPromotions[promotionSet.GovernorPromotion]
            if promoDef and not promoDef.BaseAbility and governor:HasPromotion(promoDef.Hash) then
                local name, description = GetPromotionNameAndDescription(
                    promoDef, localPlayerID, governorIndex)
                earned[#earned + 1] = JoinNonEmpty({ name, description }, ": ")
            end
        end
    end
    return earned
end

local function GetEarnedPromotionsCell(governorIndex)
    local earned = GetEarnedPromotions(governorIndex)
    local parts = { tostring(#earned) }
    for _, promotion in ipairs(earned) do parts[#parts + 1] = promotion end
    return table.concat(parts, "[NEWLINE]")
end

local function GetGovernorStatusData(governorIndex)
    local governorDef, governor, playerGovernors = GetGovernorData(governorIndex)
    if not governorDef or not playerGovernors then return "", nil end

    if not governor then
        if not m_isReadOnly and playerGovernors:CanAppoint() then
            return Locale.Lookup("LOC_CAI_GOVERNOR_STATUS_AVAILABLE"), 600000
        end
        return Locale.Lookup("LOC_CAI_GOVERNOR_STATUS_UNAVAILABLE"), 700000
    end

    if IsCannotAssign(governorDef) then
        return Locale.Lookup("LOC_CAI_GOVERNOR_STATUS_APPOINTED"), 200000
    end

    local neutralizedTurns = governor:GetNeutralizedTurns()
    if neutralizedTurns > 0 then
        return JoinNonEmpty({
            Locale.Lookup("LOC_GOVERNORS_SCREEN_NEUTRALIZED"),
            Locale.Lookup("LOC_GOVERNORS_SCREEN_NEUTRALIZED_TURNS_REMAINING", neutralizedTurns),
        }, ", "), 500000 + neutralizedTurns
    end

    local city = governor:GetAssignedCity()
    if not city then
        return Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_NEEDS_ASSIGNMENT"), 400000
    end

    local cityName = Locale.Lookup(city:GetName())
    if governor:IsEstablished() then
        return JoinNonEmpty({
            Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_ESTABLISHED_IN"),
            cityName,
        }, " "), 100000
    end

    local remainingTurns = governor:GetTurnsToEstablish() - governor:GetTurnsOnSite()
    return JoinNonEmpty({
        Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_TRANSITIONING_TO"),
        Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_NAME_WITH_TURNS", cityName, remainingTurns),
    }, " "), 300000 + remainingTurns
end

local function GetEstablishSpeed(governorIndex)
    local governorDef, _, playerGovernors = GetGovernorData(governorIndex)
    if not governorDef or not playerGovernors or IsCannotAssign(governorDef) then return nil end
    return playerGovernors:GetTurnsToEstablish(governorDef.Hash)
end

local function GetLoyaltyPressure(governorIndex)
    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef or IsCannotAssign(governorDef) then return nil end
    return governorDef.IdentityPressure
end

local function BuildGovernorColumns()
    return {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_COLUMN_NAME") end,
            getCell = GetGovernorName,
            getTooltip = GetGovernorNameTooltip,
            sortKey = GetGovernorName,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "status",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_COLUMN_STATUS") end,
            getCell = function(governorIndex) return GetGovernorStatusData(governorIndex) end,
            sortKey = function(governorIndex)
                local _, rank = GetGovernorStatusData(governorIndex)
                return rank
            end,
            sortAscendingDescription = "LOC_CAI_SORT_ACTIVE_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_UNAVAILABLE_FIRST",
        },
        {
            key = "establish_speed",
            header = GetEstablishSpeedHeader,
            getCell = function(governorIndex)
                local turns = GetEstablishSpeed(governorIndex)
                return turns and Locale.Lookup(
                    "LOC_GOVERNORS_SCREEN_GOVERNOR_TRANSITION_TURNS", turns) or ""
            end,
            sortKey = GetEstablishSpeed,
            sortAscendingDescription = "LOC_CAI_SORT_FASTEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_SLOWEST_FIRST",
        },
        {
            key = "loyalty",
            header = GetLoyaltyPressureHeader,
            getCell = function(governorIndex)
                local loyalty = GetLoyaltyPressure(governorIndex)
                return loyalty and tostring(loyalty) or ""
            end,
            sortKey = GetLoyaltyPressure,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "earned_promotions",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_COLUMN_EARNED_PROMOTIONS") end,
            getCell = GetEarnedPromotionsCell,
            sortKey = function(governorIndex) return #GetEarnedPromotions(governorIndex) end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
    }
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
            local turnsToEstablish = tonumber(ControlText(liveRow.TransitionStrengthLabel))
            if turnsToEstablish then
                local establishmentDescription = ControlTooltip(liveRow.TransitionStrengthLabel)
                if establishmentDescription == "" then
                    establishmentDescription = Locale.Lookup("LOC_GOVERNOR_TRANSITION_STRENGTH_TOOLTIP")
                end
                AppendIfNonEmpty(parts, establishmentDescription .. " "
                    .. Locale.Lookup("LOC_GOVERNORS_SCREEN_GOVERNOR_TRANSITION_TURNS", turnsToEstablish))
            end
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

    AppendIfNonEmpty(parts, governorDef.Description and Locale.Lookup(governorDef.Description) or "")

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
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_GOVERNOR_EARNED_PROMOS", table.concat(earnedNames, "[NEWLINE]"))
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
        return JoinNonEmpty(parts, "[NEWLINE]")
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
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_UNIT_PROMOTION_PREREQS_HEADER",
            FormatPromotionList(prereqNames, "LOC_CAI_OR"))
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
        parts[#parts + 1] = Locale.Lookup("LOC_CAI_UNIT_PROMOTION_LEADS_TO_HEADER",
            FormatPromotionList(leadsToNames, "LOC_CAI_AND"))
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

-- ===========================================================================
-- Promote dialog
-- ===========================================================================

local function RemovePromoDialog()
    if mgr and m_ui.promoConfirmDialog and mgr:GetWidgetById(m_ui.promoConfirmDialog:GetId()) then
        mgr:RemoveFromStack(
            m_ui.promoConfirmDialog:GetId())
    end
    m_ui.promoConfirmDialog = nil
end

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
        DisabledPredicate = function() return m_pendingPromotionGovernorIndex > -1 end,
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
        -- Async promotion event will close the dialog
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGovDlg_Cancel"), "Button", {
        Label = function() return Locale.Lookup("LOC_CANCEL") end,
        DisabledPredicate = function() return m_pendingPromotionGovernorIndex > -1 end,
    })
    cancelBtn:On("activate", function()
        RemovePromoDialog()
    end)

    m_ui.promoConfirmDialog = mgr.WidgetHelpers.MakeGeneralDialog(titleFn, { confirmBtn, cancelBtn }, { descWidget }, 1)
    m_ui.promoConfirmDialog:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            RemovePromoDialog()
            return true
        end
    })
    if m_ui.promoConfirmDialog then
        mgr:Push(m_ui.promoConfirmDialog)
    end
end

-- ===========================================================================
-- Promotion cell creation (shared by grid and list)
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
-- Promotion view helpers — persistent Grid + List, swapped via HiddenPredicate
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
    if root.Type == "Grid" then
        return mgr:RestoreFocus(root, { path = { 1, 1, 1 } })
    end
    return mgr:RestoreFocus(root, { path = { 1 } })
end

local function BuildPromoWidgets()
    m_ui.promoGrid = mgr:CreateWidget(PROMO_GRID_ID, "Grid", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTIONS") end,
        HiddenPredicate = function() return m_focusedGovernorIndex < 0 or IsFocusedGovernorSecret() end,
    })
    m_ui.promoGrid:AddColumn({
        header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_BASE_ABILITY") end,
    })
    for level = 1, m_maxLevel do
        local capturedLevel = level
        m_ui.promoGrid:AddColumn({
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_TIER", capturedLevel) end,
        })
    end

    m_ui.promoList = mgr:CreateWidget(PROMO_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNOR_PROMOTIONS") end,
        HiddenPredicate = function() return m_focusedGovernorIndex < 0 or not IsFocusedGovernorSecret() end,
    })
end

local function PopulatePromotionGrid(governorIndex)
    if not m_ui.promoGrid then return end
    m_ui.promoGrid:ClearRows()

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
        m_ui.promoGrid:AddItem(1, 1, cell)
    end

    -- Columns 2..N: progression tiers
    for level = 1, m_maxLevel do
        local colIdx = level + 1
        local levelPromos = promosByLevel[level] or {}
        for column = 0, m_maxColumn do
            local promoDef = levelPromos[column]
            if promoDef then
                local cell = CreatePromotionCell(promoDef, governor, governorDef, playerGovernors, localPlayerID, false)
                m_ui.promoGrid:AddItem(colIdx, 1, cell)
            else
                local spacer = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGov_Spacer"), "StaticText", {
                    HiddenPredicate = function() return true end,
                })
                m_ui.promoGrid:AddItem(colIdx, 1, spacer)
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

local function RefreshPromotionsView(governorIndex, resetFocus, pendingFocusKey)
    local governorDef = GameInfo.Governors[governorIndex]
    if not governorDef then return end
    local root = IsCannotAssign(governorDef) and m_ui.promoList or m_ui.promoGrid
    local capture = (root and not pendingFocusKey) and mgr:CaptureFocusKey(root) or nil

    if IsCannotAssign(governorDef) then
        PopulatePromotionList(governorIndex)
    else
        PopulatePromotionGrid(governorIndex)
    end

    if not root then return end
    if pendingFocusKey then
        mgr:PrepareFocus(root, pendingFocusKey)
        return
    end
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
    RefreshPromotionsView(governorIndex, false, m_pendingPromotionFocusKey)

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

local function GetTreeGovernorFocusKey(governorIndex)
    return "gov:" .. tostring(governorIndex)
end

local function GetTableGovernorFocusKey(governorIndex)
    return TABLE_ID .. ":row:" .. tostring(governorIndex) .. ":name"
end

local function CanActivateGovernor(governorIndex, localPlayerID)
    if m_isReadOnly then return false end

    local governorDef = GameInfo.Governors[governorIndex]
    local player = Players[localPlayerID]
    local playerGovernors = player and player:GetGovernors()
    if not governorDef or not playerGovernors then return false end

    local governor = GetAppointedGovernor(localPlayerID, governorIndex)
    if not governor then return playerGovernors:CanAppoint() end
    if IsCannotAssign(governorDef) then return false end
    return governor:GetNeutralizedTurns() == 0
end

local function ActivateGovernor(governorIndex, localPlayerID)
    if not CanActivateGovernor(governorIndex, localPlayerID) then return false end

    local governorDef = GameInfo.Governors[governorIndex]
    local governor = GetAppointedGovernor(localPlayerID, governorIndex)
    if not governor then
        OnAppointGovernor(governorIndex)
    elseif not IsCannotAssign(governorDef) then
        OnAssignButton(governorIndex, m_cityBannerPlayerID, m_cityBannerCityID)
    end
    return true
end

local function FocusGovernorPromotions(governorIndex)
    if governorIndex == m_focusedGovernorIndex then return end
    local previousGovernorIndex = m_focusedGovernorIndex
    m_focusedGovernorIndex = governorIndex
    RefreshPromotionsView(governorIndex, previousGovernorIndex ~= governorIndex)
end

local function CreateGovernorRow(governorIndex, localPlayerID)
    local governorDef, governor = GetGovernorData(governorIndex)
    local govIndex = governorIndex

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
        DisabledPredicate = function() return not CanActivateGovernor(govIndex, localPlayerID) end,
        FocusKey = GetTreeGovernorFocusKey(govIndex),
    })
    row:SetFocusSound(HOVER_SOUND)

    row:On("focus_enter", function(w)
        if w:IsFocused() then FocusGovernorPromotions(govIndex) end
    end)

    row:On("activate", function()
        ActivateGovernor(govIndex, localPlayerID)
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

local function BuildNaturalGovernorIndices()
    local indices = {}
    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == -1 or localPlayerID == PlayerTypes.NONE then return indices end
    local pPlayer = Players[localPlayerID]
    if not pPlayer then return indices end
    local playerGovernors = pPlayer:GetGovernors()
    if not playerGovernors then return indices end
    local _, tGovernorList = playerGovernors:GetGovernorList()

    m_isReadOnly = IsReadOnly()

    -- Secret society governors: appointed first, then candidates
    if tGovernorList then
        for _, pGovernor in ipairs(tGovernorList) do
            local eGovernorType = pGovernor:GetType()
            local kGovernorDef = GameInfo.Governors[eGovernorType]
            if kGovernorDef and IsCannotAssign(kGovernorDef) then
                indices[#indices + 1] = kGovernorDef.Index
            end
        end
    end

    for kGovernorDef in GameInfo.Governors() do
        if not playerGovernors:HasGovernor(kGovernorDef.Hash) then
            if playerGovernors:CanEverAppointGovernor(kGovernorDef.Hash) then
                if IsCannotAssign(kGovernorDef) then
                    indices[#indices + 1] = kGovernorDef.Index
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
                indices[#indices + 1] = kGovernorDef.Index
            end
        end
    end

    for kGovernorDef in GameInfo.Governors() do
        if not playerGovernors:HasGovernor(kGovernorDef.Hash) then
            if playerGovernors:CanEverAppointGovernor(kGovernorDef.Hash) then
                if not IsCannotAssign(kGovernorDef) then
                    indices[#indices + 1] = kGovernorDef.Index
                end
            end
        end
    end

    return indices
end


local function BuildTreeSortOptions(columns)
    local options = {
        {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = nil, ascending = false },
        },
    }
    for _, column in ipairs(columns) do
        if column.sortKey then
            local header = type(column.header) == "function" and column.header() or column.header or ""
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            }
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            }
        end
    end
    return options
end

local function SyncTreeSortDropdown()
    if not m_ui.treeSort then return end
    for index, option in ipairs(m_treeSortOptions) do
        local sort = option.value
        if sort.column == m_treeSortColumn and
            (sort.column == nil or sort.ascending == m_treeSortAscending) then
            m_ui.treeSort:SetSelectedIndex(index, true)
            return
        end
    end
end

local function CompareSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    return Locale.Compare(tostring(a), tostring(b))
end

local function GetOrderedGovernorIndices()
    local ordered = {}
    for _, governorIndex in ipairs(m_governorIndices) do ordered[#ordered + 1] = governorIndex end
    if not m_treeSortColumn then return ordered end

    local sortColumn = nil
    for _, column in ipairs(m_governorColumns) do
        if column.key == m_treeSortColumn then
            sortColumn = column
            break
        end
    end
    if not sortColumn or not sortColumn.sortKey then return ordered end

    local decorated = {}
    for naturalIndex, governorIndex in ipairs(ordered) do
        decorated[#decorated + 1] = {
            governorIndex = governorIndex,
            naturalIndex = naturalIndex,
            value = sortColumn.sortKey(governorIndex),
        }
    end
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.naturalIndex < b.naturalIndex end
            return a.value ~= nil
        end
        local comparison = CompareSortValues(a.value, b.value)
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        if m_treeSortAscending then return comparison < 0 end
        return comparison > 0
    end)

    ordered = {}
    for _, entry in ipairs(decorated) do ordered[#ordered + 1] = entry.governorIndex end
    return ordered
end

local function RebuildTree()
    if not m_ui.tree or ContextPtr:IsHidden() then return end
    local capture = mgr:CaptureFocusKey(m_ui.tree)
    m_ui.tree:ClearChildren()

    local localPlayerID = Game.GetLocalPlayer()
    for _, governorIndex in ipairs(GetOrderedGovernorIndices()) do
        m_ui.tree:AddChild(CreateGovernorRow(governorIndex, localPlayerID))
    end

    mgr:RestoreFocus(m_ui.tree, capture)
end

-- ===========================================================================
-- Panel construction and lifecycle
-- ===========================================================================

local function GetActiveGovernorView()
    return m_viewMode == "tree" and m_ui.tree or m_ui.tableView
end

local function SetViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("Governors received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end

    local activeView = GetActiveGovernorView()
    if activeView then
        if m_focusedGovernorIndex >= 0 then
            mgr:PrepareFocus(activeView, viewMode == "tree"
                and GetTreeGovernorFocusKey(m_focusedGovernorIndex)
                or GetTableGovernorFocusKey(m_focusedGovernorIndex))
        end
        mgr:SetFocus(activeView)
    end
    return true
end

local function ToggleViewMode()
    return SetViewMode(m_viewMode == "table" and "tree" or "table")
end

local function RebuildViews()
    if not m_ui.tableView or not m_ui.tree or ContextPtr:IsHidden() then return end

    m_governorIndices = BuildNaturalGovernorIndices()
    m_ui.tableView:Rebuild()
    RebuildTree()

    if m_focusedGovernorIndex >= 0 then
        local stillPresent = false
        for _, governorIndex in ipairs(m_governorIndices) do
            if governorIndex == m_focusedGovernorIndex then
                stillPresent = true
                break
            end
        end
        if not stillPresent then
            m_focusedGovernorIndex = -1
        end
    end
end

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = GetPanelTitle,
    })
    m_ui.panel:AddInputBindings({
        {
            Key = Keys["1"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetViewMode("table") end,
        },
        {
            Key = Keys["2"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetViewMode("tree") end,
        },
    })

    m_governorColumns = BuildGovernorColumns()
    for _, column in ipairs(m_governorColumns) do
        column.isDisabled = function(governorIndex)
            return not CanActivateGovernor(governorIndex, Game.GetLocalPlayer())
        end
    end
    m_treeSortOptions = BuildTreeSortOptions(m_governorColumns)

    m_ui.tableView = mgr:CreateWidget(TABLE_ID, "DataTable", {
        Label = function() return GetTitleCountsText(GetGovernerTitleCounts()) end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_ui.tableView:SetColumns(m_governorColumns)
    m_ui.tableView:SetRowsProvider(function() return m_governorIndices end)
    m_ui.tableView:SetRowKeyGetter(function(governorIndex) return governorIndex end)
    m_ui.tableView:SetRowLabelGetter(GetGovernorName)
    m_ui.tableView:SetDefaultSort(m_treeSortColumn
        and { column = m_treeSortColumn, ascending = m_treeSortAscending }
        or nil)
    m_ui.tableView:On("row_focus_enter", function(_, governorIndex, rowIndex)
        if rowIndex > 0 then FocusGovernorPromotions(governorIndex) end
    end)
    m_ui.tableView:On("row_activate", function(_, governorIndex)
        ActivateGovernor(governorIndex, Game.GetLocalPlayer())
    end)
    m_ui.tableView:On("sort_changed", function(_, columnKey, ascending)
        m_treeSortColumn = columnKey
        m_treeSortAscending = ascending == true
        SyncTreeSortDropdown()
        RebuildTree()
    end)
    m_ui.panel:AddChild(m_ui.tableView)

    m_ui.treeSort = mgr:CreateWidget(TREE_SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_GOVERNOR_ORDER_BY") end,
        FocusKey = "governors:tree-sort",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.treeSort:SetOptions(m_treeSortOptions)
    SyncTreeSortDropdown()
    m_ui.treeSort:On("value_changed", function(_, sort)
        m_treeSortColumn = sort.column
        m_treeSortAscending = sort.ascending == true
        m_ui.tableView:SetDefaultSort(sort.column
            and { column = sort.column, ascending = sort.ascending }
            or nil)
        m_ui.tableView:Rebuild()
        RebuildTree()
    end)
    m_ui.panel:AddChild(m_ui.treeSort)

    m_ui.tree = mgr:CreateWidget(TREE_ID, "Tree", {
        Label = function() return GetTitleCountsText(GetGovernerTitleCounts()) end,
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.panel:AddChild(m_ui.tree)

    BuildPromoWidgets()
    m_ui.panel:AddChild(m_ui.promoGrid)
    m_ui.panel:AddChild(m_ui.promoList)

    m_ui.switchView = mgr:CreateWidget(SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_ui.switchView:On("activate", function() ToggleViewMode() end)
    m_ui.panel:AddChild(m_ui.switchView)
end

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    RebuildViews()
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, { focus = GetActiveGovernorView() })
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil,
        tableView = nil,
        treeSort = nil,
        tree = nil,
        promoGrid = nil,
        promoList = nil,
        promoConfirmDialog = nil,
        switchView = nil,
    }
    m_focusedGovernorIndex = -1
    m_liveGovernorRows = {}
    m_governorIndices = {}
end

-- ===========================================================================
-- Vanilla function wraps
-- ===========================================================================

LuaEvents.GovernorPanel_Open.Remove(Open)
LuaEvents.GovernorPanel_CancelAssignment.Remove(Open)
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
    end
end)
LuaEvents.GovernorPanel_Open.Add(Open)
LuaEvents.GovernorPanel_CancelAssignment.Add(Open);

LuaEvents.GovernorPanel_Close.Remove(Close)
Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)
LuaEvents.GovernorPanel_Close.Add(Close)

Refresh = WrapFunc(Refresh, function(orig)
    m_liveGovernorRows = {}
    orig()
    m_isReadOnly = IsReadOnly()
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        RebuildViews()
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
    RemovePromoDialog()
end

local function SpeakGovTitles()
    Speak(GetTitleCountsText(GetGovernerTitleCounts()))
end

local function OnInputActionStarted(actionId)
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
    Events.InputActionStarted.Remove(OnInputActionStarted)
    Events.GovernorAppointed.Remove(OnCAIGovernorAppointed)
    Events.GovernorPromoted.Remove(OnCAIGovernorPromoted)
end)

-- Re-register callbacks: vanilla Initialize() captured old function references
-- before our WrapFunc reassigned the globals.
ContextPtr:SetInputHandler(OnInputHandler, true)
ContextPtr:SetShutdown(OnShutdown)
Events.InputActionStarted.Add(OnInputActionStarted)
Events.GovernorAppointed.Add(OnCAIGovernorAppointed)
Events.GovernorPromoted.Add(OnCAIGovernorPromoted)
