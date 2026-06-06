-- GreatPeoplePopup_CAI.lua
--
-- Accessibility layer for the Great People popup.
--
-- GreatPeoplePopup.lua ends with include("GreatPeoplePopup_", true) — a wildcard
-- host that pulls in every loaded GreatPeoplePopup_* file, with Initialize()
-- called *after* it. So this file rides that wildcard (registered as an InGame
-- ImportFile, NOT a LuaReplace), must NOT include("GreatPeoplePopup"), and only
-- reassigns globals — vanilla's later Initialize() registers them as the context
-- handlers.

include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID          = "CAIGreatPeople_Panel"
local TABS_ID           = "CAIGreatPeople_Tabs"
local GP_TREE_ID        = "CAIGreatPeople_Tree"
local GP_BIO_ID         = "CAIGreatPeople_Bio"
local GP_RECRUIT_BTN_ID = "CAIGreatPeople_RecruitBtn"
local GP_REJECT_BTN_ID  = "CAIGreatPeople_RejectBtn"
local GP_GOLD_BTN_ID    = "CAIGreatPeople_GoldBtn"
local GP_FAITH_BTN_ID   = "CAIGreatPeople_FaithBtn"
local PAST_TABLE_ID     = "CAIGreatPeople_PastTable"
local HEROES_TREE_ID    = "CAIGreatPeople_HeroesTree"

local m_hasBabylon = false

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui = {
    panel     = nil,
    tabs      = nil,
    gpPage    = nil,
    gpTree    = nil,
    bioEdit   = nil,
    recruitBtn = nil,
    rejectBtn  = nil,
    goldBtn    = nil,
    faithBtn   = nil,
    pastPage  = nil,
    pastTable = nil,
    heroPage  = nil,
    heroTree  = nil,
}

local m_cachedPersons   = {}
local m_cachedData      = nil
local m_focusedPersonID = nil
local m_isMirroringTab  = false

-- ===========================================================================
-- Control helpers
-- ===========================================================================

local function ControlIsHidden(c)
    return c and c.IsHidden and c:IsHidden() or false
end

local function ControlIsDisabled(c)
    return c and c.IsDisabled and c:IsDisabled() or false
end

local function ControlText(c)
    if not c or not c.GetText then return "" end
    return c:GetText() or ""
end

local function ControlTooltip(c)
    if not c or not c.GetToolTipString then return "" end
    return c:GetToolTipString() or ""
end

local function FindChildById(control, id)
    if not control or not control.GetChildren then return nil end
    for _, child in ipairs(control:GetChildren()) do
        if child:GetID() == id then return child end
        local found = FindChildById(child, id)
        if found then return found end
    end
    return nil
end

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
end

local function StripIcons(text)
    if not text then return "" end
    return text:gsub("%[ICON_[^%]]*%]", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- ===========================================================================
-- Tab 1: Great People — label/tooltip helpers
-- ===========================================================================

local function FormatPersonLabel(kPerson)
    if not kPerson or not kPerson.IndividualID then
        local className = ""
        if kPerson and kPerson.ClassID then
            className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
        end
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", className, Locale.Lookup("LOC_CAI_GP_NONE_AVAILABLE"))
    end
    local name = kPerson.Name or ""
    local className = ""
    if kPerson.ClassID then
        className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
    end
    return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", name, className)
end

local function FormatPersonTooltip(kPerson)
    if not kPerson or not kPerson.IndividualID then return "" end
    local parts = {}

    if kPerson.EraID then
        parts[#parts + 1] = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name)
    end

    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = kPerson.PassiveNameText .. ": " .. kPerson.PassiveEffectText
    end

    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionText = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionText = actionText .. " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end

    if m_cachedData and kPerson.ClassID then
        local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
        if pointsByClass then
            local localPlayerID = Game.GetLocalPlayer()
            for _, kPlayerPoints in ipairs(pointsByClass) do
                if kPlayerPoints.PlayerID == localPlayerID then
                    parts[#parts + 1] = Locale.Lookup("LOC_CAI_GP_LOCAL_PROGRESS",
                        tostring(Round(kPlayerPoints.PointsTotal, 1)),
                        tostring(kPerson.RecruitCost),
                        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
                    break
                end
            end
        end
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        parts[#parts + 1] = kPerson.EarnConditions
    end

    return JoinNonEmpty(parts, ", ")
end

local function FormatProgressLabel(kPlayerPoints, recruitCost)
    return Locale.Lookup("LOC_CAI_GP_CIV_PROGRESS",
        kPlayerPoints.PlayerName,
        tostring(Round(kPlayerPoints.PointsTotal, 1)),
        tostring(recruitCost),
        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
end

local function GetBiographyText(kPerson)
    if not kPerson or not kPerson.BiographyTextTable then
        return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY")
    end
    local text = table.concat(kPerson.BiographyTextTable, "[NEWLINE][NEWLINE]")
    if text == "" then return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY") end
    return text
end

-- ===========================================================================
-- Tab 1: Build GP tree
-- ===========================================================================

local function UpdateBiographyAndButtons()
    local kPerson = m_cachedPersons[m_focusedPersonID]
    if m_ui.bioEdit then
        m_ui.bioEdit:SetText(GetBiographyText(kPerson), true)
    end
end

local function BuildGPTree()
    if not mgr or not m_ui.gpTree then return end
    local capture = mgr:CaptureFocusKey(m_ui.gpTree)
    m_ui.gpTree:ClearChildren()

    if not m_cachedData or not m_cachedData.Timeline then
        mgr:RestoreFocus(m_ui.gpTree, capture)
        return
    end

    for _, kPerson in ipairs(m_cachedData.Timeline) do
        local personID = kPerson.IndividualID
        local item = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGP_Person"), "TreeItem", {
                Label   = function() return FormatPersonLabel(kPerson) end,
                Tooltip = function() return FormatPersonTooltip(kPerson) end,
                FocusKey = personID and ("gp:" .. tostring(personID)) or nil,
            })

        if personID then
            item:On("focus_enter", function()
                m_focusedPersonID = personID
                UpdateBiographyAndButtons()
            end)

            if m_cachedData.PointsByClass and kPerson.ClassID then
                local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
                if pointsByClass then
                    local recruitTable = {}
                    for _, kPlayerPoints in ipairs(pointsByClass) do
                        table.insert(recruitTable, kPlayerPoints)
                    end
                    table.sort(recruitTable, function(a, b)
                        if a.PointsTotal == b.PointsTotal then
                            return a.PlayerID < b.PlayerID
                        end
                        return a.PointsTotal > b.PointsTotal
                    end)

                    for _, kPlayerPoints in ipairs(recruitTable) do
                        local leaf = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGP_Progress"), "TreeItem", {
                                Label = function()
                                    return FormatProgressLabel(kPlayerPoints, kPerson.RecruitCost)
                                end,
                                FocusKey = "gpprog:" .. tostring(personID) .. ":" .. tostring(kPlayerPoints.PlayerID),
                            })
                        item:AddChild(leaf)
                    end
                end
            end
        end

        m_ui.gpTree:AddChild(item)
    end

    mgr:RestoreFocus(m_ui.gpTree, capture)
end

-- ===========================================================================
-- Tab 2: Previously Recruited table
-- ===========================================================================

local function FormatPastRecruiter(kPerson)
    local localPlayerID = Game.GetLocalPlayer()
    if kPerson.ClaimantID == nil then return "" end
    if kPerson.ClaimantID == localPlayerID then
        return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU")
    end

    local localPlayer = Players[localPlayerID]
    if Game.GetLocalObserver() == PlayerTypes.OBSERVER
        or (localPlayer and localPlayer:GetDiplomacy() and localPlayer:GetDiplomacy():HasMet(kPerson.ClaimantID)) then
        local config = PlayerConfigurations[kPerson.ClaimantID]
        if config then return Locale.Lookup(config:GetPlayerName()) end
    end

    return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
end

local function FormatPastAbilities(kPerson)
    local parts = {}
    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = kPerson.PassiveNameText .. ": " .. kPerson.PassiveEffectText
    end
    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionText = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionText = actionText .. " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end
    return JoinNonEmpty(parts, ". ")
end

local function BuildPastTable(data)
    if not mgr or not m_ui.pastTable then return end
    local capture = mgr:CaptureFocusKey(m_ui.pastTable)
    m_ui.pastTable:ClearRows()

    if not data or not data.Timeline then
        mgr:RestoreFocus(m_ui.pastTable, capture)
        return
    end

    for _, kPerson in ipairs(data.Timeline) do
        local className = ""
        if kPerson.ClassID then
            className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
        end
        local personLabel = className .. ": " .. (kPerson.Name or "")

        local earnDate = ""
        if kPerson.TurnGranted then
            earnDate = Calendar.MakeYearStr(kPerson.TurnGranted)
        end

        local recruiter = FormatPastRecruiter(kPerson)
        local abilities = FormatPastAbilities(kPerson)

        local focusKey = kPerson.IndividualID and ("past:" .. tostring(kPerson.IndividualID)) or nil
        local cellPerson = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastPerson"), "StaticText", {
            Label = function() return personLabel end,
            FocusKey = focusKey,
        })
        local cellDate = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastDate"), "StaticText", {
            Label = function() return earnDate end,
        })
        local cellRecruiter = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastRecruiter"), "StaticText", {
            Label = function() return recruiter end,
        })
        local cellAbilities = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastAbilities"), "StaticText", {
            Label = function() return abilities end,
        })

        m_ui.pastTable:AddRow({ cellPerson, cellDate, cellRecruiter, cellAbilities })
    end

    mgr:RestoreFocus(m_ui.pastTable, capture)
end

-- ===========================================================================
-- Tab 3: Heroes (Babylon DLC)
-- ===========================================================================

local function GetHeroStack()
    if not m_hasBabylon then return nil end
    return ContextPtr:LookUpControl("GreatPeopleHeroPanel/HeroStack")
end

local function ClassifyEffectChild(child)
    local statIcon = FindChildById(child, "StatIcon")
    if statIcon then return "stat" end
    local abilityName = FindChildById(child, "AbilityName")
    if abilityName then return "ability" end
    local commandIcon = FindChildById(child, "CommandIcon")
    if commandIcon then return "command" end
    return nil
end

local function ReadHeroTooltipFromControls(content)
    local parts = {}

    local effectStack = FindChildById(content, "EffectStack")
    if effectStack then
        local statParts = {}
        local abilityParts = {}
        local commandParts = {}
        for _, child in ipairs(effectStack:GetChildren()) do
            local kind = ClassifyEffectChild(child)
            if kind == "stat" then
                local nameCtrl = FindChildById(child, "NameText")
                local valCtrl = FindChildById(child, "ValueText")
                if nameCtrl and valCtrl then
                    statParts[#statParts + 1] = ControlText(nameCtrl) .. ": " .. ControlText(valCtrl)
                end
            elseif kind == "ability" then
                local nameCtrl = FindChildById(child, "AbilityName")
                local textCtrl = FindChildById(child, "AbilityText")
                if nameCtrl then
                    local t = StripIcons(ControlText(nameCtrl))
                    if textCtrl then t = t .. ": " .. ControlText(textCtrl) end
                    abilityParts[#abilityParts + 1] = t
                end
            elseif kind == "command" then
                local nameCtrl = FindChildById(child, "CommandName")
                local textCtrl = FindChildById(child, "CommandText")
                if nameCtrl then
                    local t = StripIcons(ControlText(nameCtrl))
                    if textCtrl then t = t .. ": " .. ControlText(textCtrl) end
                    commandParts[#commandParts + 1] = t
                end
            end
        end
        if #statParts > 0 then
            parts[#parts + 1] = JoinNonEmpty(statParts, ", ")
        end
        for _, a in ipairs(abilityParts) do parts[#parts + 1] = a end
        for _, c in ipairs(commandParts) do parts[#parts + 1] = c end
    end

    local statusCtrl = FindChildById(content, "HeroStatus")
    if statusCtrl then
        local statusText = ControlText(statusCtrl)
        local deceasedCtrl = FindChildById(content, "DeceasedText")
        if deceasedCtrl and not ControlIsHidden(deceasedCtrl) then
            statusText = statusText .. ", " .. ControlText(deceasedCtrl)
        end
        if statusText ~= "" then parts[#parts + 1] = statusText end
    end

    return JoinNonEmpty(parts, ", ")
end

local function BuildHeroesTree()
    if not mgr or not m_ui.heroTree then return end
    local heroStack = GetHeroStack()
    if not heroStack then return end

    local capture = mgr:CaptureFocusKey(m_ui.heroTree)
    m_ui.heroTree:ClearChildren()

    for _, content in ipairs(heroStack:GetChildren()) do
        local nameCtrl = FindChildById(content, "IndividualName")
        if nameCtrl then
            local heroName = StripIcons(ControlText(nameCtrl))
            if heroName ~= "" then
                local heroItem = mgr:CreateWidget(
                    mgr:GenerateWidgetId("CAIGP_Hero"), "TreeItem", {
                        Label = function() return heroName end,
                        Tooltip = function() return ReadHeroTooltipFromControls(content) end,
                        FocusKey = "hero:" .. heroName:gsub("%s+", "_"),
                    })

                local lookAtBtn = FindChildById(content, "LookAtButton")
                if lookAtBtn then
                    local btn = mgr:CreateWidget(
                        mgr:GenerateWidgetId("CAIGP_HeroLookAt"), "Button", {
                            Label = function() return ControlTooltip(lookAtBtn) end,
                            HiddenPredicate = function() return ControlIsHidden(lookAtBtn) end,
                        })
                    btn:On("activate", function() lookAtBtn:DoLeftClick() end)
                    heroItem:AddChild(btn)
                end

                local civBtn = FindChildById(content, "CivilopediaButton")
                if civBtn then
                    local btn = mgr:CreateWidget(
                        mgr:GenerateWidgetId("CAIGP_HeroCivpedia"), "Button", {
                            Label = function() return Locale.Lookup("LOC_CAI_GP_HERO_CIVILOPEDIA") end,
                            HiddenPredicate = function() return ControlIsHidden(civBtn) end,
                        })
                    btn:On("activate", function() civBtn:DoLeftClick() end)
                    heroItem:AddChild(btn)
                end

                local recallBtn = FindChildById(content, "FaithRecallButton")
                if recallBtn then
                    local btn = mgr:CreateWidget(
                        mgr:GenerateWidgetId("CAIGP_HeroRecall"), "Button", {
                            Label = function() return ControlText(recallBtn) end,
                            Tooltip = function() return ControlTooltip(recallBtn) end,
                            HiddenPredicate = function() return ControlIsHidden(recallBtn) end,
                            DisabledPredicate = function() return ControlIsDisabled(recallBtn) end,
                        })
                    btn:On("activate", function() recallBtn:DoLeftClick() end)
                    heroItem:AddChild(btn)
                end

                m_ui.heroTree:AddChild(heroItem)
            end
        end
    end

    mgr:RestoreFocus(m_ui.heroTree, capture)
end

-- ===========================================================================
-- Panel builder
-- ===========================================================================

local function GetFocusedPerson()
    return m_cachedPersons[m_focusedPersonID]
end

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_TITLE") end,
    })

    m_ui.tabs = mgr:CreateWidget(TABS_ID, "TabControl", {})

    -- Tab 1: Great People
    m_ui.gpPage = m_ui.tabs:AddPage(function()
        return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE")
    end)

    m_ui.gpTree = mgr:CreateWidget(GP_TREE_ID, "Tree", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_GREAT_PEOPLE") end,
    })
    m_ui.gpPage:AddChild(m_ui.gpTree)

    m_ui.bioEdit = mgr:CreateWidget(GP_BIO_ID, "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_GP_BIOGRAPHY") end,
    })
    m_ui.bioEdit:SetReadOnly(true)
    m_ui.bioEdit:SetAlwaysEdit(true)
    m_ui.gpPage:AddChild(m_ui.bioEdit)

    -- Action buttons — call vanilla global callbacks directly with individualID
    m_ui.recruitBtn = mgr:CreateWidget(GP_RECRUIT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RecruitCost then
                return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT") .. ", " ..
                    Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT_DETAILS", p.RecruitCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT")
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT") and p.CanRecruit and p.RecruitCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.recruitBtn:On("activate", function()
        if m_focusedPersonID then OnRecruitButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.recruitBtn)

    m_ui.rejectBtn = mgr:CreateWidget(GP_REJECT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RejectCost then
                return Locale.Lookup("LOC_GREAT_PEOPLE_PASS") .. ", " ..
                    Locale.Lookup("LOC_GREAT_PEOPLE_PASS_DETAILS", p.RejectCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_PASS")
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT") and p.CanReject and p.RejectCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.rejectBtn:On("activate", function()
        if m_focusedPersonID then OnRejectButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.rejectBtn)

    m_ui.goldBtn = mgr:CreateWidget(GP_GOLD_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithGoldCost then
                return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_GOLD_DETAILS", p.PatronizeWithGoldCost)
            end
            return ""
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            if not HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD") then return true end
            if p.CanRecruit or p.CanReject then return true end
            return not (p.PatronizeWithGoldCost and p.PatronizeWithGoldCost < 1000000)
        end,
        DisabledPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return (not p.CanPatronizeWithGold) or IsReadOnly()
        end,
    })
    m_ui.goldBtn:On("activate", function()
        if m_focusedPersonID then OnGoldButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.goldBtn)

    m_ui.faithBtn = mgr:CreateWidget(GP_FAITH_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithFaithCost then
                return Locale.Lookup("LOC_GREAT_PEOPLE_PATRONAGE_FAITH_DETAILS", p.PatronizeWithFaithCost)
            end
            return ""
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            if not HasCapability("CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH") then return true end
            if p.CanRecruit or p.CanReject then return true end
            return not (p.PatronizeWithFaithCost and p.PatronizeWithFaithCost < 1000000)
        end,
        DisabledPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return (not p.CanPatronizeWithFaith) or IsReadOnly()
        end,
    })
    m_ui.faithBtn:On("activate", function()
        if m_focusedPersonID then OnFaithButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.faithBtn)

    -- Tab 2: Previously Recruited
    m_ui.pastPage = m_ui.tabs:AddPage(function()
        return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_PREVIOUSLY_RECRUITED")
    end)

    m_ui.pastTable = mgr:CreateWidget(PAST_TABLE_ID, "Table", {
        Label = function() return Locale.Lookup("LOC_CAI_GP_PAST_TABLE") end,
    })
    m_ui.pastTable:AddColumn({ header = Locale.Lookup("LOC_CAI_GP_COL_PERSON") })
    m_ui.pastTable:AddColumn({ header = Locale.Lookup("LOC_CAI_GP_COL_DATE") })
    m_ui.pastTable:AddColumn({ header = Locale.Lookup("LOC_CAI_GP_COL_RECRUITER") })
    m_ui.pastTable:AddColumn({ header = Locale.Lookup("LOC_CAI_GP_COL_ABILITIES") })
    m_ui.pastPage:AddChild(m_ui.pastTable)

    -- Tab 3: Heroes (Babylon DLC)
    if m_hasBabylon then
        m_ui.heroPage = m_ui.tabs:AddPage(function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_HEROES")
        end)

        m_ui.heroTree = mgr:CreateWidget(HEROES_TREE_ID, "Tree", {
            Label = function() return Locale.Lookup("LOC_CAI_GP_HEROES_TREE") end,
        })
        m_ui.heroPage:AddChild(m_ui.heroTree)
    end

    m_ui.tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        m_isMirroringTab = true
        if idx == 1 then
            OnGreatPeopleClick(nil)
        elseif idx == 2 then
            OnPreviousRecruitedClick(nil)
        elseif idx == 3 and m_hasBabylon and OnHeroesClick then
            OnHeroesClick(nil)
        end
        m_isMirroringTab = false
    end)

    m_ui.panel:AddChild(m_ui.tabs)
end

-- ===========================================================================
-- Lifecycle helpers
-- ===========================================================================

local function PushPanel()
    if not mgr then return end
    if not m_ui.panel then BuildPanel() end
    if not m_ui.panel then return end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil, tabs = nil,
        gpPage = nil, gpTree = nil, bioEdit = nil,
        recruitBtn = nil, rejectBtn = nil, goldBtn = nil, faithBtn = nil,
        pastPage = nil, pastTable = nil,
        heroPage = nil, heroTree = nil,
    }
    m_cachedPersons = {}
    m_cachedData = nil
    m_focusedPersonID = nil
    m_isMirroringTab = false
end

-- ===========================================================================
-- Vanilla function wraps
-- ===========================================================================

AddRecruit = WrapFunc(AddRecruit, function(orig, kData, kPerson)
    orig(kData, kPerson)
    if kPerson and kPerson.IndividualID then
        m_cachedPersons[kPerson.IndividualID] = kPerson
    end
end)

ViewCurrent = WrapFunc(ViewCurrent, function(orig, data)
    m_cachedPersons = {}
    m_cachedData = nil
    orig(data)
    m_cachedData = data
    BuildGPTree()
end)

ViewPast = WrapFunc(ViewPast, function(orig, data)
    orig(data)
    BuildPastTable(data)
end)

Open = WrapFunc(Open, function(orig)
    if not m_ui.panel then BuildPanel() end
    orig()
    if not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    orig()
    if ContextPtr:IsHidden() then
        PopPanel()
    end
end)

OnGreatPeopleClick = WrapFunc(OnGreatPeopleClick, function(orig, uiSelectedButton)
    orig(uiSelectedButton)
    if m_ui.tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_ui.tabs:SetActivePage(1, true)
        m_isMirroringTab = false
    end
end)

OnPreviousRecruitedClick = WrapFunc(OnPreviousRecruitedClick, function(orig, uiSelectedButton)
    orig(uiSelectedButton)
    if m_ui.tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_ui.tabs:SetActivePage(2, true)
        m_isMirroringTab = false
    end
end)

-- Babylon-specific wraps are deferred to LateInitialize because the Babylon
-- override files may load after this CAI file in the wildcard batch; by the time
-- LateInitialize runs (called from Initialize()), all wildcard files have loaded.
local BASE_CAI_LateInitialize = LateInitialize
function LateInitialize()
    if BASE_CAI_LateInitialize then BASE_CAI_LateInitialize() end

    m_hasBabylon = (OnHeroesClick ~= nil) and (Game.GetHeroesManager ~= nil)

    if m_hasBabylon then
        OnHeroesClick = WrapFunc(OnHeroesClick, function(orig, uiSelectedButton)
            orig(uiSelectedButton)
            if m_ui.tabs and not m_isMirroringTab then
                m_isMirroringTab = true
                m_ui.tabs:SetActivePage(3, true)
                m_isMirroringTab = false
            end
        end)

        RefreshHeroesPanel = WrapFunc(RefreshHeroesPanel, function(orig)
            orig()
            BuildHeroesTree()
        end)
    end
end

-- Vanilla Initialize() calls ContextPtr:SetInputHandler(OnInputHandler, true) after
-- all wildcard includes, so reassigning the global here is enough.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel then
            if mgr:HandleInput(input) then return true end
        end
    end
    return orig(input)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
