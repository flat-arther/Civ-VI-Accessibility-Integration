-------------------------------------------------
-- Game Summaries Screen
-------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "PopupDialog" );

local MIN_SCREEN_Y				:number = 768;

----------------------------------------------------------------   
-- Utilities
----------------------------------------------------------------    
-- Attempt to set a control's icon by enumerating an array.
function SetControlIcon(control, icons)
	if(icons) then
		local s = #icons;
		for i = s, 1, -1 do
			local v = icons[i];
			if(control:TrySetIcon(v)) then
				return true;
			end
		end
	end

	return false;
end


-- Global Constants
g_TabControls = {
	{Controls.OverviewTab, Controls.SelectedOverviewTab, Controls.OverviewTabPanel},
	{Controls.HistoryTab, Controls.SelectedHistoryTab, Controls.HistoryTabPanel},
};

-- Global Variables
g_GamesManager = InstanceManager:new("GameInstance", "Button", Controls.ListingsStack);
g_LeaderProgressManager = InstanceManager:new("LeaderProgressInstance", "Icon", Controls.LeaderProgressStack);
g_VictoryProgressManager = InstanceManager:new("VictoryProgressInstance", "Root", Controls.VictoryProgressStack);

g_HighlightsManager = InstanceManager:new("StatInstance", "Root", Controls.HighlightsStack);
g_StatisticsBlockManager = InstanceManager:new("StatBlockInstance", "RootStack", Controls.StatisticsStack);
g_StatisticsManagers = {};
		
g_AvailableRulesets = nil; 			-- Array of available rulesets.
g_CurrentRuleset = nil; 			-- Currently selected ruleset.
g_Games = nil;						-- List of game history data. 
g_GameListings = nil;				-- List of game history listings.
g_GameListingsSortFunction = nil;	-- Currently selected sort method.
g_SortDirectionReversed = false;	-- Reverse the sort?
g_SelectedGameId = nil;				-- Track currently selected listing.
g_RulesetPlayers = nil;				-- Map of all ruleset playable leaders
g_RulesetTypes = nil;				-- Map of all ruleset types.	
g_RulesetVictories = nil;			-- Map/Array of all ruleset victories.
g_Categories = nil;					-- Sorted array of all statistics categories.
g_Statistics = nil;					-- Sorted array of all statistics.

-- Release cache to free up memory.
function DumpCache()
	g_AvailableRulesets = nil;
	g_CurrentRuleset = nil;
	g_Games = nil;
	g_GameListings = nil;
	g_SelectedGameListingHandle = nil;
	g_RulesetPlayers = nil;
	g_RulesetTypes = nil;
	g_RulesetVictories = nil;
	g_Categories = nil;
	g_Statistics = nil;
end

function DumpInstances()
	for i,v in ipairs(g_StatisticsManagers) do
		v:ResetInstances();
	end
	g_HighlightsManager:ResetInstances();
	g_StatisticsBlockManager:ResetInstances();
	g_StatisticsManagers = {};
	
	g_GamesManager:ResetInstances();
	g_LeaderProgressManager:ResetInstances();
	g_VictoryProgressManager:ResetInstances();
end

-- Much of hall of fame is read-only and static so it can be cached.
function UpdateGlobalCache()
	DumpCache();

	local gameObjects = HallofFame.GetGameObjects();
	g_GameObjects = {};
	for i,v in ipairs(gameObjects) do
		g_GameObjects[v.ObjectId] = v;
	end

	g_AvailableRulesets = HallofFame.GetAvailableRulesets();	
	if(g_AvailableRulesets and #g_AvailableRulesets > 0) then
		for i,v in ipairs(g_AvailableRulesets) do
			v.DisplayName = Locale.Lookup(v.Name);
		end

		table.sort(g_AvailableRulesets, function(a,b) 
			if(a.SortIndex ~= b.SortIndex) then
				return a.SortIndex < b.SortIndex;
			else
				return Locale.Compare(a.DisplayName, b.DisplayName) == -1;
			end
		end);
	else
		g_CurrentRuleset = nil;
	end
end

function UpdateRulesetCache()
	local ruleset = g_CurrentRuleset.Ruleset
	local players = HallofFame.GetRulesetPlayableLeaders(ruleset);
	g_RulesetPlayers = {};
	for i,v in ipairs(players) do
		g_RulesetPlayers[v.LeaderType] = v;
	end
	
	g_RulesetTypes = HallofFame.GetRulesetTypes(ruleset);	

	local victoryProgress = nil;
	if(g_CurrentRuleset.ChallengeIds) then
		victoryProgress = Challenges.GetChallengeVictoryProgress(g_CurrentRuleset.ChallengeIds);
	else
		victoryProgress = HallofFame.GetVictoryProgress(ruleset);
	end
	
	g_RulesetVictories = {};
	for k,v in pairs(victoryProgress) do
	
		-- Localize Name 
		v.Name = Locale.Lookup(v.Name);

		v.Icons = {"ICON_VICTORY_UNIVERSAL"};
		table.insert(v.Icons, "ICON_" .. v.Type);
		table.insert(v.Icons, v.Icon);
		
		-- Store in an array to be sorted.
		table.insert(g_RulesetVictories, v);

		-- Store as id lookup as well.
		g_RulesetVictories[v.Type] = v;
	end
	
	table.sort(g_RulesetVictories, function(a,b)
		return Locale.Compare(a.Name, b.Name) == -1;
	end);
	
	local indexed_categories = {};
	if (g_CurrentRuleset.ChallengeIds) then
		-- We do not want to show any statistics for challenge game modes
		g_Categories = {};
	else
		g_Categories = HallofFame.GetStatisticsCategories(ruleset);

		for i,v in ipairs(g_Categories) do
			indexed_categories[v.Category] = v;
			v.Name = v.Name and Locale.Lookup(v.Name) or "";
		end
		table.sort(g_Categories, function(a,b)
			if(a.SortIndex ~= b.SortIndex) then
				return a.SortIndex < b.SortIndex;
			else
				return Locale.Compare(a.Name,b.Name) == -1;
			end
		end);
	end

	g_Statistics = {};

	-- We do not want to show any statistics for challenge game modes
	if (g_CurrentRuleset.ChallengeIds == nil) then
		local statistics = HallofFame.GetStatistics(ruleset);
		for i,stat in ipairs(statistics) do
			local cat = indexed_categories[stat.Category];
			if(cat and not cat.IsHidden) then
				stat.Name = Locale.Lookup(stat.Name);
				table.insert(g_Statistics, stat);
			end
		end
	end

	table.sort(g_Statistics, function(a,b)
		if(a.Importance ~= b.Importance) then
			return a.Importance > b.Importance;
		else
			return Locale.Compare(a.Name, b.Name) == -1;
		end
	end);
end

function SelectTab(index)
	for i,v in ipairs(g_TabControls) do
		if(i ~= index) then
			v[1]:SetSelected(false);
			v[2]:SetHide(true);
			v[3]:SetHide(true);
		end
	end
	
	g_TabControls[index][3]:SetHide(false);
	g_TabControls[index][2]:SetHide(false);
	g_TabControls[index][1]:SetSelected(true);
end

function SelectRuleset(index)
	g_CurrentRuleset = g_AvailableRulesets[index];
	Controls.RulesetPullDown:GetButton():SetText(g_CurrentRuleset.DisplayName);
	
	UpdateRulesetCache();

	Overview_PopulateHighlights();
	Overview_PopulateVictoryProgress();
	Overview_PopulateLeaderProgress();
	Overview_PopulateStatistics();
	History_PopulateGames();
end
----------------------------------------------------------------  
function SelectGameListing(gameId)
	g_SelectedGameId = gameId;
	History_RefreshSelectionState();
end

function LoadConfiguration()

end

----------------------------------------------------------------   
-- Populate Methods
----------------------------------------------------------------   
function PopulateAvailableRulesets()
	local rulesets = g_AvailableRulesets or {};
	local comboBox = Controls.RulesetPullDown;
	comboBox:ClearEntries();
	for i, v in ipairs(rulesets) do
		local controlTable = {};
		comboBox:BuildEntry( "InstanceOne", controlTable );
		controlTable.Button:SetText(v.DisplayName);
	
		controlTable.Button:RegisterCallback(Mouse.eLClick, function()
			SelectRuleset(i);
		end);	
	end

	comboBox:CalculateInternals();
end

function Overview_PopulateHighlights()
	-- Clear instances.
	g_HighlightsManager:ResetInstances();
	
	--local stats = HallofFame.GetRulesetHighlights(g_CurrentRuleset.Value, 10) or {};
	--
	--if(#stats == 0) then
		--Controls.Highlights:SetHide(true);
		--return;
	--end
	--
	--Controls.Highlights:SetHide(false);
	--
	---- Process Data
	--for i,v in ipairs(stats) do
		--v.Name = Locale.Lookup(v.Name);
		--if(v.ValueType) then
			--local t = g_RulesetTypes[v.ValueType];
			--if(t) then
				--v.ValueIcon = t.Icon or ("ICON_" .. t.Type);
				--v.DisplayValue = Locale.Lookup(t.Name);
			--end
		--elseif(v.ValueObjectId) then
			--local o = g_GameObjects[v.ValueObjectId];
			--if(o) then
				--v.ValueIcon = o.Icon or v.ValueIcon;
				--v.DisplayValue = Locale.Lookup(o.Name);
			--end
		--elseif(v.ValueString) then
			--v.DisplayValue = Locale.Lookup(v.ValueString);
		--elseif(v.ValueNumeric) then
			--v.DisplayValue = Locale.ToNumber(v.ValueNumeric, "###,###");
		--end	
--
		--if(v.Annotation) then
			--v.Annotation = Locale.Lookup(v.Annotation, {Name = "Amount", Value = v.ValueNumeric});
		--end			
	--end
		--
	---- sort stats (Importance Desc, Name)
	--table.sort(stats, function(a,b)
		--if(a.Importance ~= b.Importance) then
			--return a.Importance > b.Importance;
		--else
			--return Locale.Compare(a.Name, b.Name) == -1;
		--end
	--end);
	--
	--for _,stat in ipairs(stats) do
		--if(stat.DisplayValue) then
			--local instance = g_HighlightsManager:GetInstance();
					--
			--if(stat.Icon and instance.TitleIcon:TrySetIcon(stat.Icon)) then
				--instance.TitleIcon:SetHide(false);
			--else
				--instance.TitleIcon:SetHide(true);
			--end
			--instance.TitleCaption:LocalizeAndSetText(stat.Name);
			--
			--if(stat.ValueIcon and instance.ValueIcon:TrySetIcon(stat.ValueIcon)) then
				--instance.ValueIcon:SetHide(false);
			--else
				--instance.ValueIcon:SetHide(true);
			--end
			--
			--instance.ValueCaption:SetText(stat.DisplayValue);
			--if(stat.Annotation) then
				--instance.Annotation:LocalizeAndSetText(stat.Annotation);
				--instance.Annotation:SetHide(false);
			--else
				--instance.Annotation:SetHide(true);
			--end
			--
			--instance.AnnotationStack:CalculateSize();
			--instance.AnnotationStack:ReprocessAnchoring();
			--instance.TitleStack:CalculateSize();
			--instance.TitleStack:ReprocessAnchoring();
			--instance.ValueStack:CalculateSize();
			--instance.ValueStack:ReprocessAnchoring();
		--end
	--end
	
	Controls.HighlightsStack:CalculateSize();
	Controls.HighlightsStack:ReprocessAnchoring();
end

function Overview_PopulateVictoryProgress()
	g_VictoryProgressManager:ResetInstances();
	for i, v in ipairs(g_RulesetVictories) do
		if(not v.Hidden and ((v.IsAvailableForChallenge == nil) or v.IsAvailableForChallenge)) then
			local instance = g_VictoryProgressManager:GetInstance();
		
			local tooltip = v.Name;
		
			if(tonumber(v.Count) > 0) then
				tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_COUNT", v.Count);	
				instance.Icon:SetColor(UI.GetColorValue(1,1,1,1));
				instance.Root:SetColor(UI.GetColorValue(1,1,1,1));
			else
				instance.Icon:SetColor(UI.GetColorValue(1,1,1,0.25));
				instance.Root:SetColor(UI.GetColorValue(1,1,1,0.25));
			end
		
			if(v.MostRecentLeaderType ~= nil) then
				local player = g_RulesetPlayers[v.MostRecentLeaderType];
				if(player) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_LEADER", player.LeaderName);
				end
			end

			SetControlIcon(instance.Icon, v.Icons)
			instance.Icon:SetToolTipString(tooltip);
		end
	end

	-- Add badge for challenge victory if the current page deals with a challenge game
	if (g_CurrentRuleset.ChallengeIds and Challenges.ChallengeHasCustomBadge(g_CurrentRuleset.ChallengeIds)) then
		-- Split challenge ids into individual strings
		for challengeId in string.gmatch(g_CurrentRuleset.ChallengeIds, "([^ ]+)") do
			local badgeDisplayInfo = Challenges.GetChallengeBadgeDisplayInfo(challengeId);

			if (badgeDisplayInfo) then
				local instance = g_VictoryProgressManager:GetInstance();
				local tooltip = badgeDisplayInfo.BadgeName;
				
				if(tonumber(badgeDisplayInfo.VictoryCount) > 0) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_COUNT", badgeDisplayInfo.VictoryCount);
					instance.Icon:SetColor(UI.GetColorValue(1,1,1,1));
					instance.Root:SetColor(UI.GetColorValue(1,1,1,1));
				else
					instance.Icon:SetColor(UI.GetColorValue(1,1,1,0.25));
					instance.Root:SetColor(UI.GetColorValue(1,1,1,0.25));
				end

				if(badgeDisplayInfo.MostRecentLeaderName) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_LEADER", badgeDisplayInfo.MostRecentLeaderName);
				end

				Challenges.BindCustomChallengeBadgeImageToControl(challengeId, instance.Icon);
				instance.Icon:SetToolTipString(tooltip);
			end
		end
	end
end

function Overview_PopulateLeaderProgress()
	local leaderProgress = nil;
	if (g_CurrentRuleset.ChallengeIds) then
		leaderProgress = Challenges.GetChallengeLeaderProgress(g_CurrentRuleset.ChallengeIds);
	else
		leaderProgress = HallofFame.GetLeaderProgress(g_CurrentRuleset.Ruleset);
	end
	
	
	local leaders = {};
	for k,v in pairs(leaderProgress) do
	
		-- Pre-translate for sorting.
		local player = g_RulesetPlayers[k];
		v.LeaderName = Locale.Lookup(player.LeaderName);
		v.LeaderIcon = player.LeaderIcon or ("ICON_" .. v.LeaderType);
		
		-- Insert into an array for sorting.
		table.insert(leaders, v);
	end
	
	table.sort(leaders, function(a,b)
		return Locale.Compare(a.LeaderName, b.LeaderName) == -1;
	end);
	
	-- Determine how many possible victories there are.
	-- If there is only 1 possible visible victory type, we don't need to show it in the tooltip.
	local visibleVictoryCount = 0;
	for i,v in ipairs(g_RulesetVictories) do
		if(not v.Hidden) then
			visibleVictoryCount = visibleVictoryCount + 1;
		end
	end

	g_LeaderProgressManager:ResetInstances();
	for i, v in ipairs(leaders) do
		local instance = g_LeaderProgressManager:GetInstance();
		
		local tooltip = v.LeaderName;
		if(v.MostRecentVictoryType ~= nil) then
			tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_WINCOUNT", v.VictoryCount, v.PlayCount);

			-- Only show the most recent victory type if there are more than 1 possible victories.
			if(visibleVictoryCount > 1) then
				local victory = g_RulesetVictories[v.MostRecentVictoryType];
				if(victory) then
					tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_VICTORY", victory.Name);
				end
			end

			instance.Icon:SetColor(UI.GetColorValue(1,1,1,1));
		else
			if(tonumber(v.PlayCount) > 0) then
				tooltip = tooltip .. "[NEWLINE]" .. Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_PLAYCOUNT", v.PlayCount);
				instance.Icon:SetColor(UI.GetColorValue(1,1,1,0.50));
	
			else
				instance.Icon:SetColor(UI.GetColorValue(1,1,1,0.25));
			end
		end
		
		instance.Icon:SetIcon(v.LeaderIcon);
		instance.Icon:SetToolTipString(tooltip);
	end
end

function Overview_PopulateStatistics()
	-- Clear statistics instances.
	for i,v in ipairs(g_StatisticsManagers) do
		v:ResetInstances();
	end
	g_StatisticsBlockManager:ResetInstances();
	g_StatisticsManagers = {};
	
	
	local indexed_datapoints = {};
	local datapoints = HallofFame.GetRulesetDataPoints(g_CurrentRuleset.Ruleset);
	for i,v in ipairs(datapoints) do
		indexed_datapoints[v.DataPoint] = v;
	end

	-- Faster variant of table.insert
	local AppendItem = function(t, i)
		if(i ~= nil) then
			local s = #t;
			t[s + 1] = i;
		end
	end

	local statistics_by_category = {};
	for i,stat in ipairs(g_Statistics) do		
		local dp = indexed_datapoints[stat.DataPoint];
		if(dp) then
			local icons = {stat.ValueIconDefault};

			local v = {
				Name = stat.Name,
				Icon = stat.Icon,
				
				-- Array of icons to try using (in reverse-order for quick appending).
				ValueIcons = icons
			};

			-- Based on the kind of value the icon and display value will be updated.
			if(dp.ValueType) then
				local t = g_RulesetTypes[dp.ValueType];
				if(t) then
					AppendItem(icons, t.Icon);
					v.DisplayValue = Locale.Lookup(t.Name);
				end
			elseif(dp.ValueObjectId) then
				local o = g_GameObjects[dp.ValueObjectId];
				if(o) then
					AppendItem(icons, o.Icon);
					v.DisplayValue = o.Name and Locale.Lookup(o.Name);
				end
			elseif(dp.ValueString) then
				v.DisplayValue = Locale.Lookup(dp.ValueString);
			elseif(dp.ValueNumeric) then
				v.DisplayValue = Locale.ToNumber(dp.ValueNumeric, "###,###");
			end	
			
			-- Override icon
			AppendItem(icons, stat.ValueIconOverride);

			if(stat.Annotation) then
				v.Annotation = Locale.Lookup(stat.Annotation, {Name = "Amount", Value = dp.ValueNumeric});
			end
			
			if(v.DisplayValue) then
				local s = statistics_by_category[stat.Category];
				if(s == nil) then 
					s = {};
					statistics_by_category[stat.Category] = s;
				end

				table.insert(s, v);
			end
		end
	end
	
	for i,cat in ipairs(g_Categories) do
		local stats = statistics_by_category[cat.Category];

		if(not cat.IsHidden and stats and #stats > 0) then
			local cat_instance = g_StatisticsBlockManager:GetInstance();
			cat_instance.StatsTitle:SetText(cat.Name);
			
			local statsManager = InstanceManager:new("StatInstance", "Root", cat_instance.StatisticsStack);
			table.insert(g_StatisticsManagers, statsManager);
			
			for _,stat in ipairs(stats) do
				if(stat.DisplayValue) then
					local stat_instance = statsManager:GetInstance();
							
					if(stat.Icon and stat_instance.TitleIcon:TrySetIcon(stat.Icon)) then
						stat_instance.TitleIcon:SetHide(false);
					else
						stat_instance.TitleIcon:SetHide(true);
					end
					stat_instance.TitleCaption:LocalizeAndSetText(stat.Name);

					if(SetControlIcon(stat_instance.ValueIcon, stat.ValueIcons)) then
						stat_instance.ValueIcon:SetHide(false);
					else
						stat_instance.ValueIcon:SetHide(true);
					end
									
					stat_instance.ValueCaption:SetText(stat.DisplayValue);
					if(stat.Annotation) then
						stat_instance.Annotation:LocalizeAndSetText(stat.Annotation);
						stat_instance.Annotation:SetHide(false);
					else
						stat_instance.Annotation:SetHide(true);
					end
					
					stat_instance.AnnotationStack:CalculateSize();
					stat_instance.AnnotationStack:ReprocessAnchoring();
					stat_instance.TitleStack:CalculateSize();
					stat_instance.TitleStack:ReprocessAnchoring();
					stat_instance.ValueStack:CalculateSize();
					stat_instance.ValueStack:ReprocessAnchoring();
				end

			end
			
			cat_instance.StatisticsStack:CalculateSize();
			cat_instance.StatisticsStack:ReprocessAnchoring();
			cat_instance.RootStack:CalculateSize();
			cat_instance.RootStack:ReprocessAnchoring();
		end
	end
	
	Controls.StatisticsStack:CalculateSize();
	Controls.StatisticsStack:ReprocessAnchoring();
end

function History_PopulateGames()
	local games = nil;
	if(g_CurrentRuleset.ChallengeIds) then
		games = Challenges.GetGames(g_CurrentRuleset.ChallengeIds);
	else
		games = HallofFame.GetGames(g_CurrentRuleset.Ruleset);
	end
	
	g_Games = games;

	-- Pre-process to make it sortable.
	for i,v in ipairs(games) do
		for player_index, p in ipairs(v.Players) do
			if(p.IsMajor) then
				local player = g_RulesetPlayers[p.LeaderType];
				local fgColor, bgColor = UI.GetPlayerColorValues(p.LeaderType, 0);
				
				if(player) then
					p.LeaderName = p.LeaderName or player.LeaderName;
					p.CivilizationName = p.CivilizationName or player.CivilizationName;
					p.LeaderIcon = player.LeaderIcon or ("ICON_" .. player.LeaderType);
					p.CivilizationIcon= player.CivilizationIcon or ("ICON_" .. player.CivilizationType);
					p.fgColor = fgColor;
					p.bgColor = bgColor;
				end
				
				if(p.IsLocal and v.MyPlayer == nil) then
					v.Score = p.Score;
					v.MyPlayer = player_index;				
					v.MyVictory = (v.VictorTeamId ~= nil) and (v.VictorTeamId == p.TeamId);
					v.MyLeaderName = p.LeaderName;
					v.MyCivilizationName = p.CivilizationName;
					if(v.MyVictory) then
						v.VictorLeaderName = v.MyLeaderName;
						break;
					end
				end

				if(v.VictorTeamId ~= nil and p.TeamId == v.VictorTeamId and v.VictorLeaderName == nil) then
					v.VictorLeaderName = p.LeaderName;
				end
			end
		end
	end
	
	table.sort(games, g_GameListingsSortFunction or History_SortByScore);

	-- Should we reverse the list?
	if(g_SortDirectionReversed) then
		local i, j = 1, #games;

		while i < j do
			games[i], games[j] = games[j], games[i]

			i = i + 1
			j = j - 1
		end
	end

	g_SelectedGameId = nil;
	g_GameListings = {};
	g_GamesManager:ResetInstances();
	for i,v in ipairs(games) do
		local instance = g_GamesManager:GetInstance();

		local gameSpeed = g_RulesetTypes[v.GameSpeedType];
		local startEra = g_RulesetTypes[v.StartEraType];

		instance.Score:SetText(v.Score);
		instance.Turns:LocalizeAndSetText("LOC_GAMESUMMARY_TURNS", v.TurnCount);

        instance.Button:RegisterCallback( Mouse.eLDblClick, function()
            UI.PlaySound("Main_Menu_Mouse_Over");
            OnGameDetailsClicked(g_SelectedGameId) 
        end);

		if(gameSpeed) then
			instance.GameSpeedIcon:SetIcon(gameSpeed.Icon or ("ICON_" .. gameSpeed.Type));
			instance.GameSpeedIcon:SetHide(false);
		else
			instance.GameSpeedIcon:SetHide(true);
		end

		
		if(v.MyPlayer ~= nil) then
			local myPlayer = v.Players[v.MyPlayer];

			local myPlayerDifficulty = g_RulesetTypes[myPlayer.DifficultyType];
			if(myPlayerDifficulty) then
				instance.PlayerDifficultyIcon:SetIcon(myPlayerDifficulty.Icon or ("ICON_" .. myPlayerDifficulty.Type));
				instance.PlayerDifficultyIcon:SetHide(false);
			else
				-- TODO: Populate with an "unknown difficulty" icon/tooltip.
				instance.PlayerDifficultyIcon:SetHide(true);
			end
			
			instance.PlayerLeaderIcon:SetIcon(myPlayer.LeaderIcon or "ICON_LEADER_DEFAULT");
			instance.PlayerLeaderName:LocalizeAndSetText(myPlayer.LeaderName);
			instance.PlayerCivilizationIcon:SetIcon(myPlayer.CivilizationIcon or "ICON_CIVILIZATION_UNKNOWN");
			instance.PlayerCivilizationIcon:SetColor(myPlayer.bgColor);
			instance.PlayerCivilizationIconBG:SetColor(myPlayer.fgColor);
			instance.PlayerCivilizationName:LocalizeAndSetText(myPlayer.CivilizationName or "");
		end
		
		if(v.VictorTeamId) then		
			local victory = g_RulesetVictories[v.VictoryType];				
			local myVictory = v.MyVictory or false;

			if(victory and not victory.Hidden) then
				instance.VictoryName:LocalizeAndSetText(victory.Name);
				instance.VictoryName:SetHide(false);
			else
				instance.VictoryName:SetHide(true);
			end

			if(victory) then
				instance.VictoryIcon:SetHide(not SetControlIcon(instance.VictoryIcon, victory.Icons));
			end

			local victor = v.VictorLeaderName or "LOC_TEAM_UNKNOWN_NAME";
			instance.VictorName:LocalizeAndSetText((myVictory) and "LOC_GAMESUMMARY_YOU" or victor);
			
			instance.VictoryOrDefeat:LocalizeAndSetText((myVictory) and "LOC_GAMESUMMARY_VICTORY" or "LOC_GAMESUMMARY_DEFEAT");
		else
			instance.VictoryOrDefeat:LocalizeAndSetText("LOC_GAMESUMMARY_DEFEAT");
			instance.VictoryIcon:SetIcon("ICON_DEFEAT_GENERIC");

			-- If the game mode was not single player or hot seat, we cannot determine if there was a winner.
			if(v.GameMode == GameModeTypes.SINGLEPLAYER or v.GameMode == GameModeTypes.HOTSEAT) then
				instance.VictorName:LocalizeAndSetText("LOC_GAMESUMMARY_NOBODY_WON");
			else
				instance.VictorName:LocalizeAndSetText("LOC_GAMESUMMARY_UNKNOWN");
			end

			instance.VictoryName:SetText(nil);
		end
		
		if(startEra) then
			instance.StartEra:LocalizeAndSetText("LOC_GAMESUMMARY_ERA_STARTED", startEra.Name);
			instance.StartEra:SetHide(false);
		else
			instance.StartEra:SetHide(true);
		end

		instance.LastPlayed:LocalizeAndSetText("LOC_GAMESUMMARY_LAST_PLAYED", v.LastPlayed);
		
		local h = v.GameId;
		instance.Button:RegisterCallback(Mouse.eLClick, function()
			SelectGameListing(h);
		end);
			
		table.insert(g_GameListings, {v.GameId, instance});
	end

	Controls.ListingsStack:CalculateSize();
	Controls.ListingsStack:ReprocessAnchoring();
	Controls.Listings:CalculateInternalSize();
	
	History_RefreshSelectionState();
end

function History_RefreshSelectionState()
	for i,v in ipairs(g_GameListings or {}) do
		if(v[1] == g_SelectedGameId) then
			v[2].Button:SetSelected(true);
		else
			v[2].Button:SetSelected(false);
		end
	end
	
	Controls.DeleteGame:SetDisabled(g_SelectedGameId == nil);
	Controls.ViewGameDetails:SetDisabled(g_SelectedGameId == nil);
end
		

function History_SortByScore(a,b)
	-- Score(d), LastPlayed(d), GameId
	local aScore = a.Score or -1;
	local bScore = b.Score or -1;

	if(aScore ~= bScore) then
		return aScore > bScore;
	elseif(a.LastPlayed ~= b.LastPlayed) then
		return a.LastPlayed > b.LastPlayed
	else
		return a.GameId < b.GameId;
	end

end

function History_SortByLeader(a,b)
	-- LeaderName(a), CivilizationName(a), Score(d), LastPlayed(d), GameId
	local aScore = a.Score or -1;
	local bScore = b.Score or -1;

	local aLeader = a.MyLeaderName;
	local bLeader = b.MyLeaderName;

	local aCivilization = a.MyCivilizationName;
	local bCivilization = b.MyCivilizationName;
	
	if(aLeader ~= bLeader) then
		return Locale.Compare(aLeader, bLeader) == -1;
	elseif(aCivilization ~= bCivilization) then
		return Locale.Compare(aCivilization, bCivilization) == -1;
	elseif(aScore ~= bScore) then
		return aScore > bScore;
	elseif(a.LastPlayed ~= b.LastPlayed) then
		return a.LastPlayed > b.LastPlayed;
	else
		return a.GameId < b.GameId;
	end
end

function History_SortByResult(a,b)	
	-- Victory, Score(d), LastPlayed(d), GameId
	-- Defeat, Score(d), LastPlayed(d), GameId
	local aScore = a.Score or -1;
	local bScore = b.Score or -1;

	local aVictory = a.MyVictory;
	local bVictory = b.MyVictory;

	if(aVictory ~= bVictory) then
		return aVictory;
	elseif(aScore ~= bScore) then
		return aScore > bScore;
	elseif(a.LastPlayed ~= b.LastPlayed) then
		return a.LastPlayed > b.LastPlayed;
	else
		return a.GameId < b.GameId;
	end
end

function History_SortByVictor(a,b)
	-- You, Score(d), LastPlayed(d), GameId
	-- LeaderName, Score(d), LastPlayed(d), GameId
	-- Nobody, Score(d), LastPlayed(d), GameId
	local aScore = a.Score or -1;
	local bScore = b.Score or -1;

	local aYou = a.MyVictory;
	local bYou = b.MyVictory

	local aLeader = a.VictorLeaderName or nil;
	local bLeader = b.VictorLeaderName or nil;

	if(aYou ~= bYou) then
		return aYou;
	elseif(aLeader ~= bLeader) then
		if(aLeader ~= nil and bLeader ~= nil) then
			return Locale.Compare(aLeader, bLeader) == -1;
		else
			return aLeader ~= nil;
		end
	elseif(aScore ~= bScore) then
		return aScore > bScore;
	elseif(a.LastPlayed ~= b.LastPlayed) then
		return a.LastPlayed > b.LastPlayed;
	else
		return a.GameId < b.GameId;
	end		
end

function History_SortByLastPlayed(a,b)
	-- LastPlayed(d), Score(d), GameId
	local aScore = a.Score or -1;
	local bScore = b.Score or -1;

	if(a.LastPlayed ~= b.LastPlayed) then
		return a.LastPlayed > b.LastPlayed;
	elseif(aScore ~= bScore) then
		return aScore > bScore;
	else
		return a.GameId < b.GameId;
	end
end

----------------------------------------------------------------   
-- Generic Handlers
----------------------------------------------------------------   
function HandleExitRequest()
	UIManager:DequeuePopup( ContextPtr );
end

----------------------------------------------------------------   
-- Event Handlers
----------------------------------------------------------------  
function OnGameDetailsClicked(id)
	local kParameters = {};
	kParameters.GameId = id
	UIManager:QueuePopup(Controls.GameDetails, PopupPriority.Current, kParameters);
end

function OnDeleteGame()
	local gameId = g_SelectedGameId;
	local selected_ruleset = g_CurrentRuleset.Ruleset;

	HallofFame.DeleteGame(gameId);

	UpdateGlobalCache();
	History_RefreshSelectionState();
	PopulateAvailableRulesets();

	local ruleset_index = 1;
	for i,v in ipairs(g_AvailableRulesets) do
		if(v.Ruleset == selected_ruleset) then
			ruleset_index = i;
		end
	end

	SelectRuleset(ruleset_index);
end
----------------------------------------------------------------  
function OnShow()
	UpdateGlobalCache();
	local screenX, screenY:number  = UIManager:GetScreenSizeVal();
	local hideLogo        :boolean = true;	
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		hideLogo = false;
		Controls.MainWindow:SetSizeY(screenY- (Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY()));
	else
		Controls.MainWindow:SetSizeY(screenY);
	end
	
	Controls.LogoContainer:SetHide(hideLogo);
	History_RefreshSelectionState();
	PopulateAvailableRulesets();
	SelectRuleset(1);
	SelectTab(1);
end	

function OnHide()
	DumpInstances();
	DumpCache();
end
----------------------------------------------------------------  
function PostInit()
	if(not ContextPtr:IsHidden()) then
		OnShow();
	end
end

----------------------------------------------------------------        
-- Input Handler
----------------------------------------------------------------        
function InputHandler( uiMsg, wParam, lParam )
	if (uiMsg == KeyEvents.KeyUp) then
		if (wParam == Keys.VK_ESCAPE) then
			HandleExitRequest();
			return true;
		end
	end
end



----------------------------------------------------------------   
-- Initializer
----------------------------------------------------------------    
function Initialize()
	ContextPtr:SetInputHandler( InputHandler );
	g_PopupDialog = PopupDialog:new( "GameSummaries" );
	
	Controls.OverviewTab:RegisterCallback(Mouse.eLClick, function() 
		UI.PlaySound("Main_Menu_Mouse_Over");
		OnOverviewTabClicked() 
	end);
	
	Controls.HistoryTab:RegisterCallback(Mouse.eLClick, function() 
		UI.PlaySound("Main_Menu_Mouse_Over");
		OnHistoryTabClicked() 
	end);
	
	for i,v in ipairs(g_TabControls) do
		v[1]:RegisterCallback( Mouse.eLClick, function()
			UI.PlaySound("Main_Menu_Mouse_Over");
			SelectTab(i);
		end);
	end
	
	Controls.DeleteGame:RegisterCallback(Mouse.eLClick, function()
		UI.PlaySound("Main_Menu_Mouse_Over");
		g_PopupDialog:Reset();
		g_PopupDialog:AddText(Locale.Lookup("LOC_GAMESUMMARY_DELETE_GAME_PROMPT"));
		g_PopupDialog:AddButton(Locale.Lookup("LOC_CANCEL"), nil);
		g_PopupDialog:AddButton(Locale.Lookup("LOC_YES"), function() OnDeleteGame(g_SelectedGameId) end, nil, nil, "PopupButtonInstanceRed");
		g_PopupDialog:Open();
	end);

	Controls.ViewGameDetails:RegisterCallback(Mouse.eLClick, function() 
		UI.PlaySound("Main_Menu_Mouse_Over");
		OnGameDetailsClicked(g_SelectedGameId) 
	end);
	
	Controls.ReplayGame:SetDisabled(true);

	-- Apply standard functionality when sorting.
	function HandleColumnSort(func)
		return function()
			UI.PlaySound("Main_Menu_Mouse_Over");
			if g_GameListingsSortFunction == func then
				g_SortDirectionReversed = not g_SortDirectionReversed;
			else
				g_SortDirectionReversed = false;
			end
			g_GameListingsSortFunction = func;
			History_PopulateGames();
		end;
	end

	Controls.ScoreColumn:RegisterCallback( Mouse.eLClick, HandleColumnSort(History_SortByScore));
	Controls.YouColumn:RegisterCallback( Mouse.eLClick, HandleColumnSort(History_SortByLeader));	
	Controls.ResultsColumn:RegisterCallback( Mouse.eLClick, HandleColumnSort(History_SortByResult));
	Controls.VictoryColumn:RegisterCallback( Mouse.eLClick, HandleColumnSort(History_SortByVictor));
	Controls.SettingsColumn:RegisterCallback( Mouse.eLClick, HandleColumnSort(History_SortByLastPlayed));

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, function()
		UI.PlaySound("Main_Menu_Mouse_Over");
		HandleExitRequest();
	end);
	
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
	ContextPtr:SetPostInit(PostInit);	
end

--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local HOF_PANEL_ID   = "CAIHoF_Panel"
local HOVER_SOUND    = "Main_Menu_Mouse_Over"

local m_hofPanel       = nil
local m_hofTabs        = nil
local m_overviewTree   = nil
local m_historyList    = nil
local m_sortDropdown       = nil
local m_rulesetDropdown = nil
local m_isBuilt        = false

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

-- ============================================================================
-- Overview tab: merged Tree with Victory Progress + Leader Progress categories
-- ============================================================================
local function RebuildOverviewTree()
    if not m_overviewTree then return end
    local capture = mgr:CaptureFocusKey(m_overviewTree)
    m_overviewTree:ClearChildren()

    -- Category 1: Victory Progress
    local victoryNode = mgr:CreateWidget(MakeId("CAIHoF_vp_"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS") end,
        FocusKey = "hof:overview:victories",
    })
    victoryNode:SetFocusSound(HOVER_SOUND)
    m_overviewTree:AddChild(victoryNode)

    for i, v in ipairs(g_RulesetVictories or {}) do
        if not v.Hidden and ((v.IsAvailableForChallenge == nil) or v.IsAvailableForChallenge) then
            local name = v.Name or ""
            local count = tonumber(v.Count) or 0
            local labelStr = name
            if count > 0 then
                labelStr = labelStr .. ", " .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_COUNT", count)
            end
            local tipStr = nil
            if v.MostRecentLeaderType then
                local player = g_RulesetPlayers[v.MostRecentLeaderType]
                if player then
                    tipStr = Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_LEADER", player.LeaderName)
                end
            end
            local capturedLabel = labelStr
            local capturedTip = tipStr
            local leaf = mgr:CreateWidget(MakeId("CAIHoF_vp_"), "StaticText", {
                Label = function() return capturedLabel end,
                Tooltip = capturedTip and function() return capturedTip end or nil,
                FocusKey = "hof:overview:victory:" .. i,
            })
            leaf:SetFocusSound(HOVER_SOUND)
            victoryNode:AddChild(leaf)
        end
    end

    -- Challenge badges (if applicable)
    if g_CurrentRuleset and g_CurrentRuleset.ChallengeIds and Challenges and Challenges.ChallengeHasCustomBadge and Challenges.ChallengeHasCustomBadge(g_CurrentRuleset.ChallengeIds) then
        for challengeId in string.gmatch(g_CurrentRuleset.ChallengeIds, "([^ ]+)") do
            local info = Challenges.GetChallengeBadgeDisplayInfo(challengeId)
            if info then
                local badgeName = info.BadgeName or ""
                local badgeCount = tonumber(info.VictoryCount) or 0
                local badgeLabel = badgeName
                if badgeCount > 0 then
                    badgeLabel = badgeLabel .. ", " .. Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_COUNT", badgeCount)
                end
                local badgeTip = nil
                if info.MostRecentLeaderName then
                    badgeTip = Locale.Lookup("LOC_GAMESUMMARY_VICTORYPROGRESS_LEADER", info.MostRecentLeaderName)
                end
                local capLabel = badgeLabel
                local capTip = badgeTip
                local badgeLeaf = mgr:CreateWidget(MakeId("CAIHoF_vp_"), "StaticText", {
                    Label = function() return capLabel end,
                    Tooltip = capTip and function() return capTip end or nil,
                    FocusKey = "hof:overview:badge:" .. challengeId,
                })
                badgeLeaf:SetFocusSound(HOVER_SOUND)
                victoryNode:AddChild(badgeLeaf)
            end
        end
    end

    -- Category 2: Leader Progress
    local leaderNode = mgr:CreateWidget(MakeId("CAIHoF_lp_"), "TreeItem", {
        Label = function() return Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS") end,
        FocusKey = "hof:overview:leaders",
    })
    leaderNode:SetFocusSound(HOVER_SOUND)
    m_overviewTree:AddChild(leaderNode)

    local leaderProgress = nil
    if g_CurrentRuleset then
        if g_CurrentRuleset.ChallengeIds and Challenges and Challenges.GetChallengeLeaderProgress then
            leaderProgress = Challenges.GetChallengeLeaderProgress(g_CurrentRuleset.ChallengeIds)
        else
            leaderProgress = HallofFame.GetLeaderProgress(g_CurrentRuleset.Ruleset)
        end
    end

    if leaderProgress then
        local leaders = {}
        for k, v in pairs(leaderProgress) do
            local player = g_RulesetPlayers[k]
            if player then
                v.LeaderName = Locale.Lookup(player.LeaderName)
                v.LeaderType = k
                table.insert(leaders, v)
            end
        end
        table.sort(leaders, function(a, b)
            return Locale.Compare(a.LeaderName, b.LeaderName) == -1
        end)

        local visibleVictoryCount = 0
        for _, v in ipairs(g_RulesetVictories or {}) do
            if not v.Hidden then visibleVictoryCount = visibleVictoryCount + 1 end
        end

        for idx, v in ipairs(leaders) do
            local parts = { v.LeaderName }
            if v.MostRecentVictoryType then
                table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_WINCOUNT", v.VictoryCount, v.PlayCount))
                if visibleVictoryCount > 1 then
                    local victory = g_RulesetVictories[v.MostRecentVictoryType]
                    if victory then
                        table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_VICTORY", victory.Name))
                    end
                end
            elseif tonumber(v.PlayCount) > 0 then
                table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_LEADERPROGRESS_PLAYCOUNT", v.PlayCount))
            end
            local capturedLabel = table.concat(parts, ", ")
            local leaf = mgr:CreateWidget(MakeId("CAIHoF_lp_"), "StaticText", {
                Label = function() return capturedLabel end,
                FocusKey = "hof:overview:leader:" .. idx,
            })
            leaf:SetFocusSound(HOVER_SOUND)
            leaderNode:AddChild(leaf)
        end
    end

    -- Category 3+: Statistics (by category)
    if g_CurrentRuleset then
        local indexed_datapoints = {}
        local datapoints = HallofFame.GetRulesetDataPoints(g_CurrentRuleset.Ruleset)
        for _, v in ipairs(datapoints) do
            indexed_datapoints[v.DataPoint] = v
        end

        local statistics_by_category = {}
        for _, stat in ipairs(g_Statistics or {}) do
            local dp = indexed_datapoints[stat.DataPoint]
            if dp then
                local displayValue = nil
                if dp.ValueType then
                    local t = g_RulesetTypes[dp.ValueType]
                    if t then displayValue = Locale.Lookup(t.Name) end
                elseif dp.ValueObjectId then
                    local o = g_GameObjects and g_GameObjects[dp.ValueObjectId]
                    if o and o.Name then displayValue = Locale.Lookup(o.Name) end
                elseif dp.ValueString then
                    displayValue = Locale.Lookup(dp.ValueString)
                elseif dp.ValueNumeric then
                    displayValue = Locale.ToNumber(dp.ValueNumeric, "###,###")
                end

                if displayValue then
                    local annotation = nil
                    if stat.Annotation then
                        annotation = Locale.Lookup(stat.Annotation, { Name = "Amount", Value = dp.ValueNumeric })
                    end
                    local s = statistics_by_category[stat.Category]
                    if not s then
                        s = {}
                        statistics_by_category[stat.Category] = s
                    end
                    table.insert(s, {
                        Name = stat.Name,
                        DisplayValue = displayValue,
                        Annotation = annotation,
                    })
                end
            end
        end

        for _, cat in ipairs(g_Categories or {}) do
            local stats = statistics_by_category[cat.Category]
            if not cat.IsHidden and stats and #stats > 0 then
                local catNode = mgr:CreateWidget(MakeId("CAIHoF_stat_"), "TreeItem", {
                    Label = function() return cat.Name end,
                    FocusKey = "hof:overview:statcat:" .. cat.Category,
                })
                catNode:SetFocusSound(HOVER_SOUND)
                m_overviewTree:AddChild(catNode)

                for si, stat in ipairs(stats) do
                    local statLabel = stat.Name .. ": " .. stat.DisplayValue
                    if stat.Annotation then
                        statLabel = statLabel .. " (" .. stat.Annotation .. ")"
                    end
                    local capLabel = statLabel
                    local statLeaf = mgr:CreateWidget(MakeId("CAIHoF_stat_"), "StaticText", {
                        Label = function() return capLabel end,
                        FocusKey = "hof:overview:stat:" .. cat.Category .. ":" .. si,
                    })
                    statLeaf:SetFocusSound(HOVER_SOUND)
                    catNode:AddChild(statLeaf)
                end
            end
        end
    end

    mgr:RestoreFocus(m_overviewTree, capture)
end

-- ============================================================================
-- History tab: game list + sort controls
-- ============================================================================
local function RebuildHistoryList()
    if not m_historyList then return end
    local capture = mgr:CaptureFocusKey(m_historyList)
    m_historyList:ClearChildren()

    for i, game in ipairs(g_Games or {}) do
        local parts = {}

        local score = game.Score
        if score then table.insert(parts, tostring(score)) end

        if game.MyPlayer then
            local myPlayer = game.Players[game.MyPlayer]
            if myPlayer then
                if myPlayer.LeaderName then
                    table.insert(parts, Locale.Lookup(myPlayer.LeaderName))
                end
                if myPlayer.CivilizationName then
                    table.insert(parts, Locale.Lookup(myPlayer.CivilizationName))
                end
            end
        end

        if game.VictorTeamId then
            local victory = g_RulesetVictories[game.VictoryType]
            local myVictory = game.MyVictory or false
            table.insert(parts, myVictory and Locale.Lookup("LOC_GAMESUMMARY_VICTORY") or Locale.Lookup("LOC_GAMESUMMARY_DEFEAT"))
            if victory and not victory.Hidden then
                table.insert(parts, Locale.Lookup(victory.Name))
            end
            local victor = game.VictorLeaderName or "LOC_TEAM_UNKNOWN_NAME"
            table.insert(parts, myVictory and Locale.Lookup("LOC_GAMESUMMARY_YOU") or Locale.Lookup(victor))
        else
            table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_DEFEAT"))
            if game.GameMode == GameModeTypes.SINGLEPLAYER or game.GameMode == GameModeTypes.HOTSEAT then
                table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_NOBODY_WON"))
            end
        end

        table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_TURNS", game.TurnCount))

        local tipParts = {}
        if game.MyPlayer then
            local myPlayer = game.Players[game.MyPlayer]
            if myPlayer then
                local diff = g_RulesetTypes[myPlayer.DifficultyType]
                if diff then
                    table.insert(tipParts, Locale.Lookup(diff.Name))
                end
            end
        end
        local gameSpeed = g_RulesetTypes[game.GameSpeedType]
        if gameSpeed then table.insert(tipParts, Locale.Lookup(gameSpeed.Name)) end
        local startEra = g_RulesetTypes[game.StartEraType]
        if startEra then
            table.insert(tipParts, Locale.Lookup("LOC_GAMESUMMARY_ERA_STARTED", startEra.Name))
        end
        table.insert(tipParts, Locale.Lookup("LOC_GAMESUMMARY_LAST_PLAYED", game.LastPlayed))

        local capturedLabel = table.concat(parts, ", ")
        local capturedTip = #tipParts > 0 and table.concat(tipParts, "[NEWLINE]") or nil
        local capturedGameId = game.GameId

        local row = mgr:CreateWidget(MakeId("CAIHoF_game_"), "Button", {
            Label = function() return capturedLabel end,
            Tooltip = capturedTip and function() return capturedTip end or nil,
            FocusKey = "hof:history:game:" .. i,
        })
        row:SetFocusSound(HOVER_SOUND)
        row:On("activate", function()
            SelectGameListing(capturedGameId)
            OnGameDetailsClicked(capturedGameId)
        end)
        m_historyList:AddChild(row)
    end

    if #(g_Games or {}) == 0 then
        local empty = mgr:CreateWidget(MakeId("CAIHoF_game_"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_CAI_HOF_NO_GAMES") end,
            FocusKey = "hof:history:empty",
        })
        empty:SetFocusSound(HOVER_SOUND)
        m_historyList:AddChild(empty)
    end

    mgr:RestoreFocus(m_historyList, capture)
end

-- ============================================================================
-- Build the panel
-- ============================================================================
local function BuildHoFPanel()
    if m_isBuilt then return end

    m_hofPanel = mgr:CreateWidget(HOF_PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_GAMESUMMARY_TITLE") end,
    })

    -- Ruleset dropdown
    m_rulesetDropdown = mgr:CreateWidget(MakeId("CAIHoF_rs_"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_HOF_RULESET") end,
        FocusKey = "hof:ruleset",
    })
    m_rulesetDropdown:SetFocusSound(HOVER_SOUND)
    m_hofPanel:AddChild(m_rulesetDropdown)

    -- Tabs
    m_hofTabs = mgr:CreateWidget(MakeId("CAIHoF_tabs_"), "TabControl", {})
    m_hofPanel:AddChild(m_hofTabs)

    -- Tab 1: Overview
    local overviewPage = m_hofTabs:AddPage(function() return Locale.Lookup("LOC_GAMESUMMARY_OVERVIEW") end)
    m_overviewTree = mgr:CreateWidget(MakeId("CAIHoF_ov_"), "Tree", {})
    overviewPage:AddChild(m_overviewTree)

    -- Tab 2: History
    local historyPage = m_hofTabs:AddPage(function() return Locale.Lookup("LOC_GAMESUMMARY_HISTORY") end)

    m_historyList = mgr:CreateWidget(MakeId("CAIHoF_hist_"), "List", {})
    historyPage:AddChild(m_historyList)

    local sortFuncs = {
        History_SortByScore,
        History_SortByLeader,
        History_SortByResult,
        History_SortByVictor,
        History_SortByLastPlayed,
    }
    m_sortDropdown = mgr:CreateWidget(MakeId("CAIHoF_sort_"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_HOF_SORT_BY") end,
        FocusKey = "hof:sort",
    })
    m_sortDropdown:SetFocusSound(HOVER_SOUND)
    m_sortDropdown:SetOptions({
        { label = Locale.Lookup("LOC_GAMESUMMARY_HISTORY_SCORE"),    value = 1 },
        { label = Locale.Lookup("LOC_GAMESUMMARY_HISTORY_YOU"),      value = 2 },
        { label = Locale.Lookup("LOC_GAMESUMMARY_HISTORY_RESULTS"),  value = 3 },
        { label = Locale.Lookup("LOC_GAMESUMMARY_HISTORY_VICTORY"),  value = 4 },
        { label = Locale.Lookup("LOC_GAMESUMMARY_HISTORY_SETTINGS"), value = 5 },
    })
    m_sortDropdown:SetSelectedIndex(1, true)
    m_sortDropdown:On("value_changed", function(_, val)
        g_GameListingsSortFunction = sortFuncs[val]
        g_SortDirectionReversed = false
        History_PopulateGames()
    end)
    historyPage:AddChild(m_sortDropdown)

    -- Tab sync: CAI tab changes click vanilla tab buttons
    local vanillaTabButtons = { Controls.OverviewTab, Controls.HistoryTab }
    local isMirroringTab = false
    m_hofTabs:On("value_changed", function(_, pageIndex)
        if isMirroringTab then return end
        isMirroringTab = true
        local btn = vanillaTabButtons[pageIndex]
        if btn then btn:DoLeftClick() end
        isMirroringTab = false
    end)

    m_isBuilt = true
end

local function PopulateRulesetDropdown()
    if not m_rulesetDropdown then return end
    local options = {}
    for i, v in ipairs(g_AvailableRulesets or {}) do
        table.insert(options, { label = v.DisplayName, value = i })
    end
    m_rulesetDropdown:SetOptions(options)
    if #options > 0 then
        m_rulesetDropdown:SetSelectedIndex(1, true)
    end
    m_rulesetDropdown:On("value_changed", function(_, val)
        SelectRuleset(val)
        RebuildOverviewTree()
        RebuildHistoryList()
    end)
end

local function PushHoFPanel()
    BuildHoFPanel()
    PopulateRulesetDropdown()
    RebuildOverviewTree()
    RebuildHistoryList()
    mgr:Push(m_hofPanel, PopupPriority.Current)
end

local function DestroyHoFPanel()
    if m_isBuilt then
        mgr:RemoveFromStack(HOF_PANEL_ID)
        m_hofPanel = nil
        m_hofTabs = nil
        m_overviewTree = nil
        m_historyList = nil
        m_sortDropdown = nil
        m_rulesetDropdown = nil
        m_isBuilt = false
    end
end

-- Wrap vanilla lifecycle
OnShow = WrapFunc(OnShow, function(orig)
    orig()
    if not mgr:GetWidgetById(HOF_PANEL_ID) then
        PushHoFPanel()
    end
end)

HandleExitRequest = WrapFunc(HandleExitRequest, function(orig)
    DestroyHoFPanel()
    orig()
end)

-- Wrap History_PopulateGames so CAI list stays in sync when vanilla sorts
History_PopulateGames = WrapFunc(History_PopulateGames, function(orig)
    orig()
    RebuildHistoryList()
end)

-- Wrap SelectRuleset so overview rebuilds on ruleset change from vanilla dropdown
SelectRuleset = WrapFunc(SelectRuleset, function(orig, index)
    orig(index)
    RebuildOverviewTree()
    RebuildHistoryList()
end)

-- Re-register input handler with InputStruct signature
Initialize = WrapFunc(Initialize, function(orig)
    orig()
    ContextPtr:SetInputHandler(function(input)
        if mgr:HandleInput(input) then return true end
        if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
            HandleExitRequest()
            return true
        end
    end, true)
end)
--#End of accessibility integration

Initialize();