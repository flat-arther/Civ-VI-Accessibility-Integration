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
        -- Drives the vanilla Reveal All button; the revealed state is then read
        -- live from the map database (RevealedPlots), so nothing to mirror here.
        BuildButtonField("LOC_CAI_WB_REVEAL_ALL", "VisibilityRevealAllButton")
    end
    -- Rivers and Cliffs are edge tools: no item type and no parameters here.
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
    end
    -- Rivers and Cliffs are edge tools with no item type or parameters.

    if #parts == 0 then return nil end
    return table.concat(parts, ", ")
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
    -- Tools with no settings (Rivers, Cliffs) leave this empty; hide it so it is
    -- skipped entirely instead of being a dead focus stop.
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

-- Live per-player revealed lookup: true when the loaded map database holds a
-- RevealedPlots row for this plot index and player.
info.GetWorldBuilderRevealed = function(player, plotIndex)
    if player == nil or plotIndex == nil then return false end
    local rows = DB.Query(
        "SELECT 1 FROM RevealedPlots WHERE ID = ? AND Player = ? LIMIT 1",
        plotIndex, player)
    return rows ~= nil and #rows > 0
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
