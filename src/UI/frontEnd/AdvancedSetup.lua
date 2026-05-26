-- ===========================================================================
--	Single Player Create Game w/ Advanced Options
-- ===========================================================================
include("InstanceManager");
include("PlayerSetupLogic");
include("Civ6Common");
include("SupportFunctions");
include("PopupDialog");

-- ===========================================================================
-- ===========================================================================

local PULLDOWN_TRUNCATE_OFFSET:number = 40;

local MIN_SCREEN_Y			:number = 768;
local SCREEN_OFFSET_Y		:number = 61;
local MIN_SCREEN_OFFSET_Y	:number = -53;

local MAX_SIDEBAR_Y			:number = 960;

-- ===========================================================================
-- ===========================================================================

-- Instance managers for dynamic simple game options.
g_SimpleBooleanParameterManager = InstanceManager:new("SimpleBooleanParameterInstance", "CheckBox", Controls.CheckBoxParent);
g_SimpleGameModeParameterManager = InstanceManager:new("GameModeSelectorInstance", "Top", Controls.CheckBoxParent);
g_SimplePullDownParameterManager = InstanceManager:new("SimplePullDownParameterInstance", "Root", Controls.PullDownParent);
g_SimpleSliderParameterManager = InstanceManager:new("SimpleSliderParameterInstance", "Root", Controls.SliderParent);
g_SimpleStringParameterManager = InstanceManager:new("SimpleStringParameterInstance", "Root", Controls.EditBoxParent);

-- Instance managers for Game Mode placard and details flyouts
local m_gameModeToolTipHeaderIM = InstanceManager:new("HeaderInstance", "Top", Controls.GameModeInfoStack );
local m_gameModeToolTipHeaderIconIM = InstanceManager:new("IconInstance", "Top", Controls.GameModeInfoStack );

g_kMapData = {};	-- Global set of map data; enough for map selection context to do it's thing. (Parameter list still truly owns the data.)

local m_NonLocalPlayerSlotManager	:table = InstanceManager:new("NonLocalPlayerSlotInstance", "Root", Controls.NonLocalPlayersSlotStack);
local m_singlePlayerID				:number = 0;			-- The player ID of the human player in singleplayer.
local m_AdvancedMode				:boolean = false;
local m_RulesetData					:table = {};
local m_BasicTooltipData			:table = {};
local m_WorldBuilderImport          :boolean = false;

local m_pWarningPopup:table = PopupDialog:new("CityStateWarningPopup");

-- ===========================================================================
-- Override hiding game setup to release simplified instances.
-- ===========================================================================
GameSetup_HideGameSetup = HideGameSetup;
function HideGameSetup(func)
	GameSetup_HideGameSetup(func);
	g_SimpleBooleanParameterManager:ResetInstances();
	g_SimpleGameModeParameterManager:ResetInstances();
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

local _UI_AfterRefresh = GameParameters_UI_AfterRefresh;
function GameParameters_UI_AfterRefresh(o)
	
	if(_UI_AfterRefresh) then
		_UI_AfterRefresh(o);
	end
	
	-- All parameters are provided with a sort index and are manipulated
	-- in that particular order.
	-- However, destroying and re-creating parameters can get expensive
	-- and thus is avoided.  Because of this, some parameters may be 
	-- created in a bad order.  
	-- It is up to this function to ensure order is maintained as well
	-- as refresh/resize any containers.
	-- FYI: Because of the way we're sorting, we need to delete instances
	-- rather than release them.  This is because releasing merely hides it
	-- but it still gets thrown in for sorting, which is frustrating.
	local sort = function(a,b)
	
		-- ForgUI requires a strict weak ordering sort.
		local ap = g_SortingMap[tostring(a)];
		local bp = g_SortingMap[tostring(b)];

		if(ap == nil and bp ~= nil) then
			return true;
		elseif(ap == nil and bp == nil) then
			return tostring(a) < tostring(b);
		elseif(ap ~= nil and bp == nil) then
			return false;
		else
			return o.Utility_SortFunction(ap, bp);
		end
	end

	local stacks = {};
	table.insert(stacks, Controls.CreateGame_ExtraParametersStack);
	table.insert(stacks, Controls.CreateGame_GameModeParametersStack);

	for i,v in ipairs(stacks) do
		v:SortChildren(sort);
	end

	for i,v in ipairs(stacks) do
		v:CalculateSize();
		v:ReprocessAnchoring();
	end
	   
	Controls.CreateGameOptions:CalculateSize();
	Controls.CreateGameOptions:ReprocessAnchoring();

	if Controls.CreateGame_ParametersScrollPanel then
		Controls.CreateGame_ParametersScrollPanel:CalculateInternalSize();
	end

end

-- Override for SetupParameters to filter ruleset values by non-scenario only.
function GameParameters_FilterValues(o, parameter, values)
	values = o.Default_Parameter_FilterValues(o, parameter, values);
	if(parameter.ParameterId == "Ruleset") then
		local new_values = {};
		for i,v in ipairs(values) do
			local data = GetRulesetData(v.Value);
			if(not data.IsScenario) then
				table.insert(new_values, v);
			end
		end
		values = new_values;
	end

	return values;
end

function GetRulesetData(rulesetType)
	if not m_RulesetData[rulesetType] then
		local query:string = "SELECT Description, LongDescription, IsScenario, ScenarioSetupPortrait, ScenarioSetupPortraitBackground from Rulesets where RulesetType = ? LIMIT 1";
		local result:table = DB.ConfigurationQuery(query, rulesetType);
		if result and #result > 0 then
			m_RulesetData[rulesetType] = result[1];
		else
			m_RulesetData[rulesetType] = {};
		end
	end
	return m_RulesetData[rulesetType];
end

-- Cache frequently accessed data.
local _cachedMapDomain = nil;
local _cachedMapData = nil;
function GetMapData( domain:string, file:string )
	-- Refresh the cache if needed.
	if(_cachedMapData == nil or _cachedMapDomain ~= domain) then
		_cachedMapDomain = domain;
		_cachedMapData = {};
		local query = "SELECT File, Image, StaticMap from Maps where Domain = ?";
		local results = DB.ConfigurationQuery(query, domain);
		if(results) then		
			for i,v in ipairs(results) do
				_cachedMapData[v.File] = v;
			end
		end
	end 

	local mapInfo = _cachedMapData[file];
	if(mapInfo) then
		local isOfficial = mapInfo.IsOfficial;
		if(isOfficial == nil) then
			local modId,path = Modding.ParseModUri(mapInfo.File);
			isOfficial = (modId == nil) or Modding.IsModOfficial(modId);
			mapInfo.IsOfficial = isOfficial;
		end
		
		return mapInfo;
	else
		-- return nothing.
		return nil;
	end
end

-- ===========================================================================
--	Build a sub-set of SetupParameters that can be used to populate a
--	map selection screen.
--
--	To send maps:		LuaEvents.MapSelect_PopulatedMaps( g_kMapData );
--	To receive choice:	LuaEvents.MapSelect_SetMapByValue( value );
-- ===========================================================================
function BuildMapSelectData( kMapParameters:table )
	-- Sanity checks
	if kMapParameters == nil then 
		UI.DataError("Unable to build data for map selection; NIL kMapParameter passed in.);");
		return;
	end

	g_kMapData = {};	-- Clear out existing data.

	-- Loop through maps, create subset of data that is enough to show
	-- content in a map select context as well as match up with the
	-- selection.
	-- Note that "Value" in the table below may be one of the following:
	--	somename.lua									- A map script that is generated
	--	{GUID}somefile.Civ6Map							- World builder map prefixed with a GUID
	--	../..Assets/Maps/SomeFolder/myMap.Civ6Map		- World builder map in another folder
	--	{GUID}../..Assets/Maps/SomeFolder/myMap.Civ6Map	- World builder map in another folder
	local kMapCollection:table = kMapParameters.Values;
	for i,kMapData in ipairs( kMapCollection ) do
		local kExtraInfo :table = GetMapData(kMapData.Domain, kMapData.Value);

		local mapData = {
			RawName			= kMapData.RawName,
			RawDescription	= kMapData.RawDescription,
			SortIndex		= kMapData.SortIndex,
			QueryIndex		= kMapData.QueryIndex,
			Hash			= kMapData.Hash,
			Value			= kMapData.Value,
			Name			= kMapData.Name,
			Texture			= nil,
			IsWorldBuilder	= false,
			IsOfficial		= false,
		};

		if(kExtraInfo) then
			mapData.IsOfficial		= kExtraInfo.IsOfficial;
			mapData.Texture			= kExtraInfo.Image;
			mapData.IsWorldBuilder	= kExtraInfo.StaticMap;
		end
		table.insert(g_kMapData, mapData);
	end

	table.sort(g_kMapData, SortMapsByName);
end

-- ===========================================================================
function SortMapsByName(a, b)
	return Locale.Compare(a.Name, b.Name) == -1;
end

-- ===========================================================================
--	LuaEvent
--	Called from the MapSelect popup for what map was selected.
--	value	the map to set for the game.
-- ===========================================================================
function OnSetMapByValue( value: string )
	local kParameters	:table = g_GameParameters["Parameters"];
	local kMapParameters:table = kParameters["Map"];
	local kMapCollection:table = kMapParameters.Values;
	local isFound		:boolean = false;
	for i,kMapData in ipairs( kMapCollection ) do
		if kMapData.Value == value then
			g_GameParameters:SetParameterValue(kMapParameters, kMapData);
			Network.BroadcastGameConfig();			
			isFound = true;
			break;	
		end
	end
	if (not isFound) then
		UI.DataError("Unable to set the game's map to a map with the value '"..tostring(value).."'");
	end
end

function OnSetParameterValues(pid: string, values: table)
	local indexed_values = {};
	if(values) then
		for i,v in ipairs(values) do
			indexed_values[v] = true;
		end
	end

	if(g_GameParameters) then
		local kParameter: table = g_GameParameters.Parameters and g_GameParameters.Parameters[pid] or nil;
		if(kParameter and kParameter.Values ~= nil) then
			local resolved_values = {};
			for i,v in ipairs(kParameter.Values) do
				if(indexed_values[v.Value]) then
					table.insert(resolved_values, v);
				end
			end		
			g_GameParameters:SetParameterValue(kParameter, resolved_values);
			Network.BroadcastGameConfig();	
		end
	end	
end

-- ===========================================================================
function OnSetParameterValue(pid: string, value: number)
	if(g_GameParameters) then
		local kParameter: table = g_GameParameters.Parameters and g_GameParameters.Parameters[pid] or nil;
		if(kParameter and kParameter.Value ~= nil) then	
            g_GameParameters:SetParameterValue(kParameter, value);
			Network.BroadcastGameConfig();	
		end
	end	
end

-- ===========================================================================
function CreatePulldownDriver(o, parameter, c, container)

	local cache = {};
	local driver = {
		Control = c,
		Container = container,
		UpdateValue = function(value)
			local valueText = value and value.Name or nil;
			local button = c:GetButton();
			if(cache.ValueText ~= valueText or cache.ValueDescription ~= valueDescription) then
				local truncateWidth = button:GetSizeX() - PULLDOWN_TRUNCATE_OFFSET;
				TruncateStringWithTooltip(button, truncateWidth, valueText);
				cache.ValueText = valueText;
			end		
			button:LocalizeAndSetToolTip(value.RawDescription);
		end,
		UpdateValues = function(values)
			-- If container was included, hide it if there is only 1 possible value.
			if(#values == 1 and container ~= nil) then
				container:SetHide(true);
			else
				if(container) then
					container:SetHide(false);
				end

				local refresh = false;
				local cValues = cache.Values;
				if(cValues and #cValues == #values) then
					for i,v in ipairs(values) do
						local cv = cValues[i];
						if(cv == nil) then
							refresh = true;
							break;
						elseif(cv.QueryId ~= v.QueryId or cv.QueryIndex ~= v.QueryIndex or cv.Invalid ~= v.Invalid or cv.InvalidReason ~= v.InvalidReason) then
							refresh = true;
							break;
						end
					end
				else
					refresh = true;
				end

				if(refresh) then
					c:ClearEntries();
					for i,v in ipairs(values) do
						local entry = {};
						c:BuildEntry( "InstanceOne", entry );
						entry.Button:SetText(v.Name);
						if v.RawDescription then
							entry.Button:SetToolTipString(Locale.Lookup(v.RawDescription));
						else
							entry.Button:SetToolTipString(v.Description);
						end

						entry.Button:RegisterCallback(Mouse.eLClick, function()
							o:SetParameterValue(parameter, v);
							Network.BroadcastGameConfig();
						end);
					end
					c:CalculateInternals();
					cache.Values = values;
				end
			end			
		end,
		SetEnabled = function(enabled, parameter)
			c:SetDisabled(not enabled or #parameter.Values <= 1);
		end,
		SetVisible = function(visible, parameter)
			container:SetHide(not visible or parameter.Value == nil);
		end,	
		Destroy = nil,		-- It's a fixed control, no need to delete.
	};
	
	return driver;	
end

-- ===========================================================================
--	Driver for the simple menu's "Map Select"
-- ===========================================================================
function CreateSimpleMapPopupDriver(o, parameter )
	local uiMapPopupButton:object = Controls.MapSelectButton;
	local kDriver :table = {
		UpdateValues = function(o, parameter) 
			BuildMapSelectData(parameter);
		end,
		UpdateValue = function( kValue:table )
			local valueText			:string = kValue and kValue.Name or nil;
			local valueDescription	:string = kValue and kValue.Description or nil
			uiMapPopupButton:SetText( valueText );
			uiMapPopupButton:SetToolTipString( valueDescription );
		end
	}
	return kDriver;
end

-- ===========================================================================
--	Used to launch popups
--	o				main object of all the parameters
--	parameter		the parameter being changed
--	activateFunc	The function to be called when the button is pressed
--	parent			(optional) The parent control to connect to
--
--	RETURNS:		A 'driver' that represents a UI control and various common
--					functions that manipulate the control in a setup screen.
-- ===========================================================================
function CreateButtonPopupDriver(o, parameter, activateFunc, parent )

	-- Sanity check
	if(activateFunc == nil) then
		UI.DataError("Ignoring creating popup button because no callback function was passed in. Parameters: name="..parameter.Name..", groupID="..tostring(parameter.GroupId));
		return {}
	end

	-- Apply defaults
	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value)
			local valueText = value and value.Name or nil;
			local valueDescription = value and value.Description or nil
			if(cache.ValueText ~= valueText or cache.ValueDescription ~= valueDescription) then
				local button = c.Button;
				button:RegisterCallback( Mouse.eLClick, activateFunc );					
				button:SetText(valueText);
				button:SetToolTipString(valueDescription);
				cache.ValueText = valueText;
				cache.ValueDescription = valueDescription;
			end
		end,
		UpdateValues = function(values, p) 
			BuildMapSelectData(p);
		end,
		SetEnabled = function(enabled, parameter)
			c.Button:SetDisabled(not enabled or #parameter.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- This driver is for launching a multi-select option in a separate window.
-- ===========================================================================
function CreateMultiSelectWindowDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId = parameter.ParameterId;
	local button = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.MultiSelectWindow_Initialize(o.Parameters[parameterId]);
		Controls.MultiSelectWindow:SetHide(false);
	end);
	button:SetToolTipString(parameter.Description);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- This driver is for launching the city-state picker in a separate window.
-- ===========================================================================
function CreateCityStatePickerDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId = parameter.ParameterId;
	local button = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.CityStatePicker_Initialize(o.Parameters[parameterId], g_GameParameters);
		Controls.CityStatePicker:SetHide(false);
	end);
	button:SetToolTipString(parameter.Description);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- This driver is for launching the leader picker in a separate window.
-- ===========================================================================
function CreateLeaderPickerDriver(o, parameter, parent)

	if(parent == nil) then
		parent = GetControlStack(parameter.GroupId);
	end
			
	-- Get the UI instance
	local c :object = g_ButtonParameterManager:GetInstance();	

	local parameterId = parameter.ParameterId;
	local button = c.Button;
	button:RegisterCallback( Mouse.eLClick, function()
		LuaEvents.LeaderPicker_Initialize(o.Parameters[parameterId], g_GameParameters);
		Controls.LeaderPicker:SetHide(false);
	end);
	button:SetToolTipString(parameter.Description);

	-- Store the root control, NOT the instance table.
	g_SortingMap[tostring(c.ButtonRoot)] = parameter;

	c.ButtonRoot:ChangeParent(parent);
	if c.StringName ~= nil then
		c.StringName:SetText(parameter.Name);
	end

	local cache = {};

	local kDriver :table = {
		Control = c,
		Cache = cache,
		UpdateValue = function(value, p)
			local valueText = value and value.Name or nil;
			local valueAmount :number = 0;

			-- Remove random leaders from the Values table that is used to determine number of leaders selected
			for i = #p.Values, 1, -1 do
				local kItem:table = p.Values[i];
				if kItem.Value == "RANDOM" or kItem.Value == "RANDOM_POOL1" or kItem.Value == "RANDOM_POOL2" then
					table.remove(p.Values, i);
				end
			end
		
			if(valueText == nil) then
				if(value == nil) then
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						valueText = "LOC_SELECTION_EVERYTHING";
					else
						valueText = "LOC_SELECTION_NOTHING";
					end
				elseif(type(value) == "table") then
					local count = #value;
					if (parameter.UxHint ~= nil and parameter.UxHint == "InvertSelection") then
						if(count == 0) then
							valueText = "LOC_SELECTION_EVERYTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_NOTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = #p.Values - count;
						end
					else
						if(count == 0) then
							valueText = "LOC_SELECTION_NOTHING";
						elseif(count == #p.Values) then
							valueText = "LOC_SELECTION_EVERYTHING";
						else
							valueText = "LOC_SELECTION_CUSTOM";
							valueAmount = count;
						end
					end
				end
			end				

			if(cache.ValueText ~= valueText) or (cache.ValueAmount ~= valueAmount) then
				local button = c.Button;			
				button:LocalizeAndSetText(valueText, valueAmount);
				cache.ValueText = valueText;
				cache.ValueAmount = valueAmount;
			end
		end,
		UpdateValues = function(values, p) 
			-- Values are refreshed when the window is open.
		end,
		SetEnabled = function(enabled, p)
			c.Button:SetDisabled(not enabled or #p.Values <= 1);
		end,
		SetVisible = function(visible)
			c.ButtonRoot:SetHide(not visible);
		end,
		Destroy = function()
			g_ButtonParameterManager:ReleaseInstance(c);
		end,
	};	

	return kDriver;
end

-- ===========================================================================
-- Override parameter behavior for basic setup screen.
g_ParameterFactories["Ruleset"] = function(o, parameter)
	
	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_GameRuleset, Controls.CreateGame_RulesetContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_CreateParameterDriver(o, parameter));

	return drivers;
end
g_ParameterFactories["GameDifficulty"] = function(o, parameter)

	local drivers = {};
	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_GameDifficulty, Controls.CreateGame_GameDifficultyContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_CreateParameterDriver(o, parameter));

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
	table.insert(drivers, GameParameters_UI_CreateParameterDriver(o, parameter));

	return drivers;
end

-- ===========================================================================
g_ParameterFactories["Map"] = function(o, parameter)

	local drivers = {};

    if (m_WorldBuilderImport) then
        return drivers;
    end

	-- Basic setup version.
	table.insert(drivers, CreateSimpleMapPopupDriver(o, parameter) );
	
	-- Advanced setup version.	
	table.insert( drivers, CreateButtonPopupDriver(o, parameter, OnMapSelect) );

	return drivers;
end

-- ===========================================================================
g_ParameterFactories["MapSize"] = function(o, parameter)

	local drivers = {};

    if (m_WorldBuilderImport) then
        return drivers;
    end

	-- Basic setup version.
	-- Use an explicit table.
	table.insert(drivers, CreatePulldownDriver(o, parameter, Controls.CreateGame_MapSize, Controls.CreateGame_MapSizeContainer));

	-- Advanced setup version.
	-- Create the parameter dynamically like we normally would...
	table.insert(drivers, GameParameters_UI_CreateParameterDriver(o, parameter));

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

	if(parameter.GroupId == "GameModes") then
		local c = g_SimpleGameModeParameterManager:GetInstance();	
		
		-- Store the root control, NOT the instance table.
		g_SortingMap[tostring(c.Top)] = parameter;		
		
		local name = Locale.ToUpper(parameter.Name);
		c.CheckBox:RegisterCallback(Mouse.eLClick, function()
			o:SetParameterValue(parameter, not c.CheckBox:IsSelected());
			Network.BroadcastGameConfig();
		end);	
		c.GameModeIcon:SetIcon("ICON_" .. parameter.ParameterId);
		c.Top:ChangeParent(parent);

		control = {
			UpdateValue = function(value, parameter)
				c.CheckBox:SetSelected(value);
			end,
			Control = c,
			SetEnabled = function(enabled)
				c.CheckBox:SetDisabled(not enabled);
			end,
			SetVisible = function(visible)
				c.CheckBox:SetHide(not visible);
			end,
			Destroy = function()
				g_SimpleGameModeParameterManager:ReleaseInstance(c);
			end,
		};
		c.CheckBox:RegisterCallback( Mouse.eMouseEnter, function() OnGameModeMouseEnter(parameter) end);
		c.CheckBox:RegisterCallback( Mouse.eMouseExit, function() OnGameModeMouseExit(parameter) end);

		if(Controls.NoGameModesContainer:IsHidden() == false)then
			Controls.NoGameModesContainer:SetHide(true);
		end

	elseif(parameter.Domain == "bool") then
		local c = g_SimpleBooleanParameterManager:GetInstance();	
		
		-- Store the root control, NOT the instance table.
		g_SortingMap[tostring(c.CheckBox)] = parameter;		
		
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

		-- Store the root control, NOT the instance table.
		g_SortingMap[tostring(c.Root)] = parameter;
		
		local name = Locale.ToUpper(parameter.Name);	
		c.StringName:SetText(name);
		c.Root:SetToolTipString(parameter.Description);
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

		c.Root:ChangeParent(parent);

		control = {
			Control = c,
			UpdateValue = function(value)
				c.StringEdit:SetText(Locale.Lookup(value));
			end,
			SetEnabled = function(enabled)
				if canChangeEnableState then
					c.Root:SetDisabled(not enabled);
					c.StringEdit:SetDisabled(not enabled);
				end
			end,
			SetVisible = function(visible)
				c.Root:SetHide(not visible);
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
		
		-- Store the root control, NOT the instance table.
		g_SortingMap[tostring(c.Root)] = parameter;
		
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
		
		-- Store the root control, NOT the instance table.
		g_SortingMap[tostring(c.Root)] = parameter;

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
			SetVisible = function(visible)
				c.Root:SetHide(not visible);
			end,
			Destroy = function()
				g_SimplePullDownParameterManager:ReleaseInstance(c);
			end,
		};	
	end

	return control;
end

function GameParameters_UI_CreateParameterDriver(o, parameter, ...)

	if(parameter.ParameterId == "CityStates") then
		if GameConfiguration.IsWorldBuilderEditor() then
			return nil;
		end
		return CreateCityStatePickerDriver(o, parameter);
	elseif(parameter.ParameterId == "LeaderPool1" or parameter.ParameterId == "LeaderPool2") then
		if GameConfiguration.IsWorldBuilderEditor() then
			return nil;
		end
		return CreateLeaderPickerDriver(o, parameter);
	elseif(parameter.Array) then
		return CreateMultiSelectWindowDriver(o, parameter);
	else
		return GameParameters_UI_DefaultCreateParameterDriver(o, parameter, ...);
	end
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
			GameParameters_UI_CreateParameterDriver(o, parameter)
		};
	elseif(parameter.GroupId == "GameModes") then	
		control = {
			CreateSimpleParameterDriver(o, parameter, Controls.CreateGame_GameModeParametersStack),
			GameParameters_UI_CreateParameterDriver(o, parameter)
		};	
	else
		control = GameParameters_UI_CreateParameterDriver(o, parameter);
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
	
	local basicTooltip = {};
	ContextPtr:BuildInstanceForControl( "CivToolTip", basicTooltip, Controls.BasicTooltipContainer );
	local basicPlacard	:table = {};
	ContextPtr:BuildInstanceForControl( "LeaderPlacard", basicPlacard, Controls.BasicPlacardContainer );

	m_BasicTooltipData = {
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
			SetupLeaderPulldown(player_id, Controls, "Basic_LocalPlayerPulldown", "Basic_LocalPlayerCivIcon",  "Basic_LocalPlayerCivIconBG", "Basic_LocalPlayerLeaderIcon", "Basic_LocalPlayerScrollText", m_BasicTooltipData);
			SetupLeaderPulldown(player_id, Controls, "Advanced_LocalPlayerPulldown", "Advanced_LocalPlayerCivIcon", "Advanced_LocalPlayerCivIconBG", "Advanced_LocalPlayerLeaderIcon", "Advanced_LocalPlayerScrollText", advancedTooltipData, "Advanced_LocalColorPullDown");
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
			Controls.ConflictPopup:SetHide(false);
		end
	end

	-- TTP[20948]: Display leader placard for the currently selected leader
	local playerConfig = PlayerConfigurations[m_singlePlayerID];
	if(playerConfig and m_BasicTooltipData) then
		local selectedLeader = playerConfig:GetLeaderTypeID();
		if(selectedLeader ~= -1) then
			local leaderType = playerConfig:GetLeaderTypeName();
			local info = GetPlayerInfo(playerConfig:GetValue("LEADER_DOMAIN"), leaderType);
			DisplayCivLeaderToolTip(info, m_BasicTooltipData, false);
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

	 m_WorldBuilderImport = false;
	local bWorldBuilder = GameConfiguration.IsWorldBuilderEditor();

	if (bWorldBuilder) then
		Controls.WindowTitle:LocalizeAndSetText("{LOC_SETUP_CREATE_MAP:upper}");

        if (MapConfiguration.GetScript() == "WBImport.lua") then
            m_WorldBuilderImport = true;
        end

		-- KLUDGE: Ideally setup parameters in a group should have some sort of control mechanism for whether or not the group should show.
		Controls.CreateGame_LocalPlayerContainer:SetHide(true);
		Controls.PlayersSection:SetHide(true);
		Controls.VictoryParametersHeader:SetHide(true);
		
    else
		Controls.CreateGame_LocalPlayerContainer:SetHide(false);
		Controls.PlayersSection:SetHide(false);
		Controls.VictoryParametersHeader:SetHide(false);
		
		Controls.WindowTitle:LocalizeAndSetText("{LOC_SETUP_CREATE_GAME:upper}");
	end

	RefreshPlayerSlots();	-- Will trigger a game parameter refresh.
	AutoSizeGridButton(Controls.DefaultButton,133,36,15,"H");
	AutoSizeGridButton(Controls.CloseButton,133,36,10,"H");
	-- the map size and type dropdowns don't make sense on a map import

    if (m_WorldBuilderImport) then
        Controls.CreateGame_MapType:SetDisabled(true);
        Controls.CreateGame_MapSize:SetDisabled(true);
        Controls.StartButton:LocalizeAndSetText("LOC_LOAD_TILED");
		MapConfiguration.SetScript("WBImport.lua");
    elseif(bWorldBuilder) then
		Controls.CreateGame_MapType:SetDisabled(false);
        Controls.CreateGame_MapSize:SetDisabled(false);
        Controls.StartButton:LocalizeAndSetText("LOC_SETUP_WORLDBUILDER_START");
	else
        Controls.CreateGame_MapType:SetDisabled(false);
        Controls.CreateGame_MapSize:SetDisabled(false);
        Controls.StartButton:LocalizeAndSetText("LOC_START_GAME");
    end
end

-- ===========================================================================
function OnHide()
	HideGameSetup();
	ReleasePlayerParameters();
	m_RulesetData = {};
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
	local bWorldBuilder = GameConfiguration.IsWorldBuilderEditor();

	Controls.CreateGameWindow:SetHide(true);
	Controls.AdvancedOptionsWindow:SetHide(false);
	Controls.LoadConfig:SetHide(bWorldBuilder);
	Controls.SaveConfig:SetHide(bWorldBuilder);
	Controls.ButtonStack:CalculateSize();

	m_AdvancedMode = true;
end

-- ===========================================================================
function OnMapSelect()
	LuaEvents.MapSelect_PopulatedMaps( g_kMapData );
	Controls.MapSelectWindow:SetHide(false);
end

-- ===========================================================================
function OnDefaultButton()
	print("Reseting Setup Parameters");

	local bWorldBuilder = GameConfiguration.IsWorldBuilderEditor();
	GameConfiguration.SetToDefaults();
	GameConfiguration.SetWorldBuilderEditor(bWorldBuilder);
	
	-- In World Builder we want to default to Standard Rules.
	if(not bWorldBuilder) then
		-- Kludge:  SetToDefaults assigns the ruleset to be standard.
		-- Clear this value so that the setup parameters code can guess the best 
		-- default.
		GameConfiguration.SetValue("RULESET", nil);
	end

	GameConfiguration.RegenerateSeeds();
	return GameSetup_PlayerCountChanged();
end

-- ===========================================================================
function OnStartButton()
	-- Is WorldBuilder active?
	if (GameConfiguration.IsWorldBuilderEditor()) then
        if (m_WorldBuilderImport) then
            MapConfiguration.SetScript("WBImport.lua");
			local loadGameMenu = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/LoadGameMenu" );
			UIManager:QueuePopup(loadGameMenu, PopupPriority.Current);	
		else
			UI.SetWorldRenderView( WorldRenderView.VIEW_2D );
			UI.PlaySound("Set_View_2D");
			Events.SetGameEntryMethod("Create A Game - WorldBuilder");
			Network.HostGame(ServerType.SERVER_TYPE_NONE);
		end
    else
        local showCityStatesWarning:boolean = ShouldShowCityStatesWarning();
        local showLeaderPoolWarning:boolean = ShouldShowLeaderPoolWarning();
		if showCityStatesWarning then
			ShowCityStateWarning(showLeaderPoolWarning);
        elseif showLeaderPoolWarning then
            ShowLeaderPoolWarning();
        else
            HostGame();
		end
	end
end

-- ===========================================================================
function ShowCityStateWarning(showLeaderPoolWarningNext:boolean)
    if showLeaderPoolWarningNext then
        m_pWarningPopup:ShowOkCancelDialog(Locale.Lookup("LOC_CITY_STATE_PICKER_TOO_FEW_WARNING"), ShowLeaderPoolWarning);
    else
        m_pWarningPopup:ShowOkCancelDialog(Locale.Lookup("LOC_CITY_STATE_PICKER_TOO_FEW_WARNING"), HostGame);
    end
end

-- ===========================================================================
function ShowLeaderPoolWarning()
    m_pWarningPopup:ShowOkCancelDialog(Locale.Lookup("LOC_LEADER_POOL_TOO_FEW_WARNING"), HostGame);
end

-- ===========================================================================
function HostGame()
	Events.SetGameEntryMethod("Create a Game");
	-- Start a normal game
	UI.PlaySound("Set_View_3D");
	Network.HostGame(ServerType.SERVER_TYPE_NONE);
end

-- ===========================================================================
function ShouldShowCityStatesWarning()
	local kParameters:table = g_GameParameters["Parameters"];

    -- No City-States for this game so don't worry about it
	if kParameters["CityStates"] == nil then
		return false;
	end

	local cityStateSlots:number = kParameters["CityStateCount"].Value;
	local totalCityStates:number = #kParameters["CityStates"].AllValues;
	local excludedCityStates:number = kParameters["CityStates"].Value ~= nil and #kParameters["CityStates"].Value or 0;

    -- Too few city-states selected in the city-state picker
	if (totalCityStates - excludedCityStates) < cityStateSlots then
		return true;
	end

	return false;
end

-- ===========================================================================
function ShouldShowLeaderPoolWarning()
    -- Determine how many players are trying to use leader pool 1 and 2
    local numPool1Players:number = 0;
    local numPool2Players:number = 0
    local player_ids = GameConfiguration.GetParticipatingPlayerIDs();
    for i, player_id in ipairs(player_ids) do	
	    local playerConfig = PlayerConfigurations[player_id];
	    if(playerConfig) then
            local pool_id:number = playerConfig:GetLeaderRandomPoolID();
			if pool_id == LeaderRandomPoolTypes.LEADER_RANDOM_POOL_1 then
				numPool1Players = numPool1Players + 1;
			elseif pool_id == LeaderRandomPoolTypes.LEADER_RANDOM_POOL_2 then
				numPool2Players = numPool2Players + 1;
	        end
        end
    end

    local kParameters:table = g_GameParameters["Parameters"];

    -- Check if leader pool 1 has enough leaders for all the players who selected it
    if numPool1Players > 0 then
        local kPool1Param:table = kParameters["LeaderPool1"];
        if kPool1Param then
            if kPool1Param.Value ~= nil then
                local numLeadersInPool:number = #kPool1Param.AllValues - #kPool1Param.Value;
                if numLeadersInPool ~= 0 and numPool1Players > numLeadersInPool then
                    return true;
                end
            end
        end
    end

    -- Check if leader pool 2 has enough leaders for all the players who selected it
    if numPool2Players > 0 then
        local kPool2Param:table = kParameters["LeaderPool2"];
        if kPool2Param then
            if kPool2Param.Value ~= nil then
                local numLeadersInPool:number = #kPool2Param.AllValues - #kPool2Param.Value;
                if numLeadersInPool ~= 0 and numPool2Players > numLeadersInPool then
                    return true;
                end
            end
        end
    end

    return false;
end

----------------------------------------------------------------    
function OnBackButton()
	if(m_AdvancedMode) then
		Controls.CreateGameWindow:SetHide(false);
		Controls.AdvancedOptionsWindow:SetHide(true);
		Controls.LoadConfig:SetHide(true);
		Controls.SaveConfig:SetHide(true);
		Controls.ButtonStack:CalculateSize();
		
		UpdateCivLeaderToolTip();					-- Need to make sure we update our placard/flyout card if we make a change in advanced setup and then come back
		m_AdvancedMode = false;		
	else
		LuaEvents.MapSelect_ClearMapData();
		UIManager:DequeuePopup( MapSelectWindow );
		UIManager:DequeuePopup( ContextPtr );
		Controls.NoGameModesContainer:SetHide(false);
	end
end

-- ===========================================================================
--	Realize the animated flyouts with description, icons, and portraits for 
--  the currently hovered game mode toggle.
-- ===========================================================================
function OnGameModeMouseEnter(kGameModeData : table)
	m_gameModeToolTipHeaderIM:ResetInstances();
	m_gameModeToolTipHeaderIconIM:ResetInstances();
	if(Controls.GameModeToolTipSlide:IsReversing())then
		Controls.GameModeSlide:Reverse();
		Controls.GameModeAlpha:Reverse();
		Controls.GameModeToolTipSlide:Reverse();
		Controls.GameModeToolTipAlpha:Reverse();
	else
		Controls.GameModeSlide:Play();
		Controls.GameModeAlpha:Play();
		Controls.GameModeToolTipSlide:Play();
		Controls.GameModeToolTipAlpha:Play();
	end
	local gameModeHeader : table = m_gameModeToolTipHeaderIM:GetInstance();
	gameModeHeader.Header:SetText(Locale.Lookup(kGameModeData.RawName));

	local gameModeDescription : table = m_gameModeToolTipHeaderIconIM:GetInstance();
	gameModeDescription.Description:SetText(kGameModeData.Description);
	gameModeDescription.Header:SetHide(true);

	local gameModeInfo : table = GetGameModeInfo(kGameModeData.ConfigurationId);
	if(gameModeInfo ~= nil)then
		gameModeDescription.Icon:SetIcon(gameModeInfo.Icon);

		if(gameModeInfo.UnitIcon)then
			local gameModeUnitDescription : table = m_gameModeToolTipHeaderIconIM:GetInstance();
			gameModeUnitDescription.Description:SetText(Locale.Lookup(gameModeInfo.UnitDescription));
			gameModeUnitDescription.Icon:SetIcon(gameModeInfo.UnitIcon);
			gameModeUnitDescription.Header:SetText(Locale.ToUpper(gameModeInfo.UnitName));
		end
		if(gameModeInfo.Portrait)then
			Controls.GameModeImage:SetTexture(gameModeInfo.Portrait);
		end
		if(gameModeInfo.Background)then
			Controls.GameModeBG:SetTexture(gameModeInfo.Background);
		end
	end
end

function OnGameModeMouseExit(kGameModeData : table)
	if(not Controls.GameModeToolTipSlide:IsReversing())then
		Controls.GameModeSlide:Reverse();
		Controls.GameModeAlpha:Reverse();
		Controls.GameModeToolTipSlide:Reverse();
		Controls.GameModeToolTipAlpha:Reverse();
	else
		Controls.GameModeSlide:Play();
		Controls.GameModeAlpha:Play();
		Controls.GameModeToolTipSlide:Play();
		Controls.GameModeToolTipAlpha:Play();
	end
end

-- ===========================================================================
function OnLoadConfig()

	local loadGameMenu = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/LoadGameMenu" );
	local kParameters = {
		FileType = SaveFileTypes.GAME_CONFIGURATION
	};

	UIManager:QueuePopup(loadGameMenu, PopupPriority.Current, kParameters);
end

-- ===========================================================================
function OnSaveConfig()

	local saveGameMenu = ContextPtr:LookUpControl( "/FrontEnd/MainMenu/SaveGameMenu" );
	local kParameters = {
		FileType = SaveFileTypes.GAME_CONFIGURATION
	};
    
	UIManager:QueuePopup(saveGameMenu, PopupPriority.Current, kParameters);	
end

----------------------------------------------------------------    
-- ===========================================================================
--	Handle Window Sizing
-- ===========================================================================

function Resize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal();
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2)) then
		Controls.MainWindow:SetSizeY(screenY - (Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		Controls.CreateGameWindow:SetSizeY(SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY() - (Controls.ButtonStack:GetSizeY() + Controls.LogoContainer:GetSizeY()));
		Controls.AdvancedOptionsWindow:SetSizeY(SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY() - (Controls.ButtonStack:GetSizeY() + Controls.LogoContainer:GetSizeY()));
	else
		Controls.MainWindow:SetSizeY(screenY);
		Controls.CreateGameWindow:SetSizeY(MIN_SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY() - (Controls.ButtonStack:GetSizeY()));
		Controls.AdvancedOptionsWindow:SetSizeY(MIN_SCREEN_OFFSET_Y + Controls.MainWindow:GetSizeY() - (Controls.ButtonStack:GetSizeY()));
	end

	local iSidebarSize = Controls.CreateGameWindow:GetSizeY();
	if iSidebarSize > MAX_SIDEBAR_Y then
		iSidebarSize = MAX_SIDEBAR_Y;
	end
	Controls.BasicPlacardContainer:SetSizeY(iSidebarSize);
	Controls.BasicTooltipContainer:SetSizeY(iSidebarSize);
	Controls.GameModePlacardContainer:SetSizeY(iSidebarSize);
	Controls.GameModeTooltipContainer:SetSizeY(iSidebarSize);
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
    Resize();
  end
end

-- ===========================================================================
function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidentally break the invite!
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
function OnShutdown()
	Events.FinishedGameplayContentConfigure.Remove(OnFinishedGameplayContentConfigure);
	Events.SystemUpdateUI.Remove( OnUpdateUI );
	Events.BeforeMultiplayerInviteProcessing.Remove( OnBeforeMultiplayerInviteProcessing );

	LuaEvents.MapSelect_SetMapByValue.Remove( OnSetMapByValue );
	LuaEvents.MultiSelectWindow_SetParameterValues.Remove(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValues.Remove(OnSetParameterValues);
    LuaEvents.CityStatePicker_SetParameterValue.Remove(OnSetParameterValue);
	LuaEvents.LeaderPicker_SetParameterValues.Remove(OnSetParameterValues);
end

-- ===========================================================================
--
-- ===========================================================================
function Initialize()

	ContextPtr:SetShutdown( OnShutdown );
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
	Controls.LoadConfig:RegisterCallback( Mouse.eLClick, OnLoadConfig );
	Controls.LoadConfig:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.SaveConfig:RegisterCallback( Mouse.eLClick, OnSaveConfig );
	Controls.SaveConfig:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.MapSelectButton:RegisterCallback( Mouse.eLClick, OnMapSelect );
	Controls.MapSelectButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.ConflictConfirmButton:RegisterCallback( Mouse.eLClick, function() Controls.ConflictPopup:SetHide(true); end);
	Controls.ConflictConfirmButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	
	Events.FinishedGameplayContentConfigure.Add(OnFinishedGameplayContentConfigure);
	Events.SystemUpdateUI.Add( OnUpdateUI );
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );

	LuaEvents.MapSelect_SetMapByValue.Add( OnSetMapByValue );
	LuaEvents.MultiSelectWindow_SetParameterValues.Add(OnSetParameterValues);
	LuaEvents.CityStatePicker_SetParameterValues.Add(OnSetParameterValues);
    LuaEvents.CityStatePicker_SetParameterValue.Add(OnSetParameterValue);
	LuaEvents.LeaderPicker_SetParameterValues.Add(OnSetParameterValues);

	Resize();
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_Panel = nil ---@type UIWidget
local CAI_SettingsList = nil ---@type UIWidget
local CAI_TabBar = nil ---@type UIWidget
local m_simpleParamWidgets = {} -- parameterId → UIWidget
local m_intentionalClose = false
local m_activeTab = "basic" -- "basic" or "advanced"

-- Advanced view state
local m_basicChildren = {}        -- snapshot of basic view children
local m_advancedSections = {}     -- GroupId → List widget
local m_advancedParamWidgets = {} -- parameterId → widget
local m_advancedPlayersSection = nil ---@type UIWidget
local m_aiPlayerWidgets = {}      -- ordered array of {playerId, submenu}
local SwitchToTab                 -- forward declaration (defined after BuildPanel)
local RemoveAdvancedSections      -- forward declaration

-- ---------------------------------------------------------------------------
-- Static pulldown spec: { parameterId, pulldownCtrl, containerCtrl }
-- Leader pulldown handled separately (uses scroll text, not button text).
-- ---------------------------------------------------------------------------
local kStaticPulldowns = {
	{ "Ruleset",        function() return Controls.CreateGame_GameRuleset end,     function() return Controls.CreateGame_RulesetContainer end,         "LOC_SETUP_CHOOSE_RULESET" },
	{ "GameDifficulty", function() return Controls.CreateGame_GameDifficulty end,  function() return Controls.CreateGame_GameDifficultyContainer end,  "LOC_SETUP_DIFFICULTY" },
	{ "GameSpeeds",     function() return Controls.CreateGame_SpeedPulldown end,   function() return Controls.CreateGame_SpeedPulldownContainer end,   "LOC_SETUP_SPEED" },
	{ "MapSize",        function() return Controls.CreateGame_MapSize end,         function() return Controls.CreateGame_MapSizeContainer end,         "LOC_SETUP_MAP_SIZE" },
}

-- ---------------------------------------------------------------------------
-- Helper: build an accessible option list for a game-parameter pulldown.
-- Reads parameter.Values from g_GameParameters at the time the user opens it.
-- ---------------------------------------------------------------------------
local function OpenParamDropdown(parameterId)
	local param = g_GameParameters and g_GameParameters.Parameters
		and g_GameParameters.Parameters[parameterId]
	if not param or not param.Values then return end

	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v
		local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupMenuItem"), "MenuItem", {
			Label = function() return val.Name end,
			Tooltip = function() return val.Description or "" end,
		})
		child:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		child:On("activate", function()
			g_GameParameters:SetParameterValue(param, val)
			Network.BroadcastGameConfig()
			mgr:RemoveFromStack(optList:GetId())
		end)
		optList:AddChild(child)
		if not selectedChild and currentVal and val.QueryId == currentVal.QueryId
				and val.QueryIndex == currentVal.QueryIndex then
			selectedChild = child
		end
	end
	mgr:Push(optList, { focus = selectedChild })
end

-- ---------------------------------------------------------------------------
-- Helper: build numbered info sections from a leader's GetPlayerInfo data.
-- Returns an array of {label, text} pairs and corresponding number key bindings.
-- ---------------------------------------------------------------------------
local kNumberKeys = {
	Keys["1"], Keys["2"], Keys["3"], Keys["4"], Keys["5"],
	Keys["6"], Keys["7"], Keys["8"], Keys["9"], Keys["0"],
}

local function BuildLeaderInfoSections(domain, leaderType)
	local sections = {}
	if not domain or not leaderType then return sections end
	if leaderType == "RANDOM" or leaderType == "RANDOM_POOL1" or leaderType == "RANDOM_POOL2" then
		return sections
	end

	local info = GetPlayerInfo(domain, leaderType)
	if not info then return sections end

	-- 1: Leader + Civilization name
	local names = Locale.Lookup(info.LeaderName or "")
	if info.CivilizationName then
		names = names .. ", " .. Locale.Lookup(info.CivilizationName)
	end
	table.insert(sections, { label = Locale.Lookup(info.LeaderName or ""), text = names })

	-- 2: Civilization Ability
	if info.CivilizationAbility then
		local ab = info.CivilizationAbility
		table.insert(sections, {
			label = Locale.Lookup(ab.Name),
			text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description),
		})
	end

	-- 3: Leader Ability
	if info.LeaderAbility then
		local ab = info.LeaderAbility
		table.insert(sections, {
			label = Locale.Lookup(ab.Name),
			text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description),
		})
	end

	-- 4+: Uniques
	if info.Uniques then
		for _, u in ipairs(info.Uniques) do
			table.insert(sections, {
				label = Locale.Lookup(u.Name),
				text = Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description),
			})
		end
	end

	return sections
end

-- ---------------------------------------------------------------------------
-- Helper: build an option list for the leader pulldown.
-- Leader uses PlayerLeader parameter inside the player's own parameter set.
-- Each leader entry gets number key bindings (1-0) to speak info sections.
-- ---------------------------------------------------------------------------
local function OpenLeaderDropdown()
	local parameters = GetPlayerParameters(m_singlePlayerID)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
	if not param or not param.Values then return end

	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v
		local sections = BuildLeaderInfoSections(val.Domain, val.Value)

		local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupMenuItem"), "MenuItem", {
			Label = function() return val.Name end,
		})
		child:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		child:On("activate", function()
			parameters:SetParameterValue(param, val)
			Network.BroadcastGameConfig()
			mgr:RemoveFromStack(optList:GetId())
		end)

		for i, section in ipairs(sections) do
			if i <= #kNumberKeys then
				local text = section.text
				child:AddInputBinding({
					Key = kNumberKeys[i],
					Action = function()
						Speak(text, true)
						return true
					end,
				})
			end
		end

		optList:AddChild(child)
		if not selectedChild and currentVal and val.Value == currentVal.Value then
			selectedChild = child
		end
	end
	mgr:Push(optList, { focus = selectedChild })
end

-- ---------------------------------------------------------------------------
-- Build the panel + settings list + action buttons (called once).
-- ---------------------------------------------------------------------------
local function MakeParamPulldown(getCtrl, getContainer, locKey, paramId)
	local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
		Label = function() return Locale.Lookup(locKey) end,
		ValueGetter = function() local c = getCtrl(); return c and c:GetButton():GetText() or "" end,
		Tooltip = function() local c = getCtrl(); return c and c:GetButton():GetToolTipString() or "" end,
	})
	w:SetDisabledPredicate(function() local c = getCtrl(); return c and c:IsDisabled() end)
	w:SetHiddenPredicate(function() local ct = getContainer(); return ct and ct:IsHidden() end)
	w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	w:On("activate", function() OpenParamDropdown(paramId) end)
	return w
end

local function MakeActionButton(getCtrl, onClick)
	local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return getCtrl():GetText() end,
		HiddenPredicate = function() return getCtrl():IsHidden() end,
	})
	w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	w:On("activate", onClick)
	return w
end

local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupDialog"), "Dialog", {
		Label = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})
	CAI_Panel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		OnBackButton()
		return true
	end})
	CAI_Panel.GetDefaultChild = function(w)
		if m_activeTab == "advanced" then
			return m_advancedPlayersSection or w.Children[2]
		end
		return CAI_SettingsList or w.Children[2]
	end

	-- Tab strip: Basic / Advanced (HorizontalList of Buttons, not a real TabControl
	-- because the screen swaps siblings in/out of the panel rather than owning pages).
	CAI_TabBar = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupTabBar"), "HorizontalList")
	local basicTab = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupTab"), "Button", {
		Label = function() return Controls.WindowTitle:GetText() end,
		StateGetter = function() return m_activeTab == "basic" and Locale.Lookup("LOC_CAI_STATE_SELECTED") or "" end,
	})
	basicTab:On("focus_enter", function() SwitchToTab("basic") end)
	basicTab:On("activate", function() SwitchToTab("basic") end)
	CAI_TabBar:AddChild(basicTab)
	local advTab = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupTab"), "Button", {
		Label = function() return Controls.AdvancedSetupButton:GetText() end,
		StateGetter = function() return m_activeTab == "advanced" and Locale.Lookup("LOC_CAI_STATE_SELECTED") or "" end,
	})
	advTab:On("focus_enter", function() SwitchToTab("advanced") end)
	advTab:On("activate", function() SwitchToTab("advanced") end)
	CAI_TabBar:AddChild(advTab)
	CAI_Panel:AddChild(CAI_TabBar)

	CAI_SettingsList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List")
	CAI_Panel:AddChild(CAI_SettingsList)

	-- Ruleset pulldown
	local rulesetSpec = kStaticPulldowns[1]
	CAI_SettingsList:AddChild(MakeParamPulldown(rulesetSpec[2], rulesetSpec[3], rulesetSpec[4], rulesetSpec[1]))

	-- Leader pulldown
	local leaderBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
		Label = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		ValueGetter = function()
			local scrollText = Controls.Basic_LocalPlayerScrollText
			if scrollText then return scrollText:GetText() or "" end
			return Controls.Basic_LocalPlayerPulldown:GetButton():GetText() or ""
		end,
		HiddenPredicate = function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end,
	})
	leaderBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	leaderBtn:On("activate", function() OpenLeaderDropdown() end)
	CAI_SettingsList:AddChild(leaderBtn)

	-- Remaining static pulldowns
	for i = 2, #kStaticPulldowns do
		local spec = kStaticPulldowns[i]
		CAI_SettingsList:AddChild(MakeParamPulldown(spec[2], spec[3], spec[4], spec[1]))
	end

	-- Map select button
	local mapBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return Locale.Lookup("LOC_SETUP_MAP_TYPE") end,
		ValueGetter = function() return Controls.MapSelectButton:GetText() or "" end,
		Tooltip = function() return Controls.MapSelectButton:GetToolTipString() or "" end,
	})
	mapBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	mapBtn:On("activate", function() OnMapSelect() end)
	CAI_SettingsList:AddChild(mapBtn)

	-- Action buttons as direct panel children
	CAI_Panel:AddChild(MakeActionButton(function() return Controls.LoadConfig end,    function() OnLoadConfig() end))
	CAI_Panel:AddChild(MakeActionButton(function() return Controls.SaveConfig end,    function() OnSaveConfig() end))
	CAI_Panel:AddChild(MakeActionButton(function() return Controls.StartButton end,   function() OnStartButton() end))
	CAI_Panel:AddChild(MakeActionButton(function() return Controls.DefaultButton end, function() OnDefaultButton() end))
	CAI_Panel:AddChild(MakeActionButton(function() return Controls.CloseButton end,   function() OnBackButton() end))
end

-- ---------------------------------------------------------------------------
-- Dynamic parameter widgets: wrap CreateSimpleParameterDriver to create
-- accessible widgets for game modes, booleans, pulldowns, sliders, edits.
-- ---------------------------------------------------------------------------
CreateSimpleParameterDriver = WrapFunc(CreateSimpleParameterDriver, function(orig, o, parameter, parent)
	local control = orig(o, parameter, parent)
	if not control or not CAI_SettingsList then return control end

	local paramId = parameter.ParameterId
	if m_simpleParamWidgets[paramId] then return control end -- already created

	local widget = nil

	if parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupCheckbox"), "Checkbox", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					return p.Value and Locale.Lookup("LOC_OPTIONS_ENABLED")
						or Locale.Lookup("LOC_OPTIONS_DISABLED")
				end
				return ""
			end,
			HiddenPredicate = function()
				local ctrl = control.Control
				if parameter.GroupId == "GameModes" then
					return ctrl and ctrl.Top and ctrl.Top:IsHidden()
				else
					return ctrl and ctrl.CheckBox and ctrl.CheckBox:IsHidden()
				end
			end,
			DisabledPredicate = function()
				local ctrl = control.Control
				return ctrl and ctrl.CheckBox and ctrl.CheckBox:IsDisabled()
			end,
		})
		widget:On("value_changed", function()
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p then
				o:SetParameterValue(parameter, not p.Value)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupSlider"), "Slider", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and tostring(p.Value) or ""
			end,
			HiddenPredicate = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
		})
		widget.Increment = function(self)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value and p.Value < maxVal then
				o:SetParameterValue(parameter, p.Value + 1)
				Network.BroadcastGameConfig()
				self:Announce({ "value" })
			end
			return true
		end
		widget.Decrement = function(self)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value and p.Value > minVal then
				o:SetParameterValue(parameter, p.Value - 1)
				Network.BroadcastGameConfig()
				self:Announce({ "value" })
			end
			return true
		end
	elseif parameter.Values then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local ctrl = control.Control
				return ctrl and ctrl.PullDown and ctrl.PullDown:GetButton():GetText() or ""
			end,
			HiddenPredicate = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
			DisabledPredicate = function()
				local ctrl = control.Control
				return ctrl and ctrl.PullDown and ctrl.PullDown:IsDisabled()
			end,
		})
		widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		widget:On("activate", function() OpenParamDropdown(paramId) end)
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupEdit"), "EditBox", {
			Label = function() return parameter.Name end,
			HiddenPredicate = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
		})
		local initial = (function()
			local ctrl = control.Control
			return ctrl and ctrl.StringEdit and ctrl.StringEdit:GetText() or ""
		end)()
		widget:SetText(initial, true)
		widget:SetValueSetter(function(_, text)
			local ctrl = control.Control
			if ctrl and ctrl.StringEdit then ctrl.StringEdit:SetText(text) end
			local value = text
			if domain == "int" then
				value = tonumber(text) or 0
			elseif domain == "uint" then
				value = math.max(tonumber(text) or 0, 0)
			end
			o:SetParameterValue(parameter, value)
			Network.BroadcastGameConfig()
		end)
	end

	if widget then
		CAI_SettingsList:AddChild(widget)
		m_simpleParamWidgets[paramId] = widget
	end

	return control
end)

-- ---------------------------------------------------------------------------
-- Advanced view: open leader dropdown for any player (local or AI)
-- ---------------------------------------------------------------------------
local function OpenLeaderDropdownForPlayer(playerId)
	local parameters = GetPlayerParameters(playerId)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
	if not param or not param.Values then return end

	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local currentVal = param.Value
	local selectedChild = nil
	for _, v in ipairs(param.Values) do
		local val = v
		local sections = (playerId == m_singlePlayerID)
			and BuildLeaderInfoSections(val.Domain, val.Value) or {}

		local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupMenuItem"), "MenuItem", {
			Label = function() return val.Name end,
		})
		child:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		child:On("activate", function()
			parameters:SetParameterValue(param, val)
			local colorParam = parameters.Parameters["PlayerColorAlternate"]
			if colorParam then
				parameters:SetParameterValue(colorParam, 0)
			end
			Network.BroadcastGameConfig()
			mgr:RemoveFromStack(optList:GetId())
		end)

		for i, section in ipairs(sections) do
			if i <= #kNumberKeys then
				local text = section.text
				child:AddInputBinding({
					Key = kNumberKeys[i],
					Action = function()
						Speak(text, true)
						return true
					end,
				})
			end
		end

		optList:AddChild(child)
		if not selectedChild and currentVal and val.Value == currentVal.Value then
			selectedChild = child
		end
	end
	mgr:Push(optList, { focus = selectedChild })
end

-- ---------------------------------------------------------------------------
-- Advanced view: open color dropdown for local player
-- ---------------------------------------------------------------------------
local function OpenColorDropdown()
	local parameters = GetPlayerParameters(m_singlePlayerID)
	if not parameters then return end
	local param = parameters.Parameters and parameters.Parameters["PlayerColorAlternate"]
	if not param then return end
	local leaderParam = parameters.Parameters["PlayerLeader"]
	if not leaderParam or not leaderParam.Value then return end

	local icons = GetPlayerIcons(leaderParam.Value.Domain, leaderParam.Value.Value)
	if not icons then return end

	local optList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List")
	optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
		mgr:RemoveFromStack(optList:GetId())
		return true
	end})

	local currentVal = param.Value or 0
	local selectedChild = nil
	for j = 0, 3 do
		local backColor, frontColor = UI.GetPlayerColorValues(icons.PlayerColor, j)
		if backColor and frontColor and backColor ~= 0 and frontColor ~= 0 then
			local colorIdx = j
			local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupMenuItem"), "MenuItem", {
				Label = function() return Locale.Lookup("LOC_CAI_COLOR") .. " " .. (colorIdx + 1) end,
			})
			child:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
			child:On("activate", function()
				parameters:SetParameterValue(param, colorIdx)
				Network.BroadcastGameConfig()
				mgr:RemoveFromStack(optList:GetId())
			end)
			optList:AddChild(child)
			if not selectedChild and colorIdx == currentVal then
				selectedChild = child
			end
		end
	end
	mgr:Push(optList, { focus = selectedChild })
end

-- ---------------------------------------------------------------------------
-- Advanced view: get the section list widget for a parameter group
-- ---------------------------------------------------------------------------
local kGroupToSection = {
	BasicGameOptions = "Primary",
	GameOptions      = "Primary",
	BasicMapOptions  = "Primary",
	MapOptions       = "Primary",
	GameModes        = "GameModes",
	Victories        = "Victories",
	AdvancedOptions  = "Advanced",
}

local function GetAdvancedSection(groupId)
	local sectionKey = kGroupToSection[groupId]
	if sectionKey then
		return m_advancedSections[sectionKey]
	end
	-- Default to Advanced for unknown groups
	return m_advancedSections["Advanced"]
end

-- ---------------------------------------------------------------------------
-- Advanced view: build player section widgets
-- ---------------------------------------------------------------------------
local function BuildPlayerSection()
	if not m_advancedPlayersSection then return end
	m_advancedPlayersSection:ClearChildren()
	m_aiPlayerWidgets = {}

	-- Local player leader
	local locLeader = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
		Label = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		ValueGetter = function()
			local scrollText = Controls.Advanced_LocalPlayerScrollText
			if scrollText then return scrollText:GetText() or "" end
			return Controls.Advanced_LocalPlayerPulldown:GetButton():GetText() or ""
		end,
		HiddenPredicate = function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end,
	})
	locLeader:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	locLeader:On("activate", function() OpenLeaderDropdownForPlayer(m_singlePlayerID) end)
	m_advancedPlayersSection:AddChild(locLeader)

	-- Local player color
	local locColor = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
		Label = function() return Locale.Lookup("LOC_CAI_COLOR") end,
		ValueGetter = function()
			local ctrl = Controls.Advanced_LocalColorPullDown
			if ctrl then return ctrl:GetButton():GetText() or "" end
			return ""
		end,
		HiddenPredicate = function()
			local ctrl = Controls.Advanced_LocalColorPullDown
			return ctrl and ctrl:IsDisabled()
		end,
	})
	locColor:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	locColor:On("activate", function() OpenColorDropdown() end)
	m_advancedPlayersSection:AddChild(locColor)

	-- AI player slots
	local player_ids = GameConfiguration.GetParticipatingPlayerIDs()
	local minPlayers = MapConfiguration.GetMinMajorPlayers() or 2
	local can_remove = #player_ids > minPlayers

	local aiIndex = 0
	for _, player_id in ipairs(player_ids) do
		if player_id ~= m_singlePlayerID then
			aiIndex = aiIndex + 1
			local pid = player_id
			local playerNum = aiIndex + 1 -- capture for closure
			local playerConfig = PlayerConfigurations[pid]

			local aiSubmenu = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupSubMenu"), "SubMenu", {
				Label = function()
					local params = GetPlayerParameters(pid)
					local leaderParam = params and params.Parameters and params.Parameters["PlayerLeader"]
					local leaderName = leaderParam and leaderParam.Value and leaderParam.Value.Name or "?"
					return Locale.Lookup("LOC_CAI_PLAYER") .. " " .. playerNum .. ": " .. leaderName
				end,
			})

			-- Leader dropdown
			local aiLeader = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
				Label = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
				ValueGetter = function()
					local params = GetPlayerParameters(pid)
					local leaderParam = params and params.Parameters and params.Parameters["PlayerLeader"]
					return leaderParam and leaderParam.Value and leaderParam.Value.Name or ""
				end,
			})
			aiLeader:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
			aiLeader:On("activate", function() OpenLeaderDropdownForPlayer(pid) end)
			aiSubmenu:AddChild(aiLeader)

			-- Remove button
			if can_remove then
				local rm = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
					Label = function() return Locale.Lookup("LOC_DELETE_AI") end,
				})
				rm:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
				rm:On("activate", function()
					playerConfig:SetLeaderTypeName(nil)
					GameConfiguration.RemovePlayer(pid)
					GameSetup_PlayerCountChanged()
				end)
				aiSubmenu:AddChild(rm)
			end

			m_advancedPlayersSection:AddChild(aiSubmenu)
			table.insert(m_aiPlayerWidgets, {playerId = pid, submenu = aiSubmenu})
		end
	end

	-- Add AI button
	local addAI = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return Controls.AddAIButton:GetText() end,
		HiddenPredicate = function() return Controls.AddAIButton:IsHidden() end,
	})
	addAI:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	addAI:On("activate", function() OnAddAIButton() end)
	m_advancedPlayersSection:AddChild(addAI)
end

-- ---------------------------------------------------------------------------
-- Advanced view: build all children for the advanced settings list
-- ---------------------------------------------------------------------------
local function BuildAdvancedChildren()
	m_advancedSections = {}
	m_advancedParamWidgets = {}

	-- Create section lists
	local sectionDefs = {
		{ key = "Primary",   label = "LOC_OPTIONS" },
		{ key = "GameModes", label = "LOC_SETUP_GAME_MODES" },
		{ key = "Victories", label = "LOC_SETUP_VICTORY_CONDITIONS" },
		{ key = "Advanced",  label = "LOC_ADVANCED_OPTIONS" },
	}
	for _, def in ipairs(sectionDefs) do
		m_advancedSections[def.key] = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List", {
			Label = function() return Locale.Lookup(def.label) end,
		})
	end

	-- Players section
	m_advancedPlayersSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupList"), "List", {
		Label = function() return Locale.Lookup("LOC_PLAYERS") end,
	})
	BuildPlayerSection()
end

-- ---------------------------------------------------------------------------
-- Detach all children from a widget without destroying them
-- ---------------------------------------------------------------------------
local function DetachChildren(widget)
	if not widget or not widget.Children then return end
	for _, child in ipairs(widget.Children) do
		child.Parent = nil
	end
	widget.Children = {}
	widget._lastFocusedChild = nil
	widget._lastFocusedKey = nil
end

-- ---------------------------------------------------------------------------
-- Remove advanced sections from the panel
-- ---------------------------------------------------------------------------
RemoveAdvancedSections = function()
	if m_advancedPlayersSection and m_advancedPlayersSection.Parent == CAI_Panel then
		m_advancedPlayersSection:RemoveFromParent()
	end
	for _, section in pairs(m_advancedSections) do
		if section.Parent == CAI_Panel then
			section:RemoveFromParent()
		end
	end
end

-- ---------------------------------------------------------------------------
-- Swap settings list children between basic and advanced views
-- ---------------------------------------------------------------------------
local function PopulateBasicView()
	if not CAI_SettingsList then return end

	-- Remove advanced sections from panel
	RemoveAdvancedSections()

	-- Re-add the basic settings list after TabBar if not already there
	if not CAI_Panel:GetChildIndex(CAI_SettingsList) then
		CAI_Panel:InsertChild(2, CAI_SettingsList)
	end

	-- Repopulate basic children
	DetachChildren(CAI_SettingsList)
	for _, child in ipairs(m_basicChildren) do
		CAI_SettingsList:AddChild(child)
	end
end

local function PopulateAdvancedView()
	if not CAI_Panel then return end

	-- Build advanced children fresh (params may have changed)
	BuildAdvancedChildren()

	-- Populate advanced param widgets from current game parameters
	if g_GameParameters and g_GameParameters.Parameters then
		for paramId, param in pairs(g_GameParameters.Parameters) do
			if not m_advancedParamWidgets[paramId] then
				local section = GetAdvancedSection(param.GroupId)
				if section then
					CreateAdvancedParamWidget(param, section)
				end
			end
		end
	end

	-- Remove the basic settings list from the panel
	if CAI_Panel:GetChildIndex(CAI_SettingsList) then
		CAI_SettingsList:RemoveFromParent()
	end

	-- Add sections directly to panel (after TabBar, before action buttons)
	local insertIdx = 2
	CAI_Panel:InsertChild(insertIdx, m_advancedPlayersSection)
	insertIdx = insertIdx + 1

	local sectionOrder = { "Primary", "GameModes", "Victories", "Advanced" }
	for _, key in ipairs(sectionOrder) do
		local section = m_advancedSections[key]
		if section then
			CAI_Panel:InsertChild(insertIdx, section)
			insertIdx = insertIdx + 1
		end
	end
end

-- ---------------------------------------------------------------------------
-- Switch between basic and advanced tabs
-- ---------------------------------------------------------------------------
SwitchToTab = function(tabName)
	if tabName == m_activeTab then return end
	m_activeTab = tabName
	if tabName == "advanced" then
		Controls.CreateGameWindow:SetHide(true)
		Controls.AdvancedOptionsWindow:SetHide(false)
		Controls.LoadConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
		Controls.SaveConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
		Controls.ButtonStack:CalculateSize()
		m_AdvancedMode = true
		PopulateAdvancedView()
	else
		Controls.CreateGameWindow:SetHide(false)
		Controls.AdvancedOptionsWindow:SetHide(true)
		Controls.LoadConfig:SetHide(true)
		Controls.SaveConfig:SetHide(true)
		Controls.ButtonStack:CalculateSize()
		m_AdvancedMode = false
		PopulateBasicView()
	end
end

-- ---------------------------------------------------------------------------
-- Create an accessible widget for an advanced-view parameter
-- ---------------------------------------------------------------------------
function CreateAdvancedParamWidget(parameter, section)
	if not section then return end
	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return end

	local widget = nil

	-- Skip player parameters (no parent stack) and already-handled special params
	if not kGroupToSection[parameter.GroupId] and parameter.GroupId ~= nil then
		return
	end

	if parameter.Array then
		local paramId_inner = parameter.ParameterId
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId_inner]
				if p and p.Value then
					if type(p.Value) == "table" then
						local count = #p.Value
						if count == 0 then return Locale.Lookup("LOC_SELECTION_NOTHING") end
						if p.AllValues and count == #p.AllValues then return Locale.Lookup("LOC_SELECTION_EVERYTHING") end
						return Locale.Lookup("LOC_SELECTION_CUSTOM", count)
					end
					return p.Value.Name or ""
				end
				return ""
			end,
		})
		widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		widget:On("activate", function()
			if paramId_inner == "CityStates" then
				LuaEvents.CityStatePicker_Initialize(g_GameParameters.Parameters[paramId_inner], g_GameParameters)
				Controls.CityStatePicker:SetHide(false)
			elseif paramId_inner == "LeaderPool1" or paramId_inner == "LeaderPool2" then
				LuaEvents.LeaderPicker_Initialize(g_GameParameters.Parameters[paramId_inner], g_GameParameters)
				Controls.LeaderPicker:SetHide(false)
			else
				LuaEvents.MultiSelectWindow_Initialize(g_GameParameters.Parameters[paramId_inner])
				Controls.MultiSelectWindow:SetHide(false)
			end
		end)
	elseif parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupCheckbox"), "Checkbox", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p then
					return p.Value and Locale.Lookup("LOC_OPTIONS_ENABLED")
						or Locale.Lookup("LOC_OPTIONS_DISABLED")
				end
				return ""
			end,
		})
		widget:On("value_changed", function()
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p then
				g_GameParameters:SetParameterValue(p, not p.Value)
				BroadcastGameConfigChanges()
			end
		end)
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupSlider"), "Slider", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and tostring(p.Value) or ""
			end,
		})
		widget.Increment = function(self)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value and p.Value < maxVal then
				g_GameParameters:SetParameterValue(p, p.Value + 1)
				BroadcastGameConfigChanges()
				self:Announce({ "value" })
			end
			return true
		end
		widget.Decrement = function(self)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value and p.Value > minVal then
				g_GameParameters:SetParameterValue(p, p.Value - 1)
				BroadcastGameConfigChanges()
				self:Announce({ "value" })
			end
			return true
		end
	elseif parameter.Values then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupPulldown"), "Button", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and p.Value and p.Value.Name or ""
			end,
		})
		widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
		widget:On("activate", function() OpenParamDropdown(paramId) end)
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupEdit"), "EditBox", {
			Label = function() return parameter.Name end,
		})
		local pInit = g_GameParameters and g_GameParameters.Parameters
			and g_GameParameters.Parameters[paramId]
		widget:SetText(pInit and pInit.Value and tostring(pInit.Value) or "", true)
		widget:SetValueSetter(function(_, text)
			local value = text
			if domain == "int" then
				value = tonumber(text) or 0
			elseif domain == "uint" then
				value = math.max(tonumber(text) or 0, 0)
			end
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p then
				g_GameParameters:SetParameterValue(p, value)
				BroadcastGameConfigChanges()
			end
		end)
	end

	if widget then
		section:AddChild(widget)
		m_advancedParamWidgets[paramId] = widget
	end
end

-- ---------------------------------------------------------------------------
-- Wrap special button-popup drivers to create accessible widgets
-- ---------------------------------------------------------------------------
CreateButtonPopupDriver = WrapFunc(CreateButtonPopupDriver, function(orig, o, parameter, activateFunc, parent)
	local driver = orig(o, parameter, activateFunc, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return parameter.Name end,
		ValueGetter = function()
			local c = driver.Cache
			return c and c.ValueText or ""
		end,
		Tooltip = function() return parameter.Description or "" end,
	})
	widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	widget:On("activate", function()
		if activateFunc then activateFunc() end
	end)
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateMultiSelectWindowDriver = WrapFunc(CreateMultiSelectWindowDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return parameter.Name end,
		ValueGetter = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		Tooltip = function() return parameter.Description or "" end,
	})
	widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	widget:On("activate", function()
		LuaEvents.MultiSelectWindow_Initialize(o.Parameters[paramId])
		Controls.MultiSelectWindow:SetHide(false)
	end)
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateCityStatePickerDriver = WrapFunc(CreateCityStatePickerDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return parameter.Name end,
		ValueGetter = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		Tooltip = function() return parameter.Description or "" end,
	})
	widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	widget:On("activate", function()
		LuaEvents.CityStatePicker_Initialize(o.Parameters[paramId], g_GameParameters)
		Controls.CityStatePicker:SetHide(false)
	end)
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

CreateLeaderPickerDriver = WrapFunc(CreateLeaderPickerDriver, function(orig, o, parameter, parent)
	local driver = orig(o, parameter, parent)
	if not m_AdvancedMode or not driver then return driver end

	local paramId = parameter.ParameterId
	if m_advancedParamWidgets[paramId] then return driver end

	local section = GetAdvancedSection(parameter.GroupId)
	if not section then return driver end

	local widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAIAdvancedSetupButton"), "Button", {
		Label = function() return parameter.Name end,
		ValueGetter = function()
			local c = driver.Cache
			return c and c.ValueText and Locale.Lookup(c.ValueText, c.ValueAmount or 0) or ""
		end,
		Tooltip = function() return parameter.Description or "" end,
	})
	widget:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
	widget:On("activate", function()
		LuaEvents.LeaderPicker_Initialize(o.Parameters[paramId], g_GameParameters)
		Controls.LeaderPicker:SetHide(false)
	end)
	section:AddChild(widget)
	m_advancedParamWidgets[paramId] = widget
	return driver
end)

-- ---------------------------------------------------------------------------
-- Wrap RefreshPlayerSlots to rebuild player widgets when in advanced mode
-- ---------------------------------------------------------------------------
RefreshPlayerSlots = WrapFunc(RefreshPlayerSlots, function(orig)
	orig()
	if m_AdvancedMode and m_advancedPlayersSection then
		BuildPlayerSection()
	end
end)

-- ---------------------------------------------------------------------------
-- Close: pop panel from stack
-- ---------------------------------------------------------------------------
local function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
end

-- ---------------------------------------------------------------------------
-- Lifecycle hooks
-- ---------------------------------------------------------------------------
OnShow = WrapFunc(OnShow, function(orig)
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	-- Rebuild fresh each show — game recreates parameter controls between visits
	CAI_Panel = nil
	CAI_SettingsList = nil
	m_simpleParamWidgets = {}
	m_advancedParamWidgets = {}
	m_advancedSections = {}
	m_advancedPlayersSection = nil
	m_aiPlayerWidgets = {}
	m_basicChildren = {}
	m_activeTab = "basic"
	CAI_TabBar = nil
	m_intentionalClose = false
	BuildPanel()
	-- Snapshot basic children so we can restore them after leaving advanced view
	if CAI_SettingsList then
		for _, child in ipairs(CAI_SettingsList.Children) do
			table.insert(m_basicChildren, child)
		end
	end
	orig()
	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		-- Fallback: original input handler consumed all input
		local uiMsg = input:GetMessageType()
		if uiMsg == KeyEvents.KeyUp then
			local key = input:GetKey()
			if key == Keys.VK_ESCAPE then
				OnBackButton()
			end
		end
		return true
	end, true)
	mgr:Push(CAI_Panel, { priority = PopupPriority.Current })
end)

OnBackButton = WrapFunc(OnBackButton, function(orig)
	-- Always close the screen, regardless of which tab is active
	m_intentionalClose = true
	ClosePanel()
	-- Reset to basic mode so orig() takes the full-close path
	if m_AdvancedMode then
		Controls.CreateGameWindow:SetHide(false)
		Controls.AdvancedOptionsWindow:SetHide(true)
		Controls.LoadConfig:SetHide(true)
		Controls.SaveConfig:SetHide(true)
		m_AdvancedMode = false
	end
	orig()
end)

OnHide = WrapFunc(OnHide, function(orig)
	-- Only pop if we intentionally closed (not on connection resets or temp hides)
	if m_intentionalClose then
		ClosePanel()
		m_intentionalClose = false
	end
	orig()
end)
ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
--#End of accessibility integration
Initialize();
