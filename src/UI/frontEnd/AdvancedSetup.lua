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

local CAI_Panel = nil ---@type PanelWidget
local CAI_Tabs = nil ---@type TabControlWidget
local m_basicPage = nil ---@type TabPageWidget
local m_basicList = nil ---@type ListWidget
local m_advancedPage = nil ---@type TabPageWidget
local m_actionRow = nil ---@type PanelWidget
local m_intentionalClose = false

-- Basic view: Dropdown widgets keyed by parameterId
local m_basicDropdowns = {}
local m_basicParamWidgets = {} -- parameterId → widget (simple params in basic view)
-- Advanced view: List + SubMenu nodes
local m_advList = nil ---@type ListWidget
local m_advParamWidgets = {} -- parameterId → widget
local m_advPlayerSub = nil ---@type SubMenuWidget
-- Section submenu widgets keyed by section key (persisted across rebuilds)
local m_advSections = {} ---@type table<string, SubMenuWidget>

local HOVER_SOUND = "Main_Menu_Mouse_Over"

-- Number keys for leader info sections
local kNumberKeys = {
	Keys["1"], Keys["2"], Keys["3"], Keys["4"], Keys["5"],
	Keys["6"], Keys["7"], Keys["8"], Keys["9"], Keys["0"],
}

local function CAI_SortParams(a, b)
	if (a.SortIndex or 0) ~= (b.SortIndex or 0) then
		return (a.SortIndex or 0) < (b.SortIndex or 0)
	end
	return Locale.Compare(a.Name or "", b.Name or "") == -1
end

-- ---------------------------------------------------------------------------
-- Leader tooltip builder
-- ---------------------------------------------------------------------------
local kUniqueTypeKeys = {
	{ prefix = "ICON_UNIT_",        singular = "LOC_CAI_UNIQUE_UNIT",        plural = "LOC_CAI_UNIQUE_UNITS" },
	{ prefix = "ICON_BUILDING_",    singular = "LOC_CAI_UNIQUE_BUILDING",    plural = "LOC_CAI_UNIQUE_BUILDINGS" },
	{ prefix = "ICON_DISTRICT_",    singular = "LOC_CAI_UNIQUE_DISTRICT",    plural = "LOC_CAI_UNIQUE_DISTRICTS" },
	{ prefix = "ICON_IMPROVEMENT_", singular = "LOC_CAI_UNIQUE_IMPROVEMENT", plural = "LOC_CAI_UNIQUE_IMPROVEMENTS" },
}

local function GetUniqueTypeIndex(icon)
	if not icon then return nil end
	for i, entry in ipairs(kUniqueTypeKeys) do
		if string.find(icon, entry.prefix) then return i end
	end
	return nil
end

local function BuildLeaderTooltip(domain, leaderType)
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
		for _, u in ipairs(info.Uniques) do
			local typeIdx = GetUniqueTypeIndex(u.Icon)
			if typeIdx then
				if not grouped[typeIdx] then grouped[typeIdx] = {} end
				table.insert(grouped[typeIdx], u)
			else
				table.insert(ungrouped, u)
			end
		end
		for i, entry in ipairs(kUniqueTypeKeys) do
			if grouped[i] then
				local headerKey = #grouped[i] > 1 and entry.plural or entry.singular
				local items = {}
				for _, u in ipairs(grouped[i]) do
					table.insert(items, Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description))
				end
				table.insert(parts, Locale.Lookup(headerKey) .. ": " .. table.concat(items, ", "))
			end
		end
		for _, u in ipairs(ungrouped) do
			table.insert(parts, Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description))
		end
	end
	return table.concat(parts, ", ")
end

-- ---------------------------------------------------------------------------
-- Leader info sections for number-key readout
-- ---------------------------------------------------------------------------
local function BuildLeaderInfoSections(domain, leaderType)
	local sections = {}
	if not domain or not leaderType then return sections end
	if leaderType == "RANDOM" or leaderType == "RANDOM_POOL1" or leaderType == "RANDOM_POOL2" then
		return sections
	end
	local info = GetPlayerInfo(domain, leaderType)
	if not info then return sections end

	local names = Locale.Lookup(info.LeaderName or "")
	if info.CivilizationName then
		names = names .. ", " .. Locale.Lookup(info.CivilizationName)
	end
	table.insert(sections, { text = names })

	if info.CivilizationAbility then
		local ab = info.CivilizationAbility
		table.insert(sections, { text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description) })
	end
	if info.LeaderAbility then
		local ab = info.LeaderAbility
		table.insert(sections, { text = Locale.Lookup(ab.Name) .. ": " .. Locale.Lookup(ab.Description) })
	end
	if info.Uniques then
		local grouped = {}
		local ungrouped = {}
		for _, u in ipairs(info.Uniques) do
			local typeIdx = GetUniqueTypeIndex(u.Icon)
			if typeIdx then
				if not grouped[typeIdx] then grouped[typeIdx] = {} end
				table.insert(grouped[typeIdx], u)
			else
				table.insert(ungrouped, u)
			end
		end
		for i, entry in ipairs(kUniqueTypeKeys) do
			if grouped[i] then
				local headerKey = #grouped[i] > 1 and entry.plural or entry.singular
				for _, u in ipairs(grouped[i]) do
					table.insert(sections, { text = Locale.Lookup(headerKey) .. ": " .. Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description) })
				end
			end
		end
		for _, u in ipairs(ungrouped) do
			table.insert(sections, { text = Locale.Lookup(u.Name) .. ": " .. Locale.Lookup(u.Description) })
		end
	end
	return sections
end

-- ---------------------------------------------------------------------------
-- Build Dropdown options + selected index from a game parameter
-- ---------------------------------------------------------------------------
local function BuildParamDropdownOptions(parameterId)
	local param = g_GameParameters and g_GameParameters.Parameters
		and g_GameParameters.Parameters[parameterId]
	if not param or not param.Values then return {}, 0 end

	local options = {}
	local selectedIdx = 0
	for i, v in ipairs(param.Values) do
		table.insert(options, {
			label = v.Name or "",
			tooltip = v.Description or "",
			value = v,
		})
		if selectedIdx == 0 and param.Value
				and v.QueryId == param.Value.QueryId
				and v.QueryIndex == param.Value.QueryIndex then
			selectedIdx = i
		end
	end
	if selectedIdx == 0 and #options > 0 then selectedIdx = 1 end
	return options, selectedIdx
end

-- ---------------------------------------------------------------------------
-- Build leader Dropdown options from player parameters
-- ---------------------------------------------------------------------------
local function BuildLeaderDropdownOptions(playerId)
	local parameters = GetPlayerParameters(playerId)
	if not parameters then return {}, 0 end
	local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
	if not param or not param.Values then return {}, 0 end

	local options = {}
	local selectedIdx = 0
	for i, v in ipairs(param.Values) do
		local tooltip = BuildLeaderTooltip(v.Domain, v.Value)
		local label = v.Name or ""
		local info = v.Domain and v.Value and GetPlayerInfo(v.Domain, v.Value)
		if info and info.CivilizationName then
			label = label .. ", " .. Locale.Lookup(info.CivilizationName)
		end
		table.insert(options, {
			label = label,
			tooltip = tooltip,
			value = v,
		})
		if selectedIdx == 0 and param.Value and v.Value == param.Value.Value then
			selectedIdx = i
		end
	end
	if selectedIdx == 0 and #options > 0 then selectedIdx = 1 end
	return options, selectedIdx
end

-- ---------------------------------------------------------------------------
-- Create a Dropdown for a static game parameter (Ruleset, Difficulty, etc.)
-- ---------------------------------------------------------------------------
local function MakeParamDropdown(parameterId, locKey, getContainer)
	local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_DD"), "Dropdown", {
		Label = function() return Locale.Lookup(locKey) end,
		Tooltip = function()
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[parameterId]
			if p and p.Value and p.Value.Description then
				return p.Value.Description
			end
			return ""
		end,
	})
	if getContainer then
		dd:SetHiddenPredicate(function()
			local ct = getContainer()
			return ct and ct:IsHidden()
		end)
	end

	local options, idx = BuildParamDropdownOptions(parameterId)
	dd:SetOptions(options)
	if idx > 0 then dd:SetSelectedIndex(idx, true) end

	dd:SetFocusSound(HOVER_SOUND)
	dd:On("value_changed", function(_, val)
		local param = g_GameParameters and g_GameParameters.Parameters
			and g_GameParameters.Parameters[parameterId]
		if param then
			g_GameParameters:SetParameterValue(param, val)
			Network.BroadcastGameConfig()
		end
	end)

	m_basicDropdowns[parameterId] = dd
	return dd
end

-- ---------------------------------------------------------------------------
-- Create a leader Dropdown for local player (basic view)
-- ---------------------------------------------------------------------------
local function LeaderTooltipForPlayer(playerId)
	local params = GetPlayerParameters(playerId)
	if not params then return "" end
	local lp = params.Parameters and params.Parameters["PlayerLeader"]
	if not lp or not lp.Value then return "" end
	return BuildLeaderTooltip(lp.Value.Domain, lp.Value.Value)
end

local function MakeLeaderDropdown()
	local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_LeaderDD"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		Tooltip = function() return LeaderTooltipForPlayer(m_singlePlayerID) end,
	})
	dd:SetHiddenPredicate(function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end)
	dd:SetFocusSound(HOVER_SOUND)

	local options, idx = BuildLeaderDropdownOptions(m_singlePlayerID)
	dd:SetOptions(options)
	if idx > 0 then dd:SetSelectedIndex(idx, true) end

	dd:On("value_changed", function(_, val)
		local parameters = GetPlayerParameters(m_singlePlayerID)
		if parameters then
			local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
			if param then
				parameters:SetParameterValue(param, val)
				local colorParam = parameters.Parameters["PlayerColorAlternate"]
				if colorParam then parameters:SetParameterValue(colorParam, 0) end
				Network.BroadcastGameConfig()
			end
		end
	end)

	m_basicDropdowns["PlayerLeader"] = dd
	return dd
end

-- ---------------------------------------------------------------------------
-- Refresh all basic dropdowns after game parameters change
-- ---------------------------------------------------------------------------
local function RefreshBasicDropdowns()
	for paramId, dd in pairs(m_basicDropdowns) do
		if paramId == "PlayerLeader" then
			local options, idx = BuildLeaderDropdownOptions(m_singlePlayerID)
			dd:SetOptions(options)
			if idx > 0 then dd:SetSelectedIndex(idx, true) end
		else
			local options, idx = BuildParamDropdownOptions(paramId)
			dd:SetOptions(options)
			if idx > 0 then dd:SetSelectedIndex(idx, true) end
		end
	end
end

-- ---------------------------------------------------------------------------
-- Action buttons: use DoLeftClick() on vanilla controls
-- ---------------------------------------------------------------------------
local function MakeActionButton(label, ctrl, isHiddenFn)
	local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_Btn"), "Button", {
		Label = function() return ctrl:GetText() end,
	})
	w:SetFocusSound(HOVER_SOUND)
	if isHiddenFn then
		w:SetHiddenPredicate(isHiddenFn)
	end
	w:On("activate", function() ctrl:DoLeftClick() end)
	return w
end

-- ---------------------------------------------------------------------------
-- Advanced view: build player section
-- ---------------------------------------------------------------------------
local function BuildAdvPlayerSection()
	if not m_advPlayerSub then return end
	m_advPlayerSub:ClearChildren()

	-- Local player
	local localItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_LocalPlayer"), "SubMenu", {
		Label = function()
			return Locale.Lookup("LOC_CAI_PLAYER") .. " 1"
		end,
		FocusKey = "player_local",
	})
	localItem:SetFocusSound(HOVER_SOUND)

	-- Local leader dropdown
	local locLeaderDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_LocLeaderDD"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_SETUP_CIVILIZATION") end,
		Tooltip = function() return LeaderTooltipForPlayer(m_singlePlayerID) end,
		FocusKey = "player_local_leader",
	})
	locLeaderDD:SetHiddenPredicate(function() return Controls.CreateGame_LocalPlayerContainer:IsHidden() end)
	locLeaderDD:SetFocusSound(HOVER_SOUND)
	local lOpts, lIdx = BuildLeaderDropdownOptions(m_singlePlayerID)
	locLeaderDD:SetOptions(lOpts)
	if lIdx > 0 then locLeaderDD:SetSelectedIndex(lIdx, true) end
	locLeaderDD:On("value_changed", function(_, val)
		local parameters = GetPlayerParameters(m_singlePlayerID)
		if parameters then
			local param = parameters.Parameters and parameters.Parameters["PlayerLeader"]
			if param then
				parameters:SetParameterValue(param, val)
				local colorParam = parameters.Parameters["PlayerColorAlternate"]
				if colorParam then parameters:SetParameterValue(colorParam, 0) end
				Network.BroadcastGameConfig()
			end
		end
	end)
	localItem:AddChild(locLeaderDD)

	-- Local color dropdown
	local locColorDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_LocColorDD"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_CAI_COLOR") end,
		FocusKey = "player_local_color",
	})
	local function RefreshColorOptions()
		local parameters = GetPlayerParameters(m_singlePlayerID)
		if not parameters then return end
		local colorParam = parameters.Parameters and parameters.Parameters["PlayerColorAlternate"]
		local leaderParam = parameters.Parameters and parameters.Parameters["PlayerLeader"]
		if not leaderParam or not leaderParam.Value then return end
		local icons = GetPlayerIcons(leaderParam.Value.Domain, leaderParam.Value.Value)
		if not icons then return end

		local colorOpts = {}
		local currentVal = colorParam and colorParam.Value or 0
		local selIdx = 0
		for j = 0, 3 do
			local backColor, frontColor = UI.GetPlayerColorValues(icons.PlayerColor, j)
			if backColor and frontColor and backColor ~= 0 and frontColor ~= 0 then
				table.insert(colorOpts, {
					label = Locale.Lookup("LOC_CAI_COLOR") .. " " .. (j + 1),
					value = j,
				})
				if j == currentVal then selIdx = #colorOpts end
			end
		end
		locColorDD:SetOptions(colorOpts)
		if selIdx > 0 then locColorDD:SetSelectedIndex(selIdx, true) end
	end
	RefreshColorOptions()
	locColorDD:On("value_changed", function(_, val)
		local parameters = GetPlayerParameters(m_singlePlayerID)
		if parameters then
			local colorParam = parameters.Parameters and parameters.Parameters["PlayerColorAlternate"]
			if colorParam then
				parameters:SetParameterValue(colorParam, val)
				Network.BroadcastGameConfig()
			end
		end
	end)
	locColorDD:SetFocusSound(HOVER_SOUND)
	locColorDD:SetHiddenPredicate(function()
		local ctrl = Controls.Advanced_LocalColorPullDown
		return ctrl and ctrl:IsDisabled()
	end)
	localItem:AddChild(locColorDD)

	m_advPlayerSub:AddChild(localItem)

	-- AI players
	local player_ids = GameConfiguration.GetParticipatingPlayerIDs()
	local minPlayers = MapConfiguration.GetMinMajorPlayers() or 2
	local can_remove = #player_ids > minPlayers
	local aiIndex = 0

	for _, player_id in ipairs(player_ids) do
		if player_id ~= m_singlePlayerID then
			aiIndex = aiIndex + 1
			local pid = player_id
			local playerNum = aiIndex + 1
			local playerConfig = PlayerConfigurations[pid]

			local aiDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AIDD"), "Dropdown", {
				Label = function()
					return Locale.Lookup("LOC_CAI_PLAYER") .. " " .. playerNum
				end,
				Tooltip = function() return LeaderTooltipForPlayer(pid) end,
				FocusKey = "player_ai_" .. pid,
			})
			aiDD:SetFocusSound(HOVER_SOUND)
			local aiOpts, aiIdx = BuildLeaderDropdownOptions(pid)
			aiDD:SetOptions(aiOpts)
			if aiIdx > 0 then aiDD:SetSelectedIndex(aiIdx, true) end
			aiDD:On("value_changed", function(_, val)
				local params = GetPlayerParameters(pid)
				if params then
					local lp = params.Parameters and params.Parameters["PlayerLeader"]
					if lp then
						params:SetParameterValue(lp, val)
						Network.BroadcastGameConfig()
					end
				end
			end)

			if can_remove then
				aiDD:AddInputBindings({
					{
						Key = Keys.VK_DELETE,
						MSG = KeyEvents.KeyUp,
						Action = function()
							playerConfig:SetLeaderTypeName(nil)
							GameConfiguration.RemovePlayer(pid)
							GameSetup_PlayerCountChanged()
							return true
						end,
					},
				})
			end

			m_advPlayerSub:AddChild(aiDD)
		end
	end

	-- Add AI button
	local addAI = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AddAI"), "Button", {
		Label = function() return Locale.Lookup("LOC_CAI_ADVANCED_SETUP_ADD_AI") end,
		HiddenPredicate = function() return Controls.AddAIButton:IsHidden() end,
		FocusKey = "player_add_ai",
	})
	addAI:SetFocusSound(HOVER_SOUND)
	addAI:On("activate", function() OnAddAIButton() end)
	m_advPlayerSub:AddChild(addAI)
end

-- ---------------------------------------------------------------------------
-- Advanced view: group mapping
-- ---------------------------------------------------------------------------
local kGroupToSection = {
	BasicGameOptions = "Options",
	GameOptions      = "Options",
	BasicMapOptions  = "Options",
	MapOptions       = "Options",
	GameModes        = "GameModes",
	Victories        = "Victories",
	AdvancedOptions  = "Advanced",
}

-- ---------------------------------------------------------------------------
-- Advanced view: create widget for a parameter inside a SubMenu
-- ---------------------------------------------------------------------------
local function CreateAdvParamWidget(parameter, parentItem)
	if not parentItem then return end
	local paramId = parameter.ParameterId
	if m_advParamWidgets[paramId] then return end

	local widget = nil

	if parameter.Array then
		local invert = parameter.UxHint == "InvertSelection"
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvBtn"), "Button", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value then
					if type(p.Value) == "table" then
						local count = #p.Value
						local total = p.Values and #p.Values or 0
						if invert then
							if count == 0 then return Locale.Lookup("LOC_SELECTION_EVERYTHING") end
							if count == total then return Locale.Lookup("LOC_SELECTION_NOTHING") end
							return Locale.Lookup("LOC_SELECTION_CUSTOM", total - count)
						else
							if count == 0 then return Locale.Lookup("LOC_SELECTION_NOTHING") end
							if count == total then return Locale.Lookup("LOC_SELECTION_EVERYTHING") end
							return Locale.Lookup("LOC_SELECTION_CUSTOM", count)
						end
					end
					return p.Value.Name or ""
				end
				if invert then return Locale.Lookup("LOC_SELECTION_EVERYTHING") end
				return ""
			end,
		})
		widget:On("activate", function()
			if paramId == "CityStates" then
				LuaEvents.CityStatePicker_Initialize(g_GameParameters.Parameters[paramId], g_GameParameters)
				Controls.CityStatePicker:SetHide(false)
			elseif paramId == "LeaderPool1" or paramId == "LeaderPool2" then
				LuaEvents.LeaderPicker_Initialize(g_GameParameters.Parameters[paramId], g_GameParameters)
				Controls.LeaderPicker:SetHide(false)
			else
				LuaEvents.MultiSelectWindow_Initialize(g_GameParameters.Parameters[paramId])
				Controls.MultiSelectWindow:SetHide(false)
			end
		end)
	elseif parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvChk"), "Checkbox", {
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
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values and parameter.Values.Type == "IntRange" then
		local minVal = parameter.Values.MinimumValue
		local maxVal = parameter.Values.MaximumValue
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvSlider"), "Slider", {
			Label = function() return parameter.Name end,
			Tooltip = function() return parameter.Description or "" end,
			ValueGetter = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				return p and tostring(p.Value) or ""
			end,
		})
		widget:SetMin(minVal)
		widget:SetMax(maxVal)
		widget:SetValue(parameter.Value or minVal, true)
		widget:On("value_changed", function(_, newVal)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value ~= newVal then
				g_GameParameters:SetParameterValue(p, newVal)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values then
		local dd = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvDD"), "Dropdown", {
			Label = function() return parameter.Name end,
			Tooltip = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value.Description then
					return p.Value.Description
				end
				return parameter.Description or ""
			end,
		})
		local options, idx = BuildParamDropdownOptions(paramId)
		dd:SetOptions(options)
		if idx > 0 then dd:SetSelectedIndex(idx, true) end
		dd:On("value_changed", function(_, val)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p then
				g_GameParameters:SetParameterValue(p, val)
				Network.BroadcastGameConfig()
			end
		end)
		widget = dd
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvEdit"), "EditBox", {
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
				Network.BroadcastGameConfig()
			end
		end)
	end

	if widget then
		widget:SetFocusSound(HOVER_SOUND)
		widget:SetFocusKey("adv_" .. paramId)
		parentItem:AddChild(widget)
		m_advParamWidgets[paramId] = widget
	end
end

-- ---------------------------------------------------------------------------
-- Advanced view: populate parameters into sections
-- ---------------------------------------------------------------------------
local function PopulateAdvancedList()
	if not m_advList then return end

	local capture = mgr:CaptureFocusKey(m_advList)
	m_advParamWidgets = {}

	-- Clear section contents but keep section submenus
	for _, sub in pairs(m_advSections) do
		sub:ClearChildren()
	end
	m_advPlayerSub:ClearChildren()
	BuildAdvPlayerSection()

	-- Populate parameter widgets into sections, sorted by SortIndex
	if g_GameParameters and g_GameParameters.Parameters then
		local sorted = {}
		for paramId, param in pairs(g_GameParameters.Parameters) do
			local sectionKey = kGroupToSection[param.GroupId]
			if sectionKey and m_advSections[sectionKey] then
				table.insert(sorted, param)
			end
		end
		table.sort(sorted, CAI_SortParams)
		for _, param in ipairs(sorted) do
			local sectionKey = kGroupToSection[param.GroupId]
			CreateAdvParamWidget(param, m_advSections[sectionKey])
		end
	end

	mgr:RestoreFocus(m_advList, capture)
end

-- ---------------------------------------------------------------------------
-- Build the full panel (called once per show)
-- ---------------------------------------------------------------------------
local function BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_Panel"), "Panel", {
		Label = function() return Controls.WindowTitle:GetText() end,
		SpeechSettings = { Role = false },
	})

	-- TabControl: Basic / Advanced
	CAI_Tabs = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_Tabs"), "TabControl", {})

	-- Basic page with a List container for all options
	m_basicPage = CAI_Tabs:AddPage(function() return Controls.WindowTitle:GetText() end)
	m_basicList = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_BasicList"), "List")
	m_basicPage:AddChild(m_basicList)

	-- Ruleset
	m_basicList:AddChild(MakeParamDropdown("Ruleset", "LOC_SETUP_CHOOSE_RULESET",
		function() return Controls.CreateGame_RulesetContainer end))

	-- Leader
	m_basicList:AddChild(MakeLeaderDropdown())

	-- Difficulty
	m_basicList:AddChild(MakeParamDropdown("GameDifficulty", "LOC_SETUP_DIFFICULTY",
		function() return Controls.CreateGame_GameDifficultyContainer end))

	-- Game Speed
	m_basicList:AddChild(MakeParamDropdown("GameSpeeds", "LOC_SETUP_SPEED",
		function() return Controls.CreateGame_SpeedPulldownContainer end))

	-- Map Size
	m_basicList:AddChild(MakeParamDropdown("MapSize", "LOC_SETUP_MAP_SIZE",
		function() return Controls.CreateGame_MapSizeContainer end))

	-- Map Type (button, opens popup)
	local mapBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_MapBtn"), "Button", {
		Label = function() return Locale.Lookup("LOC_SETUP_MAP_TYPE") end,
		ValueGetter = function() return Controls.MapSelectButton:GetText() or "" end,
		Tooltip = function() return Controls.MapSelectButton:GetToolTipString() or "" end,
	})
	mapBtn:SetFocusSound(HOVER_SOUND)
	mapBtn:On("activate", function() Controls.MapSelectButton:DoLeftClick() end)
	m_basicList:AddChild(mapBtn)

	-- Advanced page with a List + SubMenu sections (created once, repopulated on refresh)
	m_advancedPage = CAI_Tabs:AddPage(function() return Controls.AdvancedSetupButton:GetText() end)
	m_advList = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_AdvList"), "List")
	m_advancedPage:AddChild(m_advList)

	-- Create persistent section submenus
	m_advPlayerSub = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_PlayersSub"), "SubMenu", {
		Label = function() return Locale.Lookup("LOC_CAI_ADVANCED_SETUP_PLAYERS") end,
		FocusKey = "section_Players",
	})
	m_advPlayerSub:SetFocusSound(HOVER_SOUND)
	m_advList:AddChild(m_advPlayerSub)

	local sectionDefs = {
		{ key = "Options",   loc = "LOC_CAI_ADVANCED_SETUP_OPTIONS" },
		{ key = "GameModes", loc = "LOC_CAI_ADVANCED_SETUP_GAME_MODES" },
		{ key = "Victories", loc = "LOC_SETUP_VICTORY_CONDITIONS" },
		{ key = "Advanced",  loc = "LOC_CAI_ADVANCED_SETUP_ADVANCED" },
	}
	m_advSections = {}
	for _, def in ipairs(sectionDefs) do
		local sub = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_Sec_" .. def.key), "SubMenu", {
			Label = function() return Locale.Lookup(def.loc) end,
			FocusKey = "section_" .. def.key,
		})
		sub:SetFocusSound(HOVER_SOUND)
		m_advSections[def.key] = sub
		m_advList:AddChild(sub)
	end

	CAI_Tabs:On("value_changed", function(_, idx)
		if idx == 2 then
			Controls.CreateGameWindow:SetHide(true)
			Controls.AdvancedOptionsWindow:SetHide(false)
			Controls.LoadConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
			Controls.SaveConfig:SetHide(GameConfiguration.IsWorldBuilderEditor())
			Controls.ButtonStack:CalculateSize()
			m_AdvancedMode = true
			PopulateAdvancedList()
		else
			Controls.CreateGameWindow:SetHide(false)
			Controls.AdvancedOptionsWindow:SetHide(true)
			Controls.LoadConfig:SetHide(true)
			Controls.SaveConfig:SetHide(true)
			Controls.ButtonStack:CalculateSize()
			m_AdvancedMode = false
		end
	end)

	CAI_Panel:AddChild(CAI_Tabs)

	-- Action buttons in a Transparent panel (no wrap so Tab escapes)
	m_actionRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_Actions"), "Panel", {
		Transparent = true,
		WrapAround = false,
	})
	m_actionRow:AddChild(MakeActionButton("Save", Controls.SaveConfig,
		function() return Controls.SaveConfig:IsHidden() end))
	m_actionRow:AddChild(MakeActionButton("Load", Controls.LoadConfig,
		function() return Controls.LoadConfig:IsHidden() end))
	m_actionRow:AddChild(MakeActionButton("Defaults", Controls.DefaultButton, nil))
	m_actionRow:AddChild(MakeActionButton("Start", Controls.StartButton, nil))
	CAI_Panel:AddChild(m_actionRow)
end

-- ---------------------------------------------------------------------------
-- Helper: create a basic-view widget for a simple parameter
-- ---------------------------------------------------------------------------
local function CreateBasicParamWidget(o, parameter, control)
	if not m_basicList then return end
	local paramId = parameter.ParameterId
	if m_basicParamWidgets[paramId] then return end

	local widget = nil

	if parameter.GroupId == "GameModes" or parameter.Domain == "bool" then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_BasicChk"), "Checkbox", {
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
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_BasicSlider"), "Slider", {
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
		widget:SetMin(minVal)
		widget:SetMax(maxVal)
		widget:SetValue(parameter.Value or minVal, true)
		widget:On("value_changed", function(_, newVal)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p and p.Value ~= newVal then
				o:SetParameterValue(parameter, newVal)
				Network.BroadcastGameConfig()
			end
		end)
	elseif parameter.Values then
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_BasicDD"), "Dropdown", {
			Label = function() return parameter.Name end,
			Tooltip = function()
				local p = g_GameParameters and g_GameParameters.Parameters
					and g_GameParameters.Parameters[paramId]
				if p and p.Value and p.Value.Description then
					return p.Value.Description
				end
				return parameter.Description or ""
			end,
			HiddenPredicate = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
			DisabledPredicate = function()
				local ctrl = control.Control
				return ctrl and ctrl.PullDown and ctrl.PullDown:IsDisabled()
			end,
		})
		local options, idx = BuildParamDropdownOptions(paramId)
		widget:SetOptions(options)
		if idx > 0 then widget:SetSelectedIndex(idx, true) end
		widget:On("value_changed", function(_, val)
			local p = g_GameParameters and g_GameParameters.Parameters
				and g_GameParameters.Parameters[paramId]
			if p then
				g_GameParameters:SetParameterValue(p, val)
				Network.BroadcastGameConfig()
			end
		end)
		m_basicDropdowns[paramId] = widget
	elseif parameter.Domain == "int" or parameter.Domain == "uint" or parameter.Domain == "text" then
		local domain = parameter.Domain
		widget = mgr:CreateWidget(mgr:GenerateWidgetId("CAISetup_BasicEdit"), "EditBox", {
			Label = function() return parameter.Name end,
			HiddenPredicate = function()
				return control.Control and control.Control.Root and control.Control.Root:IsHidden()
			end,
		})
		local ctrl = control.Control
		local initial = ctrl and ctrl.StringEdit and ctrl.StringEdit:GetText() or ""
		widget:SetText(initial, true)
		widget:SetValueSetter(function(_, text)
			local c = control.Control
			if c and c.StringEdit then c.StringEdit:SetText(text) end
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
		widget:SetFocusSound(HOVER_SOUND)
		widget._sortIndex = parameter.SortIndex or 0
		widget._sortName = parameter.Name or ""
		m_basicList:AddChild(widget)
		m_basicParamWidgets[paramId] = widget
	end
end

-- ---------------------------------------------------------------------------
-- Sort basic list children by SortIndex (matches vanilla parameter order)
-- ---------------------------------------------------------------------------
local function SortBasicList()
	if not m_basicList then return end
	local fixedCount = 6 -- Ruleset, Leader, Difficulty, Speed, MapSize, MapType
	local dynamic = {}
	while #m_basicList.Children > fixedCount do
		table.insert(dynamic, table.remove(m_basicList.Children, fixedCount + 1))
	end
	table.sort(dynamic, function(a, b)
		local ai = a._sortIndex or 0
		local bi = b._sortIndex or 0
		if ai ~= bi then return ai < bi end
		return Locale.Compare(a._sortName or "", b._sortName or "") == -1
	end)
	for _, w in ipairs(dynamic) do
		table.insert(m_basicList.Children, w)
	end
end

-- ---------------------------------------------------------------------------
-- Wrap CreateSimpleParameterDriver to capture params for both views
-- ---------------------------------------------------------------------------
CreateSimpleParameterDriver = WrapFunc(CreateSimpleParameterDriver, function(orig, o, parameter, parent)
	local control = orig(o, parameter, parent)
	if not control then return control end

	-- Basic view: create accessible widget in the basic list
	if m_basicList then
		CreateBasicParamWidget(o, parameter, control)
	end

	return control
end)

-- ---------------------------------------------------------------------------
-- Wrap RefreshPlayerSlots to rebuild player widgets when in advanced mode
-- ---------------------------------------------------------------------------
RefreshPlayerSlots = WrapFunc(RefreshPlayerSlots, function(orig)
	orig()
	if m_AdvancedMode and m_advPlayerSub then
		local capture = mgr:CaptureFocusKey(m_advPlayerSub)
		BuildAdvPlayerSection()
		mgr:RestoreFocus(m_advPlayerSub, capture)
	end
end)

-- ---------------------------------------------------------------------------
-- Wrap GameParameters_UI_AfterRefresh to refresh dropdowns
-- ---------------------------------------------------------------------------
GameParameters_UI_AfterRefresh = WrapFunc(GameParameters_UI_AfterRefresh, function(orig, o)
	orig(o)
	RefreshBasicDropdowns()
	SortBasicList()
	if m_AdvancedMode and m_advList then
		PopulateAdvancedList()
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
		CAI_Panel:Destroy()
	end
	CAI_Panel = nil
	CAI_Tabs = nil
	m_basicPage = nil
	m_basicList = nil
	m_advancedPage = nil
	m_actionRow = nil
	m_basicDropdowns = {}
	m_basicParamWidgets = {}
	m_advParamWidgets = {}
	m_advSections = {}
	m_advList = nil
	m_advPlayerSub = nil
	m_intentionalClose = false

	BuildPanel()
	orig()

	-- Sync CAI tab to vanilla's current view state
	if m_AdvancedMode then
		-- Non-silent so value_changed fires and builds the advanced tree + sets vanilla windows
		CAI_Tabs:SetActivePageById(m_advancedPage.Id)
	end

	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
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
	m_intentionalClose = true
	ClosePanel()
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
