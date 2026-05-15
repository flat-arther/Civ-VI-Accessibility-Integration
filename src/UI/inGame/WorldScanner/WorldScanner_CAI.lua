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
---@field GroupLabelResolver fun(groupId:string, firstItem:table|nil):string|nil
---@field Scan fun(context:WorldScannerContext):table[]

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
local WATER_LAYER = UILens.CreateLensLayerHash("Hex_Coloring_Water_Availablity")
---@type WorldScannerCategoryDefinition[]
local RegisteredCategoryDefinitions = {}

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

local function SpeakItemEntry(item, itemIndex, itemTotal)
    if item == nil then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_UNAVAILABLE"))
        return false
    end

    local directionText = GetItemDirectionText(item)

    local parts = {
        Utils.ResolveText(item.LabelKey),
    }
    if directionText ~= nil and directionText ~= "" then
        parts[#parts + 1] = directionText
    end
    parts[#parts + 1] = Utils.MakePositionText(itemIndex, itemTotal)

    Speak(table.concat(parts, ", "))
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

local function OnScannerCursorMoved(x, y)
    Utils.SetCurrentCursorPosition(x, y)
    CAIWorldScanner:Resort()
end

local function OnScannerLensLayerOn(layerNum)
    CAIWorldScanner:Rebuild()
end

local function OnScannerLensLayerOff(layerNum)
    CAIWorldScanner:Rebuild()
end

local function OnScannerUnitSelectionChanged(playerID, unitID, locationX, locationY, locationZ, isSelected, isEditable)
    if playerID == Game.GetLocalPlayer() then
        CAIWorldScanner:Rebuild()
    end
end

---@param focusOverride WorldScannerFocus|nil
function CAIWorldScanner:Rebuild(focusOverride)
    ---@type WorldScannerContext
    local context = {
        LocalPlayerID = Game.GetLocalPlayer(),
        ObserverID = Game.GetLocalObserver(),
    }
    local focus = focusOverride or Core.CaptureFocus(self)
    self.Categories = Core.BuildScanner(self.CategoryDefinitions, context)
    Core.RestoreFocus(self, focus)
    Core.ClampIndexes(self)
end

function CAIWorldScanner:Resort()
    local focus = Core.CaptureFocus(self)
    Core.RefreshSorts(self.Categories)
    Core.RestoreFocus(self, focus)
    Core.ClampIndexes(self)
end

function CAIWorldScanner:Initialize()
    self.CategoryDefinitions = RegisteredCategoryDefinitions
    self.Categories = {}
    self.CategoryIndex = 1
    self.SubCategoryIndex = 1
    self.GroupIndex = 0
    self.ItemIndex = 0
    self.PreviousJumpPlotIndex = nil
    if CAICursor ~= nil then
        Utils.SetCurrentCursorPosition(CAICursor.curX, CAICursor.curY)
    end
    LuaEvents.CAICursorMoved.Add(OnScannerCursorMoved)
    Events.LensLayerOn.Add(OnScannerLensLayerOn)
    Events.LensLayerOff.Add(OnScannerLensLayerOff)
    Events.UnitSelectionChanged.Add(OnScannerUnitSelectionChanged)
    self:Rebuild()
end

function CAIWorldScanner:ClearScanner()
    LuaEvents.CAICursorMoved.Remove(OnScannerCursorMoved)
    Events.LensLayerOn.Remove(OnScannerLensLayerOn)
    Events.LensLayerOff.Remove(OnScannerLensLayerOff)
    Events.UnitSelectionChanged.Remove(OnScannerUnitSelectionChanged)
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
    local count = #self.Categories
    if count == 0 then
        Speak(Locale.Lookup("LOC_CAI_WORLD_SCANNER_EMPTY"))
        return
    end

    local targetIndex = ((self.CategoryIndex - 1 + step) % count) + 1
    local targetCategory = self.Categories[targetIndex]
    local focus = {
        CategoryId = targetCategory and targetCategory.Id or nil,
        SubCategoryId = nil,
        GroupId = nil,
        ItemId = nil,
        HadGroupSelection = false,
        HadItemSelection = false,
    }
    self:Rebuild(focus)
    SelectFirstGroupAndItem(self)

    local category = GetCategory(self)
    if category ~= nil then
        SpeakPositionedLabel(category.LabelKey, self.CategoryIndex, #self.Categories)
    end
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

    LuaEvents.CAICursorMove(plot:GetX(), plot:GetY())
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

    LuaEvents.CAICursorMove(plot:GetX(), plot:GetY())
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

-- This wildcard include will include all loaded files beginning with "WorldScannerCategory_".
-- Category files should define their CAIWorldScannerCategory_* globals without including this file.
RegisteredCategoryDefinitions = {}
include("WorldScannerCategory_", true)
