-- Persistent scanner category layout and Civ V-style custom category model.

CAIWorldScannerCategoryConfig = {}
local C = CAIWorldScannerCategoryConfig

local CONFIG_SECTION = "WorldScannerCategories"
local ORDER_KEY = "Order"
local NEXT_CUSTOM_ID_KEY = "NextCustomId"
local CUSTOM_PREFIX = "custom:"
local CATEGORY_ID_ALIASES = {
    wonders = "districts",
}

local DEFAULT_ORDER = {
    "cities",
    "improvements",
    "recommendations",
    "myUnits",
    "neutralUnits",
    "enemyUnits",
    "resources",
    "districts",
    "specialMapObjects",
    "terrain",
    "geography",
    "queuedPath",
    "mapTacs",
    "cityManagement",
    "validTargets",
    "activeLens",
}

local TOOLTIP_KEYS = {
    cities = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_CITIES",
    improvements = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_IMPROVEMENTS",
    recommendations = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_RECOMMENDATIONS",
    myUnits = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_MY_UNITS",
    neutralUnits = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_NEUTRAL_UNITS",
    enemyUnits = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_ENEMY_UNITS",
    resources = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_RESOURCES",
    districts = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_DISTRICTS_AND_WONDERS",
    specialMapObjects = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_SPECIAL_MAP_OBJECTS",
    terrain = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_TERRAIN",
    geography = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_GEOGRAPHY",
    queuedPath = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_QUEUED_PATH",
    mapTacs = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_MAP_TACS",
    cityManagement = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_CITY_MANAGEMENT",
    validTargets = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_VALID_TARGETS",
    activeLens = "LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_ACTIVE_LENS",
}

local m_definitions = {}
local m_definitionsById = {}
local m_customs = {}
local m_customsById = {}
local m_order = {}
local m_nextCustomId = 1
local m_configured = false

local function GetValue(key, defaultValue)
    return CAI.GetConfigValue(CONFIG_SECTION, key, defaultValue)
end

local function SetValue(key, value)
    return CAI.SetConfigValue(CONFIG_SECTION, key, tostring(value or ""))
end

local function ToBool(value, defaultValue)
    if value == nil or value == "" then return defaultValue and true or false end
    local normalized = tostring(value):lower()
    return normalized == "true" or normalized == "1" or normalized == "yes" or normalized == "on"
end

local function Trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function NormalizeCategoryId(id)
    return CATEGORY_ID_ALIASES[id] or id
end

local function Split(value, separator)
    local out = {}
    value = tostring(value or "")
    if value == "" then return out end
    local pattern = "([^" .. separator .. "]+)"
    for part in value:gmatch(pattern) do out[#out + 1] = part end
    return out
end

local function Join(values, separator)
    return table.concat(values or {}, separator)
end

local function SafeKey(value) return tostring(value or ""):gsub("[^%w_]", "_") end
local function EnabledKey(id) return "Enabled_" .. SafeKey(id) end
local function CustomActiveKey(id) return "CustomActive_" .. tostring(id) end
local function CustomNameKey(id) return "CustomName_" .. tostring(id) end
local function SelectorCountKey(id) return "CustomSelectorCount_" .. tostring(id) end
local function SelectorKey(id, index) return "CustomSelector_" .. tostring(id) .. "_" .. tostring(index) end
local function TermCountKey(id, kind) return "Custom" .. kind .. "Count_" .. tostring(id) end
local function TermKey(id, kind, index)
    return "Custom" .. kind .. "_" .. tostring(id) .. "_" .. tostring(index)
end

local function SaveOrder()
    SetValue(ORDER_KEY, Join(m_order, ","))
end

local function FindOrderIndex(id)
    for index, entryId in ipairs(m_order) do
        if entryId == id then return index end
    end
    return nil
end

local function DefaultRank(id)
    for index, defaultId in ipairs(DEFAULT_ORDER) do
        if defaultId == id then return index end
    end
    return #DEFAULT_ORDER + 1
end

local function OrderedDefinitions()
    local out = {}
    local seen = {}
    for _, id in ipairs(DEFAULT_ORDER) do
        local definition = m_definitionsById[id]
        if definition ~= nil then
            out[#out + 1] = definition
            seen[id] = true
        end
    end
    for _, definition in ipairs(m_definitions) do
        if not seen[definition.Id] then out[#out + 1] = definition end
    end
    return out
end

local function ReadTerms(id, kind)
    local out = {}
    local count = tonumber(GetValue(TermCountKey(id, kind), "0")) or 0
    for index = 1, count do
        local term = Trim(GetValue(TermKey(id, kind, index), ""))
        if term ~= "" then out[#out + 1] = term end
    end
    return out
end

local function SaveTerms(custom, kind)
    local terms = custom[kind]
    SetValue(TermCountKey(custom.NumericId, kind), #terms)
    for index, term in ipairs(terms) do
        SetValue(TermKey(custom.NumericId, kind, index), term)
    end
end

local function ReadSelectors(id)
    local selectors = {}
    local count = tonumber(GetValue(SelectorCountKey(id), "0")) or 0
    for index = 1, count do
        local encoded = tostring(GetValue(SelectorKey(id, index), ""))
        local categoryId, subCategoryId = encoded:match("^([^|]+)|(.+)$")
        categoryId = NormalizeCategoryId(categoryId)
        if categoryId ~= nil and subCategoryId ~= nil and m_definitionsById[categoryId] ~= nil then
            local selection = selectors[categoryId]
            if selection == nil then
                selection = { All = false, Subs = {} }
                selectors[categoryId] = selection
            end
            if subCategoryId == "__all" then
                selection.All = true
                selection.Subs = {}
            elseif not selection.All then
                selection.Subs[subCategoryId] = true
            end
        end
    end
    return selectors
end

local function SaveSelectors(custom)
    local rows = {}
    for _, definition in ipairs(OrderedDefinitions()) do
        local selection = custom.Selectors[definition.Id]
        if selection ~= nil then
            if selection.All then
                rows[#rows + 1] = definition.Id .. "|__all"
            else
                for _, subCategoryId in ipairs(definition.SubCategoryOrder or {}) do
                    if selection.Subs[subCategoryId] then
                        rows[#rows + 1] = definition.Id .. "|" .. subCategoryId
                    end
                end
            end
        end
    end
    SetValue(SelectorCountKey(custom.NumericId), #rows)
    for index, row in ipairs(rows) do SetValue(SelectorKey(custom.NumericId, index), row) end
end

local function SaveCustom(custom)
    SetValue(CustomActiveKey(custom.NumericId), "true")
    SetValue(CustomNameKey(custom.NumericId), custom.Name)
    SaveSelectors(custom)
    SaveTerms(custom, "Include")
    SaveTerms(custom, "Exclude")
end

local function NextDefaultNameNumber()
    local number = 1
    while true do
        local candidate = Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DEFAULT_NAME", number)
        local used = false
        for _, custom in ipairs(m_customs) do
            if custom.Name == candidate then
                used = true
                break
            end
        end
        if not used then return number end
        number = number + 1
    end
end

local function HydrateCustoms()
    m_customs = {}
    m_customsById = {}
    m_nextCustomId = tonumber(GetValue(NEXT_CUSTOM_ID_KEY, "1")) or 1
    for numericId = 1, m_nextCustomId - 1 do
        if ToBool(GetValue(CustomActiveKey(numericId), "false"), false) then
            local id = CUSTOM_PREFIX .. tostring(numericId)
            local custom = {
                Id = id,
                NumericId = numericId,
                Name = tostring(GetValue(CustomNameKey(numericId),
                    Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DEFAULT_NAME", numericId))),
                Selectors = ReadSelectors(numericId),
                Include = ReadTerms(numericId, "Include"),
                Exclude = ReadTerms(numericId, "Exclude"),
            }
            m_customs[#m_customs + 1] = custom
            m_customsById[id] = custom
        end
    end
end

local function ReconcileOrder()
    local reconciled = {}
    local seen = {}
    for _, savedId in ipairs(Split(GetValue(ORDER_KEY, ""), ",")) do
        local id = NormalizeCategoryId(savedId)
        if not seen[id] and (m_definitionsById[id] ~= nil or m_customsById[id] ~= nil) then
            reconciled[#reconciled + 1] = id
            seen[id] = true
        end
    end
    for _, definition in ipairs(OrderedDefinitions()) do
        if not seen[definition.Id] then
            local inserted = false
            if definition.Id == "geography" then
                for index, id in ipairs(reconciled) do
                    if id == "terrain" then
                        table.insert(reconciled, index + 1, definition.Id)
                        inserted = true
                        break
                    end
                end
            end
            if not inserted then
                reconciled[#reconciled + 1] = definition.Id
            end
            seen[definition.Id] = true
        end
    end
    for _, custom in ipairs(m_customs) do
        if not seen[custom.Id] then
            table.insert(reconciled, 1, custom.Id)
            seen[custom.Id] = true
        end
    end
    m_order = reconciled
    SaveOrder()
end

function C.Configure(definitions)
    m_definitions = definitions or {}
    m_definitionsById = {}
    for _, definition in ipairs(m_definitions) do
        m_definitionsById[definition.Id] = definition
    end
    HydrateCustoms()
    ReconcileOrder()
    m_configured = true
end

function C.IsConfigured() return m_configured end
function C.GetDefinition(id) return m_definitionsById[id] end
function C.GetCustom(id) return m_customsById[id] end
function C.GetDefinitions() return OrderedDefinitions() end

function C.GetEntries()
    local entries = {}
    for _, id in ipairs(m_order) do
        local definition = m_definitionsById[id]
        local custom = m_customsById[id]
        if definition ~= nil then
            entries[#entries + 1] = {
                Id = id,
                Definition = definition,
                IsCustom = false,
                IsContextual = definition.Contextual == true,
                Enabled = C.IsEnabled(id),
            }
        elseif custom ~= nil then
            entries[#entries + 1] = {
                Id = id,
                Custom = custom,
                IsCustom = true,
                IsContextual = false,
                Enabled = C.IsEnabled(id),
            }
        end
    end
    return entries
end

function C.GetLabel(entryOrId)
    local id = type(entryOrId) == "table" and entryOrId.Id or entryOrId
    local custom = m_customsById[id]
    if custom ~= nil then return custom.Name end
    local definition = m_definitionsById[id]
    return definition ~= nil and Locale.Lookup(definition.LabelKey) or tostring(id or "")
end

function C.GetTypeLabel(entryOrId)
    local id = type(entryOrId) == "table" and entryOrId.Id or entryOrId
    if m_customsById[id] ~= nil then return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_TYPE_CUSTOM") end
    local definition = m_definitionsById[id]
    if definition ~= nil and definition.Contextual then
        return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_TYPE_CONTEXTUAL")
    end
    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_TYPE_BUILT_IN")
end

local function BuildCustomTooltip(custom)
    local sourceParts = {}
    for _, definition in ipairs(OrderedDefinitions()) do
        local selection = custom.Selectors[definition.Id]
        if selection ~= nil then
            local categoryLabel = Locale.Lookup(definition.LabelKey)
            if selection.All then
                sourceParts[#sourceParts + 1] = Locale.Lookup(
                    "LOC_CAI_WORLD_SCANNER_CUSTOM_TOOLTIP_SOURCE_ALL", categoryLabel)
            else
                local subCategoryParts = {}
                for _, subCategoryId in ipairs(definition.SubCategoryOrder or {}) do
                    if selection.Subs[subCategoryId] then
                        subCategoryParts[#subCategoryParts + 1] = Locale.Lookup(
                            (definition.SubCategoryLabels and definition.SubCategoryLabels[subCategoryId])
                                or "LOC_CAI_WORLD_SCANNER_UNKNOWN")
                    end
                end
                if #subCategoryParts > 0 then
                    sourceParts[#sourceParts + 1] = Locale.Lookup(
                        "LOC_CAI_WORLD_SCANNER_CUSTOM_TOOLTIP_SOURCE_SUBCATEGORIES",
                        categoryLabel, table.concat(subCategoryParts, ", "))
                end
            end
        end
    end

    local none = Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_TOOLTIP_NONE")
    local sources = #sourceParts > 0 and table.concat(sourceParts, "; ") or none
    local included = #custom.Include > 0 and table.concat(custom.Include, ", ") or none
    local excluded = #custom.Exclude > 0 and table.concat(custom.Exclude, ", ") or none
    return Locale.Lookup("LOC_CAI_WORLD_SCANNER_CATEGORY_TOOLTIP_CUSTOM",
        sources, included, excluded)
end

function C.GetTooltip(entryOrId)
    local id = type(entryOrId) == "table" and entryOrId.Id or entryOrId
    local custom = m_customsById[id]
    if custom ~= nil then return BuildCustomTooltip(custom) end
    local tooltipKey = TOOLTIP_KEYS[id]
    return tooltipKey ~= nil and Locale.Lookup(tooltipKey) or ""
end

function C.IsEnabled(id)
    return ToBool(GetValue(EnabledKey(id), "true"), true)
end

function C.SetEnabled(id, enabled)
    if m_definitionsById[id] == nil and m_customsById[id] == nil then return false end
    return SetValue(EnabledKey(id), enabled and "true" or "false")
end

function C.Move(id, step)
    local index = FindOrderIndex(id)
    if index == nil then return false end
    local target = index + step
    if target < 1 or target > #m_order then return false end
    m_order[index], m_order[target] = m_order[target], m_order[index]
    SaveOrder()
    return true
end

function C.MoveToDefaultPosition(id)
    if m_definitionsById[id] == nil then return false end
    local index = FindOrderIndex(id)
    if index == nil then return false end
    table.remove(m_order, index)
    local targetRank = DefaultRank(id)
    local insertAt = #m_order + 1
    for position, entryId in ipairs(m_order) do
        if m_definitionsById[entryId] ~= nil and DefaultRank(entryId) > targetRank then
            insertAt = position
            break
        end
    end
    table.insert(m_order, insertAt, id)
    SaveOrder()
    return true
end

function C.ResetBuiltInLayout()
    local builtInPositions = {}
    for index, id in ipairs(m_order) do
        if m_definitionsById[id] ~= nil then builtInPositions[#builtInPositions + 1] = index end
    end
    local ordered = OrderedDefinitions()
    for index, position in ipairs(builtInPositions) do
        m_order[position] = ordered[index] and ordered[index].Id or m_order[position]
    end
    for _, definition in ipairs(ordered) do C.SetEnabled(definition.Id, true) end
    SaveOrder()
end

function C.CreateCustom(seedCategoryId)
    local numericId = m_nextCustomId
    m_nextCustomId = numericId + 1
    SetValue(NEXT_CUSTOM_ID_KEY, m_nextCustomId)
    local defaultNameNumber = NextDefaultNameNumber()
    local id = CUSTOM_PREFIX .. tostring(numericId)
    local custom = {
        Id = id,
        NumericId = numericId,
        Name = Locale.Lookup("LOC_CAI_WORLD_SCANNER_CUSTOM_DEFAULT_NAME", defaultNameNumber),
        Selectors = {},
        Include = {},
        Exclude = {},
    }
    if m_definitionsById[seedCategoryId] ~= nil then
        custom.Selectors[seedCategoryId] = { All = true, Subs = {} }
    end
    m_customs[#m_customs + 1] = custom
    m_customsById[id] = custom
    table.insert(m_order, 1, id)
    C.SetEnabled(id, true)
    SaveCustom(custom)
    SaveOrder()
    return custom
end

function C.DeleteCustom(id)
    local custom = m_customsById[id]
    if custom == nil then return false end
    for index = #m_customs, 1, -1 do
        if m_customs[index] == custom then table.remove(m_customs, index) end
    end
    local orderIndex = FindOrderIndex(id)
    if orderIndex ~= nil then table.remove(m_order, orderIndex) end
    m_customsById[id] = nil
    SetValue(CustomActiveKey(custom.NumericId), "false")
    SaveOrder()
    return true
end

function C.RenameCustom(id, name)
    local custom = m_customsById[id]
    local trimmed = Trim(name)
    if custom == nil or trimmed == "" then return false end
    custom.Name = trimmed
    SetValue(CustomNameKey(custom.NumericId), trimmed)
    return true
end

function C.IsAllSelected(customId, categoryId)
    local custom = m_customsById[customId]
    local selection = custom and custom.Selectors[categoryId] or nil
    return selection ~= nil and selection.All == true
end

function C.IsSubSelected(customId, categoryId, subCategoryId)
    local custom = m_customsById[customId]
    local selection = custom and custom.Selectors[categoryId] or nil
    return selection ~= nil and (selection.All or selection.Subs[subCategoryId] == true) or false
end

function C.SetAllSelected(customId, categoryId, selected)
    local custom = m_customsById[customId]
    if custom == nil or m_definitionsById[categoryId] == nil then return false end
    if selected then
        custom.Selectors[categoryId] = { All = true, Subs = {} }
    else
        custom.Selectors[categoryId] = nil
    end
    SaveSelectors(custom)
    return true
end

function C.SetSubSelected(customId, categoryId, subCategoryId, selected)
    local custom = m_customsById[customId]
    local definition = m_definitionsById[categoryId]
    if custom == nil or definition == nil then return false end
    local selection = custom.Selectors[categoryId]
    if selection == nil then
        selection = { All = false, Subs = {} }
        custom.Selectors[categoryId] = selection
    end
    if selection.All then
        selection.All = false
        for _, id in ipairs(definition.SubCategoryOrder or {}) do selection.Subs[id] = true end
    end
    selection.Subs[subCategoryId] = selected and true or nil
    if next(selection.Subs) == nil then custom.Selectors[categoryId] = nil end
    SaveSelectors(custom)
    return true
end

function C.ValidateTerm(customId, kind, value)
    local custom = m_customsById[customId]
    local term = Trim(value)
    local terms = custom and custom[kind] or nil
    if terms == nil or term == "" then return false, "empty" end
    local lower = term:lower()
    for _, existing in ipairs(terms) do
        if existing:lower() == lower then return false, "duplicate" end
    end
    return true, nil
end

function C.AddTerm(customId, kind, value)
    local valid = C.ValidateTerm(customId, kind, value)
    if not valid then return false end
    local custom = m_customsById[customId]
    local term = Trim(value)
    local terms = custom[kind]
    terms[#terms + 1] = term
    SaveTerms(custom, kind)
    return true
end

function C.RemoveTerm(customId, kind, termIndex)
    local custom = m_customsById[customId]
    local terms = custom and custom[kind] or nil
    if terms == nil or terms[termIndex] == nil then return false end
    table.remove(terms, termIndex)
    SaveTerms(custom, kind)
    return true
end

local function LeafMatchesSubCategory(sourceCategory, leafId, subCategoryId)
    local memberships = sourceCategory.LeafMemberships and sourceCategory.LeafMemberships[leafId] or nil
    for _, membership in ipairs(memberships or {}) do
        if membership.SubCategory.Id == subCategoryId then return true end
    end
    return false
end

local function MatchesAnyTerm(label, terms)
    for _, term in ipairs(terms or {}) do
        if CAIWidgetHelpers_Search.MatchSearchText(label, term) ~= nil then return true end
    end
    return false
end

local function AddUnique(values, seen, value)
    if value ~= nil and not seen[value] then
        values[#values + 1] = value
        seen[value] = true
    end
end

local function BuildCustomCategory(custom, sourceCategories, context, core)
    local subCategoryOrder = {}
    local subCategoryLabels = {}
    for _, definition in ipairs(OrderedDefinitions()) do
        local selection = custom.Selectors[definition.Id]
        if selection ~= nil then
            if selection.All then
                local id = "source:" .. definition.Id .. ":__all"
                subCategoryOrder[#subCategoryOrder + 1] = id
                subCategoryLabels[id] = definition.LabelKey
            else
                for _, sourceSubId in ipairs(definition.SubCategoryOrder or {}) do
                    if selection.Subs[sourceSubId] then
                        local id = "source:" .. definition.Id .. ":" .. sourceSubId
                        subCategoryOrder[#subCategoryOrder + 1] = id
                        subCategoryLabels[id] = definition.SubCategoryLabels[sourceSubId]
                    end
                end
            end
        end
    end
    for index, term in ipairs(custom.Include) do
        local id = "include:" .. tostring(index)
        subCategoryOrder[#subCategoryOrder + 1] = id
        subCategoryLabels[id] = term
    end

    local definition = {
        Id = custom.Id,
        LabelKey = custom.Name,
        SubCategoryOrder = subCategoryOrder,
        SubCategoryLabels = subCategoryLabels,
        GroupLabelResolver = function(_, firstItem)
            return firstItem and firstItem.ProjectedGroupLabelKey or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
        end,
    }
    local rawItems = {}
    for _, sourceDefinition in ipairs(OrderedDefinitions()) do
        local sourceCategory = sourceCategories[sourceDefinition.Id]
        if sourceCategory ~= nil then
            local allSub = sourceCategory.SubCategories and sourceCategory.SubCategories[1] or nil
            if allSub ~= nil and allSub.Id == core.AllSubCategoryId then
                for _, group in ipairs(allSub.Groups or {}) do
                    for _, leaf in ipairs(group.Items or {}) do
                        local label = leaf.ResolvedLabel or Locale.Lookup(leaf.LabelKey)
                        if not MatchesAnyTerm(label, custom.Exclude) then
                            local matchedIds = {}
                            local matchedSet = {}
                            local selection = custom.Selectors[sourceDefinition.Id]
                            if selection ~= nil then
                                if selection.All then
                                    AddUnique(matchedIds, matchedSet,
                                        "source:" .. sourceDefinition.Id .. ":__all")
                                else
                                    for _, sourceSubId in ipairs(sourceDefinition.SubCategoryOrder or {}) do
                                        if selection.Subs[sourceSubId]
                                            and LeafMatchesSubCategory(sourceCategory, leaf.Id, sourceSubId) then
                                            AddUnique(matchedIds, matchedSet,
                                                "source:" .. sourceDefinition.Id .. ":" .. sourceSubId)
                                        end
                                    end
                                end
                            end
                            for index, term in ipairs(custom.Include) do
                                if CAIWidgetHelpers_Search.MatchSearchText(label, term) ~= nil then
                                    AddUnique(matchedIds, matchedSet, "include:" .. tostring(index))
                                end
                            end
                            if #matchedIds > 0 then
                                local sourceItem = leaf.Item
                                local projected = {}
                                for key, value in pairs(sourceItem or {}) do projected[key] = value end
                                projected.Id = custom.Id .. "|" .. sourceDefinition.Id .. "|" .. tostring(leaf.Id)
                                projected.SourceItemId = leaf.Id
                                projected.PlotIndex = leaf.PlotIndex
                                projected.LabelKey = leaf.LabelKey
                                projected.SubCategoryId = nil
                                projected.SubCategoryIds = matchedIds
                                projected.GroupId = sourceDefinition.Id .. "|" .. tostring(group.Id)
                                projected.ProjectedGroupLabelKey = group.LabelKey
                                if sourceItem ~= nil and sourceItem.Validate ~= nil then
                                    local sourceValidator = sourceItem.Validate
                                    projected.Validate = function(_, validateContext)
                                        return sourceValidator(sourceItem, validateContext)
                                    end
                                end
                                rawItems[#rawItems + 1] = projected
                            end
                        end
                    end
                end
            end
        end
    end
    return core.BuildCategoryFromItems(definition, rawItems, context)
end

function C.BuildCustomCategories(sourceCategories, context, core)
    local results = {}
    for _, custom in ipairs(m_customs) do
        if C.IsEnabled(custom.Id) then
            results[custom.Id] = BuildCustomCategory(custom, sourceCategories, context, core)
        end
    end
    return results
end
