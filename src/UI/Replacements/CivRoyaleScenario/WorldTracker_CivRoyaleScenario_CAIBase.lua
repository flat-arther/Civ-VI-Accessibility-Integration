-- Copyright 2020, Firaxis Games 

include("WorldTracker.lua");
include("CivRoyaleScenario_UnitCommandDefs");

--	CACHE BASE FUNCTIONS
BASE_LateInitialize = LateInitialize;
BASE_Refresh = Refresh;
BASE_Unsubscribe = Unsubscribe;
BASE_UpdateUnitIcon = UpdateUnitIcon;

-- ===========================================================================
local m_uiGlobalAbilityInstance : table = {};

local STATUS_LABEL_BASE_OFFSET_Y	:number = 8;
local STATUS_LABEL_CHARGES_OFFSET_Y :number = 0;
local MINIMAP_PADDING				:number = 120;

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function Refresh()
	ContextPtr:ClearRequestRefresh();
	BASE_Refresh();
	if(PlayerHasGlobalAbility())then
		m_uiGlobalAbilityInstance.MainPanel:SetHide(false);
		UpdateGlobalAbility();
		if(GameConfiguration.IsHotseat())then
			ContextPtr:SetHide(false);
		end
	else
		m_uiGlobalAbilityInstance.MainPanel:SetHide(true);
		if(GameConfiguration.IsHotseat())then
			ContextPtr:SetHide(true);
		end
	end
end

-- ===========================================================================
-- ===========================================================================
function PlayerHasGlobalAbility()
	local pLocalPlayerConfig : object = PlayerConfigurations[Game.GetLocalPlayer()];
	if(pLocalPlayerConfig ~= nil and pLocalPlayerConfig:IsAlive())then
		local civName : string = pLocalPlayerConfig:GetCivilizationTypeName();
		if(civName == g_CivTypeNames.Wanderers or
			civName == g_CivTypeNames.Pirates or
			civName == g_CivTypeNames.EdgeLords) then
			return true;
		end
	end
	return false;
end

-- ===========================================================================
-- ===========================================================================
function UpdateGlobalAbility()

	local kGlobalAbilityData : table = GetGlobalAbilityData();
	if(kGlobalAbilityData == nil) then return; end

	local toolTipString : string = Locale.Lookup(kGlobalAbilityData.ToolTip);
	local cooldownPercent : number = 1;

	--Only abilities that are currently active or on cooldown will have a disabled tooltip
	if(kGlobalAbilityData.DisabledToolTip ~= nil)then
		m_uiGlobalAbilityInstance.IconButton:SetDisabled(true);
		toolTipString = toolTipString .. "[NEWLINE]" .. kGlobalAbilityData.DisabledToolTip;
		cooldownPercent = (Game.GetCurrentGameTurn() - kGlobalAbilityData.LastTurnUsed) / kGlobalAbilityData.Cooldown;
		m_uiGlobalAbilityInstance.AbilityStatusLabel:SetText(kGlobalAbilityData.DisabledToolTip);
	else
		m_uiGlobalAbilityInstance.IconButton:SetDisabled(false);
		m_uiGlobalAbilityInstance.AbilityStatusLabel:LocalizeAndSetText("LOC_CIV_ROYALE_GLOBAL_ABILITY_AVAILABLE");
	end

	if(kGlobalAbilityData.Charges ~= nil)then
		m_uiGlobalAbilityInstance.Divider:SetHide(false);
		m_uiGlobalAbilityInstance.AbilityChargesLabel:SetHide(false);
		m_uiGlobalAbilityInstance.AbilityChargesLabel:LocalizeAndSetText("LOC_CIV_ROYALE_GLOBAL_ABILITY_CHARGES", kGlobalAbilityData.Charges, kGlobalAbilityData.MaxCharges);
		m_uiGlobalAbilityInstance.AbilityStatusLabel:SetOffsetY(STATUS_LABEL_CHARGES_OFFSET_Y);
	else
		m_uiGlobalAbilityInstance.Divider:SetHide(true);
		m_uiGlobalAbilityInstance.AbilityChargesLabel:SetHide(true);
		m_uiGlobalAbilityInstance.AbilityStatusLabel:SetOffsetY(STATUS_LABEL_BASE_OFFSET_Y);
	end

	if(kGlobalAbilityData.EventName ~= nil) then
		local tParameters : table = {};
		tParameters[UnitCommandTypes.PARAM_NAME] = kGlobalAbilityData.EventName or "";
		m_uiGlobalAbilityInstance.IconButton:RegisterCallback(Mouse.eLClick, function()
			UnitManager.RequestCommand(kGlobalAbilityData.Unit, UnitCommandTypes.EXECUTE_SCRIPT, tParameters);
		end);
	elseif(kGlobalAbilityData.InterfaceMode ~= nil) then
		m_uiGlobalAbilityInstance.IconButton:RegisterCallback(Mouse.eLClick, function()
			if(UI.GetHeadSelectedUnit() == nil and not m_uiGlobalAbilityInstance.IconButton:IsDisabled())then
				--There must be a unit selected for this interface mode to work properly.
				UI.SelectUnit(kGlobalAbilityData.Unit);
			end
			UI.SetInterfaceMode(kGlobalAbilityData.InterfaceMode);
			m_uiGlobalAbilityInstance.IconButton:SetSelected(true);
		end);
	end

	m_uiGlobalAbilityInstance.IconButton:SetSelected(false);
	m_uiGlobalAbilityInstance.Icon:SetIcon(kGlobalAbilityData.IconID);
	m_uiGlobalAbilityInstance.TitleButton:LocalizeAndSetText(kGlobalAbilityData.Name);
	m_uiGlobalAbilityInstance.IconButton:SetToolTipString(toolTipString);
	m_uiGlobalAbilityInstance.CooldownMeter:SetPercent(cooldownPercent);
end

-- ===========================================================================
-- Retrieve the needed info from the Civ specific global ability
-- ===========================================================================
function GetGlobalAbilityData()
	local civName			: string = PlayerConfigurations[Game.GetLocalPlayer()]:GetCivilizationTypeName();
	local kGlobalAbilityData : table = nil;
	local localPlayerID		: number = Game.GetLocalPlayer();
	local pDefaultUnit		: table = UnitManager.GetUnit(localPlayerID, nil); --passing in nil as unitID returns the first unit in player's unit array
	local pLocalPlayer		: table = Players[localPlayerID];
	
	if(civName == g_CivTypeNames.Wanderers)then
		--Road Vision
		kGlobalAbilityData =
		{
			EventName = m_ScenarioUnitCommands.ROAD_VISION.EventName;
			IconID = m_ScenarioUnitCommands.ROAD_VISION.Icon;
			Unit = pDefaultUnit;
			Name = m_ScenarioUnitCommands.ROAD_VISION.Name;
			ToolTip = m_ScenarioUnitCommands.ROAD_VISION.ToolTipString;
			DisabledToolTip = m_ScenarioUnitCommands.ROAD_VISION.GetDisabledTTString(pDefaultUnit);
			Cooldown = WANDERER_ROAD_VISION_DEBOUNCE + WANDERER_ROAD_VISION_DURATION;
			LastTurnUsed = pLocalPlayer:GetProperty(g_playerPropertyKeys.RoadVisionTurn);
			IsActive = m_ScenarioUnitCommands.ROAD_VISION.IsActive();
		};
	elseif(civName == g_CivTypeNames.Pirates)then
		--Burn Treasure Map
		kGlobalAbilityData =
		{
			EventName = m_ScenarioUnitCommands.BURN_TREASURE_MAP.EventName;
			IconID = m_ScenarioUnitCommands.BURN_TREASURE_MAP.Icon;
			Unit = pDefaultUnit;
			Name = m_ScenarioUnitCommands.BURN_TREASURE_MAP.Name;
			ToolTip = m_ScenarioUnitCommands.BURN_TREASURE_MAP.ToolTipString;
			DisabledToolTip = m_ScenarioUnitCommands.BURN_TREASURE_MAP.GetDisabledTTString(pDefaultUnit);
			Cooldown = PIRATES_BURN_TREASURE_MAP_DEBOUNCE;
			LastTurnUsed = pLocalPlayer:GetProperty(g_playerPropertyKeys.BurnTreasureTurn);
		}
	elseif(civName == g_CivTypeNames.EdgeLords)then
		--Grieving Gift
		kGlobalAbilityData =
		{
			InterfaceMode = m_ScenarioUnitCommands.GRIEVING_GIFT.InterfaceMode;
			IconID = m_ScenarioUnitCommands.GRIEVING_GIFT.Icon;
			Unit = pDefaultUnit;
			Name = m_ScenarioUnitCommands.GRIEVING_GIFT.Name;
			ToolTip = m_ScenarioUnitCommands.GRIEVING_GIFT.ToolTipString;
			DisabledToolTip = m_ScenarioUnitCommands.GRIEVING_GIFT.GetDisabledTTString(pDefaultUnit);
			Cooldown = EDGELORDS_GRIEVING_GIFT_DEBOUNCE;
			LastTurnUsed = pLocalPlayer:GetProperty(g_playerPropertyKeys.GrievingGiftTurn);
			Charges = pLocalPlayer:GetProperty(g_playerPropertyKeys.GrievingGiftCount);
			MaxCharges = EDGELORDS_GRIEVING_GIFT_MAX_COUNT;
		}
	end
	return kGlobalAbilityData;
end

-- ===========================================================================
function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	if(not PlayerHasGlobalAbility())then return; end
	local kGlobalAbilityData = GetGlobalAbilityData();
	if(kGlobalAbilityData.InterfaceMode ~= nil and kGlobalAbilityData.InterfaceMode == eOldMode) then
		--Update on next frame to ensure operation has completed and stats have updated
		ContextPtr:RequestRefresh();
	end
end

-- ===========================================================================
function OnUnitCommandStarted( player:number, unitID:number, hCommand, iData1)
	if(not PlayerHasGlobalAbility() or player ~= Game.GetLocalPlayer())then return; end
	--Update on next frame to ensure operation has completed and stats have updated
	ContextPtr:RequestRefresh();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function GetMinimapPadding()
	return MINIMAP_PADDING;
end

-- ===========================================================================
function UpdateUnitIcon(pUnit:table, uiUnitEntry:table)
	local unit:table = GameInfo.Units[pUnit:GetUnitType()];
	local unitIcon = "ICON_" .. unit.UnitType;
	unitIcon = unitIcon .. "_" .. PlayerConfigurations[pUnit:GetOwner()]:GetCivilizationTypeName();
	local textureOffsetX : number, textureOffsetY : number, textureSheet : string = IconManager:FindIconAtlas(unitIcon, iconSize);
	if (textureSheet == nil) then
		BASE_UpdateUnitIcon(pUnit, uiUnitEntry);
	else
		uiUnitEntry.UnitTypeIcon:SetTexture( textureOffsetX, textureOffsetY, textureSheet );
	end
end


-- ===========================================================================
function Unsubscribe()
	Events.InterfaceModeChanged.Remove( OnInterfaceModeChanged );
	Events.UnitCommandStarted.Remove( OnUnitCommandStarted );
	BASE_Unsubscribe();
end

-- ===========================================================================
--	OVERRIDE
-- ===========================================================================
function LateInitialize()
	ContextPtr:SetRefreshHandler( Refresh );
	ContextPtr:BuildInstanceForControl( "GlobalAbilityInstance", m_uiGlobalAbilityInstance, Controls.GlobalAbilityStack );

	if (GameConfiguration.IsPlayByCloud() and not PlayerHasGlobalAbility()) then
		ContextPtr:SetHide( true );
	end

	Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );
	Events.UnitCommandStarted.Add( OnUnitCommandStarted );

	BASE_LateInitialize();

	Refresh();
end
