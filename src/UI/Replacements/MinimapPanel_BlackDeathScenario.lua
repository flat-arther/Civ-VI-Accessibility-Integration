-- Copyright 2018-2019, Firaxis Games

-- ===========================================================================
-- Base File
-- ===========================================================================
include("MinimapPanel_Expansion2");
include("SupportFunctions");

-- ===========================================================================
-- Constants
-- ===========================================================================
local PLAGUE_PROP:string = "Plague";
local OVERLAY_ID:string = "PlagueHighlight";
local PLAGUE_PROP_MAX_AMOUNT:number = 10;
local PLAGUE_OVERLAY_ALPHA:number = 0.6;
local LENS_PANEL_OFFSET				:number	= 50;
function Lerp(a, b, t) return a + (b - a) * t end

-- ===========================================================================
-- Cached XP2 Functions
-- ===========================================================================
BASE_RefreshInterfaceMode = RefreshInterfaceMode;

XP2_LateInitialize         = LateInitialize;
XP2_OnInputActionTriggered = OnInputActionTriggered;
XP2_OnInterfaceModeChanged = OnInterfaceModeChanged;
XP2_OnLensLayerOn          = OnLensLayerOn;
XP2_OnLensLayerOff         = OnLensLayerOff;
XP2_OnShutdown             = OnShutdown;
XP2_OnToggleLensList       = OnToggleLensList;
XP2_SetGovernmentHexes     = SetGovernmentHexes;

-- ===========================================================================
-- Members
-- ===========================================================================
local m_TogglePlagueLensId:number = Input.GetActionId("LensPlague");
local m_uiPlagueToggle:table = InstanceManager:new("LensButtonInstance", "LensButton", Controls.LensToggleStack):GetInstance();

-- CAI integration hook: expose the scenario-created toggle without duplicating its behavior.
function GetBlackDeathPlagueLensButton()
	return m_uiPlagueToggle.LensButton;
end

function RefreshInterfaceMode()
	local isOn:boolean = UILens.IsLensActive("Plague");
	local pOverlay = UILens.GetOverlay("PlagueHighlight");
	pOverlay:SetChannelOn(0);
	pOverlay:SetVisible(isOn);
--	UILens.SetDesaturation(isOn and 1 or 0);
	BASE_RefreshInterfaceMode();
end

function TurnPlagueLensOn()
	LuaEvents.OnPlagueLensOn();
	UI.PlaySound("UI_Lens_Overlay_On");
	UILens.SetActive("Plague");
	RefreshInterfaceMode();
	UpdatePlagueLens();
end

function TurnPlagueLensOff()
	UI.PlaySound("UI_Lens_Overlay_Off");
	UILens.GetOverlay(OVERLAY_ID):SetVisible(false);
--	UILens.SetDesaturation(0);
	if UI.GetInterfaceMode() == InterfaceModeTypes.VIEW_MODAL_LENS then
		UI.SetInterfaceMode(InterfaceModeTypes.SELECTION);
	end
end

function OnToggleLensList()
	if m_uiPlagueToggle ~= nil then
		if Controls.LensPanel:IsHidden() then
			m_uiPlagueToggle.LensButton:SetCheck(false);
		end
	end
	XP2_OnToggleLensList();
end

function TogglePlagueLens()
	if m_uiPlagueToggle.LensButton:IsChecked() then
		TurnPlagueLensOn();
	else
		TurnPlagueLensOff();
	end
end

function UpdatePlagueLens()
	local colorData:table = {};
	local mapCount:number = Map.GetPlotCount() - 1;
	for plotIndex = 0, mapCount, 1 do
		local pPlot:object = Map.GetPlotByIndex(plotIndex);
		local plagueAmt:number = pPlot:GetProperty(PLAGUE_PROP);
		if plagueAmt ~= nil and plagueAmt > 0 then
			if not colorData[plagueAmt] then colorData[plagueAmt] = {}; end
			table.insert(colorData[plagueAmt], plotIndex);
		end
	end

	local pOverlay:object = UILens.GetOverlay("PlagueHighlight");
	pOverlay:ClearAll();
	for plagueAmt, plots in pairs(colorData) do
		local plaguePct:number = plagueAmt / PLAGUE_PROP_MAX_AMOUNT;
		local color:number = UI.GetColorValue(1-plaguePct, 1-plaguePct, 1-plaguePct, PLAGUE_OVERLAY_ALPHA);
		pOverlay:HighlightColoredHexes(plots, color, 0);
	end
end

function OnInterfaceModeChanged(eOldMode:number, eNewMode:number)
	if eOldMode == InterfaceModeTypes.VIEW_MODAL_LENS then
		if m_uiPlagueToggle.LensButton:IsChecked() then
			m_uiPlagueToggle.LensButton:SetCheck(false);
			TurnPlagueLensOff();
		end
	end
end

function OnInputActionTriggered( actionId )
	-- dont show panel if there is no local player
	if (Game.GetLocalPlayer() == -1) then
		return;
	end

	if(actionId == m_TogglePlagueLensId) then
		LensPanelHotkeyControl( m_uiPlagueToggle.LensButton );
		TogglePlagueLens();
    else
        XP2_OnInputActionTriggered( actionId );
	end
end

-- ===========================================================================
function OnLensLayerOn( layerNum:number )
	if layerNum == m_TogglePlagueLensId then
		UpdateLoyaltyLens();
		UI.PlaySound("UI_Lens_Overlay_On");
		UILens.SetDesaturation(1.0);
	else 
		XP2_OnLensLayerOn( layerNum );
	end
end

-- ===========================================================================
function OnLensLayerOff( layerNum:number )
	if layerNum == m_TogglePlagueLensId then
		UILens.SetDesaturation(0.0);
	else
		XP2_OnLensLayerOff( layerNum );
	end


--	if UILens.IsLensActive("Plague") then
--		-- Other lenses may set saturation value in their LensLayerOff event handler
--		-- Overriding it here ensures the saturation value is always correct when the Plague lens is active - sbatista ]]
--		UILens.SetDesaturation(1.0);
--	end
end

-- ===========================================================================
function ToggleLensList( closeIfOpen )
	if Controls.LensPanel:IsHidden() then
		OnToggleLensList();
	elseif closeIfOpen then
		CloseLensList();
		return false;
	end
	return true;
end

-- ===========================================================================
function LateInitialize()

	XP2_LateInitialize();

	local pTextButton = m_uiPlagueToggle.LensButton:GetTextButton();
	pTextButton:LocalizeAndSetText("LOC_HUD_PLAGUE_LENS");

	local pToolTip = Locale.Lookup("LOC_HUD_PLAGUE_LENS_TT");
	m_uiPlagueToggle.LensButton:SetToolTipString(pToolTip);
	
	m_uiPlagueToggle.LensButton:RegisterCallback( Mouse.eLClick, TogglePlagueLens );
	Events.InterfaceModeChanged.Add( OnInterfaceModeChanged );

	LuaEvents.OnViewPlagueLens.Add(function()
		if ToggleLensList(m_uiPlagueToggle.LensButton:IsChecked()) then
			m_uiPlagueToggle.LensButton:SetCheck(not m_uiPlagueToggle.LensButton:IsChecked());
			TogglePlagueLens();
		end
	end);

	-- Listen to our version of this callback
	Controls.LensButton:RegisterCallback( Mouse.eLClick, OnToggleLensList );
end
