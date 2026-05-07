-- Shared in-game CAI formatting and widget helpers used by ResearchChooser_CAI,
-- TechTree_CAI, CivicsChooser_CAI, CivicsTree_CAI, and ProductionPanel_CAI.
-- Defined as plain globals; _G is per-context in Civ VI Lua, so each consumer
-- still has to include this file to make the helpers visible in its context.
--
-- Widget builders take `mgr` as their first arg (the caller's
-- ExposedMembers.CAI_UIManager) so they work in any screen context regardless
-- of which local `mgr` variable is in scope.

-- ===========================================================================
-- Pure string utilities
-- ===========================================================================

function AppendIfNonEmpty(parts, text)
    if text and text ~= "" then table.insert(parts, text) end
end

function NormalizeFormattedText(text)
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%s+", " ")
    return text
end

function SplitFormattedLines(text)
    local lines = {}
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    for line in string.gmatch(text, "([^\n]+)") do
        local trimmed = string.gsub(line, "^%s*(.-)%s*$", "%1")
        if trimmed ~= "" then
            table.insert(lines, trimmed)
        end
    end
    return lines
end

function StartsWithIconBullet(text)
    return text and string.find(text, "^%s*%[ICON_Bullet%]") ~= nil
end

function IsUnlocksHeader(text)
    if not text or text == "" then return false end
    local label = Locale.Lookup("LOC_TOOLTIP_UNLOCKS")
    return label and label ~= "" and string.find(text, label, 1, true) ~= nil
end

function IsMakesObsoleteHeader(text)
    if not text or text == "" then return false end
    local label = Locale.Lookup("LOC_TOOLTIP_MAKES_OBSOLETE")
    return label and label ~= "" and string.find(text, label, 1, true) ~= nil
end

-- Tech/research tooltips: drop the Unlocks header and its bullet rows so the
-- expandable unlocks node doesn't duplicate them.
function SplitTooltipLinesWithoutUnlocks(text)
    local lines = {}
    local skippingUnlocks = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) then
            skippingUnlocks = true
        elseif skippingUnlocks and StartsWithIconBullet(line) then
            -- handled by AddTechUnlocksNode
        else
            skippingUnlocks = false
            table.insert(lines, line)
        end
    end
    return lines
end

-- Civic tooltips: drop both the Unlocks and Makes Obsolete headers and their
-- bullet rows so the expandable unlocks/obsolete nodes don't duplicate them.
function SplitTooltipLinesWithoutSpecialLists(text)
    local lines = {}
    local skippingList = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) or IsMakesObsoleteHeader(line) then
            skippingList = true
        elseif skippingList and StartsWithIconBullet(line) then
            -- handled by AddCivicUnlocksNode / AddMakesObsoleteNode
        else
            skippingList = false
            table.insert(lines, line)
        end
    end
    return lines
end

-- ===========================================================================
-- Domain queries
-- ===========================================================================

function GetTechUnlockNames(kData)
    local techType = kData and (kData.TechType or kData.Type)
    if not techType then return {} end
    local playerID = Game.GetLocalPlayer()
    local unlockables = GetUnlockablesForTech_Cached(techType, playerID) or {}
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
end

local function GetCivicUnlockables(kData)
    local civicType = kData and (kData.CivicType or kData.Type)
    if not civicType then return {} end
    local playerID = Game.GetLocalPlayer()
    return GetUnlockablesForCivic_Cached(civicType, playerID) or {}
end

function GetCivicUnlockNames(kData)
    local unlockables = GetCivicUnlockables(kData)
    local names = {}
    for _, v in ipairs(unlockables) do
        local name = v[2]
        if name and name ~= "" then
            table.insert(names, Locale.Lookup(name))
        end
    end
    return names
end

function GetObsoletePolicyNames(kData)
    local unlockables = GetCivicUnlockables(kData)
    local unlockableIndex = {}
    for _, v in ipairs(unlockables) do
        unlockableIndex[v[1]] = true
    end

    local obsoleteNames = {}
    for row in GameInfo.ObsoletePolicies() do
        if unlockableIndex[row.ObsoletePolicy] then
            local policy = GameInfo.Policies[row.PolicyType]
            if policy then
                table.insert(obsoleteNames, Locale.Lookup("LOC_TOOLTIP_UNLOCKS_POLICY", policy.Name))
            end
        end
    end
    table.sort(obsoleteNames, function(a, b) return Locale.Compare(a, b) == -1 end)
    return obsoleteNames
end

-- ===========================================================================
-- Widget builders
-- ===========================================================================

function AddTextDetailNode(mgr, parent, text)
    if not text or text == "" then return end
    local detailText = text
    parent:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIDetailNode"), "TreeviewItem", {
        GetLabel = function() return NormalizeFormattedText(detailText) end,
    }))
end

-- Generic counted expandable list node. `items` is a list of strings; the parent
-- gets one TreeviewItem child whose label is `locOne` (with count = 1) or
-- `locMany` (with count = N), and whose children are one TreeviewItem per item.
function AddCountedListNode(mgr, parent, items, widgetIdPrefix, locOne, locMany)
    local count = items and #items or 0
    if count <= 0 then return end

    local node = mgr:CreateUIWidget(mgr:GenerateWidgetId(widgetIdPrefix), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then return Locale.Lookup(locOne, count) end
            return Locale.Lookup(locMany, count)
        end,
    })

    for _, text in ipairs(items) do
        local itemText = text
        node:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId(widgetIdPrefix .. "Item"), "TreeviewItem", {
            GetLabel = function() return NormalizeFormattedText(itemText) end,
        }))
    end

    parent:AddChild(node)
end

function AddTechUnlocksNode(mgr, parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_RESEARCH_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlock"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchUnlock"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_RESEARCH_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

function AddCivicUnlocksNode(mgr, parent, unlockNames)
    local count = #unlockNames
    local unlockNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlocks"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_UNLOCKS_COUNT", count)
        end,
    })

    if count > 0 then
        for _, name in ipairs(unlockNames) do
            local unlockName = name
            unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlockItem"), "TreeviewItem", {
                GetLabel = function() return unlockName end,
            }))
        end
    else
        unlockNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicUnlockItem"), "TreeviewItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_CIVIC_NO_UNLOCKS") end,
        }))
    end

    parent:AddChild(unlockNode)
end

function AddMakesObsoleteNode(mgr, parent, obsoleteNames)
    local count = #obsoleteNames
    if count <= 0 then return end

    local obsoleteNode = mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicObsolete"), "TreeviewItem", {
        GetLabel = function()
            if count == 1 then
                return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT_ONE", count)
            end
            return Locale.Lookup("LOC_CAI_CIVIC_MAKES_OBSOLETE_COUNT", count)
        end,
    })

    for _, name in ipairs(obsoleteNames) do
        local obsoleteName = name
        obsoleteNode:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAICivicObsoleteItem"), "TreeviewItem", {
            GetLabel = function() return obsoleteName end,
        }))
    end

    parent:AddChild(obsoleteNode)
end
