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

local mgr                 = ExposedMembers.CAI_UIManager

-- ===========================================================================
-- Constants
-- ===========================================================================

local PANEL_ID            = "CAIGreatPeople_Panel"
local TABS_ID             = "CAIGreatPeople_Tabs"
local GP_TABLE_ID         = "CAIGreatPeople_Table"
local GP_TREE_ID          = "CAIGreatPeople_Tree"
local GP_SORT_ID          = "CAIGreatPeople_Sort"
local GP_BIO_ID           = "CAIGreatPeople_Bio"
local GP_RECRUIT_BTN_ID   = "CAIGreatPeople_RecruitBtn"
local GP_REJECT_BTN_ID    = "CAIGreatPeople_RejectBtn"
local GP_GOLD_BTN_ID      = "CAIGreatPeople_GoldBtn"
local GP_FAITH_BTN_ID     = "CAIGreatPeople_FaithBtn"
local GP_SWITCH_VIEW_ID   = "CAIGreatPeople_SwitchView"
local PAST_LIST_ID        = "CAIGreatPeople_PastList"
local HEROES_LIST_ID      = "CAIGreatPeople_HeroesList"
local HEROES_TABLE_ID     = "CAIGreatPeople_HeroesTable"
local HEROES_SORT_ID      = "CAIGreatPeople_HeroesSort"
local HEROES_SWITCH_ID    = "CAIGreatPeople_HeroesSwitch"
local HERO_RECALL_BTN_ID  = "CAIGreatPeople_HeroRecallBtn"

local VIEW_SETTING_SECTION = "UI"
local VIEW_SETTING_ID      = "GreatPeopleViewMode"
local HERO_VIEW_SETTING_ID = "GreatPeopleHeroesViewMode"

local HOVER_SOUND         = "Main_Menu_Mouse_Over"

local m_hasBabylon        = false

local function LoadViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, VIEW_SETTING_ID, "table")):lower()
    if stored == "tree" then return "tree" end
    if stored ~= "table" then
        LogWarn("Great People ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, VIEW_SETTING_ID, viewMode) then
        LogError("Great People failed to save view mode " .. tostring(viewMode))
    end
end

local function LoadHeroViewModeSetting()
    local stored = tostring(CAI.GetConfigValue(
        VIEW_SETTING_SECTION, HERO_VIEW_SETTING_ID, "table")):lower()
    if stored == "list" then return "list" end
    if stored ~= "table" then
        LogWarn("Great People Heroes ignored invalid saved view mode " .. tostring(stored))
    end
    return "table"
end

local function SaveHeroViewModeSetting(viewMode)
    if not CAI.SetConfigValue(VIEW_SETTING_SECTION, HERO_VIEW_SETTING_ID, viewMode) then
        LogError("Great People Heroes failed to save view mode " .. tostring(viewMode))
    end
end

-- ===========================================================================
-- State
-- ===========================================================================

local m_ui                = {
    panel         = nil,
    tabs          = nil,
    gpPage        = nil,
    gpTable       = nil,
    gpTree        = nil,
    gpSort        = nil,
    bioEdit       = nil,
    recruitBtn    = nil,
    rejectBtn     = nil,
    goldBtn       = nil,
    faithBtn      = nil,
    switchView    = nil,
    pastPage      = nil,
    pastList      = nil,
    heroPage      = nil,
    heroTable     = nil,
    heroList      = nil,
    heroSort      = nil,
    heroSwitch    = nil,
    heroRecallBtn = nil,
}

local m_cachedPersons     = {}
local m_cachedData        = nil
local m_cachedProgress    = {}
local m_progressPlayerIDs = {}
local m_focusedPersonID   = nil
local m_focusedClassID    = nil
local m_focusedProgressPlayerID = nil
local m_focusedHero       = nil
local m_focusedHeroClass  = nil
local m_heroRecords       = {}
local m_heroColumns       = {}
local m_heroSortOptions   = {}
local m_heroSortColumn    = "name"
local m_heroSortAscending = true
local m_heroViewMode      = LoadHeroViewModeSetting()
local m_FocusRecruitable  = nil
local m_FocusRecruitableClassID = nil
local m_viewMode          = LoadViewModeSetting()
local m_gpSortColumn      = nil
local m_gpSortAscending   = false
local m_gpSortOptions     = {}
local UpdateBiographyAndButtons
local m_FocusHero         = nil
local m_isMirroringTab    = false
local m_vanillaTabButtons = {}
local m_vanillaTabCount   = 0

-- ===========================================================================
-- Control helpers
-- ===========================================================================

local function JoinNonEmpty(parts, sep)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then out[#out + 1] = part end
    end
    return table.concat(out, sep)
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
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", Locale.Lookup("LOC_GREAT_PEOPLE_NONE_AVAILABLE"), className)
            .. ", " .. Locale.Lookup("LOC_GREAT_PEOPLE_ALL_POSSIBLE_CHOSEN")
    end
    local name = kPerson.Name or ""
    local className = ""
    if kPerson.ClassID then
        className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL_EARN_BLOCKED", name, className, kPerson.EarnConditions)
    end

    if kPerson.CanRecruit then
        return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL_RECRUITABLE", name, className)
    end

    return Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", name, className)
end

local function FormatPersonTooltip(kPerson)
    if not kPerson or not kPerson.IndividualID then return "" end
    local parts = {}

    if kPerson.EraID then
        parts[#parts + 1] = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name)
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

    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = kPerson.PassiveNameText .. ": " .. kPerson.PassiveEffectText
    end

    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionText = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionText = actionText ..
                " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        if kPerson.ActionUsageText and kPerson.ActionUsageText ~= "" then
            actionText = actionText .. ", " .. kPerson.ActionUsageText
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        parts[#parts + 1] = kPerson.EarnConditions
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function FormatProgressLabel(kPlayerPoints, recruitCost)
    return Locale.Lookup("LOC_CAI_GP_CIV_PROGRESS",
        kPlayerPoints.PlayerName,
        tostring(Round(kPlayerPoints.PointsTotal, 1)),
        tostring(recruitCost),
        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
end

local function GetLocalProgressText(kPerson)
    if not kPerson or not kPerson.ClassID or not m_cachedData or not m_cachedData.PointsByClass then
        return ""
    end

    local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
    if not pointsByClass then return "" end

    local localPlayerID = Game.GetLocalPlayer()
    for _, kPlayerPoints in ipairs(pointsByClass) do
        if kPlayerPoints.PlayerID == localPlayerID then
            return FormatProgressLabel(kPlayerPoints, kPerson.RecruitCost)
        end
    end
    return ""
end

local function IsRecruitActionAvailable(kPerson)
    return kPerson
        and HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT")
        and kPerson.CanRecruit
        and kPerson.RecruitCost
        and not IsReadOnly()
end

local function IsPassActionAvailable(kPerson)
    return kPerson
        and HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT")
        and kPerson.CanReject
        and kPerson.RejectCost
        and not IsReadOnly()
end

local function GetBiographyText(kPerson)
    if not kPerson or not kPerson.BiographyTextTable then
        return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY")
    end
    local text = table.concat(kPerson.BiographyTextTable, "[NEWLINE][NEWLINE]")
    if text == "" then return Locale.Lookup("LOC_CAI_GP_NO_BIOGRAPHY") end
    return table.concat(SplitTextIntoLines(text), "[NEWLINE]")
end

-- ===========================================================================
-- Tab 1: Great People comparison table
-- ===========================================================================

local function FormatAbility(name, effect)
    if not name or name == "" then return effect or "" end
    if not effect or effect == "" then return name end
    return Locale.Lookup("LOC_CAI_GP_ABILITY_EFFECT", name, effect)
end

local function FormatTablePersonHeader(kPerson)
    if not kPerson or not kPerson.IndividualID then
        return FormatPersonLabel(kPerson)
    end

    local parts = {}
    local className = ""
    if kPerson.ClassID then
        className = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
    end
    parts[#parts + 1] = Locale.Lookup("LOC_CAI_GP_PERSON_LABEL", kPerson.Name or "", className)

    if kPerson.EraID then
        parts[#parts + 1] = Locale.Lookup(GameInfo.Eras[kPerson.EraID].Name)
    end

    if kPerson.PassiveNameText and kPerson.PassiveNameText ~= "" then
        parts[#parts + 1] = FormatAbility(kPerson.PassiveNameText, kPerson.PassiveEffectText)
    end

    if kPerson.ActionNameText and kPerson.ActionNameText ~= "" then
        local actionName = kPerson.ActionNameText
        if kPerson.ActionCharges and kPerson.ActionCharges > 0 then
            actionName = Locale.Lookup(
                "LOC_CAI_GP_ABILITY_WITH_CHARGES",
                actionName,
                Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges))
        end
        parts[#parts + 1] = FormatAbility(actionName, kPerson.ActionEffectText)
        if kPerson.ActionUsageText and kPerson.ActionUsageText ~= "" then
            parts[#parts + 1] = kPerson.ActionUsageText
        end
    end

    if kPerson.EarnConditions and kPerson.EarnConditions ~= "" then
        parts[#parts + 1] = kPerson.EarnConditions
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function ReindexProgressData()
    m_cachedProgress = {}
    m_progressPlayerIDs = {}
    if not m_cachedData or not m_cachedData.PointsByClass then return end

    for classID, pointsByPlayer in pairs(m_cachedData.PointsByClass) do
        for _, kPlayerPoints in ipairs(pointsByPlayer) do
            local playerID = kPlayerPoints.PlayerID
            local playerData = m_cachedProgress[playerID]
            if not playerData then
                playerData = {
                    PlayerID = playerID,
                    PlayerName = kPlayerPoints.PlayerName,
                    IsPlayer = kPlayerPoints.IsPlayer,
                    ByClass = {},
                }
                m_cachedProgress[playerID] = playerData
                m_progressPlayerIDs[#m_progressPlayerIDs + 1] = playerID
            end
            playerData.ByClass[classID] = kPlayerPoints
        end
    end

    table.sort(m_progressPlayerIDs, function(a, b)
        local aData = m_cachedProgress[a]
        local bData = m_cachedProgress[b]
        if aData.IsPlayer ~= bData.IsPlayer then return aData.IsPlayer end
        return a < b
    end)

    if not m_cachedProgress[m_focusedProgressPlayerID] then
        local localPlayerID = Game.GetLocalPlayer()
        m_focusedProgressPlayerID = m_cachedProgress[localPlayerID]
            and localPlayerID
            or m_progressPlayerIDs[1]
    end
end

local function GetProgressPlayerLabel(playerID)
    local playerData = m_cachedProgress[playerID]
    if not playerData then return "" end
    if playerData.IsPlayer then
        return Locale.Lookup("LOC_CAI_GP_LOCAL_CIVILIZATION", playerData.PlayerName)
    end
    return playerData.PlayerName
end

local function GetProgressForClass(playerID, classID)
    local playerData = m_cachedProgress[playerID]
    return playerData and playerData.ByClass[classID] or nil
end

local function FormatTableProgress(playerID, kPerson)
    if not kPerson or not kPerson.IndividualID then return "" end
    local kPlayerPoints = GetProgressForClass(playerID, kPerson.ClassID)
    if not kPlayerPoints then return "" end
    return Locale.Lookup(
        "LOC_CAI_GP_TABLE_PROGRESS",
        tostring(Round(kPlayerPoints.PointsTotal, 1)),
        tostring(kPerson.RecruitCost),
        tostring(Round(kPlayerPoints.PointsPerTurn, 1)))
end

local function BuildGPTableColumns()
    local columns = {
        {
            key = "civilization",
            header = function() return Locale.Lookup("LOC_CAI_GP_CIVILIZATION_NAME") end,
            sortLabel = function() return Locale.Lookup("LOC_CAI_GP_CIVILIZATION_NAME") end,
            getCell = GetProgressPlayerLabel,
            sortKey = function(playerID)
                local playerData = m_cachedProgress[playerID]
                return playerData and playerData.PlayerName or ""
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
    }

    if not m_cachedData or not m_cachedData.Timeline then return columns end
    for timelineIndex, kPerson in ipairs(m_cachedData.Timeline) do
        local classID = kPerson.ClassID
        local capturedPerson = kPerson
        local capturedClassID = classID
        local column = {
            key = "class:" .. tostring(classID or timelineIndex),
            header = function() return FormatTablePersonHeader(capturedPerson) end,
            sortLabel = function()
                local class = capturedClassID and GameInfo.GreatPersonClasses[capturedClassID] or nil
                return class and Locale.Lookup(class.Name) or FormatTablePersonHeader(capturedPerson)
            end,
            getCell = function(playerID) return FormatTableProgress(playerID, capturedPerson) end,
            GreatPersonID = capturedPerson.IndividualID,
            GreatPersonClassID = capturedClassID,
        }
        if capturedPerson.IndividualID and capturedClassID then
            column.sortKey = function(playerID)
                local points = GetProgressForClass(playerID, capturedClassID)
                return points and points.PointsTotal or nil
            end
            column.sortAscendingDescription = "LOC_CAI_SORT_LOWEST_PROGRESS_FIRST"
            column.sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_PROGRESS_FIRST"
        end
        columns[#columns + 1] = column
    end
    return columns
end

local function ResolveColumnSortLabel(column)
    local label = column.sortLabel or column.header
    return type(label) == "function" and label() or label or ""
end

local function BuildGPSortOptions(columns)
    local options = {
        {
            label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"),
            value = { column = nil, ascending = false },
        },
    }
    for _, column in ipairs(columns) do
        if column.sortKey then
            local header = ResolveColumnSortLabel(column)
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

local function SyncGPSortDropdown()
    if not m_ui.gpSort then return end
    for index, option in ipairs(m_gpSortOptions) do
        local sort = option.value
        if sort.column == m_gpSortColumn
            and (sort.column == nil or sort.ascending == m_gpSortAscending) then
            m_ui.gpSort:SetSelectedIndex(index, true)
            return
        end
    end
end

local function CompareGPSortValues(a, b)
    if a == b then return 0 end
    if a == nil then return 1 end
    if b == nil then return -1 end
    if type(a) == "number" and type(b) == "number" then return a < b and -1 or 1 end
    return Locale.Compare(tostring(a), tostring(b))
end

local function SortTreeProgress(pointsByPlayer)
    local entriesByPlayerID = {}
    for _, points in ipairs(pointsByPlayer) do
        entriesByPlayerID[points.PlayerID] = points
    end

    local ordered = {}
    for _, playerID in ipairs(m_progressPlayerIDs) do
        local points = entriesByPlayerID[playerID]
        if points then
            ordered[#ordered + 1] = points
            entriesByPlayerID[playerID] = nil
        end
    end
    for _, points in ipairs(pointsByPlayer) do
        if entriesByPlayerID[points.PlayerID] then
            ordered[#ordered + 1] = points
            entriesByPlayerID[points.PlayerID] = nil
        end
    end

    if not m_gpSortColumn then
        table.sort(ordered, function(a, b)
            if a.PointsTotal == b.PointsTotal then return a.PlayerID < b.PlayerID end
            return a.PointsTotal > b.PointsTotal
        end)
        return ordered
    end

    local sortColumn = nil
    for _, column in ipairs(BuildGPTableColumns()) do
        if column.key == m_gpSortColumn then
            sortColumn = column
            break
        end
    end
    if not sortColumn or not sortColumn.sortKey then return ordered end

    local decorated = {}
    for naturalIndex, points in ipairs(ordered) do
        decorated[#decorated + 1] = {
            points = points,
            naturalIndex = naturalIndex,
            value = sortColumn.sortKey(points.PlayerID),
        }
    end
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.naturalIndex < b.naturalIndex end
            return a.value ~= nil
        end
        local comparison = CompareGPSortValues(a.value, b.value)
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        if m_gpSortAscending then return comparison < 0 end
        return comparison > 0
    end)

    ordered = {}
    for _, entry in ipairs(decorated) do ordered[#ordered + 1] = entry.points end
    return ordered
end

local function GetGPTableFocusKey(playerID, classID)
    if playerID == nil or classID == nil then return nil end
    return GP_TABLE_ID .. ":row:" .. tostring(playerID) .. ":class:" .. tostring(classID)
end

local function GetFocusedTablePerson()
    if not m_ui.gpTable then return nil end
    local row = m_ui.gpTable:GetFocusedRow()
    local column = m_ui.gpTable:GetFocusedColumn()
    if not row or not column or not column.GreatPersonID then return nil end
    return m_cachedPersons[column.GreatPersonID]
end

local function ActivateFocusedTablePerson()
    local kPerson = GetFocusedTablePerson()
    if not kPerson then return false end
    m_focusedPersonID = kPerson.IndividualID
    m_focusedClassID = kPerson.ClassID
    UpdateBiographyAndButtons()
    if IsRecruitActionAvailable(kPerson) then
        OnRecruitButtonClick(kPerson.IndividualID)
    else
        local progressText = GetLocalProgressText(kPerson)
        if progressText ~= "" then Speak(progressText) end
    end
    return true
end

local function PassFocusedTablePerson()
    local kPerson = GetFocusedTablePerson()
    if not kPerson then return false end
    m_focusedPersonID = kPerson.IndividualID
    m_focusedClassID = kPerson.ClassID
    UpdateBiographyAndButtons()
    if IsPassActionAvailable(kPerson) then
        OnRejectButtonClick(kPerson.IndividualID)
    end
    return true
end

local function BuildGPTable()
    if not mgr or not m_ui.gpTable then return end
    ReindexProgressData()
    local columns = BuildGPTableColumns()
    m_ui.gpTable:SetColumns(columns)
    local resetSort = false
    if m_gpSortColumn and not m_ui.gpTable:GetColumnIndex(m_gpSortColumn) then
        m_gpSortColumn = nil
        m_gpSortAscending = false
        resetSort = true
    end
    m_ui.gpTable:SetDefaultSort(m_gpSortColumn
        and { column = m_gpSortColumn, ascending = m_gpSortAscending }
        or nil)
    m_gpSortOptions = BuildGPSortOptions(columns)
    if m_ui.gpSort then
        local dropdownCapture = mgr:CaptureFocusKey(m_ui.gpSort)
        m_ui.gpSort:SetOptions(m_gpSortOptions)
        SyncGPSortDropdown()
        if dropdownCapture then
            if resetSort then
                dropdownCapture = { key = m_ui.gpSort.FocusKey, path = {} }
            end
            mgr:RestoreFocus(m_ui.gpSort, dropdownCapture)
        end
    end
    m_ui.gpTable:Rebuild()
end

-- ===========================================================================
-- Tab 1: Build GP tree
-- ===========================================================================

UpdateBiographyAndButtons = function()
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

    local firstRecruitableKey = nil
    local firstRecruitableID = nil
    local firstPersonID = nil
    local firstPersonClassID = nil
    m_FocusRecruitable = nil
    m_FocusRecruitableClassID = nil
    for _, kPerson in ipairs(m_cachedData.Timeline) do
        local personID = kPerson.IndividualID
        local item = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIGP_Person"), "TreeItem", {
                Label    = function() return FormatPersonLabel(kPerson) end,
                Tooltip  = function() return FormatPersonTooltip(kPerson) end,
                FocusKey = personID and ("gp:" .. tostring(personID)) or nil,
            })
        item:SetFocusSound(HOVER_SOUND)

        if personID then
            if not firstPersonID then
                firstPersonID = personID
                firstPersonClassID = kPerson.ClassID
            end
            if not firstRecruitableKey and kPerson.CanRecruit then
                firstRecruitableKey = "gp:" .. tostring(personID)
                firstRecruitableID = personID
                m_FocusRecruitableClassID = kPerson.ClassID
            end

            item:On("focus_enter", function()
                m_focusedPersonID = personID
                m_focusedClassID = kPerson.ClassID
                UpdateBiographyAndButtons()
            end)

            item:On("activate", function()
                if IsRecruitActionAvailable(kPerson) then
                    OnRecruitButtonClick(personID)
                else
                    local progressText = GetLocalProgressText(kPerson)
                    if progressText ~= "" then Speak(progressText) end
                end
            end)

            item:AddInputBindings({
                {
                    Key = Keys.VK_DELETE,
                    MSG = KeyEvents.KeyUp,
                    Description = "LOC_GREAT_PEOPLE_PASS",
                    Action = function()
                        if IsPassActionAvailable(kPerson) then
                            OnRejectButtonClick(personID)
                        end
                        return true
                    end,
                },
            })

            if m_cachedData.PointsByClass and kPerson.ClassID then
                local pointsByClass = m_cachedData.PointsByClass[kPerson.ClassID]
                if pointsByClass then
                    local recruitTable = SortTreeProgress(pointsByClass)

                    for _, kPlayerPoints in ipairs(recruitTable) do
                        local leaf = mgr:CreateWidget(
                            mgr:GenerateWidgetId("CAIGP_Progress"), "TreeItem", {
                                Label = function()
                                    return FormatProgressLabel(kPlayerPoints, kPerson.RecruitCost)
                                end,
                                FocusKey = "gpprog:" .. tostring(personID) .. ":" .. tostring(kPlayerPoints.PlayerID),
                            })
                        leaf:SetFocusSound(HOVER_SOUND)
                        item:AddChild(leaf)
                    end
                end
            end
        end

        m_ui.gpTree:AddChild(item)
    end

    if firstRecruitableKey then
        m_FocusRecruitable = firstRecruitableKey
    end
    if not m_cachedPersons[m_focusedPersonID] then
        m_focusedPersonID = firstRecruitableID or firstPersonID
        local focused = m_cachedPersons[m_focusedPersonID]
        m_focusedClassID = focused and focused.ClassID or firstPersonClassID
        UpdateBiographyAndButtons()
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
            actionText = actionText ..
                " (" .. Locale.Lookup("LOC_GREATPERSON_ACTION_CHARGES", kPerson.ActionCharges) .. ")"
        end
        if kPerson.ActionUsageText and kPerson.ActionUsageText ~= "" then
            actionText = actionText .. ", " .. kPerson.ActionUsageText
        end
        actionText = actionText .. ": " .. kPerson.ActionEffectText
        parts[#parts + 1] = actionText
    end
    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function BuildPastList(data)
    if not mgr or not m_ui.pastList then return end
    local capture = mgr:CaptureFocusKey(m_ui.pastList)
    m_ui.pastList:ClearChildren()

    if not data or not data.Timeline then
        mgr:RestoreFocus(m_ui.pastList, capture)
        return
    end

    for _, kPerson in ipairs(data.Timeline) do
        local parts = {}

        if kPerson.TurnGranted then
            parts[#parts + 1] = Calendar.MakeYearStr(kPerson.TurnGranted)
        end

        if kPerson.ClassID then
            parts[#parts + 1] = Locale.Lookup(GameInfo.GreatPersonClasses[kPerson.ClassID].Name)
        end

        if kPerson.Name and kPerson.Name ~= "" then
            parts[#parts + 1] = kPerson.Name
        end

        local recruiter = FormatPastRecruiter(kPerson)
        if recruiter ~= "" then
            parts[#parts + 1] = recruiter
        end

        local abilities = FormatPastAbilities(kPerson)
        if abilities ~= "" then
            parts[#parts + 1] = abilities
        end

        local label = table.concat(parts, "[NEWLINE]")
        local focusKey = kPerson.IndividualID and ("past:" .. tostring(kPerson.IndividualID)) or nil
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_PastRow"), "StaticText", {
            Label = function() return label end,
            FocusKey = focusKey,
        })
        row:SetFocusSound(HOVER_SOUND)
        m_ui.pastList:AddChild(row)
    end

    mgr:RestoreFocus(m_ui.pastList, capture)
end

-- ===========================================================================
-- Tab 3: Heroes (Babylon DLC)
-- ===========================================================================

local function GetHeroData(pGameHeroes, kHeroDef)
    local localPlayerID = Game.GetLocalPlayer()
    local claimedByPlayer = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index)

    local data = {
        heroDef         = kHeroDef,
        claimedByPlayer = claimedByPlayer,
        isAlive         = false,
        heroUnit        = nil,
        heroCity        = nil,
        recallInfo      = nil,
    }

    if claimedByPlayer ~= -1 then
        local pPlayer = Players[claimedByPlayer]
        if pPlayer then
            local pPlayerUnits = pPlayer:GetUnits()
            for _, pUnit in pPlayerUnits:Members() do
                if GameInfo.Units[pUnit:GetType()].UnitType == kHeroDef.UnitType then
                    data.isAlive = true
                    data.heroUnit = pUnit
                end
            end
        end
        if claimedByPlayer == localPlayerID and not data.heroUnit then
            local kCityID = pGameHeroes:GetHeroOriginCityID(kHeroDef.Index)
            local pPlayerCities = Players[claimedByPlayer]:GetCities()
            data.heroCity = pPlayerCities:FindID(kCityID.id)

            if not data.isAlive and data.heroCity then
                local kHeroUnitDef = GameInfo.Units[kHeroDef.UnitType]
                local kYieldDef = GameInfo.Yields["YIELD_FAITH"]
                local tParameters = {}
                tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = kHeroUnitDef.Hash
                tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = kYieldDef.Index
                if CityManager.CanStartCommand(data.heroCity, CityCommandTypes.PURCHASE, true, tParameters, false) then
                    local isCanStart, results = CityManager.CanStartCommand(data.heroCity, CityCommandTypes.PURCHASE,
                        false, tParameters, true)
                    local pCityGold = data.heroCity:GetGold()
                    local faithCost = pCityGold:GetPurchaseCost(kYieldDef.Index, kHeroUnitDef.Hash,
                        MilitaryFormationTypes.STANDARD_MILITARY_FORMATION)
                    local sToolTip = Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_FAITH_RECALL_TT", faithCost)
                    if not isCanStart and results and results[CityCommandResults.FAILURE_REASONS] then
                        for _, v in ipairs(results[CityCommandResults.FAILURE_REASONS]) do
                            sToolTip = sToolTip .. ", " .. Locale.Lookup(v)
                        end
                        local pPlayerReligion = Players[data.heroCity:GetOwner()]:GetReligion()
                        if pPlayerReligion and not pPlayerReligion:CanAfford(data.heroCity:GetID(), kHeroUnitDef.Hash) then
                            sToolTip = sToolTip .. ", " .. Locale.Lookup("LOC_GREAT_PEOPLE_HEROES_INSUFFICIENT_FAITH_TT")
                        end
                    end
                    data.recallInfo = {
                        faithCost = faithCost,
                        canRecall = isCanStart,
                        tooltip   = sToolTip,
                        heroClass = kHeroDef.Index,
                    }
                end
            end
        end
    end

    return data
end

local function RequestHeroRecall(heroClass)
    local kHeroDef = GameInfo.HeroClasses[heroClass]
    if not kHeroDef then
        LogWarn("Great People cannot recall missing hero class " .. tostring(heroClass))
        return false
    end

    local kHeroUnitDef = GameInfo.Units[kHeroDef.UnitType]
    local pGameHeroes = Game.GetHeroesManager()
    local claimedByPlayer = pGameHeroes:GetHeroClaimPlayer(kHeroDef.Index)
    local pPlayer = Players[claimedByPlayer]
    local kCityID = pGameHeroes:GetHeroOriginCityID(kHeroDef.Index)
    local pHeroCity = pPlayer and kCityID and pPlayer:GetCities():FindID(kCityID.id) or nil
    if not kHeroUnitDef or not pHeroCity then
        LogWarn("Great People cannot resolve the origin city for hero class " .. tostring(heroClass))
        return false
    end

    LuaEvents.GreatPeopleHeroPanel_Close()
    UI.LookAtPlotScreenPosition(pHeroCity:GetX(), pHeroCity:GetY(), 0.5, 0.5)

    local tParameters = {}
    tParameters[CityCommandTypes.PARAM_UNIT_TYPE] = kHeroUnitDef.Hash
    tParameters[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] =
        MilitaryFormationTypes.STANDARD_MILITARY_FORMATION
    tParameters[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields["YIELD_FAITH"].Index
    UI.PlaySound("Purchase_With_Faith")
    CityManager.RequestCommand(pHeroCity, CityCommandTypes.PURCHASE, tParameters)
    return true
end

local function GetHeroClaimantName(claimedByPlayer)
    local localPlayerID = Game.GetLocalPlayer()
    if claimedByPlayer == localPlayerID then
        return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_YOU")
    end
    local localPlayer = Players[localPlayerID]
    if Game.GetLocalObserver() == PlayerTypes.OBSERVER
        or (localPlayer and localPlayer:GetDiplomacy()
            and localPlayer:GetDiplomacy():HasMet(claimedByPlayer)) then
        local config = PlayerConfigurations[claimedByPlayer]
        return config and Locale.Lookup(config:GetPlayerName())
            or Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
    end
    return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITED_BY_UNKNOWN")
end

local function GetHeroName(hero)
    return Locale.ToUpper(hero.heroDef.Name)
end

local function GetHeroStatus(hero)
    if hero.claimedByPlayer == -1 then
        return Locale.Lookup("LOC_CAI_GP_HERO_STATUS_DISCOVERED")
    end
    local civName = GetHeroClaimantName(hero.claimedByPlayer)
    if hero.isAlive then
        return Locale.Lookup("LOC_CAI_GP_HERO_STATUS_RECRUITED", civName)
    end
    return Locale.Lookup("LOC_CAI_GP_HERO_STATUS_DECEASED", civName)
end

-- Keep hero states in useful, visible bands instead of sorting the complete
-- localized status string, where an embedded civilization name would decide
-- the order. Ownership is already exposed by the status as "you", a known
-- civilization, or the unknown-player fallback, so none of these bands hide
-- information from the player.
local function GetHeroStatusSortRank(hero)
    if hero.claimedByPlayer == -1 then
        return 1
    end
    if hero.claimedByPlayer == Game.GetLocalPlayer() then
        return hero.isAlive and 2 or 3
    end
    return hero.isAlive and 4 or 5
end

local function FormatHeroLabel(hero)
    local heroName = GetHeroName(hero)
    if hero.claimedByPlayer == -1 then
        return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_DISCOVERED", heroName)
    end
    local civName = GetHeroClaimantName(hero.claimedByPlayer)
    if hero.isAlive then
        return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_RECRUITED", heroName, civName)
    end
    return Locale.Lookup("LOC_CAI_GP_HERO_LABEL_DECEASED", heroName, civName)
end

local function FormatHeroEffects(entries)
    local parts = {}
    for _, entry in ipairs(entries) do
        local text = Locale.Lookup(entry.Name)
        if entry.Description and entry.Description ~= "" then
            text = text .. ": " .. Locale.Lookup(entry.Description)
        end
        parts[#parts + 1] = text
    end
    return JoinNonEmpty(parts, ", ")
end

local function FormatHeroTooltip(hero)
    local parts = {}
    local kStats = hero.stats
    local statParts = {}
    if kStats.Lifespan then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_LIFESPAN") .. ": " .. tostring(kStats.Lifespan)
    end
    if kStats.BaseMoves and kStats.BaseMoves > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_MOVEMENT") .. ": " .. tostring(kStats.BaseMoves)
    end
    if kStats.Combat and kStats.Combat > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH") .. ": " .. tostring(kStats.Combat)
    end
    if kStats.RangedCombat and kStats.RangedCombat > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH") ..
            ": " .. tostring(kStats.RangedCombat)
    end
    if kStats.Range and kStats.Range > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_ATTACK_RANGE") .. ": " .. tostring(kStats.Range)
    end
    if kStats.Charges and kStats.Charges > 0 then
        statParts[#statParts + 1] = Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") .. ": " .. tostring(kStats.Charges)
    end
    if #statParts > 0 then
        parts[#parts + 1] = JoinNonEmpty(statParts, "[NEWLINE]")
    end

    if #hero.abilities > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GP_HEROES_PASSIVES"))
        parts[#parts + 1] = FormatHeroEffects(hero.abilities)
    end

    if #hero.commands > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_GP_HEROES_COMMANDS"))
        parts[#parts + 1] = FormatHeroEffects(hero.commands)
    end

    return JoinNonEmpty(parts, "[NEWLINE]")
end

local function BuildHeroRecords()
    local pGameHeroes = Game.GetHeroesManager()
    if not pGameHeroes then return {} end
    local localPlayerID = Game.GetLocalPlayer()
    local records = {}
    for row in GameInfo.HeroClasses() do
        if pGameHeroes:IsHeroDiscovered(localPlayerID, row.Index) then
            local hero = GetHeroData(pGameHeroes, row)
            hero.stats = GetHeroUnitStats(row.Index)
            hero.abilities = GetHeroClassUnitAbilities(row.Index)
            hero.commands = GetHeroClassUnitCommands(row.Index)
            records[#records + 1] = hero
        end
    end
    return records
end

local function GetHeroStat(hero, key)
    return hero.stats and hero.stats[key] or nil
end

local function FormatHeroStat(hero, key)
    local value = GetHeroStat(hero, key)
    return value ~= nil and tostring(value) or ""
end

local function BuildHeroColumns()
    local function StatColumn(key, headerTag)
        return {
            key = string.lower(key),
            header = function() return Locale.Lookup(headerTag) end,
            getCell = function(hero) return FormatHeroStat(hero, key) end,
            sortKey = function(hero) return GetHeroStat(hero, key) end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        }
    end

    return {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_NAME") end,
            getCell = GetHeroName,
            sortKey = GetHeroName,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "status",
            header = function() return Locale.Lookup("LOC_CAI_GP_HEROES_STATUS") end,
            getCell = GetHeroStatus,
            sortKey = GetHeroStatusSortRank,
            sortAscendingDescription = "LOC_CAI_SORT_DISCOVERED_HEROES_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_OTHER_DECEASED_HEROES_FIRST",
        },
        StatColumn("Lifespan", "LOC_HUD_UNIT_PANEL_LIFESPAN"),
        StatColumn("BaseMoves", "LOC_HUD_UNIT_PANEL_MOVEMENT"),
        StatColumn("Combat", "LOC_HUD_UNIT_PANEL_STRENGTH"),
        StatColumn("RangedCombat", "LOC_HUD_UNIT_PANEL_RANGED_STRENGTH"),
        StatColumn("Range", "LOC_HUD_UNIT_PANEL_ATTACK_RANGE"),
        {
            key = "charges",
            header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") end,
            getCell = function(hero) return FormatHeroStat(hero, "Charges") end,
            sortKey = function(hero) return GetHeroStat(hero, "Charges") end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
        {
            key = "passive_abilities",
            header = function() return Locale.Lookup("LOC_CAI_GP_HEROES_PASSIVES") end,
            getCell = function(hero) return FormatHeroEffects(hero.abilities) end,
            sortKey = function(hero) return #hero.abilities end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
        {
            key = "commands",
            header = function() return Locale.Lookup("LOC_CAI_GP_HEROES_COMMANDS") end,
            getCell = function(hero) return FormatHeroEffects(hero.commands) end,
            sortKey = function(hero) return #hero.commands end,
            sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
        },
    }
end

local function GetHeroColumn(columnKey)
    for _, column in ipairs(m_heroColumns) do
        if column.key == columnKey then return column end
    end
    return nil
end

local function GetOrderedHeroRecords()
    local ordered = {}
    for _, hero in ipairs(m_heroRecords) do ordered[#ordered + 1] = hero end
    local column = GetHeroColumn(m_heroSortColumn)
    if not column or not column.sortKey then return ordered end

    local decorated = {}
    for naturalIndex, hero in ipairs(ordered) do
        decorated[#decorated + 1] = {
            hero = hero,
            naturalIndex = naturalIndex,
            value = column.sortKey(hero),
        }
    end
    table.sort(decorated, function(a, b)
        if a.value == nil or b.value == nil then
            if a.value == b.value then return a.naturalIndex < b.naturalIndex end
            return a.value ~= nil
        end
        local comparison
        if type(a.value) == "number" and type(b.value) == "number" then
            comparison = a.value == b.value and 0 or (a.value < b.value and -1 or 1)
        else
            comparison = Locale.Compare(tostring(a.value), tostring(b.value))
        end
        if comparison == 0 then return a.naturalIndex < b.naturalIndex end
        if m_heroSortAscending then return comparison < 0 end
        return comparison > 0
    end)

    ordered = {}
    for _, entry in ipairs(decorated) do ordered[#ordered + 1] = entry.hero end
    return ordered
end

local function BuildHeroSortOptions()
    local options = {
        { label = Locale.Lookup("LOC_CAI_DATATABLE_SORT_NATURAL"), value = { column = nil, ascending = false } },
    }
    for _, column in ipairs(m_heroColumns) do
        local header = type(column.header) == "function" and column.header() or column.header
        options[#options + 1] = {
            label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
            value = { column = column.key, ascending = true },
        }
        options[#options + 1] = {
            label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
            value = { column = column.key, ascending = false },
        }
    end
    return options
end

local function SyncHeroSortDropdown()
    if not m_ui.heroSort then return end
    for index, option in ipairs(m_heroSortOptions) do
        local sort = option.value
        if sort.column == m_heroSortColumn
            and (sort.column == nil or sort.ascending == m_heroSortAscending) then
            m_ui.heroSort:SetSelectedIndex(index, true)
            return
        end
    end
end

local function GetFocusedHero()
    return m_focusedHero
end

local function ActivateHero(hero)
    if not hero or hero.claimedByPlayer ~= Game.GetLocalPlayer() then return true end
    if hero.heroUnit then
        LuaEvents.GreatPeopleHeroPanel_Close()
        UI.LookAtPlotScreenPosition(hero.heroUnit:GetX(), hero.heroUnit:GetY(), 0.5, 0.5)
        UI.SelectUnit(hero.heroUnit)
    elseif hero.heroCity then
        LuaEvents.GreatPeopleHeroPanel_Close()
        UI.LookAtPlotScreenPosition(hero.heroCity:GetX(), hero.heroCity:GetY(), 0.5, 0.5)
        UI.SelectCity(hero.heroCity)
    end
    return true
end

local function OpenHeroCivilopedia(hero)
    if not hero then return false end
    LuaEvents.GreatPeopleHeroPanel_Close()
    LuaEvents.OpenCivilopedia(hero.heroDef.UnitType)
    return true
end

local function BuildHeroesList()
    if not mgr or not m_ui.heroList then return end
    local capture = mgr:CaptureFocusKey(m_ui.heroList)
    m_ui.heroList:ClearChildren()
    for _, hero in ipairs(GetOrderedHeroRecords()) do
        local capturedHero = hero
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIGP_Hero"), "MenuItem", {
            Label = function() return FormatHeroLabel(capturedHero) end,
            Tooltip = function() return FormatHeroTooltip(capturedHero) end,
            FocusKey = "hero:" .. tostring(capturedHero.heroDef.Index),
        })
        item:SetFocusSound(HOVER_SOUND)
        item:On("focus_enter", function()
            m_focusedHero = capturedHero
            m_focusedHeroClass = capturedHero.heroDef.Index
        end)
        item:On("activate", function() return ActivateHero(capturedHero) end)
        if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_CIVPEDIA") then
            item:AddInputBindings({
                {
                    Key = Keys.VK_RETURN,
                    MSG = KeyEvents.KeyUp,
                    IsShift = true,
                    Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                    Action = function() return OpenHeroCivilopedia(capturedHero) end,
                },
            })
        end
        m_ui.heroList:AddChild(item)
    end
    mgr:RestoreFocus(m_ui.heroList, capture)
end

local function RebuildHeroViews()
    if not m_ui.heroTable or not m_ui.heroList then return end
    m_heroRecords = BuildHeroRecords()
    m_focusedHero = nil
    if m_focusedHeroClass ~= nil then
        for _, hero in ipairs(m_heroRecords) do
            if hero.heroDef.Index == m_focusedHeroClass then
                m_focusedHero = hero
                break
            end
        end
    end
    if not m_focusedHero then m_focusedHeroClass = nil end
    m_ui.heroTable:Rebuild()
    BuildHeroesList()
end

local function GetHeroTableFocusKey(heroClass)
    return HEROES_TABLE_ID .. ":row:" .. tostring(heroClass) .. ":name"
end

local function GetActiveHeroView()
    return m_heroViewMode == "list" and m_ui.heroList or m_ui.heroTable
end

local function SetHeroViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "list" then
        LogError("Great People Heroes received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_heroViewMode ~= viewMode then
        m_heroViewMode = viewMode
        SaveHeroViewModeSetting(viewMode)
    end
    local activeView = GetActiveHeroView()
    if not activeView then return false end
    if m_focusedHeroClass ~= nil then
        mgr:PrepareFocus(activeView, viewMode == "list"
            and "hero:" .. tostring(m_focusedHeroClass)
            or GetHeroTableFocusKey(m_focusedHeroClass))
    end
    mgr:SetFocus(activeView)
    return true
end

local function GetFocusedHeroTableRecord()
    return m_ui.heroTable and m_ui.heroTable:GetFocusedRow() or nil
end

-- ===========================================================================
-- Panel builder
-- ===========================================================================

local function GetFocusedPerson()
    return m_cachedPersons[m_focusedPersonID]
end

local function GetActiveGPView()
    return m_viewMode == "tree" and m_ui.gpTree or m_ui.gpTable
end

local function SetGPViewMode(viewMode)
    if viewMode ~= "table" and viewMode ~= "tree" then
        LogError("Great People received invalid view mode " .. tostring(viewMode))
        return false
    end
    if m_viewMode ~= viewMode then
        m_viewMode = viewMode
        SaveViewModeSetting(viewMode)
    end

    local activeView = GetActiveGPView()
    if not activeView then return false end
    if viewMode == "table" then
        m_ui.gpTable:Rebuild()
        local playerID = m_focusedProgressPlayerID or Game.GetLocalPlayer()
        local classID = m_focusedClassID or m_FocusRecruitableClassID
        local focusKey = GetGPTableFocusKey(playerID, classID)
        if focusKey then mgr:PrepareFocus(activeView, focusKey) end
    else
        BuildGPTree()
        if m_focusedPersonID then
            mgr:PrepareFocus(activeView, "gp:" .. tostring(m_focusedPersonID))
        end
    end
    mgr:SetFocus(activeView)
    return true
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

    m_ui.gpTable = mgr:CreateWidget(GP_TABLE_ID, "DataTable", {
        Label = function() return Locale.Lookup("LOC_CAI_GP_PROGRESS_TABLE") end,
        HiddenPredicate = function() return m_viewMode ~= "table" end,
    })
    m_ui.gpTable:SetColumns({
        {
            key = "civilization",
            header = function() return Locale.Lookup("LOC_CAI_GP_CIVILIZATION_NAME") end,
            getCell = function() return "" end,
        },
    })
    m_ui.gpTable:SetRowsProvider(function() return m_progressPlayerIDs end)
    m_ui.gpTable:SetRowKeyGetter(function(playerID) return playerID end)
    m_ui.gpTable:SetRowLabelGetter(GetProgressPlayerLabel)
    m_ui.gpTable:SetDefaultSort(nil)
    m_ui.gpTable:On("cell_focus_enter", function(_, playerID, column)
        if playerID ~= nil then m_focusedProgressPlayerID = playerID end
        if column and column.GreatPersonClassID then
            m_focusedClassID = column.GreatPersonClassID
            m_focusedPersonID = column.GreatPersonID
            UpdateBiographyAndButtons()
        end
    end)
    m_ui.gpTable:On("sort_changed", function(_, columnKey, ascending)
        m_gpSortColumn = columnKey
        m_gpSortAscending = ascending == true
        SyncGPSortDropdown()
    end)
    m_ui.gpTable:AddInputBindings({
        {
            Key = Keys.VK_RETURN,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_ACTIVATE",
            Action = ActivateFocusedTablePerson,
        },
        {
            Key = Keys.VK_SPACE,
            Description = "LOC_CAI_KB_ACTIVATE",
            Action = ActivateFocusedTablePerson,
        },
        {
            Key = Keys.VK_DELETE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_GREAT_PEOPLE_PASS",
            Action = PassFocusedTablePerson,
        },
    })
    m_ui.gpPage:AddChild(m_ui.gpTable)

    m_ui.gpTree = mgr:CreateWidget(GP_TREE_ID, "Tree", {
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.gpPage:AddChild(m_ui.gpTree)

    m_ui.gpSort = mgr:CreateWidget(GP_SORT_ID, "Dropdown", {
        Label = function() return Locale.Lookup("LOC_REPORTS_ORDER_CIVS_BY") end,
        FocusKey = "great-people:sort",
        HiddenPredicate = function() return m_viewMode ~= "tree" end,
    })
    m_ui.gpSort:SetOptions(m_gpSortOptions)
    SyncGPSortDropdown()
    m_ui.gpSort:On("value_changed", function(_, sort)
        m_gpSortColumn = sort.column
        m_gpSortAscending = sort.ascending == true
        m_ui.gpTable:SetDefaultSort(sort.column
            and { column = sort.column, ascending = sort.ascending }
            or nil)
        BuildGPTree()
    end)
    m_ui.gpPage:AddChild(m_ui.gpSort)

    m_ui.gpPage:AddInputBindings({
        {
            Key = Keys["1"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetGPViewMode("table") end,
        },
        {
            Key = Keys["2"],
            IsAlt = true,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetGPViewMode("tree") end,
        },
    })

    m_ui.bioEdit = mgr:CreateWidget(GP_BIO_ID, "EditBox", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_BIOGRAPHY") end,
    })
    m_ui.bioEdit:SetReadOnly(true)
    m_ui.bioEdit:SetAlwaysEdit(true)
    m_ui.bioEdit:SetFocusSound(HOVER_SOUND)

    -- Action buttons — call vanilla global callbacks directly with individualID
    m_ui.recruitBtn = mgr:CreateWidget(GP_RECRUIT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RecruitCost then
                return Locale.Lookup("LOC_CAI_GP_RECRUIT_LABEL", p.RecruitCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT")
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUIT_DETAILS", (GetFocusedPerson() or {}).RecruitCost or 0)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT") and p.CanRecruit and p.RecruitCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.recruitBtn:SetFocusSound(HOVER_SOUND)
    m_ui.recruitBtn:On("activate", function()
        if m_focusedPersonID then OnRecruitButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.recruitBtn)

    m_ui.rejectBtn = mgr:CreateWidget(GP_REJECT_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.RejectCost then
                return Locale.Lookup("LOC_CAI_GP_REJECT_LABEL", p.RejectCost)
            end
            return Locale.Lookup("LOC_GREAT_PEOPLE_PASS")
        end,
        Tooltip = function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_PASS_DETAILS", (GetFocusedPerson() or {}).RejectCost or 0)
        end,
        HiddenPredicate = function()
            local p = GetFocusedPerson()
            if not p then return true end
            return not (HasCapability("CAPABILITY_GREAT_PEOPLE_CAN_REJECT") and p.CanReject and p.RejectCost)
        end,
        DisabledPredicate = function() return IsReadOnly() end,
    })
    m_ui.rejectBtn:SetFocusSound(HOVER_SOUND)
    m_ui.rejectBtn:On("activate", function()
        if m_focusedPersonID then OnRejectButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.rejectBtn)

    m_ui.goldBtn = mgr:CreateWidget(GP_GOLD_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithGoldCost then
                return Locale.Lookup("LOC_CAI_GP_PATRONIZE_GOLD_LABEL", p.PatronizeWithGoldCost)
            end
            return ""
        end,
        Tooltip = function()
            local p = GetFocusedPerson()
            if not p then return "" end
            return GetPatronizeWithGoldTT(p)
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
    m_ui.goldBtn:SetFocusSound(HOVER_SOUND)
    m_ui.goldBtn:On("activate", function()
        if m_focusedPersonID then OnGoldButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.goldBtn)

    m_ui.faithBtn = mgr:CreateWidget(GP_FAITH_BTN_ID, "Button", {
        Label = function()
            local p = GetFocusedPerson()
            if p and p.PatronizeWithFaithCost then
                return Locale.Lookup("LOC_CAI_GP_PATRONIZE_FAITH_LABEL", p.PatronizeWithFaithCost)
            end
            return ""
        end,
        Tooltip = function()
            local p = GetFocusedPerson()
            if not p then return "" end
            return GetPatronizeWithFaithTT(p)
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
    m_ui.faithBtn:SetFocusSound(HOVER_SOUND)
    m_ui.faithBtn:On("activate", function()
        if m_focusedPersonID then OnFaithButtonClick(m_focusedPersonID) end
    end)
    m_ui.gpPage:AddChild(m_ui.faithBtn)

    -- Keep biography after all contextual actions in the tab order.
    m_ui.gpPage:AddChild(m_ui.bioEdit)

    m_ui.switchView = mgr:CreateWidget(GP_SWITCH_VIEW_ID, "Button", {
        Label = function()
            return Locale.Lookup(m_viewMode == "table"
                and "LOC_CAI_TREE_SWITCH_TO_TREE"
                or "LOC_CAI_TREE_SWITCH_TO_TABLE")
        end,
    })
    m_ui.switchView:On("activate", function()
        return SetGPViewMode(m_viewMode == "table" and "tree" or "table")
    end)
    m_ui.gpPage:AddChild(m_ui.switchView)

    -- Tab 2: Previously Recruited
    m_ui.pastPage = m_ui.tabs:AddPage(function()
        return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_PREVIOUSLY_RECRUITED")
    end)

    m_ui.pastList = mgr:CreateWidget(PAST_LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_GREAT_PEOPLE_RECRUITMENT_HISTORY") end,
    })
    m_ui.pastPage:AddChild(m_ui.pastList)

    -- Tab 3: Heroes (Babylon DLC)
    if m_hasBabylon then
        m_ui.heroPage = m_ui.tabs:AddPage(function()
            return Locale.Lookup("LOC_GREAT_PEOPLE_TAB_HEROES")
        end)

        m_heroColumns = BuildHeroColumns()
        m_heroSortOptions = BuildHeroSortOptions()

        m_ui.heroTable = mgr:CreateWidget(HEROES_TABLE_ID, "DataTable", {
            Label = function() return Locale.Lookup("LOC_CAI_GP_HEROES_LIST") end,
            HiddenPredicate = function() return m_heroViewMode ~= "table" end,
        })
        m_ui.heroTable:SetColumns(m_heroColumns)
        m_ui.heroTable:SetRowsProvider(function() return m_heroRecords end)
        m_ui.heroTable:SetRowKeyGetter(function(hero) return hero.heroDef.Index end)
        m_ui.heroTable:SetRowLabelGetter(GetHeroName)
        m_ui.heroTable:SetDefaultSort({ column = m_heroSortColumn, ascending = m_heroSortAscending })
        m_ui.heroTable:On("row_focus_enter", function(_, hero, rowIndex)
            if rowIndex > 0 then
                m_focusedHero = hero
                m_focusedHeroClass = hero.heroDef.Index
            end
        end)
        m_ui.heroTable:On("row_activate", function(_, hero) return ActivateHero(hero) end)
        m_ui.heroTable:On("sort_changed", function(_, columnKey, ascending)
            m_heroSortColumn = columnKey
            m_heroSortAscending = ascending == true
            SyncHeroSortDropdown()
            BuildHeroesList()
        end)
        if GameCapabilities.HasCapability("CAPABILITY_DISPLAY_TOP_PANEL_CIVPEDIA") then
            m_ui.heroTable:AddInputBinding({
                Key = Keys.VK_RETURN,
                MSG = KeyEvents.KeyUp,
                IsShift = true,
                Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                Action = function() return OpenHeroCivilopedia(GetFocusedHeroTableRecord()) end,
            })
        end
        m_ui.heroPage:AddChild(m_ui.heroTable)

        m_ui.heroList = mgr:CreateWidget(HEROES_LIST_ID, "List", {
            Label = function() return Locale.Lookup("LOC_CAI_GP_HEROES_LIST") end,
            HiddenPredicate = function() return m_heroViewMode ~= "list" end,
        })
        m_ui.heroPage:AddChild(m_ui.heroList)

        m_ui.heroSort = mgr:CreateWidget(HEROES_SORT_ID, "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_GP_HEROES_SORT") end,
            FocusKey = "heroes:sort",
            HiddenPredicate = function() return m_heroViewMode ~= "list" end,
        })
        m_ui.heroSort:SetOptions(m_heroSortOptions)
        SyncHeroSortDropdown()
        m_ui.heroSort:On("value_changed", function(_, sort)
            m_heroSortColumn = sort.column
            m_heroSortAscending = sort.ascending == true
            m_ui.heroTable:SetDefaultSort(sort.column
                and { column = sort.column, ascending = sort.ascending }
                or nil)
            m_ui.heroTable:Rebuild()
            BuildHeroesList()
        end)
        m_ui.heroPage:AddChild(m_ui.heroSort)

        m_ui.heroRecallBtn = mgr:CreateWidget(HERO_RECALL_BTN_ID, "Button", {
            Label = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return "" end
                return Locale.Lookup("LOC_CAI_GP_RECALL_WITH_FAITH_LABEL", h.recallInfo.faithCost)
            end,
            Tooltip = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return "" end
                return h.recallInfo.tooltip
            end,
            HiddenPredicate = function()
                local h = GetFocusedHero()
                if not h then return true end
                if h.claimedByPlayer ~= Game.GetLocalPlayer() then return true end
                return h.isAlive or not h.recallInfo
            end,
            DisabledPredicate = function()
                local h = GetFocusedHero()
                if not h or not h.recallInfo then return true end
                return not h.recallInfo.canRecall
            end,
        })
        m_ui.heroRecallBtn:SetFocusSound(HOVER_SOUND)
        m_ui.heroRecallBtn:On("activate", function()
            local h = GetFocusedHero()
            if not h or not h.recallInfo then return false end
            return RequestHeroRecall(h.recallInfo.heroClass)
        end)
        m_ui.heroPage:AddChild(m_ui.heroRecallBtn)

        m_ui.heroSwitch = mgr:CreateWidget(HEROES_SWITCH_ID, "Button", {
            Label = function()
                return Locale.Lookup(m_heroViewMode == "table"
                    and "LOC_CAI_REPORTS_SWITCH_TO_LIST"
                    or "LOC_CAI_REPORTS_SWITCH_TO_TABLE")
            end,
        })
        m_ui.heroSwitch:On("activate", function()
            return SetHeroViewMode(m_heroViewMode == "table" and "list" or "table")
        end)
        m_ui.heroPage:AddChild(m_ui.heroSwitch)

        m_ui.heroPage:AddInputBindings({
            {
                Key = Keys["1"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_TABLE",
                Action = function() return SetHeroViewMode("table") end,
            },
            {
                Key = Keys["2"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_LIST",
                Action = function() return SetHeroViewMode("list") end,
            },
        })
    end

    m_ui.tabs:On("value_changed", function(_, idx)
        if m_isMirroringTab then return end
        local btn = m_vanillaTabButtons[idx]
        if btn then
            m_isMirroringTab = true
            btn:DoLeftClick()
            m_isMirroringTab = false
        end
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
        local focus = m_FocusHero
        if focus then
            local heroClass = string.match(tostring(focus), "^hero:(.+)$")
            if heroClass then
                focus = m_heroViewMode == "list"
                    and "hero:" .. heroClass
                    or GetHeroTableFocusKey(heroClass)
            end
        end
        if not focus then
            if m_viewMode == "table" then
                focus = GetGPTableFocusKey(
                    m_focusedProgressPlayerID or Game.GetLocalPlayer(),
                    m_focusedClassID or m_FocusRecruitableClassID)
            else
                focus = m_FocusRecruitable
            end
        end
        mgr:Push(m_ui.panel, { priority = PopupPriority.Low, focus = focus })
    end
end

local function PopPanel()
    if mgr and m_ui.panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui = {
        panel = nil,
        tabs = nil,
        gpPage = nil,
        gpTable = nil,
        gpTree = nil,
        gpSort = nil,
        bioEdit = nil,
        recruitBtn = nil,
        rejectBtn = nil,
        goldBtn = nil,
        faithBtn = nil,
        switchView = nil,
        pastPage = nil,
        pastList = nil,
        heroPage = nil,
        heroTable = nil,
        heroList = nil,
        heroSort = nil,
        heroSwitch = nil,
        heroRecallBtn = nil,
    }
    m_cachedPersons = {}
    m_cachedData = nil
    m_cachedProgress = {}
    m_progressPlayerIDs = {}
    m_focusedPersonID = nil
    m_focusedClassID = nil
    m_focusedProgressPlayerID = nil
    m_focusedHero = nil
    m_focusedHeroClass = nil
    m_heroRecords = {}
    m_heroColumns = {}
    m_heroSortOptions = {}
    m_FocusRecruitable = nil
    m_FocusRecruitableClassID = nil
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

local function SyncCAITab(idx)
    if m_ui.tabs and not m_isMirroringTab then
        m_isMirroringTab = true
        m_ui.tabs:SetActivePage(idx, true)
        m_isMirroringTab = false
    end
end

ViewCurrent = WrapFunc(ViewCurrent, function(orig, data)
    m_cachedPersons = {}
    m_cachedData = nil
    orig(data)
    m_cachedData = data
    BuildGPTable()
    BuildGPTree()
    SyncCAITab(1)
end)

ViewPast = WrapFunc(ViewPast, function(orig, data)
    orig(data)
    BuildPastList(data)
    SyncCAITab(2)
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

AddTabInstance = WrapFunc(AddTabInstance, function(orig, buttonText, callbackFunc)
    local kInstance = orig(buttonText, callbackFunc)
    m_vanillaTabCount = m_vanillaTabCount + 1
    m_vanillaTabButtons[m_vanillaTabCount] = kInstance.Button
    return kInstance
end)

-- Babylon-specific wraps are deferred to LateInitialize because the Babylon
-- override files may load after this CAI file in the wildcard batch; by the time
-- LateInitialize runs (called from Initialize()), all wildcard files have loaded.
local BASE_CAI_LateInitialize = LateInitialize
function LateInitialize()
    if BASE_CAI_LateInitialize then BASE_CAI_LateInitialize() end

    m_hasBabylon = (OnHeroesClick ~= nil) and (Game.GetHeroesManager ~= nil)

    if m_hasBabylon then
        include("HeroesSupport")

        RefreshHeroesPanel = WrapFunc(RefreshHeroesPanel, function(orig)
            orig()
            RebuildHeroViews()
            SyncCAITab(3)
        end)
    end
end

function OnCAI_UpdateHeroPanelOpenFocus(key)
    if key then m_FocusHero = key end
end

LuaEvents.CAI_UpdateHeroPanelOpenFocus.Add(OnCAI_UpdateHeroPanelOpenFocus)

function OnCAI_ClearHeroPanelOpenFocus()
    m_FocusHero = nil
end

LuaEvents.CAI_ClearHeroPanelOpenFocus.Add(OnCAI_ClearHeroPanelOpenFocus)

-- Vanilla Initialize() calls ContextPtr:SetInputHandler(OnInputHandler, true) after
-- all wildcard includes, so reassigning the global here is enough.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel then
            if mgr:HandleInput(input) then return true end
        end
    end
    if IsCAIEscapeKeyUp(input) and not IsCAITutorialScreenCloseAllowed() then
        AnnounceCAITutorialScreenCloseBlocked()
        return true
    end
    return orig(input)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
    LuaEvents.CAI_ClearHeroPanelOpenFocus.Remove(OnCAI_ClearHeroPanelOpenFocus)
    LuaEvents.CAI_UpdateHeroPanelOpenFocus.Remove(OnCAI_UpdateHeroPanelOpenFocus)
end)
