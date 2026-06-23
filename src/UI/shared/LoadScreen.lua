--
--	Loading screen as player goes from shell to game state.
--
-- ===========================================================================

include( "InputSupport" );
include( "InstanceManager" );
include( "SupportFunctions" );
include( "Civ6Common" );
include( "Colors") ;

-- ===========================================================================
--	Action Hotkeys
-- ===========================================================================
local m_actionHotkeyStartGame		:number = Input.GetActionId("StartGame");
local m_actionHotkeyStartGameAlt	:number = Input.GetActionId("StartGameAlt");



-- ===========================================================================
--	CONSTANTS
-- ===========================================================================

local DARKEN_AMOUNT			:number = -25;
local MIN_BLACK_Y			:number = 2;	-- Minimum size for black boxes on row bars
local SIZE_BUILDING_ICON	:number = 32;
local SIZE_CIV_LOGO_ICON	:number = 256;	-- Size of the logo in the background
local SIZE_UNIT_ICON		:number = 32;
local TIMEOUT_LOAD			:number = 1000;	-- # of frames before a timeout occurs obtaining player data for load screen


-- ===========================================================================
--	MEMBERS / VARIABLES
-- ===========================================================================
local m_isLoadComplete				:boolean = false;
local m_isResyncLoad				:boolean = false;
local m_isTraitsFullDescriptions	:boolean = false;



-- ===========================================================================
--	FUNCTIONS
-- ===========================================================================

-- ===========================================================================
function OnActivateButtonClicked()
	Controls.BackgroundImage:UnloadTexture();
	Controls.Portrait:UnloadTexture();
	Events.LoadScreenClose();
	UI.PlaySound("STOP_SPEECH_DAWNOFMAN");
	UI.StartStopMenuMusic(false);
	UI.PlaySound("Game_Begin_Button_Click");
	UI.PlaySound("Set_View_3D");
	UIManager:DequeuePopup( ContextPtr );

	Input.SetActiveContext( InputContext.World );

	if(UILens.IsPlayerLensSetToActive()) then
		UILens.SetActive("Default");
	end

    UI.SetExitOnClose(false);

	-- In PlayByCloud, we should trigger another cloud notification check now.  
	-- This will ensure the player gets a notification for the next cloud match so they can daisy chain all their turns quickly.
	if(GameConfiguration.IsPlayByCloud()) then
		local kandoConnected = FiraxisLive.IsFiraxisLiveLoggedIn();
		if(kandoConnected) then
			FiraxisLive.CheckForCloudNotifications();
		end
	end
end

-- ===========================================================================
--	Input Processing
-- ===========================================================================
function OnInput( uiMsg, wParam, lParam )
    if uiMsg == KeyEvents.KeyUp then
        if wParam == Keys.VK_ESCAPE then
			if m_isLoadComplete then
				OnActivateButtonClicked();
				return true;
			end
        end
    end
    return false;	-- Don't consume all; let hotkey action system get a crack
end

-- ===========================================================================
--	Hotkey
-- ===========================================================================
function OnInputActionTriggered( actionId:number )
	if	actionId == m_actionHotkeyStartGame		or
		actionId == m_actionHotkeyStartGameAlt	then
		if m_isLoadComplete then
			OnActivateButtonClicked();
		end
	end		

end

-- ===========================================================================
function RegisterButtonCallbacks()
	Controls.ActivateButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end );
	Controls.ActivateButton:RegisterCallback( Mouse.eLClick, OnActivateButtonClicked );
	Controls.StartLabelButton:RegisterCallback( Mouse.eLClick, OnActivateButtonClicked );
end

-- ===========================================================================
function ClearButtonCallbacks()
	Controls.ActivateButton:ClearCallback( Mouse.eLClick );
	Controls.ActivateButton:ClearCallback( Mouse.eMouseEnter );
	Controls.StartLabelButton:ClearCallback( Mouse.eLClick );
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnShow()
	
	m_isLoadComplete	= false;
	m_isResyncLoad		= UI.IsResyncLoadInProgress(); -- Remember if this is a resync load for later.

	UIManager:SetUICursor( 1 );
	Controls.FadeAnim:SetToBeginning();	
	Controls.ActivateButton:SetHide(true);	
	Controls.LoadingContainer:SetHide(false);

	-- Wait until game configuration data is ready before showing anything.
	Controls.BackgroundImage:SetHide(true);
	Controls.Banner:SetHide(true);
	Controls.Portrait:SetHide(true);
	
	-- Clear button callbacks until loading is complete.
	ClearButtonCallbacks();

	-- Signal to a potentially raised state transition context that we're up (so it can hide).
	LuaEvents.Lower_State_Transition("LoadScreen");
end

-- ===========================================================================
--	UI Event
-- ===========================================================================
function OnHide()
	UIManager:SetUICursor( 0 );
end

-- ===========================================================================
function OnInit( isReload:boolean )
	if isReload then		
		OnShow();
		OnLoadScreenContentReady();
		OnLoadGameViewStateDone();
	end
end

-- ===========================================================================
--	All game data exists for the player in order to fill out the screen.
--	Do it...
-- ===========================================================================
function OnLoadScreenContentReady()

	if (GameConfiguration:IsWorldBuilderEditor()) then
		-- This needs to show some kind of World Builder splash screen.
		-- It can't show leaders, etc., they may not be initialized.
		return;
	end

	-- Because Game.GetLocalPlayer() not servicing yet use the network flavor;
	-- if in a hotseat mode the first slot may not be set to the human.
	local localPlayer	:number = Network.GetLocalPlayerID();
	if GameConfiguration.IsHotseat() then

		local maxPlayers :number = MapConfiguration.GetMaxMajorPlayers();
		for playerID = 0, maxPlayers-1,1 do
			local pPlayerConfig :table	= PlayerConfigurations[playerID];
			local slotStatus	:number = pPlayerConfig:GetSlotStatus();
			
			-- Potentially change the localPlayer number to the first human
			-- player in a slot.
			if slotStatus == SlotStatus.SS_TAKEN then
				localPlayer = playerID;	
				break;
			end
		end	
	end	

	local primaryColor, secondaryColor  = UI.GetPlayerColors( localPlayer );

	if primaryColor == nil then
		primaryColor = UI.GetColorValueFromHexLiteral(0xff99aaaa);
		UI.DataError("NIL primary color; likely player object not ready... using default color.");
	end
	if secondaryColor == nil then
		secondaryColor = UI.GetColorValueFromHexLiteral(0xffaa9999);
		UI.DataError("NIL secondary color; likely player object not ready... using default color.");
	end

	local backColor						= UI.DarkenLightenColor(primaryColor, DARKEN_AMOUNT, 255);
	Controls.Banner:SetColor(backColor);
	
	local playerConfig		:table = PlayerConfigurations[localPlayer];
	if playerConfig == nil then
		UI.DataError("Received NIL playerConfig for player #"..tostring(localPlayer));
	else
		local backgroundTexture:string;
		local leaderType:string = playerConfig:GetLeaderTypeName();
		local loadingInfo:table = GameInfo.LoadingInfo[leaderType];
		if loadingInfo and loadingInfo.BackgroundImage then
			backgroundTexture = loadingInfo.BackgroundImage;
		else
			backgroundTexture = leaderType .. "_BACKGROUND";
		end
	
		Controls.BackgroundImage:SetTexture( backgroundTexture );
		if (not Controls.BackgroundImage:HasTexture()) then
			UI.DataError("Failed to load background image texture: "..backgroundTexture);
			Controls.BackgroundImage:SetTexture("LEADER_T_ROOSEVELT_BACKGROUND");	-- Set to well known texture
		end

		-- fix 720P
		if (Controls.Background:GetSizeY() < 768) then
			Controls.Banner:SetSizeY(920);
			Controls.MainStack:SetOffsetY(20);
		else
			Controls.Banner:SetSizeY(987);
			Controls.MainStack:SetOffsetY(0);
		end

		local LEADER_CONTAINER_X = 512;
		local offsetX = math.floor((Controls.Portrait:GetSizeX() - LEADER_CONTAINER_X)/2);
		if (offsetX > 0) then
			Controls.Portrait:SetOffsetX(offsetX);
		else
			Controls.Portrait:SetOffsetX(0);
		end

		local portraitName:string;
		if loadingInfo and loadingInfo.ForegroundImage then
			portraitName = loadingInfo.ForegroundImage;
		else
			portraitName = leaderType .. "_NEUTRAL";
		end
	
		Controls.Portrait:SetTexture( portraitName );
		if (not Controls.Portrait:HasTexture()) then
			UI.DataError("We are lacking a texture for "..portraitName);
		end
		Controls.CivName:SetText( Locale.ToUpper( Locale.Lookup(playerConfig:GetCivilizationDescription())) );

	
		local eraInfoText;
		local leaderInfoText;

		local startEra = GameInfo.Eras[ GameConfiguration.GetStartEra() ];
		if (GameConfiguration.IsSavedGame()) then
			-- Returns a list of 1 entry...
			local metaData = UI.GetSaveGameMetaData();
			if(metaData and #metaData == 1) then
				local item = metaData[1];
				local saveEra = GameInfo.Eras[ item.HostEra ];
				if(saveEra) then
					startEra = saveEra;
				end
			end
		end

		if (startEra ~= nil) then
			eraInfoText = startEra.Description;
		end

		local challengeName;
		local challengeInfoText;

		local isChallengeActive = Challenges.IsChallengeActive();
		if isChallengeActive then
			challengeName = Challenges.GetLocalizedChallengeNameText();
			challengeInfoText = Challenges.GetLocalizedChallengeLoadingScreenDescriptionText();
		end

		local kLeader	:table = GameInfo.Leaders[leaderType];
		local leaderName;
		if kLeader ~= nil then
			leaderName = Locale.ToUpper(Locale.Lookup( kLeader.Name ));

			local details = "LOC_LOADING_INFO_" .. leaderType;
			if(Locale.HasTextKey(details)) then
				leaderInfoText = details;
			end
		else
			UI.DataError("No leader in DB by leaderType '"..leaderType.."'");
		end

		if(challengeName) then
			Controls.LeaderName:SetText(challengeName);
		elseif(leaderName) then
			Controls.LeaderName:SetText(leaderName);
		else
			UI.DataError("No proper text for the LeaderName field");
		end
	
		if(loadingInfo) then
			if(loadingInfo.EraText) then
				eraInfoText = loadingInfo.EraText;
			end

			if(loadingInfo.LeaderText) then
				leaderInfoText = loadingInfo.LeaderText;
			end
		end

		if (eraInfoText) then
			Controls.EraInfo:LocalizeAndSetText(eraInfoText);
			Controls.EraInfo:SetHide(false);
		else
			Controls.EraInfo:SetHide(true);
		end

		if(challengeInfoText) then
			Controls.LeaderInfo:SetText(challengeInfoText);
			Controls.LeaderInfo:SetHide(false);
		elseif(leaderInfoText) then
			Controls.LeaderInfo:LocalizeAndSetText(leaderInfoText);
			Controls.LeaderInfo:SetHide(false);
		else
			Controls.LeaderInfo:SetHide(true);
		end

		local civType	:string = playerConfig:GetCivilizationTypeName();
		local iconName	:string = "ICON_"..civType;
		Controls.LogoContainer:SetColor(primaryColor);
		Controls.Logo:SetColor(secondaryColor);
		Controls.Logo:SetIcon(iconName);

		Controls.Logo:SetHide(false);
		Controls.BackgroundImage:SetHide(false);
		Controls.Banner:SetHide(false);
		Controls.Portrait:SetHide(false);

		-- Find center of remaining space to right of ribbon, portrait will center it's texture on that.
		local ribbonRunsPastCenter:number = 80;
		local screenWidth, screenHeight = UIManager:GetScreenSizeVal();
		local backgroundWidth, backgroundHeight = Controls.BackgroundImage:GetSizeVal();
		local minWidth = math.min(backgroundWidth, screenWidth);
		Controls.PortraitContainer:SetSizeX( (minWidth*0.5) - ribbonRunsPastCenter );

		-- start the voiceover
		local leaderID = playerConfig:GetLeaderTypeID();
		local bPlayDOM = true;

		if(loadingInfo) then
			bPlayDOM = loadingInfo.PlayDawnOfManAudio;
		end

		if (m_isResyncLoad) then
			bPlayDOM = false;
		end

		if bPlayDOM then
			local dawnOfManLeaderID = leaderID;
			local dawnOfManEraHash = startEra.Hash;

			if(loadingInfo and loadingInfo.DawnOfManLeaderId) then
				dawnOfManLeaderID = loadingInfo.DawnOfManLeaderId;	
			end

			if(loadingInfo and loadingInfo.DawnOfManEraId) then
				dawnOfManEraHash = DB.MakeHash(loadingInfo.DawnOfManEraId);
			end

			if (Challenges.IsChallengeActive()) then
				-- Don't play leader/civilization for challenge games as those have the text missing.
				-- Setting this to the "NO_LEADER" values will cause sound not to play
				-- and override any stale values for the switch.
				dawnOfManLeaderID = -1;
			end

			UI.SetSoundSwitchValue("Leader_Screen_Civilization", UI.GetCivilizationSoundSwitchValueByLeader(dawnOfManLeaderID));
			UI.SetSoundSwitchValue("Civilization", UI.GetCivilizationSoundSwitchValueByLeader(dawnOfManLeaderID));
			UI.SetSoundSwitchValue("Era_DawnOfMan", UI.GetEraSoundSwitchValue(dawnOfManEraHash));
			UI.PlaySound("Play_DawnOfMan_Speech");
		end

		-- Obtain "uniques" from Civilization and for the chosen leader
		local uniqueAbilities;
		local uniqueUnits;
		local uniqueBuildings;
		uniqueAbilities, uniqueUnits, uniqueBuildings = GetLeaderUniqueTraits( leaderType );
		local CivUniqueAbilities, CivUniqueUnits, CivUniqueBuildings = GetCivilizationUniqueTraits( civType );
	
		-- Merge tables
		for i,v in ipairs(CivUniqueAbilities)	do table.insert(uniqueAbilities, v) end
		for i,v in ipairs(CivUniqueUnits)		do table.insert(uniqueUnits, v)		end
		for i,v in ipairs(CivUniqueBuildings)	do table.insert(uniqueBuildings, v) end

		-- Generate content
		for _, item in ipairs(uniqueAbilities) do
			--print( "ua:", item.TraitType, item.Name, item.Description, Locale.Lookup(item.Description));	--debug
			local instance:table = {};
			ContextPtr:BuildInstanceForControl("TextInfoInstance", instance, Controls.FeaturesStack );
			if (item.Name ~= nil and item.Name ~= "NONE") then
				local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name )); 
				instance.Header:SetText( headerText );
			else
				instance.Header:SetShow(false);
			end

			if (item.Description ~= nil and item.Description ~= "NONE") then
				instance.Description:SetText( Locale.Lookup( item.Description ) );
			else
				instance.Description:SetShow(false);
			end
		end

		local size:number = SIZE_BUILDING_ICON;

		for _, item in ipairs(uniqueUnits) do
			--print( "uu:", item.TraitType, item.Name, item.Description, Locale.Lookup(item.Description));	--debug
			local instance:table = {};
			ContextPtr:BuildInstanceForControl("IconInfoInstance", instance, Controls.FeaturesStack );
			iconAtlas = "ICON_"..item.Type;
			instance.Icon:SetIcon(iconAtlas);
			instance.TextStack:SetOffsetX( size + 4 );
			local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name ));
			instance.Header:SetText( headerText );
			instance.Description:SetText(Locale.Lookup(item.Description));
		end


		for _, item in ipairs(uniqueBuildings) do
			--print( "ub:", item.TraitType, item.Name, item.Description, Locale.Lookup(item.Description));	--debug
			local instance:table = {};
			ContextPtr:BuildInstanceForControl("IconInfoInstance", instance, Controls.FeaturesStack );
			instance.Icon:SetSizeVal(38,38);
			iconAtlas = "ICON_"..item.Type;
			instance.Icon:SetIcon(iconAtlas);
			instance.TextStack:SetOffsetX( size + 4 );
			local headerText:string = Locale.ToUpper(Locale.Lookup( item.Name ));
			instance.Header:SetText( headerText );
			instance.Description:SetText(Locale.Lookup(item.Description));
		end
	end
end

-- ===========================================================================
-- ENGINE Event
-- ===========================================================================
function OnBeforeMultiplayerInviteProcessing()
	-- We're about to process a game invite.  Get off the popup stack before we accidently break the invite!
	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
--	ENGINE Event
-- ===========================================================================
function OnLoadGameViewStateDone()
	
	m_isLoadComplete = true;	
	print("OnLoadGameViewStateDone");
	
	UIManager:SetUICursor( 0 );	
	
	if m_isResyncLoad or GameConfiguration.IsAnyMultiplayer() or GameConfiguration:IsWorldBuilderEditor() then
		-- If this is a resync load, skip the Begin Game button.
		OnActivateButtonClicked();
	else
		-- Activate the Begin Game button.
		local strGameButtonName;


		if (GameConfiguration.IsSavedGame()) then
			strGameButtonName = Locale.Lookup("LOC_CONTINUE_GAME");		
		else
			strGameButtonName = Locale.Lookup("LOC_BEGIN_GAME");
		end

		Controls.StartLabelButton:SetText(strGameButtonName);
		Controls.ActivateButton:SetHide(false);
		Controls.LoadingContainer:SetHide(true);
		Controls.FadeAnim:SetToBeginning();
		Controls.FadeAnim:Play();
		UI.PlaySound("Game_Begin_Button_Appear");
        		
		Input.SetActiveContext( InputContext.Ready );

		-- If automation is running, continue on.
		if (Automation.IsAutoStartEnabled()) then
			OnActivateButtonClicked();
		end
	end    
	
	RegisterButtonCallbacks();

	-- Engine loading should be done at this point; enable input handling.	
	ContextPtr:SetInputHandler( OnInput );
	Events.InputActionTriggered.Add( OnInputActionTriggered );
end

-- ===========================================================================
function Initialize()

	Input.SetActiveContext( InputContext.Loading );

	-- EVENTS:
	ContextPtr:SetInitHandler( OnInit );
	-- Do not set input handler until content loading is done; otherwise engine will make LUA calls to engine during load (not recommended).
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );	

	Events.LoadScreenContentReady.Add( OnLoadScreenContentReady );		-- Ready to show player info
	Events.LoadGameViewStateDone.Add( OnLoadGameViewStateDone );		-- Ready to start game
	Events.BeforeMultiplayerInviteProcessing.Add( OnBeforeMultiplayerInviteProcessing );

    UI.SetExitOnClose(true);
end
--#Accessibility integration
include("caiUtils")
include("CAIUIScreenManager") -- self-runs UIScreenManager:Init() and populates ExposedMembers.CAI_UIManager
local mgr = ExposedMembers.CAI_UIManager
local m_CAIPanel = nil
local m_PanelId = "CAILoadScreenPanel"
local m_CAIList = nil
local m_ListId = "CAILoadScreenList"

local m_startBtn = nil

local function PopulateList()
	if not m_CAIList then return end
	m_CAIList:ClearChildren()
m_CAIList:AddChild(mgr:CreateWidget("LeaderCivInfo", "StaticText", {
	Label = function() return Controls.LeaderName:GetText() .. ", " .. Controls.CivName:GetText() end
}))
	local localPlayer = Network.GetLocalPlayerID()
	if GameConfiguration.IsHotseat() then
		local maxPlayers = MapConfiguration.GetMaxMajorPlayers()
		for playerID = 0, maxPlayers - 1 do
			local pPlayerConfig = PlayerConfigurations[playerID]
			if pPlayerConfig:GetSlotStatus() == SlotStatus.SS_TAKEN then
				localPlayer = playerID
				break
			end
		end
	end

	local playerConfig = PlayerConfigurations[localPlayer]
	if not playerConfig then return end

	local leaderType = playerConfig:GetLeaderTypeName()
	local civType = playerConfig:GetCivilizationTypeName()

	local uniqueAbilities, uniqueUnits, uniqueBuildings = GetLeaderUniqueTraits(leaderType)
	local civAbilities, civUnits, civBuildings = GetCivilizationUniqueTraits(civType)
	for _, v in ipairs(civAbilities) do table.insert(uniqueAbilities, v) end
	for _, v in ipairs(civUnits) do table.insert(uniqueUnits, v) end
	for _, v in ipairs(civBuildings) do table.insert(uniqueBuildings, v) end

	local function AddFeature(item)
		local parts = {}
		if item.Name and item.Name ~= "NONE" then
			table.insert(parts, Locale.Lookup(item.Name))
		end
		if item.Description and item.Description ~= "NONE" then
			table.insert(parts, Locale.Lookup(item.Description))
		end
		if #parts > 0 then
			local text = table.concat(parts, ", ")
			m_CAIList:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAILoadScreenFeature"), "StaticText", {
				Label = function() return text end,
			}))
		end
	end

	for _, item in ipairs(uniqueAbilities) do AddFeature(item) end
	for _, item in ipairs(uniqueUnits) do AddFeature(item) end
	for _, item in ipairs(uniqueBuildings) do AddFeature(item) end
	m_CAIList:AddChild(mgr:CreateWidget("EraInfo", "StaticText", {
	Label = function() return Controls.EraInfo:GetText() end,
	HiddenPredicate = function() return Controls.EraInfo:IsHidden() end
}))
m_CAIList:AddChild(mgr:CreateWidget("LeaderInfo", "StaticText", {
	Label = function() return Controls.LeaderInfo:GetText() end,
	HiddenPredicate = function() return Controls.LeaderInfo:IsHidden() end
}))
end

local function BuildPanel()
	if not mgr then return end
	m_CAIPanel = mgr:CreateWidget(m_PanelId, "Panel", {
		Label = function() return Controls.FallbackMessage:GetText() end,
	})
	m_CAIList = mgr:CreateWidget(m_ListId, "List", {
		Label = function() return Locale.Lookup("LOC_LOADING_FEATURES_ABILITIES") end,
	})
	m_startBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAILoadScreenStart"), "Button", {
		Label = function() return Controls.StartLabelButton:GetText() end,
		HiddenPredicate = function() return Controls.ActivateButton:IsHidden() end,
	})
	m_startBtn:On("activate", function()
		Controls.ActivateButton:DoLeftClick()
	end)
	m_CAIPanel:AddChild(m_CAIList)
	m_CAIPanel:AddChild(m_startBtn)
end

local function ClosePanel()
	if m_CAIPanel then
		mgr:RemoveFromStack(m_CAIPanel:GetId())
	end
end

function OnInputHandler( pInputStruct)
	if mgr then
		if mgr:HandleInput(pInputStruct) then return true end
	end
    if pInputStruct:GetMessageType() == KeyEvents.KeyUp then
        if pInputStruct:GetKey() == Keys.VK_ESCAPE then
			if m_isLoadComplete then
				OnActivateButtonClicked()
				return true
			end
        end
    end
    return false
end

Events.LoadScreenContentReady.Remove(OnLoadScreenContentReady)
OnLoadScreenContentReady = WrapFunc(OnLoadScreenContentReady, function(orig, ...)
	orig(...)
	ContextPtr:SetInputHandler(OnInputHandler, true)
	if not m_CAIPanel or mgr:GetTop() ~= m_CAIPanel then
	BuildPanel()
	PopulateList()
	mgr:Push(m_CAIPanel, { focus = m_CAIList })
	end
end)
Events.LoadScreenContentReady.Add(OnLoadScreenContentReady)

OnActivateButtonClicked = WrapFunc(OnActivateButtonClicked, function(orig)
	mgr:ShutDown()
	orig()
end)
local spokeReady = false
Events.LoadGameViewStateDone.Remove(OnLoadGameViewStateDone)
OnLoadGameViewStateDone = WrapFunc(OnLoadGameViewStateDone, function(orig, ...)
	orig(...)
	if not spokeReady then
	Speak(Locale.Lookup("LOC_READY_LABEL"))
	if m_CAIPanel then
		m_CAIPanel:SetLabel(function() return Locale.Lookup("LOC_READY_LABEL") end)
		end
		spokeReady = true
	end
	RegisterButtonCallbacks();
	ContextPtr:SetInputHandler(OnInputHandler, true)
end)
Events.LoadGameViewStateDone.Add(OnLoadGameViewStateDone)


OnHide = WrapFunc(OnHide, function(orig, ...)
	ClosePanel()
	orig(...)
end)
ContextPtr:SetHideHandler(OnHide)
--#End of accessibility integration
Initialize();