include( "InstanceManager" );
include( "SupportFunctions" );

-- Shared code between the LoadGameMenu and the SaveGameMenu
include( "LoadSaveMenu_Shared" );

local RELOAD_CACHE_ID: string = "SaveGameMenu";		-- hotloading
local MIN_SCREEN_Y   : number = 768;
g_IsDeletingFile = false;

----------------------------------------------------------------        
----------------------------------------------------------------        
function OnBack()
    UIManager:DequeuePopup( ContextPtr );
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnActionButton()
	if (g_iSelectedFileEntry == -1) then
		local fileName = Controls.FileName:GetText();
		for i, v in ipairs(g_FileList) do
			local displayName = GetDisplayName(v); 
			if(Locale.Length(displayName) > 0) then
				if(Locale.ToUpper(fileName) == Locale.ToUpper(displayName)) then
					SetSelected(i);
					break;
				end
			end
		end
	end
	
	if(g_iSelectedFileEntry ~= -1) then
		g_IsDeletingFile = false;

		-- A file is selected, if it is a directory, go into it, else confirm overwrite.
		local selectedFile = g_FileList[ g_iSelectedFileEntry ];
		if selectedFile ~= nil then
			if selectedFile.IsDirectory then
				-- Open the directory
				ChangeDirectoryTo(selectedFile.Path);
				return;
			else
				Controls.DeleteHeader:SetText(Locale.ToUpper( "LOC_CONFIRM_TITLE_TXT" ));
				Controls.Message:LocalizeAndSetText( "LOC_OVERWRITE_TXT" );
				Controls.DeleteConfirm:SetHide(false);
				return;
			end
		end

	else
		local gameFile = {};
		gameFile.Name = Controls.FileName:GetText();
		if(g_ShowCloudSaves) then
			gameFile.Location = UI.GetDefaultCloudSaveLocation();
		else
			gameFile.Location = SaveLocations.LOCAL_STORAGE;
			-- If it is a WorldBuilder map, allow for a specific path.
			if g_GameType == SaveTypes.WORLDBUILDER_MAP then
				gameFile.Path = g_CurrentDirectoryPath .. "/" .. gameFile.Name ;
			end
		end
		gameFile.Type = g_GameType;
		gameFile.FileType = g_FileType;
		UIManager:SetUICursor( 1 );
		Network.SaveGame(gameFile);
		UIManager:SetUICursor( 0 );
		UI.PlaySound("Confirm_Bed_Positive");
	end
	
	Controls.FileName:ClearString();
	SetupFileList();
	OnBack();
end
 

----------------------------------------------------------------        
function OnFileNameChange( fileNameEntry )
	
	if( g_iSelectedFileEntry ~= -1 ) then
		local kSelectedFile = g_FileList[ g_iSelectedFileEntry ];
		local displayName = GetDisplayName(kSelectedFile); 
		if (fileNameEntry:GetText() ~= displayName) then
			DismissCurrentSelected();
		end
	end
	
	local fileName = "";
	if(fileNameEntry:GetText() ~= nil) then
		fileName = fileNameEntry:GetText();
	end

	g_FilenameIsValid = ValidateFileName(fileName);

	UpdateActionButtonState();
	Controls.Delete:SetHide(true); 
	
end

----------------------------------------------------------------        
----------------------------------------------------------------
function OnCloudCheck( )
	local bWantShowCloudSaves = not g_ShowCloudSaves;

	if (bWantShowCloudSaves) then
		-- Make sure we can switch to it.
		if (not CanShowCloudSaves()) then
			return;
		end
	end

	g_ShowCloudSaves = bWantShowCloudSaves;
	Controls.CloudCheck:SetSelected(g_ShowCloudSaves);
    SetDontUpdateFileName(true);
	SetupDirectoryBrowsePulldown();
	SetupFileList();
	UpdateActionButtonState();
    SetDontUpdateFileName(false);
end


---------------------------------------------------------------- 
-- Show/Hide Handlers
---------------------------------------------------------------- 
function OnShow()

	g_ShowCloudSaves = false;
	g_ShowAutoSaves = false;

	LoadSaveMenu_OnShow();

	g_MenuType = SAVE_GAME;
	UpdateGameType();
	Controls.Delete:SetHide( true );
	Controls.ActionButton:SetDisabled( true );
	Controls.ActionButton:SetToolTipString( nil );

	InitializeDirectoryBrowsing();
	RefreshSortPulldown();
	SetupDirectoryBrowsePulldown();
	SetupFileList();
		
	Controls.CloudCheck:SetSelected(false);

	g_FilenameIsValid = ValidateFileName( Controls.FileName:GetText() );

	UpdateActionButtonState();

	local cloudServicesEnabled,cloudServicesResult = UI.AreCloudSavesEnabled("SAVE");
	local cloudEnabled = UI.AreCloudSavesEnabled() and not GameConfiguration.IsAnyMultiplayer() and g_FileType ~= SaveFileTypes.GAME_CONFIGURATION and g_GameType ~= SaveTypes.WORLDBUILDER_MAP;
	Controls.CloudCheck:SetHide(false);
	Controls.CloudCheck:SetEnabled(cloudEnabled);

    local isNew = Options.GetAppOption("Misc", "UserSawCloudNew");
	Controls.CheckNewIndicator:SetHide(true);
	Controls.DummyNewIndicator:SetHide(true);

	if cloudEnabled == false then
		if cloudServicesResult ~= nil then
			if cloudServicesResult == DB.MakeHash("REQUIRES_LINKED_ACCOUNT") then
				Controls.CloudCheck:LocalizeAndSetToolTip("LOC_CLOUD_SAVES_REQUIRE_LINKED_ACCOUNT");
			else
				Controls.CloudCheck:LocalizeAndSetToolTip("LOC_CLOUD_SAVES_SERVICE_NOT_CONNECTED");
			end
		end
        if (isNew == 0) then
            Controls.CheckNewIndicator:SetHide(false);
        end

		if g_GameType == SaveTypes.WORLDBUILDER_MAP or g_FileType == SaveFileTypes.GAME_CONFIGURATION then
			Controls.CloudCheck:SetHide(true);
		else
			Controls.CloudCheck:SetHide(false);
		end
	else
		if UI.Is2KCloudAvailable() then
			Controls.CloudCheck:SetToolTipString(Locale.Lookup("LOC_2K_CLOUD_SAVES_HELP"));
			Controls.CloudCheck:SetText(Locale.Lookup("LOC_2K_CLOUD"));
			Controls.CloudDummy:SetHide(true);
			if (isNew == 0) then
				Controls.CheckNewIndicator:SetHide(false);
			end
		else
			Controls.CloudDummy:SetHide(false);
			Controls.CloudDummy:SetDisabled(true);
			Controls.CloudDummy:SetToolTipString(Locale.Lookup("LOC_2K_CLOUD_SAVES_HELP"));
			Controls.CloudCheck:SetToolTipString(Locale.Lookup("LOC_STANDARD_CLOUD_SAVES_HELP"));
			if (isNew == 0) then
				Controls.DummyNewIndicator:SetHide(false);
			end
		end
	end

    if (isNew == 0) then
        Options.SetAppOption("Misc", "UserSawCloudNew", 1);
    end

	local cloudSavesVisible = Controls.CloudCheck:IsVisible();
	local sortByVisible = Controls.SortByPullDown:IsVisible();
	local directoryVisible = Controls.DirectoryPullDown:IsVisible();
    local dummyCloudVisible = Controls.CloudDummy:IsVisible();

	local count:number = 0;
	if(cloudSavesVisible) then
		count = count + 1;
	end
	if(sortByVisible) then
		count = count + 1;
	end
	if(directoryVisible) then
		count = count + 1;
	end
	if(dummyCloudVisible) then
		count = count + 1;
	end		
	
	Controls.FileName:TakeFocus();
	
	local decoSize:number = Controls.InspectorArea:GetSizeY();

	Controls.DecoContainer:SetSizeY(decoSize - (count * 25) - count);	

	if g_GameType == SaveTypes.WORLDBUILDER_MAP then
		Controls.GameDetailIconsArea:SetHide(true);
	else
		Controls.GameDetailIconsArea:SetHide(false);
	end
end
----------------------------------------------------------------        
function OnHide()
	LoadSaveMenu_OnHide();
end

function OnDelete()
	g_IsDeletingFile = true;
	Controls.DeleteHeader:SetText( Locale.ToUpper(Locale.Lookup("LOC_CONFIRM_DELETE_TITLE_TXT")));
	Controls.Message:LocalizeAndSetText( "LOC_CONFIRM_TXT" );
	Controls.DeleteConfirm:SetHide(false);
	Controls.DeleteConfirmAlpha:SetToBeginning();
	Controls.DeleteConfirmAlpha:Play();
	Controls.DeleteConfirmSlide:SetToBeginning();
	Controls.DeleteConfirmSlide:Play();
end    
----------------------------------------------------------------
function OnYes()
	Controls.DeleteConfirm:SetHide(true);

	if (g_iSelectedFileEntry ~= -1) then
		local kSelectedFile = g_FileList[ g_iSelectedFileEntry ];		
		if(g_IsDeletingFile) then
			UI.DeleteSavedGame( kSelectedFile );
		else
			UI.PlaySound("Confirm_Bed_Positive");

			if(g_ShowCloudSaves) then
				local gameFile = {};
				gameFile.Name = Controls.FileName:GetText();
				gameFile.Location = UI.GetDefaultCloudSaveLocation();
				gameFile.LocationIndex = g_iSelectedFileEntry;
				gameFile.Type = g_GameType;
				gameFile.FileType = g_FileType;
				UIManager:SetUICursor( 1 );
				Network.SaveGame(gameFile);
				UIManager:SetUICursor( 0 );
			else
				Network.SaveGame( kSelectedFile );
			end

			OnBack();
		end
	end
	
	SetupFileList();
	Controls.FileName:ClearString();
	Controls.ActionButton:SetDisabled(true);
end       
----------------------------------------------------------------
function OnNo( )
	Controls.DeleteConfirm:SetHide(true);
	Controls.MainGrid:SetHide(false);
end


-- ===========================================================================
--	Input Processing
-- ===========================================================================
function KeyHandler( key:number )
	if (key == Keys.VK_ESCAPE) then
		if(not Controls.DeleteConfirm:IsHidden()) then
			OnNo();
		else
			OnBack(); 
		end
		return true;
	end	
	if key == Keys.VK_RETURN then
        if(not Controls.ActionButton:IsHidden() and not Controls.ActionButton:IsDisabled()) then
            OnActionButton();
        end
        return true;
	end
	return false;
end
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
	if uiMsg == KeyEvents.KeyUp then KeyHandler( pInputStruct:GetKey() ); end;
    return true;
end


-- ===========================================================================
function OnInit(isReload:boolean)
	if isReload then
		LuaEvents.GameDebug_GetValues( RELOAD_CACHE_ID );
	end
end

-- ===========================================================================
function OnShutdown()
	-- Cache values for hotloading...
	LuaEvents.GameDebug_AddValue(RELOAD_CACHE_ID, "isHidden", ContextPtr:IsHidden());
end

-- ===========================================================================
function OnGameDebugReturn( context:string, contextTable:table )
	if context == RELOAD_CACHE_ID and contextTable["isHidden"] == false then
		UIManager:QueuePopup(ContextPtr, PopupPriority.Current);
	end	
end

-- ===========================================================================
--	Handle Window Sizing
-- ===========================================================================

function Resize()
	local screenX, screenY:number  = UIManager:GetScreenSizeVal();
	local hideLogo        :boolean = true;
	
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		Controls.MainWindow:SetSizeY(screenY-(Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY() * 2));
		hideLogo = false;
	else
		Controls.MainWindow:SetSizeY(screenY);
	end
	
	Controls.LogoContainer:SetHide(hideLogo);
	Controls.DeleteConfirm:SetSizeVal(screenX,screenY);
	Controls.DeleteConfirm:ReprocessAnchoring();
end

-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
    Resize();
  end
end

-- ===========================================================================
function OnFileListQueryComplete()
	UpdateActionButtonState();
end

-- ===========================================================================
function OnRefresh()
	SetupDirectoryBrowsePulldown();
	SetupFileList();
end

-- ===========================================================================
function OnSelectedFileStackSizeChanged()
	ResizeGameInfoScrollPanel();
end

-- ===========================================================================
function Initialize()
	ContextPtr:SetInitHandler(OnInit);
	ContextPtr:SetShutdown(OnShutdown);
	LuaEvents.GameDebug_Return.Add(OnGameDebugReturn);
	SetupSortPulldown();
	InitializeDirectoryBrowsing();
	Resize();

	LuaEvents.FileListQueryComplete.Add( OnFileListQueryComplete );

	Controls.ActionButton:RegisterCallback( Mouse.eLClick, OnActionButton );
	Controls.ActionButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnBack );
	Controls.BackButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CloudCheck:RegisterCallback( Mouse.eLClick, OnCloudCheck );
	Controls.FileName:RegisterStringChangedCallback( OnFileNameChange )
	Controls.No:RegisterCallback( Mouse.eLClick, OnNo );
	Controls.No:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.Yes:RegisterCallback( Mouse.eLClick, OnYes );
	Controls.Yes:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.Delete:RegisterCallback( Mouse.eLClick, OnDelete );
	Controls.Delete:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.SelectedFileStack:RegisterSizeChanged( OnSelectedFileStackSizeChanged );

	Events.SystemUpdateUI.Add( OnUpdateUI );

	-- UI Events
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
	ContextPtr:SetInputHandler( OnInputHandler, true );
	ContextPtr:SetRefreshHandler( OnRefresh );

end
--#Accessibility integration
include("caiUtils")
mgr = ExposedMembers.CAI_UIManager
include("LoadSaveHelpers_CAI")


local CAI_Panel = nil
local CAI_SaveTree = nil
local CAI_DirList = nil
local CAI_DirDropdown = nil
local CAI_SortDropdown = nil
local CAI_ConfirmDialog = nil
local CAI_LoadingFiles = false


local function ClosePanel()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
        CAI_Panel = nil
	end
    CAI_LoadingFiles = false
    CAI_SaveTree = nil
    CAI_DirList = nil
    CAI_DirDropdown = nil
    CAI_SortDropdown = nil
end

-- ---------------------------------------------------------------------------
-- Rebuild the accessible file tree / directory list
-- ---------------------------------------------------------------------------
local function RebuildFileListAccessibility()
    if not CAI_Panel then return end

    local dirView = IsDirectoryView()

    if CAI_SaveTree then
        CAI_SaveTree:SetHiddenPredicate(function() return dirView end)
    end
    if CAI_DirList then
        CAI_DirList:SetHiddenPredicate(function() return not dirView end)
    end

    local container = dirView and CAI_DirList or CAI_SaveTree
    if not container then return end

    local capture = mgr:CaptureFocusKey(container)
    container:ClearChildren()

    if not g_FileList or #g_FileList == 0 then
        container:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveEmpty"), "MenuItem", {
            Label = function()
                if CAI_LoadingFiles then return Locale.Lookup("LOC_MULTIPLAYER_JOINING_ROOM_TITLE") end
				return Controls.NoGames:GetText() or ""
            end,
        }))
        mgr:RestoreFocus(container, capture)
        return
    end

    for idx, entry in ipairs(g_FileList) do
        if entry.IsDirectory then
            local child = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveDir"), "MenuItem", {
                Label = function() return GetEntryLabel(idx, entry) end,
                FocusKey = "savegame:file:" .. tostring(idx),
            })
            child:SetFocusSound("Main_Menu_Mouse_Over")
            child:On("activate", function()
                SetSelected(idx)
                OnActionButton()
            end)
            container:AddChild(child)
        else
            local mods = {}
            if g_FileType == SaveFileTypes.GAME_CONFIGURATION then
                mods = entry.EnabledMods or {}
            else
                mods = entry.RequiredMods or {}
            end
            local modErrors = Modding.CheckRequirements(mods, g_GameType)
            if entry.GameChallengeUuid and not Challenges.IsNullChallengeUuid(entry.GameChallengeUuid) then
                for _, v in ipairs(mods) do
                    if modErrors and modErrors[v.Id] == "NotAllowed" then
                        modErrors[v.Id] = nil
                    end
                end
            end
            local saveHasError = not (modErrors == nil or modErrors.Success)
            local errorModNames = {}
            if saveHasError and modErrors then
                for _, v in ipairs(mods) do
                    if modErrors[v.Id] then
                        local name = nil
                        local modHandle = Modding.GetModHandle(v.Id)
                        if modHandle then
                            local modInfo = Modding.GetModInfo(modHandle)
                            if modInfo and modInfo.Name then
                                name = Locale.Lookup(modInfo.Name)
                            end
                        end
                        if not name or name == "" then
                            name = LookupBundleOrText(v.Title)
                        end
                        if name and name ~= "" then
                            table.insert(errorModNames, name)
                        end
                    end
                end
            end

            local treeItem = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveSave"), "TreeItem", {
                Label = function() return GetEntryLabel(idx, entry) end,
                Tooltip = function()
                    local parts = {}
                    if saveHasError then
                        if #errorModNames > 0 then
                            table.insert(parts, Locale.Lookup("LOC_GAME_START_ERROR_TITLE") .. ": " .. table.concat(errorModNames, ", "))
                        else
                            table.insert(parts, Locale.Lookup("LOC_GAME_START_ERROR_TITLE"))
                        end
                    end
                    local leader = LookupBundleOrText(entry.HostLeaderName)
                    if leader ~= "" then table.insert(parts, leader) end
                    local civ = LookupBundleOrText(entry.HostCivilizationName)
                    if civ ~= "" then table.insert(parts, civ) end
                    if entry.CurrentTurn then
                        table.insert(parts, Locale.Lookup("LOC_LOADSAVE_CURRENT_TURN", entry.CurrentTurn))
                    end
                    local era = LookupBundleOrText(entry.HostEraName)
                    if era ~= "" then table.insert(parts, era) end
                    if entry.DisplaySaveTime and entry.DisplaySaveTime ~= "" then
                        table.insert(parts, entry.DisplaySaveTime)
                    end
                    return table.concat(parts, "[NEWLINE]")
                end,
                FocusKey = "savegame:file:" .. tostring(idx),
            })
            treeItem:On("activate", function()
                if g_iSelectedFileEntry ~= idx then
                    SetSelected(idx)
                end
                    CAI_FileNameEdit:SetText(Controls.FileName:GetText() or "", true)
                    mgr:SetFocus(CAI_FileNameEdit)
            end)

            PopulateTreeItemDetails(treeItem, entry)

            treeItem:AddInputBinding({
                Key = Keys.VK_DELETE,
                Description = "LOC_CAI_KB_DELETE_SAVE",
                Action = function()
                        SetSelected(idx)
                        Controls.Delete:DoLeftClick()
                        return true
                end
            })

            container:AddChild(treeItem)
        end
    end

    

    if CAI_DirDropdown then
        local options, selectedIdx = BuildDirectoryOptions()
        CAI_DirDropdown:SetOptions(options)
        if selectedIdx > 0 then
            CAI_DirDropdown:SetSelectedIndex(selectedIdx, true)
        end
    end
    mgr:RestoreFocus(container, capture)
end

-- ---------------------------------------------------------------------------
-- Build panel
-- ---------------------------------------------------------------------------
local function BuildPanel()
    CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveGameMenu"), "Panel", {
        Label = function() return (Controls.WindowHeader and Controls.WindowHeader:GetText()) end,
    })

    CAI_Panel:AddInputBindings({
    {
        Key = Keys.VK_RETURN,
        Description = "LOC_SAVE_GAME",
        Action = function()
            Controls.ActionButton:DoLeftClick()
            return true
        end
    }
})

    -- 1. Directory dropdown (hidden when not applicable)
    CAI_DirDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveDir"), "Dropdown", {
        Label = function()
            local button = Controls.DirectoryPullDown and Controls.DirectoryPullDown:GetButton()
            return button and button:GetText() or ""
        end,
        HiddenPredicate = function() return Controls.DirectoryPullDown:IsHidden() end,
    })
    CAI_DirDropdown:On("value_changed", function(self, val)
        if not val then return end
        if val.type == "level" then
            ChangeDirectoryLevelTo(val.level)
        elseif val.type == "volume" then
            ChangeVolumeTo(val.name)
        end
    end)
    CAI_Panel:AddChild(CAI_DirDropdown)

    

    -- 2a. Save tree (shown when not in directory view)
    CAI_SaveTree = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveSaves"), "Tree", {
        Label = function() return (Controls.WindowHeader and Controls.WindowHeader:GetText()) or "" end,
    })

    CAI_Panel:AddChild(CAI_SaveTree)

    -- 2b. Directory list (shown when in directory view)
    CAI_DirList = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveDirs"), "List", {
        Label = function() return (Controls.WindowHeader and Controls.WindowHeader:GetText()) or "" end,
        HiddenPredicate = function() return true end,
    })
    CAI_Panel:AddChild(CAI_DirList)

-- 2. File Name text input field box 
    CAI_FileNameEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveFileName"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_CAI_LABEL_FILE_NAME") end,
        ValueGetter = function() return Controls.FileName:GetText() or "" end,
    })
    CAI_FileNameEdit:SetAlwaysEdit(true)
    CAI_FileNameEdit:SetEnterToCommit(false)
    CAI_FileNameEdit:On("text_changed", function(self, text)
        Controls.FileName:SetText(text)
        OnFileNameChange(Controls.FileName)
    end)
    CAI_FileNameEdit:SetMaxCharacters(32)
    CAI_FileNameEdit:SetValidator(function(b)
        return ValidateFileName(b)
    end)
    CAI_Panel:AddChild(CAI_FileNameEdit)

    -- 4. Sort dropdown
    CAI_SortDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveSort"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_LABEL_SORT_BY") end,
        HiddenPredicate = function() return Controls.SortByPullDown:IsHidden() end,
    })
    CAI_SortDropdown:SetOptions(BuildSortOptions())
    CAI_SortDropdown:SetSelectedIndex(GetCurrentSortIndex(), true)
    CAI_SortDropdown:On("value_changed", function(self, val)
        if not val then return end
        Controls.SortByPullDown:GetButton():SetText(self._options[self._selectedIndex].label)
        g_CurrentSort = val.func
        if g_GameType == SaveTypes.WORLDBUILDER_MAP then
            Options.SetUserOption("Interface", "WorldBuilderMapBrowseSortDefault", val.index)
        else
            Options.SetUserOption("Interface", "SaveGameBrowseSortDefault", val.index)
        end
        Options.SaveOptions()
        SetupFileList()
        RebuildFileListAccessibility()
    end)
    CAI_Panel:AddChild(CAI_SortDropdown)

    -- 5. Cloud checkbox
    local cloudCheck = mgr:CreateWidget(mgr:GenerateWidgetId("CAISaveCloudCheck"), "Checkbox", {
        Label = function()
            local base
            if not Controls.CloudDummy:IsHidden() then
                base = Controls.CloudDummy:GetText()
            else
                base = Controls.CloudCheck:GetText()
            end
            local isNew = (not Controls.CheckNewIndicator:IsHidden()) or (not Controls.DummyNewIndicator:IsHidden())
            if isNew then
                return base .. ", "..Locale.Lookup("LOC_CAI_WC_NEW")
            end
            return base
        end,
        Tooltip = function()
            if not Controls.CloudDummy:IsHidden() then
                return SafeTooltip(Controls.CloudDummy)
            end
            return SafeTooltip(Controls.CloudCheck)
        end,
        HiddenPredicate = function()
            return Controls.CloudCheck:IsHidden() and Controls.CloudDummy:IsHidden()
        end,
        DisabledPredicate = function()
            if not Controls.CloudDummy:IsHidden() then
                return Controls.CloudDummy:IsDisabled()
            end
            return Controls.CloudCheck:IsDisabled()
        end,
    })
    cloudCheck:SetValueSetter(function()
            OnCloudCheck()
    end)
    cloudCheck:SetChecked(Controls.CloudCheck:IsSelected(), true)
    CAI_Panel:AddChild(cloudCheck)
end

local function RemoveCAIDialog()
	if CAI_ConfirmDialog then 
		mgr:RemoveFromStack(CAI_ConfirmDialog:GetId())
		CAI_ConfirmDialog = nil
	end
end

local function MakeConfirmDialog()
	RemoveCAIDialog()
	if Controls.DeleteConfirm:IsHidden() then return end
	local function GetTitle() return Controls.DeleteHeader:GetText() end
	local msg = mgr:CreateWidget("SaveDeleteConfirmMsg", "StaticText", {
		Label = function() return Controls.Message:GetText() or "" end
	})
local yesBtn = MakeSimpleBtn(Controls.Yes)
local noBtn = MakeSimpleBtn(Controls.No)
CAI_ConfirmDialog = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, { yesBtn, noBtn}, {msg})
if CAI_ConfirmDialog then
mgr:Push(CAI_ConfirmDialog)
end
end

OnDelete = WrapFunc(OnDelete, function(orig)
	orig()
	MakeConfirmDialog()
end)

OnActionButton = WrapFunc(OnActionButton, function(orig)
	orig()
	MakeConfirmDialog()
end)

OnYes = WrapFunc(OnYes, function(orig)
	orig()
	RemoveCAIDialog()
end)

OnNo = WrapFunc(OnNo, function(orig)
	orig()
	RemoveCAIDialog()
end)

SetupFileList = WrapFunc(SetupFileList, function(orig)
    CAI_LoadingFiles = true
    orig()
end)

OnFileListQueryResults = WrapFunc(OnFileListQueryResults, function(orig, list, id)
    CAI_LoadingFiles = false
    orig(list, id)
	if CAI_Panel and not mgr:GetWidgetById(CAI_Panel:GetId(), false) then
		mgr:Push(CAI_Panel, { priority = PopupPriority.Current})
	end
end)

RebuildFileList = WrapFunc(RebuildFileList, function(orig)
    orig()
    RebuildFileListAccessibility()
end)

-- ---------------------------------------------------------------------------
-- Wrapped show/hide
-- ---------------------------------------------------------------------------
OnShow = WrapFunc(OnShow, function(orig, ...)
    orig(...)

    if CAI_Panel then
        mgr:RemoveFromStack(CAI_Panel:GetId())
    end
    CAI_Panel = nil
    CAI_SaveTree = nil
    CAI_DirList = nil
    CAI_DirDropdown = nil
    CAI_SortDropdown = nil
    CAI_FileNameEdit = nil
    BuildPanel()
Controls.FileName:DropFocus();
end)

OnHide = WrapFunc(OnHide, function(orig, ...)
ClosePanel()
    orig(...)
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
	if mgr:HandleInput(input) then return true end
	return orig(input)
end)

--#End of accessibility integration

Initialize();

