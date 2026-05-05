-- Shared research/tech formatting and widget helpers used by ResearchChooser_CAI
-- and TechTree_CAI. Defined as plain globals; _G is per-context in Civ VI Lua,
-- so there is no shared-namespace risk.
--
-- Widget builders take `mgr` as their first arg so they work in either screen
-- context regardless of which local `mgr` variable is in scope.

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

function SplitTooltipLinesWithoutUnlocks(text)
    local lines = {}
    local skippingUnlocks = false
    for _, line in ipairs(SplitFormattedLines(text)) do
        if IsUnlocksHeader(line) then
            skippingUnlocks = true
        elseif skippingUnlocks and StartsWithIconBullet(line) then
            -- Unlock rows live in the dedicated expandable unlock node.
        else
            skippingUnlocks = false
            table.insert(lines, line)
        end
    end
    return lines
end

-- ===========================================================================
-- Data queries
-- ===========================================================================

function GetUnlockNames(kData)
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

-- ===========================================================================
-- Widget builders
-- Each function takes `mgr` as first arg (the caller's ExposedMembers.CAI_UIManager)
-- so they work in any screen context.
-- ===========================================================================

function AddTextDetailNode(mgr, parent, text)
    if not text or text == "" then return end
    local detailText = text
    parent:AddChild(mgr:CreateUIWidget(mgr:GenerateWidgetId("CAIResearchDetail"), "TreeviewItem", {
        GetLabel = function() return NormalizeFormattedText(detailText) end,
    }))
end

function AddUnlocksNode(mgr, parent, unlockNames)
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
