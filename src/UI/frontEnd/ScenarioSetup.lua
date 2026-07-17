-- ===========================================================================
--	Single Player Create Game w/ Advanced Options
-- ===========================================================================
include("InstanceManager");
include("PlayerSetupLogic");
include("Civ6Common");
include("SupportFunctions");

-- ===========================================================================
-- ===========================================================================

local PULLDOWN_TRUNCATE_OFFSET:number = 40;
local MIN_SCREEN_Y            :number = 768;

local MAX_SIDEBAR_Y			:number = 960;

-- ===========================================================================
-- ===========================================================================

-- Instance managers for dynamic simple game options.
g_SimpleBooleanParameterManager = InstanceManager:new("SimpleBooleanParameterInstance", "CheckBox", Controls.CheckBoxParent);
g_SimplePullDownParameterManager = InstanceManager:new("SimplePullDownParameterInstance", "Root", Controls.PullDownParent);
g_SimpleSliderParameterManager = InstanceManager:new("SimpleSliderParameterInstance", "Root", Controls.SliderParent);
g_SimpleStringParameterManager = InstanceManager:new("SimpleStringParameterInstance", "StringRoot", Controls.EditBoxParent);

local m_NonLocalPlayerSlotManager	:table = InstanceManager:new("NonLocalPlayerSlotInstance", "Root", Controls.NonLocalPlayersSlotStack);
local m_singlePlayerID				:number = 0;			-- The player ID of the human player in singleplayer.
local m_AdvancedMode				:boolean = false;
local m_ScenarioData				:table = {};

-- ===========================================================================
-- Override hiding game setup to release simplified instances.
-- ===========================================================================
GameSetup_HideGameSetup = HideGameSetup;
function HideGameSetup(func)
	GameSetup_HideGameSetup(func);
	g_SimpleBooleanParameterManager:ResetInstances();
	g_SimplePullDownParameterManager:ResetInstances();
	g_SimpleSliderParameterManager:ResetInstances();
	g_SimpleStringParameterManager:ResetInstances();
end

-- ===========================================================================
-- Input Handler
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then
		local key:number = pInputStruct:GetKey();
		if key == Keys.VK_ESCAPE then
			OnBackButton();
		end
	end
	return true;
end

local _UI_BeforeRefresh = UI_BeforeRefresh;
function UI_BeforeRefresh()
	
	if(_UI_BeforeRefresh) then
		_UI_BeforeRefresh();
	end

	-- Reset basic setup container states
	Controls.CreateGame_GameDifficultyContainer:SetHide(true);
	Controls.CreateGame_SpeedPulldownContainer:SetHide(true);
	Controls.CreateGame_MapTypeContainer:SetHide(true);
	Controls.CreateGame_MapSizeContainer:SetHide(true);
end

-- Override for SetupParameters to filter ruleset values by non-scenario only.
function GameParameters_FilterValues(o, parameter, values)
	values = o.Default_Parameter_FilterValues(o, parameter, values);
	if(parameter.ParameterId == "Ruleset") then
		local new_values = {};
		for i,v in ipairs(values) do
			local scenarioData = GetScenarioData(v.Value);
			if(scenarioData.IsScenario) then
				table.insert(new_values, v);
			end
		end
		values = new_values;
	end

	return values;
end

function GetScenarioData(scenarioType:string)
	if not m_ScenarioData[scenarioType] then
		local query:string = "SELECT Description, LongDescription, IsScenario, ScenarioSetupPortrait, ScenarioSetupPortraitBackground from Rulesets where RulesetType = ? LIMIT 1";
		local result:table = DB.ConfigurationQuery(query, scenarioType);
		if result and #result > 0 then
			m_ScenarioData[scenarioType] = result[1];
		else
			m_ScenarioData[scenarioType] = {};
		end
	end
	return m_ScenarioData[scenarioType];
end

function RefreshScenarioData(scenarioType:string)
	local portrait:string;
	local background:string;
	local description:string;
	local data:table = GetScenarioData(scenarioType);

	if (data.LongDescription) then
		description = Locale.Lookup(data.LongDescription);
	elseif(data.Description) then
		description = Locale.Lookup(data.Description);
	end

	if data.ScenarioSetupPortrait then
		portrait = data.ScenarioSetupPortrait;
	end
	
	if data.ScenarioSetupPortraitBackground then
		background = data.ScenarioSetupPortraitBackground;
	end

	if(background) then
		Controls.LeaderBG:SetTexture(background);
		Controls.RLeaderBG:SetTexture(background);
	end
	Controls.LeaderBG:SetHide(background == nil);
	Controls.RLeaderBG:SetHide(background == nil);

	if(portrait) then
		Controls.LeaderImage:SetTexture(portrait);
	end
	Controls.LeaderImage:SetHide(portrait == nil);

	Controls.ScenarioDescription:SetText(description);
end

-- ===========================================================================
function CreatePulldownDriver(o, parameter, c, container)
	local driver = {
		Control = c,
		Container = container,
		UpdateValue = function(value)
			local button = c:GetButton();
			local truncateWidth = button:GetSizeX() - PULLDOWN_TRUNCATE_OFFSET;
			TruncateStringWithTooltip(button, truncateWidth, value and value.Name or nil);
		end,
		UpdateValues = function(values)
			-- If container was included, hide it if there is only 1 possible value.
			if(#values == 1 and container ~= nil) then
				container:SetHide(true);
			else
				if(container) then
					container:SetHide(false);
				end

				c:ClearEntries();
				for i,v in ipairs(values) do
					local entry = {};
					c:BuildEntry( "InstanceOne", entry );
					entry.Button:SetText(v.Name);
					entry.Button:SetToolTipString(v.Description);

					entry.Button:RegisterCallback(Mouse.eLClick, function()
						o:SetParameterValue(parameter, v);
						Network.BroadcastGameConfig();
					end);

					if v.Domain == "Rulesets" then
						entry.Button:RegisterCallback(Mouse.eMouseEnter, function() 
							if c:IsOpen() then
								RefreshScenarioData(v.Value);
							end
						end);
					end
				end
				c:CalculateInternals();
			end			
		end,
		SetEnabled = function(enabled, parameter)
			c:SetDisabled(not enabled or #parameter.Values <= 1);
		end,
		SetVisible = function(visible, parameter)
			container:SetHide(not visible or parameter.Value == nil or #parameter.Values <= 1);
		end,	
		Destroy = nil,		-- It's a fixed control, no need to delete.
	};
	
	return driver;	
end

-- ===========================================================================
function CreateRightPanelDescriptionDriver(o, parameter)
	local driver = {
		UpdateValue = function(v)
			Controls.ScenarioDescription:SetText(v.Description or v.Name);
			RefreshScenarioData(v.Value);
		end,
		UpdateValues = nil,
		SetEnabled = nil,
		SetVisible = nil,	-- Never hide the basic pulldown.
		Destroy = nil,		-- It's a fixed control, no need to delete.
	};
	
	return driver;	
end

-- ===========================================================================
-- Override parameter behavior for basic setup screen.
g_ParameterFactories["Ruleset"] = function(o, parameter)
	
	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_GameRuleset, Controls.CreateGame_RulesetContainer));

	table.insert(drivers, CreateRightPanelDescriptionDriver(o, parameter));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_DefaultCreateParameterDriver(o, parameter));

	return drivers;
end
g_ParameterFactories["GameDifficulty"] = function(o, parameter)

	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_GameDifficulty, Controls.CreateGame_GameDifficultyContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_DefaultCreateParameterDriver(o, parameter));

	return drivers;
end

-- ===========================================================================
g_ParameterFactories["GameSpeeds"] = function(o, parameter)

	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_SpeedPulldown, Controls.CreateGame_SpeedPulldownContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_DefaultCreateParameterDriver(o, parameter));

	return drivers;
end

-- ===========================================================================
g_ParameterFactories["Map"] = function(o, parameter)

	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_MapType, Controls.CreateGame_MapTypeContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_DefaultCreateParameterDriver(o, parameter));

	return drivers;
end

-- ===========================================================================
g_ParameterFactories["MapSize"] = function(o, parameter)

	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_MapSize, Controls.CreateGame_MapSizeContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_DefaultCreateParameterDriver(o, parameter));

	return drivers;
end

function CreateSimpleParameterDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end

	local control;
	
	-- If there is no parent, don't visualize the control.  This is most likely a player parameter.
	if(parent == nil) then
		return;
	end;

	if(parameter.Domain == "bool") then
		local c = g_SimpleBooleanParameterManager:GetInstance();	
		
		local name = Locale.ToUpper(parameter.Name);
		c.CheckBox:SetText(name);
		c.CheckBox:SetToolTipString(parameter.Description);
		c.CheckBox:RegisterCallback(Mouse.eLClick, function()
			o:SetParameterValue(parameter, not c.CheckBox:IsSelected());
			Network.BroadcastGameConfig();
		end);
		c.CheckBox:ChangeParent(parent);

		control = {
			Control = c,
			UpdateValue = function(value, parameter)
				
				-- Sometimes the parameter name is changed, be sure to update it.
				c.CheckBox:SetText(parameter.Name);
				c.CheckBox:SetToolTipString(parameter.Description);
				
				-- We have to invalidate the selection state in order
				-- to trick the button to use the right vis state..
				-- Please change this to a real check box in the future...please
				c.CheckBox:SetSelected(not value);
				c.CheckBox:SetSelected(value);
			end,
			SetEnabled = function(enabled)
				c.CheckBox:SetDisabled(not enabled);
			end,
			SetVisible = function(visible)
				c.CheckBox:SetHide(not visible);
			end,
			Destroy = function()
				g_SimpleBooleanParameterManager:ReleaseInstance(c);
			end,
		};

	elseif(parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text") then
		local c = g_SimpleStringParameterManager:GetInstance();		

		local name = Locale.ToUpper(parameter.Name);	
		c.StringName:SetText(name);
		c.StringRoot:SetToolTipString(parameter.Description);
		c.StringEdit:SetEnabled(true);

		local canChangeEnableState = true;

		if(parameter.Domain == "int") then
			c.StringEdit:SetNumberInput(true);
			c.StringEdit:SetMaxCharacters(16);
			c.StringEdit:RegisterCommitCallback(function(textString)
				o:SetParameterValue(parameter, tonumber(textString));	
				Network.BroadcastGameConfig();
			end);
		elseif(parameter.Domain == "uint") then
			c.StringEdit:SetNumberInput(true);
			c.StringEdit:SetMaxCharacters(16);
			c.StringEdit:RegisterCommitCallback(function(textString)
				local value = math.max(tonumber(textString) or 0, 0);
				o:SetParameterValue(parameter, value);	
				Network.BroadcastGameConfig();
			end);
		else
			c.StringEdit:SetNumberInput(false);
			c.StringEdit:SetMaxCharacters(64);
			if UI.HasFeature("TextEntry") == true then
				c.StringEdit:RegisterCommitCallback(function(textString)
					o:SetParameterValue(parameter, textString);	
					Network.BroadcastGameConfig();
				end);
			else
				canChangeEnableState = false;
				c.StringEdit:SetEnabled(false);
			end
		end

		c.StringRoot:ChangeParent(parent);

		control = {
			Control = c,
			UpdateValue = function(value)
				c.StringEdit:SetText(value);
			end,
			SetEnabled = function(enabled)
				if canChangeEnableState then
					c.StringRoot:SetDisabled(not enabled);
					c.StringEdit:SetDisabled(not enabled);
				end
			end,
			SetVisible = function(visible)
				c.StringRoot:SetHide(not visible);
			end,
			Destroy = function()
				g_SimpleStringParameterManager:ReleaseInstance(c);
			end,
		};
	elseif (parameter.Values and parameter.Values.Type == "IntRange") then -- Range
		
		local minimumValue = parameter.Values.MinimumValue;
		local maximumValue = parameter.Values.MaximumValue;

		-- Get the UI instance
		local c = g_SimpleSliderParameterManager:GetInstance();	
		
		c.Root:ChangeParent(parent);

		local name = Locale.ToUpper(parameter.Name);
		if c.StringName ~= nil then
			c.StringName:SetText(name);
		end
			
		c.OptionTitle:SetText(name);
		c.Root:SetToolTipString(parameter.Description);
		c.OptionSlider:RegisterSliderCallback(function()
			local stepNum = c.OptionSlider:GetStep();
			
			-- This method can get called pretty frequently, try and throttle it.
			if(parameter.Value ~= minimumValue + stepNum) then
				o:SetParameterValue(parameter, minimumValue + stepNum);
				Network.BroadcastGameConfig();
			end
		end);


		control = {
			Control = c,
			UpdateValue = function(value)
				if(value) then
					c.OptionSlider:SetStep(value - minimumValue);
					c.NumberDisplay:SetText(tostring(value));
				end
			end,
			UpdateValues = function(values)
				c.OptionSlider:SetNumSteps(values.MaximumValue - values.MinimumValue);
			end,
			SetEnabled = function(enabled, parameter)
				c.OptionSlider:SetHide(not enabled or parameter.Values == nil or parameter.Values.MinimumValue == parameter.Values.MaximumValue);
			end,
			SetVisible = function(visible, parameter)
				c.Root:SetHide(not visible or parameter.Value == nil );
			end,
			Destroy = function()
				g_SimpleSliderParameterManager:ReleaseInstance(c);
			end,
		};	
	elseif (parameter.Values) then -- MultiValue
		
		-- Get the UI instance
		local c = g_SimplePullDownParameterManager:GetInstance();	

		c.Root:ChangeParent(parent);
		if c.StringName ~= nil then
			local name = Locale.ToUpper(parameter.Name);
			c.StringName:SetText(name);
		end

		control = {
			Control = c,
			UpdateValue = function(value)
				local button = c.PullDown:GetButton();
				button:SetText( value and value.Name or nil);
				button:SetToolTipString(value and value.Description or nil);
			end,
			UpdateValues = function(values)
				c.PullDown:ClearEntries();

				for i,v in ipairs(values) do
					local entry = {};
					c.PullDown:BuildEntry( "InstanceOne", entry );
					entry.Button:SetText(v.Name);
					entry.Button:SetToolTipString(v.Description);

					entry.Button:RegisterCallback(Mouse.eLClick, function()
						o:SetParameterValue(parameter, v);
						Network.BroadcastGameConfig();
					end);
				end
				c.PullDown:CalculateInternals();
			end,
			SetEnabled = function(enabled, parameter)
				c.PullDown:SetDisabled(not enabled or #parameter.Values <= 1);
			end,
			SetVisible = function(visible, parameter)
				c.Root:SetHide(not visible or parameter.Value == nil or #parameter.Values <= 1);
			end,
			Destroy = function()
				g_SimplePullDownParameterManager:ReleaseInstance(c);
			end,
		};	
	end

	return control;
end

-- The method used to create a UI control associated with the parameter.
-- Returns either a control or table that will be used in other parameter view related hooks.
function GameParameters_UI_CreateParameter(o, parameter)
	local func = g_ParameterFactories[parameter.ParameterId];

	local control;
	if(func)  then
		control = func(o, parameter);
	elseif(parameter.GroupId == "BasicGameOptions" or parameter.GroupId == "BasicMapOptions") then	
		control = {
			CreateSimpleParameterDriver(o, parameter, Controls.CreateGame_ExtraParametersStack),
			GameParameters_UI_DefaultCreateParameterDriver(o, parameter)
		};
	else
		control = GameParameters_UI_DefaultCreateParameterDriver(o, parameter);
	end

	o.Controls[parameter.ParameterId] = control;
end

-- ===========================================================================
-- Remove player handler.
function RemovePlayer(voidValue1, voidValue2, control)
	print("Removing Player " .. tonumber(voidValue1));
	local playerConfig = PlayerConfigurations[voidValue1];
	playerConfig:SetLeaderTypeName(nil);
	
	GameConfiguration.RemovePlayer(voidValue1);

	GameSetup_PlayerCountChanged();
end

-- ===========================================================================
-- Add UI entries for all the players.  This does not set the
-- UI values of the player.
-- ===========================================================================
function RefreshPlayerSlots()

	RebuildPlayerParameters();
	m_NonLocalPlayerSlotManager:ResetInstances();

	local player_ids = GameConfiguration.GetParticipatingPlayerIDs();

	local minPlayers = MapConfiguration.GetMinMajorPlayers() or 2;
	local maxPlayers = MapConfiguration.GetMaxMajorPlayers() or 2;
	local can_remove = #player_ids > minPlayers;
	local can_add = #player_ids < maxPlayers;

	Controls.AddAIButton:SetHide(not can_add);

	print("There are " .. #player_ids .. " participating players.");

	Controls.BasicTooltipContainer:DestroyAllChildren();
	Controls.BasicPlacardContainer:DestroyAllChildren();
	Controls.AdvancedTooltipContainer:DestroyAllChildren();

	local iSidebarSize = Controls.CreateGameWindow:GetSizeY() - 100;
	if iSidebarSize > MAX_SIDEBAR_Y then
		iSidebarSize = MAX_SIDEBAR_Y;
	end
	Controls.LeftPanel:SetSizeY(iSidebarSize);
	Controls.RightPanel:SetSizeY(iSidebarSize);

    local basicTooltip	:table = {};
	ContextPtr:BuildInstanceForControl( "CivToolTip", basicTooltip, Controls.BasicTooltipContainer );
	local basicPlacard	:table = {};
	ContextPtr:BuildInstanceForControl( "LeaderPlacard", basicPlacard, Controls.BasicPlacardContainer );

	local basicTooltipData : table = {
		InfoStack			= basicTooltip.InfoStack,
		InfoScrollPanel		= basicTooltip.InfoScrollPanel;
		CivToolTipSlide		= basicTooltip.CivToolTipSlide;
		CivToolTipAlpha		= basicTooltip.CivToolTipAlpha;
		UniqueIconIM		= InstanceManager:new("IconInfoInstance",	"Top",	basicTooltip.InfoStack );		
		HeaderIconIM		= InstanceManager:new("IconInstance",		"Top",	basicTooltip.InfoStack );
		CivHeaderIconIM		= InstanceManager:new("CivIconInstance",	"Top",	basicTooltip.InfoStack );
		HeaderIM			= InstanceManager:new("HeaderInstance",		"Top",	basicTooltip.InfoStack );
		HasLeaderPlacard	= true;
		LeaderBG			= basicPlacard.LeaderBG;
		LeaderImage			= basicPlacard.LeaderImage;
		DummyImage			= basicPlacard.DummyImage;
		CivLeaderSlide		= basicPlacard.CivLeaderSlide;
		CivLeaderAlpha		= basicPlacard.CivLeaderAlpha;
	};

	local advancedTooltip	:table = {};
	ContextPtr:BuildInstanceForControl( "CivToolTip", advancedTooltip, Controls.AdvancedTooltipContainer );

	local advancedTooltipData : table = {
		InfoStack			= advancedTooltip.InfoStack,
		InfoScrollPanel		= advancedTooltip.InfoScrollPanel;
		CivToolTipSlide		= advancedTooltip.CivToolTipSlide;
		CivToolTipAlpha		= advancedTooltip.CivToolTipAlpha;
		UniqueIconIM		= InstanceManager:new("IconInfoInstance",	"Top",	advancedTooltip.InfoStack );		
		HeaderIconIM		= InstanceManager:new("IconInstance",		"Top",	advancedTooltip.InfoStack );
		CivHeaderIconIM		= InstanceManager:new("CivIconInstance",	"Top",	advancedTooltip.InfoStack );
		HeaderIM			= InstanceManager:new("HeaderInstance",		"Top",	advancedTooltip.InfoStack );
		HasLeaderPlacard	= false;
	};

	for i, player_id in ipairs(player_ids) do	
		if(m_singlePlayerID == player_id) then
			SetupLeaderPulldown(player_id, Controls, "Basic_LocalPlayerPulldown", "Basic_LocalPlayerCivIcon", "Basic_LocalPlayerCivIconBG", "Basic_LocalPlayerLeaderIcon", "Basic_LocalPlayerScrollText", basicTooltipData);
			SetupLeaderPulldown(player_id, Controls, "Advanced_LocalPlayerPulldown", "Advanced_LocalPlayerCivIcon", "Advanced_LocalPlayerCivIconBG", "Advanced_LocalPlayerLeaderIcon", "Advanced_LocalPlayerScrollText", advancedTooltipData);
		else
			local ui_instance = m_NonLocalPlayerSlotManager:GetInstance();
			
			-- Assign the Remove handler
			if(can_remove) then
				ui_instance.RemoveButton:SetVoid1(player_id);
				ui_instance.RemoveButton:RegisterCallback(Mouse.eLClick, RemovePlayer);
			end
			ui_instance.RemoveButton:SetHide(not can_remove);
			
			SetupLeaderPulldown(player_id, ui_instance,"PlayerPullDown",nil,nil,nil,nil,advancedTooltipData);
		end
	end

	Controls.NonLocalPlayersSlotStack:CalculateSize();
	Controls.NonLocalPlayersSlotStack:ReprocessAnchoring();
	Controls.NonLocalPlayersStack:CalculateSize();
	Controls.NonLocalPlayersStack:ReprocessAnchoring();
	Controls.NonLocalPlayersPanel:CalculateInternalSize();
	Controls.NonLocalPlayersPanel:CalculateSize();

	-- Queue another refresh
	GameSetup_RefreshParameters();
end

-- ===========================================================================
-- Called every time parameters have been refreshed.
-- This is a useful spot to perform validation.
function UI_PostRefreshParameters()
	-- Most of the options self-heal due to the setup parameter logic.
	-- However, player options are allowed to be in an 'invalid' state for UI
	-- This way, instead of hiding/preventing the user from selecting an invalid player
	-- we can allow it, but display an error message explaining why it's invalid.

	-- This is primarily used to present ownership errors and custom constraint errors.
	Controls.StartButton:SetDisabled(false);
	Controls.StartButton:SetToolTipString(nil);

	local game_err = GetGameParametersError();
	if(game_err) then
		Controls.StartButton:SetDisabled(true);
		Controls.StartButton:LocalizeAndSetToolTip("LOC_SETUP_PARAMETER_ERROR");
	end

	local player_ids = GameConfiguration.GetParticipatingPlayerIDs();
	for i, player_id in ipairs(player_ids) do	
		local err = GetPlayerParameterError(player_id);
		if(err) then
			Controls.StartButton:SetDisabled(true);
			Controls.StartButton:LocalizeAndSetToolTip("LOC_SETUP_PLAYER_PARAMETER_ERROR");
		end
	end

	Controls.CreateGameOptions:CalculateSize();
	Controls.CreateGameOptions:ReprocessAnchoring();
end

-------------------------------------------------------------------------------
-- Event Listeners
-------------------------------------------------------------------------------
function OnFinishedGameplayContentConfigure(result)
	if(ContextPtr and not ContextPtr:IsHidden() and result.Success) then
		GameSetup_RefreshParameters();
	end
end

-- ===========================================================================
function GameSetup_PlayerCountChanged()
	print("Player Count Changed");
	RefreshPlayerSlots();
end

-- ===========================================================================
function OnShow()
	RefreshPlayerSlots();	-- Will trigger a game parameter refresh.
	AutoSizeGridButton(Controls.DefaultButton,133,36,15,"H");
	AutoSizeGridButton(Controls.CloseButton,133,36,10,"H");
end

-- ===========================================================================
function OnHide()
	HideGameSetup();
	ReleasePlayerParameters();
	m_ScenarioData = {};
end


-- ===========================================================================
-- Button Handlers
-- ===========================================================================

-- ===========================================================================
function OnAddAIButton()
	-- Search for an empty slot number and mark the slot as computer.
	-- Then dispatch the player count changed event.
	local iPlayer = 0;
	while(true) do
		local playerConfig = PlayerConfigurations[iPlayer];
		
		-- If we've reached the end of the line, exit.
		if(playerConfig == nil) then
			break;
		end

		-- Find a suitable slot to add the AI.
		if (playerConfig:GetSlotStatus() == SlotStatus.SS_CLOSED) then
			playerConfig:SetSlotStatus(SlotStatus.SS_COMPUTER);
			playerConfig:SetMajorCiv();

			GameSetup_PlayerCountChanged();
			break;
		end

		-- Increment the AI, this assumes that either player config will hit nil 
		-- or we'll reach a suitable slot.
		iPlayer = iPlayer + 1;
	end
end

-- ===========================================================================
function OnAdvancedSetup()
	Controls.CreateGameWindow:SetHide(true);
	Controls.AdvancedOptionsWindow:SetHide(false);
	m_AdvancedMode = true;
end

-- ===========================================================================
function OnDefaultButton()
	print("Reseting Setup Parameters");
	GameConfiguration.SetToDefaults();
	GameConfiguration.RegenerateSeeds();
	return GameSetup_PlayerCountChanged();
end

-- ===========================================================================
function OnStartButton()
	-- Is WorldBuilder active?
	if (GameConfiguration.IsWorldBuilderEditor()) then
		UI.SetWorldRenderView( WorldRenderView.VIEW_2D );
		UI.PlaySound("Set_View_2D");
		Events.SetGameEntryMethod("Scenario Start - World Builder");
		Network.HostGame(ServerType.SERVER_TYPE_NONE);
		
	else
		-- No, start a normal game
		UI.PlaySound("Set_View_3D");
		Events.SetGameEntryMethod("Scenario Start");
		Network.HostGame(ServerType.SERVER_TYPE_NONE);
	end
end



----------------------------------------------------------------    
function OnBackButton()
	if(m_AdvancedMode) then
		Controls.CreateGameWindow:SetHide(false);
		Controls.AdvancedOptionsWindow:SetHide(true);
		UpdateCivLeaderToolTip();					-- Need to make sure we update our placard/flyout card if we make a change in advanced setup and then come back
		m_AdvancedMode = false;		
	else
		UIManager:DequeuePopup( ContextPtr );
	end
end

----------------------------------------------------------------    
-- ===========================================================================
--	Handle Window Sizing
-- ===========================================================================

function Resize()
	local screenX, screenY:number  = UIManager:GetScreenSizeVal();
	local hideLogo		  :boolean = true;
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		Controls.MainWindow:SetSizeY(screenY-(Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		Controls.CreateGameWindow:SetSizeY(screenY-(Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		hideLogo = false;
	else
		Controls.MainWindow:SetSizeY(screenY);
	end
	Controls.LogoContainer:SetHide(hideLogo);	

	local iSidebarSize = Controls.CreateGameWindow:GetSizeY();
	if iSidebarSize > MAX_SIDEBAR_Y then
		iSidebarSize = MAX_SIDEBAR_Y;
	end
	Controls.BasicPlacardContainer:SetSizeY(iSidebarSize);
	Controls.BasicTooltipContainer:SetSizeY(iSidebarSize);
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
    Resize();
  end
end

-- ===========================================================================
function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidently break the invite!
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
--
-- ===========================================================================
function Initialize()

	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );

	Controls.AddAIButton:RegisterCallback( Mouse.eLClick, OnAddAIButton );
	Controls.AddAIButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.AdvancedSetupButton:RegisterCallback( Mouse.eLClick, OnAdvancedSetup );
	Controls.AdvancedSetupButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.DefaultButton:RegisterCallback( Mouse.eLClick, OnDefaultButton);
	Controls.DefaultButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.StartButton:RegisterCallback( Mouse.eLClick, OnStartButton );
	Controls.StartButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CloseButton:RegisterCallback( Mouse.eLClick, OnBackButton );
	Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	
	Events.FinishedGameplayContentConfigure.Add(OnFinishedGameplayContentConfigure);
	Events.SystemUpdateUI.Add( OnUpdateUI );
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );
	Resize();
end
--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local HOVER_SOUND = "Main_Menu_Mouse_Over"

local CAI_Panel = nil ---@type PanelWidget
local CAI_Tabs = nil ---@type TabControlWidget
local CAI_BasicPage = nil ---@type TabPageWidget
local CAI_BasicList = nil ---@type ListWidget
local CAI_AdvancedPage = nil ---@type TabPageWidget
local CAI_AdvancedList = nil ---@type ListWidget
local CAI_PlayerSection = nil ---@type SubMenuWidget
local CAI_Sections = {} ---@type table<string, SubMenuWidget>

local kFixedBasicParameters = {
	{ id = "Ruleset",       container = function() return Controls.CreateGame_RulesetContainer end },
	{ id = "GameDifficulty", container = function() return Controls.CreateGame_GameDifficultyContainer end },
	{ id = "GameSpeeds",    container = function() return Controls.CreateGame_SpeedPulldownContainer end },
	{ id = "Map",           container = function() return Controls.CreateGame_MapTypeContainer end },
	{ id = "MapSize",       container = function() return Controls.CreateGame_MapSizeContainer end },
}

local kFixedBasicParameterIds = {
	Ruleset = true,
	GameDifficulty = true,
	GameSpeeds = true,
	Map = true,
	MapSize = true,
}

local kGroupToSection = {
	BasicGameOptions = "Options",
	GameOptions = "Options",
	BasicMapOptions = "Options",
	MapOptions = "Options",
	GameModes = "Options",
	Victories = "Victories",
	AdvancedOptions = "Advanced",
}

local function CAI_Lookup(text, ...)
	if text == nil or text == "" then return "" end
	return Locale.Lookup(text, ...)
end

local function CAI_AppendExplanation(baseText, extraText)
	local base = baseText or ""
	local extra = extraText or ""
	if extra == "" or extra == base then return base end
	if base == "" then return extra end
	return base .. "[NEWLINE]" .. extra
end

local function CAI_ControlTooltip(control)
	if control and control.GetToolTipString then
		return control:GetToolTipString() or ""
	end
	return ""
end

local function CAI_SortParameters(a, b)
	if (a.SortIndex or 0) ~= (b.SortIndex or 0) then
		return (a.SortIndex or 0) < (b.SortIndex or 0)
	end
	return Locale.Compare(a.Name or "", b.Name or "") == -1
end

local function CAI_GetParameter(parameterId)
	return g_GameParameters and g_GameParameters.Parameters
		and g_GameParameters.Parameters[parameterId]
end

local function CAI_GetParameterControl(parameterId)
	return g_GameParameters and g_GameParameters.Controls
		and g_GameParameters.Controls[parameterId]
end

local function CAI_GetResolvedControl(control, preferLast)
	if control and control.Control then return control end
	if not control then return nil end
	if preferLast then
		for i = #control, 1, -1 do
			if control[i] and control[i].Control then return control[i] end
		end
	else
		for i = 1, #control do
			if control[i] and control[i].Control then return control[i] end
		end
	end
	return control
end

local function CAI_GetControlData(parameterId, preferLast)
	local resolved = CAI_GetResolvedControl(CAI_GetParameterControl(parameterId), preferLast)
	return resolved and resolved.Control
end

local function CAI_GetControlRoot(parameterId, preferLast)
	local c = CAI_GetControlData(parameterId, preferLast)
	if not c then return nil end
	if type(c) ~= "table" then return c end
	return c.CheckBox or c.StringRoot or c.Root or c.ButtonRoot or c.Button or c
end

local function CAI_IsParameterHidden(parameterId, preferLast)
	local root = CAI_GetControlRoot(parameterId, preferLast)
	return root and root.IsHidden and root:IsHidden()
end

local function CAI_IsParameterDisabled(parameterId, preferLast)
	local c = CAI_GetControlData(parameterId, preferLast)
	if not c then return false end
	if type(c) ~= "table" then
		return c.IsDisabled and c:IsDisabled()
	end
	local candidates = {
		c.CheckBox,
		c.Button,
		c.PullDown,
		c.OptionSlider,
		c.StringEdit,
		c.StringRoot,
		c.Root,
		c,
	}
	for _, candidate in ipairs(candidates) do
		if candidate and candidate.IsDisabled and candidate:IsDisabled() then
			return true
		end
	end
	return false
end

local function CAI_GetInvalidReason(value)
	if not value or not value.Invalid then return "" end
	return CAI_Lookup(value.InvalidReason or "LOC_SETUP_ERROR_INVALID_OPTION")
end

local function CAI_GetLocalizedError(errorValue)
	if type(errorValue) == "table" then
		return CAI_Lookup(errorValue.Reason or errorValue.InvalidReason or errorValue.Error)
	end
	if type(errorValue) == "string" and string.sub(errorValue, 1, 4) == "LOC_" then
		return CAI_Lookup(errorValue)
	end
	return ""
end

local function CAI_ValueMatches(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	if a.QueryId ~= nil or b.QueryId ~= nil then
		return a.QueryId == b.QueryId and a.QueryIndex == b.QueryIndex
	end
	return a.Value == b.Value
end

local function CAI_GetScenarioDescription(value)
	if not value then return "" end
	local data = value.Value and GetScenarioData(value.Value)
	if data then
		if data.LongDescription then return CAI_Lookup(data.LongDescription) end
		if data.Description then return CAI_Lookup(data.Description) end
	end
	return value.Description or CAI_Lookup(value.RawDescription)
end

local kUniqueTypeKeys = {
	{ prefix = "ICON_UNIT_",        singular = "LOC_CAI_UNIQUE_UNIT",        plural = "LOC_CAI_UNIQUE_UNITS" },
	{ prefix = "ICON_BUILDING_",    singular = "LOC_CAI_UNIQUE_BUILDING",    plural = "LOC_CAI_UNIQUE_BUILDINGS" },
	{ prefix = "ICON_DISTRICT_",    singular = "LOC_CAI_UNIQUE_DISTRICT",    plural = "LOC_CAI_UNIQUE_DISTRICTS" },
	{ prefix = "ICON_IMPROVEMENT_", singular = "LOC_CAI_UNIQUE_IMPROVEMENT", plural = "LOC_CAI_UNIQUE_IMPROVEMENTS" },
}

local function CAI_GetUniqueTypeIndex(icon)
	if not icon then return nil end
	for i, entry in ipairs(kUniqueTypeKeys) do
		if string.find(icon, entry.prefix) then return i end
	end
	return nil
end

local function CAI_BuildLeaderTooltip(domain, leaderType)
	if not domain or not leaderType then return "" end
	if leaderType == "RANDOM" or leaderType == "RANDOM_POOL1" or leaderType == "RANDOM_POOL2" then
		return ""
	end
	local info = GetPlayerInfo(domain, leaderType)
	if not info then return "" end

	local parts = {}
	if info.CivilizationAbility then
		table.insert(parts, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_CIV_ABILITY") .. ": "
			.. Locale.Lookup(info.CivilizationAbility.Name) .. ": "
			.. Locale.Lookup(info.CivilizationAbility.Description))
	end
	if info.LeaderAbility then
		table.insert(parts, Locale.Lookup("LOC_CAI_ADVANCED_SETUP_LEADER_ABILITY") .. ": "
			.. Locale.Lookup(info.LeaderAbility.Name) .. ": "
			.. Locale.Lookup(info.LeaderAbility.Description))
	end
	if info.Uniques then
		local grouped = {}
		local ungrouped = {}
		for _, unique in ipairs(info.Uniques) do
			local typeIndex = CAI_GetUniqueTypeIndex(unique.Icon)
			if typeIndex then
				grouped[typeIndex] = grouped[typeIndex] or {}
				table.insert(grouped[typeIndex], unique)
			else
				table.insert(ungrouped, unique)
			end
		end
		for i, entry in ipairs(kUniqueTypeKeys) do
			if grouped[i] then
				local heading = #grouped[i] > 1 and entry.plural or entry.singular
				local items = {}
				for _, unique in ipairs(grouped[i]) do
					table.insert(items, Locale.Lookup(unique.Name) .. ": " .. Locale.Lookup(unique.Description))
				end
				table.insert(parts, Locale.Lookup(heading) .. "[NEWLINE]" .. table.concat(items, "[NEWLINE]"))
			end
		end
		for _, unique in ipairs(ungrouped) do
			table.insert(parts, Locale.Lookup(unique.Name) .. ": " .. Locale.Lookup(unique.Description))
		end
	end
	return table.concat(parts, "[NEWLINE]")
end

local function CAI_GetPlayerLeaderParameter(playerId)
	local parameters = GetPlayerParameters(playerId)
	return parameters and parameters.Parameters and parameters.Parameters.PlayerLeader
end

local function CAI_GetPlayerLeaderTooltip(playerId)
	local parameter = CAI_GetPlayerLeaderParameter(playerId)
	if not parameter or not parameter.Value then return "" end
	return CAI_AppendExplanation(
		CAI_BuildLeaderTooltip(parameter.Value.Domain, parameter.Value.Value),
		CAI_GetInvalidReason(parameter.Value)
	)
end

local function CAI_BuildLeaderOptions(playerId)
	local parameter = CAI_GetPlayerLeaderParameter(playerId)
	if not parameter or not parameter.Values then return {}, 0 end

	local options = {}
	local selectedIndex = 0
	for i, value in ipairs(parameter.Values) do
		local invalidReason = CAI_GetInvalidReason(value)
		local label = value.Name or ""
		local info = value.Domain and value.Value and GetPlayerInfo(value.Domain, value.Value)
		if info and info.CivilizationName then
			label = label .. ", " .. Locale.Lookup(info.CivilizationName)
		end
		table.insert(options, {
			label = CAI_AppendExplanation(label, invalidReason),
			tooltip = CAI_AppendExplanation(CAI_BuildLeaderTooltip(value.Domain, value.Value), invalidReason),
			value = value,
		})
		if selectedIndex == 0 and parameter.Value and value.Value == parameter.Value.Value then
			selectedIndex = i
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

local function CAI_MakeLeaderDropdown(playerId, label, focusKey, hiddenPredicate)
	local dropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioLeader"), "Dropdown", {
		Label = label,
		Tooltip = function() return CAI_GetPlayerLeaderTooltip(playerId) end,
		HiddenPredicate = hiddenPredicate,
		DisabledPredicate = function()
			local parameter = CAI_GetPlayerLeaderParameter(playerId)
			return parameter and parameter.Enabled == false
		end,
		FocusKey = focusKey,
	})
	local options, selectedIndex = CAI_BuildLeaderOptions(playerId)
	dropdown:SetOptions(options)
	if selectedIndex > 0 then dropdown:SetSelectedIndex(selectedIndex, true) end
	dropdown:SetValueSetter(function(_, value)
		local parameters = GetPlayerParameters(playerId)
		local parameter = parameters and parameters.Parameters and parameters.Parameters.PlayerLeader
		if parameter then
			parameters:SetParameterValue(parameter, value)
			Network.BroadcastGameConfig()
		end
	end)
	dropdown:SetFocusSound(HOVER_SOUND)
	return dropdown
end

local function CAI_BuildParameterOptions(parameterId, includeScenarioDescription, suppressTooltip)
	local parameter = CAI_GetParameter(parameterId)
	if not parameter or not parameter.Values then return {}, 0 end

	local options = {}
	local selectedIndex = 0
	for i, value in ipairs(parameter.Values) do
		local invalidReason = CAI_GetInvalidReason(value)
		local tooltip = suppressTooltip and "" or (value.Description or CAI_Lookup(value.RawDescription))
		if includeScenarioDescription then
			tooltip = CAI_AppendExplanation(tooltip, CAI_GetScenarioDescription(value))
		end
		table.insert(options, {
			label = CAI_AppendExplanation(value.Name or "", invalidReason),
			tooltip = suppressTooltip and "" or CAI_AppendExplanation(tooltip, invalidReason),
			value = value,
		})
		if selectedIndex == 0 and CAI_ValueMatches(value, parameter.Value) then
			selectedIndex = i
		end
	end
	if selectedIndex == 0 and #options > 0 then selectedIndex = 1 end
	return options, selectedIndex
end

local function CAI_GetArraySummary(parameter)
	if not parameter then return "" end
	local value = parameter.Value
	local invert = parameter.UxHint == "InvertSelection"
	if type(value) == "table" then
		local count = #value
		local total = parameter.Values and #parameter.Values or 0
		if invert then
			if count == 0 then return CAI_Lookup("LOC_SELECTION_EVERYTHING") end
			if count == total then return CAI_Lookup("LOC_SELECTION_NOTHING") end
			return CAI_Lookup("LOC_SELECTION_CUSTOM", total - count)
		end
		if count == 0 then return CAI_Lookup("LOC_SELECTION_NOTHING") end
		if count == total then return CAI_Lookup("LOC_SELECTION_EVERYTHING") end
		return CAI_Lookup("LOC_SELECTION_CUSTOM", count)
	end
	return invert and CAI_Lookup("LOC_SELECTION_EVERYTHING") or CAI_Lookup("LOC_SELECTION_NOTHING")
end

local function CAI_MakeParameterWidget(parameter, options)
	local parameterId = parameter.ParameterId
	local preferLast = options and options.preferLast
	local includeScenarioDescription = options and options.includeScenarioDescription
	local suppressTooltip = parameterId == "GameDifficulty"
	local extraHidden = options and options.hidden
	local focusKey = options and options.focusKey or "param:" .. tostring(parameterId)
	local widget = nil

	local function IsHidden()
		if extraHidden and extraHidden() then return true end
		return CAI_IsParameterHidden(parameterId, preferLast)
	end

	local function IsDisabled()
		local live = CAI_GetParameter(parameterId)
		return (live and live.Enabled == false) or CAI_IsParameterDisabled(parameterId, preferLast)
	end

	if parameter.Array then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioArray"), "Button", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function() return CAI_GetArraySummary(CAI_GetParameter(parameterId)) end,
			HiddenPredicate = IsHidden,
			DisabledPredicate = IsDisabled,
			FocusKey = focusKey,
		})
	elseif parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioCheckbox"), "Checkbox", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			HiddenPredicate = IsHidden,
			DisabledPredicate = IsDisabled,
			FocusKey = focusKey,
		})
		local c = CAI_GetControlData(parameterId, preferLast)
		local checked = parameter.Value and true or false
		if c and c.CheckBox and c.CheckBox.IsSelected then checked = c.CheckBox:IsSelected() end
		widget:SetChecked(checked, true)
		widget:SetValueSetter(function(_, newValue)
			local liveControl = CAI_GetControlData(parameterId, preferLast)
			local checkBox = liveControl and liveControl.CheckBox
			if checkBox and checkBox.IsSelected and checkBox:IsSelected() ~= newValue then
				checkBox:DoLeftClick()
				return
			end
			local live = CAI_GetParameter(parameterId)
			if live and live.Value ~= newValue then
				g_GameParameters:SetParameterValue(live, newValue)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minimum = parameter.Values.MinimumValue
		local maximum = parameter.Values.MaximumValue
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioSlider"), "Slider", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local live = CAI_GetParameter(parameterId)
				return live and tostring(live.Value) or ""
			end,
			HiddenPredicate = IsHidden,
			DisabledPredicate = IsDisabled,
			FocusKey = focusKey,
		})
		widget:SetMin(minimum)
		widget:SetMax(maximum)
		widget:SetValue(parameter.Value or minimum, true)
		widget:SetValueSetter(function(_, newValue)
			local live = CAI_GetParameter(parameterId)
			if live and live.Value ~= newValue then
				g_GameParameters:SetParameterValue(live, newValue)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioDropdown"), "Dropdown", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function()
				local live = CAI_GetParameter(parameterId)
				if not live or not live.Value then return suppressTooltip and "" or (parameter.Description or "") end
				if suppressTooltip then return "" end
				local tooltip = live.Value.Description or CAI_Lookup(live.Value.RawDescription)
				if includeScenarioDescription then
					tooltip = CAI_AppendExplanation(tooltip, CAI_GetScenarioDescription(live.Value))
				end
				return CAI_AppendExplanation(tooltip, CAI_GetInvalidReason(live.Value))
			end,
			HiddenPredicate = IsHidden,
			DisabledPredicate = IsDisabled,
			FocusKey = focusKey,
		})
		local dropdownOptions, selectedIndex = CAI_BuildParameterOptions(
			parameterId,
			includeScenarioDescription,
			suppressTooltip
		)
		widget:SetOptions(dropdownOptions)
		if selectedIndex > 0 then widget:SetSelectedIndex(selectedIndex, true) end
		widget:SetValueSetter(function(_, value)
			local live = CAI_GetParameter(parameterId)
			if live then
				g_GameParameters:SetParameterValue(live, value)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioEdit"), "EditBox", {
			Label = function() return parameter.Name or "" end,
			Tooltip = function() return parameter.Description or "" end,
			HiddenPredicate = IsHidden,
			DisabledPredicate = IsDisabled,
			FocusKey = focusKey,
			HighlightOnEdit = true,
		})
		if domain == "int" or domain == "uint" then
			widget:SetEditMode(2)
			widget:SetMaxCharacters(16)
		else
			widget:SetMaxCharacters(64)
		end
		widget:SetText(parameter.Value ~= nil and tostring(parameter.Value) or "", true)
		widget:SetValueSetter(function(_, text)
			local value = text
			if domain == "int" then
				value = tonumber(text) or 0
			elseif domain == "uint" then
				value = math.max(tonumber(text) or 0, 0)
			end
			local live = CAI_GetParameter(parameterId)
			if live then
				g_GameParameters:SetParameterValue(live, value)
				Network.BroadcastGameConfig()
			end
		end)
	end

	if widget then widget:SetFocusSound(HOVER_SOUND) end
	return widget
end

local function CAI_RebuildBasicPage()
	if not CAI_BasicList then return end
	CAI_BasicList:ClearChildren()

	local function AddFixedParameter(definition)
		local parameter = CAI_GetParameter(definition.id)
		if parameter then
			local widget = CAI_MakeParameterWidget(parameter, {
				focusKey = "basic:param:" .. definition.id,
				includeScenarioDescription = definition.id == "Ruleset",
				hidden = function()
					local container = definition.container()
					return container and container.IsHidden and container:IsHidden()
				end,
			})
			if widget then CAI_BasicList:AddChild(widget) end
		end
	end

	AddFixedParameter(kFixedBasicParameters[1])

	CAI_BasicList:AddChild(CAI_MakeLeaderDropdown(
		m_singlePlayerID,
		function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		"basic:player:" .. tostring(m_singlePlayerID),
		function()
			return Controls.Basic_LocalPlayerPulldown.IsHidden
				and Controls.Basic_LocalPlayerPulldown:IsHidden()
		end
	))

	for i = 2, #kFixedBasicParameters do
		AddFixedParameter(kFixedBasicParameters[i])
	end

	local extraParameters = {}
	if g_GameParameters and g_GameParameters.Parameters then
		for parameterId, parameter in pairs(g_GameParameters.Parameters) do
			if not kFixedBasicParameterIds[parameterId]
				and (parameter.GroupId == "BasicGameOptions" or parameter.GroupId == "BasicMapOptions") then
				table.insert(extraParameters, parameter)
			end
		end
	end
	table.sort(extraParameters, CAI_SortParameters)
	for _, parameter in ipairs(extraParameters) do
		local widget = CAI_MakeParameterWidget(parameter, {
			focusKey = "basic:param:" .. tostring(parameter.ParameterId),
		})
		if widget then CAI_BasicList:AddChild(widget) end
	end
end

local function CAI_BuildPlayerDropdown(playerId, ordinal, canRemove)
	local dropdown = CAI_MakeLeaderDropdown(
		playerId,
		function() return Locale.Lookup("LOC_CAI_PLAYER") .. " " .. tostring(ordinal) end,
		"player:" .. tostring(playerId)
	)
	if canRemove then
		local pid = playerId
		dropdown:AddInputBindings({
			{
				Key = Keys.VK_DELETE,
				MSG = KeyEvents.KeyUp,
				Description = "LOC_CAI_KB_DELETE_PLAYER",
				Action = function()
					local playerConfig = PlayerConfigurations[pid]
					playerConfig:SetLeaderTypeName(nil)
					GameConfiguration.RemovePlayer(pid)
					GameSetup_PlayerCountChanged()
					return true
				end,
			},
		})
	end
	return dropdown
end

local function CAI_RebuildPlayers()
	if not CAI_PlayerSection then return end
	CAI_PlayerSection:ClearChildren()
	local playerIds = GameConfiguration.GetParticipatingPlayerIDs()
	local minimumPlayers = MapConfiguration.GetMinMajorPlayers() or 2
	local canRemove = #playerIds > minimumPlayers
	for ordinal, playerId in ipairs(playerIds) do
		CAI_PlayerSection:AddChild(CAI_BuildPlayerDropdown(
			playerId,
			ordinal,
			playerId ~= m_singlePlayerID and canRemove
		))
	end

	local addAI = mgr:CreateWidget(mgr:GenerateWidgetId("CAIScenarioAddAI"), "Button", {
		Label = function() return Locale.Lookup("LOC_CAI_ADVANCED_SETUP_ADD_AI") end,
		HiddenPredicate = function() return Controls.AddAIButton:IsHidden() end,
		FocusKey = "player:add",
	})
	addAI:SetFocusSound(HOVER_SOUND)
	addAI:On("activate", function() OnAddAIButton() end)
	CAI_PlayerSection:AddChild(addAI)
end

local function CAI_RebuildAdvancedParameters()
	if not CAI_AdvancedList then return end
	for _, section in pairs(CAI_Sections) do section:ClearChildren() end

	local parameters = {}
	if g_GameParameters and g_GameParameters.Parameters then
		for _, parameter in pairs(g_GameParameters.Parameters) do
			if kGroupToSection[parameter.GroupId] then table.insert(parameters, parameter) end
		end
	end
	table.sort(parameters, CAI_SortParameters)
	for _, parameter in ipairs(parameters) do
		local section = CAI_Sections[kGroupToSection[parameter.GroupId]]
		local widget = CAI_MakeParameterWidget(parameter, {
			focusKey = "advanced:param:" .. tostring(parameter.ParameterId),
			includeScenarioDescription = parameter.ParameterId == "Ruleset",
			preferLast = true,
		})
		if section and widget then section:AddChild(widget) end
	end
end

local function CAI_RebuildAll()
	if not CAI_Panel then return end
	local capture = mgr:CaptureFocusKey(CAI_Panel)
	CAI_RebuildBasicPage()
	CAI_RebuildPlayers()
	CAI_RebuildAdvancedParameters()
	mgr:RestoreFocus(CAI_Panel, capture)
end

local function CAI_GetStartTooltip()
	local tooltip = CAI_ControlTooltip(Controls.StartButton)
	local gameError = GetGameParametersError()
	tooltip = CAI_AppendExplanation(tooltip, CAI_GetLocalizedError(gameError))
	for ordinal, playerId in ipairs(GameConfiguration.GetParticipatingPlayerIDs()) do
		local playerError = GetPlayerParameterError(playerId)
		if playerError then
			local reason = CAI_GetLocalizedError(playerError)
			if reason ~= "" then
				tooltip = CAI_AppendExplanation(tooltip,
					Locale.Lookup("LOC_CAI_PLAYER") .. " " .. tostring(ordinal) .. ": " .. reason)
			end
		end
	end
	return tooltip
end

local function CAI_MakeActionButton(id, control, tooltipGetter)
	local button = mgr:CreateWidget(id, "Button", {
		Label = function() return control:GetText() or "" end,
		Tooltip = tooltipGetter or function() return CAI_ControlTooltip(control) end,
		HiddenPredicate = function() return control.IsHidden and control:IsHidden() end,
		DisabledPredicate = function() return control.IsDisabled and control:IsDisabled() end,
		FocusKey = id,
	})
	button:SetFocusSound(HOVER_SOUND)
	button:On("activate", function() control:DoLeftClick() end)
	return button
end

local function CAI_BuildPanel()
	CAI_Panel = mgr:CreateWidget("CAIScenarioSetup_Panel", "Panel", {
		Label = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Tabs = mgr:CreateWidget("CAIScenarioSetup_Tabs", "TabControl")

	CAI_BasicPage = CAI_Tabs:AddPage(function() return Controls.WindowTitle:GetText() end)
	CAI_BasicList = mgr:CreateWidget("CAIScenarioSetup_BasicList", "List")
	CAI_BasicPage:AddChild(CAI_BasicList)

	CAI_AdvancedPage = CAI_Tabs:AddPage(function() return Controls.AdvancedSetupButton:GetText() end)
	CAI_AdvancedList = mgr:CreateWidget("CAIScenarioSetup_AdvancedList", "List")
	CAI_AdvancedPage:AddChild(CAI_AdvancedList)

	CAI_PlayerSection = mgr:CreateWidget("CAIScenarioSetup_Players", "SubMenu", {
		Label = function() return Locale.Lookup("LOC_CAI_ADVANCED_SETUP_PLAYERS") end,
		FocusKey = "section:players",
	})
	CAI_PlayerSection:SetFocusSound(HOVER_SOUND)
	CAI_AdvancedList:AddChild(CAI_PlayerSection)

	local sectionDefinitions = {
		{ key = "Options", label = "LOC_OPTIONS" },
		{ key = "Victories", label = "LOC_SETUP_VICTORY_CONDITIONS" },
		{ key = "Advanced", label = "LOC_ADVANCED_OPTIONS" },
	}
	CAI_Sections = {}
	for _, definition in ipairs(sectionDefinitions) do
		local section = mgr:CreateWidget("CAIScenarioSetup_" .. definition.key, "SubMenu", {
			Label = function() return Locale.Lookup(definition.label) end,
			FocusKey = "section:" .. definition.key,
		})
		section:SetFocusSound(HOVER_SOUND)
		CAI_Sections[definition.key] = section
		CAI_AdvancedList:AddChild(section)
	end

	CAI_Tabs:On("value_changed", function(_, pageIndex)
		if pageIndex == 2 then
			Controls.CreateGameWindow:SetHide(true)
			Controls.AdvancedOptionsWindow:SetHide(false)
			m_AdvancedMode = true
		else
			Controls.CreateGameWindow:SetHide(false)
			Controls.AdvancedOptionsWindow:SetHide(true)
			UpdateCivLeaderToolTip()
			m_AdvancedMode = false
		end
	end)
	CAI_Panel:AddChild(CAI_Tabs)

	local actions = mgr:CreateWidget("CAIScenarioSetup_Actions", "Panel", {
		Transparent = true,
		WrapAround = false,
	})
	actions:AddChild(CAI_MakeActionButton("CAIScenarioSetup_Defaults", Controls.DefaultButton))
	actions:AddChild(CAI_MakeActionButton("CAIScenarioSetup_Start", Controls.StartButton, CAI_GetStartTooltip))
	CAI_Panel:AddChild(actions)

	CAI_RebuildBasicPage()
	CAI_RebuildPlayers()
	CAI_RebuildAdvancedParameters()
end

local function CAI_ClosePanel()
	if mgr and mgr:GetWidgetById("CAIScenarioSetup_Panel") then
		mgr:RemoveFromStack("CAIScenarioSetup_Panel")
	end
	CAI_Panel = nil
	CAI_Tabs = nil
	CAI_BasicPage = nil
	CAI_BasicList = nil
	CAI_AdvancedPage = nil
	CAI_AdvancedList = nil
	CAI_PlayerSection = nil
	CAI_Sections = {}
end

RefreshPlayerSlots = WrapFunc(RefreshPlayerSlots, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then CAI_RebuildAll() end
	return result
end)

GameParameters_UI_AfterRefresh = WrapFunc(GameParameters_UI_AfterRefresh, function(orig, ...)
	local result = orig(...)
	if CAI_Panel then CAI_RebuildAll() end
	return result
end)

OnAdvancedSetup = WrapFunc(OnAdvancedSetup, function(orig, ...)
	local result = orig(...)
	if CAI_Tabs and CAI_AdvancedPage then
		CAI_Tabs:SetActivePageById(CAI_AdvancedPage.Id, true)
	end
	return result
end)

OnBackButton = WrapFunc(OnBackButton, function(orig, ...)
	CAI_ClosePanel()
	if m_AdvancedMode then
		Controls.CreateGameWindow:SetHide(false)
		Controls.AdvancedOptionsWindow:SetHide(true)
		m_AdvancedMode = false
	end
	return orig(...)
end)

OnShow = WrapFunc(OnShow, function(orig, ...)
	CAI_ClosePanel()
	local result = orig(...)
	CAI_BuildPanel()
	mgr:Push(CAI_Panel, { priority = PopupPriority.Current })
	return result
end)

OnHide = WrapFunc(OnHide, function(orig, ...)
	CAI_ClosePanel()
	return orig(...)
end)

OnBeforeMultiplayerInviteProcessing = WrapFunc(OnBeforeMultiplayerInviteProcessing, function(orig, ...)
	CAI_ClosePanel()
	return orig(...)
end)
Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr and not ContextPtr:IsHidden() and mgr:HandleInput(input) then return true end
		if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
			OnBackButton()
			return true
		end
		return true
	end, true)
end)
--#End of accessibility integration
Initialize();
