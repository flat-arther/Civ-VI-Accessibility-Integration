-------------------------------------------------
-- Mods Browser Screen
-------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "PopupDialog" );

LOC_MODS_SEARCH_NAME = Locale.Lookup("LOC_MODS_SEARCH_NAME");

g_ModListingsManager = InstanceManager:new("ModInstance", "ModInstanceRoot", Controls.ModListingsStack);
g_SubscriptionsListingsManager = InstanceManager:new("SubscriptionInstance", "SubscriptionInstanceRoot", Controls.SubscriptionListingsStack);
g_DependencyListingsManager = InstanceManager:new("ReferenceItemInstance", "Item", Controls.ModDependencyItemsStack);


g_SearchContext = "Mods";
g_SearchQuery = nil;
g_ModListings = nil;			-- An array of pairs containing the mod handle and its associated listing.
g_SelectedModHandle = nil;		-- The currently selected mod entry.
g_CurrentListingsSort = nil;	-- The current method of sorting the mod listings.
g_ModSubscriptions = nil;
g_SubscriptionsSortingMap = {};

local MIN_SCREEN_Y				:number = 768;

---------------------------------------------------------------------------
---------------------------------------------------------------------------
function RefreshModGroups()
	local groups = Modding.GetModGroups();
	for i, v in ipairs(groups) do
		v.DisplayName = Locale.Lookup(v.Name);
	end
	table.sort(groups, function(a,b)
		if(a.SortIndex == b.SortIndex) then
			-- Sort by Name.
			return Locale.Compare(a.DisplayName, b.DisplayName) == -1;
		else
			return a.SortIndex < b.SortIndex;
		end
	end);	
	
	local g = Modding.GetCurrentModGroup();

	local comboBox = Controls.ModGroupPullDown;
	comboBox:ClearEntries();
	for i, v in ipairs(groups) do
		local controlTable = {};
		comboBox:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText(v.Name);
	
		controlTable.Button:RegisterCallback(Mouse.eLClick, function()
			Modding.SetCurrentModGroup(v.Handle);
			RefreshModGroups();
			RefreshListings();
		end);	

		if(v.Handle == g) then
			comboBox:GetButton():SetText(v.DisplayName);
			Controls.DeleteModGroup:SetDisabled(not v.CanDelete);
		end
	end

	comboBox:CalculateInternals();
end
---------------------------------------------------------------------------
---------------------------------------------------------------------------
function RefreshListings()
	local mods = Modding.GetInstalledMods();

	g_ModListings = {};
	g_ModListingsManager:ResetInstances();

	Controls.EnableAll:SetDisabled(true);
	Controls.DisableAll:SetDisabled(true);

	if(mods == nil or #mods == 0) then
		Controls.ModListings:SetHide(true);
		Controls.NoModsInstalled:SetHide(false);
	else
		Controls.ModListings:SetHide(false);
		Controls.NoModsInstalled:SetHide(true);

		PreprocessListings(mods);

		mods = FilterListings(mods);

		SortListings(mods);

		local hasEnabledMods = false;
		local hasDisabledMods = false;

		for i,v in ipairs(mods) do		
			local instance = g_ModListingsManager:GetInstance();

			table.insert(g_ModListings, {v.Handle, instance});

			local handle = v.Handle;

			instance.ModInstanceButton:RegisterCallback(Mouse.eLClick, function()
				SelectMod(handle);
			end);

			local name = TruncateStringByLength(v.DisplayName, 96);
			
			if(v.Allowance == false) then
				name = name .. " [COLOR_RED](" .. Locale.Lookup("LOC_MODS_DETAILS_OWNERSHIP_NO") .. ")[ENDCOLOR]";
			end

			if(Modding.ShouldShowCompatibilityWarnings()) then
				if(not Modding.IsModCompatible(v.Handle) and not Modding.GetIgnoreCompatibilityWarnings(v.Handle)) then
					name = name .. " [COLOR_RED](" .. Locale.Lookup("LOC_MODS_DETAILS_COMPATIBLE_NOT") .. ")[ENDCOLOR]";
				end
			end

			instance.ModTitle:LocalizeAndSetText(name);

			local tooltip;
			if(#v.Teaser) then
				tooltip = Locale.Lookup(v.Teaser);
			end
			instance.ModInstanceRoot:SetToolTipString(tooltip);

			local enabled = v.Enabled;
			if(enabled) then
				hasEnabledMods = true;
				instance.ModEnabled:LocalizeAndSetText("LOC_MODS_ENABLED");
			else
				hasDisabledMods = true;
				instance.ModEnabled:SetText("[COLOR_RED]" .. Locale.Lookup("LOC_MODS_DISABLED") .. "[ENDCOLOR]");
			end

			local bOfficial = v.Official;
			local bIsMap = v.Source == "Map";
			instance.MapIcon:SetHide(not bIsMap);
			instance.OfficialIcon:SetHide(bIsMap or not bOfficial);
			instance.CommunityIcon:SetHide(bIsMap or bOfficial);
		end

		if(hasEnabledMods) then
			Controls.DisableAll:SetDisabled(false);
		end

		if(hasDisabledMods) then
			Controls.EnableAll:SetDisabled(false);
		end

		Controls.ModListingsStack:CalculateSize();
		Controls.ModListingsStack:ReprocessAnchoring();
		Controls.ModListings:CalculateInternalSize();
	end

	-- Update the selection state of each listing.
	RefreshListingsSelectionState();
	RefreshModDetails();
end

---------------------------------------------------------------------------
-- Pre-process listings by translating strings or stripping tags.
---------------------------------------------------------------------------
function PreprocessListings(mods)
	for i,v in ipairs(mods) do
		v.DisplayName = Locale.Lookup(v.Name);
		v.StrippedDisplayName = Locale.StripTags(v.DisplayName);
	end
end

---------------------------------------------------------------------------
-- Filter the listings, returns filtered list.
---------------------------------------------------------------------------
function FilterListings(mods)

	local isFinalRelease = UI.IsFinalRelease();
	local showOfficialContent = Controls.ShowOfficialContent:IsChecked();
	local showCommunityContent = Controls.ShowCommunityContent:IsChecked();

	local original = mods;
	mods = {};
	for i,v in ipairs(original) do	
		-- Hide mods marked as always hidden or DLC which is not owned.
		local category = Modding.GetModProperty(v.Handle, "ShowInBrowser");
		if(category ~= "AlwaysHidden" and not (isFinalRelease and v.Allowance == false)) then
			-- Filter by selected options (currently only official and community content).
			if(v.Official and showOfficialContent) then
				table.insert(mods, v);
			elseif(not v.Official and showCommunityContent) then
				table.insert(mods, v);
			end
		end
	end

	-- Index remaining mods and filter by search query.
	if(Search.HasContext(g_SearchContext)) then
		Search.ClearData(g_SearchContext);
		for i, v in ipairs(mods) do
			Search.AddData(g_SearchContext, v.Handle, v.DisplayName, Locale.Lookup(v.Teaser or ""));
		end
		Search.Optimize(g_SearchContext);

		if(g_SearchQuery) then
			if (g_SearchQuery ~= nil and #g_SearchQuery > 0 and g_SearchQuery ~= LOC_MODS_SEARCH_NAME) then
				local include_map = {};
				local search_results = Search.Search(g_SearchContext, g_SearchQuery);
				if (search_results and #search_results > 0) then
					for i, v in ipairs(search_results) do
						include_map[tonumber(v[1])] = v[2];
					end
				end

				local original = mods;
				mods = {};
				for i,v in ipairs(original) do
					if(include_map[v.Handle]) then
						v.DisplayName = include_map[v.Handle];
						v.StrippedDisplayName = Locale.StripTags(v.DisplayName);
						table.insert(mods, v);
					end
				end
			end
		end
	end
	
	return mods;
end

---------------------------------------------------------------------------
-- Sort the listings in-place.
---------------------------------------------------------------------------
function SortListings(mods)
	if(g_CurrentListingsSort) then
		g_CurrentListingsSort(mods);
	end
end

-- Update the state of each instanced listing to reflect whether it is selected.
function RefreshListingsSelectionState()
	for i,v in ipairs(g_ModListings) do
		if(v[1] == g_SelectedModHandle) then
			v[2].ModInstanceButton:SetSelected(true);
		else
			v[2].ModInstanceButton:SetSelected(false);
		end
	end
end

function RefreshModDetails()
	if(g_SelectedModHandle == nil) then
		-- Hide details and offer up a guidance string.
		Controls.NoModSelected:SetHide(false);
		Controls.ModDetailsContainer:SetHide(true);

	else
		Controls.NoModSelected:SetHide(true);
		Controls.ModDetailsContainer:SetHide(false);

		local modHandle = g_SelectedModHandle;
		local info = Modding.GetModInfo(modHandle);

		local bIsMap = info.Source == "Map";

		if(bIsMap) then
			Controls.ModContent:LocalizeAndSetText("LOC_MODS_WORLDBUILDER_CONTENT");
		elseif(info.Official) then
			Controls.ModContent:LocalizeAndSetText("LOC_MODS_FIRAXIAN_CONTENT");
		else
			Controls.ModContent:LocalizeAndSetText("LOC_MODS_USER_CONTENT");
		end

		local compatible = Modding.IsModCompatible(modHandle);
		Controls.ModCompatibilityWarning:SetHide(compatible);
		Controls.WhitelistMod:SetHide(compatible);

		if(not compatible) then
			Controls.WhitelistMod:SetCheck(Modding.GetIgnoreCompatibilityWarnings(modHandle));
			Controls.WhitelistMod:RegisterCallback(Mouse.eLClick, function()
				Modding.SetIgnoreCompatibilityWarnings(modHandle, Controls.WhitelistMod:IsChecked());
				RefreshListings();
			end);
		end

		-- Official/Community Icons
		local bIsOfficial = info.Official;
		Controls.MapIcon:SetHide(not bIsMap);
		Controls.OfficialIcon:SetHide(bIsMap or not bIsOfficial);
		Controls.CommunityIcon:SetHide(bIsMap or bIsOfficial);

		local enableButton = Controls.EnableButton;
		local disableButton = Controls.DisableButton;
		if(info.Official and info.Allowance == false) then
			enableButton:SetHide(true);
			disableButton:SetHide(true);
		else
			local enabled = info.Enabled;
			if(enabled) then
				enableButton:SetHide(true);
				disableButton:SetHide(false);
				
				local err, xtra, sources = Modding.CanDisableMod(modHandle);
				if(err == "OK") then
					disableButton:SetDisabled(false);
					disableButton:SetToolTipString(nil);

					disableButton:RegisterCallback(Mouse.eLClick, function()
						Modding.DisableMod(modHandle);
						RefreshListings();
					end);
				else
					disableButton:SetDisabled(true);
							
					-- Generate tip w/ list of mods to enable.
					local error_suffix;

					local tip = {};
					local items = xtra or {};
					
					if(err == "OwnershipRequired") then
						error_suffix = "(" .. Locale.Lookup("LOC_MODS_DETAILS_OWNERSHIP_NO") .. ")";
					end

					if(err == "MissingDependencies") then
						tip[1] = Locale.Lookup("LOC_MODS_DISABLE_ERROR_DEPENDS");
						items = sources or {}; -- show sources of errors rather than targets of error.
					else
						tip[1] = Locale.Lookup("LOC_MODS_DISABLE_ERROR") .. err;
					end

					local unique_items = {};
					for k,ref in ipairs(items) do
						if(unique_items[ref.Id] == nil) then
							unique_items[ref.Id] = true;

							local name = ref.Id;
							if(ref.Name) then
								name = Locale.LookupBundle(ref.Name);
								if(name == nil) then
									name = Locale.Lookup(ref.Name);
								end
							end

							local item = "[ICON_BULLET] " .. name;
							if(error_suffix) then
								item = item .. " " .. error_suffix;
							end

							table.insert(tip, item);
						end
						
					end

					disableButton:SetToolTipString(table.concat(tip, "[NEWLINE]"));
				end
			else
				enableButton:SetHide(false);
				disableButton:SetHide(true);
				local err, xtra = Modding.CanEnableMod(modHandle);
				if(err == "MissingDependencies") then
					-- Don't replace xtra since we want the old list to enumerate missing mods.
					err, _ = Modding.CanEnableMod(modHandle, true);
				end

				if(err == "OK") then
					enableButton:SetDisabled(false);

					if(xtra and #xtra > 0) then
						-- Generate tip w/ list of mods to enable.
						local tip = {Locale.Lookup("LOC_MODS_ENABLE_INCLUDE")};


						local unique_items = {};
						for k,ref in ipairs(xtra) do
							if(unique_items[ref.Id] == nil) then
								unique_items[ref.Id] = true;

								local name = ref.Id;
								if(ref.Name) then
									name = Locale.LookupBundle(ref.Name);
									if(name == nil) then
										name = Locale.Lookup(ref.Name);
									end
								end

								local item = "[ICON_BULLET] " .. name;
								table.insert(tip, item);
							end	
						end

						enableButton:SetToolTipString(table.concat(tip, "[NEWLINE]"));
					else	
						enableButton:SetToolTipString(nil);
					end

					local OnEnable = function()
						Modding.EnableMod(modHandle, true);
						RefreshListings();
					end

					if(	Modding.ShouldShowCompatibilityWarnings() and 
						not Modding.IsModCompatible(modHandle) and 
						not Modding.GetIgnoreCompatibilityWarnings(modHandle)) then

						enableButton:RegisterCallback(Mouse.eLClick, function()
							m_kPopupDialog:AddText(Locale.Lookup("LOC_MODS_ENABLE_WARNING_NOT_COMPATIBLE"));
							m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_MODS_TITLE")));
							m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES_BUTTON"), OnEnable, nil, nil, "PopupButtonInstanceGreen"); 
							m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO_BUTTON"), nil);
							m_kPopupDialog:Open();
						end);

					else
						enableButton:RegisterCallback(Mouse.eLClick, OnEnable);
					end
				else
					enableButton:SetDisabled(true);
					
					if(err == "ContainsDuplicates") then
						enableButton:SetToolTipString(Locale.Lookup("LOC_MODS_ERROR_MOD_VERSION_ALREADY_ENABLED"));
					else
						-- Generate tip w/ list of mods to enable.
						local error_suffix;

						if(err == "OwnershipRequired") then
							error_suffix = "(" .. Locale.Lookup("LOC_MODS_DETAILS_OWNERSHIP_NO") .. ")";
						end

						local tip = {Locale.Lookup("LOC_MODS_ENABLE_ERROR")};

						local unique_items = {};
						for k,ref in ipairs(xtra) do
							if(unique_items[ref.Id] == nil) then
								unique_items[ref.Id] = true;

								local name = ref.Id;
								if(ref.Name) then
									name = Locale.LookupBundle(ref.Name);
									if(name == nil) then
										name = Locale.Lookup(ref.Name);
									end
								end

								local item = "[ICON_BULLET] " .. name;
								if(error_suffix) then
									item = item .. " " .. error_suffix;
								end
								table.insert(tip, item);
							end	
						end

						enableButton:SetToolTipString(table.concat(tip, "[NEWLINE]"));
					end		
					
				end
			end
		end

		Controls.ModTitle:LocalizeAndSetText(info.Name, 64);
		Controls.ModIdVersion:SetText(info.Id);
		if(bIsMap) then
			Controls.ModFileName:SetText(info.SourceFileName);
			Controls.ModFileName:SetHide(false);
		else
			Controls.ModFileName:SetHide(true);
		end

		local desc = Modding.GetModProperty(g_SelectedModHandle, "Description") or info.Teaser;
		if(desc) then
			desc = Modding.GetModText(g_SelectedModHandle, desc) or desc
			Controls.ModDescription:LocalizeAndSetText(desc);
			Controls.ModDescription:SetHide(false);
		else
			Controls.ModDescription:SetHide(true);
		end

		local authors = Modding.GetModProperty(g_SelectedModHandle, "Authors");
		if(authors) then
			authors = Modding.GetModText(g_SelectedModHandle, authors) or authors
			Controls.ModAuthorsValue:LocalizeAndSetText(authors);

			local width, height = Controls.ModAuthorsValue:GetSizeVal();
			Controls.ModAuthorsCaption:SetSizeY(height);
			Controls.ModAuthorsCaption:SetHide(false);
			Controls.ModAuthorsValue:SetHide(false);
		else
			Controls.ModAuthorsCaption:SetHide(true);
			Controls.ModAuthorsValue:SetHide(true);
		end

		local specialThanks = Modding.GetModProperty(g_SelectedModHandle, "SpecialThanks");
		if(specialThanks) then
			specialThanks = Modding.GetModText(g_SelectedModHandle, specialThanks) or specialThanks
			Controls.ModSpecialThanksValue:LocalizeAndSetText(specialThanks);
		
			local width, height = Controls.ModSpecialThanksValue:GetSizeVal();
			Controls.ModSpecialThanksCaption:SetSizeY(height);
			Controls.ModSpecialThanksValue:SetHide(false);
			Controls.ModSpecialThanksCaption:SetHide(false);
		
		else
			Controls.ModSpecialThanksCaption:SetHide(true);
			Controls.ModSpecialThanksValue:SetHide(true);
		end

		local created = info.Created;
		if(created) then
			Controls.ModCreatedValue:LocalizeAndSetText("{1_Created : date long}", created);
			Controls.ModCreatedCaption:SetHide(false);		
			Controls.ModCreatedValue:SetHide(false);
		else
			Controls.ModCreatedCaption:SetHide(true);
			Controls.ModCreatedValue:SetHide(true);
		end

		if(info.Official and info.Allowance ~= nil) then
			
			Controls.ModOwnershipCaption:SetHide(false);
			Controls.ModOwnershipValue:SetHide(false);
			if(info.Allowance) then
				Controls.ModOwnershipValue:SetText("[COLOR_GREEN]" .. Locale.Lookup("LOC_MODS_YES") .. "[ENDCOLOR]");
			else
				Controls.ModOwnershipValue:SetText("[COLOR_RED]" .. Locale.Lookup("LOC_MODS_NO") .. "[ENDCOLOR]");
			end
		else
			Controls.ModOwnershipCaption:SetHide(true);
			Controls.ModOwnershipValue:SetHide(true);
		end

		local affectsSavedGames = Modding.GetModProperty(g_SelectedModHandle, "AffectsSavedGames");
		if(affectsSavedGames and tonumber(affectsSavedGames) == 0) then
			Controls.ModAffectsSavedGamesValue:LocalizeAndSetText("LOC_MODS_NO");
		else
			Controls.ModAffectsSavedGamesValue:LocalizeAndSetText("LOC_MODS_YES");
		end

		local supportsSinglePlayer = Modding.GetModProperty(g_SelectedModHandle, "SupportsSinglePlayer");
		if(supportsSinglePlayer and tonumber(supportsSinglePlayer) == 0) then
			Controls.ModSupportsSinglePlayerValue:LocalizeAndSetText("[COLOR_RED]" .. Locale.Lookup("LOC_MODS_NO") .. "[ENDCOLOR]");
		else
			Controls.ModSupportsSinglePlayerValue:LocalizeAndSetText("LOC_MODS_YES");
		end

		local supportsMultiplayer = Modding.GetModProperty(g_SelectedModHandle, "SupportsMultiplayer");
		if(supportsMultiplayer and tonumber(supportsMultiplayer) == 0) then
			Controls.ModSupportsMultiplayerValue:LocalizeAndSetText("[COLOR_RED]" .. Locale.Lookup("LOC_MODS_NO") .. "[ENDCOLOR]");
		else
			Controls.ModSupportsMultiplayerValue:LocalizeAndSetText("LOC_MODS_YES");
		end

		local dependencies, references, blocks = Modding.GetModAssociations(g_SelectedModHandle);

		g_DependencyListingsManager:ResetInstances();
		if(dependencies) then
			local dependencyStrings = {}
			for i,v in ipairs(dependencies) do
				
				local name = v.Name;
				if(name) then
					local text = Locale.LookupBundle(name);
					if(text == nil) then
						text = Locale.Lookup(name);
					end

					dependencyStrings[i] = text or name;
				end				
			end
			table.sort(dependencyStrings, function(a,b) return Locale.Compare(a,b) == -1 end);

			for i,v in ipairs(dependencyStrings) do
				local instance = g_DependencyListingsManager:GetInstance();
				instance.Item:SetText( "[ICON_BULLET] " .. v);		
			end
		end
		Controls.ModDependenciesStack:SetHide(dependencies == nil or #dependencies == 0);

		
		Controls.ModDependencyItemsStack:CalculateSize();
		Controls.ModDependencyItemsStack:ReprocessAnchoring();
		Controls.ModDependenciesStack:CalculateSize();
		Controls.ModDependenciesStack:ReprocessAnchoring();	
		Controls.ModPropertiesValuesStack:CalculateSize();
		Controls.ModPropertiesValuesStack:ReprocessAnchoring();
		Controls.ModPropertiesCaptionStack:CalculateSize();
		Controls.ModPropertiesCaptionStack:ReprocessAnchoring();
		Controls.ModPropertiesStack:CalculateSize();
		Controls.ModPropertiesStack:ReprocessAnchoring();
		Controls.ModDetailsStack:CalculateSize();
		Controls.ModDetailsStack:ReprocessAnchoring();
		Controls.ModDetailsScrollPanel:CalculateInternalSize();
	end
end

-- Select a specific entry in the listings.
function SelectMod(handle)
	g_SelectedModHandle = handle;
	RefreshListingsSelectionState();
	RefreshModDetails();
end

function CreateModGroup()
	Controls.ModGroupEditBox:SetText("");
	Controls.CreateModGroupButton:SetDisabled(true);

	Controls.NameModGroupPopup:SetHide(false);
	Controls.NameModGroupPopupAlpha:SetToBeginning();
	Controls.NameModGroupPopupAlpha:Play();
	Controls.NameModGroupPopupSlide:SetToBeginning();
	Controls.NameModGroupPopupSlide:Play();

	Controls.ModGroupEditBox:TakeFocus();
end

function DeleteModGroup()
	local currentGroup = Modding.GetCurrentModGroup();
	local groups = Modding.GetModGroups();
	for i, v in ipairs(groups) do
		v.DisplayName = Locale.Lookup(v.Name);
	end

	table.sort(groups, function(a,b)
		if(a.SortIndex == b.SortIndex) then
			-- Sort by Name.
			return Locale.Compare(a.DisplayName, b.DisplayName) == -1;
		else
			return a.SortIndex < b.SortIndex;
		end
	end);	

	for i, v in ipairs(groups) do
		if(v.Handle ~= currentGroup) then
			Modding.SetCurrentModGroup(v.Handle);
			Modding.DeleteModGroup(currentGroup);
			break;
		end
	end

	RefreshModGroups();
	RefreshListings();
end

function EnableAllMods()
	local mods = Modding.GetInstalledMods();
	PreprocessListings(mods);
	mods = FilterListings(mods);

	local modHandles = {};
	for i,v in ipairs(mods) do
		local err, _ =  Modding.CanEnableMod(v.Handle, true);
		if (err == "OK") then
			table.insert(modHandles, v.Handle);
		end
	end

	if(	Modding.ShouldShowCompatibilityWarnings()) then
		local whitelistMods = false;
		local incompatibleMods = {};
		for i,v in ipairs(modHandles) do
			if(	not Modding.IsModCompatible(v) and 
				not Modding.GetIgnoreCompatibilityWarnings(v)) then
				table.insert(incompatibleMods, v);
			end
		end

		function OnYes()
			if(whitelistMods) then
				for i,v in ipairs(incompatibleMods) do
					Modding.SetIgnoreCompatibilityWarnings(v, true);
				end
			end

			Modding.EnableMod(modHandles);
			RefreshListings();
		end

		if(#incompatibleMods > 0) then
			m_kPopupDialog:AddText(Locale.Lookup("LOC_MODS_ENABLE_WARNING_NOT_COMPATIBLE_MANY"));
			m_kPopupDialog:AddTitle(Locale.ToUpper(Locale.Lookup("LOC_MODS_TITLE")));
			m_kPopupDialog:AddButton(Locale.Lookup("LOC_YES_BUTTON"), OnYes, nil, nil, "PopupButtonInstanceGreen"); 
			m_kPopupDialog:AddButton(Locale.Lookup("LOC_NO_BUTTON"), nil);
			m_kPopupDialog:AddCheckBox(Locale.Lookup("LOC_MODS_WARNING_WHITELIST_MANY"), false, function(checked) whitelistMods = checked; end);
			m_kPopupDialog:Open();
		else
			OnYes();
		end
	else	
		Modding.EnableMod(modHandles);
		RefreshListings();
	end
end

function DisableAllMods()
	local mods = Modding.GetInstalledMods();
	PreprocessListings(mods);
	mods = FilterListings(mods);

	local modHandles = {};
	for i,v in ipairs(mods) do
		modHandles[i] = v.Handle;
	end
	Modding.DisableMod(modHandles);
	RefreshListings();
end

----------------------------------------------------------------        
-- Subscriptions Tab
----------------------------------------------------------------        
function RefreshSubscriptions()
	local subs = Modding.GetSubscriptions();

	g_Subscriptions = {};
	g_SubscriptionsSortingMap = {};
	g_SubscriptionsListingsManager:ResetInstances();

	Controls.NoSubscriptions:SetHide(#subs > 0);

	for i,v in ipairs(subs) do
		local instance = g_SubscriptionsListingsManager:GetInstance();
		table.insert(g_Subscriptions, {
			SubscriptionId = v,
			Instance = instance,
			NeedsRefresh = true
		});
	end
	UpdateSubscriptions()

	Controls.SubscriptionListingsStack:CalculateSize();
	Controls.SubscriptionListingsStack:ReprocessAnchoring();
	Controls.SubscriptionListings:CalculateInternalSize();
end
----------------------------------------------------------------  
function RefreshSubscriptionItem(item)

	local needsRefresh = false;
	local instance = item.Instance;
	local subscriptionId = item.SubscriptionId;

	local details = Modding.GetSubscriptionDetails(subscriptionId);

	local name = details.Name;
	if(name == nil) then
		name = Locale.Lookup("LOC_MODS_SUBSCRIPTION_NAME_PENDING");
		needsRefresh = true;
	end

	instance.SubscriptionTitle:SetText(name);
	g_SubscriptionsSortingMap[tostring(instance.SubscriptionInstanceRoot)] = name;

	if(details.LastUpdated) then
		instance.LastUpdated:SetText(Locale.Lookup("LOC_MODS_LAST_UPDATED", details.LastUpdated));
	end
	
	instance.UnsubscribeButton:SetHide(true);

	local status = details.Status;
	instance.SubscriptionDownloadProgress:SetHide(status ~= "Downloading");
	if(status == "Downloading") then
		local downloaded, total = Modding.GetSubscriptionDownloadStatus(subscriptionId);

		if(total > 0) then
			local w = instance.SubscriptionInstanceRoot:GetSizeX();
			local pct = downloaded/total;

			instance.SubscriptionDownloadProgress:SetSizeX(math.floor(w * pct));
			instance.SubscriptionDownloadProgress:SetHide(false);
		else
			instance.SubscriptionDownloadProgress:SetHide(true);
		end

		instance.SubscriptionStatus:LocalizeAndSetText("LOC_MODS_SUBSCRIPTION_DOWNLOADING", downloaded, total);
	else
		local statusStrings = {
			["Installed"] = "LOC_MODS_SUBSCRIPTION_DOWNLOAD_INSTALLED",
			["DownloadPending"] = "LOC_MODS_SUBSCRIPTION_DOWNLOAD_PENDING",
			["Subscribed"] = "LOC_MODS_SUBSCRIPTION_SUBSCRIBED"
		};
		instance.SubscriptionStatus:LocalizeAndSetText(statusStrings[status]);
	end

	if(Steam and Steam.IsOverlayEnabled and Steam.IsOverlayEnabled()) then
		instance.SubscriptionViewButton:SetHide(false);
		instance.SubscriptionViewButton:RegisterCallback(Mouse.eLClick, function()
			local url = "http://steamcommunity.com/sharedfiles/filedetails/?id=" .. subscriptionId;
			Steam.ActivateGameOverlayToUrl(url);
		end);
	else
		instance.SubscriptionViewButton:SetHide(true);
	end

	-- If we're downloading or about to download, keep refreshing the details.
	if(status == "Downloading" or status == "DownloadingPending") then
		needsRefresh = true;
		instance.SubscriptionUpdateButton:SetHide(true);
	else
		local needsUpdate = details.NeedsUpdate;
		if(needsUpdate) then
			instance.SubscriptionUpdateButton:SetHide(false);
			instance.SubscriptionUpdateButton:RegisterCallback(Mouse.eLClick, function()
				Modding.UpdateSubscription(subscriptionId);
				RefreshSubscriptions();
			end);
		else
			instance.SubscriptionUpdateButton:SetHide(true);
			instance.UnsubscribeButton:SetHide(false);
			instance.UnsubscribeButton:RegisterCallback(Mouse.eLClick, function()
				Modding.Unsubscribe(subscriptionId);
				instance.SubscriptionInstanceRoot:SetHide(true);
			end);
		end
	end


	instance.SubscriptionInstanceRoot:SetHide(false);
	item.NeedsRefresh = needsRefresh;
end
----------------------------------------------------------------  
function SortSubscriptionListings(a,b)
	-- ForgUI requires a strict weak ordering sort.
	local ap = g_SubscriptionsSortingMap[tostring(a)];
	local bp = g_SubscriptionsSortingMap[tostring(b)];

	if(ap == nil and bp ~= nil) then
		return true;
	elseif(ap == nil and bp == nil) then
		return tostring(a) < tostring(b);
	elseif(ap ~= nil and bp == nil) then
		return false;
	else
		return Locale.Compare(ap, bp) == -1;
	end
end
----------------------------------------------------------------  
function UpdateSubscriptions()
	local updated = false;
	if(g_Subscriptions) then
		for i, v in ipairs(g_Subscriptions) do
			if(v.NeedsRefresh) then
				RefreshSubscriptionItem(v);
				updated = true;
			end
		end
	end

	if(updated) then
		Controls.SubscriptionListingsStack:SortChildren(SortSubscriptionListings);
	end
end


----------------------------------------------------------------        
-- Input Handler
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
	if uiMsg == KeyEvents.KeyUp then
		if wParam == Keys.VK_ESCAPE then
			if(Controls.NameModGroupPopup ~= nil and Controls.NameModGroupPopup:IsVisible()) then
				Controls.NameModGroupPopup:SetHide(true);
			else
				HandleExitRequest();
			end
			return true;
		end
	end
	return false;
end
ContextPtr:SetInputHandler( InputHandler );

----------------------------------------------------------------  
function OnInstalledModsTabClick(bForce)
	if(Controls.InstalledTabPanel:IsHidden() or bForce) then
		Controls.SubscriptionsTabPanel:SetHide(true);
		Controls.InstalledTabPanel:SetHide(false);

		-- Clear search queries.
		g_SearchQuery = nil;
		g_SelectedModHandle = nil;

		Controls.SearchEditBox:SetText(LOC_MODS_SEARCH_NAME);
		RefreshModGroups();
		RefreshListings();
	end
end
----------------------------------------------------------------  
function OnSubscriptionsTabClick()
	if(Controls.SubscriptionsTabPanel:IsHidden() or bForce) then
		Controls.InstalledTabPanel:SetHide(true);
		Controls.SubscriptionsTabPanel:SetHide(false);

		RefreshSubscriptions();
	end
end
----------------------------------------------------------------  
function OnOpenWorkshop()
	if (Steam ~= nil) then
		Steam.ActivateGameOverlayToWorkshop();
	end
end

----------------------------------------------------------------    
function OnShow()
	OnInstalledModsTabClick(true);
	if(GameConfiguration.IsAnyMultiplayer()) then
		Controls.BrowseWorkshop:SetHide(true);
	else
		Controls.BrowseWorkshop:SetHide(false);
	end
end	
----------------------------------------------------------------    
function HandleExitRequest()
	GameConfiguration.UpdateEnabledMods();
	UIManager:DequeuePopup( ContextPtr );
end
----------------------------------------------------------------  
function PostInit()
	if(not ContextPtr:IsHidden()) then
		OnShow();
	end
end

function OnUpdate(delta)
	-- Overkill..
	UpdateSubscriptions();
end
----------------------------------------------------------------  
-- ===========================================================================
--	Handle Window Sizing
-- ===========================================================================
function Resize()
	local screenX, screenY:number = UIManager:GetScreenSizeVal();
	local hideLogo = true;
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		hideLogo = false;
		Controls.MainWindow:SetSizeY(screenY- (Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY()));
	else
		Controls.MainWindow:SetSizeY(screenY);
	end
	Controls.LogoContainer:SetHide(hideLogo);
end

function OnSearchBarGainFocus()
	Controls.SearchEditBox:ClearString();
end

----------------------------------------------------------------
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string )   
  if type == SystemUpdateUI.ScreenResize then
    Resize();
  end
end

----------------------------------------------------------------
function OnSearchCharCallback()
	local str = Controls.SearchEditBox:GetText();
	if (str ~= nil and #str > 0 and str ~= LOC_MODS_SEARCH_NAME) then
		g_SearchQuery = str;
		RefreshListings();
	elseif(str == nil or #str == 0) then
		g_SearchQuery = nil;
		RefreshListings();
	end
end


---------------------------------------------------------------------------
-- Sort By Pulldown setup
-- Must exist below callback function names
---------------------------------------------------------------------------
function SortListingsByName(mods)
	-- Keep XP1 and XP2 at the top of the list, regardless of sort.
	local sortOverrides = {
		["4873eb62-8ccc-4574-b784-dda455e74e68"] = -2,
		["1B28771A-C749-434B-9053-D1380C553DE9"] = -1
	};

	table.sort(mods, function(a,b) 
		local aSort = sortOverrides[a.Id] or 0;
		local bSort = sortOverrides[b.Id] or 0;

		if(aSort ~= bSort) then
			return aSort < bSort;
		else
			return Locale.Compare(a.StrippedDisplayName, b.StrippedDisplayName) == -1;
		end
	end);
end
---------------------------------------------------------------------------
function SortListingsByEnabled(mods)
	-- Keep XP1 and XP2 at the top of the list, regardless of sort.
	local sortOverrides = {
		["4873eb62-8ccc-4574-b784-dda455e74e68"] = -2,
		["1B28771A-C749-434B-9053-D1380C553DE9"] = -1
	};

	table.sort(mods, function(a,b) 
		local aSort = sortOverrides[a.Id] or 0;
		local bSort = sortOverrides[b.Id] or 0;

		if(aSort ~= bSort) then
			return aSort < bSort;
		elseif(a.Enabled ~= b.Enabled) then
			return a.Enabled;
		else
			-- Sort by Name.
			return Locale.Compare(a.StrippedDisplayName, b.StrippedDisplayName) == -1;
		end
	end);
end
---------------------------------------------------------------------------
local g_SortListingsOptions = {
	{"LOC_MODS_SORTBY_NAME", SortListingsByName},
	{"LOC_MODS_SORTBY_ENABLED", SortListingsByEnabled},
};
---------------------------------------------------------------------------
function InitializeSortListingsPulldown()
	local sortByPulldown = Controls.SortListingsPullDown;
	sortByPulldown:ClearEntries();
	for i, v in ipairs(g_SortListingsOptions) do
		local controlTable = {};
		sortByPulldown:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:LocalizeAndSetText(v[1]);
	
		controlTable.Button:RegisterCallback(Mouse.eLClick, function()
			sortByPulldown:GetButton():LocalizeAndSetText( v[1] );
			g_CurrentListingsSort = v[2];
			RefreshListings();
		end);
	
	end
	sortByPulldown:CalculateInternals();

	sortByPulldown:GetButton():LocalizeAndSetText(g_SortListingsOptions[1][1]);
	g_CurrentListingsSort = g_SortListingsOptions[1][2];
end

function Initialize()
	m_kPopupDialog = PopupDialog:new( "Mods" );

	Controls.EnableAll:RegisterCallback(Mouse.eLClick, EnableAllMods);
	Controls.DisableAll:RegisterCallback(Mouse.eLClick, DisableAllMods);
	Controls.CreateModGroup:RegisterCallback(Mouse.eLClick, CreateModGroup);
	Controls.DeleteModGroup:RegisterCallback(Mouse.eLClick, DeleteModGroup);
	
	if(not Search.CreateContext(g_SearchContext, "[COLOR_LIGHTBLUE]", "[ENDCOLOR]", "...")) then
		print("Failed to create mods browser search context!");
	end
	Controls.SearchEditBox:RegisterStringChangedCallback(OnSearchCharCallback);
	Controls.SearchEditBox:RegisterHasFocusCallback(OnSearchBarGainFocus);

	local refreshListings = function() RefreshListings(); end;
	Controls.ShowOfficialContent:RegisterCallback(Mouse.eLClick, refreshListings);
	Controls.ShowCommunityContent:RegisterCallback(Mouse.eLClick, refreshListings);

	Controls.CancelBindingButton:RegisterCallback(Mouse.eLClick, function()
		Controls.NameModGroupPopup:SetHide(true);
	end);

	Controls.CreateModGroupButton:RegisterCallback(Mouse.eLClick, function()
		Controls.NameModGroupPopup:SetHide(true);
		local groupName = Controls.ModGroupEditBox:GetText();
		local currentGroup = Modding.GetCurrentModGroup();
		Modding.CreateModGroup(groupName, currentGroup);
		RefreshModGroups();
		RefreshListings();
	end);

	Controls.ModGroupEditBox:RegisterStringChangedCallback(function()
		local str = Controls.ModGroupEditBox:GetText();
		Controls.CreateModGroupButton:SetDisabled(str == nil or #str == 0);
	end);

	Controls.ModGroupEditBox:RegisterCommitCallback(function()
		local str = Controls.ModGroupEditBox:GetText();
		if(str and #str > 0) then
			Controls.NameModGroupPopup:SetHide(true);
			local currentGroup = Modding.GetCurrentModGroup();
			Modding.CreateModGroup(str, currentGroup);
			RefreshModGroups();
			RefreshListings();
		end
	end);

	if(Steam ~= nil and Steam.GetAppID() ~= 0) then
		Controls.SubscriptionsTab:RegisterCallback(Mouse.eLClick, function() OnSubscriptionsTabClick() end);
		Controls.SubscriptionsTab:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
		Controls.SubscriptionsTab:SetHide(false);
	else
		Controls.SubscriptionsTab:SetHide(true);
	end

	local pFriends = Network.GetFriends();
	if(pFriends ~= nil and pFriends:IsOverlayEnabled()) then
		Controls.BrowseWorkshop:RegisterCallback( Mouse.eLClick, OnOpenWorkshop );
		Controls.BrowseWorkshop:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	else
		Controls.BrowseWorkshop:SetDisabled(true);
	end
	Controls.ShowOfficialContent:SetCheck(true);
	Controls.ShowCommunityContent:SetCheck(true);

	InitializeSortListingsPulldown();
	Resize();
	Controls.InstalledTab:RegisterCallback(Mouse.eLClick, function() OnInstalledModsTabClick() end);
	Controls.InstalledTab:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);
	Controls.CloseButton:RegisterCallback( Mouse.eLClick, HandleExitRequest );
	Controls.CloseButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	Events.SystemUpdateUI.Add( OnUpdateUI );

	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetUpdate(OnUpdate);
	ContextPtr:SetPostInit(PostInit);	
end

--#Accessibility integration
include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager
local CAI_Panel = nil
local CAI_Tabs = nil
local CAI_InstalledPage = nil
local CAI_SubscriptionsPage = nil
local CAI_ModsTree = nil
local CAI_SubscriptionsList = nil
local CAI_SortDropdown = nil
local CAI_OfficialCheck = nil
local CAI_CommunityCheck = nil
local CAI_IgnoreWarningsCheck = nil
local CAI_GroupDropdown = nil
local CAI_GroupDialog = nil
local CAI_SyncingTabs = false
local CAI_PostInitialized = false
local CAI_PendingModAction = nil
local CAI_PendingUnsubscriptions = {}

local function CAI_GetText(control)
	if control and control.GetText then
		return control:GetText() or ""
	end
	return ""
end

local function CAI_GetTooltip(control)
	if control and control.GetToolTipString then
		return control:GetToolTipString() or ""
	end
	return ""
end

local function CAI_LookupBundleOrText(value)
	if value == nil or value == "" then return "" end
	local text = Locale.LookupBundle(value)
	if text == nil or text == "" then
		text = Locale.Lookup(value)
	end
	return text or ""
end

local function CAI_GetModPropertyText(handle, property)
	local value = Modding.GetModProperty(handle, property)
	if value == nil or value == "" then return "" end
	return Modding.GetModText(handle, value) or Locale.Lookup(value) or value
end

local function CAI_GetContentType(info)
	if not info then return "" end
	if info.Source == "Map" then
		return Locale.Lookup("LOC_MODS_WORLDBUILDER_CONTENT")
	end
	if info.Official then
		return Locale.Lookup("LOC_MODS_FIRAXIAN_CONTENT")
	end
	return Locale.Lookup("LOC_MODS_USER_CONTENT")
end

local function CAI_GetModLabel(handle)
	local info = Modding.GetModInfo(handle)
	if not info then return "" end

	local parts = {
		Locale.Lookup(info.Name),
		info.Enabled and Locale.Lookup("LOC_MODS_ENABLED") or Locale.Lookup("LOC_MODS_DISABLED"),
		CAI_GetContentType(info),
	}

	if info.Allowance == false then
		table.insert(parts, Locale.Lookup("LOC_MODS_DETAILS_OWNERSHIP_NO"))
	end
	if Modding.ShouldShowCompatibilityWarnings()
		and not Modding.IsModCompatible(handle)
		and not Modding.GetIgnoreCompatibilityWarnings(handle) then
		table.insert(parts, Locale.Lookup("LOC_MODS_DETAILS_COMPATIBLE_NOT"))
	end

	return table.concat(parts, "[NEWLINE]")
end

local function CAI_GetModTeaser(handle)
	local info = Modding.GetModInfo(handle)
	if not info or info.Teaser == nil then return "" end
	return Modding.GetModText(handle, info.Teaser) or Locale.Lookup(info.Teaser) or ""
end

local CAI_ModFailureTags = {
	ContainsDuplicates = "LOC_MODS_ERROR_MOD_VERSION_ALREADY_ENABLED",
	BlockedByOtherMod = "LOC_MODS_ERROR_MOD_BLOCKED_BY_OTHER_MOD",
	MissingDependencies = "LOC_MODS_ERROR_MOD_MISSING_DEPENDENCIES",
	HasExclusivityConflicts = "LOC_MODS_ERROR_MOD_HAS_EXCLUSIVITY_CONFLICTS",
	BadGameVersion = "LOC_MODS_ERROR_BAD_GAMEVERSION",
	OwnershipRequired = "LOC_MODS_DETAILS_OWNERSHIP_NO",
}

local function CAI_GetModActionFailure(handle, enabling, control)
	local tooltip = CAI_GetTooltip(control)
	if tooltip ~= "" then return tooltip end

	local err
	if enabling then
		err = Modding.CanEnableMod(handle)
		if err == "MissingDependencies" then
			err = Modding.CanEnableMod(handle, true)
		end
	else
		err = Modding.CanDisableMod(handle)
	end
	if err == nil or err == "OK" then
		return Locale.Lookup(enabling and "LOC_CAI_MODS_ENABLE_FAILED" or "LOC_CAI_MODS_DISABLE_FAILED")
	end

	local tag = CAI_ModFailureTags[err]
	if tag then return Locale.Lookup(tag) end
	local prefix = Locale.Lookup(enabling and "LOC_MODS_ENABLE_ERROR" or "LOC_MODS_DISABLE_ERROR")
	return prefix .. tostring(err)
end

local function CAI_ClearPendingModAction()
	CAI_PendingModAction = nil
end

local function CAI_FinishPendingModAction()
	local pending = CAI_PendingModAction
	if not pending then return end

	local info = Modding.GetModInfo(pending.Handle)
	if info and info.Enabled ~= pending.WasEnabled then
		CAI_PendingModAction = nil
		local state = info.Enabled and Locale.Lookup("LOC_MODS_ENABLED") or Locale.Lookup("LOC_MODS_DISABLED")
		Speak(Locale.Lookup("LOC_CAI_MODS_STATE_CHANGED", pending.Name, state), true)
	elseif not pending.AwaitingDialog then
		CAI_PendingModAction = nil
		Speak(CAI_GetModActionFailure(pending.Handle, not pending.WasEnabled, pending.Control), true)
	end
end

local function CAI_AddDetail(parent, suffix, labelGetter, hiddenPredicate)
	local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsDetail"), "MenuItem", {
		Label = labelGetter,
		FocusKey = parent.FocusKey .. ":detail:" .. suffix,
		HiddenPredicate = hiddenPredicate,
	})
	parent:AddChild(row)
	return row
end

local function CAI_AddModDetails(parent, handle)
	CAI_AddDetail(parent, "content", function()
		local info = Modding.GetModInfo(handle)
		return Locale.Lookup("LOC_CAI_MODS_CONTENT_TYPE") .. ", " .. CAI_GetContentType(info)
	end)

	CAI_AddDetail(parent, "compatibility", function()
		return Locale.Lookup("LOC_MODS_DETAILS_NOT_COMPATIBLE_WARNING")
	end, function()
		return Modding.IsModCompatible(handle)
	end)

	CAI_AddDetail(parent, "id", function()
		local info = Modding.GetModInfo(handle)
		return Locale.Lookup("LOC_CAI_MODS_ID") .. ", " .. (info and info.Id or "")
	end)

	CAI_AddDetail(parent, "filename", function()
		local info = Modding.GetModInfo(handle)
		return Locale.Lookup("LOC_CAI_LABEL_FILE_NAME") .. ", " .. (info and info.SourceFileName or "")
	end, function()
		local info = Modding.GetModInfo(handle)
		return not info or info.Source ~= "Map" or info.SourceFileName == nil or info.SourceFileName == ""
	end)

	CAI_AddDetail(parent, "description", function()
		local info = Modding.GetModInfo(handle)
		local description = CAI_GetModPropertyText(handle, "Description")
		if description == "" and info and info.Teaser then
			description = Modding.GetModText(handle, info.Teaser) or Locale.Lookup(info.Teaser) or ""
		end
		return Locale.Lookup("LOC_CAI_MODS_DESCRIPTION") .. ", " .. description
	end, function()
		local info = Modding.GetModInfo(handle)
		return CAI_GetModPropertyText(handle, "Description") == ""
			and (not info or info.Teaser == nil or info.Teaser == "")
	end)

	CAI_AddDetail(parent, "authors", function()
		return Locale.Lookup("LOC_MODS_DETAILS_AUTHOR") .. ", " .. CAI_GetModPropertyText(handle, "Authors")
	end, function()
		return CAI_GetModPropertyText(handle, "Authors") == ""
	end)

	CAI_AddDetail(parent, "thanks", function()
		return Locale.Lookup("LOC_MODS_DETAILS_SPECIAL_THANKS") .. ", "
			.. CAI_GetModPropertyText(handle, "SpecialThanks")
	end, function()
		return CAI_GetModPropertyText(handle, "SpecialThanks") == ""
	end)

	CAI_AddDetail(parent, "created", function()
		local info = Modding.GetModInfo(handle)
		local created = info and info.Created
		local value = created and Locale.Lookup("{1_Created : date long}", created) or ""
		return Locale.Lookup("LOC_MODS_DETAILS_CREATED") .. ", " .. value
	end, function()
		local info = Modding.GetModInfo(handle)
		return not info or info.Created == nil
	end)

	CAI_AddDetail(parent, "ownership", function()
		local info = Modding.GetModInfo(handle)
		local value = info and info.Allowance and Locale.Lookup("LOC_MODS_YES") or Locale.Lookup("LOC_MODS_NO")
		return Locale.Lookup("LOC_MODS_DETAILS_OWNERSHIP") .. ", " .. value
	end, function()
		local info = Modding.GetModInfo(handle)
		return not info or not info.Official or info.Allowance == nil
	end)

	CAI_AddDetail(parent, "savedgames", function()
		local value = Modding.GetModProperty(handle, "AffectsSavedGames")
		local answer = value and tonumber(value) == 0
			and Locale.Lookup("LOC_MODS_NO")
			or Locale.Lookup("LOC_MODS_YES")
		return Locale.Lookup("LOC_MODS_DETAILS_AFFECTS_SAVED_GAMES") .. ", " .. answer
	end)

	CAI_AddDetail(parent, "singleplayer", function()
		local value = Modding.GetModProperty(handle, "SupportsSinglePlayer")
		local answer = value and tonumber(value) == 0
			and Locale.Lookup("LOC_MODS_NO")
			or Locale.Lookup("LOC_MODS_YES")
		return Locale.Lookup("LOC_MODS_DETAILS_SINGLEPLAYER") .. ", " .. answer
	end)

	CAI_AddDetail(parent, "multiplayer", function()
		local value = Modding.GetModProperty(handle, "SupportsMultiplayer")
		local answer = value and tonumber(value) == 0
			and Locale.Lookup("LOC_MODS_NO")
			or Locale.Lookup("LOC_MODS_YES")
		return Locale.Lookup("LOC_MODS_DETAILS_MULTIPLAYER") .. ", " .. answer
	end)

	local dependencies = Modding.GetModAssociations(handle)
	if dependencies and #dependencies > 0 then
		local dependencyNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsDependencies"), "TreeItem", {
			Label = function() return Locale.Lookup("LOC_MODS_DETAILS_REFERENCES_DEPENDENCY") end,
			FocusKey = parent.FocusKey .. ":dependencies",
		})
		local names = {}
		for _, dependency in ipairs(dependencies) do
			local name = CAI_LookupBundleOrText(dependency.Name)
			if name == "" then name = dependency.Id or "" end
			if name ~= "" then table.insert(names, name) end
		end
		table.sort(names, function(a, b) return Locale.Compare(a, b) == -1 end)
		for index, name in ipairs(names) do
			local dependencyName = name
			dependencyNode:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsDependency"), "MenuItem", {
				Label = function() return dependencyName end,
				FocusKey = dependencyNode.FocusKey .. ":" .. tostring(index),
			}))
		end
		parent:AddChild(dependencyNode)
	end
end

local function CAI_SyncIgnoreWarnings()
	if not CAI_IgnoreWarningsCheck then return end
	CAI_IgnoreWarningsCheck:SetChecked(Controls.WhitelistMod:IsChecked(), true)
end

local function CAI_SelectMod(handle)
	if g_SelectedModHandle ~= handle then
		SelectMod(handle)
	end
	CAI_SyncIgnoreWarnings()
end

local function CAI_ToggleMod(handle)
	CAI_SelectMod(handle)
	local info = Modding.GetModInfo(handle)
	if not info then return end

	local control = info.Enabled and Controls.DisableButton or Controls.EnableButton
	if control:IsHidden() or control:IsDisabled() then
		Speak(CAI_GetModActionFailure(handle, not info.Enabled, control), true)
		return
	end

	local awaitingDialog = not info.Enabled
		and Modding.ShouldShowCompatibilityWarnings()
		and not Modding.IsModCompatible(handle)
		and not Modding.GetIgnoreCompatibilityWarnings(handle)
	CAI_PendingModAction = {
		Handle = handle,
		Name = Locale.Lookup(info.Name),
		WasEnabled = info.Enabled,
		AwaitingDialog = awaitingDialog,
		Control = control,
	}
	control:DoLeftClick()
	if CAI_PendingModAction and not awaitingDialog then
		CAI_FinishPendingModAction()
	end
end

local function CAI_RebuildModsTree()
	if not CAI_ModsTree then return end
	local capture = mgr:CaptureFocusKey(CAI_ModsTree)
	CAI_ModsTree:ClearChildren()

	if not g_ModListings or #g_ModListings == 0 then
		CAI_ModsTree:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsEmpty"), "MenuItem", {
			Label = function() return Locale.Lookup("LOC_MODS_NONE_INSTALLED") end,
			FocusKey = "mods:empty",
		}))
	else
		for _, listing in ipairs(g_ModListings) do
			local handle = listing[1]
			local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMod"), "TreeItem", {
				Label = function() return CAI_GetModLabel(handle) end,
				Tooltip = function() return CAI_GetModTeaser(handle) end,
				FocusKey = "mods:installed:" .. tostring(handle),
			})
			row:SetFocusSound("Main_Menu_Mouse_Over")
			row:On("focus_enter", function()
				CAI_SelectMod(handle)
			end)
			row:On("activate", function()
				CAI_ToggleMod(handle)
			end)
			CAI_AddModDetails(row, handle)
			CAI_ModsTree:AddChild(row)
		end
	end

	mgr:RestoreFocus(CAI_ModsTree, capture)
end

local function CAI_BuildSortOptions()
	return {
		{
			label = Locale.Lookup("LOC_CAI_MODS_SORT_NAME"),
			value = g_SortListingsOptions[1][2],
		},
		{
			label = Locale.Lookup("LOC_CAI_MODS_SORT_ENABLED"),
			value = g_SortListingsOptions[2][2],
		},
	}
end

local function CAI_SyncSortDropdown()
	if not CAI_SortDropdown then return end
	local selected = 1
	for index, option in ipairs(g_SortListingsOptions) do
		if option[2] == g_CurrentListingsSort then
			selected = index
			break
		end
	end
	CAI_SortDropdown:SetSelectedIndex(selected, true)
end

local function CAI_GetSortedGroups()
	local groups = Modding.GetModGroups() or {}
	for _, group in ipairs(groups) do
		group.DisplayName = Locale.Lookup(group.Name)
	end
	table.sort(groups, function(a, b)
		if a.SortIndex == b.SortIndex then
			return Locale.Compare(a.DisplayName, b.DisplayName) == -1
		end
		return a.SortIndex < b.SortIndex
	end)
	return groups
end

local function CAI_SyncGroupDropdown()
	if not CAI_GroupDropdown then return end
	local groups = CAI_GetSortedGroups()
	local current = Modding.GetCurrentModGroup()
	local options = {}
	local selected = 1
	for index, group in ipairs(groups) do
		table.insert(options, {
			label = group.DisplayName,
			value = group.Handle,
		})
		if group.Handle == current then selected = index end
	end
	CAI_GroupDropdown:SetOptions(options)
	if #options > 0 then CAI_GroupDropdown:SetSelectedIndex(selected, true) end
end

local function CAI_SyncInstalledControls()
	if CAI_OfficialCheck then
		CAI_OfficialCheck:SetChecked(Controls.ShowOfficialContent:IsChecked(), true)
	end
	if CAI_CommunityCheck then
		CAI_CommunityCheck:SetChecked(Controls.ShowCommunityContent:IsChecked(), true)
	end
	CAI_SyncIgnoreWarnings()
	CAI_SyncSortDropdown()
	CAI_SyncGroupDropdown()
end

local function CAI_ModsSearchHandler(query, maxResults)
	local results = {}
	local seen = {}
	if not Search.HasContext(g_SearchContext) then return results end

	local raw = Search.Search(g_SearchContext, query)
	if not raw then return results end
	for _, hit in ipairs(raw) do
		local handle = tonumber(hit[1]) or hit[1]
		local key = tostring(handle)
		if not seen[key] and Modding.GetModInfo(handle) then
			seen[key] = true
			local resultHandle = handle
			results[#results + 1] = {
				key = "mods:search:" .. key,
				label = CAI_GetModLabel(resultHandle),
				tooltip = CAI_GetModTeaser(resultHandle),
				onActivate = function()
					local target = mgr:FindByFocusKey(CAI_ModsTree, "mods:installed:" .. tostring(resultHandle))
					if target then mgr:SetFocus(target) end
				end,
			}
			if #results >= maxResults then break end
		end
	end
	return results
end

local function CAI_RemoveGroupDialog()
	if not CAI_GroupDialog then return end
	mgr:RemoveFromStack(CAI_GroupDialog:GetId())
	CAI_GroupDialog = nil
end

local function CAI_MakeGroupDialog()
	CAI_RemoveGroupDialog()
	if Controls.NameModGroupPopup:IsHidden() then return end

	local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModGroupName"), "EditBox", {
		Label = function() return CAI_GetText(Controls.BindingTitle) end,
	})
	edit:SetText(Controls.ModGroupEditBox:GetText() or "", true)
	edit:SetAlwaysEdit(true)
	edit:SetEnterToCommit(false)
	edit:SetMaxCharacters(40)
	edit:On("text_changed", function(_, text)
		Controls.ModGroupEditBox:SetText(text)
	end)

	local cancel = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModGroupCancel"), "Button", {
		Label = function() return CAI_GetText(Controls.CancelBindingButton) end,
	})
	cancel:On("activate", function()
		Controls.CancelBindingButton:DoLeftClick()
		CAI_RemoveGroupDialog()
	end)

	local create = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModGroupCreate"), "Button", {
		Label = function() return CAI_GetText(Controls.CreateModGroupButton) end,
		DisabledPredicate = function() return Controls.CreateModGroupButton:IsDisabled() end,
	})
	create:On("activate", function()
		Controls.CreateModGroupButton:DoLeftClick()
		CAI_RemoveGroupDialog()
	end)

	CAI_GroupDialog = mgr.WidgetHelpers.MakeGeneralDialog(
		function() return CAI_GetText(Controls.BindingTitle) end,
		{ create, cancel },
		{ edit },
		1
	)
	if CAI_GroupDialog then
		mgr:Push(CAI_GroupDialog, { priority = PopupPriority.Current, focus = edit })
	end
end

local function CAI_BuildInstalledPage(page)
	CAI_ModsTree = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsInstalledTree"), "Tree", {
		Label = function() return Locale.Lookup("LOC_CAI_MODS_INSTALLED_TREE") end,
		FocusKey = "mods:installed:tree",
	})
	CAI_ModsTree:SetSearchQueryHandler(CAI_ModsSearchHandler)
	CAI_ModsTree:SetSearchHistoryContext("mods")
	page:AddChild(CAI_ModsTree)

	CAI_SortDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsSort"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_CAI_LABEL_SORT_BY") end,
		FocusKey = "mods:sort",
	})
	CAI_SortDropdown:SetOptions(CAI_BuildSortOptions())
	CAI_SortDropdown:SetValueSetter(function(_, sorter)
		CAI_ClearPendingModAction()
		g_CurrentListingsSort = sorter
		for _, option in ipairs(g_SortListingsOptions) do
			if option[2] == sorter then
				Controls.SortListingsPullDown:GetButton():LocalizeAndSetText(option[1])
				break
			end
		end
		RefreshListings()
	end)
	page:AddChild(CAI_SortDropdown)

	CAI_OfficialCheck = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsOfficial"), "Checkbox", {
		Label = function() return Locale.Lookup("LOC_MODS_FIRAXIAN_CONTENT") end,
		Tooltip = function() return CAI_GetTooltip(Controls.ShowOfficialContent) end,
		FocusKey = "mods:filter:official",
	})
	CAI_OfficialCheck:SetValueSetter(function(_, checked)
		CAI_ClearPendingModAction()
		if Controls.ShowOfficialContent:IsChecked() ~= checked then
			Controls.ShowOfficialContent:DoLeftClick()
		end
	end)
	page:AddChild(CAI_OfficialCheck)

	CAI_CommunityCheck = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsCommunity"), "Checkbox", {
		Label = function() return Locale.Lookup("LOC_MODS_USER_CONTENT") end,
		Tooltip = function() return CAI_GetTooltip(Controls.ShowCommunityContent) end,
		FocusKey = "mods:filter:community",
	})
	CAI_CommunityCheck:SetValueSetter(function(_, checked)
		CAI_ClearPendingModAction()
		if Controls.ShowCommunityContent:IsChecked() ~= checked then
			Controls.ShowCommunityContent:DoLeftClick()
		end
	end)
	page:AddChild(CAI_CommunityCheck)

	CAI_IgnoreWarningsCheck = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsIgnoreWarnings"), "Checkbox", {
		Label = function() return Locale.Lookup("LOC_MODS_DETAILS_COMPATIBILITY_WHITELIST_PROMPT") end,
		HiddenPredicate = function()
			return g_SelectedModHandle == nil
				or Modding.IsModCompatible(g_SelectedModHandle)
				or Controls.WhitelistMod:IsHidden()
		end,
		FocusKey = "mods:ignore-warnings",
	})
	CAI_IgnoreWarningsCheck:SetValueSetter(function(_, checked)
		CAI_ClearPendingModAction()
		if Controls.WhitelistMod:IsChecked() ~= checked then
			Controls.WhitelistMod:DoLeftClick()
		end
	end)
	page:AddChild(CAI_IgnoreWarningsCheck)

	CAI_GroupDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsGroups"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_CAI_MODS_GROUP") end,
		FocusKey = "mods:group",
	})
	CAI_GroupDropdown:SetValueSetter(function(_, handle)
		CAI_ClearPendingModAction()
		Modding.SetCurrentModGroup(handle)
		RefreshModGroups()
		RefreshListings()
	end)
	page:AddChild(CAI_GroupDropdown)

	local createGroup = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsCreateGroup"), "Button", {
		Label = function() return Locale.Lookup("LOC_CAI_MODS_CREATE_GROUP") end,
		Tooltip = function() return CAI_GetTooltip(Controls.CreateModGroup) end,
		DisabledPredicate = function() return Controls.CreateModGroup:IsDisabled() end,
		FocusKey = "mods:group:create",
	})
	createGroup:On("activate", function()
		CAI_ClearPendingModAction()
		Controls.CreateModGroup:DoLeftClick()
	end)
	page:AddChild(createGroup)

	local deleteGroup = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsDeleteGroup"), "Button", {
		Label = function() return Locale.Lookup("LOC_CAI_MODS_DELETE_GROUP") end,
		Tooltip = function() return CAI_GetTooltip(Controls.DeleteModGroup) end,
		DisabledPredicate = function() return Controls.DeleteModGroup:IsDisabled() end,
		FocusKey = "mods:group:delete",
	})
	deleteGroup:On("activate", function()
		CAI_ClearPendingModAction()
		local current = Modding.GetCurrentModGroup()
		local deletedName = ""
		for _, group in ipairs(CAI_GetSortedGroups()) do
			if group.Handle == current then
				deletedName = group.DisplayName
				break
			end
		end
		Controls.DeleteModGroup:DoLeftClick()
		if deletedName ~= "" then
			Speak(Locale.Lookup("LOC_CAI_MODS_GROUP_DELETED", deletedName), true)
		end
	end)
	page:AddChild(deleteGroup)

	local enableAll = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsEnableAll"), "Button", {
		Label = function() return Locale.Lookup("LOC_MODS_ENABLE_ALL") end,
		DisabledPredicate = function() return Controls.EnableAll:IsDisabled() end,
		FocusKey = "mods:enable-all",
	})
	enableAll:On("activate", function()
		CAI_ClearPendingModAction()
		local before = {}
		local willShowDialog = false
		for _, listing in ipairs(g_ModListings or {}) do
			local handle = listing[1]
			local info = Modding.GetModInfo(handle)
			if info then
				before[handle] = info.Enabled
				local err = Modding.CanEnableMod(handle, true)
				if not info.Enabled and err == "OK"
					and Modding.ShouldShowCompatibilityWarnings()
					and not Modding.IsModCompatible(handle)
					and not Modding.GetIgnoreCompatibilityWarnings(handle) then
					willShowDialog = true
				end
			end
		end
		Controls.EnableAll:DoLeftClick()
		if willShowDialog then return end

		local changed = 0
		for handle, wasEnabled in pairs(before) do
			local info = Modding.GetModInfo(handle)
			if not wasEnabled and info and info.Enabled then changed = changed + 1 end
		end
		Speak(Locale.Lookup(
			changed > 0 and "LOC_CAI_MODS_ENABLED_COUNT" or "LOC_CAI_MODS_NONE_ENABLED",
			changed
		), true)
	end)
	page:AddChild(enableAll)

	local disableAll = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsDisableAll"), "Button", {
		Label = function() return Locale.Lookup("LOC_MODS_DISABLE_ALL") end,
		DisabledPredicate = function() return Controls.DisableAll:IsDisabled() end,
		FocusKey = "mods:disable-all",
	})
	disableAll:On("activate", function()
		CAI_ClearPendingModAction()
		local before = {}
		for _, listing in ipairs(g_ModListings or {}) do
			local handle = listing[1]
			local info = Modding.GetModInfo(handle)
			if info then before[handle] = info.Enabled end
		end
		Controls.DisableAll:DoLeftClick()

		local changed = 0
		for handle, wasEnabled in pairs(before) do
			local info = Modding.GetModInfo(handle)
			if wasEnabled and info and not info.Enabled then changed = changed + 1 end
		end
		Speak(Locale.Lookup(
			changed > 0 and "LOC_CAI_MODS_DISABLED_COUNT" or "LOC_CAI_MODS_NONE_DISABLED",
			changed
		), true)
	end)
	page:AddChild(disableAll)

	CAI_SyncInstalledControls()
	CAI_RebuildModsTree()
end

local function CAI_GetSubscriptionLabel(item)
	local instance = item and item.Instance
	if not instance then return "" end
	return CAI_GetText(instance.SubscriptionTitle)
end

local function CAI_GetSubscriptionTooltip(item)
	local instance = item and item.Instance
	if not instance then return "" end
	local parts = {
		CAI_GetText(instance.SubscriptionStatus),
		CAI_GetText(instance.LastUpdated),
	}
	local result = {}
	for _, part in ipairs(parts) do
		if part ~= "" then table.insert(result, part) end
	end
	return table.concat(result, "[NEWLINE]")
end

local function CAI_FilterPendingUnsubscriptions()
	if not g_Subscriptions then return end

	local returned = {}
	for _, item in ipairs(g_Subscriptions) do
		returned[tostring(item.SubscriptionId)] = true
	end
	for id in pairs(CAI_PendingUnsubscriptions) do
		if not returned[id] then CAI_PendingUnsubscriptions[id] = nil end
	end
	for index = #g_Subscriptions, 1, -1 do
		local item = g_Subscriptions[index]
		if CAI_PendingUnsubscriptions[tostring(item.SubscriptionId)] then
			item.Instance.SubscriptionInstanceRoot:SetHide(true)
			table.remove(g_Subscriptions, index)
		end
	end
end

local function CAI_RebuildSubscriptionsList(preferredFocusKey)
	if not CAI_SubscriptionsList then return end
	local capture = mgr:CaptureFocusKey(CAI_SubscriptionsList)
	if capture and preferredFocusKey then capture.key = preferredFocusKey end
	CAI_SubscriptionsList:ClearChildren()

	if not g_Subscriptions or #g_Subscriptions == 0 then
		CAI_SubscriptionsList:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAISubscriptionsEmpty"), "MenuItem", {
			Label = function() return Locale.Lookup("LOC_MODS_NO_SUBSCRIPTIONS") end,
			FocusKey = "mods:subscriptions:empty",
		}))
	else
		for _, subscription in ipairs(g_Subscriptions) do
			local item = subscription
			local instance = item.Instance
			local id = item.SubscriptionId
			local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModSubscription"), "Button", {
				Label = function() return CAI_GetSubscriptionLabel(item) end,
				Tooltip = function() return CAI_GetSubscriptionTooltip(item) end,
				FocusKey = "mods:subscription:" .. tostring(id),
			})
			row:SetFocusSound("Main_Menu_Mouse_Over")
			row:On("activate", function()
				if not instance.SubscriptionUpdateButton:IsHidden()
					and not instance.SubscriptionUpdateButton:IsDisabled() then
					instance.SubscriptionUpdateButton:DoLeftClick()
				elseif not instance.SubscriptionViewButton:IsHidden()
					and not instance.SubscriptionViewButton:IsDisabled() then
					instance.SubscriptionViewButton:DoLeftClick()
				end
			end)
			row:AddInputBinding({
				Key = Keys.VK_RETURN,
				IsControl = true,
				Description = "LOC_MODS_VIEW",
				Action = function()
					if not instance.SubscriptionViewButton:IsHidden()
						and not instance.SubscriptionViewButton:IsDisabled() then
						instance.SubscriptionViewButton:DoLeftClick()
					end
					return true
				end,
			})
			row:AddInputBinding({
				Key = Keys.VK_DELETE,
				Description = "LOC_MODS_UNSUBSCRIBE",
				Action = function()
					if not instance.UnsubscribeButton:IsHidden()
						and not instance.UnsubscribeButton:IsDisabled() then
						local name = CAI_GetText(instance.SubscriptionTitle)
						instance.UnsubscribeButton:DoLeftClick()
						CAI_PendingUnsubscriptions[tostring(id)] = true

						local removedIndex = nil
						for index = #g_Subscriptions, 1, -1 do
							if g_Subscriptions[index].SubscriptionId == id then
								table.remove(g_Subscriptions, index)
								removedIndex = index
								break
							end
						end
						local nextItem = removedIndex and (g_Subscriptions[removedIndex] or g_Subscriptions[removedIndex - 1])
						local nextKey = nextItem
							and "mods:subscription:" .. tostring(nextItem.SubscriptionId)
							or nil
						CAI_RebuildSubscriptionsList(nextKey)
						Speak(Locale.Lookup("LOC_CAI_MODS_UNSUBSCRIBED", name), true)
					end
					return true
				end,
			})
			CAI_SubscriptionsList:AddChild(row)
		end
	end

	mgr:RestoreFocus(CAI_SubscriptionsList, capture)
end

local function CAI_BuildSubscriptionsPage(page)
	CAI_SubscriptionsList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsSubscriptionsList"), "List", {
		Label = function() return Locale.Lookup("LOC_CAI_MODS_SUBSCRIPTIONS_LIST") end,
		FocusKey = "mods:subscriptions:list",
	})
	page:AddChild(CAI_SubscriptionsList)

	local browse = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsBrowseWorkshop"), "Button", {
		Label = function() return CAI_GetText(Controls.BrowseWorkshop) end,
		Tooltip = function() return CAI_GetTooltip(Controls.BrowseWorkshop) end,
		HiddenPredicate = function() return Controls.BrowseWorkshop:IsHidden() end,
		DisabledPredicate = function() return Controls.BrowseWorkshop:IsDisabled() end,
		FocusKey = "mods:subscriptions:browse",
	})
	browse:On("activate", function() Controls.BrowseWorkshop:DoLeftClick() end)
	page:AddChild(browse)

	CAI_RebuildSubscriptionsList()
end

local function CAI_BuildPanel()
	CAI_Panel = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsPanel"), "Panel", {
		Label = function() return Locale.Lookup("LOC_MODS_TITLE") end,
	})
	CAI_Tabs = mgr:CreateWidget(mgr:GenerateWidgetId("CAIModsTabs"), "TabControl", {
		Label = function() return Locale.Lookup("LOC_MODS_TITLE") end,
	})
	CAI_Panel:AddChild(CAI_Tabs)

	CAI_InstalledPage = CAI_Tabs:AddPage(function() return Locale.Lookup("LOC_MODS_INSTALLED") end)
	CAI_BuildInstalledPage(CAI_InstalledPage)

	if not Controls.SubscriptionsTab:IsHidden() then
		CAI_SubscriptionsPage = CAI_Tabs:AddPage(function()
			return Locale.Lookup("LOC_MODS_SUBSCRIPTIONS")
		end)
		CAI_BuildSubscriptionsPage(CAI_SubscriptionsPage)
	end

	CAI_Tabs:On("value_changed", function(_, index)
		if CAI_SyncingTabs then return end
		CAI_ClearPendingModAction()
		if index == 1 then
			Controls.InstalledTab:DoLeftClick()
		elseif index == 2 and CAI_SubscriptionsPage then
			Controls.SubscriptionsTab:DoLeftClick()
		end
	end)
end

local function CAI_OpenPanel()
	if CAI_Panel then return end
	CAI_BuildPanel()
	mgr:Push(CAI_Panel, { priority = PopupPriority.Current, focus = CAI_ModsTree })
end

local function CAI_ClosePanel()
	CAI_RemoveGroupDialog()
	if CAI_Panel then
		mgr:RemoveFromStack(CAI_Panel:GetId())
	end
	CAI_Panel = nil
	CAI_Tabs = nil
	CAI_InstalledPage = nil
	CAI_SubscriptionsPage = nil
	CAI_ModsTree = nil
	CAI_SubscriptionsList = nil
	CAI_SortDropdown = nil
	CAI_OfficialCheck = nil
	CAI_CommunityCheck = nil
	CAI_IgnoreWarningsCheck = nil
	CAI_GroupDropdown = nil
end

RefreshListings = WrapFunc(RefreshListings, function(orig)
	orig()
	CAI_SyncInstalledControls()
	CAI_RebuildModsTree()
	CAI_FinishPendingModAction()
end)

RefreshModGroups = WrapFunc(RefreshModGroups, function(orig)
	orig()
	CAI_SyncGroupDropdown()
end)

RefreshSubscriptions = WrapFunc(RefreshSubscriptions, function(orig)
	orig()
	CAI_FilterPendingUnsubscriptions()
	CAI_RebuildSubscriptionsList()
end)

CreateModGroup = WrapFunc(CreateModGroup, function(orig)
	orig()
	Controls.ModGroupEditBox:DropFocus()
	CAI_MakeGroupDialog()
end)

OnInstalledModsTabClick = WrapFunc(OnInstalledModsTabClick, function(orig, ...)
	orig(...)
	if CAI_Tabs and CAI_Tabs:GetActivePageIndex() ~= 1 then
		CAI_SyncingTabs = true
		CAI_Tabs:SetActivePage(1, true)
		CAI_SyncingTabs = false
	end
end)

OnSubscriptionsTabClick = WrapFunc(OnSubscriptionsTabClick, function(orig, ...)
	orig(...)
	if CAI_Tabs and CAI_SubscriptionsPage and CAI_Tabs:GetActivePageIndex() ~= 2 then
		CAI_SyncingTabs = true
		CAI_Tabs:SetActivePage(2, true)
		CAI_SyncingTabs = false
	end
end)

OnShow = WrapFunc(OnShow, function(orig)
	orig()
	if CAI_PostInitialized then
		CAI_OpenPanel()
	end
end)

PostInit = WrapFunc(PostInit, function(orig)
	orig()
	CAI_PostInitialized = true
	if not ContextPtr:IsHidden() then
		CAI_OpenPanel()
	end
end)

HandleExitRequest = WrapFunc(HandleExitRequest, function(orig)
	CAI_ClosePanel()
	orig()
end)

OnUpdate = WrapFunc(OnUpdate, function(orig, delta)
	orig(delta)
	if CAI_GroupDialog and Controls.NameModGroupPopup:IsHidden() then
		CAI_RemoveGroupDialog()
	end
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	ContextPtr:SetHideHandler(function()
		CAI_ClosePanel()
	end)
	ContextPtr:SetInputHandler(function(input)
		if mgr and mgr:HandleInput(input) then return true end
		if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE
			and CAI_GroupDialog then
			Controls.CancelBindingButton:DoLeftClick()
			CAI_RemoveGroupDialog()
			return true
		end
		return InputHandler(input:GetMessageType(), input:GetKey(), nil)
	end, true)
end)
--#End of accessibility integration

Initialize();
