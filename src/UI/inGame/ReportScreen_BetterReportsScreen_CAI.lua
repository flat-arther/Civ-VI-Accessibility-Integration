-- Better Report Screen (Infixo) accessibility layer. Included by ReportScreen_CAI.lua
-- (the shared builder infrastructure) when the Better Report Screen mod is active
-- and its engine loaded into this context (ViewDealsPage defined).
--
-- BRS replaces the ReportScreen context and removes vanilla GetData(), so this
-- variant supplies the report data through a vendored copy of vanilla GetData()
-- (below, as CAIBRS_GetData) that uses the CitySupport globals BRS still ships
-- (GetCityData/GetCityResourceData/GetWorkedTileYieldData/AddResourceData). That
-- feeds the four shared tabs (Yields, Resources, City Status, Gossip) unchanged.
-- BRS adds five more tabs (Deals, Units, Policy, Minor, Cities2) which this file
-- builds from BRS's own data getters / live game state.
--
-- Shared globals used from ReportScreen_CAI.lua: CAIReports_DataSource,
-- RefreshCAIData, GatherGossip, FilterCAIGossip, and the tab builders
-- RebuildYieldsTree/RebuildResourcesTree/RebuildCityStatusTab/RebuildGossipTab,
-- plus CAIReports_IsCityStatusListMode. City cycling is owned by the shared file.

local mgr                  = ExposedMembers.CAI_UIManager

local PANEL_ID             = "CAIReports_Panel"
local TABS_ID              = "CAIReports_Tabs"
local HOVER_SOUND          = "Main_Menu_Mouse_Over"

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

-- Vendored verbatim from the base game ReportScreen.lua GetData() (BRS removes it),
function CAIBRS_GetData()
	local kResources	:table = {};
	local kCityData		:table = {};
	local kCityTotalData:table = {
		Income	= {},
		Expenses= {},
		Net		= {},
		Treasury= {}
	};
	local kUnitData		:table = {};


	kCityTotalData.Income[YieldTypes.CULTURE]	= 0;
	kCityTotalData.Income[YieldTypes.FAITH]		= 0;
	kCityTotalData.Income[YieldTypes.FOOD]		= 0;
	kCityTotalData.Income[YieldTypes.GOLD]		= 0;
	kCityTotalData.Income[YieldTypes.PRODUCTION]= 0;
	kCityTotalData.Income[YieldTypes.SCIENCE]	= 0;
	kCityTotalData.Income["TOURISM"]			= 0;
	kCityTotalData.Expenses[YieldTypes.GOLD]	= 0;
	
	local playerID	:number = Game.GetLocalPlayer();
	if playerID == PlayerTypes.NONE then
		UI.DataError("Unable to get valid playerID for report screen.");
		return;
	end

	local player	:table  = Players[playerID];
	local pCulture	:table	= player:GetCulture();
	local pTreasury	:table	= player:GetTreasury();
	local pReligion	:table	= player:GetReligion();
	local pScience	:table	= player:GetTechs();
	local pResources:table	= player:GetResources();		

	local pCities = player:GetCities();
	for i, pCity in pCities:Members() do	
		local cityName	:string = pCity:GetName();
			
		-- Big calls, obtain city data and add report specific fields to it.
		local data		:table	= GetCityData( pCity );
		data.Resources			= GetCityResourceData( pCity );					-- Add more data (not in CitySupport)			
		data.WorkedTileYields	= GetWorkedTileYieldData( pCity, pCulture );	-- Add more data (not in CitySupport)
		data.Order= i;

		-- Add to totals.
		kCityTotalData.Income[YieldTypes.CULTURE]	= kCityTotalData.Income[YieldTypes.CULTURE] + data.CulturePerTurn;
		kCityTotalData.Income[YieldTypes.FAITH]		= kCityTotalData.Income[YieldTypes.FAITH] + data.FaithPerTurn;
		kCityTotalData.Income[YieldTypes.FOOD]		= kCityTotalData.Income[YieldTypes.FOOD] + data.FoodPerTurn;
		kCityTotalData.Income[YieldTypes.GOLD]		= kCityTotalData.Income[YieldTypes.GOLD] + data.GoldPerTurn;
		kCityTotalData.Income[YieldTypes.PRODUCTION]= kCityTotalData.Income[YieldTypes.PRODUCTION] + data.ProductionPerTurn;
		kCityTotalData.Income[YieldTypes.SCIENCE]	= kCityTotalData.Income[YieldTypes.SCIENCE] + data.SciencePerTurn;
		kCityTotalData.Income["TOURISM"]			= kCityTotalData.Income["TOURISM"] + data.WorkedTileYields["TOURISM"];
			
		table.insert(kCityData, data);

		-- Add outgoing route data
		data.OutgoingRoutes = pCity:GetTrade():GetOutgoingRoutes();

		-- Add resources
		for eResourceType,amount in pairs(data.Resources) do
			AddResourceData(kResources, eResourceType, cityName, "LOC_HUD_REPORTS_TRADE_OWNED", amount);
		end
	end



	kCityTotalData.Expenses[YieldTypes.GOLD] = pTreasury:GetTotalMaintenance();

	-- NET = Income - Expense
	kCityTotalData.Net[YieldTypes.GOLD]			= kCityTotalData.Income[YieldTypes.GOLD] - kCityTotalData.Expenses[YieldTypes.GOLD];
	kCityTotalData.Net[YieldTypes.FAITH]		= kCityTotalData.Income[YieldTypes.FAITH];

	-- Treasury
	kCityTotalData.Treasury[YieldTypes.CULTURE]		= Round( pCulture:GetCultureYield(), 0 );
	kCityTotalData.Treasury[YieldTypes.FAITH]		= Round( pReligion:GetFaithBalance(), 0 );
	kCityTotalData.Treasury[YieldTypes.GOLD]		= Round( pTreasury:GetGoldBalance(), 0 );
	kCityTotalData.Treasury[YieldTypes.SCIENCE]		= Round( pScience:GetScienceYield(), 0 );
	kCityTotalData.Treasury["TOURISM"]				= Round( kCityTotalData.Income["TOURISM"], 0 );


	-- Units (TODO: Group units by promotion class and determine total maintenance cost)
	local MaintenanceDiscountPerUnit:number = pTreasury:GetMaintDiscountPerUnit();
	local pUnits :table = player:GetUnits(); 	
	for i, pUnit in pUnits:Members() do
		local pUnitInfo:table = GameInfo.Units[pUnit:GetUnitType()];
		local unitTypeKey = pUnitInfo.UnitType;
		local TotalMaintenanceAfterDiscount:number = 0;
		local unitMaintenance = 0;
		local unitName :string = Locale.Lookup(pUnitInfo.Name);
		local unitMilitaryFormation = pUnit:GetMilitaryFormation();
		unitTypeKey = unitTypeKey .. unitMilitaryFormation;
		if (pUnitInfo.Domain == "DOMAIN_SEA") then
			if (unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
				unitName = unitName .. " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_FLEET_SUFFIX");
				unitMaintenance = UnitManager.GetUnitCorpsMaintenance(pUnitInfo.Hash);
			elseif (unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
				unitName = unitName .. " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMADA_SUFFIX");
				unitMaintenance = UnitManager.GetUnitArmyMaintenance(pUnitInfo.Hash);
			else
				unitMaintenance = UnitManager.GetUnitMaintenance(pUnitInfo.Hash);
			end
		else
			if (unitMilitaryFormation == MilitaryFormationTypes.CORPS_FORMATION) then
				unitName = unitName .. " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_CORPS_SUFFIX");
				unitMaintenance = UnitManager.GetUnitCorpsMaintenance(pUnitInfo.Hash);
			elseif (unitMilitaryFormation == MilitaryFormationTypes.ARMY_FORMATION) then
				unitName = unitName .. " " .. Locale.Lookup("LOC_HUD_UNIT_PANEL_ARMY_SUFFIX");
				unitMaintenance = UnitManager.GetUnitArmyMaintenance(pUnitInfo.Hash);
			else
				unitMaintenance = UnitManager.GetUnitMaintenance(pUnitInfo.Hash);
			end
		end

		if (unitMaintenance > 0) then
			TotalMaintenanceAfterDiscount = unitMaintenance - MaintenanceDiscountPerUnit; 
		end
		if TotalMaintenanceAfterDiscount > 0 then
			if kUnitData[unitTypeKey] == nil then
				local UnitEntry:table = {};
				UnitEntry.Name = unitName;
				UnitEntry.Count = 1;
				UnitEntry.Maintenance = TotalMaintenanceAfterDiscount;
				kUnitData[unitTypeKey]= UnitEntry;
			else
				kUnitData[unitTypeKey].Count = kUnitData[unitTypeKey].Count + 1;
				kUnitData[unitTypeKey].Maintenance = kUnitData[unitTypeKey].Maintenance + TotalMaintenanceAfterDiscount;
			end
		end
	end
	
	local kDealData	:table = {};
	local kPlayers	:table = PlayerManager.GetAliveMajors();
	for _, pOtherPlayer in ipairs(kPlayers) do
		local otherID:number = pOtherPlayer:GetID();
		local currentGameTurn = Game.GetCurrentGameTurn();
		if  otherID ~= playerID then			
			
			local pPlayerConfig	:table = PlayerConfigurations[otherID];
			local pDeals		:table = DealManager.GetPlayerDeals(playerID, otherID);
			
			if pDeals ~= nil then
				for i,pDeal in ipairs(pDeals) do
					-- Add outgoing gold deals
					local pOutgoingDeal :table	= pDeal:FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, playerID);
					if pOutgoingDeal ~= nil then
						for i,pDealItem in ipairs(pOutgoingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local gold :number = pDealItem:GetAmount();
								table.insert( kDealData, {
									Type		= DealItemTypes.GOLD,
									Amount		= gold,
									Duration	= remainingTurns,
									IsOutgoing	= true,
									PlayerID	= otherID,
									Name		= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});						
							end
						end
					end

					-- Add outgoing resource deals
					pOutgoingDeal = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, playerID);
					if pOutgoingDeal ~= nil then
						for i,pDealItem in ipairs(pOutgoingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local amount		:number = pDealItem:GetAmount();
								local resourceType	:number = pDealItem:GetValueType();
								table.insert( kDealData, {
									Type			= DealItemTypes.RESOURCES,
									ResourceType	= resourceType,
									Amount			= amount,
									Duration		= remainingTurns,
									IsOutgoing		= true,
									PlayerID		= otherID,
									Name			= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});
								
								local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. " " .. Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", remainingTurns) .. ")";
								AddResourceData(kResources, resourceType, entryString, "LOC_HUD_REPORTS_TRADE_EXPORTED", -1 * amount);				
							end
						end
					end
					
					-- Add incoming gold deals
					local pIncomingDeal :table = pDeal:FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, otherID);
					if pIncomingDeal ~= nil then
						for i,pDealItem in ipairs(pIncomingDeal) do
							local duration		:number = pDealItem:GetDuration();
							local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
							if duration ~= 0 then
								local gold :number = pDealItem:GetAmount()
								table.insert( kDealData, {
									Type		= DealItemTypes.GOLD;
									Amount		= gold,
									Duration	= remainingTurns,
									IsOutgoing	= false,
									PlayerID	= otherID,
									Name		= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});						
							end
						end
					end

					-- Add incoming resource deals
					pIncomingDeal = pDeal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, otherID);
					if pIncomingDeal ~= nil then
						for i,pDealItem in ipairs(pIncomingDeal) do
							local duration		:number = pDealItem:GetDuration();
							if duration ~= 0 then
								local amount		:number = pDealItem:GetAmount();
								local resourceType	:number = pDealItem:GetValueType();
								local remainingTurns:number = duration - (currentGameTurn - pDealItem:GetEnactedTurn());
								table.insert( kDealData, {
									Type			= DealItemTypes.RESOURCES,
									ResourceType	= resourceType,
									Amount			= amount,
									Duration		= remainingTurns,
									IsOutgoing		= false,
									PlayerID		= otherID,
									Name			= Locale.Lookup( pPlayerConfig:GetCivilizationDescription() )
								});
								
								local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_ROW_DIPLOMATIC_DEALS") .. " (" .. Locale.Lookup(pPlayerConfig:GetPlayerName()) .. " " .. Locale.Lookup("LOC_REPORTS_NUMBER_OF_TURNS", remainingTurns) .. ")";
								AddResourceData(kResources, resourceType, entryString, "LOC_HUD_REPORTS_TRADE_IMPORTED", amount);				
							end
						end
					end	
				end							
			end

		end
	end

	-- Add resources provided by city states
	for i, pMinorPlayer in ipairs(PlayerManager.GetAliveMinors()) do
		local pMinorPlayerInfluence:table = pMinorPlayer:GetInfluence();		
		if pMinorPlayerInfluence ~= nil then
			local suzerainID:number = pMinorPlayerInfluence:GetSuzerain();
			if suzerainID == playerID then
				for row in GameInfo.Resources() do
					local resourceAmount:number =  pMinorPlayer:GetResources():GetExportedResourceAmount(row.Index);
					if resourceAmount > 0 then
						local pMinorPlayerConfig:table = PlayerConfigurations[pMinorPlayer:GetID()];
						local entryString:string = Locale.Lookup("LOC_HUD_REPORTS_CITY_STATE") .. " (" .. Locale.Lookup(pMinorPlayerConfig:GetPlayerName()) .. ")";
						AddResourceData(kResources, row.Index, entryString, "LOC_CITY_STATES_SUZERAIN", resourceAmount);
					end
				end
			end
		end
	end

	kResources = AddMiscResourceData(pResources, kResources);

	return kCityData, kCityTotalData, kResources, kUnitData, kDealData;
end

-- The four shared tabs read report data through the shared RefreshCAIData(), which
-- calls this vendored vanilla GetData() copy (BRS removed the original).
CAIReports_DataSource = CAIBRS_GetData

-- ============================================================================
-- Panel / tab state (owned by this variant)
-- ============================================================================
local m_panel              = nil
local m_tabs               = nil
local m_trees              = {}
local m_tabDefs            = {}
local m_capturedTabs       = {}
local m_isMirroringTab     = false
local m_activeTab          = 1
local m_pendingOpenFocusKey = nil

-- ============================================================================
-- Tab descriptors (BRS tab order, honoring capability / expansion gating)
-- ============================================================================
local function BuildTabDefs()
    local defs = {}
    defs[#defs + 1] = { key = "yields",    label = "LOC_HUD_REPORTS_TAB_YIELDS",    kind = "tree" }
    defs[#defs + 1] = { key = "resources", label = "LOC_HUD_REPORTS_TAB_RESOURCES", kind = "tree" }
    defs[#defs + 1] = { key = "city",      label = "LOC_HUD_REPORTS_TAB_CITIES",    kind = "citystatus" }
    if GameCapabilities.HasCapability("CAPABILITY_GOSSIP_REPORT") then
        defs[#defs + 1] = { key = "gossip", label = "LOC_HUD_REPORTS_TAB_GOSSIP", kind = "gossip" }
    end
    defs[#defs + 1] = { key = "deals",  label = "LOC_HUD_REPORTS_TAB_DEALS",    kind = "tree" }
    defs[#defs + 1] = { key = "units",  label = "LOC_HUD_REPORTS_TAB_UNITS",    kind = "units" }
    defs[#defs + 1] = { key = "policy", label = "LOC_HUD_REPORTS_TAB_POLICIES", kind = "tree" }
    defs[#defs + 1] = { key = "minor",  label = "LOC_HUD_REPORTS_TAB_MINORS",   kind = "minor" }
    -- The Cities2 (Gathering Storm power) tab is intentionally not exposed here; its
    -- figures will be merged into the City Status tab. RebuildCities2Tab is kept
    -- below for reference until that merge happens.
    return defs
end

-- ============================================================================
-- Deals tab (BRS global GetDataDeals)
-- ============================================================================
local function RebuildDealsTab(entry)
    local tree = entry.tree
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local deals = GetDataDeals() or {}
    table.sort(deals, function(a, b) return a.EndTurn > b.EndTurn end)
    local currentTurn = Game.GetCurrentGameTurn()

    local shown = 0
    for _, playerDeals in ipairs(deals) do
        if #playerDeals.Deals > 0 then
            shown = shown + 1
            local capturedDeals = playerDeals
            local node = mgr:CreateWidget(MakeId("CAIRPT_Deal"), "TreeItem", {
                Label = function()
                    local parts = { capturedDeals.WithCivilization ..
                        " (" .. tostring(#capturedDeals.Deals) .. ")" }
                    if capturedDeals.GoldBalance ~= 0 then
                        parts[#parts + 1] = "[ICON_Gold]" ..
                            toPlusMinusNoneString(capturedDeals.GoldBalance)
                    end
                    if capturedDeals.EndTurn > 0 then
                        local turns = capturedDeals.EndTurn - currentTurn
                        parts[#parts + 1] = tostring(turns) .. " " ..
                            Locale.Lookup("LOC_HUD_REPORTS_TURNS_UNTIL_COMPLETED", turns)
                    end
                    return table.concat(parts, ", ")
                end,
                FocusKey = "deals:civ:" .. tostring(capturedDeals.WithCivilization),
            })
            node:SetFocusSound(HOVER_SOUND)
            tree:AddChild(node)

            for di, deal in ipairs(playerDeals.Deals) do
                local capturedDeal = deal
                local capturedDI = di
                local leaf = mgr:CreateWidget(MakeId("CAIRPT_DealItem"), "TreeItem", {
                    Label = function()
                        local parts = {}
                        if capturedDeal.Incoming ~= "" then
                            parts[#parts + 1] = Locale.Lookup("LOC_BRS_CURRENT_DEALS_INCOMING") ..
                                " " .. capturedDeal.Incoming
                        end
                        if capturedDeal.Outgoing ~= "" then
                            parts[#parts + 1] = Locale.Lookup("LOC_BRS_CURRENT_DEALS_OUTGOING") ..
                                " " .. capturedDeal.Outgoing
                        end
                        if capturedDeal.EndTurn > 0 then
                            local turns = capturedDeal.EndTurn - currentTurn
                            parts[#parts + 1] = tostring(turns) .. " " ..
                                Locale.Lookup("LOC_HUD_REPORTS_TURNS_UNTIL_COMPLETED", turns)
                        end
                        return table.concat(parts, "[NEWLINE]")
                    end,
                    FocusKey = "deals:item:" .. tostring(capturedDeals.WithCivilization) .. ":" .. capturedDI,
                })
                leaf:SetFocusSound(HOVER_SOUND)
                node:AddChild(leaf)
            end
        end
    end

    if shown == 0 then
        local empty = mgr:CreateWidget(MakeId("CAIRPT_DealEmpty"), "TreeItem", {
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_DEALS_EMPTY") end,
            FocusKey = "deals:empty",
        })
        empty:SetFocusSound(HOVER_SOUND)
        tree:AddChild(empty)
    end

    mgr:RestoreFocus(tree, capture)
end

-- ============================================================================
-- Units tab: dual table/list view of the local player's units, matching the
-- columns the Better Report Screen shows per unit class. Units are grouped by
-- BRS's nine classes (the filter); each class contributes its own columns on top
-- of the common ones. Rows are the shared unit records (inGameHelpers_CAI).
-- ============================================================================
local UNITS_TABLE_ID        = "CAIReports_UnitsTable"
local UNITS_VIEW_SETTING_ID = "ReportsUnitsViewMode"
local m_unitViewMode = (function()
    local stored = tostring(CAI.GetConfigValue("UI", UNITS_VIEW_SETTING_ID, "table")):lower()
    return stored == "list" and "list" or "table"
end)()
local m_unitFilterKey   = "all"
local m_unitSort        = { column = "name", ascending = true }
local m_unitSelectedKey = nil
local m_nearCity        = {}

-- Filter keys match BRS's unit groups; labels reuse BRS's shipped group names.
local UNIT_FILTERS = {
    { key = "all",          label = "LOC_CAI_UNIT_CAT_ALL" },
    { key = "military",     label = "LOC_BRS_UNITS_GROUP_LAND_COMBAT" },
    { key = "naval",        label = "LOC_BRS_UNITS_GROUP_NAVAL" },
    { key = "air",          label = "LOC_BRS_UNITS_GROUP_AIR" },
    { key = "support",      label = "LOC_BRS_UNITS_GROUP_SUPPORT" },
    { key = "civilian",     label = "LOC_BRS_UNITS_GROUP_CIVILIAN" },
    { key = "religious",    label = "LOC_BRS_UNITS_GROUP_RELIGIOUS" },
    { key = "great_person", label = "LOC_BRS_UNITS_GROUP_GREAT_PERSON" },
    { key = "spy",          label = "LOC_BRS_UNITS_GROUP_SPY" },
    { key = "trader",       label = "LOC_BRS_UNITS_GROUP_TRADER" },
}

-- BRS categorization (BRSPage_Units GetDataUnits): civilians are split into
-- great person / trader / spy / religious / civilian; combat by formation class.
local function ReportUnitGroup(unit)
    if unit == nil then return "support" end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info == nil then return "support" end
    local fc = info.FormationClass
    if fc == "FORMATION_CLASS_CIVILIAN" then
        if unit:GetGreatPerson():IsGreatPerson() then return "great_person" end
        if info.MakeTradeRoute then return "trader" end
        if info.Spy then return "spy" end
        if unit:GetReligiousStrength() > 0 then return "religious" end
        return "civilian"
    elseif fc == "FORMATION_CLASS_LAND_COMBAT" then return "military"
    elseif fc == "FORMATION_CLASS_NAVAL" then return "naval"
    elseif fc == "FORMATION_CLASS_AIR" then return "air"
    elseif fc == "FORMATION_CLASS_SUPPORT" then return "support"
    end
    return "support"
end

local function IsMilitaryFilter(key)
    return key == "military" or key == "naval" or key == "air" or key == "support"
end

-- Compute the nearest city for every local unit (BRS shows a city column with the
-- distance); rebuilt each time the tab is rebuilt.
local function BuildNearCityCache()
    m_nearCity = {}
    local localID = Game.GetLocalPlayer()
    local player = localID >= 0 and Players[localID] or nil
    if player == nil then return end
    local units = {}
    for _, u in player:GetUnits():Members() do
        m_nearCity[u:GetID()] = { dist = 9999, name = "", isCapital = false, isOurs = true }
        units[#units + 1] = u
    end
    for _, p in ipairs(PlayerManager.GetAlive()) do
        local isOurs = (p:GetID() == localID)
        for _, city in p:GetCities():Members() do
            local cx, cy = city:GetX(), city:GetY()
            local cname = Locale.Lookup(city:GetName())
            local cap = city:IsCapital()
            for _, u in ipairs(units) do
                local d = Map.GetPlotDistance(u:GetX(), u:GetY(), cx, cy)
                local rec = m_nearCity[u:GetID()]
                if d < rec.dist then
                    rec.dist = d; rec.name = cname; rec.isCapital = cap; rec.isOurs = isOurs
                end
            end
        end
    end
end

-- ---------------------------------------------------------------------------
-- Per-unit field getters (each takes a record and resolves the live unit)
-- ---------------------------------------------------------------------------
local function UnitNetMaintenance(unit)
    if unit == nil or GetUnitMaintenance == nil then return 0 end
    local maint = GetUnitMaintenance(unit) or 0
    local localPlayer = Players[Game.GetLocalPlayer()]
    local discount = localPlayer and localPlayer:GetTreasury():GetMaintDiscountPerUnit() or 0
    return math.max(0, maint - discount)
end

-- Reuse the unit panel's readiness logic (inGameHelpers_CAI): it is based on
-- IsReadyToMove(), so a spy on a mission or a trader on a route reads as busy,
-- not "ready", instead of keying off leftover movement.
local function UnitStatusText(unit)
    return CAI_GetUnitActivityStatus(unit) or ""
end

local function UnitMovesText(unit)
    if unit == nil then return "" end
    if unit:GetFormationUnitCount() > 1 then
        return tostring(unit:GetFormationMovesRemaining()) .. "/" ..
            tostring(unit:GetFormationMaxMoves()) .. " [ICON_Formation]"
    end
    return tostring(unit:GetMovesRemaining()) .. "/" .. tostring(unit:GetMaxMoves())
end

local function UnitCityText(unit)
    if unit == nil then return "" end
    local nc = m_nearCity[unit:GetID()]
    if nc == nil or nc.dist > 3 then return "" end
    local s = (nc.isCapital and "[ICON_Capital]" or "") .. nc.name
    if nc.dist > 0 then s = s .. " " .. tostring(nc.dist) end
    return s
end

local function UnitCityDist(unit)
    if unit == nil then return nil end
    local nc = m_nearCity[unit:GetID()]
    return nc and nc.dist or nil
end

local function UnitLevel(unit)
    local exp = unit and unit:GetExperience() or nil
    return exp and exp:GetLevel() or 0
end

local function UnitExpText(unit)
    local exp = unit and unit:GetExperience() or nil
    if exp == nil then return "" end
    return tostring(exp:GetExperiencePoints()) .. "/" .. tostring(exp:GetExperienceForNextLevel())
end

local function UnitExpValue(unit)
    local exp = unit and unit:GetExperience() or nil
    return exp and exp:GetExperiencePoints() or nil
end

local function UnitHealthValue(unit)
    if unit == nil then return 0 end
    local maximum = unit:GetMaxDamage()
    if maximum == nil or maximum <= 0 then return 0 end
    return maximum - (unit:GetDamage() or 0)
end

local function UnitHealthText(unit)
    if unit == nil then return "" end
    local maximum = unit:GetMaxDamage()
    if maximum == nil or maximum <= 0 then return "" end
    return tostring(UnitHealthValue(unit)) .. "/" .. tostring(maximum)
end

local function UnitBuildCharges(unit)
    return unit and (unit:GetBuildCharges() or 0) or 0
end

local function UnitAlbums(unit)
    if unit == nil or not bIsGatheringStorm then return 0 end
    local info = GameInfo.Units[unit:GetUnitType()]
    if info and info.PromotionClass == "PROMOTION_CLASS_ROCK_BAND" then
        return unit:GetRockBand():GetAlbumSales() or 0
    end
    return 0
end

local function UnitGreatPersonClass(unit)
    if unit == nil then return "" end
    local gp = unit:GetGreatPerson()
    if gp == nil or not gp:IsGreatPerson() then return "" end
    local classInfo = GameInfo.GreatPersonClasses[gp:GetClass()]
    return classInfo and Locale.Lookup(classInfo.Name) or ""
end

local function UnitSpreadCharges(unit)
    return unit and (unit:GetSpreadCharges() or 0) or 0
end

local function UnitReligiousStrength(unit)
    return unit and (unit:GetReligiousStrength() or 0) or 0
end

local function UnitSpyOperationText(unit)
    if unit == nil then return "" end
    -- The mission column is only meaningful for spies; other units (shown under
    -- the "all" filter) read as unavailable rather than a bare dash.
    if ReportUnitGroup(unit) ~= "spy" then return Locale.Lookup("LOC_CAI_STATE_DISABLED") end
    local op = unit:GetSpyOperation()
    if op == nil or op == -1 then return "-" end
    local info = GameInfo.UnitOperations[op]
    if info and info.Description then return Locale.Lookup(info.Description) end
    return Locale.Lookup("LOC_UNITOPERATION_SPY_COUNTERSPY_DESCRIPTION")
end

local function UnitSpyTurns(unit)
    if unit == nil then return nil end
    local op = unit:GetSpyOperation()
    if op == nil or op == -1 then return nil end
    return unit:GetSpyOperationEndTurn() - Game.GetCurrentGameTurn()
end

local function UnitMelee(unit) return unit and (unit:GetCombat() or 0) or 0 end
local function UnitRanged(unit) return unit and (unit:GetRangedCombat() or 0) or 0 end
local function UnitBombard(unit) return unit and (unit:GetBombardCombat() or 0) or 0 end
local function UnitRange(unit) return unit and (unit:GetRange() or 0) or 0 end

-- One "Charges" figure covering build (workers), spread/heal (religious), and
-- other action charges, so a single column serves civilian and religious units.
local function UnitChargeCount(unit)
    if unit == nil then return 0 end
    return math.max(unit:GetBuildCharges() or 0, unit:GetSpreadCharges() or 0,
        unit:GetReligiousHealCharges() or 0, unit:GetActionCharges() or 0)
end

local function UnitPromotionsTooltip(unit)
    if unit == nil then return "" end
    local info = GameInfo.Units[unit:GetUnitType()]
    local parts = {}
    if info then
        -- The row/list label already speaks the unit's name. Only repeat the type
        -- name here when it differs (renamed or numbered units); otherwise skip it
        -- so identical names are not read twice.
        local typeName = Locale.Lookup(info.Name)
        if typeName ~= Locale.Lookup(unit:GetName()) then
            parts[#parts + 1] = typeName
        end
        if info.Description then parts[#parts + 1] = Locale.Lookup(info.Description) end
    end
    local exp = unit:GetExperience()
    local promotions = exp and exp:GetPromotions() or nil
    if promotions then
        for _, promo in ipairs(promotions) do
            local pInfo = GameInfo.UnitPromotions[promo]
            if pInfo then
                parts[#parts + 1] = Locale.Lookup(pInfo.Name) .. ": " .. Locale.Lookup(pInfo.Description)
            end
        end
    end
    return table.concat(parts, "[NEWLINE]")
end

-- ---------------------------------------------------------------------------
-- Column definitions
-- ---------------------------------------------------------------------------
local LOW_HIGH_ASC  = "LOC_CAI_SORT_LOWEST_FIRST"
local LOW_HIGH_DESC = "LOC_CAI_SORT_HIGHEST_FIRST"

local function TextColumn(key, headerTag, cellFn, sortFn, ascTag, descTag)
    return {
        key = key,
        header = function() return Locale.Lookup(headerTag) end,
        getCell = function(record) return cellFn(ResolveUnitRecord(record)) end,
        sortKey = sortFn and function(record) return sortFn(ResolveUnitRecord(record)) end or nil,
        sortAscendingDescription = ascTag or "LOC_CAI_SORT_A_TO_Z",
        sortDescendingDescription = descTag or "LOC_CAI_SORT_Z_TO_A",
    }
end

local function NumberColumn(key, headerTag, getter)
    return TextColumn(key, headerTag,
        function(unit) return unit and tostring(getter(unit)) or "" end,
        function(unit) return unit and getter(unit) or nil end,
        LOW_HIGH_ASC, LOW_HIGH_DESC)
end

local function CommonColumns()
    return {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME") end,
            getCell = function(record)
                local u = ResolveUnitRecord(record)
                return u and Locale.Lookup(u:GetName()) or ""
            end,
            getTooltip = function(record) return UnitPromotionsTooltip(ResolveUnitRecord(record)) end,
            sortKey = function(record)
                local u = ResolveUnitRecord(record)
                return u and Locale.Lookup(u:GetName()) or ""
            end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        TextColumn("status", "LOC_CAI_UNIT_LIST_COLUMN_ACTIVITY", UnitStatusText, UnitStatusText),
        {
            key = "moves",
            header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_CURRENT_MOVES") end,
            getCell = function(record) return UnitMovesText(ResolveUnitRecord(record)) end,
            sortKey = function(record)
                local u = ResolveUnitRecord(record)
                return u and u:GetMovesRemaining() or nil
            end,
            sortAscendingDescription = LOW_HIGH_ASC,
            sortDescendingDescription = LOW_HIGH_DESC,
        },
        {
            key = "city",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_CITY") end,
            getCell = function(record) return UnitCityText(ResolveUnitRecord(record)) end,
            sortKey = function(record) return UnitCityDist(ResolveUnitRecord(record)) end,
            sortAscendingDescription = "LOC_CAI_SORT_NEAREST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_FARTHEST_FIRST",
        },
        NumberColumn("maintenance", "LOC_CAI_REPORTS_UNIT_MAINTENANCE", UnitNetMaintenance),
    }
end

local function MilitaryColumns()
    return {
        NumberColumn("level", "LOC_BRS_HEADER_LEVEL", UnitLevel),
        {
            key = "experience",
            header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_XP") end,
            getCell = function(record) return UnitExpText(ResolveUnitRecord(record)) end,
            sortKey = function(record) return UnitExpValue(ResolveUnitRecord(record)) end,
            sortAscendingDescription = LOW_HIGH_ASC,
            sortDescendingDescription = LOW_HIGH_DESC,
        },
        {
            key = "health",
            header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_HEALTH") end,
            getCell = function(record) return UnitHealthText(ResolveUnitRecord(record)) end,
            sortKey = function(record) return UnitHealthValue(ResolveUnitRecord(record)) end,
            sortAscendingDescription = LOW_HIGH_ASC,
            sortDescendingDescription = LOW_HIGH_DESC,
        },
        -- Strength columns grouped together, matching the unit panel: melee,
        -- ranged, bombard, religious strength, then range.
        NumberColumn("melee", "LOC_HUD_UNIT_PANEL_STRENGTH", UnitMelee),
        NumberColumn("ranged", "LOC_HUD_UNIT_PANEL_RANGED_STRENGTH", UnitRanged),
        NumberColumn("bombard", "LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH", UnitBombard),
        NumberColumn("religiousstrength", "LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH", UnitReligiousStrength),
        NumberColumn("range", "LOC_CAI_ICON_RANGE_ALIAS", UnitRange),
    }
end

local function CivilianColumns()
    local cols = { NumberColumn("charges", "LOC_HUD_UNIT_PANEL_CHARGES", UnitChargeCount) }
    if bIsGatheringStorm then
        cols[#cols + 1] = NumberColumn("albums", "LOC_CAI_REPORTS_COL_ALBUMS", UnitAlbums)
    end
    return cols
end

local function GreatColumns()
    return {
        TextColumn("gpclass", "LOC_BRS_HEADER_CLASS", UnitGreatPersonClass, UnitGreatPersonClass),
        NumberColumn("level", "LOC_BRS_HEADER_LEVEL", UnitLevel),
    }
end

local function ReligiousColumns()
    return {
        -- Spread charges share the single "Charges" column; religious strength and
        -- range sit with the other strength columns.
        NumberColumn("charges", "LOC_HUD_UNIT_PANEL_CHARGES", UnitChargeCount),
        NumberColumn("religiousstrength", "LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH", UnitReligiousStrength),
        NumberColumn("range", "LOC_CAI_ICON_RANGE_ALIAS", UnitRange),
    }
end

-- Trade route origin->destination and yields for a trader (BRS group_trader):
-- scan the owner's cities' outgoing routes for one whose trader is this unit.
local function FindUnitTradeRoute(unit)
    if unit == nil then return nil, nil, nil end
    local owner = Players[unit:GetOwner()]
    if owner == nil then return nil, nil, nil end
    local cities = owner:GetCities()
    for _, city in cities:Members() do
        for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
            if route.TraderUnitID == unit:GetID() then
                local originCity = cities:FindID(route.OriginCityID)
                local destPlayer = Players[route.DestinationCityPlayer]
                local destCity = destPlayer and destPlayer:GetCities():FindID(route.DestinationCityID) or nil
                return route, originCity, destCity
            end
        end
    end
    return nil, nil, nil
end

local function UnitTradeRoute(unit)
    if unit == nil then return "" end
    -- The route column is only meaningful for traders; other units (shown under
    -- the "all" filter) read as unavailable rather than "make trade route".
    if ReportUnitGroup(unit) ~= "trader" then return Locale.Lookup("LOC_CAI_STATE_DISABLED") end
    local _, originCity, destCity = FindUnitTradeRoute(unit)
    if originCity and destCity then
        return Locale.Lookup("LOC_HUD_UNIT_PANEL_TRADE_ROUTE_NAME", originCity:GetName(), destCity:GetName())
    end
    return Locale.Lookup("LOC_UNITOPERATION_MAKE_TRADE_ROUTE_DESCRIPTION")
end

local function UnitTradeYields(unit)
    if unit == nil then return "" end
    -- Yields, like the route column, only apply to traders; other units read as
    -- unavailable rather than blank under the "all" filter.
    if ReportUnitGroup(unit) ~= "trader" then return Locale.Lookup("LOC_CAI_STATE_DISABLED") end
    local route = FindUnitTradeRoute(unit)
    if route == nil then return "" end
    local parts = {}
    for _, yieldInfo in pairs(route.OriginYields or {}) do
        if yieldInfo.Amount > 0 then
            local yInfo = GameInfo.Yields[yieldInfo.YieldIndex]
            if yInfo then
                parts[#parts + 1] = yInfo.IconString .. toPlusMinusString(yieldInfo.Amount)
            end
        end
    end
    return table.concat(parts, " ")
end

local function UnitTradeYieldsTotal(unit)
    local route = FindUnitTradeRoute(unit)
    if route == nil then return 0 end
    local total = 0
    for _, yieldInfo in pairs(route.OriginYields or {}) do
        if yieldInfo.Amount > 0 then total = total + yieldInfo.Amount end
    end
    return total
end

local function SpyColumns()
    return {
        TextColumn("operation", "LOC_BRS_HEADER_MISSION", UnitSpyOperationText, UnitSpyOperationText),
        NumberColumn("turns", "LOC_CAI_REPORTS_COL_TURNS", function(u) return UnitSpyTurns(u) or 0 end),
    }
end

local function TraderColumns()
    return {
        TextColumn("route", "LOC_BRS_HEADER_ROUTE", UnitTradeRoute, UnitTradeRoute),
        -- Yields cell shows the per-yield breakdown but sorts by the total amount.
        {
            key = "routeyields",
            header = function() return Locale.Lookup("LOC_BRS_HEADER_YIELDS") end,
            getCell = function(record) return UnitTradeYields(ResolveUnitRecord(record)) end,
            sortKey = function(record) return UnitTradeYieldsTotal(ResolveUnitRecord(record)) end,
            sortAscendingDescription = LOW_HIGH_ASC,
            sortDescendingDescription = LOW_HIGH_DESC,
        },
    }
end

local function ColumnsForFilter(filterKey)
    local cols = CommonColumns()
    local function add(list) for _, c in ipairs(list) do cols[#cols + 1] = c end end
    if filterKey == "all" then
        add(MilitaryColumns())
        add(CivilianColumns())
        add(GreatColumns())
        add(ReligiousColumns())
        add(SpyColumns())
        add(TraderColumns())
    elseif IsMilitaryFilter(filterKey) then
        add(MilitaryColumns())
    elseif filterKey == "civilian" then
        add(CivilianColumns())
    elseif filterKey == "great_person" then
        add(GreatColumns())
    elseif filterKey == "religious" then
        add(ReligiousColumns())
    elseif filterKey == "spy" then
        add(SpyColumns())
    elseif filterKey == "trader" then
        add(TraderColumns())
    end
    -- Deduplicate by key (level appears in both military and great-person sets).
    local seen, unique = {}, {}
    for _, c in ipairs(cols) do
        if not seen[c.key] then seen[c.key] = true; unique[#unique + 1] = c end
    end
    return unique
end

local function GetUnitColumns()
    return ColumnsForFilter(m_unitFilterKey)
end

local function FindUnitColumn(key)
    for _, column in ipairs(GetUnitColumns()) do
        if column.key == key then return column end
    end
    return nil
end

local function GetFilteredUnitRecords()
    local records = {}
    for _, record in ipairs(BuildLocalUnitRecords()) do
        local unit = ResolveUnitRecord(record)
        if unit and (m_unitFilterKey == "all" or ReportUnitGroup(unit) == m_unitFilterKey) then
            records[#records + 1] = record
        end
    end
    return records
end

local function GetSortedUnitRecords()
    local records = GetFilteredUnitRecords()
    local column = FindUnitColumn(m_unitSort.column) or FindUnitColumn("name")
    if column and column.sortKey then
        local ascending = m_unitSort.ascending
        table.sort(records, function(a, b)
            local av, bv = column.sortKey(a), column.sortKey(b)
            if av == nil and bv == nil then return false end
            if av == nil then return false end
            if bv == nil then return true end
            if av == bv then return a.UnitID < b.UnitID end
            if type(av) == "string" then
                local cmp = Locale.Compare(av, bv)
                if ascending then return cmp < 0 else return cmp > 0 end
            end
            if ascending then return av < bv else return av > bv end
        end)
    end
    return records
end

local function UnitFullTooltip(record)
    local unit = ResolveUnitRecord(record)
    if unit == nil then return "" end
    local parts = {}
    -- List-view tooltip: each field reads "Label: value" so the label and value
    -- are clearly separated for the screen reader.
    local function add(labelTag, value)
        if value ~= nil and value ~= "" then
            parts[#parts + 1] = Locale.Lookup(labelTag) .. ": " .. tostring(value)
        end
    end
    parts[#parts + 1] = UnitPromotionsTooltip(unit)
    add("LOC_CAI_UNIT_LIST_COLUMN_ACTIVITY", UnitStatusText(unit))
    add("LOC_CAI_UNIT_LIST_COLUMN_CURRENT_MOVES", UnitMovesText(unit))
    add("LOC_CAI_REPORTS_COL_CITY", UnitCityText(unit))
    local group = ReportUnitGroup(unit)
    if IsMilitaryFilter(group) then
        add("LOC_BRS_HEADER_LEVEL", UnitLevel(unit))
        add("LOC_HUD_UNIT_PANEL_XP", UnitExpText(unit))
        add("LOC_CAI_UNIT_LIST_COLUMN_HEALTH", UnitHealthText(unit))
        if UnitMelee(unit) > 0 then add("LOC_HUD_UNIT_PANEL_STRENGTH", UnitMelee(unit)) end
        if UnitRanged(unit) > 0 then add("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH", UnitRanged(unit)) end
        if UnitBombard(unit) > 0 then add("LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH", UnitBombard(unit)) end
        if UnitRange(unit) > 0 then add("LOC_CAI_ICON_RANGE_ALIAS", UnitRange(unit)) end
    elseif group == "great_person" then
        add("LOC_BRS_HEADER_CLASS", UnitGreatPersonClass(unit))
        add("LOC_BRS_HEADER_LEVEL", UnitLevel(unit))
    elseif group == "religious" then
        add("LOC_HUD_UNIT_PANEL_CHARGES", UnitChargeCount(unit))
        add("LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH", UnitReligiousStrength(unit))
    elseif group == "spy" then
        add("LOC_BRS_HEADER_MISSION", UnitSpyOperationText(unit))
        add("LOC_CAI_REPORTS_COL_TURNS", UnitSpyTurns(unit))
    elseif group == "trader" then
        add("LOC_BRS_HEADER_ROUTE", UnitTradeRoute(unit))
        add("LOC_BRS_HEADER_YIELDS", UnitTradeYields(unit))
    elseif group == "civilian" then
        add("LOC_HUD_UNIT_PANEL_CHARGES", UnitChargeCount(unit))
        if bIsGatheringStorm then add("LOC_CAI_REPORTS_COL_ALBUMS", UnitAlbums(unit)) end
    end
    local net = UnitNetMaintenance(unit)
    if net > 0 then
        add("LOC_CAI_REPORTS_UNIT_MAINTENANCE", "[ICON_Gold]" .. tostring(net))
    end
    return table.concat(parts, "[NEWLINE]")
end

-- List row label is the unit name only; all state lives in the tooltip.
local function UnitListItemLabel(record)
    local unit = ResolveUnitRecord(record)
    return unit and Locale.Lookup(unit:GetName()) or ""
end

local function ActivateUnitRecordFromReport(record)
    -- The report may be open away from the map; close it first, then select the
    -- unit and look at it.
    return SelectUnitRecord(record, function() Close() end)
end

local function RebuildUnitsList(list)
    if list == nil then return end
    local capture = mgr:CaptureFocusKey(list)
    list:ClearChildren()

    local records = GetSortedUnitRecords()
    for _, record in ipairs(records) do
        local capturedRecord = record
        local item = mgr:CreateWidget(MakeId("CAIRPT_Unit"), "Button", {
            Label = function() return UnitListItemLabel(capturedRecord) end,
            Tooltip = function() return UnitFullTooltip(capturedRecord) end,
            FocusKey = UnitRecordFocusKey(record.PlayerID, record.UnitID),
        })
        item:SetFocusSound(HOVER_SOUND)
        item:On("activate", function() return ActivateUnitRecordFromReport(capturedRecord) end)
        list:AddChild(item)
    end

    if #records == 0 then
        list:AddChild(mgr:CreateWidget(MakeId("CAIRPT_UnitEmpty"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_REPORTS_UNITS_EMPTY") end,
            FocusKey = "units:empty",
        }))
    end

    mgr:RestoreFocus(list, capture)
end

local function BuildUnitSortOptions()
    local options = {}
    for _, column in ipairs(GetUnitColumns()) do
        if column.sortKey then
            local header = column.header()
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            }
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            }
        end
    end
    return options
end

local function SetUnitViewMode(entry, viewMode)
    if viewMode ~= "table" and viewMode ~= "list" then return false end
    if m_unitViewMode ~= viewMode then
        m_unitViewMode = viewMode
        CAI.SetConfigValue("UI", UNITS_VIEW_SETTING_ID, viewMode)
    end
    local activeView = viewMode == "table" and entry.table or entry.tree
    if activeView then mgr:SetFocus(activeView) end
    return true
end

local function SyncUnitSortDropdown(entry)
    if entry.sortDropdown == nil then return end
    local options = BuildUnitSortOptions()
    entry.sortDropdown:SetOptions(options)
    for i, opt in ipairs(options) do
        if opt.value.column == m_unitSort.column and opt.value.ascending == m_unitSort.ascending then
            entry.sortDropdown:SetSelectedIndex(i, true)
            return
        end
    end
    if options[1] then entry.sortDropdown:SetSelectedIndex(1, true) end
end

local function EnsureUnitControls(entry)
    if entry.table then return end
    local page = entry.page
    if not page then return end

    entry.table = mgr:CreateWidget(UNITS_TABLE_ID, "DataTable", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TAB_UNITS") end,
        HiddenPredicate = function() return m_unitViewMode ~= "table" end,
    })
    entry.table:SetColumns(GetUnitColumns())
    entry.table:SetRowsProvider(function() return GetFilteredUnitRecords() end)
    entry.table:SetRowKeyGetter(function(record) return UnitRecordFocusKey(record.PlayerID, record.UnitID) end)
    entry.table:SetRowLabelGetter(function(record)
        local u = ResolveUnitRecord(record)
        return u and Locale.Lookup(u:GetName()) or ""
    end)
    entry.table:SetDefaultSort({ column = m_unitSort.column, ascending = m_unitSort.ascending })
    entry.table:On("row_focus_enter", function(_, record, rowIndex)
        if rowIndex and rowIndex > 0 then
            m_unitSelectedKey = UnitRecordFocusKey(record.PlayerID, record.UnitID)
        end
    end)
    entry.table:On("row_activate", function(_, record) return ActivateUnitRecordFromReport(record) end)
    entry.table:On("sort_changed", function(_, columnKey, ascending)
        m_unitSort = { column = columnKey or "name", ascending = ascending == true }
        SyncUnitSortDropdown(entry)
    end)
    page:AddChild(entry.table)

    -- Class filter (drives which columns and rows are shown).
    local filterOptions = {}
    for _, filter in ipairs(UNIT_FILTERS) do
        filterOptions[#filterOptions + 1] = { label = Locale.Lookup(filter.label), value = filter.key }
    end
    entry.filter = mgr:CreateWidget(MakeId("CAIRPT_UnitFilter"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_UNIT_FILTER") end,
        FocusKey = "units:filter",
    })
    entry.filter:SetOptions(filterOptions)
    for i, opt in ipairs(filterOptions) do
        if opt.value == m_unitFilterKey then entry.filter:SetSelectedIndex(i, true); break end
    end
    entry.filter:On("value_changed", function(_, value)
        m_unitFilterKey = value
        if FindUnitColumn(m_unitSort.column) == nil then
            m_unitSort = { column = "name", ascending = true }
        end
        if entry.table then
            entry.table:SetColumns(GetUnitColumns())
            entry.table:SetDefaultSort({ column = m_unitSort.column, ascending = m_unitSort.ascending })
            entry.table:Rebuild()
        end
        SyncUnitSortDropdown(entry)
        RebuildUnitsList(entry.tree)
    end)
    page:AddChild(entry.filter)

    -- Sort dropdown (list mode only; the table sorts via its column headers).
    entry.sortDropdown = mgr:CreateWidget(MakeId("CAIRPT_UnitSort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "units:sort",
        HiddenPredicate = function() return m_unitViewMode ~= "list" end,
    })
    SyncUnitSortDropdown(entry)
    entry.sortDropdown:On("value_changed", function(_, value)
        m_unitSort = { column = value.column, ascending = value.ascending }
        if entry.table then
            entry.table:SetDefaultSort({ column = value.column, ascending = value.ascending })
        end
        RebuildUnitsList(entry.tree)
    end)
    page:AddChild(entry.sortDropdown)

    -- Switch view button.
    entry.switchView = mgr:CreateWidget(MakeId("CAIRPT_UnitSwitch"), "Button", {
        Label = function()
            return Locale.Lookup(m_unitViewMode == "table"
                and "LOC_CAI_REPORTS_SWITCH_TO_LIST" or "LOC_CAI_REPORTS_SWITCH_TO_TABLE")
        end,
        FocusKey = "units:switch-view",
    })
    entry.switchView:On("activate", function()
        return SetUnitViewMode(entry, m_unitViewMode == "table" and "list" or "table")
    end)
    page:AddChild(entry.switchView)

    page:AddInputBindings({
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_REPORTS_SWITCH_TO_TABLE",
            Action = function() return SetUnitViewMode(entry, "table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_REPORTS_SWITCH_TO_LIST",
            Action = function() return SetUnitViewMode(entry, "list") end,
        },
    })
end

local function RebuildUnitsTab(entry)
    BuildNearCityCache()
    EnsureUnitControls(entry)
    RebuildUnitsList(entry.tree)
    if entry.table then entry.table:Rebuild() end
end

-- ============================================================================
-- Policy tab (BRS global m_kPolicyData via UpdatePolicyData)
-- ============================================================================
local POLICY_SLOT_ORDER = {
    SLOT_MILITARY = 1, SLOT_ECONOMIC = 2, SLOT_DIPLOMATIC = 3, SLOT_GREAT_PERSON = 4,
    SLOT_WILDCARD = 5, SLOT_DARKAGE = 6, SLOT_PANTHEON = 7, SLOT_FOLLOWER = 8,
}
local POLICY_SLOT_NAME_EXCEPTIONS = {
    SLOT_GREAT_PERSON = "LOC_PEDIA_GOVERNMENTS_PAGEGROUP_GREATPEOPLE_POLICIES_NAME",
    SLOT_PANTHEON     = "LOC_PEDIA_RELIGIONS_PAGEGROUP_PANTHEON_BELIEFS_NAME",
    SLOT_FOLLOWER     = "LOC_PEDIA_RELIGIONS_PAGEGROUP_FOLLOWER_BELIEFS_NAME",
}

local function PolicyGroupName(slot)
    if POLICY_SLOT_NAME_EXCEPTIONS[slot] then
        return Locale.Lookup(POLICY_SLOT_NAME_EXCEPTIONS[slot])
    end
    return Locale.Lookup((string.gsub(slot, "SLOT_", "LOC_GOVT_POLICY_TYPE_")))
end

local POLICY_TABLE_ID        = "CAIReports_PolicyTable"
local POLICY_VIEW_SETTING_ID = "ReportsPolicyViewMode"
local m_policyViewMode = (function()
    local stored = tostring(CAI.GetConfigValue("UI", POLICY_VIEW_SETTING_ID, "table")):lower()
    return stored == "tree" and "tree" or "table"
end)()
local m_policySort = { column = "name", ascending = true }

local function PolicyYieldsSummary(policy)
    local parts = {}
    for yield, value in pairs(policy.Yields or {}) do
        if value ~= 0 then
            parts[#parts + 1] = toPlusMinusNoneString(value) .. " " .. tostring(yield)
        end
    end
    return table.concat(parts, ", ")
end

-- Scalar magnitude of a policy's yields, used only to sort impact high-to-low.
local function PolicyImpactTotal(policy)
    local total = 0
    for _, value in pairs(policy.Yields or {}) do total = total + value end
    return total
end

-- Status sort bands: active+slotted first (0), active (1), inactive last (2).
local function PolicyStatusBand(policy)
    if policy.IsActive and policy.IsSlotted then return 0 end
    if policy.IsActive then return 1 end
    return 2
end

local function PolicyStatusText(policy)
    if policy.IsActive and policy.IsSlotted then
        return Locale.Lookup("LOC_CAI_UNIT_ACTION_ACTIVE") ..
            ", " .. Locale.Lookup("LOC_CAI_REPORTS_POLICY_SLOTTED")
    end
    if policy.IsActive then return Locale.Lookup("LOC_CAI_UNIT_ACTION_ACTIVE") end
    return Locale.Lookup("LOC_CAI_UNIT_ACTION_INACTIVE")
end

-- Slots ordered the same way for both the tree groups and the flat table rows.
local function SortedPolicySlots(data)
    local slots = {}
    for slot in pairs(data) do slots[#slots + 1] = slot end
    table.sort(slots, function(a, b)
        return (POLICY_SLOT_ORDER[a] or 99) < (POLICY_SLOT_ORDER[b] or 99)
    end)
    return slots
end

local m_policyColumns = nil
local function GetPolicyColumns()
    if m_policyColumns then return m_policyColumns end
    m_policyColumns = {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME") end,
            getCell = function(policy) return policy.Name end,
            getTooltip = function(policy) return policy.Description or "" end,
            sortKey = function(policy) return policy.Name end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "type",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_TYPE") end,
            getCell = function(policy) return PolicyGroupName(policy.Slot) end,
            sortKey = function(policy) return PolicyGroupName(policy.Slot) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "status",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_COLUMN_STATUS") end,
            getCell = PolicyStatusText,
            sortKey = PolicyStatusBand,
            sortAscendingDescription = "LOC_CAI_SORT_ACTIVE_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_INACTIVE_FIRST",
        },
        {
            key = "impact",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_IMPACT") end,
            getCell = function(policy) return PolicyYieldsSummary(policy) end,
            sortKey = function(policy) return PolicyImpactTotal(policy) end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    return m_policyColumns
end

local function FindPolicyColumn(key)
    for _, column in ipairs(GetPolicyColumns()) do
        if column.key == key then return column end
    end
    return nil
end

local function PolicyPasses(policy, hideInactive, hideNoImpact)
    local passInactive = (not hideInactive) or policy.IsActive
    local passImpact = (not hideNoImpact) or policy.IsImpact
    return passInactive and passImpact
end

local function PolicyFilters()
    local hideInactive = Controls.HideInactivePoliciesCheckbox
        and Controls.HideInactivePoliciesCheckbox:IsSelected()
    local hideNoImpact = Controls.HideNoImpactPoliciesCheckbox
        and Controls.HideNoImpactPoliciesCheckbox:IsSelected()
    return hideInactive, hideNoImpact
end

-- Flat, filtered policy rows for the table view (each carries its slot).
local function GetPolicyRows()
    if g_DirtyFlag.POLICY then UpdatePolicyData() end
    local data = m_kPolicyData or {}
    local hideInactive, hideNoImpact = PolicyFilters()
    local rows = {}
    for _, slot in ipairs(SortedPolicySlots(data)) do
        for _, policy in ipairs(data[slot] or {}) do
            if PolicyPasses(policy, hideInactive, hideNoImpact) then
                policy.Slot = slot
                rows[#rows + 1] = policy
            end
        end
    end
    return rows
end

local function RebuildPolicyTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    if g_DirtyFlag.POLICY then UpdatePolicyData() end
    local data = m_kPolicyData or {}
    local hideInactive, hideNoImpact = PolicyFilters()

    -- Policies within each slot group are ordered by the shared sort selection.
    local sortColumn = FindPolicyColumn(m_policySort.column) or FindPolicyColumn("name")
    local function sortPolicies(list)
        if not (sortColumn and sortColumn.sortKey) then return end
        local ascending = m_policySort.ascending
        table.sort(list, function(a, b)
            local av, bv = sortColumn.sortKey(a), sortColumn.sortKey(b)
            if av == bv then return Locale.Compare(a.Name, b.Name) < 0 end
            if type(av) == "string" then
                local cmp = Locale.Compare(av, bv)
                if ascending then return cmp < 0 else return cmp > 0 end
            end
            if ascending then return av < bv else return av > bv end
        end)
    end

    for _, slot in ipairs(SortedPolicySlots(data)) do
        local policies = data[slot]
        if policies and #policies > 0 then
            local groupNode = mgr:CreateWidget(MakeId("CAIRPT_PolGroup"), "TreeItem", {
                Label = function() return PolicyGroupName(slot) end,
                FocusKey = "policy:group:" .. slot,
            })
            groupNode:SetFocusSound(HOVER_SOUND)
            tree:AddChild(groupNode)

            local sorted = {}
            for _, p in ipairs(policies) do p.Slot = slot; sorted[#sorted + 1] = p end
            sortPolicies(sorted)

            for _, policy in ipairs(sorted) do
                if PolicyPasses(policy, hideInactive, hideNoImpact) then
                    local capturedPolicy = policy
                    local leaf = mgr:CreateWidget(MakeId("CAIRPT_Policy"), "TreeItem", {
                        Label = function()
                            local parts = { capturedPolicy.Name, PolicyStatusText(capturedPolicy) }
                            local yields = PolicyYieldsSummary(capturedPolicy)
                            if yields ~= "" then parts[#parts + 1] = yields end
                            return table.concat(parts, ", ")
                        end,
                        -- BRS's ImpactToolTip is a raw modifier/effect dump it only
                        -- shows under an advanced "modifiers" option; keep the plain
                        -- localized description here.
                        Tooltip = function() return capturedPolicy.Description or "" end,
                        FocusKey = "policy:" .. slot .. ":" .. tostring(policy.Index),
                    })
                    leaf:SetFocusSound(HOVER_SOUND)
                    groupNode:AddChild(leaf)
                end
            end
        end
    end

    mgr:RestoreFocus(tree, capture)
end

local function SetPolicyViewMode(entry, viewMode)
    if viewMode ~= "tree" and viewMode ~= "table" then return false end
    if m_policyViewMode ~= viewMode then
        m_policyViewMode = viewMode
        CAI.SetConfigValue("UI", POLICY_VIEW_SETTING_ID, viewMode)
    end
    local activeView = viewMode == "table" and entry.table or entry.tree
    if activeView then mgr:SetFocus(activeView) end
    return true
end

local function RebuildPolicyTab(entry)
    RebuildPolicyTree(entry.tree)
    if entry.table then entry.table:Rebuild() end
end

local function BuildPolicySortOptions()
    local options = {}
    for _, column in ipairs(GetPolicyColumns()) do
        -- The tree already groups by type, so a "sort by type" option in the
        -- tree-only dropdown would do nothing useful; skip it.
        if column.sortKey and column.key ~= "type" then
            local header = column.header()
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            }
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            }
        end
    end
    return options
end

local function SyncPolicySortDropdown(entry)
    if entry.sortDropdown == nil then return end
    for i, opt in ipairs(BuildPolicySortOptions()) do
        if opt.value.column == m_policySort.column and opt.value.ascending == m_policySort.ascending then
            entry.sortDropdown:SetSelectedIndex(i, true)
            return
        end
    end
end

function BuildPolicyFilters(page, entry)
    if entry.filtersBuilt then return end
    entry.filtersBuilt = true

    local hideInactive = mgr:CreateWidget(MakeId("CAIRPT_PolHideInactive"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_BRS_CHECKBOX_HIDE_INACTIVE_POLICIES") end,
        FocusKey = "policy:filter:inactive",
    })
    hideInactive:SetChecked(Controls.HideInactivePoliciesCheckbox
        and Controls.HideInactivePoliciesCheckbox:IsSelected() or false, true)
    hideInactive:SetValueSetter(function(_, value)
        if Controls.HideInactivePoliciesCheckbox then
            Controls.HideInactivePoliciesCheckbox:SetSelected(value)
        end
        RebuildPolicyTab(entry)
    end)
    hideInactive:SetFocusSound(HOVER_SOUND)
    page:AddChild(hideInactive)

    local hideNoImpact = mgr:CreateWidget(MakeId("CAIRPT_PolHideNoImpact"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_BRS_CHECKBOX_HIDE_NO_IMPACT_POLICIES") end,
        FocusKey = "policy:filter:noimpact",
    })
    hideNoImpact:SetChecked(Controls.HideNoImpactPoliciesCheckbox
        and Controls.HideNoImpactPoliciesCheckbox:IsSelected() or false, true)
    hideNoImpact:SetValueSetter(function(_, value)
        if Controls.HideNoImpactPoliciesCheckbox then
            Controls.HideNoImpactPoliciesCheckbox:SetSelected(value)
        end
        RebuildPolicyTab(entry)
    end)
    hideNoImpact:SetFocusSound(HOVER_SOUND)
    page:AddChild(hideNoImpact)
end

local function EnsurePolicyControls(entry)
    if entry.controlsBuilt then return end
    entry.controlsBuilt = true
    local page = entry.page
    if not page then return end

    entry.table = mgr:CreateWidget(POLICY_TABLE_ID, "DataTable", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TAB_POLICIES") end,
        HiddenPredicate = function() return m_policyViewMode ~= "table" end,
    })
    entry.table:SetColumns(GetPolicyColumns())
    entry.table:SetRowsProvider(function() return GetPolicyRows() end)
    entry.table:SetRowKeyGetter(function(policy)
        return tostring(policy.Slot) .. ":" .. tostring(policy.Index)
    end)
    entry.table:SetRowLabelGetter(function(policy) return policy.Name end)
    entry.table:SetDefaultSort({ column = m_policySort.column, ascending = m_policySort.ascending })
    entry.table:On("sort_changed", function(_, columnKey, ascending)
        m_policySort = { column = columnKey or "name", ascending = ascending == true }
        SyncPolicySortDropdown(entry)
    end)
    page:AddChild(entry.table)

    -- Sort dropdown for the tree view (the table sorts via its own column headers).
    entry.sortDropdown = mgr:CreateWidget(MakeId("CAIRPT_PolicySort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "policy:sort",
        HiddenPredicate = function() return m_policyViewMode ~= "tree" end,
    })
    entry.sortDropdown:SetOptions(BuildPolicySortOptions())
    SyncPolicySortDropdown(entry)
    entry.sortDropdown:On("value_changed", function(_, value)
        m_policySort = { column = value.column, ascending = value.ascending }
        if entry.table then
            entry.table:SetDefaultSort({ column = value.column, ascending = value.ascending })
        end
        RebuildPolicyTab(entry)
    end)
    page:AddChild(entry.sortDropdown)

    entry.switchView = mgr:CreateWidget(MakeId("CAIRPT_PolicySwitch"), "Button", {
        Label = function()
            return Locale.Lookup(m_policyViewMode == "tree"
                and "LOC_CAI_TREE_SWITCH_TO_TABLE" or "LOC_CAI_TREE_SWITCH_TO_TREE")
        end,
        FocusKey = "policy:switch-view",
    })
    entry.switchView:On("activate", function()
        return SetPolicyViewMode(entry, m_policyViewMode == "tree" and "table" or "tree")
    end)
    page:AddChild(entry.switchView)

    BuildPolicyFilters(page, entry)

    page:AddInputBindings({
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetPolicyViewMode(entry, "table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetPolicyViewMode(entry, "tree") end,
        },
    })
end

-- ============================================================================
-- Minor / City-States tab: dual tree/table view of BRS's m_kMinorData. The tree
-- groups city-states by category (the category node's tooltip carries the three
-- envoy-tier bonuses and their yields); the table is a flat, sortable list (BRS's
-- Minor tab has no sorting). Each city-state has an Impact column showing the typed
-- yield breakdown it currently grants us -- the envoy-tier bonuses our influence has
-- unlocked, plus its suzerain-unique bonus when we are the suzerain. That column
-- sorts by the summed magnitude of those yields (highest impact first). The
-- suzerain-unique bonus description (text) also stays in the row/leaf tooltip.
-- ============================================================================
local MINOR_TABLE_ID        = "CAIReports_MinorTable"
local MINOR_VIEW_SETTING_ID = "ReportsMinorViewMode"
local m_minorViewMode = (function()
    local stored = tostring(CAI.GetConfigValue("UI", MINOR_VIEW_SETTING_ID, "table")):lower()
    return stored == "tree" and "tree" or "table"
end)()
local m_minorSort = { column = "name", ascending = true }

local function MinorYieldsSummary(entryData, multiplier)
    local parts = {}
    for yield, value in pairs(entryData.Yields or {}) do
        local scaled = value * (multiplier or 1)
        if scaled ~= 0 then
            parts[#parts + 1] = toPlusMinusNoneString(scaled) .. " " .. tostring(yield)
        end
    end
    return table.concat(parts, ", ")
end

-- Returns tiers (NumTokens 1/3/6) and city-states (NumTokens 0) for a category.
local function SplitMinorCategory(entries)
    local tiers, cities = {}, {}
    for _, e in ipairs(entries or {}) do
        if e.NumTokens and e.NumTokens > 0 then tiers[#tiers + 1] = e else cities[#cities + 1] = e end
    end
    table.sort(tiers, function(a, b) return a.NumTokens < b.NumTokens end)
    return tiers, cities
end

local function MinorCategoryTooltip(tiers)
    local tt = {}
    for _, tier in ipairs(tiers) do
        local line = tier.Name .. " (" .. tostring(tier.Influence) .. ")"
        if tier.Description and tier.Description ~= "" then
            line = line .. "[NEWLINE]" .. tier.Description
        end
        local yields = MinorYieldsSummary(tier, tier.Influence)
        if yields ~= "" then line = line .. "[NEWLINE]" .. yields end
        tt[#tt + 1] = line
    end
    return table.concat(tt, "[NEWLINE]")
end

local function MinorCategoryName(category)
    return Locale.Lookup("LOC_CITY_STATES_TYPE_" .. category)
end

local function MinorFilters()
    local hideNotMet = Controls.HideNotMetMinorsCheckbox
        and Controls.HideNotMetMinorsCheckbox:IsSelected()
    local hideNoImpact = Controls.HideNoImpactMinorsCheckbox
        and Controls.HideNoImpactMinorsCheckbox:IsSelected()
    return hideNotMet, hideNoImpact
end

local function MinorCityPasses(city, hideNotMet, hideNoImpact)
    local passMet = (not hideNotMet) or city.HasMet
    local passImpact = (not hideNoImpact) or city.IsImpact or city.Influence > 0
    return passMet and passImpact
end

-- The actual, typed yields a city-state currently grants us: every envoy-tier
-- bonus our influence has unlocked (Small at 1 envoy, Medium at 3, Large at 6),
-- plus its suzerain-unique bonus when we are the suzerain. Keyed by yield name to
-- match BRS's RMA yield tables. Defined above its callers (GetMinorRows/
-- RebuildMinorTree) because Lua binds locals at parse time.
local function MinorCityYieldTable(city, tiers)
    local totals = {}
    local function accumulate(yields)
        for yield, value in pairs(yields or {}) do
            if value ~= 0 then totals[yield] = (totals[yield] or 0) + value end
        end
    end
    for _, tier in ipairs(tiers) do
        if (city.Influence or 0) >= tier.NumTokens then accumulate(tier.Yields) end
    end
    if city.IsSuzerained then accumulate(city.Yields) end
    return totals
end

-- Formatted per-yield breakdown of a yield table (e.g. "+2 SCIENCE, +4 GOLD"),
-- matching the Policy tab / MinorYieldsSummary convention.
local function YieldTableBreakdown(yields)
    local parts = {}
    for yield, value in pairs(yields or {}) do
        if value ~= 0 then
            parts[#parts + 1] = toPlusMinusNoneString(value) .. " " .. tostring(yield)
        end
    end
    return table.concat(parts, ", ")
end

-- Scalar magnitude of a yield table, used only to sort impact high-to-low.
local function YieldTableTotal(yields)
    local total = 0
    for _, value in pairs(yields or {}) do total = total + value end
    return total
end

-- Stash the typed breakdown string and the sort scalar on the city record.
local function AnnotateMinorImpact(city, tiers)
    local yields = MinorCityYieldTable(city, tiers)
    city._impactText = YieldTableBreakdown(yields)
    city._impactTotal = YieldTableTotal(yields)
    return city._impactTotal
end

local function GetMinorCategories()
    if g_DirtyFlag.MINOR then UpdateMinorData() end
    local data = m_kMinorData or {}
    local categories = {}
    for category in pairs(data) do categories[#categories + 1] = category end
    table.sort(categories)
    return categories, data
end

-- Flat, filtered city-state rows for the table view (each carries its category).
local function GetMinorRows()
    local categories, data = GetMinorCategories()
    local hideNotMet, hideNoImpact = MinorFilters()
    local rows = {}
    for _, category in ipairs(categories) do
        local tiers, cities = SplitMinorCategory(data[category])
        for _, city in ipairs(cities) do
            if MinorCityPasses(city, hideNotMet, hideNoImpact) then
                city.Category = category
                AnnotateMinorImpact(city, tiers)
                rows[#rows + 1] = city
            end
        end
    end
    return rows
end

local function MinorStatusText(city)
    if city.IsSuzerained then return Locale.Lookup("LOC_CITY_STATES_SUZERAIN") end
    if not city.HasMet then return Locale.Lookup("LOC_LOYALTY_PANEL_UNMET_CIV") end
    if city.Influence > 0 then return Locale.Lookup("LOC_ENVOY_NAME") end
    return ""
end

local m_minorColumns = nil
local function GetMinorColumns()
    if m_minorColumns then return m_minorColumns end
    m_minorColumns = {
        {
            key = "name",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_NAME") end,
            getCell = function(city) return city.Name end,
            getTooltip = function(city) return city.Description or "" end,
            sortKey = function(city) return city.Name end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "category",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_CATEGORY") end,
            getCell = function(city) return MinorCategoryName(city.Category) end,
            getTooltip = function(city)
                local _, data = GetMinorCategories()
                local tiers = SplitMinorCategory(data[city.Category])
                return MinorCategoryTooltip(tiers)
            end,
            sortKey = function(city) return MinorCategoryName(city.Category) end,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "envoys",
            header = function() return Locale.Lookup("LOC_ENVOY_NAME") end,
            getCell = function(city) return tostring(city.Influence) end,
            sortKey = function(city) return city.Influence end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
        {
            key = "status",
            header = function() return Locale.Lookup("LOC_CAI_GOVERNOR_COLUMN_STATUS") end,
            getCell = MinorStatusText,
            sortKey = MinorStatusText,
            sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
            sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
        },
        {
            key = "impact",
            header = function() return Locale.Lookup("LOC_CAI_REPORTS_COL_IMPACT") end,
            getCell = function(city) return city._impactText or "" end,
            sortKey = function(city) return city._impactTotal or 0 end,
            sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
            sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
        },
    }
    return m_minorColumns
end

local function FindMinorColumn(key)
    for _, column in ipairs(GetMinorColumns()) do
        if column.key == key then return column end
    end
    return nil
end

local function RebuildMinorTree(tree)
    local capture = mgr:CaptureFocusKey(tree)
    tree:ClearChildren()

    local categories, data = GetMinorCategories()
    local hideNotMet, hideNoImpact = MinorFilters()

    -- City-states within each category are ordered by the shared sort selection.
    local sortColumn = FindMinorColumn(m_minorSort.column) or FindMinorColumn("name")
    local function sortCities(cities)
        if not (sortColumn and sortColumn.sortKey) then return end
        local ascending = m_minorSort.ascending
        table.sort(cities, function(a, b)
            local av, bv = sortColumn.sortKey(a), sortColumn.sortKey(b)
            if av == bv then return Locale.Compare(a.Name, b.Name) < 0 end
            if type(av) == "string" then
                local cmp = Locale.Compare(av, bv)
                if ascending then return cmp < 0 else return cmp > 0 end
            end
            if ascending then return av < bv else return av > bv end
        end)
    end

    for _, category in ipairs(categories) do
        local capturedCategory = category
        local tiers, cities = SplitMinorCategory(data[category])
        for _, city in ipairs(cities) do AnnotateMinorImpact(city, tiers) end
        sortCities(cities)

        local groupNode = mgr:CreateWidget(MakeId("CAIRPT_MinorCat"), "TreeItem", {
            Label = function() return MinorCategoryName(capturedCategory) end,
            Tooltip = function() return MinorCategoryTooltip(tiers) end,
            FocusKey = "minor:cat:" .. category,
        })
        groupNode:SetFocusSound(HOVER_SOUND)
        tree:AddChild(groupNode)

        for _, city in ipairs(cities) do
            if MinorCityPasses(city, hideNotMet, hideNoImpact) then
                local capturedCity = city
                local leaf = mgr:CreateWidget(MakeId("CAIRPT_Minor"), "TreeItem", {
                    Label = function()
                        local parts = { capturedCity.Name }
                        parts[#parts + 1] = Locale.Lookup("LOC_CAI_CITYSTATES_ENVOYS_TIER", capturedCity.Influence)
                        local status = MinorStatusText(capturedCity)
                        if status ~= "" then parts[#parts + 1] = status end
                        if capturedCity._impactText and capturedCity._impactText ~= "" then
                            parts[#parts + 1] = Locale.Lookup("LOC_CAI_REPORTS_COL_IMPACT") ..
                                " " .. capturedCity._impactText
                        end
                        return table.concat(parts, ", ")
                    end,
                    Tooltip = function() return capturedCity.Description or "" end,
                    FocusKey = "minor:" .. category .. ":" .. tostring(capturedCity.CivType),
                })
                leaf:SetFocusSound(HOVER_SOUND)
                groupNode:AddChild(leaf)
            end
        end
    end

    mgr:RestoreFocus(tree, capture)
end

local function SetMinorViewMode(entry, viewMode)
    if viewMode ~= "tree" and viewMode ~= "table" then return false end
    if m_minorViewMode ~= viewMode then
        m_minorViewMode = viewMode
        CAI.SetConfigValue("UI", MINOR_VIEW_SETTING_ID, viewMode)
    end
    local activeView = viewMode == "table" and entry.table or entry.tree
    if activeView then mgr:SetFocus(activeView) end
    return true
end

local function RebuildMinorTab(entry)
    RebuildMinorTree(entry.tree)
    if entry.table then entry.table:Rebuild() end
end

local function BuildMinorSortOptions()
    local options = {}
    for _, column in ipairs(GetMinorColumns()) do
        -- The tree already groups by category, so offering "sort by category" in the
        -- tree-only dropdown would do nothing useful; skip it.
        if column.sortKey and column.key ~= "category" then
            local header = column.header()
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortAscendingDescription),
                value = { column = column.key, ascending = true },
            }
            options[#options + 1] = {
                label = header .. ", " .. Locale.Lookup(column.sortDescendingDescription),
                value = { column = column.key, ascending = false },
            }
        end
    end
    return options
end

local function SyncMinorSortDropdown(entry)
    if entry.sortDropdown == nil then return end
    for i, opt in ipairs(BuildMinorSortOptions()) do
        if opt.value.column == m_minorSort.column and opt.value.ascending == m_minorSort.ascending then
            entry.sortDropdown:SetSelectedIndex(i, true)
            return
        end
    end
end

local function EnsureMinorControls(entry)
    if entry.controlsBuilt then return end
    entry.controlsBuilt = true
    local page = entry.page
    if not page then return end

    entry.table = mgr:CreateWidget(MINOR_TABLE_ID, "DataTable", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TAB_MINORS") end,
        HiddenPredicate = function() return m_minorViewMode ~= "table" end,
    })
    entry.table:SetColumns(GetMinorColumns())
    entry.table:SetRowsProvider(function() return GetMinorRows() end)
    entry.table:SetRowKeyGetter(function(city) return tostring(city.CivType) end)
    entry.table:SetRowLabelGetter(function(city) return city.Name end)
    entry.table:SetDefaultSort({ column = m_minorSort.column, ascending = m_minorSort.ascending })
    entry.table:On("sort_changed", function(_, columnKey, ascending)
        m_minorSort = { column = columnKey or "name", ascending = ascending == true }
        SyncMinorSortDropdown(entry)
    end)
    page:AddChild(entry.table)

    -- Sort dropdown for the tree view (the table sorts via its own column headers).
    entry.sortDropdown = mgr:CreateWidget(MakeId("CAIRPT_MinorSort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_REPORTS_SORT_BY") end,
        FocusKey = "minor:sort",
        HiddenPredicate = function() return m_minorViewMode ~= "tree" end,
    })
    entry.sortDropdown:SetOptions(BuildMinorSortOptions())
    SyncMinorSortDropdown(entry)
    entry.sortDropdown:On("value_changed", function(_, value)
        m_minorSort = { column = value.column, ascending = value.ascending }
        if entry.table then
            entry.table:SetDefaultSort({ column = value.column, ascending = value.ascending })
        end
        RebuildMinorTab(entry)
    end)
    page:AddChild(entry.sortDropdown)

    entry.switchView = mgr:CreateWidget(MakeId("CAIRPT_MinorSwitch"), "Button", {
        Label = function()
            return Locale.Lookup(m_minorViewMode == "tree"
                and "LOC_CAI_TREE_SWITCH_TO_TABLE" or "LOC_CAI_TREE_SWITCH_TO_TREE")
        end,
        FocusKey = "minor:switch-view",
    })
    entry.switchView:On("activate", function()
        return SetMinorViewMode(entry, m_minorViewMode == "tree" and "table" or "tree")
    end)
    page:AddChild(entry.switchView)

    BuildMinorFilters(page, entry)

    page:AddInputBindings({
        {
            Key = Keys["1"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TABLE",
            Action = function() return SetMinorViewMode(entry, "table") end,
        },
        {
            Key = Keys["2"], IsAlt = true, MSG = KeyEvents.KeyDown,
            Description = "LOC_CAI_TREE_SWITCH_TO_TREE",
            Action = function() return SetMinorViewMode(entry, "tree") end,
        },
    })
end

function BuildMinorFilters(page, entry)
    if entry.filtersBuilt then return end
    entry.filtersBuilt = true

    local hideNotMet = mgr:CreateWidget(MakeId("CAIRPT_MinHideNotMet"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_BRS_CHECKBOX_HIDE_NOT_MET_MINORS") end,
        FocusKey = "minor:filter:notmet",
    })
    hideNotMet:SetChecked(Controls.HideNotMetMinorsCheckbox
        and Controls.HideNotMetMinorsCheckbox:IsSelected() or false, true)
    hideNotMet:SetValueSetter(function(_, value)
        if Controls.HideNotMetMinorsCheckbox then
            Controls.HideNotMetMinorsCheckbox:SetSelected(value)
        end
        RebuildMinorTab(entry)
    end)
    hideNotMet:SetFocusSound(HOVER_SOUND)
    page:AddChild(hideNotMet)

    local hideNoImpact = mgr:CreateWidget(MakeId("CAIRPT_MinHideNoImpact"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_BRS_CHECKBOX_HIDE_NO_IMPACT_MINORS") end,
        FocusKey = "minor:filter:noimpact",
    })
    hideNoImpact:SetChecked(Controls.HideNoImpactMinorsCheckbox
        and Controls.HideNoImpactMinorsCheckbox:IsSelected() or false, true)
    hideNoImpact:SetValueSetter(function(_, value)
        if Controls.HideNoImpactMinorsCheckbox then
            Controls.HideNoImpactMinorsCheckbox:SetSelected(value)
        end
        RebuildMinorTab(entry)
    end)
    hideNoImpact:SetFocusSound(HOVER_SOUND)
    page:AddChild(hideNoImpact)
end

-- ============================================================================
-- Cities2 tab, Gathering Storm only (BRS global m_kCity2Data)
-- ============================================================================
local function RebuildCities2Tab(entry)
    local list = entry.tree
    local capture = mgr:CaptureFocusKey(list)
    list:ClearChildren()

    if g_DirtyFlag.CITIES2 then UpdateCities2Data() end
    local data = m_kCity2Data or {}

    local cityNames = {}
    for name in pairs(data) do cityNames[#cityNames + 1] = name end
    table.sort(cityNames, function(a, b) return Locale.Compare(a, b) < 0 end)

    for _, name in ipairs(cityNames) do
        local capturedCity = data[name]
        local item = mgr:CreateWidget(MakeId("CAIRPT_City2"), "StaticText", {
            Label = function()
                local city = capturedCity.City
                local cityName = city and Locale.Lookup(city:GetName()) or ""
                local parts = { cityName }
                if capturedCity.PowerRequired and capturedCity.PowerRequired > 0 then
                    parts[#parts + 1] = Locale.Lookup("LOC_CAI_REPORTS_CITIES2_POWER",
                        capturedCity.PowerConsumed or 0, capturedCity.PowerRequired)
                end
                return table.concat(parts, ", ")
            end,
            -- BRS stores PowerConsumedTT already flattened to a string.
            Tooltip = function() return capturedCity.PowerConsumedTT or "" end,
            FocusKey = "cities2:" .. tostring(name),
        })
        item:SetFocusSound(HOVER_SOUND)
        list:AddChild(item)
    end

    mgr:RestoreFocus(list, capture)
end

-- ============================================================================
-- Panel construction
-- ============================================================================
local function BuildPanel()
    if m_panel then return end
    if Game.GetLocalPlayer() == -1 then return end

    m_tabDefs = BuildTabDefs()

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_HUD_REPORTS_TITLE") end,
    })

    m_tabs = mgr:CreateWidget(TABS_ID, "TabControl", { FocusKey = "reports:tabs" })
    m_panel:AddChild(m_tabs)

    for i, def in ipairs(m_tabDefs) do
        local capturedDef = def
        local tree
        if def.kind == "citystatus" then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. i .. ":list",
                HiddenPredicate = function() return not CAIReports_IsCityStatusListMode() end,
            })
        elseif def.kind == "units" then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. i .. ":list",
                HiddenPredicate = function() return m_unitViewMode ~= "list" end,
            })
        elseif def.kind == "minor" then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "Tree", {
                FocusKey = "reports:tab:" .. i .. ":tree",
                HiddenPredicate = function() return m_minorViewMode ~= "tree" end,
            })
        elseif def.key == "policy" then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "Tree", {
                FocusKey = "reports:tab:" .. i .. ":tree",
                HiddenPredicate = function() return m_policyViewMode ~= "tree" end,
            })
        elseif def.kind == "gossip" or def.kind == "list" then
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "List", {
                FocusKey = "reports:tab:" .. i .. ":list",
            })
        else
            tree = mgr:CreateWidget(MakeId("CAIRPT_"), "Tree", {
                FocusKey = "reports:tab:" .. i .. ":tree",
            })
        end

        m_tabs:AddPage(function() return Locale.Lookup(capturedDef.label) end)
        local page = m_tabs:GetPage(i)
        if page then page:AddChild(tree) end

        m_trees[i] = { tree = tree, page = page, tabIndex = i, key = def.key }
    end

    m_tabs:On("value_changed", function(_, pageIndex)
        if m_isMirroringTab then return end
        m_activeTab = pageIndex
        -- Drive BRS's own tab button (like the vanilla report variant does) so its
        -- page state and m_kCurrentTab stay in sync, then rebuild the CAI content.
        -- Guarded so a rebuild error in one tab cannot break tab navigation; the
        -- error is logged for diagnosis.
        local btn = m_capturedTabs[pageIndex]
        local ok, err = pcall(function()
            if btn then btn:DoLeftClick() end
            RebuildActiveTab()
        end)
        if not ok then
            LogError("CAI Reports (BRS) tab " .. tostring(pageIndex) .. " rebuild failed: " .. tostring(err))
        end
    end)
end

-- Forward declaration resolved below (RebuildActiveTab references the builders).
function RebuildActiveTab()
    local entry = m_trees[m_activeTab]
    if not entry then return end
    local key = entry.key
    if key == "yields" then
        RebuildYieldsTree(entry.tree)
    elseif key == "resources" then
        RebuildResourcesTree(entry.tree)
    elseif key == "city" then
        RebuildCityStatusTab(entry)
    elseif key == "gossip" then
        RebuildGossipTab(entry)
    elseif key == "deals" then
        RebuildDealsTab(entry)
    elseif key == "units" then
        RebuildUnitsTab(entry)
    elseif key == "policy" then
        EnsurePolicyControls(entry)
        RebuildPolicyTab(entry)
    elseif key == "minor" then
        EnsureMinorControls(entry)
        RebuildMinorTab(entry)
    end
end

local function PushPanel()
    BuildPanel()
    if not m_panel then return end
    if m_activeTab < 1 or m_activeTab > #m_tabDefs then m_activeTab = 1 end

    m_isMirroringTab = true
    if m_tabs then m_tabs:SetActivePage(m_activeTab) end
    m_isMirroringTab = false

    RebuildActiveTab()

    local options = { priority = PopupPriority.Medium }
    if m_pendingOpenFocusKey ~= nil then
        options.focus = m_pendingOpenFocusKey
    end
    m_pendingOpenFocusKey = nil
    mgr:Push(m_panel, options)
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tabs = nil
    m_trees = {}
    m_tabDefs = {}
end

-- ============================================================================
-- Lifecycle wraps
-- ============================================================================
-- BRS builds its tab buttons in LateInitialize via AddTabSection (one per tab, in
-- the same order as m_tabDefs). Capture each button so the CAI tab switch can drive
-- it with DoLeftClick, mirroring the vanilla report variant.
AddTabSection = WrapFunc(AddTabSection, function(orig, name, populateCallback)
    orig(name, populateCallback)
    local children = Controls.TabContainer:GetChildren()
    local lastChild = children[#children]
    if lastChild then
        table.insert(m_capturedTabs, lastChild)
    end
end)

Open = WrapFunc(Open, function(orig, tabToOpen)
    mgr = assert(ExposedMembers.CAI_UIManager,
        "CAI Report Screen opened before the accessibility UI manager was available")

    local reportsRequest = ExposedMembers.CAIReports
    if not IsCAITutorialControlAllowed("LaunchBar_Hook_Reports") then
        if reportsRequest then reportsRequest.PendingFocusKey = nil end
        return
    end
    if reportsRequest and reportsRequest.PendingFocusKey then
        m_pendingOpenFocusKey = reportsRequest.PendingFocusKey
        reportsRequest.PendingFocusKey = nil
    end

    orig(tabToOpen)
    -- BRS's Open sets m_kCurrentTab from tabToOpen (or the last-opened tab); mirror
    -- it so a ReportsList request that jumps to a specific tab is honored.
    m_activeTab = m_kCurrentTab or 1
    RefreshCAIData()
    GatherGossip()
    FilterCAIGossip()
    PushPanel()
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
    -- Reset to the first tab so reopening the report starts on Yields, matching the
    -- vanilla report's fresh-open behavior.
    m_kCurrentTab = 1
    m_activeTab = 1
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) and mgr:GetTop() == m_panel then
        if mgr:HandleInput(pInputStruct) then
            return true
        end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

-- BRS's reportscreen.lua does not define OnShutdown; register one so the panel is
-- removed from the stack if the context is torn down while open.
ContextPtr:SetShutdown(function()
    PopPanel()
end)
