-- ===========================================================================
--  WorldBuilderPlacement_CAI
--  Accessible tool & item picker for the World Builder Placement panel.
--
--  Structure (one pushed Panel):
--    * a List of the 16 placement tools; focus-entering a tool row arms it
--      (drives the vanilla mode change) and Enter on a tool row closes the
--      panel back to the map cursor.
--    * a settings region that rebuilds to match the armed tool: the item-type
--      Dropdown first, then that tool's extra parameters (brush size, feature
--      rotation, resource amount / generate / clear, pillaged flags, and the
--      owner / player / continent / route dropdowns). Every choice field is a
--      Dropdown so navigating options never commits by accident; only opening a
--      dropdown and activating an option changes the selection.
--
--  This cut is the picker + host only. Placing on the map cursor (the
--  place/delete keys and brush/paint-mode) is handled separately in the world
--  input layer and is intentionally not wired here.
--
--  Selection mechanism: vanilla keeps every tool's item list and SelectedIndex
--  in file-locals with no public setter, so we wrap the global MakeItem to
--  capture each grid tool's per-item select-closure + localized label as the
--  vanilla grid is (re)built, and drive the pulldown-backed tools through their
--  real Controls.
-- ===========================================================================

include("caiUtils")
include("Civ6Common") -- IsExpansion2Active
include("WorldBuilderPlacement")

local mgr = ExposedMembers.CAI_UIManager

-- Shared CAI cross-context query table. interfaceInfoHelpers_CAI runs in the
-- WorldInput context and cannot reach PlacementValid / the placement pulldown
-- (both live in this context), so the placement-validity query is published here
-- for it to call. Reassigned fresh each load per [[project_exposedmembers_reload_stale]].
local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local PANEL_ID = "CAIWorldBuilderTools_Panel"

-- Vanilla plays no distinct sound when a tool or item is selected; it uses the
-- standard menu hover sound on mouse-over (MakeTool / MakeItem). Mirror that as
-- the focus sound so navigating the picker feels like the rest of CAI.
local FOCUS_SOUND = "Main_Menu_Mouse_Over"

-- The 16 tools in vanilla advanced order (CAI always runs advanced). Names are
-- the vanilla localization tags; the improvements slot is the full improvements
-- list, not the basic-mode goody-huts label.
local CAI_TOOLS = {
    { ID = WorldBuilderModes.PLACE_TERRAIN,         Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_TERRAIN" },
    { ID = WorldBuilderModes.PLACE_FEATURES,        Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_FEATURES" },
    { ID = WorldBuilderModes.PLACE_WONDERS,         Text = "LOC_HUD_CITY_WONDERS" }, -- placement-mode wonders tag has no localized text; matches the vanilla tools palette
    { ID = WorldBuilderModes.PLACE_CONTINENTS,      Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_CONTINENT" },
    { ID = WorldBuilderModes.PLACE_RIVERS,          Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_RIVERS" },
    { ID = WorldBuilderModes.PLACE_CLIFFS,          Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_CLIFFS" },
    { ID = WorldBuilderModes.PLACE_RESOURCES,       Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_RESOURCES" },
    { ID = WorldBuilderModes.PLACE_CITIES,          Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_CITIES" },
    { ID = WorldBuilderModes.PLACE_DISTRICTS,       Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_DISTRICTS" },
    { ID = WorldBuilderModes.PLACE_BUILDINGS,       Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_BUILDINGS" },
    { ID = WorldBuilderModes.PLACE_UNITS,           Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_UNITS" },
    { ID = WorldBuilderModes.PLACE_IMPROVEMENTS,    Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_IMPROVEMENTS" },
    { ID = WorldBuilderModes.PLACE_ROUTES,          Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_ROUTES" },
    { ID = WorldBuilderModes.PLACE_START_POSITIONS, Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_START_POSITIONS" },
    { ID = WorldBuilderModes.PLACE_TERRAIN_OWNER,   Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_OWNER" },
    { ID = WorldBuilderModes.SET_VISIBILITY,        Text = "LOC_WORLDBUILDER_PLACEMENT_MODE_SET_VISIBILITY" },
}

-- Brush size cycle, matching vanilla's Small/Medium/Large (1 / 7 / 19 hexes).
local BRUSH_SIZES = {
    { size = 1,  button = "SmallBrushButton",  label = "LOC_CAI_WB_BRUSH_SMALL" },
    { size = 7,  button = "MediumBrushButton", label = "LOC_CAI_WB_BRUSH_MEDIUM" },
    { size = 19, button = "LargeBrushButton",  label = "LOC_CAI_WB_BRUSH_LARGE" },
}

-- Feature rotation states in vanilla's OnRotateRight cycle order (Auto-fit, then
-- the six directions). Vanilla exposes only OnRotateLeft/Right, so a dropdown
-- commit steps OnRotateRight the needed number of times.
local ROTATION_STATES = {
    "LOC_WORLDBUILDER_AUTO_FIT",
    "LOC_WORLDBUILDER_DIRECTION_NORTHEAST",
    "LOC_WORLDBUILDER_DIRECTION_EAST",
    "LOC_WORLDBUILDER_DIRECTION_SOUTHEAST",
    "LOC_WORLDBUILDER_DIRECTION_SOUTHWEST",
    "LOC_WORLDBUILDER_DIRECTION_WEST",
    "LOC_WORLDBUILDER_DIRECTION_NORTHWEST",
}

-- Edge directions for the Rivers / Cliffs tools, ordered to match DirectionTypes
-- (0 = NORTHEAST .. 5 = NORTHWEST) so the index doubles as the edge value passed
-- to EditRiver / EditCliff. Vanilla picks the edge from the mouse-nearest plot
-- edge; CAI has no cursor edge, so the direction is an explicit parameter here
-- and is fed to placement through info.GetWorldBuilderEdgeDirection (below).
local DIRECTION_TAGS = {
    "LOC_WORLDBUILDER_DIRECTION_NORTHEAST",
    "LOC_WORLDBUILDER_DIRECTION_EAST",
    "LOC_WORLDBUILDER_DIRECTION_SOUTHEAST",
    "LOC_WORLDBUILDER_DIRECTION_SOUTHWEST",
    "LOC_WORLDBUILDER_DIRECTION_WEST",
    "LOC_WORLDBUILDER_DIRECTION_NORTHWEST",
}

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local m_panel            = nil   -- pushed root Panel
local m_toolList         = nil   -- List of the 16 tools
local m_settings         = nil   -- transparent container for the armed tool's fields
local m_settingsWidgets  = {}    -- current settings child widgets (for teardown)
local m_capture          = {}    -- per-grid-tool captured items: { idx, label, select, uiItem }
local m_brushIndex       = 1     -- CAI-tracked brush size index into BRUSH_SIZES
local m_rotationIndex    = 0     -- CAI-tracked rotation index into ROTATION_STATES (0-based; 0 = Auto-fit)
local m_edgeIndex        = 0     -- CAI-tracked Rivers/Cliffs edge direction (0-based DirectionTypes; 0 = NE)
local m_qnIndex          = 1     -- Quick-nav parameter cursor (1-based; 1 = the tool parameter)

-- ===========================================================================
--  Vanilla data re-derivation (for the pulldown-backed tools). Order mirrors
--  the vanilla population loops so a CAI dropdown index maps 1:1 onto the
--  vanilla pulldown index we commit through SetSelectedIndex.
-- ===========================================================================

local function DeriveContinents()
    local options = {}
    for row in GameInfo.Continents() do
        options[#options + 1] = { label = Locale.Lookup(row.Description), value = #options + 1 }
    end
    return options
end

local function DeriveRoutes()
    local options = {}
    for row in GameInfo.Routes() do
        options[#options + 1] = { label = Locale.Lookup(row.Name), value = #options + 1 }
    end
    return options
end

-- scenarioOnly mirrors m_ScenarioPlayerEntries (players with a fixed civ);
-- otherwise mirrors m_PlayerEntries (every non-barbarian, non-closed slot).
local function DerivePlayers(scenarioOnly)
    local options = {}
    for i = 0, GameDefines.MAX_PLAYERS - 1 do
        local eStatus = WorldBuilder.PlayerManager():GetSlotStatus(i)
        if eStatus ~= SlotStatus.SS_CLOSED then
            local playerConfig = WorldBuilder.PlayerManager():GetPlayerConfig(i)
            if playerConfig.IsBarbarian == false then
                if (not scenarioOnly) or playerConfig.Civ ~= nil then
                    options[#options + 1] = { label = Locale.Lookup(playerConfig.Name), value = #options + 1 }
                end
            end
        end
    end
    return options
end

-- Mirrors vanilla UpdateCityEntries: OwnerPullDown's authoritative source. Every
-- city of every player, in player then city order; a plot's owner is a city.
local function DeriveCities()
    local options = {}
    for iPlayer = 0, GameDefines.MAX_PLAYERS - 1 do
        local player = Players[iPlayer]
        local cities = player and player:GetCities()
        if cities ~= nil then
            for _, city in cities:Members() do
                options[#options + 1] = { label = Locale.Lookup(city:GetName()), value = #options + 1 }
            end
        end
    end
    return options
end

-- ===========================================================================
--  Settings field builders. Each returns a widget already added to m_settings.
-- ===========================================================================

local function TrackSettingsWidget(w)
    w:SetFocusSound(FOCUS_SOUND)
    m_settingsWidgets[#m_settingsWidgets + 1] = w
    m_settings:AddChild(w)
    return w
end

-- The item-type picker for a grid tool: a Dropdown built from the captured item
-- closures. A dropdown (rather than a list that commits on focus-enter) means
-- navigating the items never changes the selection; only opening it and
-- activating an option commits, matching the owner/player dropdowns. Seeds to the
-- item vanilla currently has selected (its Active overlay is shown).
local function BuildTypeDropdown(toolID)
    local options = {}
    local selectByValue = {}
    local selectedPos = nil
    for i, item in ipairs(m_capture) do
        options[i] = { label = item.label, value = item.idx }
        selectByValue[item.idx] = item.select
        local ui = item.uiItem
        if ui ~= nil and ui.Active ~= nil and not ui.Active:IsHidden() then
            selectedPos = i
        end
    end

    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Type"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_TYPE") end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(selectedPos or 1, true)
    dd:On("value_changed", function(_, value)
        local select = selectByValue[value]
        if select ~= nil then select(value) end
    end)
    TrackSettingsWidget(dd)
    return dd
end

-- Owner / player selection: always a Dropdown. options are {label,value}; value
-- is the 1-based vanilla entry index committed through SetSelectedIndex.
local function BuildPulldownDropdown(toolID, labelTag, options, vanillaPulldown)
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_DD"), "Dropdown", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(1, true)
    dd:On("value_changed", function(_, value)
        if vanillaPulldown ~= nil then
            vanillaPulldown:SetSelectedIndex(value, true)
        end
    end)
    TrackSettingsWidget(dd)
    return dd
end

-- Brush size dropdown. Only offered for Terrain/Continents, where vanilla enables
-- the brush; committed through the vanilla brush buttons.
local function BuildBrushField()
    local options = {}
    for i, entry in ipairs(BRUSH_SIZES) do
        options[i] = { label = Locale.Lookup(entry.label), value = i }
    end
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Brush"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_BRUSH") end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(m_brushIndex, true)
    dd:On("value_changed", function(_, value)
        m_brushIndex = value
        Controls[BRUSH_SIZES[value].button]:DoLeftClick()
    end)
    TrackSettingsWidget(dd)
    return dd
end

-- Feature rotation dropdown. Vanilla exposes only OnRotateLeft/Right, so a commit
-- steps OnRotateRight forward the needed number of times.
local function BuildRotationField()
    local options = {}
    for i, tag in ipairs(ROTATION_STATES) do
        options[i] = { label = Locale.Lookup(tag), value = i }
    end
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Rotate"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_ROTATION") end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(m_rotationIndex + 1, true)
    dd:On("value_changed", function(_, value)
        local steps = (value - 1 - m_rotationIndex) % #ROTATION_STATES
        for _ = 1, steps do OnRotateRight() end
        m_rotationIndex = value - 1
    end)
    TrackSettingsWidget(dd)
    return dd
end

-- Edge-direction dropdown for the Rivers / Cliffs tools. Purely CAI state
-- (m_edgeIndex); vanilla has no direction control. The chosen edge is read at
-- placement time through info.GetWorldBuilderEdgeDirection.
local function BuildDirectionField()
    local options = {}
    for i, tag in ipairs(DIRECTION_TAGS) do
        options[i] = { label = Locale.Lookup(tag), value = i }
    end
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Direction"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_DIRECTION") end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(m_edgeIndex + 1, true)
    dd:On("value_changed", function(_, value)
        m_edgeIndex = value - 1
    end)
    TrackSettingsWidget(dd)
    return dd
end

-- Strategic resource amount. Hidden by vanilla for non-strategic resources; the
-- hidden predicate lets navigation skip it live.
local function BuildAmountField()
    local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Amount"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_AMOUNT") end,
    })
    edit:SetText(Controls.ResourceAmount:GetText() or "", true)
    edit:SetValueSetter(function(_, text) Controls.ResourceAmount:SetText(text) end)
    edit:SetHiddenPredicate(function() return Controls.ResourceAmountStack:IsHidden() end)
    TrackSettingsWidget(edit)
    return edit
end

local function BuildButtonField(labelTag, vanillaButtonName, onAfter)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Btn"), "Button", {
        Label = function()
            local vanilla = Controls[vanillaButtonName]
            local text = vanilla and vanilla:GetText()
            if text ~= nil and text ~= "" then return text end
            return Locale.Lookup(labelTag)
        end,
    })
    btn:On("activate", function()
        Controls[vanillaButtonName]:DoLeftClick()
        if onAfter ~= nil then onAfter() end
    end)
    TrackSettingsWidget(btn)
    return btn
end

local function BuildPillagedField(vanillaCheckName)
    local vanillaCheck = Controls[vanillaCheckName]
    local check = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Pillaged"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_PILLAGED") end,
    })
    check:SetChecked(vanillaCheck:IsChecked(), true)
    check:SetValueSetter(function(_, v)
        if vanillaCheck:IsChecked() ~= v then vanillaCheck:DoLeftClick() end
    end)
    TrackSettingsWidget(check)
    return check
end

-- ===========================================================================
--  Settings region rebuild
-- ===========================================================================

local function ClearSettings()
    for _, w in ipairs(m_settingsWidgets) do
        w:Destroy()
    end
    m_settingsWidgets = {}
end

-- Rebuilds the settings region for the currently armed tool. Grid tools show
-- the captured item list first; every tool then shows its specific extras.
local function RebuildSettings()
    if not m_panel or not m_settings then return end

    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode == nil then return end
    local toolID = mode.ID

    ClearSettings()

    if toolID == WorldBuilderModes.PLACE_TERRAIN then
        BuildTypeDropdown(toolID)
        BuildBrushField()
    elseif toolID == WorldBuilderModes.PLACE_FEATURES then
        BuildTypeDropdown(toolID)
        BuildRotationField()
    elseif toolID == WorldBuilderModes.PLACE_WONDERS then
        BuildTypeDropdown(toolID)
        BuildRotationField()
    elseif toolID == WorldBuilderModes.PLACE_RESOURCES then
        BuildTypeDropdown(toolID)
        BuildAmountField()
        BuildButtonField("LOC_CAI_WB_GENERATE", "GenResourcesButton")
        BuildButtonField("LOC_CAI_WB_CLEAR", "RegenResourcesButton")
    elseif toolID == WorldBuilderModes.PLACE_IMPROVEMENTS then
        BuildTypeDropdown(toolID)
        BuildPillagedField("ImprovementPillagedCheck")
    elseif toolID == WorldBuilderModes.PLACE_DISTRICTS then
        BuildTypeDropdown(toolID)
        BuildPillagedField("DistrictPillagedCheck")
    elseif toolID == WorldBuilderModes.PLACE_BUILDINGS then
        BuildTypeDropdown(toolID)
    elseif toolID == WorldBuilderModes.PLACE_UNITS then
        BuildTypeDropdown(toolID)
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_OWNER", DerivePlayers(true), Controls.UnitOwnerPullDown)
    elseif toolID == WorldBuilderModes.PLACE_CONTINENTS then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_CONTINENT", DeriveContinents(), Controls.ContinentPullDown)
        BuildBrushField()
    elseif toolID == WorldBuilderModes.PLACE_ROUTES then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_TYPE", DeriveRoutes(), Controls.RoutePullDown)
        BuildPillagedField("RoutePillagedCheck")
    elseif toolID == WorldBuilderModes.PLACE_CITIES then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_OWNER", DerivePlayers(true), Controls.CityOwnerPullDown)
    elseif toolID == WorldBuilderModes.PLACE_START_POSITIONS then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_PLAYER", DerivePlayers(false), Controls.StartPosPlayerPulldown)
    elseif toolID == WorldBuilderModes.PLACE_TERRAIN_OWNER then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_OWNER", DeriveCities(), Controls.OwnerPullDown)
    elseif toolID == WorldBuilderModes.SET_VISIBILITY then
        BuildPulldownDropdown(toolID, "LOC_CAI_WB_PLAYER", DerivePlayers(true), Controls.VisibilityPullDown)
        -- Drives the vanilla Reveal All button; that edit only reaches the map
        -- database on save, so mirror the whole-map reveal into the visibility
        -- model for the selected player so live readout updates immediately.
        BuildButtonField("LOC_CAI_WB_REVEAL_ALL", "VisibilityRevealAllButton", function()
            local visMgr = ExposedMembers.CAI_WBVisManager
            if visMgr ~= nil and visMgr.SetRevealedAll ~= nil then
                local visPlayer = info.GetWorldBuilderVisibilityPlayer()
                if visPlayer ~= nil then
                    visMgr.SetRevealedAll(visPlayer, true)
                end
            end
        end)
    elseif toolID == WorldBuilderModes.PLACE_RIVERS or toolID == WorldBuilderModes.PLACE_CLIFFS then
        -- CAI-only direction parameter (vanilla uses the mouse-nearest edge).
        BuildDirectionField()
    end
end

-- ===========================================================================
--  Panel build / open / close
-- ===========================================================================

local function ArmTool(toolID)
    -- Drives the vanilla mode change; the wrapped OnPlacementTypeSelected then
    -- rebuilds our settings region for this tool.
    OnToolSelectMode(toolID)
end

-- ---------------------------------------------------------------------------
-- Tool-row parameter readout. A tool row speaks the tool name followed by every
-- parameter currently selected for that tool (type, owner/player/continent/route,
-- brush, rotation, resource amount, pillaged), so the row always reflects the
-- full selection rather than only the last field changed. Read live from vanilla
-- state so it is correct on first open without the user touching anything.
--
-- Only the focused tool row's label is ever built, and focus-entering a row arms
-- its tool first (see the focus_enter handler), so m_capture and the vanilla
-- controls below always describe the tool whose label we are building.
-- ---------------------------------------------------------------------------

-- The captured grid item currently highlighted as selected (its Active overlay is
-- shown). Mirrors vanilla MakeItemGrid, which shows Active only on SelectedIndex.
local function SelectedTypeLabel()
    for _, item in ipairs(m_capture) do
        local ui = item.uiItem
        if ui ~= nil and ui.Active ~= nil and not ui.Active:IsHidden() then
            return item.label
        end
    end
    return nil
end

-- Localized display text of a vanilla pulldown's current entry.
local function PulldownLabel(pulldown)
    local entry = pulldown ~= nil and pulldown:GetSelectedEntry() or nil
    if entry ~= nil and entry.Text ~= nil then
        return Locale.Lookup(entry.Text)
    end
    return nil
end

-- Ordered list of the armed tool's selected-parameter strings (nil if none).
local function BuildToolParamString(toolID)
    local parts = {}
    local function add(s) if s ~= nil and s ~= "" then parts[#parts + 1] = s end end

    if toolID == WorldBuilderModes.PLACE_TERRAIN then
        add(SelectedTypeLabel())
        add(Locale.Lookup(BRUSH_SIZES[m_brushIndex].label))
    elseif toolID == WorldBuilderModes.PLACE_FEATURES or toolID == WorldBuilderModes.PLACE_WONDERS then
        add(SelectedTypeLabel())
        add(Locale.Lookup(ROTATION_STATES[m_rotationIndex + 1]))
    elseif toolID == WorldBuilderModes.PLACE_RESOURCES then
        add(SelectedTypeLabel())
        if not Controls.ResourceAmountStack:IsHidden() then add(Controls.ResourceAmount:GetText()) end
    elseif toolID == WorldBuilderModes.PLACE_IMPROVEMENTS then
        add(SelectedTypeLabel())
        if Controls.ImprovementPillagedCheck:IsChecked() then add(Locale.Lookup("LOC_CAI_WB_PILLAGED")) end
    elseif toolID == WorldBuilderModes.PLACE_DISTRICTS then
        add(SelectedTypeLabel())
        if Controls.DistrictPillagedCheck:IsChecked() then add(Locale.Lookup("LOC_CAI_WB_PILLAGED")) end
    elseif toolID == WorldBuilderModes.PLACE_BUILDINGS then
        add(SelectedTypeLabel())
    elseif toolID == WorldBuilderModes.PLACE_UNITS then
        add(SelectedTypeLabel())
        add(PulldownLabel(Controls.UnitOwnerPullDown))
    elseif toolID == WorldBuilderModes.PLACE_CONTINENTS then
        add(PulldownLabel(Controls.ContinentPullDown))
        add(Locale.Lookup(BRUSH_SIZES[m_brushIndex].label))
    elseif toolID == WorldBuilderModes.PLACE_ROUTES then
        add(PulldownLabel(Controls.RoutePullDown))
        if Controls.RoutePillagedCheck:IsChecked() then add(Locale.Lookup("LOC_CAI_WB_PILLAGED")) end
    elseif toolID == WorldBuilderModes.PLACE_CITIES then
        add(PulldownLabel(Controls.CityOwnerPullDown))
    elseif toolID == WorldBuilderModes.PLACE_START_POSITIONS then
        add(PulldownLabel(Controls.StartPosPlayerPulldown))
    elseif toolID == WorldBuilderModes.PLACE_TERRAIN_OWNER then
        add(PulldownLabel(Controls.OwnerPullDown))
    elseif toolID == WorldBuilderModes.SET_VISIBILITY then
        add(PulldownLabel(Controls.VisibilityPullDown))
    elseif toolID == WorldBuilderModes.PLACE_RIVERS or toolID == WorldBuilderModes.PLACE_CLIFFS then
        add(Locale.Lookup(DIRECTION_TAGS[m_edgeIndex + 1]))
    end

    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
end

-- ===========================================================================
--  Quick nav: arrow-key parameter cycling on the World Builder interface
-- ===========================================================================
-- An ambient, panel-free way to change the current tool and its parameters
-- straight from the map (the interface widget in WorldInput_CAI binds the arrow
-- keys and forwards them here as CAIWorldBuilderQuickNav). It shares all of its
-- state and vanilla drivers with the pushed tools panel above, so the two stay
-- in sync: Left / Right move between parameters (parameter 1 is always the tool,
-- 2..N are the armed tool's parameters), Up / Down change the focused
-- parameter's value, and Shift + arrow jumps to the first / last parameter or
-- list value. Speech is one line: switching a parameter speaks name + value,
-- changing a value speaks the new value.

-- Live tool id from the vanilla placement pulldown (the authoritative source).
local function CurrentToolID()
    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    return mode ~= nil and mode.ID or nil
end

-- Localized name of a tool id, from the CAI_TOOLS table.
local function ToolName(toolID)
    for _, tool in ipairs(CAI_TOOLS) do
        if tool.ID == toolID then return Locale.Lookup(tool.Text) end
    end
    return nil
end

-- Position of the currently armed tool within CAI_TOOLS (1-based; 1 on miss).
local function CurrentToolPos()
    local toolID = CurrentToolID()
    for i, tool in ipairs(CAI_TOOLS) do
        if tool.ID == toolID then return i end
    end
    return 1
end

-- Position of the captured grid item vanilla currently has selected (its Active
-- overlay is shown), or nil when none is highlighted.
local function GetSelectedTypePos()
    for i, item in ipairs(m_capture) do
        local ui = item.uiItem
        if ui ~= nil and ui.Active ~= nil and not ui.Active:IsHidden() then
            return i
        end
    end
    return nil
end

-- True when a +/-1 step at 1-based position `old` in a ring of `n` crosses an
-- end (used to fire the wrap sound). Callers with a 0-based index pass old + 1.
local function StepWraps(old, delta, n)
    if n <= 1 then return false end
    local new = ((old - 1 + delta) % n) + 1
    return (delta > 0 and new < old) or (delta < 0 and new > old)
end

-- Play the framework's list-wrap sound (the same one the manager plays for a
-- navigation_wrap). mgr is the shared singleton, so this works cross-context.
local function PlayWrapSound()
    if mgr ~= nil and mgr.HandleNavigationWrap ~= nil then
        mgr:HandleNavigationWrap()
    end
end

-- ---------------------------------------------------------------------------
-- Parameter descriptors. Each is { name, value, cycle(delta), jump(toLast)?,
-- nameSep?, listLike? }: name/value return localized strings; cycle steps the
-- value by delta and returns true when it wrapped past an end; jump (list-like
-- params only) goes to the first / last value (Shift + Up / Down). listLike
-- marks list / dropdown parameters, where Down advances and Up goes back (to
-- match the tools panel's list navigation); on amount / checkbox parameters Up
-- increases / turns on and Down decreases / turns off instead. nameSep is the
-- separator spoken between the name and value on a parameter switch (": " for
-- ordinary params; the tool parameter uses ", " because its value already reads
-- "<tool>: <params>").
-- ---------------------------------------------------------------------------

local function ToolParam()
    return {
        listLike = true,
        nameSep = ", ",
        name = function() return Locale.Lookup("LOC_CAI_WB_PARAM_TOOL") end,
        value = function()
            local toolID = CurrentToolID()
            local name = ToolName(toolID) or ""
            local params = BuildToolParamString(toolID)
            if params ~= nil then return name .. ": " .. params end
            return name
        end,
        cycle = function(delta)
            local n = #CAI_TOOLS
            local oldPos = CurrentToolPos()
            local newPos = ((oldPos - 1 + delta) % n) + 1
            ArmTool(CAI_TOOLS[newPos].ID)
            return StepWraps(oldPos, delta, n)
        end,
        jump = function(toLast)
            ArmTool(CAI_TOOLS[toLast and #CAI_TOOLS or 1].ID)
        end,
    }
end

local function TypeParam()
    return {
        listLike = true,
        name = function() return Locale.Lookup("LOC_CAI_WB_TYPE") end,
        value = function() return SelectedTypeLabel() end,
        cycle = function(delta)
            local n = #m_capture
            if n == 0 then return false end
            local oldPos = GetSelectedTypePos() or 1
            local newPos = ((oldPos - 1 + delta) % n) + 1
            local item = m_capture[newPos]
            if item ~= nil and item.select ~= nil then item.select(item.idx) end
            return StepWraps(oldPos, delta, n)
        end,
        jump = function(toLast)
            local n = #m_capture
            if n == 0 then return end
            local item = m_capture[toLast and n or 1]
            if item ~= nil and item.select ~= nil then item.select(item.idx) end
        end,
    }
end

local function PulldownParam(labelTag, pulldown, deriveFn)
    return {
        listLike = true,
        name = function() return Locale.Lookup(labelTag) end,
        value = function() return PulldownLabel(pulldown) end,
        cycle = function(delta)
            local n = #deriveFn()
            if n == 0 then return false end
            local cur = pulldown:GetSelectedIndex() or 1
            pulldown:SetSelectedIndex((((cur - 1) + delta) % n) + 1, true)
            return StepWraps(cur, delta, n)
        end,
        jump = function(toLast)
            local n = #deriveFn()
            if n == 0 then return end
            pulldown:SetSelectedIndex(toLast and n or 1, true)
        end,
    }
end

local function BrushParam()
    return {
        listLike = true,
        name = function() return Locale.Lookup("LOC_CAI_WB_BRUSH") end,
        value = function() return Locale.Lookup(BRUSH_SIZES[m_brushIndex].label) end,
        cycle = function(delta)
            local old = m_brushIndex
            m_brushIndex = ((m_brushIndex - 1 + delta) % #BRUSH_SIZES) + 1
            Controls[BRUSH_SIZES[m_brushIndex].button]:DoLeftClick()
            return StepWraps(old, delta, #BRUSH_SIZES)
        end,
        jump = function(toLast)
            m_brushIndex = toLast and #BRUSH_SIZES or 1
            Controls[BRUSH_SIZES[m_brushIndex].button]:DoLeftClick()
        end,
    }
end

-- Rotation and Direction are advanced one step at a time through the vanilla
-- OnRotateRight cycle (rotation) or by index (direction), so a jump replays the
-- forward steps needed to reach the first / last state.
local function RotationParam()
    local function stepTo(target)
        local n = #ROTATION_STATES
        local steps = (target - m_rotationIndex) % n
        for _ = 1, steps do OnRotateRight() end
        m_rotationIndex = target
    end
    return {
        listLike = true,
        name = function() return Locale.Lookup("LOC_CAI_WB_ROTATION") end,
        value = function() return Locale.Lookup(ROTATION_STATES[m_rotationIndex + 1]) end,
        cycle = function(delta)
            local old = m_rotationIndex
            stepTo((m_rotationIndex + delta) % #ROTATION_STATES)
            return StepWraps(old + 1, delta, #ROTATION_STATES)
        end,
        jump = function(toLast) stepTo(toLast and (#ROTATION_STATES - 1) or 0) end,
    }
end

local function DirectionParam()
    return {
        listLike = true,
        name = function() return Locale.Lookup("LOC_CAI_WB_DIRECTION") end,
        value = function() return Locale.Lookup(DIRECTION_TAGS[m_edgeIndex + 1]) end,
        cycle = function(delta)
            local old = m_edgeIndex
            m_edgeIndex = (m_edgeIndex + delta) % #DIRECTION_TAGS
            return StepWraps(old + 1, delta, #DIRECTION_TAGS)
        end,
        jump = function(toLast) m_edgeIndex = toLast and (#DIRECTION_TAGS - 1) or 0 end,
    }
end

-- Resource amount: an integer stepped by +/- 1 (no list jump). Committed by
-- setting the vanilla edit box, which PlaceResource reads at placement time.
local function AmountParam()
    return {
        name = function() return Locale.Lookup("LOC_CAI_WB_AMOUNT") end,
        value = function() return Controls.ResourceAmount:GetText() or "" end,
        cycle = function(delta)
            local v = (tonumber(Controls.ResourceAmount:GetText()) or 0) + delta
            if v < 0 then v = 0 end
            Controls.ResourceAmount:SetText(tostring(v))
        end,
    }
end

-- Pillaged flag: Up = on, Down = off (no list jump). Drives the vanilla checkbox.
local function PillagedParam(checkName)
    local check = Controls[checkName]
    return {
        name = function() return Locale.Lookup("LOC_CAI_WB_PILLAGED") end,
        value = function()
            return check:IsChecked()
                and Locale.Lookup("LOC_UIWidget_Checked")
                or Locale.Lookup("LOC_UIWidget_Unchecked")
        end,
        cycle = function(delta)
            local want = delta > 0
            if check:IsChecked() ~= want then check:DoLeftClick() end
        end,
    }
end

-- The ordered parameter list for a tool. Mirrors RebuildSettings (minus the
-- action buttons, which are not up/down values) so quick nav and the panel
-- expose the same parameters. Rebuilt on every keypress so live vanilla state
-- (e.g. the resource-amount field hidden for non-strategic resources) is honored.
local function BuildQuickNavParams(toolID)
    local params = { ToolParam() }
    local function add(d) params[#params + 1] = d end

    if toolID == WorldBuilderModes.PLACE_TERRAIN then
        add(TypeParam()); add(BrushParam())
    elseif toolID == WorldBuilderModes.PLACE_FEATURES then
        add(TypeParam()); add(RotationParam())
    elseif toolID == WorldBuilderModes.PLACE_WONDERS then
        add(TypeParam()); add(RotationParam())
    elseif toolID == WorldBuilderModes.PLACE_CONTINENTS then
        add(PulldownParam("LOC_CAI_WB_CONTINENT", Controls.ContinentPullDown, DeriveContinents))
        add(BrushParam())
    elseif toolID == WorldBuilderModes.PLACE_RIVERS or toolID == WorldBuilderModes.PLACE_CLIFFS then
        add(DirectionParam())
    elseif toolID == WorldBuilderModes.PLACE_RESOURCES then
        add(TypeParam())
        if not Controls.ResourceAmountStack:IsHidden() then add(AmountParam()) end
    elseif toolID == WorldBuilderModes.PLACE_IMPROVEMENTS then
        add(TypeParam()); add(PillagedParam("ImprovementPillagedCheck"))
    elseif toolID == WorldBuilderModes.PLACE_DISTRICTS then
        add(TypeParam()); add(PillagedParam("DistrictPillagedCheck"))
    elseif toolID == WorldBuilderModes.PLACE_BUILDINGS then
        add(TypeParam())
    elseif toolID == WorldBuilderModes.PLACE_UNITS then
        add(TypeParam())
        add(PulldownParam("LOC_CAI_WB_OWNER", Controls.UnitOwnerPullDown, function() return DerivePlayers(true) end))
    elseif toolID == WorldBuilderModes.PLACE_ROUTES then
        add(PulldownParam("LOC_CAI_WB_TYPE", Controls.RoutePullDown, DeriveRoutes))
        add(PillagedParam("RoutePillagedCheck"))
    elseif toolID == WorldBuilderModes.PLACE_CITIES then
        add(PulldownParam("LOC_CAI_WB_OWNER", Controls.CityOwnerPullDown, function() return DerivePlayers(true) end))
    elseif toolID == WorldBuilderModes.PLACE_START_POSITIONS then
        add(PulldownParam("LOC_CAI_WB_PLAYER", Controls.StartPosPlayerPulldown, function() return DerivePlayers(false) end))
    elseif toolID == WorldBuilderModes.PLACE_TERRAIN_OWNER then
        add(PulldownParam("LOC_CAI_WB_OWNER", Controls.OwnerPullDown, DeriveCities))
    elseif toolID == WorldBuilderModes.SET_VISIBILITY then
        add(PulldownParam("LOC_CAI_WB_PLAYER", Controls.VisibilityPullDown, function() return DerivePlayers(true) end))
    end

    return params
end

-- Speak a parameter's name and current value (on a parameter switch).
local function SpeakParamSwitch(param)
    local name = param.name()
    local value = param.value()
    if value ~= nil and value ~= "" then
        Speak(name .. (param.nameSep or ": ") .. value)
    else
        Speak(name)
    end
end

-- Speak only a parameter's current value (after an Up / Down / jump change).
local function SpeakParamValue(param)
    local value = param.value()
    if value ~= nil and value ~= "" then
        Speak(value)
    else
        Speak(param.name())
    end
end

-- Handle one arrow-key quick-nav action forwarded from the interface widget.
local function OnQuickNav(action)
    local toolID = CurrentToolID()
    if toolID == nil then return end

    local params = BuildQuickNavParams(toolID)
    local n = #params
    if n == 0 then return end
    -- The parameter set can shrink (e.g. the amount field disappears); clamp.
    if m_qnIndex < 1 then m_qnIndex = 1 elseif m_qnIndex > n then m_qnIndex = n end

    if action == "next_param" then
        local wrapped = (m_qnIndex == n)
        m_qnIndex = (m_qnIndex % n) + 1
        if wrapped then PlayWrapSound() end
        SpeakParamSwitch(params[m_qnIndex])
    elseif action == "prev_param" then
        local wrapped = (m_qnIndex == 1)
        m_qnIndex = ((m_qnIndex - 2 + n) % n) + 1
        if wrapped then PlayWrapSound() end
        SpeakParamSwitch(params[m_qnIndex])
    elseif action == "first_param" then
        m_qnIndex = 1
        SpeakParamSwitch(params[1])
    elseif action == "last_param" then
        m_qnIndex = n
        SpeakParamSwitch(params[n])
    elseif action == "value_up" or action == "value_down" then
        -- Changing the tool re-arms it; the cursor stays on the tool parameter
        -- (index 1), so navigation resumes from the tool for the new tool set.
        -- On list / dropdown parameters Down advances and Up goes back (to match
        -- the tools panel's list navigation); on amount / checkbox parameters Up
        -- increases / turns on and Down decreases / turns off.
        local param = params[m_qnIndex]
        local delta
        if action == "value_up" then
            delta = param.listLike and -1 or 1
        else
            delta = param.listLike and 1 or -1
        end
        if param.cycle(delta) then PlayWrapSound() end
        SpeakParamValue(param)
    elseif action == "first_value" or action == "last_value" then
        local param = params[m_qnIndex]
        if param.jump ~= nil then param.jump(action == "last_value") end
        SpeakParamValue(param)
    end
end

-- Arm a tool directly by its 1-based palette position, forwarded from the
-- interface widget's number-key hotkeys (WorldInput_CAI). Speaks the tool name
-- and its current parameters, and resets the quick-nav cursor to the tool
-- parameter so arrow-key nav resumes from the newly armed tool. An out-of-range
-- position (no such tool) is a no-op.
local function OnSelectTool(pos)
    local tool = CAI_TOOLS[pos]
    if tool == nil then return end
    ArmTool(tool.ID)
    m_qnIndex = 1
    local name = ToolName(tool.ID) or ""
    local params = BuildToolParamString(tool.ID)
    if params ~= nil then
        Speak(name .. ": " .. params)
    else
        Speak(name)
    end
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_TOOLS_TITLE") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function() ClosePanel() return true end,
        },
    })

    m_toolList = mgr:CreateWidget("CAIWorldBuilderTools_List", "List", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_TOOLS_TITLE") end,
    })
    for _, tool in ipairs(CAI_TOOLS) do
        local toolRef = tool
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWB_Tool"), "MenuItem", {
            Label = function()
                local name = Locale.Lookup(toolRef.Text)
                local params = BuildToolParamString(toolRef.ID)
                if params ~= nil then return name .. ", " .. params end
                return name
            end,
        })
        row.FocusKey = "caiwb:tool:" .. tostring(tool.ID)
        row:SetFocusSound(FOCUS_SOUND)
        row:On("focus_enter", function(w)
            if w:IsFocused() then ArmTool(toolRef.ID) end
        end)
        row:On("activate", function() ClosePanel() end)
        m_toolList:AddChild(row)
    end
    m_panel:AddChild(m_toolList)

    -- Transparent container so Tab from the tool list lands on the first field
    -- and the container itself is silent in speech. Wrap is disabled so Tab past
    -- the last field bubbles out instead of cycling back to the first.
    m_settings = mgr:CreateWidget("CAIWorldBuilderTools_Settings", "Panel", {
        Transparent = true,
        WrapAround = false,
    })
    -- A tool with no settings leaves this empty; hide it so it is skipped
    -- entirely instead of being a dead focus stop.
    m_settings:SetHiddenPredicate(function() return #m_settingsWidgets == 0 end)
    m_panel:AddChild(m_settings)
end

function OpenPanel()
    if m_panel or not mgr then return end
    BuildPanel()

    -- Open with focus on the tool vanilla currently has armed, not always the
    -- first row, so reopening lands where the user left off. Each tool row's
    -- FocusKey is "caiwb:tool:<ID>"; fall back to the tool list if unresolved.
    local focusTarget = m_toolList
    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode ~= nil then
        focusTarget = "caiwb:tool:" .. tostring(mode.ID)
    end
    mgr:Push(m_panel, { focus = focusTarget })
end

function ClosePanel()
    if not m_panel then return end
    m_settingsWidgets = {}
    m_settings = nil
    m_toolList = nil
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
end

local function TogglePanel()
    if m_panel then ClosePanel() else OpenPanel() end
end

-- ===========================================================================
--  Cross-context placement-validity query (consumed by interfaceInfoHelpers_CAI)
-- ===========================================================================

-- Gather the plots a brush of the given size covers: center only (1), center +
-- adjacent ring (7), or center + two rings (19). Mirrors the footprint vanilla
-- UpdateMouseOverHighlight highlights, without needing the placement-context
-- local m_19HexTable (unreachable): two rings out is exactly distance <= 2.
local function GatherBrushPlots(plotId, size)
    local plots = { plotId }
    if size <= 1 then return plots end

    local seen = { [plotId] = true }
    local frontier = { plotId }
    local rings = (size >= 19) and 2 or 1
    for _ = 1, rings do
        local nextFrontier = {}
        for _, pid in ipairs(frontier) do
            local p = Map.GetPlotByIndex(pid)
            if p ~= nil then
                local adj = Map.GetAdjacentPlots(p:GetX(), p:GetY())
                for i = 1, 6 do
                    if adj[i] ~= nil then
                        local aid = adj[i]:GetIndex()
                        if not seen[aid] then
                            seen[aid] = true
                            plots[#plots + 1] = aid
                            nextFrontier[#nextFrontier + 1] = aid
                        end
                    end
                end
            end
        end
        frontier = nextFrontier
    end
    return plots
end

-- Validity of placing the current setup (armed tool + selected item + rotation +
-- brush) at plotId. One call for every tool: mode.PlacementValid already encodes
-- the whole setup, exactly as vanilla's OnPlotSelected / UpdateMouseOverHighlight
-- use it. Returns data only; interfaceInfoHelpers_CAI localizes and speaks.
--   { valid, footprint, brushValid?, brushTotal? } or nil when no tool is armed.
info.GetWorldBuilderPlacementValidity = function(plotId)
    if plotId == nil or not Map.IsPlot(plotId) then return nil end

    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode == nil then return nil end

    local valid, aValidPlots = PlacementValid(plotId, mode)
    local result = {
        valid = valid == true,
        footprint = (aValidPlots ~= nil and #aValidPlots > 0) and #aValidPlots or (valid and 1 or 0),
    }

    -- Brush footprint count, only where vanilla enables the brush (Terrain /
    -- Continents). m_brushIndex is CAI's mirror of the vanilla brush size.
    local brushSize = (BRUSH_SIZES[m_brushIndex] and BRUSH_SIZES[m_brushIndex].size) or 1
    if brushSize > 1
        and (mode.ID == WorldBuilderModes.PLACE_TERRAIN or mode.ID == WorldBuilderModes.PLACE_CONTINENTS) then
        local brushPlots = GatherBrushPlots(plotId, brushSize)
        local validCount = 0
        for _, pid in ipairs(brushPlots) do
            if PlacementValid(pid, mode) then validCount = validCount + 1 end
        end
        result.brushTotal = #brushPlots
        result.brushValid = validCount
    end

    return result
end

-- Per-plot placement validity for the current setup across the brush footprint
-- at centerPlotId, for the scanner's Valid Targets listing. Mirrors
-- GetWorldBuilderPlacementValidity's footprint rule: the brush footprint only
-- for Terrain / Continents (where vanilla enables the brush), otherwise just the
-- center plot. Returns an ordered list { { PlotIndex = , Valid = }, ... }, or
-- nil when no tool is armed or the plot is invalid.
info.GetWorldBuilderBrushTargets = function(centerPlotId)
    if centerPlotId == nil or not Map.IsPlot(centerPlotId) then return nil end

    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode == nil then return nil end

    local brushSize = (BRUSH_SIZES[m_brushIndex] and BRUSH_SIZES[m_brushIndex].size) or 1
    local usesBrush = (mode.ID == WorldBuilderModes.PLACE_TERRAIN
        or mode.ID == WorldBuilderModes.PLACE_CONTINENTS)

    local plots
    if usesBrush and brushSize > 1 then
        plots = GatherBrushPlots(centerPlotId, brushSize)
    else
        plots = { centerPlotId }
    end

    local out = {}
    for _, pid in ipairs(plots) do
        out[#out + 1] = { PlotIndex = pid, Valid = PlacementValid(pid, mode) == true }
    end
    return out
end

-- ===========================================================================
--  World Builder per-player visibility (live map-database read)
-- ===========================================================================
-- The Set Visibility tool reveals / hides plots for a chosen player through the
-- vanilla placement path, which records the state in the loaded map's SQLite
-- database: the RevealedPlots table holds one (ID, Player) row per revealed
-- plot, where ID is the 0-based plot index (matching Plots.ID / Map plot
-- indices). While the World Builder is active that database is queryable from
-- this context with DB.Query, so CAI reads the revealed state live instead of
-- shadowing every edit in its own cache and persisting it through the config
-- manager. A row's presence means "revealed for that player".

-- The player the Set Visibility tool is currently pointed at, or nil when that
-- tool is not the armed one.
info.GetWorldBuilderVisibilityPlayer = function()
    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode == nil or mode.ID ~= WorldBuilderModes.SET_VISIBILITY then return nil end
    local entry = Controls.VisibilityPullDown:GetSelectedEntry()
    if entry == nil then return nil end
    return entry.PlayerIndex
end

-- Per-player revealed lookup, delegated to the in-memory visibility manager
-- (WorldBuilderVisManager_CAI). The map's RevealedPlots table lives only on disk
-- and is written on save, so the manager seeds from the file at load and tracks
-- Set Visibility edits and placed-unit sight live; this reads that model.
info.GetWorldBuilderRevealed = function(player, plotIndex)
    if player == nil or plotIndex == nil then return false end
    local visMgr = ExposedMembers.CAI_WBVisManager
    if visMgr == nil or visMgr.IsRevealed == nil then return false end
    return visMgr.IsRevealed(player, plotIndex) == true
end

-- The edge direction (0-based DirectionTypes) the Rivers / Cliffs tool should
-- place on, or nil when neither of those tools is armed. WorldInput_CAI feeds
-- this to EditRiver / EditCliff in place of the mouse-nearest plot edge.
info.GetWorldBuilderEdgeDirection = function()
    local toolID = nil
    local mode = Controls.PlacementPullDown:GetSelectedEntry()
    if mode ~= nil then toolID = mode.ID end
    if toolID ~= WorldBuilderModes.PLACE_RIVERS and toolID ~= WorldBuilderModes.PLACE_CLIFFS then
        return nil
    end
    return m_edgeIndex
end

-- ===========================================================================
--  Vanilla hooks
-- ===========================================================================

-- Capture each grid item's select-closure + label as the vanilla grid is built.
-- The first arg vanilla passes as "toolID" is really the item index; the third
-- is the already-localized item text; the fourth is the selection closure.
MakeItem = WrapFunc(MakeItem, function(orig, idx, icon, label, itemCallback)
    local uiItem = orig(idx, icon, label, itemCallback)
    m_capture[#m_capture + 1] = { idx = idx, label = label, select = itemCallback, uiItem = uiItem }
    return uiItem
end)

-- Reset the capture before the vanilla rebuild, then refresh our settings after.
OnPlacementTypeSelected = WrapFunc(OnPlacementTypeSelected, function(orig, ...)
    m_capture = {}
    orig(...)
    if m_panel then RebuildSettings() end
end)

-- External open/close hook (e.g. from a parent World Builder host context).
LuaEvents.CAIWorldBuilderTools_Toggle.Add(TogglePanel)

-- Arrow-key quick nav forwarded from the World Builder interface widget
-- (WorldInput_CAI). Works ambiently on the map, independent of the tools panel.
LuaEvents.CAIWorldBuilderQuickNav.Add(OnQuickNav)

-- Number-key tool selection forwarded from the World Builder interface widget
-- (WorldInput_CAI). Arms a tool by its palette position, panel-free on the map.
LuaEvents.CAIWorldBuilderSelectTool.Add(OnSelectTool)

-- ===========================================================================
--  Input: while the panel is open, forward to the manager. The panel is opened
--  from the World Builder interface-mode widget (WorldInput_CAI) via the
--  CAIWorldBuilderTools_Toggle event, not from a key handler here.
-- ===========================================================================
ContextPtr:SetInputHandler(function(input)
    if mgr and m_panel then
        if mgr:HandleInput(input) then return true end
    end
    return false
end, true)

-- Wrap (do not replace) vanilla shutdown so its LuaEvents cleanup still runs.
OnShutdown = WrapFunc(OnShutdown, function(orig)
    ClosePanel()
    orig()
end)
