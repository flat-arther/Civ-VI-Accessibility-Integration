-- ===========================================================================
--  WorldBuilderPlotEditor_CAI
--  Accessible replacement for the World Builder Plot Editor tab.
--
--  Vanilla is one of the two Map Tools tabs (Placement is the other): a scroll
--  panel of label + pulldown rows that reads and writes a single selected plot.
--  Sighted players pick the tab, click a hex, and tweak its properties. CAI
--  reaches it differently: pressing F3 over the source plot (marked tile if
--  locked, else the cursor) in the World Builder interface fires
--  CAIWorldBuilderPlotEditor_Toggle(plotId). We answer by switching the vanilla
--  tab to the Plot Editor (so the Placement tab's brush handler goes dormant and
--  vanilla's own state is coherent) and pushing ONE List for that plot. Escape
--  switches the tab back to Placement, which restores the brush-place flow.
--
--  The List holds, in vanilla order:
--    * Terrain              - standalone Dropdown
--    * Features   (SubMenu) - Feature + Feature Direction dropdowns
--    * Resources  (SubMenu) - Resource dropdown + strategic Amount edit
--    * Improvements(SubMenu)- Improvement dropdown + Pillaged checkbox
--    * Districts  (SubMenu) - District dropdown + Pillaged checkbox
--    * Routes     (SubMenu) - Route dropdown + Pillaged checkbox
--    * Start Positions(SubMenu) - type dropdown + Player/Leader/Civ sub-dropdown
--    * Owner                - standalone Dropdown
--    * Lowland              - standalone Dropdown (Gathering Storm only)
--  Each SubMenu row's label summarises its current selection, exactly like the
--  Placement tool rows (header tag reused from the Placement mode list).
--
--  Everything drives the real data path by pointing the base at our plot
--  (UpdateSelectedPlot) and committing through the vanilla Controls with the
--  trigger flag, so every cascade (terrain dropping an invalid feature, coast
--  fixups, undo blocks) and every disabled/hidden rule runs unchanged. Option
--  lists are re-derived from GameInfo in the exact base order so a CAI dropdown
--  index maps 1:1 onto the vanilla pulldown index; selections are seeded from
--  each pulldown's live GetSelectedIndex.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderPlotEditor")

local mgr = ExposedMembers.CAI_UIManager

local LIST_ID     = "CAIWorldBuilderPlotEditor_List"
local FOCUS_SOUND = "Main_Menu_Mouse_Over"

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local m_list        = nil    -- pushed root List
local m_pendingPlot = nil    -- plot to seed once the tab shows / while open
local m_reseeders   = {}     -- closures that re-read a field from its vanilla control

-- ===========================================================================
--  Option derivation (mirrors the base OnInit / Update* build order so a CAI
--  dropdown index equals the vanilla pulldown index we commit through).
-- ===========================================================================

local function DeriveTerrains()
    local opts = {}
    for row in GameInfo.Terrains() do
        opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = #opts + 1 }
    end
    return opts
end

-- "No X" first, then the rows sorted by localized name - the base's exact sort.
-- Each non-none option keeps its GameInfo row so a per-option validity predicate
-- can be attached (see ApplyValidity).
local function DeriveSortedWithNone(noneTag, iter, includePredicate)
    local rows = {}
    for row in iter do
        if includePredicate == nil or includePredicate(row) then
            rows[#rows + 1] = { label = Locale.Lookup(row.Name), row = row }
        end
    end
    table.sort(rows, function(a, b) return a.label < b.label end)
    local opts = { { label = Locale.Lookup(noneTag), value = 1 } }
    for _, r in ipairs(rows) do
        opts[#opts + 1] = { label = r.label, value = #opts + 1, row = r.row }
    end
    return opts
end

local function DeriveFeatures()
    return DeriveSortedWithNone("LOC_WORLDBUILDER_NO_FEATURE", GameInfo.Features())
end

local function DeriveResources()
    return DeriveSortedWithNone("LOC_WORLDBUILDER_NO_RESOURCE", GameInfo.Resources(),
        function(row) return WorldBuilder.MapManager():IsImprovementPlaceable(row.Index) end)
end

-- "No X" first, then the rows in raw GameInfo order (base does not sort these).
-- Each non-none option keeps its GameInfo row for ApplyValidity.
local function DeriveWithNone(noneTag, iter)
    local opts = { { label = Locale.Lookup(noneTag), value = 1 } }
    for row in iter do
        opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = #opts + 1, row = row }
    end
    return opts
end

-- Attach a per-option disabled predicate (from makePredicate(row)) to every real
-- option, mirroring vanilla's per-entry CanPlace*/CanStartOperation graying so an
-- item invalid for this tile is announced disabled and cannot be committed. The
-- "No X" option (no row) always stays enabled - removing is always allowed.
local function ApplyValidity(options, makePredicate)
    for _, opt in ipairs(options) do
        if opt.row ~= nil then
            opt.disabledPredicate = makePredicate(opt.row)
        end
    end
    return options
end

local function HasPlot()
    return m_pendingPlot ~= nil and Map.IsPlot(m_pendingPlot)
end

local function DeriveDirections()
    -- m_DirectionTypeEntries order: Auto-fit, NE, E, SE, SW, W, NW.
    local tags = {
        "LOC_WORLDBUILDER_AUTO_FIT",
        "LOC_WORLDBUILDER_DIRECTION_NORTHEAST",
        "LOC_WORLDBUILDER_DIRECTION_EAST",
        "LOC_WORLDBUILDER_DIRECTION_SOUTHEAST",
        "LOC_WORLDBUILDER_DIRECTION_SOUTHWEST",
        "LOC_WORLDBUILDER_DIRECTION_WEST",
        "LOC_WORLDBUILDER_DIRECTION_NORTHWEST",
    }
    local opts = {}
    for i, tag in ipairs(tags) do
        opts[i] = { label = Locale.Lookup(tag), value = i }
    end
    return opts
end

local function DeriveStartPosTypes()
    -- m_StartPosTypeEntries order: None, Player, Leader, Civilization, RandomMajor, RandomMinor.
    local tags = {
        "LOC_WORLDBUILDER_NONE",
        "LOC_WORLDBUILDER_PLAYER",
        "LOC_WORLDBUILDER_LEADER",
        "LOC_WORLDBUILDER_CIVILIZATION",
        "LOC_WORLDBUILDER_RANDOM_PLAYER",
        "LOC_WORLDBUILDER_RANDOM_CITY_STATE",
    }
    local opts = {}
    for i, tag in ipairs(tags) do
        opts[i] = { label = Locale.Lookup(tag), value = i }
    end
    return opts
end

-- Mirrors base UpdatePlayerEntries: non-barbarian, non-closed slots, in order.
local function DeriveStartPlayers()
    local opts = {}
    for i = 0, GameDefines.MAX_PLAYERS - 1 do
        if WorldBuilder.PlayerManager():GetSlotStatus(i) ~= SlotStatus.SS_CLOSED then
            local cfg = WorldBuilder.PlayerManager():GetPlayerConfig(i)
            if cfg.IsBarbarian == false then
                opts[#opts + 1] = { label = Locale.Lookup(cfg.Name), value = #opts + 1 }
            end
        end
    end
    return opts
end

local function DeriveLeaders()
    local opts = {}
    for row in GameInfo.Leaders() do
        if row.Name ~= "LOC_EMPTY" then
            opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = #opts + 1 }
        end
    end
    return opts
end

local function DeriveCivilizations()
    local opts = {}
    for row in GameInfo.Civilizations() do
        opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = #opts + 1 }
    end
    return opts
end

-- Mirrors base UpdateCityEntries: "No City" first, then every city of every
-- player in player-then-city order.
local function DeriveOwners()
    local opts = { { label = Locale.Lookup("LOC_WORLDBUILDER_NO_CITY"), value = 1 } }
    for iPlayer = 0, GameDefines.MAX_PLAYERS - 1 do
        local player = Players[iPlayer]
        local cities = player and player:GetCities()
        if cities ~= nil then
            for _, city in cities:Members() do
                opts[#opts + 1] = { label = Locale.Lookup(city:GetName()), value = #opts + 1 }
            end
        end
    end
    return opts
end

local function DeriveLowlands()
    return DeriveWithNone("LOC_WORLDBUILDER_NO_LOWLAND", GameInfo.CoastalLowlands())
end

-- ===========================================================================
--  Live readout helpers (read straight off the vanilla controls)
-- ===========================================================================

local function PLabel(pulldown)
    local e = pulldown ~= nil and pulldown:GetSelectedEntry() or nil
    if e ~= nil and e.Text ~= nil then return Locale.Lookup(e.Text) end
    return ""
end

local function SelIdx(pulldown)
    return math.max(1, pulldown:GetSelectedIndex())
end

local function Join(parts)
    local kept = {}
    for _, s in ipairs(parts) do
        if s ~= nil and s ~= "" then kept[#kept + 1] = s end
    end
    return table.concat(kept, ", ")
end

-- ===========================================================================
--  Field builders. Each is added to a parent (the List or a SubMenu) and
--  registers a reseeder so cascades reflect in the CAI widget.
-- ===========================================================================

local function AddReseeder(fn) m_reseeders[#m_reseeders + 1] = fn end

local function ReseedAll()
    for _, fn in ipairs(m_reseeders) do fn() end
end

-- A Dropdown backed 1:1 by a vanilla pulldown. Committing drives the pulldown
-- with the trigger flag so the base's OnXxxSelected (and its cascades) run.
local function AddDropdown(parent, labelTag, options, pulldown)
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_DD"), "Dropdown", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    dd:SetOptions(options)
    dd:SetSelectedIndex(SelIdx(pulldown), true)
    dd:SetDisabledPredicate(function() return pulldown:IsDisabled() end)
    dd:SetFocusSound(FOCUS_SOUND)
    dd:On("value_changed", function(_, value)
        LuaEvents.CAIWorldBuilderStatusBurstBegin()
        pulldown:SetSelectedIndex(value, true)
        ReseedAll()
    end)
    parent:AddChild(dd)
    AddReseeder(function() dd:SetSelectedIndex(SelIdx(pulldown), true) end)
    return dd
end

-- The strategic-resource amount: mirrors Controls.ResourceAmount. Hidden for
-- non-strategic resources (vanilla SetHide), disabled when no resource.
local function AddAmountField(parent)
    local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Amount"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_RESOURCE_AMOUNT") end,
    })
    edit:SetText(Controls.ResourceAmount:GetText() or "", true)
    edit:SetEditMode(2 --[[ NumbersOnly; enum lives in the uiManager context ]])
    edit:SetMaxCharacters(2) -- vanilla SetMaxCharacters(2)
    edit:SetValueSetter(function(_, text)
        Controls.ResourceAmount:SetText(text)
        OnResourceAmountChanged()
    end)
    edit:SetHiddenPredicate(function() return Controls.ResourceAmount:IsHidden() end)
    edit:SetDisabledPredicate(function() return Controls.ResourceAmount:IsDisabled() end)
    edit:SetFocusSound(FOCUS_SOUND)
    parent:AddChild(edit)
    AddReseeder(function() edit:SetText(Controls.ResourceAmount:GetText() or "", true) end)
    return edit
end

-- A pillaged checkbox backed by a vanilla GridButton. The base toggle handler
-- flips the selected state and applies it, so drive it only when out of sync.
local function AddPillagedField(parent, labelTag, vanillaButton, baseToggle)
    local check = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Pillaged"), "Checkbox", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    check:SetChecked(vanillaButton:IsSelected(), true)
    check:SetValueSetter(function(_, v)
        if vanillaButton:IsSelected() ~= v then baseToggle() end
    end)
    check:SetDisabledPredicate(function() return vanillaButton:IsDisabled() end)
    check:SetFocusSound(FOCUS_SOUND)
    parent:AddChild(check)
    AddReseeder(function() check:SetChecked(vanillaButton:IsSelected(), true) end)
    return check
end

local function MakeSubMenu(labelFn)
    local sub = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Sub"), "SubMenu", {
        Label = labelFn,
    })
    sub:SetFocusSound(FOCUS_SOUND)
    m_list:AddChild(sub)
    return sub
end

-- ===========================================================================
--  List build
-- ===========================================================================

local function BuildList()
    -- Terrain (standalone)
    AddDropdown(m_list, "LOC_WORLDBUILDER_ATTRIBUTE_TERRAIN", DeriveTerrains(), Controls.TerrainPullDown)

    -- Features: Feature + Feature Direction
    local features = MakeSubMenu(function()
        local featurePresent = Controls.FeaturePullDown:GetSelectedIndex() > 1
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_FEATURES"),
            PLabel(Controls.FeaturePullDown),
            featurePresent and PLabel(Controls.FeatureDirectionPulldown) or nil,
        })
    end)
    -- Vanilla grays features only when the tile's current feature has no direction
    -- (plotDir == -1), using the live Feature Direction selection as the direction.
    local featureOpts = ApplyValidity(DeriveFeatures(), function(row)
        return function()
            if not HasPlot() then return false end
            if Map.GetPlotByIndex(m_pendingPlot):GetFeature():GetDirection() ~= -1 then return false end
            local dirEntry = Controls.FeatureDirectionPulldown:GetSelectedEntry()
            local dir = dirEntry and dirEntry.Type or DirectionTypes.NO_DIRECTION
            return not WorldBuilder.MapManager():CanPlaceFeature(m_pendingPlot, row.Index, { Direction = dir, IgnoreExisting = true })
        end
    end)
    AddDropdown(features, "LOC_WORLDBUILDER_ATTRIBUTE_FEATURE", featureOpts, Controls.FeaturePullDown)
    AddDropdown(features, "LOC_WORLDBUILDER_ATTRIBUTE_FEATURE_DIRECTION", DeriveDirections(), Controls.FeatureDirectionPulldown)

    -- Resources: Resource + strategic Amount
    local resources = MakeSubMenu(function()
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_RESOURCES"),
            PLabel(Controls.ResourcePullDown),
            (not Controls.ResourceAmount:IsHidden()) and Controls.ResourceAmount:GetText() or nil,
        })
    end)
    local resourceOpts = ApplyValidity(DeriveResources(), function(row)
        return function()
            if not HasPlot() then return false end
            return not WorldBuilder.MapManager():CanPlaceResource(m_pendingPlot, row.Index, true)
        end
    end)
    AddDropdown(resources, "LOC_WORLDBUILDER_ATTRIBUTE_RESOURCE", resourceOpts, Controls.ResourcePullDown)
    AddAmountField(resources)

    -- Improvements: Improvement + Pillaged
    local improvements = MakeSubMenu(function()
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_IMPROVEMENTS"),
            PLabel(Controls.ImprovementPullDown),
            Controls.ImprovementPillagedButton:IsSelected()
                and Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_IMPROVEMENT_PILLAGED") or nil,
        })
    end)
    local improvementOpts = ApplyValidity(DeriveWithNone("LOC_WORLDBUILDER_NO_IMPROVEMENT", GameInfo.Improvements()), function(row)
        return function()
            if not HasPlot() then return false end
            local owner = Map.GetPlotByIndex(m_pendingPlot):GetOwner()
            return not WorldBuilder.MapManager():CanPlaceImprovement(m_pendingPlot, row.Index, owner, true)
        end
    end)
    AddDropdown(improvements, "LOC_WORLDBUILDER_ATTRIBUTE_IMPROVEMENT", improvementOpts, Controls.ImprovementPullDown)
    AddPillagedField(improvements, "LOC_WORLDBUILDER_ATTRIBUTE_IMPROVEMENT_PILLAGED", Controls.ImprovementPillagedButton, OnImprovementPillagedButton)

    -- Districts: District + Pillaged
    local districts = MakeSubMenu(function()
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_DISTRICTS"),
            PLabel(Controls.DistrictPullDown),
            Controls.DistrictPillagedButton:IsSelected()
                and Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_DISTRICT_PILLAGED") or nil,
        })
    end)
    -- Vanilla UpdateDistrictInfo grays a district unless the tile's owning city can
    -- start a BUILD operation for it (needs an owner city + a valid district plot).
    local districtOpts = ApplyValidity(DeriveWithNone("LOC_WORLDBUILDER_NO_DISTRICT", GameInfo.Districts()), function(row)
        return function()
            if not HasPlot() then return false end
            local pPlot = Map.GetPlotByIndex(m_pendingPlot)
            local kOwner = WorldBuilder.CityManager():GetPlotOwner(pPlot)
            if kOwner == nil then return true end
            local pCity = CityManager.GetCity(kOwner.PlayerID, kOwner.CityID)
            if pCity == nil then return true end
            local kParameters = {}
            kParameters[CityOperationTypes.PARAM_DISTRICT_TYPE] = row.Hash
            kParameters[CityOperationTypes.PARAM_X] = pPlot:GetX()
            kParameters[CityOperationTypes.PARAM_Y] = pPlot:GetY()
            return not CityManager.CanStartOperation(pCity, CityOperationTypes.BUILD, kParameters, true)
        end
    end)
    AddDropdown(districts, "LOC_WORLDBUILDER_ATTRIBUTE_DISTRICT", districtOpts, Controls.DistrictPullDown)
    AddPillagedField(districts, "LOC_WORLDBUILDER_ATTRIBUTE_DISTRICT_PILLAGED", Controls.DistrictPillagedButton, OnDistrictPillagedButton)

    -- Routes: Route + Pillaged
    local routes = MakeSubMenu(function()
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_ROUTES"),
            PLabel(Controls.RoutePullDown),
            Controls.RoutePillagedButton:IsSelected()
                and Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_ROUTE_PILLAGED") or nil,
        })
    end)
    AddDropdown(routes, "LOC_WORLDBUILDER_ATTRIBUTE_ROUTE", DeriveWithNone("LOC_WORLDBUILDER_NO_ROUTE", GameInfo.Routes()), Controls.RoutePullDown)
    AddPillagedField(routes, "LOC_WORLDBUILDER_ATTRIBUTE_ROUTE_PILLAGED", Controls.RoutePillagedButton, OnRoutePillagedButton)

    -- Start Positions: type + a Player/Leader/Civ sub-dropdown (only the one that
    -- matches the current type is visible, mirroring vanilla's StartPosTabControl).
    local function startType() local e = Controls.StartPosPulldown:GetSelectedEntry() return e and e.Type or nil end
    local startPos = MakeSubMenu(function()
        local t = startType()
        local sub = nil
        if     t == "Player"       then sub = PLabel(Controls.StartPosPlayerPulldown)
        elseif t == "Leader"       then sub = PLabel(Controls.StartPosLeaderPulldown)
        elseif t == "Civilization" then sub = PLabel(Controls.StartPosCivPulldown) end
        return Join({
            Locale.Lookup("LOC_WORLDBUILDER_PLACEMENT_MODE_START_POSITIONS"),
            PLabel(Controls.StartPosPulldown),
            sub,
        })
    end)
    AddDropdown(startPos, "LOC_WORLDBUILDER_START_POSITION", DeriveStartPosTypes(), Controls.StartPosPulldown)
    local playerDD = AddDropdown(startPos, "LOC_WORLDBUILDER_PLAYER", DeriveStartPlayers(), Controls.StartPosPlayerPulldown)
    local leaderDD = AddDropdown(startPos, "LOC_WORLDBUILDER_LEADER", DeriveLeaders(), Controls.StartPosLeaderPulldown)
    local civDD    = AddDropdown(startPos, "LOC_WORLDBUILDER_CIVILIZATION", DeriveCivilizations(), Controls.StartPosCivPulldown)
    playerDD:SetHiddenPredicate(function() return startType() ~= "Player" end)
    leaderDD:SetHiddenPredicate(function() return startType() ~= "Leader" end)
    civDD:SetHiddenPredicate(function() return startType() ~= "Civilization" end)

    -- Owner (standalone)
    AddDropdown(m_list, "LOC_WORLDBUILDER_ATTRIBUTE_OWNER", DeriveOwners(), Controls.OwnerPulldown)

    -- Lowland (Gathering Storm only). IsExpansion2 is a base global.
    if IsExpansion2() then
        AddDropdown(m_list, "LOC_WORLDBUILDER_ATTRIBUTE_LOWLAND_TYPE", DeriveLowlands(), Controls.LowlandTypePulldown)
    end
end

-- ===========================================================================
--  Open / close
-- ===========================================================================

local function PlotCoords()
    if m_pendingPlot == nil or not Map.IsPlot(m_pendingPlot) then return "" end
    local plot = Map.GetPlotByIndex(m_pendingPlot)
    return string.format("(%i, %i)", plot:GetX(), plot:GetY())
end

local function OpenList()
    if m_list or not mgr then return end
    m_reseeders = {}
    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function()
            return Join({ Locale.Lookup("LOC_WORLDBUILDER_SELECT_TOOL"), PlotCoords() })
        end,
    })
    m_list:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        MSG = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            -- Switch the vanilla tab back to Placement; its hide handler pops us.
            LuaEvents.CAIWorldBuilderSelectTab("Placement")
            return true
        end,
    })
    BuildList()
    mgr:Push(m_list, { focus = m_list })
end

local function CloseList()
    if not m_list then return end
    m_reseeders = {}
    mgr:RemoveFromStack(LIST_ID)
    m_list = nil
end

-- ===========================================================================
--  Vanilla lifecycle bridge
-- ===========================================================================

-- F3 over a plot fires this. Switch to the Plot Editor tab (its show handler
-- seeds + opens the list). If already open, just retarget to the new plot.
local function OnToggle(plotId)
    if plotId == nil or not Map.IsPlot(plotId) then return end
    m_pendingPlot = plotId
    if m_list then
        UpdateSelectedPlot(plotId)
        ReseedAll()
        mgr:Refocus()
        return
    end
    LuaEvents.CAIWorldBuilderSelectTab("PlotEditor")
end
LuaEvents.CAIWorldBuilderPlotEditor_Toggle.Add(OnToggle)

-- The tab becoming visible is the authoritative open signal: the base OnShow
-- clears the selection to nil, so re-seed our plot afterward, then open the list.
OnShow = WrapFunc(OnShow, function(orig)
    orig()
    if m_pendingPlot ~= nil and Map.IsPlot(m_pendingPlot) then
        UpdateSelectedPlot(m_pendingPlot)
    end
    OpenList()
end)
ContextPtr:SetShowHandler(OnShow)

OnHide = WrapFunc(OnHide, function(orig)
    orig()
    CloseList()
    m_pendingPlot = nil
end)
ContextPtr:SetHideHandler(OnHide)

-- A start position changed out of band (e.g. clearing another tile) - re-read.
local function OnStartPositionChangedCAI()
    if m_list then ReseedAll() end
end
LuaEvents.WorldBuilder_StartPositionChanged.Add(OnStartPositionChangedCAI)

-- Forward input to the manager while our list is open. The base plot editor has
-- no input handler of its own, so this is the only one on the context.
ContextPtr:SetInputHandler(function(input)
    if mgr and m_list then
        if mgr:HandleInput(input) then return true end
    end
    return false
end, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    LuaEvents.CAIWorldBuilderPlotEditor_Toggle.Remove(OnToggle)
    LuaEvents.WorldBuilder_StartPositionChanged.Remove(OnStartPositionChangedCAI)
    CloseList()
    orig()
end)
