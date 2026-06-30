include("hexCoordUtils_CAI")
include("WorldScannerCategoryUtils")
include("WorldScannerCore")

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
---@field PlotExtract fun(plotIndex:integer, plot:table, context:WorldScannerContext, collect:fun(item:table))|nil
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

---@type WorldScanner
CAIWorldScanner = CAIWorldScanner or {}

local HexCoordUtils = CAIHexCoordUtils
local Core = CAIWorldScannerCore
local Utils = CAIWorldScannerUtils
---@type WorldScannerCategoryDefinition[]
local RegisteredCategoryDefinitions = {}
local EMPTY_CATEGORY = false
local FindCategorySlotById

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

local function CreateCategorySlots(definitions)
    local autoFocusSlots = {}
    local normalSlots = {}
    for _, definition in ipairs(definitions or {}) do
        local slot = {
            Definition = definition,
            Category = nil,
        }
        if definition.AutoFocus then
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
    if plot == nil or CAICursor == nil then
        return nil
    end

    local directionText = HexCoordUtils.directionString(CAICursor.curX, CAICursor.curY, plot:GetX(), plot:GetY())
    if directionText == nil or directionText == "" then
        return Locale.Lookup("LOC_CAI_HERE")
    end

    return directionText
end

local function BuildItemEntryText(item, itemIndex, itemTotal)
    if item == nil then
        return nil
    end

    local directionText = GetItemDirectionText(item)
    local parts = { Utils.ResolveText(item.LabelKey) }
    if directionText ~= nil and directionText ~= "" then
        parts[#parts + 1] = directionText
    end
    parts[#parts + 1] = Utils.MakePositionText(itemIndex, itemTotal)
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

local function SpeakCurrentGroup(scanner)
    local group = GetGroup(scanner)
    if group == nil or group.Items == nil or #group.Items == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return false
    end

    return SpeakItemEntry(group.Items[scanner.ItemIndex], scanner.ItemIndex, group.TotalItems or #group.Items)
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
    local line1 = Utils.ResolveText(category.LabelKey) ..
    ", " .. Utils.MakePositionText(GetAvailableCategoryPosition(scanner, scanner.CategoryIndex), count)

    local group = GetGroup(scanner)
    local item = group ~= nil and group.Items ~= nil and group.Items[scanner.ItemIndex] or nil
    local line2 = BuildItemEntryText(item, scanner.ItemIndex, group ~= nil and (group.TotalItems or #group.Items) or 0)
    if line2 ~= nil then
        SpeakLines({ line1, line2 })
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
    if not isSelected then return end
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

---@param focusOverride WorldScannerFocus|nil
function CAIWorldScanner:Rebuild(focusOverride)
    local focus = focusOverride or Core.CaptureFocus(self)
    self.Categories = CreateCategorySlots(self.CategoryDefinitions)
    BuildAllIntoSlots(self)

    if focus ~= nil and focus.CategoryId ~= nil then
        self.CategoryIndex = FindCategorySlotById(self, focus.CategoryId) or self.CategoryIndex
    end
    if self.CategoryIndex < 1 then
        self.CategoryIndex = 1
    end

    EnsureCurrentCategory(self)
    Core.RestoreFocus(self, focus)
    EnsureCurrentCategory(self)
    Core.ClampIndexes(self)
end

function CAIWorldScanner:RebuildCategory(categoryId)
    local index = FindCategorySlotById(self, categoryId)
    if index == nil then
        return
    end

    local focus = Core.CaptureFocus(self)
    local slot = self.Categories[index]
    local definition = slot.Definition

    if definition ~= nil and definition.PlotExtract ~= nil then
        BuildAllIntoSlots(self)
    else
        local context = BuildScannerContext()
        slot.Category = Core.BuildCategory(definition, context) or EMPTY_CATEGORY
    end

    if definition ~= nil and definition.AutoFocus
        and slot.Category ~= nil and slot.Category ~= EMPTY_CATEGORY then
        FocusCategory(self, index)
    else
        Core.RestoreFocus(self, focus)
    end

    EnsureCurrentCategory(self)
    Core.ClampIndexes(self)
end

function CAIWorldScanner:ResortCurrentCategory()
    local focus = Core.CaptureFocus(self)
    Core.RefreshCategorySort(GetCategory(self))
    Core.RestoreFocus(self, focus)
    Core.ClampIndexes(self)
end

function CAIWorldScanner:Resort()
    self:ResortCurrentCategory()
end

function CAIWorldScanner:Initialize()
    self.CategoryDefinitions = RegisteredCategoryDefinitions
    self.Categories = CreateCategorySlots(self.CategoryDefinitions)
    self.CategoryIndex = 1
    self.SubCategoryIndex = 1
    self.GroupIndex = 0
    self.ItemIndex = 0
    self.PreviousJumpPlotIndex = nil
    if CAICursor ~= nil then
        Utils.SetCurrentCursorPosition(CAICursor.curX, CAICursor.curY)
    end
    BuildAllIntoSlots(self)
    LuaEvents.CAICursorMoved.Add(OnScannerCursorMoved)
    Events.LensLayerOn.Add(OnScannerLensLayerChanged)
    Events.LensLayerOff.Add(OnScannerLensLayerChanged)
    Events.UnitSelectionChanged.Add(OnScannerUnitSelectionChanged)
    Events.InterfaceModeChanged.Add(OnScannerInterfaceModeChanged)
    EnsureCurrentCategory(self)
end

function CAIWorldScanner:ClearScanner()
    LuaEvents.CAICursorMoved.Remove(OnScannerCursorMoved)
    Events.LensLayerOn.Remove(OnScannerLensLayerChanged)
    Events.LensLayerOff.Remove(OnScannerLensLayerChanged)
    Events.UnitSelectionChanged.Remove(OnScannerUnitSelectionChanged)
    Events.InterfaceModeChanged.Remove(OnScannerInterfaceModeChanged)
    self.Categories = {}
    self.CategoryDefinitions = {}
    self.CategoryIndex = 1
    self.SubCategoryIndex = 1
    self.GroupIndex = 0
    self.ItemIndex = 0
    self.PreviousJumpPlotIndex = nil
end

function CAIWorldScanner:OnLocalPlayerTurnBegin()
    self:Rebuild()
end

---@param step integer
function CAIWorldScanner:CycleCategory(step)
    self:Rebuild()

    local count = CountAvailableCategories(self)
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local targetIndex = FindAvailableCategoryIndex(self, self.CategoryIndex + step, step)
    if targetIndex == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end
    count = CountAvailableCategories(self)

    FocusCategory(self, targetIndex)
end

---@param step integer
function CAIWorldScanner:CycleSubCategory(step)
    local category = GetCategory(self)
    if category == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local count = #category.SubCategories
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    self.SubCategoryIndex = ((self.SubCategoryIndex - 1 + step) % count) + 1
    SelectFirstGroupAndItem(self)

    local subCategory = GetSubCategory(self)
    if subCategory ~= nil then
        SpeakPositionedLabel(subCategory.LabelKey, self.SubCategoryIndex, count)
    end
end

---@param step integer
function CAIWorldScanner:CycleGroup(step)
    local subCategory = GetSubCategory(self)
    if subCategory == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local count = #subCategory.Groups
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    if self.GroupIndex == 0 then
        self.GroupIndex = step > 0 and 1 or count
    else
        self.GroupIndex = ((self.GroupIndex - 1 + step) % count) + 1
    end
    self.ItemIndex = 1

    SpeakItemEntry(GetCurrentItem(self), self.ItemIndex, GetGroup(self).TotalItems or #GetGroup(self).Items)
end

---@param step integer
function CAIWorldScanner:CycleItem(step)
    local group = GetGroup(self)
    if group == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    local count = #group.Items
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    if self.ItemIndex == 0 then
        self.ItemIndex = step > 0 and 1 or count
    else
        self.ItemIndex = ((self.ItemIndex - 1 + step) % count) + 1
    end

    SpeakItemEntry(group.Items[self.ItemIndex], self.ItemIndex, count)
end

function CAIWorldScanner:JumpToCurrent()
    local item = GetCurrentItem(self)
    local plotIndex = item and item.PlotIndex or nil
    if plotIndex == nil then
        local group = GetGroup(self)
        plotIndex = group and group.PlotIndex or nil
    end

    if plotIndex == nil or plotIndex < 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    local currentPlotIndex = CAICursor and CAICursor.GetPlotId and CAICursor:GetPlotId() or -1
    if currentPlotIndex ~= nil and currentPlotIndex >= 0 then
        self.PreviousJumpPlotIndex = currentPlotIndex
    end

    local plot = Map.GetPlotByIndex(plotIndex)
    if plot == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return
    end

    LuaEvents.CAICursorMoveTo(plotIndex, "jump")
end

function CAIWorldScanner:ReturnFromJump()
    if self.PreviousJumpPlotIndex == nil or self.PreviousJumpPlotIndex < 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_NO_PREVIOUS_JUMP"))
        return
    end

    local plot = Map.GetPlotByIndex(self.PreviousJumpPlotIndex)
    if plot == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_NO_PREVIOUS_JUMP"))
        self.PreviousJumpPlotIndex = nil
        return
    end

    LuaEvents.CAICursorMoveTo(self.PreviousJumpPlotIndex, "jump")
    self.PreviousJumpPlotIndex = nil
end

function CAIWorldScanner:SpeakCurrentDirection()
    local item = GetCurrentItem(self)
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
local m_searchSnapshot = nil
local m_searchHistoryIndex = 0

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
                            local key = category.Id ..
                            "|" .. (subCategory.Id or "") .. "|" .. (group.Id or "") .. "|" .. tostring(leaf.Id)
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
    for _, entry in ipairs(snapshot) do
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

    local lookup = BuildSnapshotLookup(m_searchSnapshot)

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

    scanner:InjectSearchCategory(searchCategory)
end

local function CloseSearchEditBox()
    if m_searchEditBox then
        if mgr then
            mgr:RemoveFromStack(m_searchEditBox.Id)
        end
        m_searchEditBox:Destroy()
        m_searchEditBox = nil
    end
    m_searchHistoryIndex = 0
end

function CAIWorldScanner:OpenSearch()
    if not mgr then return end
    if m_searchEditBox then return end

    self:Rebuild()

    m_searchSnapshot = BuildSearchSnapshot(self)
    if #m_searchSnapshot == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    if not BuildSearchContext(m_searchSnapshot) then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local scanner = self
    m_searchHistoryIndex = 0

    local editBox = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScannerSearch"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_WORLD_SCANNER_SEARCH_EDIT") end,
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
                local newIndex, entry = SearchUtils.NavigateHistory(SCANNER_SEARCH_HISTORY_CONTEXT, m_searchHistoryIndex,
                    1)
                if newIndex == m_searchHistoryIndex then return true end
                m_searchHistoryIndex = newIndex
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
                local newIndex, entry = SearchUtils.NavigateHistory(SCANNER_SEARCH_HISTORY_CONTEXT, m_searchHistoryIndex,
                    -1)
                if newIndex == m_searchHistoryIndex then return true end
                m_searchHistoryIndex = newIndex
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
    if not self.Categories then return end

    for i = #self.Categories, 1, -1 do
        local slot = self.Categories[i]
        if slot and slot.Category and slot.Category ~= false and slot.Category.Id == SCANNER_SEARCH_CATEGORY_ID then
            table.remove(self.Categories, i)
            break
        end
    end
end

function CAIWorldScanner:InjectSearchCategory(searchCategory)
    self:ClearSearchCategory()

    local slot = {
        Definition = {
            Id = SCANNER_SEARCH_CATEGORY_ID,
            LabelKey = searchCategory.LabelKey,
        },
        Category = searchCategory,
    }

    table.insert(self.Categories, 1, slot)
    FocusCategory(self, 1)
end

-- Override CycleCategory to clear search results on category change.
local OrigCycleCategory = CAIWorldScanner.CycleCategory
function CAIWorldScanner:CycleCategory(step)
    self:ClearSearchCategory()
    OrigCycleCategory(self, step)
end

-- Override ClearScanner to clean up search state.
local OrigClearScanner = CAIWorldScanner.ClearScanner
function CAIWorldScanner:ClearScanner()
    CloseSearchEditBox()
    DestroySearchContext()
    m_searchSnapshot = nil
    OrigClearScanner(self)
end

-- This wildcard include will include all loaded files beginning with "WorldScannerCategory_".
-- Category files should define their CAIWorldScannerCategory_* globals without including this file.
RegisteredCategoryDefinitions = {}
include("WorldScannerCategory_", true)
