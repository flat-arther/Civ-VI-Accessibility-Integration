include("hexCoordUtils_CAI")
include("WorldScannerCategoryUtils")
include("WorldScannerCore")
include("PlayerStateManager_CAI")

---@class WorldScannerContext
---@field LocalPlayerID integer
---@field ObserverID integer

---@class WorldScannerFocus
---@field CategoryId string|nil
---@field SubCategoryId string|nil
---@field GroupId string|nil
---@field ItemId string|nil
---@field HadGroupSelection boolean
---@field HadItemSelection boolean

---@class WorldScannerCategoryDefinition
---@field Id string
---@field LabelKey string
---@field SubCategoryOrder string[]
---@field SubCategoryLabels table<string, string>
---@field GroupOrderBySubCategory table<string, string[]>|nil
---@field GroupComparatorBySubCategory table<string, fun(a:WorldScannerGroup, b:WorldScannerGroup):boolean|nil>|nil
---@field GroupLabelResolver fun(groupId:string, firstItem:table|nil):string|nil
---@field CanScan fun(context:WorldScannerContext):boolean|nil
---@field BuildOncePerDynamicState boolean|nil
---@field Scan fun(context:WorldScannerContext):table[]|nil
---@field PlotExtract fun(plotIndex:integer, plot:table, context:WorldScannerContext, collect:fun(item:table), isRevealed:boolean)|nil
---@field ExtractHiddenPlots boolean|nil
---@field BeginExtract fun()|nil
---@field AutoFocus boolean|nil

---@class WorldScanner
---@field Categories table[]
---@field CategoryDefinitions WorldScannerCategoryDefinition[]
---@field CategoryIndex integer
---@field SubCategoryIndex integer
---@field GroupIndex integer
---@field ItemIndex integer
---@field PreviousJumpPlotIndex integer|nil
---@field SearchSnapshot table[]|nil
---@field SearchHistoryIndex integer

---@type WorldScanner
CAIWorldScanner = CAIWorldScanner or {}

local HexCoordUtils = CAIHexCoordUtils
local Core = CAIWorldScannerCore
local Utils = CAIWorldScannerUtils

---@type WorldScannerCategoryDefinition[]
local RegisteredCategoryDefinitions = {}

local EMPTY_CATEGORY = false
local FindCategorySlotById
local AUTO_FOCUS_SETTING_BY_CATEGORY_ID = {
    validTargets = "ScannerAutoFocusValidTargets",
    activeLens = "ScannerAutoFocusActiveLens",
}

local m_PlayerState = PlayerStateManager.Init(function(playerID)
    return {
        Categories = {},
        CategoryDefinitions = RegisteredCategoryDefinitions,

        CategoryIndex = 1,
        SubCategoryIndex = 1,
        GroupIndex = 0,
        ItemIndex = 0,
        PreviousJumpPlotIndex = nil,

        SearchSnapshot = nil,
        SearchHistoryIndex = 0,
    }
end)

local function GetScannerState()
    local state = m_PlayerState:GetActive()
    if state ~= nil then
        state.CategoryDefinitions = RegisteredCategoryDefinitions
    end

    return state
end

local function GetCursorCoords()
    if CAICursor == nil or CAICursor.GetCoords == nil then
        return nil, nil
    end

    return CAICursor:GetCoords()
end

---@param definition WorldScannerCategoryDefinition|nil
function CAIWorldScanner:RegisterCategoryDefinition(definition)
    if definition == nil then
        return
    end

    table.insert(RegisteredCategoryDefinitions, definition)
end

local function SpeakPositionedLabel(labelKey, index, total)
    Speak(Utils.ResolveText(labelKey) .. ", " .. Utils.MakePositionText(index, total))
end

local function GetCategory(scanner)
    return Core.GetCategory(scanner)
end

local function GetSubCategory(scanner)
    return Core.GetSubCategory(scanner)
end

local function GetGroup(scanner)
    return Core.GetGroup(scanner)
end

local function GetCurrentItem(scanner)
    return Core.GetCurrentItem(scanner)
end

local function BuildScannerContext()
    return {
        LocalPlayerID = Game.GetLocalPlayer(),
        ObserverID = Game.GetLocalObserver(),
    }
end

local function ShouldAutoFocusCategory(definition)
    if definition == nil or not definition.AutoFocus then
        return false
    end

    local settingId = AUTO_FOCUS_SETTING_BY_CATEGORY_ID[definition.Id]
    if settingId == nil then
        return true
    end

    return CAISettings.GetBool(settingId)
end

local function CreateCategorySlots(definitions)
    local autoFocusSlots = {}
    local normalSlots = {}

    for _, definition in ipairs(definitions or {}) do
        local slot = {
            Definition = definition,
            Category = nil,
        }

        if ShouldAutoFocusCategory(definition) then
            autoFocusSlots[#autoFocusSlots + 1] = slot
        else
            normalSlots[#normalSlots + 1] = slot
        end
    end

    local slots = {}

    for _, slot in ipairs(autoFocusSlots) do
        slots[#slots + 1] = slot
    end

    for _, slot in ipairs(normalSlots) do
        slots[#slots + 1] = slot
    end

    return slots
end

local function GetCategorySlot(scanner, index)
    return scanner and scanner.Categories and scanner.Categories[index] or nil
end

local function GetSlotCategory(slot)
    if slot == nil or slot.Category == EMPTY_CATEGORY then
        return nil
    end

    return slot.Category
end

local function BuildAllIntoSlots(scanner)
    local context = BuildScannerContext()
    local builtMap = Core.BuildAllCategories(scanner.CategoryDefinitions, context)

    for _, slot in ipairs(scanner.Categories) do
        local definition = slot.Definition
        if definition ~= nil then
            local built = builtMap[definition.Id]
            slot.Category = built or EMPTY_CATEGORY
            if built ~= nil then
                LogMessage("World scanner slot built category "
                    .. tostring(definition.Id)
                    .. ", totalItems=" .. tostring(built.TotalItems or 0))
            else
                LogMessage("World scanner slot empty category " .. tostring(definition.Id))
            end
        end
    end
end

local function CountCategorySlots(scanner)
    return scanner and scanner.Categories and #scanner.Categories or 0
end

local function IsCategoryAvailable(slot)
    if slot == nil or slot.Category == EMPTY_CATEGORY then
        return false
    end

    return slot.Category ~= nil
end

local function CountAvailableCategories(scanner)
    local count = 0

    for _, slot in ipairs(scanner and scanner.Categories or {}) do
        if IsCategoryAvailable(slot) then
            count = count + 1
        end
    end

    return count
end

local function GetAvailableCategoryPosition(scanner, targetIndex)
    local position = 0

    for index, slot in ipairs(scanner and scanner.Categories or {}) do
        if IsCategoryAvailable(slot) then
            position = position + 1
            if index == targetIndex then
                return position
            end
        end
    end

    return 0
end

local function FindAvailableCategoryIndex(scanner, startIndex, step)
    local count = CountCategorySlots(scanner)
    if count == 0 then
        return nil
    end

    for offset = 0, count - 1 do
        local index = ((startIndex - 1 + (offset * step)) % count) + 1
        local slot = GetCategorySlot(scanner, index)

        if GetSlotCategory(slot) ~= nil then
            return index
        end
    end

    return nil
end

local function EnsureCurrentCategory(scanner)
    local slot = GetCategorySlot(scanner, scanner.CategoryIndex)
    local current = GetSlotCategory(slot)

    if current ~= nil then
        return current
    end

    local availableIndex = FindAvailableCategoryIndex(scanner, scanner.CategoryIndex, 1)
    if availableIndex == nil then
        scanner.CategoryIndex = 0
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return nil
    end

    scanner.CategoryIndex = availableIndex
    scanner.SubCategoryIndex = 1
    scanner.GroupIndex = 0
    scanner.ItemIndex = 0

    return GetCategory(scanner)
end

FindCategorySlotById = function(scanner, categoryId)
    if scanner == nil or scanner.Categories == nil then
        return nil
    end

    for index, slot in ipairs(scanner.Categories) do
        if slot.Definition ~= nil and slot.Definition.Id == categoryId then
            return index
        end
    end

    return nil
end

local function GetItemDirectionText(item)
    if item == nil or item.PlotIndex == nil then
        return nil
    end

    local plot = Map.GetPlotByIndex(item.PlotIndex)
    if plot == nil then
        return nil
    end

    local cursorX, cursorY = GetCursorCoords()
    if cursorX == nil or cursorY == nil then
        return nil
    end

    local directionText = HexCoordUtils.directionString(cursorX, cursorY, plot:GetX(), plot:GetY())
    if directionText == nil or directionText == "" then
        return Locale.Lookup("LOC_CAI_HERE")
    end

    return directionText
end

local function GetItemCoordinatesText(item)
    if item == nil or item.PlotIndex == nil or HexCoordUtils == nil or HexCoordUtils.coordinateString == nil then
        return nil
    end

    local x, y = Utils.GetPlotCoords(item.PlotIndex)
    if x == nil or y == nil then
        return nil
    end

    return HexCoordUtils.coordinateString(x, y)
end

local function BuildItemEntryText(item, itemIndex, itemTotal)
    if item == nil then
        return nil
    end

    local coordsText = GetItemCoordinatesText(item)
    local coordsMode = CAISettings.GetString("ScannerCoordinates")
    local directionText = GetItemDirectionText(item)
    local parts = { Utils.ResolveText(item.LabelKey) }

    if coordsText ~= nil and coordsText ~= "" and coordsMode == "prepend" then
        table.insert(parts, 1, coordsText)
    end

    if directionText ~= nil and directionText ~= "" then
        parts[#parts + 1] = directionText
    end

    parts[#parts + 1] = Utils.MakePositionText(itemIndex, itemTotal)

    if coordsText ~= nil and coordsText ~= "" and coordsMode == "append" then
        parts[#parts + 1] = coordsText
    end

    return table.concat(parts, ", ")
end

local function SpeakItemEntry(item, itemIndex, itemTotal)
    local text = BuildItemEntryText(item, itemIndex, itemTotal)
    if text == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return false
    end

    Speak(text)
    return true
end

local function GetCurrentTargetPlotIndex(scanner)
    local item = GetCurrentItem(scanner)
    if item ~= nil and item.PlotIndex ~= nil then
        return item.PlotIndex
    end

    local group = GetGroup(scanner)
    if group ~= nil and group.PlotIndex ~= nil then
        return group.PlotIndex
    end

    return nil
end

local function FollowCurrentTarget(scanner)
    if scanner == nil or not CAISettings.GetBool("ScannerAutoMoveCursor") then
        return false
    end

    local plotIndex = GetCurrentTargetPlotIndex(scanner)
    if plotIndex == nil or plotIndex < 0 then
        return false
    end

    local currentPlotIndex = CAICursor and CAICursor.GetPlotId and CAICursor:GetPlotId() or -1
    if currentPlotIndex == plotIndex then
        return false
    end

    LuaEvents.CAICursorMoveTo(plotIndex, "snap")
    return true
end

local function FocusCurrentItem(scanner)
    local group = GetGroup(scanner)
    if group == nil or group.Items == nil or #group.Items == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return false
    end

    local spoke = SpeakItemEntry(group.Items[scanner.ItemIndex], scanner.ItemIndex, group.TotalItems or #group.Items)
    if spoke then
        FollowCurrentTarget(scanner)
    end
    return spoke
end

local function SelectFirstGroupAndItem(scanner)
    local subCategory = GetSubCategory(scanner)
    if subCategory == nil or subCategory.Groups == nil or #subCategory.Groups == 0 then
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return false
    end

    scanner.GroupIndex = 1

    local group = subCategory.Groups[1]
    if group == nil or group.Items == nil or #group.Items == 0 then
        scanner.ItemIndex = 0
        return false
    end

    scanner.ItemIndex = 1
    return true
end

local function FocusCategory(scanner, categoryIndex)
    scanner.CategoryIndex = categoryIndex
    scanner.SubCategoryIndex = 1
    scanner.GroupIndex = 0
    scanner.ItemIndex = 0

    SelectFirstGroupAndItem(scanner)

    local category = GetCategory(scanner)
    if category == nil then
        return
    end

    local count = CountAvailableCategories(scanner)
    local line1 = Utils.ResolveText(category.LabelKey)
        .. ", "
        .. Utils.MakePositionText(GetAvailableCategoryPosition(scanner, scanner.CategoryIndex), count)

    local group = GetGroup(scanner)
    local item = group ~= nil and group.Items ~= nil and group.Items[scanner.ItemIndex] or nil
    local line2 = BuildItemEntryText(item, scanner.ItemIndex, group ~= nil and (group.TotalItems or #group.Items) or 0)

    if line2 ~= nil then
        SpeakLines({ line1, line2 })
        FollowCurrentTarget(scanner)
    else
        SpeakLines({ line1 })
    end
end

local function OnScannerCursorMoved(state)
    Utils.SetCurrentCursorPosition(state.toX, state.toY)
    CAIWorldScanner:ResortCurrentCategory()
end

local _lastActiveLensId = nil

local function OnScannerLensLayerChanged(layerNum)
    local activeLens = CAIWorldScannerCategory_ActiveLens.CanScan() and "activeLens" or nil
    if activeLens == _lastActiveLensId then
        return
    end

    _lastActiveLensId = activeLens
    CAIWorldScanner:RebuildCategory("activeLens")
end

local function OnScannerUnitSelectionChanged(playerID, unitID, locationX, locationY, locationZ, isSelected, isEditable)
    if not isSelected then
        return
    end

    if playerID == Game.GetLocalPlayer() then
        if CAIInterfaceTargets ~= nil and CAIInterfaceTargets.ClearCache ~= nil then
            CAIInterfaceTargets.ClearCache()
        end

        CAIWorldScanner:RebuildCategory("validTargets")
    end
end

local function OnScannerInterfaceModeChanged(oldMode, newMode)
    if CAIInterfaceTargets ~= nil and CAIInterfaceTargets.ClearCache ~= nil then
        CAIInterfaceTargets.ClearCache()
    end

    CAIWorldScanner:RebuildCategory("validTargets")
end

local function OnScannerSettingsChanged(settingId)
    if settingId == "ScannerGroupCitiesByCivilization" then
        CAIWorldScanner:RebuildCategory("cities")
    end
end

---@param focusOverride WorldScannerFocus|nil
function CAIWorldScanner:Rebuild(focusOverride)
    local scanner = GetScannerState()
    if scanner == nil then
        LogError("World scanner Rebuild called without scanner state")
        return
    end

    local focus = focusOverride or Core.CaptureFocus(scanner)

    scanner.CategoryDefinitions = RegisteredCategoryDefinitions
    scanner.Categories = CreateCategorySlots(scanner.CategoryDefinitions)

    BuildAllIntoSlots(scanner)

    if focus ~= nil and focus.CategoryId ~= nil then
        scanner.CategoryIndex = FindCategorySlotById(scanner, focus.CategoryId) or scanner.CategoryIndex
    end

    if scanner.CategoryIndex < 1 then
        scanner.CategoryIndex = 1
    end

    EnsureCurrentCategory(scanner)
    Core.RestoreFocus(scanner, focus)
    EnsureCurrentCategory(scanner)
    Core.ClampIndexes(scanner)
    LogMessage("World scanner rebuilt, availableCategories=" .. tostring(CountAvailableCategories(scanner)))
end

function CAIWorldScanner:RebuildCategory(categoryId)
    local scanner = GetScannerState()
    if scanner == nil then
        LogError("World scanner RebuildCategory called without scanner state for category " .. tostring(categoryId))
        return
    end

    local index = FindCategorySlotById(scanner, categoryId)
    if index == nil then
        LogWarn("World scanner RebuildCategory could not find category " .. tostring(categoryId))
        return
    end

    local focus = Core.CaptureFocus(scanner)
    local slot = scanner.Categories[index]
    local definition = slot.Definition

    if definition ~= nil and definition.PlotExtract ~= nil then
        BuildAllIntoSlots(scanner)
    else
        local context = BuildScannerContext()
        slot.Category = Core.BuildCategory(definition, context) or EMPTY_CATEGORY
    end

    if definition ~= nil
        and ShouldAutoFocusCategory(definition)
        and slot.Category ~= nil
        and slot.Category ~= EMPTY_CATEGORY then
        FocusCategory(scanner, index)
    else
        Core.RestoreFocus(scanner, focus)
    end

    EnsureCurrentCategory(scanner)
    Core.ClampIndexes(scanner)
    if slot.Category ~= nil and slot.Category ~= EMPTY_CATEGORY then
        LogMessage("World scanner rebuilt category "
            .. tostring(categoryId)
            .. ", totalItems=" .. tostring(slot.Category.TotalItems or 0))
    else
        LogWarn("World scanner rebuilt category " .. tostring(categoryId) .. " as empty")
    end
end

function CAIWorldScanner:ResortCurrentCategory()
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local focus = Core.CaptureFocus(scanner)

    Core.RefreshCategorySort(GetCategory(scanner))
    Core.RestoreFocus(scanner, focus)
    Core.ClampIndexes(scanner)
end

function CAIWorldScanner:Resort()
    self:ResortCurrentCategory()
end

function CAIWorldScanner:Initialize()
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    scanner.CategoryDefinitions = RegisteredCategoryDefinitions
    scanner.Categories = CreateCategorySlots(scanner.CategoryDefinitions)
    scanner.CategoryIndex = 1
    scanner.SubCategoryIndex = 1
    scanner.GroupIndex = 0
    scanner.ItemIndex = 0
    scanner.PreviousJumpPlotIndex = nil
    scanner.SearchSnapshot = nil
    scanner.SearchHistoryIndex = 0

    local cursorX, cursorY = GetCursorCoords()
    if cursorX ~= nil and cursorY ~= nil then
        Utils.SetCurrentCursorPosition(cursorX, cursorY)
    end

    BuildAllIntoSlots(scanner)

    LuaEvents.CAICursorMoved.Add(OnScannerCursorMoved)
    Events.LensLayerOn.Add(OnScannerLensLayerChanged)
    Events.LensLayerOff.Add(OnScannerLensLayerChanged)
    Events.UnitSelectionChanged.Add(OnScannerUnitSelectionChanged)
    Events.InterfaceModeChanged.Add(OnScannerInterfaceModeChanged)
    LuaEvents.CAISettingsChanged.Add(OnScannerSettingsChanged)

    EnsureCurrentCategory(scanner)
    LogMessage("World scanner initialized")
end

function CAIWorldScanner:ClearScanner()
    LuaEvents.CAICursorMoved.Remove(OnScannerCursorMoved)
    Events.LensLayerOn.Remove(OnScannerLensLayerChanged)
    Events.LensLayerOff.Remove(OnScannerLensLayerChanged)
    Events.UnitSelectionChanged.Remove(OnScannerUnitSelectionChanged)
    Events.InterfaceModeChanged.Remove(OnScannerInterfaceModeChanged)
    LuaEvents.CAISettingsChanged.Remove(OnScannerSettingsChanged)

    local scanner = GetScannerState()
    if scanner ~= nil then
        scanner.Categories = {}
        scanner.CategoryDefinitions = {}
        scanner.CategoryIndex = 1
        scanner.SubCategoryIndex = 1
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        scanner.PreviousJumpPlotIndex = nil
        scanner.SearchSnapshot = nil
        scanner.SearchHistoryIndex = 0
    end
    LogMessage("World scanner cleared")
end

function CAIWorldScanner:OnLocalPlayerTurnBegin()
    self:Rebuild()
end

---@param step integer
function CAIWorldScanner:CycleCategory(step)
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    self:ClearSearchCategory()
    self:Rebuild()

    scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local count = CountAvailableCategories(scanner)
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local previousPosition = GetAvailableCategoryPosition(scanner, scanner.CategoryIndex)
    local targetIndex = FindAvailableCategoryIndex(scanner, scanner.CategoryIndex + step, step)
    if targetIndex == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    count = CountAvailableCategories(scanner)
    local targetPosition = GetAvailableCategoryPosition(scanner, targetIndex)
    FocusCategory(scanner, targetIndex)
    local wrapped = step > 0 and targetPosition <= previousPosition
        or step < 0 and targetPosition >= previousPosition
    if wrapped then
        ExposedMembers.CAI_UIManager:HandleNavigationWrap(self, step)
    end
end

---@param step integer
function CAIWorldScanner:CycleSubCategory(step)
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local category = GetCategory(scanner)
    if category == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local count = #category.SubCategories
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local previousIndex = scanner.SubCategoryIndex
    scanner.SubCategoryIndex = ((scanner.SubCategoryIndex - 1 + step) % count) + 1
    local wrapped = step > 0 and scanner.SubCategoryIndex <= previousIndex
        or step < 0 and scanner.SubCategoryIndex >= previousIndex
    SelectFirstGroupAndItem(scanner)

    local subCategory = GetSubCategory(scanner)
    if subCategory == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local line1 = Utils.ResolveText(subCategory.LabelKey)
        .. ", "
        .. Utils.MakePositionText(scanner.SubCategoryIndex, count)

    local group = GetGroup(scanner)
    local item = group ~= nil and group.Items ~= nil and group.Items[scanner.ItemIndex] or nil
    local line2 = BuildItemEntryText(item, scanner.ItemIndex, group ~= nil and (group.TotalItems or #group.Items) or 0)

    if line2 ~= nil then
        SpeakLines({ line1, line2 })
        FollowCurrentTarget(scanner)
    else
        SpeakLines({ line1 })
    end
    if wrapped then
        ExposedMembers.CAI_UIManager:HandleNavigationWrap(self, step)
    end
end

---@param step integer
function CAIWorldScanner:CycleGroup(step)
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local subCategory = GetSubCategory(scanner)
    if subCategory == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local count = #subCategory.Groups
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local previousIndex = scanner.GroupIndex
    if scanner.GroupIndex == 0 then
        scanner.GroupIndex = step > 0 and 1 or count
    else
        scanner.GroupIndex = ((scanner.GroupIndex - 1 + step) % count) + 1
    end

    scanner.ItemIndex = 1

    FocusCurrentItem(scanner)
    local wrapped = previousIndex ~= 0 and (step > 0 and scanner.GroupIndex <= previousIndex
        or step < 0 and scanner.GroupIndex >= previousIndex)
    if wrapped then
        ExposedMembers.CAI_UIManager:HandleNavigationWrap(self, step)
    end
end

---@param step integer
function CAIWorldScanner:CycleItem(step)
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local group = GetGroup(scanner)
    if group == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    local count = #group.Items
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    local previousIndex = scanner.ItemIndex
    if scanner.ItemIndex == 0 then
        scanner.ItemIndex = step > 0 and 1 or count
    else
        scanner.ItemIndex = ((scanner.ItemIndex - 1 + step) % count) + 1
    end

    FocusCurrentItem(scanner)
    local wrapped = previousIndex ~= 0 and (step > 0 and scanner.ItemIndex <= previousIndex
        or step < 0 and scanner.ItemIndex >= previousIndex)
    if wrapped then
        ExposedMembers.CAI_UIManager:HandleNavigationWrap(self, step)
    end
end

function CAIWorldScanner:JumpToCurrent()
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local plotIndex = GetCurrentTargetPlotIndex(scanner)

    if plotIndex == nil or plotIndex < 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    local currentPlotIndex = CAICursor and CAICursor.GetPlotId and CAICursor:GetPlotId() or -1
    if currentPlotIndex ~= nil and currentPlotIndex >= 0 then
        scanner.PreviousJumpPlotIndex = currentPlotIndex
    end

    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    LuaEvents.CAICursorMoveTo(plotIndex, "jump")
end

function CAIWorldScanner:ReturnFromJump()
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    if scanner.PreviousJumpPlotIndex == nil or scanner.PreviousJumpPlotIndex < 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_NO_PREVIOUS_JUMP"))
        return
    end

    local plot = Map.GetPlotByIndex(scanner.PreviousJumpPlotIndex)
    if plot == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_NO_PREVIOUS_JUMP"))
        scanner.PreviousJumpPlotIndex = nil
        return
    end

    LuaEvents.CAICursorMoveTo(scanner.PreviousJumpPlotIndex, "jump")
    scanner.PreviousJumpPlotIndex = nil
end

function CAIWorldScanner:SpeakCurrentDirection()
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    local item = GetCurrentItem(scanner)
    local directionText = GetItemDirectionText(item)

    if directionText == nil or directionText == "" then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    Speak(directionText)
end

-- ==========================================================================
-- Scanner Search
-- ==========================================================================

local SCANNER_SEARCH_CONTEXT = "CAI_ScannerSearch"
local SCANNER_SEARCH_HISTORY_CONTEXT = "WorldScanner"
local SCANNER_SEARCH_CATEGORY_ID = "__searchResults"
local SCANNER_SEARCH_MAX_RESULTS = 200

local SearchUtils = CAIWidgetHelpers_Search
local mgr = ExposedMembers.CAI_UIManager

local m_searchEditBox = nil

---Walk all built scanner categories and collect a flat snapshot of every leaf item.
---@return table[] Array of { key, text, categoryLabel, groupLabel, item }
local function BuildSearchSnapshot(scanner)
    local snapshot = {}

    for _, slot in ipairs(scanner.Categories or {}) do
        local category = slot.Category

        if category and category ~= false then
            local categoryLabel = Utils.ResolveText(category.LabelKey)

            for _, subCategory in ipairs(category.SubCategories or {}) do
                if subCategory.Id ~= Core.AllSubCategoryId then
                    for _, group in ipairs(subCategory.Groups or {}) do
                        local groupLabel = Utils.ResolveText(group.LabelKey)

                        for _, leaf in ipairs(group.Items or {}) do
                            local itemLabel = Utils.ResolveText(leaf.LabelKey)
                            local searchText = itemLabel .. " " .. groupLabel .. " " .. categoryLabel
                            local key = category.Id
                                .. "|"
                                .. (subCategory.Id or "")
                                .. "|"
                                .. (group.Id or "")
                                .. "|"
                                .. tostring(leaf.Id)

                            snapshot[#snapshot + 1] = {
                                key = key,
                                text = searchText,
                                label = itemLabel,
                                categoryLabel = categoryLabel,
                                groupLabel = groupLabel,
                                plotIndex = leaf.PlotIndex,
                                item = leaf,
                            }
                        end
                    end
                end
            end
        end
    end

    return snapshot
end

local function BuildSearchContext(snapshot)
    Search.DestroyContext(SCANNER_SEARCH_CONTEXT)

    if not Search.CreateContext(SCANNER_SEARCH_CONTEXT, "", "", "...") then
        return false
    end

    for _, entry in ipairs(snapshot) do
        Search.AddData(SCANNER_SEARCH_CONTEXT, entry.key, entry.text, "", {})
    end

    Search.Optimize(SCANNER_SEARCH_CONTEXT)
    return true
end

local function DestroySearchContext()
    Search.DestroyContext(SCANNER_SEARCH_CONTEXT)
end

local function BuildSnapshotLookup(snapshot)
    local lookup = {}

    for _, entry in ipairs(snapshot or {}) do
        lookup[entry.key] = entry
    end

    return lookup
end

local function CommitSearch(scanner, rawQuery)
    if not rawQuery or rawQuery == "" then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_NO_RESULTS"))
        return
    end

    local whitelist, blacklist = SearchUtils.ParseQuery(rawQuery)
    if #whitelist == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_NO_RESULTS"))
        return
    end

    SearchUtils.AddHistory(SCANNER_SEARCH_HISTORY_CONTEXT, rawQuery)

    local hits = SearchUtils.MultiTermSearch(SCANNER_SEARCH_CONTEXT, whitelist, blacklist, SCANNER_SEARCH_MAX_RESULTS)
    if #hits == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_NO_RESULTS"))
        return
    end

    local lookup = BuildSnapshotLookup(scanner.SearchSnapshot)

    local groups = {}

    for _, hit in ipairs(hits) do
        local entry = lookup[hit.key]

        if entry then
            groups[#groups + 1] = {
                Id = hit.key,
                Key = hit.key,
                LabelKey = entry.label,
                PlotIndex = entry.plotIndex,
                Items = { entry.item },
                TotalItems = 1,
            }
        end
    end

    if #groups == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_NO_RESULTS"))
        return
    end

    table.sort(groups, function(a, b)
        return Utils.GetDistance(nil, a.PlotIndex) < Utils.GetDistance(nil, b.PlotIndex)
    end)

    local searchCategory = {
        Id = SCANNER_SEARCH_CATEGORY_ID,
        LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_SEARCH_RESULTS",
        SubCategories = {
            {
                Id = "results",
                Key = "results",
                LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_SEARCH_RESULTS",
                Groups = groups,
                TotalItems = #groups,
            },
        },
        TotalItems = #groups,
    }

    CAIWorldScanner:InjectSearchCategory(searchCategory)
end

local function CloseSearchEditBox()
    if m_searchEditBox then
        if mgr then
            mgr:RemoveFromStack(m_searchEditBox.Id)
        end

        m_searchEditBox:Destroy()
        m_searchEditBox = nil
    end

    local scanner = GetScannerState()
    if scanner ~= nil then
        scanner.SearchHistoryIndex = 0
    end
end

function CAIWorldScanner:OpenSearch()
    if not mgr then
        return
    end

    if m_searchEditBox then
        return
    end

    self:Rebuild()

    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    scanner.SearchSnapshot = BuildSearchSnapshot(scanner)

    if #scanner.SearchSnapshot == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    if not BuildSearchContext(scanner.SearchSnapshot) then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    scanner.SearchHistoryIndex = 0

    local editBox = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScannerSearch"), "EditBox", {
        Label = function()
            return Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_EDIT")
        end,
        AlwaysEdit = true,
        EnterToCommit = true,
    })

    editBox:On("value_changed", function(_, text)
        CloseSearchEditBox()
        CommitSearch(scanner, text)
        DestroySearchContext()
    end)

    editBox:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                CloseSearchEditBox()
                DestroySearchContext()
                return true
            end,
        },
        {
            Key = Keys.VK_PRIOR,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_SEARCH_HISTORY_BACK",
            Action = function()
                local history = SearchUtils.GetHistory(SCANNER_SEARCH_HISTORY_CONTEXT)
                if #history == 0 then
                    Speak(Locale.Lookup("LOC_CAI_SEARCH_HISTORY_EMPTY"))
                    return true
                end

                local newIndex, entry = SearchUtils.NavigateHistory(
                    SCANNER_SEARCH_HISTORY_CONTEXT,
                    scanner.SearchHistoryIndex,
                    1
                )

                if newIndex == scanner.SearchHistoryIndex then
                    return true
                end

                scanner.SearchHistoryIndex = newIndex

                if entry then
                    editBox:SetText(entry, true)
                    Speak(entry)
                end

                return true
            end,
        },
        {
            Key = Keys.VK_NEXT,
            MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_SEARCH_HISTORY_FORWARD",
            Action = function()
                local history = SearchUtils.GetHistory(SCANNER_SEARCH_HISTORY_CONTEXT)
                if #history == 0 then
                    Speak(Locale.Lookup("LOC_CAI_SEARCH_HISTORY_EMPTY"))
                    return true
                end

                local newIndex, entry = SearchUtils.NavigateHistory(
                    SCANNER_SEARCH_HISTORY_CONTEXT,
                    scanner.SearchHistoryIndex,
                    -1
                )

                if newIndex == scanner.SearchHistoryIndex then
                    return true
                end

                scanner.SearchHistoryIndex = newIndex

                if entry then
                    editBox:SetText(entry, true)
                    Speak(entry)
                else
                    editBox:SetText("", true)
                end

                return true
            end,
        },
    })

    m_searchEditBox = editBox
    mgr:Push(editBox)
end

function CAIWorldScanner:ClearSearchCategory()
    local scanner = GetScannerState()
    if scanner == nil or not scanner.Categories then
        return
    end

    for i = #scanner.Categories, 1, -1 do
        local slot = scanner.Categories[i]

        if slot
            and slot.Category
            and slot.Category ~= false
            and slot.Category.Id == SCANNER_SEARCH_CATEGORY_ID then
            table.remove(scanner.Categories, i)
            break
        end
    end
end

function CAIWorldScanner:InjectSearchCategory(searchCategory)
    local scanner = GetScannerState()
    if scanner == nil then
        return
    end

    self:ClearSearchCategory()

    local slot = {
        Definition = {
            Id = SCANNER_SEARCH_CATEGORY_ID,
            LabelKey = searchCategory.LabelKey,
        },
        Category = searchCategory,
    }

    table.insert(scanner.Categories, 1, slot)
    FocusCategory(scanner, 1)
end

function CAIWorldScanner:GetActiveState()
    return GetScannerState()
end

function CAIWorldScanner:GetStateForPlayer(playerID)
    local state = m_PlayerState:Get(playerID)
    if state ~= nil then
        state.CategoryDefinitions = RegisteredCategoryDefinitions
    end

    return state
end

function CAIWorldScanner:ClearAllPlayerStates()
    m_PlayerState:ClearAll()
end

-- This wildcard include will include all loaded files beginning with "WorldScannerCategory_".
-- Category files should define their CAIWorldScannerCategory_* globals without including this file.
RegisteredCategoryDefinitions = {}
include("WorldScannerCategory_", true)
