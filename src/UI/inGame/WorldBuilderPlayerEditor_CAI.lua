-- ===========================================================================
--  WorldBuilderPlayerEditor_CAI
--  Accessible replacement for the World Builder Player Editor modal.
--
--  Vanilla is a single modal: a player list beside a 4-tab editor (General,
--  Techs, Civics, Cities) that reflects the selected player. CAI mirrors that
--  as ONE pushed panel holding both:
--
--    * a player List (Add Player / Add AI are rows at the bottom of the list;
--      Delete removes the focused player). Focusing a player row selects it.
--    * a TabControl next to the list. Tab from the list lands on it; its pages
--      always read/write the currently selected player.
--
--  Selection follows focus: entering a player row sets the selection and
--  reseeds the tab widgets (dropdown/checkbox/edit state + the city tree) for
--  that player, without stealing focus. The tab widgets are built once and read
--  the live selection, so switching players is a reseed, not a rebuild.
--
--  Cities tab is a Tree: each city expands to Population (Enter opens an inline
--  editor) and Districts / Buildings subtrees. A district/building leaf reads
--  live state - added / not added / pillaged (pillage is display-only, matching
--  vanilla). Enter on an unadded item adds it; Delete removes it. A city and a
--  district need a plot, so Add City and add-District use vanilla's placement
--  handoff (WorldBuilderModeChangeRequest closes the editor and arms the tool on
--  the map); buildings here are all non-placement, so they are created inline.
--
--  Everything drives the real data path (WorldBuilder.PlayerManager() /
--  CityManager() / the base's PlacementSetResults global). Option lists are
--  re-derived from GameInfo because the base's m_*Entries are file-locals with
--  no cross-context reach.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderPlayerEditor")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID    = "CAIWorldBuilderPlayerEditor_Panel"
local FOCUS_SOUND = "Main_Menu_Mouse_Over"

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local m_panel         = nil
local m_playerList    = nil
local m_playerRows    = {}     -- index -> row widget (rebuilt each RefreshPlayerList)
local m_tabs          = nil
local m_selectedIndex = nil    -- selected player index (follows list focus)
local m_cityTree      = nil

-- Detail widget refs (built once; reseeded per selected player)
local m_civDD, m_leaderDD, m_civLevelDD, m_eraDD, m_goldEdit, m_faithEdit
local m_techChecks  = {}
local m_civicChecks = {}

local MAX_NUMBER_CHARS = 22 -- vanilla MaxLength on the gold/faith/population edit boxes

-- Forward declarations (mutually-recursive locals must precede use).
local RefreshPlayerList
local RefreshDetail
local ReseedGeneral
local RefreshCityTree
local AddCityNode
local AddPlayerAndFocus
local OpenPanel
local CloseAll

local function SelIndex() return m_selectedIndex end

-- ===========================================================================
--  Option lists (re-derived from GameInfo, mirroring the base OnInit build)
-- ===========================================================================

local m_civOpts, m_leaderOpts, m_civLevelOpts, m_eraOpts
local m_districtDefs, m_buildingDefs

local function SortByLabel(list)
    table.sort(list, function(a, b) return a.label < b.label end)
end

local function GetCivOptions()
    if m_civOpts then return m_civOpts end
    local opts = {}
    for row in GameInfo.Civilizations() do
        opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = row.CivilizationType, default = -1 }
    end
    SortByLabel(opts)
    table.insert(opts, 1, { label = Locale.Lookup("LOC_WORLDBUILDER_RANDOM"), value = "RANDOM",    default = "RANDOM" })
    table.insert(opts, 2, { label = Locale.Lookup("LOC_WORLDBUILDER_ANY"),    value = "UNDEFINED", default = "UNDEFINED" })
    -- Default leader per civ, so choosing a civ seeds its leader (vanilla OnCivSelected).
    for entry in GameInfo.CivilizationLeaders() do
        for _, o in ipairs(opts) do
            if o.value == entry.CivilizationType then o.default = entry.LeaderType end
        end
    end
    m_civOpts = opts
    return opts
end

local function GetLeaderOptions()
    if m_leaderOpts then return m_leaderOpts end
    local opts = {}
    for row in GameInfo.Leaders() do
        if row.Name ~= "LOC_EMPTY" then
            opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = row.LeaderType }
        end
    end
    SortByLabel(opts)
    table.insert(opts, 1, { label = Locale.Lookup("LOC_WORLDBUILDER_RANDOM"), value = "RANDOM" })
    table.insert(opts, 2, { label = Locale.Lookup("LOC_WORLDBUILDER_ANY"),    value = "UNDEFINED" })
    -- Vanilla InitGeneralTab disables the RANDOM / RANDOM_POOL leader entries so the
    -- user can never manually pick them (Any/UNDEFINED stays selectable).
    for _, o in ipairs(opts) do
        if o.value == "RANDOM" or o.value == "RANDOM_POOL1" or o.value == "RANDOM_POOL2" then
            o.disabledPredicate = function() return true end
        end
    end
    m_leaderOpts = opts
    return opts
end

local function GetCivLevelOptions()
    if m_civLevelOpts then return m_civLevelOpts end
    local opts = {}
    for row in GameInfo.CivilizationLevels() do
        local name = row.Name ~= nil and row.Name or row.CivilizationLevelType
        opts[#opts + 1] = { label = Locale.Lookup("LOC_WORLDBUILDER_" .. name), value = row.CivilizationLevelType }
    end
    m_civLevelOpts = opts
    return opts
end

local function GetEraOptions()
    if m_eraOpts then return m_eraOpts end
    local opts = { { label = Locale.Lookup("LOC_WORLDBUILDER_DEFAULT"), value = "DEFAULT" } }
    for row in GameInfo.Eras() do
        opts[#opts + 1] = { label = Locale.Lookup(row.Name), value = row.EraType }
    end
    m_eraOpts = opts
    return opts
end

-- Districts: all buildable districts except the wonder pseudo-district (vanilla).
local function GetDistrictDefs()
    if m_districtDefs then return m_districtDefs end
    local defs = {}
    for row in GameInfo.Districts() do
        if row.DistrictType ~= "DISTRICT_WONDER" then
            defs[#defs + 1] = { row = row, label = Locale.Lookup(row.Name) }
        end
    end
    SortByLabel(defs)
    m_districtDefs = defs
    return defs
end

-- Buildings: the base's Player Editor list only holds non-placement, non-internal
-- buildings, so every add here is a clean inline CreateBuilding.
local function GetBuildingDefs()
    if m_buildingDefs then return m_buildingDefs end
    local defs = {}
    for row in GameInfo.Buildings() do
        if row.RequiresPlacement ~= true and (row.InternalOnly == nil or row.InternalOnly == false) then
            defs[#defs + 1] = { row = row, label = Locale.Lookup(row.Name) }
        end
    end
    SortByLabel(defs)
    m_buildingDefs = defs
    return defs
end

local function IndexOfValue(opts, val)
    for i, o in ipairs(opts) do
        if o.value == val then return i end
    end
    return 1
end

-- Vanilla GetCivEntryIndexByType / GetLeaderEntryIndexByType return 0 (blank) on a
-- miss; this returns nil so the caller can clear the dropdown to match.
local function MatchIndex(opts, val)
    for i, o in ipairs(opts) do
        if o.value == val then return i end
    end
    return nil
end

-- Seed a dropdown from a config value: select the matching option, or clear the
-- selection (blank) when nothing matches, exactly like a vanilla PullDown at index 0.
local function SeedDropdown(dd, opts, val)
    local idx = MatchIndex(opts, val)
    if idx ~= nil then
        dd:SetSelectedIndex(idx, true)
    else
        dd:ClearSelection(true)
    end
end

local function OptionByValue(opts, val)
    for _, o in ipairs(opts) do
        if o.value == val then return o end
    end
    return nil
end

-- ===========================================================================
--  Shared data helpers
-- ===========================================================================

local function PlayerCfg(index)
    return WorldBuilder.PlayerManager():GetPlayerConfig(index)
end

local function PlayerLabel(index)
    local cfg = PlayerCfg(index)
    local who = cfg.IsHuman and Locale.Lookup("LOC_WORLDBUILDER_HUMAN") or Locale.Lookup("LOC_WORLDBUILDER_AI")
    return string.format("%s - %s", who, Locale.Lookup(cfg.Name))
end

-- Enumerate open, non-barbarian player slots (mirrors vanilla UpdatePlayerList).
local function EnumeratePlayers()
    local list = {}
    for i = 0, GameDefines.MAX_PLAYERS - 1 do
        if WorldBuilder.PlayerManager():GetSlotStatus(i) ~= SlotStatus.SS_CLOSED then
            if PlayerCfg(i).IsBarbarian == false then
                list[#list + 1] = i
            end
        end
    end
    return list
end

local function LiveCity(index, cityID)
    return WorldBuilder.CityManager():GetCity(index, cityID)
end

-- "Name, Not added" / "Name, Added" / "Name, Added, Pillaged".
local function ItemStateLabel(name, present, pillaged)
    if not present then
        return name .. ", " .. Locale.Lookup("LOC_CAI_WB_PE_NOT_ADDED")
    end
    if pillaged then
        return name .. ", " .. Locale.Lookup("LOC_CAI_WB_PE_ADDED") .. ", " .. Locale.Lookup("LOC_CAI_WB_PE_PILLAGED")
    end
    return name .. ", " .. Locale.Lookup("LOC_CAI_WB_PE_ADDED")
end

local function DistrictState(index, cityID, drow)
    local c = LiveCity(index, cityID)
    if not c then return false, false end
    local dd = c:GetDistricts()
    if dd == nil then return false, false end
    local present = dd:HasDistrict(drow.Index)
    local pillaged = false
    if present then
        local pDistrict = dd:GetDistrict(drow.Hash)
        pillaged = pDistrict ~= nil and pDistrict:IsPillaged()
    end
    return present, pillaged
end

local function BuildingState(index, cityID, brow)
    local c = LiveCity(index, cityID)
    if not c then return false, false end
    local bb = c:GetBuildings()
    if bb == nil then return false, false end
    local present = bb:HasBuilding(brow.Index)
    local pillaged = present and bb:IsPillaged(brow.Hash) or false
    return present, pillaged
end

-- ===========================================================================
--  Cities tree
-- ===========================================================================

local function AddDistrictLeaf(parent, index, cityID, def)
    local drow = def.row
    local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Dist"), "TreeItem", {
        Label = function()
            local present, pillaged = DistrictState(index, cityID, drow)
            return ItemStateLabel(def.label, present, pillaged)
        end,
        FocusKey = "wbcity:" .. cityID .. ":d:" .. drow.DistrictType,
    })
    leaf:SetFocusSound(FOCUS_SOUND)
    leaf:On("activate", function()
        local present = DistrictState(index, cityID, drow)
        if not present then
            -- Districts need a plot: hand off to map placement exactly like vanilla.
            local c = LiveCity(index, cityID)
            if c ~= nil then
                LuaEvents.WorldBuilderModeChangeRequest(WorldBuilderModes.PLACE_DISTRICTS, {
                    DistrictType = drow.Hash, PlayerID = index, CityID = c:GetID(),
                })
            end
        end
        -- Present: pillage is display-only (vanilla), so nothing else to do.
    end)
    leaf:AddInputBinding({
        Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_WB_PE_REMOVE",
        Action = function(w)
            local present = DistrictState(index, cityID, drow)
            if present then
                local c = LiveCity(index, cityID)
                local pDistrict = c ~= nil and c:GetDistricts():GetDistrict(drow.Hash) or nil
                if pDistrict ~= nil then
                    WorldBuilder.CityManager():RemoveDistrict(pDistrict)
                end
                w:Announce()
            end
            return true
        end,
    })
    parent:AddChild(leaf)
end

local function AddBuildingLeaf(parent, index, cityID, def)
    local brow = def.row
    local leaf = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Bld"), "TreeItem", {
        Label = function()
            local present, pillaged = BuildingState(index, cityID, brow)
            return ItemStateLabel(def.label, present, pillaged)
        end,
        FocusKey = "wbcity:" .. cityID .. ":b:" .. brow.BuildingType,
    })
    leaf:SetFocusSound(FOCUS_SOUND)
    leaf:On("activate", function()
        local present = BuildingState(index, cityID, brow)
        if not present then
            local c = LiveCity(index, cityID)
            if c ~= nil then
                -- New user action: reset the launch-bar status de-dupe so the
                -- result (or failure reason) is always spoken.
                LuaEvents.CAIWorldBuilderStatusBurstBegin()
                local bStatus, sStatus = WorldBuilder.CityManager():CreateBuilding(c, brow.BuildingType, 100)
                PlacementSetResults(bStatus, sStatus, brow.Name)
            end
        end
        -- Present: pillage is display-only (vanilla), so nothing else to do.
    end)
    leaf:AddInputBinding({
        Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_WB_PE_REMOVE",
        Action = function(w)
            local present = BuildingState(index, cityID, brow)
            if present then
                local c = LiveCity(index, cityID)
                if c ~= nil then
                    WorldBuilder.CityManager():RemoveBuilding(c, brow.BuildingType)
                end
                w:Announce()
            end
            return true
        end,
    })
    parent:AddChild(leaf)
end

AddCityNode = function(index, cityID)
    local cityNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_City"), "TreeItem", {
        Label = function()
            local c = LiveCity(index, cityID)
            return c ~= nil and Locale.Lookup(c:GetName()) or ""
        end,
        FocusKey = "wbcity:" .. cityID,
    })
    cityNode:SetFocusSound(FOCUS_SOUND)
    cityNode:AddInputBinding({
        Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_WB_PE_REMOVE",
        Action = function()
            local c = LiveCity(index, cityID)
            if c ~= nil then
                WorldBuilder.CityManager():Remove(c)
            end
            RefreshCityTree()
            return true
        end,
    })
    m_cityTree:AddChild(cityNode)

    -- Population: a real EditBox row in the tree (not AlwaysEdit, so Up/Down still
    -- navigate the tree; Enter begins editing, Enter commits, Escape cancels).
    -- Number-only + max length 22 match vanilla's PopulationEdit.
    local popEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_PopRow"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_HEADER_POPULATION") end,
        FocusKey = "wbcity:" .. cityID .. ":pop",
    })
    local c0 = LiveCity(index, cityID)
    local pop0 = c0 ~= nil and WorldBuilder.CityManager():GetCityValue(c0, "Population") or nil
    popEdit:SetText(tostring(pop0 or 0), true)
    popEdit:SetEditMode(2 --[[ EditModes.NumbersOnly; enum lives in the uiManager context, not here ]])
    popEdit:SetMaxCharacters(MAX_NUMBER_CHARS)
    popEdit:SetValueSetter(function(_, text)
        local v = tonumber(text)
        if v ~= nil then
            local cc = LiveCity(index, cityID)
            if cc ~= nil then
                WorldBuilder.CityManager():SetCityValue(cc, "Population", v)
            end
        end
    end)
    popEdit:SetFocusSound(FOCUS_SOUND)
    cityNode:AddChild(popEdit)

    -- Districts subtree
    local distNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Districts"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_DISTRICTS") end,
        FocusKey = "wbcity:" .. cityID .. ":districts",
    })
    distNode:SetFocusSound(FOCUS_SOUND)
    cityNode:AddChild(distNode)
    for _, def in ipairs(GetDistrictDefs()) do
        AddDistrictLeaf(distNode, index, cityID, def)
    end

    -- Buildings subtree
    local bldNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Buildings"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_BUILDINGS") end,
        FocusKey = "wbcity:" .. cityID .. ":buildings",
    })
    bldNode:SetFocusSound(FOCUS_SOUND)
    cityNode:AddChild(bldNode)
    for _, def in ipairs(GetBuildingDefs()) do
        AddBuildingLeaf(bldNode, index, cityID, def)
    end
end

RefreshCityTree = function()
    if not m_cityTree then return end
    local capture = mgr:CaptureFocusKey(m_cityTree)
    m_cityTree:ClearChildren()

    local i = m_selectedIndex
    if i ~= nil then
        local pPlayer = Players[i]
        local cities = pPlayer ~= nil and pPlayer:GetCities() or nil
        if cities ~= nil then
            for _, pCity in cities:Members() do
                AddCityNode(i, pCity:GetID())
            end
        end
    end

    mgr:RestoreFocus(m_cityTree, capture)
end

-- ===========================================================================
--  Detail tab pages (built once; widgets read the live selection)
-- ===========================================================================

local function MakeDropdown(page, labelTag, opts, onCommit, disabledPredicate)
    local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_DD"), "Dropdown", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    dd:SetOptions(opts)
    dd:SetFocusSound(FOCUS_SOUND)
    dd:On("value_changed", function(_, value)
        if SelIndex() ~= nil then onCommit(SelIndex(), value) end
    end)
    dd:SetDisabledPredicate(disabledPredicate)
    page:AddChild(dd)
    return dd
end

local function MakeNumberField(page, labelTag, commitFn, disabledPredicate)
    local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Num"), "EditBox", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    edit:SetText("0", true)
    edit:SetAlwaysEdit(true)
    edit:SetCommitOnFocusLeave(false)
    edit:SetEditMode(2 --[[ EditModes.NumbersOnly; enum lives in the uiManager context, not here ]])  -- vanilla SetNumberInput(true)
    edit:SetMaxCharacters(MAX_NUMBER_CHARS)   -- vanilla MaxLength="22"
    edit:SetValueSetter(function(_, text)
        local v = tonumber(text)
        if v ~= nil and SelIndex() ~= nil then commitFn(SelIndex(), v) end
    end)
    edit:SetDisabledPredicate(disabledPredicate)
    edit:SetFocusSound(FOCUS_SOUND)
    page:AddChild(edit)
    return edit
end

local function BuildGeneralPage(page)
    local function initialized()
        local i = SelIndex()
        return i ~= nil and WorldBuilder.PlayerManager():IsPlayerInitialized(i)
    end
    local function moneyDisabled()
        local i = SelIndex()
        if i == nil then return true end
        if not WorldBuilder.PlayerManager():IsPlayerInitialized(i) then return true end
        return PlayerCfg(i).Civ == "CIVILIZATION_BARBARIAN"
    end

    local civOpts = GetCivOptions()
    m_civDD = MakeDropdown(page, "LOC_WORLDBUILDER_CIVILIZATION", civOpts, function(i, value)
        local opt = OptionByValue(civOpts, value)
        WorldBuilder.PlayerManager():SetPlayerLeader(i, opt ~= nil and opt.default or -1, value, PlayerCfg(i).CivLevel)
    end, function() return SelIndex() == nil end)

    m_leaderDD = MakeDropdown(page, "LOC_WORLDBUILDER_LEADER", GetLeaderOptions(), function(i, value)
        WorldBuilder.PlayerManager():SetPlayerLeader(i, value, PlayerCfg(i).Civ, PlayerCfg(i).CivLevel)
    end, function()
        -- Vanilla: not playerSelected or not IsFullCiv or Civ == -1 (undefined civ).
        local i = SelIndex()
        if i == nil then return true end
        local cfg = PlayerCfg(i)
        return not cfg.IsFullCiv or cfg.Civ == -1
    end)

    m_civLevelDD = MakeDropdown(page, "LOC_WORLDBUILDER_CIVILIZATION_LEVEL", GetCivLevelOptions(), function(i, value)
        WorldBuilder.PlayerManager():SetPlayerLeader(i, PlayerCfg(i).Leader, PlayerCfg(i).Civ, value)
    end, function() return SelIndex() == nil end)

    m_eraDD = MakeDropdown(page, "LOC_WORLDBUILDER_ERA", GetEraOptions(), function(i, value)
        WorldBuilder.PlayerManager():SetPlayerEra(i, value)
    end, function() return not initialized() end)

    m_goldEdit = MakeNumberField(page, "LOC_WORLDBUILDER_ATTRIBUTE_GOLD", function(i, v)
        WorldBuilder.PlayerManager():SetPlayerGold(i, v)
    end, moneyDisabled)
    m_faithEdit = MakeNumberField(page, "LOC_WORLDBUILDER_ATTRIBUTE_FAITH", function(i, v)
        WorldBuilder.PlayerManager():SetPlayerFaith(i, v)
    end, moneyDisabled)
end

local function BuildTechsPage(page)
    local list = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Techs"), "List", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_TECHS") end,
    })
    m_techChecks = {}
    local techs = {}
    for row in GameInfo.Technologies() do
        techs[#techs + 1] = { row = row, label = Locale.Lookup(row.Name) }
    end
    SortByLabel(techs)
    for _, def in ipairs(techs) do
        local row = def.row
        local cb = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Tech"), "Checkbox", {
            Label = function() return def.label end,
            FocusKey = "wbtech:" .. row.TechnologyType,
        })
        cb:SetValueSetter(function(_, v)
            if SelIndex() ~= nil then
                WorldBuilder.PlayerManager():SetPlayerHasTech(SelIndex(), row.Index, v and 100 or -1)
            end
        end)
        cb:SetDisabledPredicate(function() return SelIndex() == nil end)
        cb:SetFocusSound(FOCUS_SOUND)
        list:AddChild(cb)
        m_techChecks[#m_techChecks + 1] = { cb = cb, row = row }
    end
    page:AddChild(list)
end

local function BuildCivicsPage(page)
    local list = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Civics"), "List", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_CIVICS") end,
    })
    m_civicChecks = {}
    local civics = {}
    for row in GameInfo.Civics() do
        civics[#civics + 1] = { row = row, label = Locale.Lookup(row.Name) }
    end
    SortByLabel(civics)
    for _, def in ipairs(civics) do
        local row = def.row
        local cb = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Civic"), "Checkbox", {
            Label = function() return def.label end,
            FocusKey = "wbcivic:" .. row.CivicType,
        })
        cb:SetValueSetter(function(_, v)
            if SelIndex() ~= nil then
                WorldBuilder.PlayerManager():SetPlayerHasCivic(SelIndex(), row.Index, v and 100 or -1)
            end
        end)
        cb:SetDisabledPredicate(function() return SelIndex() == nil end)
        cb:SetFocusSound(FOCUS_SOUND)
        list:AddChild(cb)
        m_civicChecks[#m_civicChecks + 1] = { cb = cb, row = row }
    end
    page:AddChild(list)
end

local function BuildCitiesPage(page)
    m_cityTree = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Cities"), "Tree", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_CITIES") end,
    })
    page:AddChild(m_cityTree)

    -- Add City sits below the tree; adding a city needs a plot, so it uses the
    -- vanilla placement handoff (closes the editor, arms the city tool on the map).
    local addCity = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_AddCity"), "Button", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_BUTTON_ADD_CITY") end,
    })
    addCity:SetDisabledPredicate(function() return SelIndex() == nil end)
    addCity:SetFocusSound(FOCUS_SOUND)
    addCity:On("activate", function()
        if SelIndex() ~= nil then
            LuaEvents.WorldBuilderModeChangeRequest(WorldBuilderModes.PLACE_CITIES, { PlayerID = SelIndex() })
        end
    end)
    page:AddChild(addCity)
end

-- Reseed the General dropdowns + gold/faith from the selected player's live
-- config. Silent (no focus move). Runs on selection change and, crucially, when
-- the player is edited: choosing a civ sets that civ's default leader, so the
-- Leader dropdown must re-seed to show it (vanilla UpdateGeneralTabValues does
-- the same off WorldBuilder_PlayerEdited).
ReseedGeneral = function()
    if not m_civDD then return end
    local i = m_selectedIndex
    if i == nil then return end
    local cfg = PlayerCfg(i)
    -- Civ / Leader / CivLevel: the engine reads these back as real type strings
    -- ("CIVILIZATION_*", "RANDOM", "UNDEFINED") or nil for a never-configured player
    -- (a fresh player's CivLevel is nil). Match the option, or clear to blank on a
    -- miss - exactly what vanilla's Get*EntryIndexByType (0 on miss) does.
    SeedDropdown(m_civDD, GetCivOptions(), cfg.Civ)
    SeedDropdown(m_leaderDD, GetLeaderOptions(), cfg.Leader)
    SeedDropdown(m_civLevelDD, GetCivLevelOptions(), cfg.CivLevel)
    -- Era falls back to DEFAULT on a miss (vanilla GetCivEraIndexByType returns 1).
    m_eraDD:SetSelectedIndex(IndexOfValue(GetEraOptions(), cfg.Era or "DEFAULT"), true)
    m_goldEdit:SetText(tostring(cfg.Gold or 0), true)
    m_faithEdit:SetText(tostring(cfg.Faith or 0), true)
end

-- Reseed the whole detail (General + tech/civic checkboxes + city tree) for the
-- current selection. Silent (no focus move): the caller (a player row
-- focus_enter) keeps focus on the list.
RefreshDetail = function()
    if not m_tabs then return end
    local i = m_selectedIndex
    if i == nil then
        RefreshCityTree()
        return
    end
    ReseedGeneral()
    for _, tc in ipairs(m_techChecks) do
        tc.cb:SetChecked(WorldBuilder.PlayerManager():PlayerHasTech(i, tc.row.Index), true)
    end
    for _, cc in ipairs(m_civicChecks) do
        cc.cb:SetChecked(WorldBuilder.PlayerManager():PlayerHasCivic(i, cc.row.Index), true)
    end
    RefreshCityTree()
end

-- ===========================================================================
--  Players list (with Add Player / Add AI as rows at the bottom)
-- ===========================================================================

RefreshPlayerList = function()
    if not m_playerList then return end
    local capture = mgr:CaptureFocusKey(m_playerList)
    m_playerList:ClearChildren()
    m_playerRows = {}

    local players = EnumeratePlayers()
    for _, index in ipairs(players) do
        local idx = index
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Player"), "MenuItem", {
            Label = function() return PlayerLabel(idx) end,
            FocusKey = "wbplayer:" .. idx,
        })
        row:SetFocusSound(FOCUS_SOUND)
        -- Focus = selection: entering a player row selects it and reseeds the tabs.
        row:On("focus_enter", function(w)
            if w:IsFocused() and m_selectedIndex ~= idx then
                m_selectedIndex = idx
                RefreshDetail()
            end
        end)
        row:AddInputBinding({
            Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_WB_PE_REMOVE",
            Action = function()
                WorldBuilder.PlayerManager():UninitializePlayer(idx)
                RefreshPlayerList()
                return true
            end,
        })
        m_playerRows[idx] = row
        m_playerList:AddChild(row)
    end

    -- Add Player / Add AI as the last rows in the list (they don't change selection).
    local addPlayer = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_AddPlayer"), "MenuItem", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_BUTTON_ADD_PLAYER") end,
        FocusKey = "wbpe:add",
    })
    addPlayer:SetFocusSound(FOCUS_SOUND)
    addPlayer:On("activate", function() AddPlayerAndFocus(false) end)
    m_playerList:AddChild(addPlayer)

    local addAI = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_AddAI"), "MenuItem", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_BUTTON_ADD_AI_PLAYER") end,
        FocusKey = "wbpe:addai",
    })
    addAI:SetFocusSound(FOCUS_SOUND)
    addAI:On("activate", function() AddPlayerAndFocus(true) end)
    m_playerList:AddChild(addAI)

    -- Keep the selection valid, then reseed the tabs for it.
    local stillThere = false
    for _, index in ipairs(players) do
        if index == m_selectedIndex then stillThere = true break end
    end
    if not stillThere then
        m_selectedIndex = players[1] -- first player, or nil when the list is empty
    end
    RefreshDetail()

    mgr:RestoreFocus(m_playerList, capture)
end

AddPlayerAndFocus = function(bAI)
    local newIdx = WorldBuilder.PlayerManager():AddPlayer(bAI)
    RefreshPlayerList()
    if newIdx ~= nil and newIdx ~= -1 and m_playerRows[newIdx] then
        mgr:SetFocus(m_playerRows[newIdx]) -- focus_enter selects the new player
    end
end

-- ===========================================================================
--  Panel build / open / close
-- ===========================================================================

OpenPanel = function()
    if m_panel or not mgr then return end
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_WORLD_BUILDER_PLAYER_EDITOR_TT") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                -- Mirror the vanilla close path; our show-handler tears down the panel.
                LuaEvents.WorldBuilder_ShowPlayerEditor(false)
                return true
            end,
        },
    })

    m_playerList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_List"), "List", {
        Label = function() return Locale.Lookup("LOC_PLAYERS") end,
    })
    m_panel:AddChild(m_playerList)

    m_tabs = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBPE_Tabs"), "TabControl", {
        Label = function() return Locale.Lookup("LOC_WORLD_BUILDER_PLAYER_EDITOR_TT") end,
    })
    BuildGeneralPage(m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_GENERAL") end))
    BuildTechsPage(m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_TECHS") end))
    BuildCivicsPage(m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_CIVICS") end))
    BuildCitiesPage(m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_CITIES") end))
    m_panel:AddChild(m_tabs)

    RefreshPlayerList()
    mgr:Push(m_panel, { focus = m_playerList })
end

CloseAll = function()
    if not m_panel then return end
    m_playerList    = nil
    m_playerRows    = {}
    m_tabs          = nil
    m_cityTree      = nil
    m_selectedIndex = nil
    m_civDD, m_leaderDD, m_civLevelDD, m_eraDD, m_goldEdit, m_faithEdit = nil, nil, nil, nil, nil, nil
    m_techChecks    = {}
    m_civicChecks   = {}
    m_panel = nil
    mgr:RemoveFromStack(PANEL_ID)
end

-- ===========================================================================
--  Vanilla lifecycle bridge
-- ===========================================================================

-- Same show/hide semantics as the base OnShowPlayerEditor (nil or true = show).
local function OnShowPlayerEditorCAI(bShow)
    if bShow == nil or bShow == true then
        OpenPanel()
    else
        CloseAll()
    end
end
LuaEvents.WorldBuilder_ShowPlayerEditor.Add(OnShowPlayerEditorCAI)

-- Opening the Map Editor hides the Player Editor (vanilla OnShowMapEditor); close ours too.
local function OnShowMapEditorCAI(bShow)
    if bShow == nil or bShow == true then CloseAll() end
end
LuaEvents.WorldBuilder_ShowMapEditor.Add(OnShowMapEditorCAI)

-- When the selected player is edited (e.g. choosing a civ cascades to its default
-- leader), re-seed the General dropdowns/edit boxes so their displayed values
-- track the live config, exactly as vanilla's UpdateGeneralTabValues does.
local function OnPlayerEditedCAI(index)
    if m_panel and index == m_selectedIndex then
        ReseedGeneral()
    end
end
LuaEvents.WorldBuilder_PlayerEdited.Add(OnPlayerEditedCAI)

-- Forward input to the manager while our panel is open. Wrapping the base global
-- (rather than calling ContextPtr:SetInputHandler ourselves) survives the base
-- OnInit re-registering OnInputHandler after this file's top-level code runs.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    return orig(pInputStruct)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    LuaEvents.WorldBuilder_ShowPlayerEditor.Remove(OnShowPlayerEditorCAI)
    LuaEvents.WorldBuilder_ShowMapEditor.Remove(OnShowMapEditorCAI)
    LuaEvents.WorldBuilder_PlayerEdited.Remove(OnPlayerEditedCAI)
    CloseAll()
    orig()
end)
