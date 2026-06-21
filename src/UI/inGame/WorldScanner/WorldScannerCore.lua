---@class WorldScannerLeafItem
---@field Id string
---@field PlotIndex integer
---@field LabelKey string
---@field Item table

---@class WorldScannerGroup
---@field Id string
---@field Key string
---@field LabelKey string
---@field PlotIndex integer
---@field Items WorldScannerLeafItem[]
---@field TotalItems integer

---@class WorldScannerSubCategory
---@field Id string
---@field Key string
---@field LabelKey string
---@field Groups WorldScannerGroup[]
---@field TotalItems integer

---@class WorldScannerCategory
---@field Id string
---@field LabelKey string
---@field SubCategories WorldScannerSubCategory[]
---@field TotalItems integer

---@type table
CAIWorldScannerCore = CAIWorldScannerCore or {}

local Core = CAIWorldScannerCore
local Utils = CAIWorldScannerUtils

Core.AllSubCategoryId = "__all"
Core.AllSubCategoryLabelKey = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_ALL"

local function CompareResolvedLabels(aLabelKey, bLabelKey)
    local aLabel = Utils.ResolveText(aLabelKey)
    local bLabel = Utils.ResolveText(bLabelKey)
    if aLabel == bLabel then
        return 0
    end

    return Locale.Compare(aLabel, bLabel)
end

local function SortItems(items)
    table.sort(items, function(a, b)
        local aDistance = Utils.GetDistance(nil, a.PlotIndex)
        local bDistance = Utils.GetDistance(nil, b.PlotIndex)
        if aDistance ~= bDistance then
            return aDistance < bDistance
        end

        local labelCompare = CompareResolvedLabels(a.LabelKey, b.LabelKey)
        if labelCompare ~= 0 then
            return labelCompare < 0
        end

        return tostring(a.Id) < tostring(b.Id)
    end)
end

local function ResolveCategoryEntry(entry)
    if entry == nil then
        return nil
    end

    if entry.Category ~= nil then
        if entry.Category == false then
            return nil
        end

        return entry.Category
    end

    return entry
end

local function FindIndexInOrder(order, key)
    if order == nil or key == nil then
        return nil
    end

    for index, orderedKey in ipairs(order) do
        if orderedKey == key then
            return index
        end
    end

    return nil
end

local function SortGroups(groups, groupOrder, groupComparator)
    table.sort(groups, function(a, b)
        if groupComparator ~= nil then
            local result = groupComparator(a, b)
            if result ~= nil then
                return result
            end
        end

        local aOrder = FindIndexInOrder(groupOrder, a.Id)
        local bOrder = FindIndexInOrder(groupOrder, b.Id)
        if aOrder ~= nil or bOrder ~= nil then
            aOrder = aOrder or math.huge
            bOrder = bOrder or math.huge
            if aOrder ~= bOrder then
                return aOrder < bOrder
            end
        end

        local aDistance = Utils.GetDistance(nil, a.PlotIndex)
        local bDistance = Utils.GetDistance(nil, b.PlotIndex)
        if aDistance ~= bDistance then
            return aDistance < bDistance
        end

        local labelCompare = CompareResolvedLabels(a.LabelKey, b.LabelKey)
        if labelCompare ~= 0 then
            return labelCompare < 0
        end

        return tostring(a.Id or "") < tostring(b.Id or "")
    end)
end

local function BuildLeafItems(items, context)
    local built = {}

    for _, item in ipairs(items) do
        if item.Validate == nil or item.Validate(item, context) then
            built[#built + 1] = {
                Id = item.Id,
                PlotIndex = item.PlotIndex,
                LabelKey = item.LabelKey,
                Item = item,
            }
        end
    end

    SortItems(built)
    return built
end

local function AddBucketItem(buckets, key, item)
    if key == nil or key == "" then
        return
    end

    local bucket = buckets[key]
    if bucket == nil then
        bucket = {}
        buckets[key] = bucket
    end

    bucket[#bucket + 1] = item
end

local function ResolveGroupLabel(definition, groupId, firstItem)
    if definition.GroupLabelResolver ~= nil then
        return definition.GroupLabelResolver(groupId, firstItem)
    end

    return firstItem and firstItem.LabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

local function BuildGroups(definition, subCategoryId, items, context)
    local buckets = {}
    for _, item in ipairs(items) do
        AddBucketItem(buckets, item.GroupId, item)
    end

    local groups = {}
    for groupId, groupedItems in pairs(buckets) do
        local leaves = BuildLeafItems(groupedItems, context)
        if #leaves > 0 then
            local firstItem = leaves[1].Item
            groups[#groups + 1] = {
                Id = groupId,
                Key = groupId,
                LabelKey = ResolveGroupLabel(definition, groupId, firstItem),
                PlotIndex = leaves[1].PlotIndex,
                Items = leaves,
                TotalItems = #leaves,
                SortValue = firstItem and firstItem.GroupSortValue or nil,
            }
        end
    end

    local groupOrder = definition.GroupOrderBySubCategory and definition.GroupOrderBySubCategory[subCategoryId] or nil
    local groupComparator = definition.GroupComparatorBySubCategory and definition.GroupComparatorBySubCategory[subCategoryId] or nil
    SortGroups(groups, groupOrder, groupComparator)
    return groups
end

---@param definition WorldScannerCategoryDefinition
---@param rawItems table[]
---@param context WorldScannerContext
---@return WorldScannerCategory|nil
local function BuildCategoryFromItems(definition, rawItems, context)
    if rawItems == nil or #rawItems == 0 then
        return nil
    end

    local subBuckets = {}
    for _, item in ipairs(rawItems) do
        AddBucketItem(subBuckets, item.SubCategoryId, item)
    end

    local subCategories = {}
    local subCategoryOrder = definition.SubCategoryOrder or {}

    local allGroups = BuildGroups(definition, Core.AllSubCategoryId, rawItems, context)
    if #allGroups > 0 then
        local allCount = 0
        for _, group in ipairs(allGroups) do
            allCount = allCount + group.TotalItems
        end

        subCategories[#subCategories + 1] = {
            Id = Core.AllSubCategoryId,
            Key = Core.AllSubCategoryId,
            LabelKey = Core.AllSubCategoryLabelKey,
            Groups = allGroups,
            TotalItems = allCount,
            GroupOrder = definition.GroupOrderBySubCategory and definition.GroupOrderBySubCategory[Core.AllSubCategoryId] or nil,
            GroupComparator = definition.GroupComparatorBySubCategory and definition.GroupComparatorBySubCategory[Core.AllSubCategoryId] or nil,
        }
    end

    for _, subCategoryId in ipairs(subCategoryOrder) do
        local groupedItems = subBuckets[subCategoryId]
        if groupedItems ~= nil and #groupedItems > 0 then
            local groups = BuildGroups(definition, subCategoryId, groupedItems, context)
            if #groups > 0 then
                local count = 0
                for _, group in ipairs(groups) do
                    count = count + group.TotalItems
                end

                subCategories[#subCategories + 1] = {
                    Id = subCategoryId,
                    Key = subCategoryId,
                    LabelKey = definition.SubCategoryLabels[subCategoryId] or "LOC_CAI_WORLD_SCANNER_UNKNOWN",
                    Groups = groups,
                    TotalItems = count,
                    GroupOrder = definition.GroupOrderBySubCategory and definition.GroupOrderBySubCategory[subCategoryId] or nil,
                    GroupComparator = definition.GroupComparatorBySubCategory and definition.GroupComparatorBySubCategory[subCategoryId] or nil,
                }
            end
        end
    end

    if #subCategories == 0 then
        return nil
    end

    return {
        Id = definition.Id,
        LabelKey = definition.LabelKey,
        SubCategories = subCategories,
        TotalItems = subCategories[1] and subCategories[1].TotalItems or 0,
    }
end

---@param definition WorldScannerCategoryDefinition
---@param context WorldScannerContext
---@return WorldScannerCategory|nil
function Core.BuildCategory(definition, context)
    if definition.CanScan ~= nil and not definition.CanScan(context) then
        return nil
    end

    local rawItems = definition.Scan and definition.Scan(context) or {}
    return BuildCategoryFromItems(definition, rawItems, context)
end

---@param definitions WorldScannerCategoryDefinition[]
---@param context WorldScannerContext
---@return table<string, WorldScannerCategory|nil>
function Core.BuildAllCategories(definitions, context)
    local results = {}
    local plotExtractors = {}
    local scanCategories = {}

    for _, definition in ipairs(definitions) do
        if definition.CanScan ~= nil and not definition.CanScan(context) then
            results[definition.Id] = nil
        elseif definition.PlotExtract ~= nil then
            local entry = { Definition = definition, RawItems = {} }
            plotExtractors[#plotExtractors + 1] = entry
        else
            scanCategories[#scanCategories + 1] = definition
        end
    end

    if #plotExtractors > 0 then
        for _, entry in ipairs(plotExtractors) do
            if entry.Definition.BeginExtract ~= nil then
                entry.Definition.BeginExtract()
            end
        end

        Utils.ForEachRevealedPlot(context, function(plotIndex, plot)
            for _, entry in ipairs(plotExtractors) do
                local items = entry.RawItems
                entry.Definition.PlotExtract(plotIndex, plot, context, function(item)
                    items[#items + 1] = item
                end)
            end
        end)

        for _, entry in ipairs(plotExtractors) do
            results[entry.Definition.Id] = BuildCategoryFromItems(entry.Definition, entry.RawItems, context)
        end
    end

    for _, definition in ipairs(scanCategories) do
        local rawItems = definition.Scan and definition.Scan(context) or {}
        results[definition.Id] = BuildCategoryFromItems(definition, rawItems, context)
    end

    return results
end

---@param category WorldScannerCategory|nil
function Core.RefreshCategorySort(category)
    if category == nil then
        return
    end

    local subCategories = category.SubCategories or {}
    for _, subCategory in ipairs(subCategories) do
        local groups = subCategory.Groups or {}
        for _, group in ipairs(groups) do
            SortItems(group.Items or {})
            local firstItem = group.Items and group.Items[1] or nil
            group.PlotIndex = firstItem and firstItem.PlotIndex or group.PlotIndex
        end
        SortGroups(groups, subCategory.GroupOrder, subCategory.GroupComparator)
    end
end

---@param categories WorldScannerCategory[]|nil
function Core.RefreshSorts(categories)
    if categories == nil then
        return
    end

    for _, entry in ipairs(categories) do
        Core.RefreshCategorySort(ResolveCategoryEntry(entry))
    end
end

---@param scanner WorldScanner
---@return WorldScannerCategory|nil
function Core.GetCategory(scanner)
    return scanner and scanner.Categories and ResolveCategoryEntry(scanner.Categories[scanner.CategoryIndex]) or nil
end

---@param scanner WorldScanner
---@return WorldScannerSubCategory|nil
function Core.GetSubCategory(scanner)
    local category = Core.GetCategory(scanner)
    return category and category.SubCategories and category.SubCategories[scanner.SubCategoryIndex] or nil
end

---@param scanner WorldScanner|nil
---@return WorldScannerGroup|nil
function Core.GetGroup(scanner)
    if scanner == nil or scanner.GroupIndex <= 0 then
        return nil
    end

    local subCategory = Core.GetSubCategory(scanner)
    return subCategory and subCategory.Groups and subCategory.Groups[scanner.GroupIndex] or nil
end

---@param scanner WorldScanner|nil
---@return WorldScannerLeafItem|nil
function Core.GetCurrentItem(scanner)
    local group = Core.GetGroup(scanner)
    if scanner == nil or group == nil or scanner.ItemIndex <= 0 then
        return nil
    end

    return group.Items and group.Items[scanner.ItemIndex] or nil
end

---@param scanner WorldScanner|nil
---@return WorldScannerFocus
function Core.CaptureFocus(scanner)
    local focus = {
        CategoryId = nil,
        SubCategoryId = nil,
        GroupId = nil,
        ItemId = nil,
        HadGroupSelection = scanner ~= nil and scanner.GroupIndex ~= nil and scanner.GroupIndex > 0 or false,
        HadItemSelection = scanner ~= nil and scanner.ItemIndex ~= nil and scanner.ItemIndex > 0 or false,
    }

    local category = Core.GetCategory(scanner)
    if category ~= nil then
        focus.CategoryId = category.Id
    end

    local subCategory = Core.GetSubCategory(scanner)
    if subCategory ~= nil then
        focus.SubCategoryId = subCategory.Id
    end

    local group = Core.GetGroup(scanner)
    if group ~= nil then
        focus.GroupId = group.Id
    end

    local item = Core.GetCurrentItem(scanner)
    if item ~= nil then
        focus.ItemId = item.Id
    end

    return focus
end

local function FindCategoryIndex(categories, categoryId)
    if categories == nil or categoryId == nil then
        return nil
    end

    for index, entry in ipairs(categories) do
        local category = ResolveCategoryEntry(entry)
        local definition = entry and entry.Definition or nil
        if (category ~= nil and category.Id == categoryId)
            or (definition ~= nil and definition.Id == categoryId) then
            return index
        end
    end

    return nil
end

local function FindSubCategoryIndex(subCategories, subCategoryKey)
    if subCategories == nil or subCategoryKey == nil then
        return nil
    end

    for index, subCategory in ipairs(subCategories) do
        if subCategory.Key == subCategoryKey then
            return index
        end
    end

    return nil
end

local function FindGroupIndex(groups, groupKey)
    if groups == nil or groupKey == nil then
        return nil
    end

    for index, group in ipairs(groups) do
        if group.Key == groupKey then
            return index
        end
    end

    return nil
end

local function FindItemIndex(items, itemId)
    if items == nil or itemId == nil then
        return nil
    end

    for index, item in ipairs(items) do
        if item.Id == itemId then
            return index
        end
    end

    return nil
end

---@param scanner WorldScanner|nil
---@param focus WorldScannerFocus|nil
function Core.RestoreFocus(scanner, focus)
    if scanner == nil then
        return
    end

    local categories = scanner.Categories or {}
    if #categories == 0 then
        scanner.CategoryIndex = 0
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    scanner.CategoryIndex = FindCategoryIndex(categories, focus and focus.CategoryId) or 1

    local category = ResolveCategoryEntry(categories[scanner.CategoryIndex])
    if category == nil then
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end
    local subCategories = category.SubCategories or {}
    if #subCategories == 0 then
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    scanner.SubCategoryIndex = FindSubCategoryIndex(subCategories, focus and focus.SubCategoryId) or 1

    local subCategory = subCategories[scanner.SubCategoryIndex]
    local groups = subCategory.Groups or {}
    if #groups == 0 then
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    if focus ~= nil and focus.HadGroupSelection then
        scanner.GroupIndex = FindGroupIndex(groups, focus.GroupId) or 1
    else
        scanner.GroupIndex = 0
    end

    if scanner.GroupIndex == 0 then
        scanner.ItemIndex = 0
        return
    end

    local group = groups[scanner.GroupIndex]
    local items = group.Items or {}
    if #items == 0 then
        scanner.ItemIndex = 0
        return
    end

    if focus ~= nil and focus.HadItemSelection then
        scanner.ItemIndex = FindItemIndex(items, focus.ItemId) or 1
    else
        scanner.ItemIndex = 0
    end
end

---@param scanner WorldScanner|nil
function Core.ClampIndexes(scanner)
    if scanner == nil then
        return
    end

    local categoryCount = scanner.Categories and #scanner.Categories or 0
    if categoryCount <= 0 then
        scanner.CategoryIndex = 0
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    if scanner.CategoryIndex < 1 then
        scanner.CategoryIndex = 1
    elseif scanner.CategoryIndex > categoryCount then
        scanner.CategoryIndex = categoryCount
    end

    local category = ResolveCategoryEntry(scanner.Categories[scanner.CategoryIndex])
    if category == nil then
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    local subCategories = category.SubCategories or {}
    local subCount = #subCategories
    if subCount <= 0 then
        scanner.SubCategoryIndex = 0
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    if scanner.SubCategoryIndex < 1 then
        scanner.SubCategoryIndex = 1
    elseif scanner.SubCategoryIndex > subCount then
        scanner.SubCategoryIndex = subCount
    end

    local groups = subCategories[scanner.SubCategoryIndex].Groups or {}
    local groupCount = #groups
    if groupCount <= 0 then
        scanner.GroupIndex = 0
        scanner.ItemIndex = 0
        return
    end

    if scanner.GroupIndex > groupCount then
        scanner.GroupIndex = groupCount
    end
    if scanner.GroupIndex < 0 then
        scanner.GroupIndex = 0
    end

    if scanner.GroupIndex == 0 then
        scanner.ItemIndex = 0
        return
    end

    local items = groups[scanner.GroupIndex].Items or {}
    local itemCount = #items
    if itemCount <= 0 then
        scanner.ItemIndex = 0
        return
    end

    if scanner.ItemIndex > itemCount then
        scanner.ItemIndex = itemCount
    end
    if scanner.ItemIndex < 0 then
        scanner.ItemIndex = 0
    end
end
