-------------------------------------------------
-- Game Summaries Screen
-------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "PopupDialog" );

----------------------------------------------------------------   
-- Utilities
----------------------------------------------------------------    
function remove_if(arr, f)
	local n = #arr;
	local ni = 1;
	for i = 1,n do
		local v = arr[i];
		if(f(v)) then
			arr[i] = nil;	
		else
			if(ni ~= i) then
				arr[i] = nil;
				arr[ni] = v;
			end
			ni = ni + 1;
		end
	end
end

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

-- v[0]=Control, v[1]=Selected Control, v[2]=area to show when selected
g_TabControls = {
	{Controls.OverviewTab,	Controls.SelectedOverviewTab,	Controls.OverviewTabPanel},
	{Controls.GraphsTab,	Controls.SelectedGraphsTab,		Controls.GraphsTabPanel},
	{Controls.ReportsTab,	Controls.SelectedReportsTab,	Controls.ReportsTabPanel}
};

g_HighlightsManager = InstanceManager:new("StatInstance", "Root", Controls.HighlightsStack);
g_StatisticsBlockManager = InstanceManager:new("StatBlockInstance", "RootStack", Controls.StatisticsStack);
g_PlayerManager = InstanceManager:new("PlayerInstance", "Button", Controls.PlayersStack);
g_GraphLegendManager = InstanceManager:new("GraphLegendInstance", "Root", Controls.GraphLegendStack);

g_ReportHeaderManager = InstanceManager:new("ReportHeaderInstance", "Root", Controls.ReportHeaderStack);
g_ReportRowManager = InstanceManager:new("ReportRowInstance", "Root", Controls.ReportStack);
g_ReportCellManagers ={}
g_StatisticsManagers = {};

local m_GameModeNamesIM	= InstanceManager:new("GameModeNameInstance", "GameModeName", Controls.GameModeNamesStack);

g_GameId = nil;				-- Hall of Fame Game Id for getting details and graphs.
g_GameData = nil;
g_GameObjects = nil;		-- Map of game objects by object id.
g_GamePlayers = nil;		-- Map of game players by object id.
g_AvailableContexts = nil;	-- The available overview contexts.
g_OverviewContext = nil;	-- The current overview context.
g_RulesetPlayers = nil;		-- Map of all ruleset playable leaders
g_RulesetTypes = nil;		-- Map of all ruleset types.
g_RulesetVictories = nil;	-- Map/Array of all ruleset victories.	
g_Categories = nil;			-- Sorted array of all statistics categories.
g_Statistics = nil;			-- Sorted array of all statistics.

g_Graphs = nil;				-- All graph data for the game, organized by groups.
g_GraphGroup = nil;			-- The currently selected group.
g_Graph = nil;				-- The currently selected graph.
g_GraphLegendColors = nil;	-- The currently chosen colors for graph legends.
g_GraphDataSets = nil;		-- Currently allocated datasets.

g_Reports = nil;			-- All reports for the game, organized by groups.
g_ReportsGroup = nil;		-- The currently selected report group.
g_Report = nil;				-- The currently selected report.

REPORT_CELL_WIDTH = 136;


-- Release global cache to free up memory.
function DumpGlobalCache()
	g_GameId = nil;
	g_GameData = nil;
	g_GameObjects = nil;
	g_GamePlayers = nil;
	g_GameStatistics = nil;
	g_AvailableContexts = nil;
	g_OverviewContext = nil;
	g_RulesetPlayers = nil;
	g_RulesetTypes = nil;
	g_RulesetVictories = nil;
	g_Categories = nil;
	g_Statistics = nil;
	
	g_Graphs = nil;
	g_GraphGroup = nil;
	g_Graph = nil;
	g_GraphLegendColors = nil;
	g_GraphDataSets = nil;
	
	g_Reports = nil;
	g_ReportsGroup = nil;
	g_Report = nil;
end

function DumpInstances()
	for i,v in ipairs(g_StatisticsManagers) do
		v:ResetInstances();
	end

	for i,v in ipairs(g_ReportCellManagers) do
		v:ResetInstances();
	end

	g_HighlightsManager:ResetInstances();
	g_StatisticsBlockManager:ResetInstances();
	g_PlayerManager:ResetInstances();
	g_GraphLegendManager:ResetInstances();
	g_ReportHeaderManager:ResetInstances();
	g_ReportRowManager:ResetInstances();
	-- TODO: Reset instances in pulldowns.
	
	g_StatisticsManagers = {};	
end

-- Much of hall of fame is read-only and static so it can be cached.
function UpdateGlobalCache()
	DumpGlobalCache();
	
	local params = ContextPtr:GetPopupParameters();
	if (params) then
		g_GameId = params:GetValue("GameId");
	end
	g_GameId = g_GameId or 1;	
	g_GameData = HallofFame.GetGameData(g_GameId);

	local gameObjects = HallofFame.GetGameObjects(g_GameId);
	g_GameObjects = {};
	for i,v in ipairs(gameObjects) do
		g_GameObjects[v.ObjectId] = v;
	end

	g_GamePlayers = {};
	for i,v in ipairs(g_GameData.Players) do
		g_GamePlayers[v.PlayerObjectId] = v;
	end
	
	local ruleset = g_GameData.Ruleset;
	local players = HallofFame.GetRulesetPlayableLeaders(ruleset);
	g_RulesetPlayers = {};
	for i,v in ipairs(players) do
		g_RulesetPlayers[v.LeaderType] = v;
	end
	
	g_RulesetTypes = HallofFame.GetRulesetTypes(ruleset);
	
	local victoryProgress = HallofFame.GetVictoryProgress(ruleset);
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

	g_Statistics = {};
	local statistics = HallofFame.GetStatistics(ruleset);
	for i,stat in ipairs(statistics) do
		local cat = indexed_categories[stat.Category];
		if(cat and not cat.IsHidden) then
			stat.Name = Locale.Lookup(stat.Name);
			table.insert(g_Statistics, stat);
		end
	end

	table.sort(g_Statistics, function(a,b)
		if(a.Importance ~= b.Importance) then
			return a.Importance > b.Importance;
		else
			return Locale.Compare(a.Name, b.Name) == -1;
		end
	end);
			
	g_AvailableContexts = Overview_GetContexts(g_GameData);	
		
	-- Graphs are not grouped.  Group them by Object Id. using AvailableContexts.
	local graphs = HallofFame.GetGraphs(g_GameId, ruleset);

	-- Massage data, add data set names etc.
	for i,g in ipairs(graphs) do

		local minX = g.MinX;
		local maxX = g.MaxX;

		-- for each data set in the graph.
		for _ , ds in ipairs(g) do
			local objectId = ds.ObjectId;

			if(ds.Type) then
				local t = g_RulesetTypes[ds.Type];
				if(t) then
					ds.Name = t.Name;
				end
			elseif(ds.ObjectId) then
				local p = g_GamePlayers[ds.ObjectId];
				if(p) then
					ds.Name = p.LeaderName;
					ds.Hidden = not p.IsMajor;
				else
					local o = g_GameObjects[ds.ObjectId];
					if(o) then
						ds.Name = o.Name;
					end
				end
			end

			if(ds.Name == nil) then
				ds.Name = "LOC_GAMESUMMARY_UNKNOWN";
			end
			
			if(not ds.Hidden) then
				-- Mark as empty if no data found or all 0.
				local count = 0;
				local empty = true;
				for i = minX, maxX, 1 do
					local value = ds[i];
					if(value ~= nil) then
						count = count + 1;
						if( value ~= 0) then
							empty = false;
						end
					end
				end

				ds.Count = count;

				if(empty) then 
					ds.Empty = true; 
				end
			end
		end

		-- Filter hidden and empty groups.
		-- Also filter graphs that are not delta (or continuous) and contain only 1 vertex.
		remove_if(g, function(ds)  return ds.Hidden or ds.Empty or (not ds.IsDelta and ds.Count == 1); end);

		-- Sort groups by name.
		table.sort(g, function(a,b) return Locale.Compare(a.Name, b.Name) == -1; end);
	end

	-- Filter graphs that contain 0 data sets.
	-- TODO: Remove graphs where minX == maxX or minY == maxY??
	remove_if(graphs, function(g) return #g == 0; end);

	local sortByImportance = function(a,b)
		if(a.Importance == b.Importance) then
			return Locale.Compare(a.Name, b.Name) == -1;
		else
			return a.Importance > b.Importance;
		end
	end

	local sortRowsByName = function(a,b) 
		return Locale.Compare(a.Name, b.Name) == -1;
	end
	
	g_Graphs = {}
	for i,v in ipairs(g_AvailableContexts) do
		local group = {};
		local contextId = v.ObjectId;
		for _, g in ipairs(graphs) do
			if(contextId == g.ObjectId) then
				table.insert(group, g);
			end
		end
		if(#group > 0) then
			for _,graph in ipairs(group) do
				graph.Name = Locale.Lookup(graph.Name);
				graph.Importance = graph.Importance or 0;
			end
			table.sort(group, sortByImportance);
			
			group.Name = Locale.Lookup(v.Name);
			group.Importance = group.Importance or 0;
			table.insert(g_Graphs, group);
		end
	end
	
	-- Massage the data, filter out empty groups, localize and sort groups.
	local reports = HallofFame.GetReports(g_GameId, ruleset);
	g_Reports = {};

	for _, report in ipairs(reports) do
		
		-- Gather data before populating
		-- (This way we can cull-out empty columns/rows.)

		-- Mark all columns as empty (will update as rows are processed).
		for _, column in ipairs(report.Columns) do
			column.Empty = true;
		end

		-- Resolve the initial column name and localize it.
		-- This will be used for sorting purposes.
		for _,row in ipairs(report) do
			local row_object = row.ObjectId;
			local row_type = row.Type;
	
			-- OPTIMIZATION (This could be cached/shared amongst multiple reports that have the same object.);
			-- Collect data points.
			local indexed_datapoints = {};
			local type_indexed_datapoints = {};
			local datapoints = HallofFame.GetObjectDataPoints(row_object);

			-- Index data points 
			for i,v in ipairs(datapoints) do
				if(v.ValueType == nil) then
					indexed_datapoints[v.DataPoint] = v;
				else
					local t = type_indexed_datapoints[v.DataPoint];
					if(t == nil) then
						t = {};
						type_indexed_datapoints[v.DataPoint] = t;
					end
					t[v.ValueType] = v;
				end
			end

			-- Populate Additional Columns
			row.Empty = true;
			for column_index, column in ipairs(report.Columns) do

				local dp;
				if(row_type) then
					local t = type_indexed_datapoints[column.DataPoint];
					if(t) then 
						dp = t[row_type];
					end
				else
					dp = indexed_datapoints[column.DataPoint];
				end

				if(dp) then
					local value;
					local icons = {column.ValueIconDefault};
					value, icons = GetDataPointValue(dp, icons, column.UxHint);
					
					if(value ~= nil and (tostring(value) ~= tostring(column.EmptyValue))) then
						table.insert(icons, column.ValueIconOverride);

						local cell = {
							Icons = icons,
							Value = value
						};
						row[column_index] = cell;

						column.Empty = false;

						-- If column is not a minotr one, mark row as not empty.
						if(column.Minor ~= true) then
							row.Empty = false;
						end
					end
				end
			end

			-- Only perform this work if the row has data to be shown.
			if(not row.Empty) then

				-- Determine the name of the row.
				local row_name = "LOC_GAMESUMMARY_UNKNOWN";
				if(row_type) then
					local r = g_RulesetTypes[row_type];
					if(r) then
						row_name = r.Name;
					end
				elseif(row_object) then
					local o = g_GameObjects[row_object];
					if(o) then
						local p = g_GamePlayers[row_object];
						if(p) then
							row_name = p.LeaderName;
						else
							row_name = o.Name;
						end
					end
				end

				row.Name = row_name and Locale.Lookup(row_name) or "LOC_GAMESUMMARY_UNKNOWN";
			
				-- Populate initial column data.
				local icons = {row.InitialColumnValueIconDefault};

				if(row_type) then
					local r = g_RulesetTypes[row_type];
					if(r) then
						table.insert(icons, r.Icon);
					end
				elseif(row_object) then
					local o = g_GameObjects[row_object];
					if(o) then
						table.insert(icons, o.Icon);
					end
				end
				table.insert(icons, row.InitialColumnValueIconOverride);

				row[0] = {
					Icons = icons,
					Value = row.Name
				};
			end
		end

		-- Filter out empty rows.
		remove_if(report, function(r) return r.Empty; end);

		-- Sort rows by name.
		table.sort(report, sortRowsByName);

		-- Perform any processing that can be skipped if there are no rows.
		if(#report > 0) then
			report.Name = Locale.Lookup(report.Name or "LOC_GAMESUMMARY_UNKNOWN");
			report.Importance = report.Importance or 0;
		end
	end

	-- Filter out reports w/ no rows.
	remove_if(reports, function(r) return #r == 0; end);

	for i,v in ipairs(g_AvailableContexts) do
		local group = {};
		local contextId = v.ObjectId;
		for _, g in ipairs(reports) do
			if(contextId == g.ObjectId) then
				table.insert(group, g);
			end
		end
		if(#group > 0) then
			table.sort(group, sortByImportance);
			
			group.Name = Locale.Lookup(v.Name);
			group.Importance = group.Importance or 0;
			table.insert(g_Reports, group);
		end
	end
	
	-- Older games are missing the starting turn making it difficult to show the entire game graph.
	-- In this situation, scrub all "GameTurn" graphs to determine the largest range.
	local startTurn;
	local endTurn;

	if(g_GameData.StartTurn == nil or g_GameData.StartTurn == -1) then
		for _, graphCategories in ipairs(g_Graphs) do
			for _, graph in ipairs(graphCategories) do
				if(graph.XUnit == "GameTurn") then
					if(startTurn == nil or startTurn > graph.MinX) then
						startTurn = graph.MinX;
					end

					if(endTurn == nil or endTurn < graph.MaxX) then
						endTurn = graph.MaxX;
					end
				end
			end 
		end
	else
		startTurn = g_GameData.StartTurn;
		endTurn = startTurn + g_GameData.TurnCount;
	end

	-- TODO Edge Case: If the game is 0-1 turns long, pad out the range!

	-- Once again enumerate all "GameTurn" graphs and adjust their MinX,MaxX to fix the total GameTurn range.
	-- For Delta datasets, fill in the missing values.
	for _, graphCategories in ipairs(g_Graphs) do
		for _, graph in ipairs(graphCategories) do
			if(graph.XUnit == "GameTurn") then
				if(graph.MinX ~= startTurn or graph.MaxX ~= endTurn) then
					graph.MinX = startTurn;
					graph.MaxX = endTurn;

					for _, ds in ipairs(graph) do
						if(ds.IsDelta) then
							local value = 0;
							for i = graph.MinX, graph.MaxX, 1 do
								value = ds[i] or value;
								ds[i] = value;
							end	
						end
					end
				end
			end
		end 
	end
end


function GetVictoryDetails(victoryType)
	local name = "LOC_GAMESUMMARY_VICTORY";
	local icons = {"ICON_VICTORY_UNIVERSAL"};

	local victory = g_RulesetVictories[g_GameData.VictoryType];
	if(victory) then
		name = victory.Name;
		icons = victory.Icons;
	else
		victory = g_RulesetTypes[g_GameData.VictoryType];
		if(victory) then
			table.insert(icons, "ICON_" .. victory.Type);
			table.insert(icons, victory.Icon);
			name = victory.Name;
		end				
	end

	return name, icons;
end

local colorDistances = {};
local pow = math.pow;
function ColorDistance(color1, color2)
	
	local color1Type = color1[1];
	local color1Value = color1[2];

	local color2Type = color2[1];
	local color2Value = color2[2];

	local distance = nil;
	local colorDistanceTable = colorDistances[color1Type];
	if(colorDistanceTable == nil) then
		colorDistanceTable = {
			[color1Type] = 0;	--We can assume the distance of a color to itself is 0.
		};
				
		colorDistances[color1Type] = colorDistanceTable
	end
			
	local distance = colorDistanceTable[color2Type];
	if(distance == nil) then
		local c1 = {UI.GetColorChannels(color1Value)};
		local c2 = {UI.GetColorChannels(color2Value)};

		local r2 = pow(c1[1] - c2[1], 2);
		local g2 = pow(c1[2] - c2[2], 2);
		local b2 = pow(c1[3] - c2[3], 2);	
				
		distance = r2 + g2 + b2;
		colorDistanceTable[color2Type] = distance;
	end
			
	return distance;
end
		
local colorBlack;

function IsUniqueColor(color, unique_cache)
	local id = color[1];

	if(unique_cache[id]) then
		return false;
	end

	if(colorBlack == nil) then
		colorBlack = {DB.MakeHash("COLOR_BLACK"), UI.GetColorValue("COLOR_BLACK")};
	end
			
	local blackThreshold = 5000;
	local differenceThreshold = 3000;
					
	local distanceAgainstBlack = ColorDistance(color, colorBlack);
	if(distanceAgainstBlack > blackThreshold) then
		for i, v in pairs(g_GraphLegendColors) do
			local distanceAgainstOtherPlayer = ColorDistance(color, v);
			if(distanceAgainstOtherPlayer < differenceThreshold) then
				-- Return false if the color is too close to a color that's already being used
				unique_cache[id] = true;
				return false;
			end
		end

		-- Return true if the color is far enough away from black and other colors being used
		unique_cache[id] = true;	
		return true;
	end
			
	-- Return false if color is too close to black
	unique_cache[id] = true;
	return false;
end
		
function DetermineGraphColor(unique_cache)
	local colors = UI.GetColors();

	for i, color in ipairs(colors) do
		local id = color[1];
		local value = color[2];

		local r,g,b,a = UI.GetColorChannels(value);

		if a == 255 then
			-- Ensure we only use unique and opaque colors
			if(IsUniqueColor(color, unique_cache)) then
				return color;
			end
		end
	end
								
	--error("Could not find a unique color");
	-- return the last entry.
	return colors[#colors];
end

function GetDataPointValue(dp, icons, uxHint)
	icons = icons or {};
	local value;

	if(uxHint == "Numeric") then
		value = tonumber(dp.ValueNumeric);
	else
		if(dp.ValueType) then
			value = "[COLOR_RED]" .. dp.ValueType .. "[ENDCOLOR]"; -- DEBUG
			local t = g_RulesetTypes[dp.ValueType];
			if(t) then
				table.insert(icons, t.Icon);
				value = Locale.Lookup(t.Name);
			end
		elseif(dp.ValueObjectId) then
			local o = g_GameObjects[dp.ValueObjectId];
			value ="[COLOR_RED]" .. dp.ValueObjectId .. "[ENDCOLOR]"; -- DEBUG
			if(o) then
				table.insert(icons, o.Icon);
				local p = g_GamePlayers[dp.ValueObjectId];						
				if(p) then
					table.insert(icons, "ICON_" .. p.LeaderType);
					table.insert(icons, "ICON_" .. p.CivilizationType);
					value = p.LeaderName;
				elseif(o.Name) then
					value = Locale.Lookup(o.Name);
				end
			end
		elseif(dp.ValueString) then
			value = Locale.Lookup(dp.ValueString);
		elseif(dp.ValueNumeric) then
			value = tonumber(dp.ValueNumeric);
		end	
	end

	return value, icons;
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

function SelectOverviewContext(index)
	g_OverviewContext = g_AvailableContexts[index];
	local button = Controls.OverviewContextPulldown:GetButton();

	TruncateStringWithTooltip(button, button:GetSizeX() - 50, g_OverviewContext.Name);
	
	Overview_UpdateMajorCivs(g_OverviewContext);
	Overview_UpdateVictoryBanner(g_OverviewContext.ObjectId);
	Overview_PopulateHighlightsForContext();
	Overview_PopulateStatisticsForContext();
	
	Controls.OverviewStack:CalculateSize();
	Controls.OverviewStack:ReprocessAnchoring();
	Controls.OverviewScrollPanel:CalculateInternalSize();
end

function SelectGraphGroup(index)
	local comboBox = Controls.GraphDataContextPulldown;
	local button = comboBox:GetButton();
	g_GraphGroup = g_Graphs and g_Graphs[index];
	if(g_GraphGroup) then
		TruncateStringWithTooltip(button, button:GetSizeX() - 50, g_GraphGroup.Name);
	else
		comboBox:GetButton():SetText("");
	end

	Graphs_PopulateGraphs();
	SelectGraph(1);
end

function SelectGraph(index)
	local comboBox = Controls.GraphDataSetPulldown;
	g_Graph = g_GraphGroup and g_GraphGroup[index];
	if(g_Graph) then
		comboBox:GetButton():SetText(g_Graph.Name);
	else
		comboBox:GetButton():SetText("");
	end
	Graphs_RefreshGraph(g_Graph);
end

function SelectReportGroup(index)
	local comboBox = Controls.ReportDataContextPulldown;
	local button = comboBox:GetButton();

	g_ReportsGroup = g_Reports and g_Reports[index];

	if(g_ReportsGroup) then
		TruncateStringWithTooltip(button, button:GetSizeX() - 50, g_ReportsGroup.Name);
	else
		button:SetText("");
	end

	Reports_PopulateReports();
	SelectReport(1);
end

function SelectReport(index)
	local comboBox = Controls.ReportPulldown;
	g_Report = g_ReportsGroup and g_ReportsGroup[index];
	if(g_Report) then
		Controls.ReportPulldown:GetButton():SetText(g_Report.Name);
	else
		Controls.ReportPulldown:GetButton():SetText("");
	end
	Reports_RefreshReport(g_Report);
end

----------------------------------------------------------------   
-- Populate Methods
----------------------------------------------------------------   
function Overview_GetContexts(data)
	-- Return an array of contexts.
	-- First entry is "Global"
	-- Followed by each player in the game sorted by PlayerId.
	-- Winner/You is denoted.
	
	local contexts = {};
	for i,v in ipairs(data.Players) do
		if(v.IsMajor) then
			local leaderName = v.LeaderName;					
			local name;
			if(v.IsLocal and data.VictorTeamId == v.TeamId) then
				name = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_LOCAL_WINNER", leaderName);
			elseif(data.IsLocal) then
				name = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_LOCAL", leaderName);
			elseif(data.VictorTeamId == v.TeamId) then
				name = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_WINNER", leaderName);
			else
				name = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT", leaderName);
			end
			
			table.insert(contexts,{
				Name = name,
				ObjectId = v.PlayerObjectId,
				PlayerId = v.PlayerId
			});
		end
	end
	
	table.sort(contexts, function(a,b) 
		return a.PlayerId < b.PlayerId;
	end);

	table.insert(contexts, 1, {Name = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_GLOBAL")});
	
	return contexts;
end

function Overview_PopulateContexts()
	local contexts = g_AvailableContexts;
	local comboBox = Controls.OverviewContextPulldown;
	comboBox:ClearEntries();
	for i, v in ipairs(contexts) do
		local controlTable = {};
		comboBox:BuildEntry( "InstanceOne", controlTable );
		TruncateStringWithTooltip(controlTable.Button, controlTable.Button:GetSizeX() - 12, v.Name);	
		controlTable.Button:RegisterCallback(Mouse.eLClick, function()
			SelectOverviewContext(i);
		end);	
	end

	comboBox:CalculateInternals();
end

function Overview_UpdateMajorCivs()
	g_PlayerManager:ResetInstances();
	
	if(g_OverviewContext.ObjectId == nil and g_GameData) then		
		
		-- Sort players by PlayerId.
		local players = {};
		for i,p in ipairs(g_GameData.Players) do
			table.insert(players,p);
		end
		table.sort(players, function(a,b) return a.PlayerId < b.PlayerId end);
		
		for i,p in ipairs(players) do
			if(p.IsMajor) then

				local civilizationName = p.CivilizationName;
				local leaderName = p.LeaderName;

				local civilizationIcons = {"ICON_CIVILIZATION_UNKNOWN"};
				local leaderIcons = {"ICON_LEADER_DEFAULT"};
			
				if(p.CivilizationType) then
					table.insert(civilizationIcons, "ICON_" .. p.CivilizationType);
				end
				
				if(p.LeaderType) then
					table.insert(leaderIcons, "ICON_" .. p.LeaderType);
				end

				local player = g_RulesetPlayers[p.LeaderType];
				if(player) then
					civilizationName = player.CivilizationName or civilizationName;
					leaderName = player.LeaderName or leaderName;
			
					table.insert(civilizationIcons, player.CivilizationIcon);
					table.insert(leaderIcons, player.LeaderIcon);
				end

				if(p.IsLocal) then
					leaderName = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_LOCAL", leaderName);
				else
					leaderName = Locale.Lookup(leaderName);
				end

				local instance = g_PlayerManager:GetInstance();
				instance.Score:SetText(p.Score);
				instance.PlayerLeaderIcon:SetHide(not SetControlIcon(instance.PlayerLeaderIcon, leaderIcons));
				instance.PlayerCivilizationIcon:SetHide(not SetControlIcon(instance.PlayerCivilizationIcon, civilizationIcons));

				local fgColor, bgColor = UI.GetPlayerColorValues(p.LeaderType, 0);
				instance.PlayerCivilizationIcon:SetColor(bgColor);
				instance.PlayerCivilizationIconBG:SetColor(fgColor);

				instance.PlayerLeaderName:LocalizeAndSetText(leaderName);
				instance.PlayerCivilizationName:LocalizeAndSetText(civilizationName);
	
				if(g_GameData.VictorTeamId == p.TeamId) then
					
					local name, icons = GetVictoryDetails(g_GameData.VictoryType);

					instance.VictoryName:SetText(HallofFame.GetLocalizedVictoryTypeText(name));
					SetControlIcon(instance.VictoryIcon, icons);
				else
					instance.VictoryIcon:SetIcon("ICON_DEFEAT_GENERIC");
					instance.VictoryName:LocalizeAndSetText("LOC_GAMESUMMARY_DEFEAT");
				end
			end
		end
		
		Controls.Players:SetHide(false);
		Controls.PlayersStack:CalculateSize();
		Controls.PlayersStack:ReprocessAnchoring();
	else
		Controls.Players:SetHide(true);
	end
end

function Overview_UpdateVictoryBanner(playerObjectId)

	local victoryName, victoryIcons;
	if(playerObjectId) then
		local player;
		for i,v in ipairs(g_GameData.Players) do 
			if(v.PlayerObjectId == playerObjectId) then
				player = v;
				break;
			end
		end
	
		if(player) then
			if(player.TeamId == g_GameData.VictorTeamId) then
				victoryName, victoryIcons = GetVictoryDetails(g_GameData.VictoryType);
			end
		end		
	end
	
	if(victoryName and victoryIcons) then
		
		SetControlIcon(Controls.RibbonIcon, victoryIcons);

		Controls.RibbonTile:SetTexture("EndGame_RibbonTile_Time");
		Controls.Ribbon:SetTexture("EndGame_Ribbon_Time");
		Controls.RibbonLabel:LocalizeAndSetText(victoryName);
		Controls.RibbonContainer:SetHide(false);
	elseif(playerObjectId) then
		Controls.RibbonIcon:SetIcon("ICON_DEFEAT_GENERIC");
		Controls.RibbonTile:SetTexture("EndGame_RibbonTile_Defeat");
		Controls.Ribbon:SetTexture("EndGame_Ribbon_Defeat");
		Controls.RibbonLabel:LocalizeAndSetText("LOC_DEFEAT_DEFAULT_NAME");
		Controls.RibbonContainer:SetHide(false);
	else
		Controls.RibbonContainer:SetHide(true);
	end	
end

function Overview_PopulateHighlightsForContext()
	-- Clear instances.
	g_HighlightsManager:ResetInstances();
	
	--local stats;
	--if(g_OverviewContext.ObjectId) then
		--stats = HallofFame.GetObjectHighlights(g_OverviewContext.ObjectId, 10) or {};
	--else
		--stats = HallofFame.GetGameHighlights(g_GameData.GameId, 10) or {};
	--end
	--
	--if(#stats == 0) then
		--Controls.Highlights:SetHide(true);
		--return;
	--end
	--
	--Controls.Highlights:SetHide(false);
	--
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

function Overview_PopulateStatisticsForContext()

	-- Clear statistics instances.
	for i,v in ipairs(g_StatisticsManagers) do
		v:ResetInstances();
	end
	g_StatisticsBlockManager:ResetInstances();
	g_StatisticsManagers = {};

	-- Clear GameMode name instances.
	m_GameModeNamesIM:ResetInstances();
	local enabledGameModesMetaData : string = "";

	-- Collect data points.
	local indexed_datapoints = {};
	local datapoints;
	if(g_OverviewContext.ObjectId) then
		datapoints = HallofFame.GetObjectDataPoints(g_OverviewContext.ObjectId);
	else
		datapoints = HallofFame.GetGameDataPoints(g_GameData.GameId);
	end
	for i,v in ipairs(datapoints) do
		indexed_datapoints[v.DataPoint] = v;
		if(v.DataPoint == "EnabledGameModes") then
			enabledGameModesMetaData = v.ValueString;
		end
	end

	-- Correlate Statistics with data points
	local statistics_by_category = {};
	for i,stat in ipairs(g_Statistics) do		
		local dp = indexed_datapoints[stat.DataPoint];
		if(dp) then
			local v = {
				Name = stat.Name,
				Icon = stat.Icon,	
			};

			local value = "";
			local icons = {stat.ValueIconDefault};
			value, icons = GetDataPointValue(dp, icons);

			if(value and value ~= 0) then
				table.insert(icons, stat.ValueIconOverride);

				v.DisplayValue = value;
				v.ValueIcons = icons;

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
	end

	-- Visualize Statistics
	for i,cat in ipairs(g_Categories) do
		local stats = statistics_by_category[cat.Category];

		if(not cat.IsHidden and stats and #stats > 0) then
			local cat_instance = g_StatisticsBlockManager:GetInstance();
			cat_instance.StatsTitle:SetText(cat.Name);
			
			local statsManager = InstanceManager:new("StatInstance", "Root", cat_instance.StatisticsStack);
			table.insert(g_StatisticsManagers, statsManager);
			
			for _,stat in ipairs(stats) do
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
			
			cat_instance.StatisticsStack:CalculateSize();
			cat_instance.StatisticsStack:ReprocessAnchoring();
			cat_instance.RootStack:CalculateSize();
			cat_instance.RootStack:ReprocessAnchoring();
		end
	end

	--Populate the enabled game modes section from our metadata
	if(enabledGameModesMetaData ~= "" and enabledGameModesMetaData ~= nil)then
		local enabledGameModesNames : table = Modding.GetGameModesFromConfigurationString(enabledGameModesMetaData);
		if(enabledGameModesNames ~= nil and #enabledGameModesNames > 0)then
			Controls.GameModesStack:SetHide(false);
			table.sort(enabledGameModesNames, function(a,b) return Locale.Compare(a.Name,b.Name) == -1 end);
			for i,enabledGameMode in ipairs(enabledGameModesNames)do
				local uiGameModeName : table = m_GameModeNamesIM:GetInstance();
				uiGameModeName.GameModeName:SetText(enabledGameMode.Name);
			end
		end
	else
		Controls.GameModesStack:SetHide(true);
	end

	Controls.StatisticsStack:CalculateSize();
	Controls.StatisticsStack:ReprocessAnchoring();
end

function Graphs_PopulateGroups()
	local comboBox = Controls.GraphDataContextPulldown;
	comboBox:ClearEntries();

	local hasItems = g_Graphs and #g_Graphs > 1;
	if(hasItems) then
		for i, v in ipairs(g_Graphs) do
			local controlTable = {};
			comboBox:BuildEntry( "InstanceOne", controlTable );
			TruncateStringWithTooltip(controlTable.Button, controlTable.Button:GetSizeX() - 12, v.Name);
			controlTable.Button:RegisterCallback(Mouse.eLClick, function()
				SelectGraphGroup(i);
			end);	
		end
	end
	
	comboBox:SetDisabled(not hasItems);
	comboBox:CalculateInternals();
end

function Graphs_PopulateGraphs()
	local comboBox = Controls.GraphDataSetPulldown;
	comboBox:ClearEntries();

	local hasItems = g_GraphGroup and #g_GraphGroup > 1;
	if(hasItems) then
		for i, v in ipairs(g_GraphGroup) do
			local controlTable = {};
			comboBox:BuildEntry( "InstanceOne", controlTable );
			controlTable.Button:SetText(v.Name);
			controlTable.Button:RegisterCallback(Mouse.eLClick, function()
				SelectGraph(i);
			end);	
		end
	end
	comboBox:SetDisabled(not hasItems);
	comboBox:CalculateInternals();
end

function Graphs_RefreshGraph(graph)

	-- Reset data.
	g_GraphLegendManager:ResetInstances();
	Controls.NoGraphData:SetHide(graph ~= nil);
	Controls.GraphContainer:SetHide(graph == nil);

	if(graph == nil) then
		return;
	end

	function DrawGraph(data, pDataSet, minX, maxX)
		turnData = {};
		local prev_value;
		local isDelta = data.IsDelta;
		for i = minX,maxX,1 do
			local value = data[i];
			if(value ~= nil) then			
				turnData[i - minX] = value;
				prev_value = value;
			elseif(prev_value and isDelta) then
				turnData[i - minX] = prev_value;
			end
		end
		
		pDataSet:Clear();
		for turn = minX, maxX + 1, 1 do
			local y = turnData[turn - minX];
			if (y == nil) then
				pDataSet:BreakLine();
			else
				pDataSet:AddVertex(turn, y);
			end
		end
	end
		
	Controls.ResultsGraph:SetRange(graph.MinY - (graph.MinY % 10), graph.MaxY + (10 - (graph.MaxY % 10)));
	Controls.ResultsGraph:SetDomain(graph.MinX, graph.MaxX);
	
	local yTick = math.max(1, math.floor((graph.MaxY - graph.MinY) / 20));
	Controls.ResultsGraph:SetYTickInterval(yTick);
	Controls.ResultsGraph:SetYNumberInterval( yTick * 2);
	
	local xTick = math.max(1, math.floor((graph.MaxX - graph.MinX) / 24));
	Controls.ResultsGraph:SetXTickInterval(xTick);
	Controls.ResultsGraph:SetXNumberInterval( xTick * 2);

	Controls.ResultsGraph:DeleteAllDataSets();
	g_GraphLegendColors = {};
	g_GraphDataSets = {};
	local unique_color_cache = {
		["COLOR_CLEAR"] = true,
		["COLOR_WHITE"] = true,
		["COLOR_BLACK"] = true,
		["COLOR_GREY"] = true,

	};
	for i,v in ipairs(graph) do
		local instance = g_GraphLegendManager:GetInstance();

		TruncateStringWithTooltip(instance.Name, instance.Root:GetSizeX() - 52, Locale.Lookup(v.Name));
		local color = DetermineGraphColor(unique_color_cache);
		g_GraphLegendColors[i] = color;
		local colorValue = color[2];
		instance.Icon:SetColor(colorValue);
		instance.ShowHide:SetCheck(v.Hidden ~= true);

		local pDataSet = Controls.ResultsGraph:CreateDataSet(tostring(i));
		pDataSet:SetColor(colorValue);
		pDataSet:SetWidth(2.0);
		pDataSet:SetVisible(v.Hidden ~= true);

		instance.ShowHide:RegisterCheckHandler( function(bCheck)
			local s = g_GraphDataSets[i];
			if(s) then
				s:SetVisible(bCheck);
			end
		end);

		DrawGraph(v, pDataSet, graph.MinX, graph.MaxX);
		
		g_GraphDataSets[i] = pDataSet;
	end	
end

function Reports_PopulateGroups()
	local comboBox = Controls.ReportDataContextPulldown;
	comboBox:ClearEntries();

	local hasItems = g_Reports and #g_Reports > 1;
	if(hasItems) then
		for i, v in ipairs(g_Reports) do
			local controlTable = {};
			comboBox:BuildEntry( "InstanceOne", controlTable );
			TruncateStringWithTooltip(controlTable.Button, controlTable.Button:GetSizeX() - 12, v.Name);
			controlTable.Button:RegisterCallback(Mouse.eLClick, function()
				SelectReportGroup(i);
			end);	
		end
	end
	
	comboBox:SetDisabled(not hasItems);
	comboBox:CalculateInternals();
end

function Reports_PopulateReports()
	local comboBox = Controls.ReportPulldown;
	comboBox:ClearEntries();

	local hasItems = g_ReportsGroup and #g_ReportsGroup > 1;
	if(hasItems) then
		for i, v in ipairs(g_ReportsGroup) do
			local controlTable = {};
			comboBox:BuildEntry( "InstanceOne", controlTable );
			controlTable.Button:SetText(v.Name);
			controlTable.Button:RegisterCallback(Mouse.eLClick, function()
				SelectReport(i);
			end);	
		end
	end
	comboBox:SetDisabled(not hasItems);
	comboBox:CalculateInternals();
end

function Reports_RefreshReport(report)
	for i,v in ipairs(g_ReportCellManagers) do
		v:ResetInstances();
	end
	 g_ReportRowManager:ResetInstances();
	 g_ReportHeaderManager:ResetInstances();
	
	Controls.NoReportData:SetHide(report ~= nil);
	if(report == nil) then
		return;
	end

	-- Populate Initial Column
	local initialColumnInstance = g_ReportHeaderManager:GetInstance();
	initialColumnInstance.Name:LocalizeAndSetText(report.InitialColumnName);

	-- Populate Additional Columns
	for i,v in ipairs(report.Columns) do
		if(not v.Empty or v.AlwaysShow) then
			local instance = g_ReportHeaderManager:GetInstance();
			instance.Name:LocalizeAndSetText(v.Name);
		end
	end

	-- Populate each row.
	for i,v in ipairs(report) do
		
		local row = g_ReportRowManager:GetInstance();

		local cellManager = InstanceManager:new("ReportCellInstance", "Root", row.ColumnStack);
		table.insert(g_ReportCellManagers, cellManager);

		-- Populate Initial Column
		local initialColumn = v[0];
		local initialCell = cellManager:GetInstance();
		
		--initialCell.Value:SetText(initialColumn.Value);
		TruncateStringWithTooltip(initialCell.Value, REPORT_CELL_WIDTH, initialColumn.Value);

		-- Disable Icons for now
		----if(SetControlIcon(initialCell.ValueIcon, initialColumn.Icons)) then
		--	initialCell.ValueIcon:SetHide(false);
		--else
			initialCell.ValueIcon:SetHide(true);
		--end
		
		initialCell.ValueStack:CalculateSize();
		initialCell.ValueStack:ReprocessAnchoring();

		-- Populate Additional Columns
		for column_index, column in ipairs(report.Columns) do
			if(not column.Empty or column.AlwaysShow) then
				local instance = cellManager:GetInstance();

				local column_data = v[column_index];

				local valueIcons = column_data and column_data.Icons or {column.ValueIconDefault, column.ValueIconOverride};
				local value = column_data and column_data.Value or column.DefaultValue;

--				instance.Value:LocalizeAndSetText(value);
				TruncateStringWithTooltip(instance.Value, REPORT_CELL_WIDTH, value);

				-- Disable icons for now
				--if(valueIcons and SetControlIcon(instance.ValueIcon, valueIcons)) then
				--	instance.ValueIcon:SetHide(false);
				--else
					instance.ValueIcon:SetHide(true);
				--end
			
				instance.ValueStack:CalculateSize();
				instance.ValueStack:ReprocessAnchoring();
			end

		end
		row.ColumnStack:CalculateSize();
		row.ColumnStack:ReprocessAnchoring();
	end

	Controls.ReportHeaderStack:CalculateSize();
	Controls.ReportHeaderStack:ReprocessAnchoring();
	Controls.ReportStack:CalculateSize();
	Controls.ReportStack:ReprocessAnchoring();
end

----------------------------------------------------------------    
function HandleExitRequest()
	UIManager:DequeuePopup( ContextPtr );
end

----------------------------------------------------------------   
-- Event Handlers
----------------------------------------------------------------  


----------------------------------------------------------------    
function OnShow()
	UpdateGlobalCache();
	Overview_PopulateContexts();	
	Graphs_PopulateGroups();
	Reports_PopulateGroups();

	SelectGraphGroup(1);
	SelectReportGroup(1);
	SelectOverviewContext(1);	-- Should always be 'Global'
	SelectTab(1);
end	

function OnHide()
	DumpInstances();
	DumpGlobalCache();
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
	g_PopupDialog = PopupDialog:new( "GameDetails" );

	Controls.CloseButton:RegisterCallback( Mouse.eLClick, function()
		UI.PlaySound("Main_Menu_Mouse_Over");
		HandleExitRequest();
	end);
	
	for i,v in ipairs(g_TabControls) do
		v[1]:RegisterCallback( Mouse.eLClick, function()
			UI.PlaySound("Main_Menu_Mouse_Over");
			SelectTab(i);
		end);
	end
	SelectTab(1);
	
	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
	ContextPtr:SetPostInit(PostInit);
end

--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local DETAIL_PANEL_ID = "CAIHoFDetail_Panel"
local HOVER_SOUND     = "Main_Menu_Mouse_Over"

local m_detailPanel     = nil
local m_detailTabs      = nil
local m_overviewTree    = nil
local m_reportsTree     = nil
local m_graphsTree      = nil
local m_isDetailBuilt   = false

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

-- ============================================================================
-- Overview tab: statistics tree
-- ============================================================================
local function BuildStatsForDatapoints(parentNode, datapoints, idPrefix)
    local indexed_datapoints = {}
    if datapoints then
        for _, v in ipairs(datapoints) do
            indexed_datapoints[v.DataPoint] = v
        end
    end

    local statistics_by_category = {}
    for _, stat in ipairs(g_Statistics or {}) do
        local dp = indexed_datapoints[stat.DataPoint]
        if dp then
            local value = GetDataPointValue(dp, {})
            if value and value ~= 0 then
                local annotation = nil
                if stat.Annotation then
                    annotation = Locale.Lookup(stat.Annotation, { Name = "Amount", Value = dp.ValueNumeric })
                end
                local displayValue = type(value) == "number" and Locale.ToNumber(value, "###,###") or tostring(value)
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
            local catNode = mgr:CreateWidget(MakeId("CAIHoFD_stat_"), "TreeItem", {
                Label = function() return cat.Name end,
                FocusKey = idPrefix .. ":statcat:" .. cat.Category,
            })
            catNode:SetFocusSound(HOVER_SOUND)
            parentNode:AddChild(catNode)

            for si, stat in ipairs(stats) do
                local statLabel = stat.Name .. ": " .. stat.DisplayValue
                if stat.Annotation then
                    statLabel = statLabel .. " (" .. stat.Annotation .. ")"
                end
                local capLabel = statLabel
                local statLeaf = mgr:CreateWidget(MakeId("CAIHoFD_stat_"), "StaticText", {
                    Label = function() return capLabel end,
                    FocusKey = idPrefix .. ":stat:" .. cat.Category .. ":" .. si,
                })
                statLeaf:SetFocusSound(HOVER_SOUND)
                catNode:AddChild(statLeaf)
            end
        end
    end

    return indexed_datapoints
end

local function RebuildDetailOverview()
    if not m_overviewTree then return end
    local capture = mgr:CaptureFocusKey(m_overviewTree)
    m_overviewTree:ClearChildren()

    if not g_GameData then
        mgr:RestoreFocus(m_overviewTree, capture)
        return
    end

    -- Overall category: game-level statistics and game modes
    local overallLabel = Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_GLOBAL")
    local overallNode = mgr:CreateWidget(MakeId("CAIHoFD_ov_"), "TreeItem", {
        Label = function() return overallLabel end,
        FocusKey = "hofdetail:overview:overall",
    })
    overallNode:SetFocusSound(HOVER_SOUND)
    m_overviewTree:AddChild(overallNode)

    local gameDatapoints = HallofFame.GetGameDataPoints(g_GameData.GameId)
    local gameIndexed = BuildStatsForDatapoints(overallNode, gameDatapoints, "hofdetail:overview:game")

    local enabledGameModesStr = gameIndexed["EnabledGameModes"] and gameIndexed["EnabledGameModes"].ValueString or nil
    if enabledGameModesStr and enabledGameModesStr ~= "" and Modding and Modding.GetGameModesFromConfigurationString then
        local modeNames = Modding.GetGameModesFromConfigurationString(enabledGameModesStr)
        if modeNames and #modeNames > 0 then
            local modesNode = mgr:CreateWidget(MakeId("CAIHoFD_gm_"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_GAMESUMMARY_CATEGORY_ENABLED_GAMEMODES") end,
                FocusKey = "hofdetail:overview:gamemodes",
            })
            modesNode:SetFocusSound(HOVER_SOUND)
            overallNode:AddChild(modesNode)

            table.sort(modeNames, function(a, b) return Locale.Compare(a.Name, b.Name) == -1 end)
            for mi, mode in ipairs(modeNames) do
                local capName = mode.Name
                local modeLeaf = mgr:CreateWidget(MakeId("CAIHoFD_gm_"), "StaticText", {
                    Label = function() return capName end,
                    FocusKey = "hofdetail:overview:gamemode:" .. mi,
                })
                modeLeaf:SetFocusSound(HOVER_SOUND)
                modesNode:AddChild(modeLeaf)
            end
        end
    end

    -- Per-player nodes with player info + player-specific statistics
    local players = {}
    for _, p in ipairs(g_GameData.Players) do
        if p.IsMajor then table.insert(players, p) end
    end
    table.sort(players, function(a, b) return a.PlayerId < b.PlayerId end)

    for pi, p in ipairs(players) do
        local parts = {}
        local leaderName = p.LeaderName
        local civName = p.CivilizationName
        local rulesetPlayer = g_RulesetPlayers[p.LeaderType]
        if rulesetPlayer then
            leaderName = rulesetPlayer.LeaderName or leaderName
            civName = rulesetPlayer.CivilizationName or civName
        end
        if p.IsLocal then
            table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_CONTEXT_LOCAL", leaderName))
        else
            table.insert(parts, Locale.Lookup(leaderName))
        end
        table.insert(parts, Locale.Lookup(civName))
        if p.Score then table.insert(parts, tostring(p.Score)) end
        if g_GameData.VictorTeamId == p.TeamId then
            local vName = GetVictoryDetails(g_GameData.VictoryType)
            if vName then table.insert(parts, Locale.Lookup(vName)) end
        else
            table.insert(parts, Locale.Lookup("LOC_GAMESUMMARY_DEFEAT"))
        end
        local capLabel = table.concat(parts, ", ")

        local playerNode = mgr:CreateWidget(MakeId("CAIHoFD_pl_"), "TreeItem", {
            Label = function() return capLabel end,
            FocusKey = "hofdetail:overview:player:" .. pi,
        })
        playerNode:SetFocusSound(HOVER_SOUND)
        m_overviewTree:AddChild(playerNode)

        -- Find this player's context and add their statistics
        for _, ctx in ipairs(g_AvailableContexts or {}) do
            if ctx.ObjectId and ctx.PlayerId == p.PlayerId then
                local playerDatapoints = HallofFame.GetObjectDataPoints(ctx.ObjectId)
                BuildStatsForDatapoints(playerNode, playerDatapoints, "hofdetail:overview:p" .. pi)
                break
            end
        end
    end

    mgr:RestoreFocus(m_overviewTree, capture)
end

-- ============================================================================
-- Graphs tab: Player → Graph Type (final value) → Turn samples
-- ============================================================================
local function AddTurnSamples(parentNode, ds, minX, maxX, idPrefix)
    local step = math.max(1, math.floor((maxX - minX) / 10))
    for turn = minX, maxX, step do
        local val = ds[turn]
        if val ~= nil then
            local capTurnLabel = Locale.Lookup("LOC_GAMESUMMARY_TURNS", turn) .. ": " .. tostring(math.floor(val))
            local turnLeaf = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "StaticText", {
                Label = function() return capTurnLabel end,
                FocusKey = idPrefix .. ":t:" .. turn,
            })
            turnLeaf:SetFocusSound(HOVER_SOUND)
            parentNode:AddChild(turnLeaf)
        end
    end
end

local function GetLastValue(ds, minX, maxX)
    for turn = maxX, minX, -1 do
        if ds[turn] ~= nil then
            return ds[turn]
        end
    end
    return nil
end

local function RebuildGraphsTree()
    if not m_graphsTree then return end
    local capture = mgr:CaptureFocusKey(m_graphsTree)
    m_graphsTree:ClearChildren()

    if not g_Graphs or #g_Graphs == 0 then
        local noData = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_GAMESUMMARY_NOGRAPHDATA") end,
            FocusKey = "hofdetail:graph:nodata",
        })
        noData:SetFocusSound(HOVER_SOUND)
        m_graphsTree:AddChild(noData)
        mgr:RestoreFocus(m_graphsTree, capture)
        return
    end

    local function AddGraphEntry(parentNode, graphName, ds, minX, maxX, idBase)
        local lastVal = GetLastValue(ds, minX, maxX)
        local valStr = lastVal and tostring(math.floor(lastVal)) or "0"
        local capLabel = graphName .. ": " .. valStr
        local node = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "TreeItem", {
            Label = function() return capLabel end,
            FocusKey = idBase,
        })
        node:SetFocusSound(HOVER_SOUND)
        parentNode:AddChild(node)
        AddTurnSamples(node, ds, minX, maxX, idBase)
    end

    local function FindOrCreateEntity(parentNode, entityName, entityKey)
        local existing = mgr:FindByFocusKey(parentNode, entityKey)
        if existing then return existing end
        local node = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "TreeItem", {
            Label = function() return entityName end,
            FocusKey = entityKey,
        })
        node:SetFocusSound(HOVER_SOUND)
        parentNode:AddChild(node)
        return node
    end

    if #g_Graphs > 1 then
        -- Merge Overall (group 1) into per-player groups (2+)
        -- Step 1: create player nodes with Overall subcategories
        local playerNodes = {}
        local overallNodes = {}
        for gi = 2, #g_Graphs do
            local group = g_Graphs[gi]
            local playerName = group.Name or ""
            local playerNode = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "TreeItem", {
                Label = function() return playerName end,
                FocusKey = "hofdetail:graph:player:" .. gi,
            })
            playerNode:SetFocusSound(HOVER_SOUND)
            m_graphsTree:AddChild(playerNode)

            local overallLabel = Locale.Lookup("LOC_GAMESUMMARY_OVERVIEW")
            local overallNode = mgr:CreateWidget(MakeId("CAIHoFD_graph_"), "TreeItem", {
                Label = function() return overallLabel end,
                FocusKey = "hofdetail:graph:player:" .. gi .. ":ov",
            })
            overallNode:SetFocusSound(HOVER_SOUND)
            playerNode:AddChild(overallNode)

            playerNodes[gi] = playerNode
            overallNodes[gi] = overallNode
            overallNodes[playerName] = overallNode
        end

        -- Step 2: distribute Overall group datasets into player Overall subcategories
        local overallGroup = g_Graphs[1]
        for gri, graph in ipairs(overallGroup) do
            local graphName = graph.Name or ""
            local minX = graph.MinX
            local maxX = graph.MaxX
            for dsi, ds in ipairs(graph) do
                if ds.Name then
                    local dsName = Locale.Lookup(ds.Name)
                    local target = overallNodes[dsName]
                    if target then
                        AddGraphEntry(target, graphName, ds, minX, maxX,
                            "hofdetail:graph:1:" .. gri .. ":" .. dsi)
                    end
                end
            end
        end

        -- Step 3: process per-player groups — named datasets under city nodes,
        -- nameless datasets under the Overall subcategory
        for gi = 2, #g_Graphs do
            local group = g_Graphs[gi]
            local playerNode = playerNodes[gi]
            local overallNode = overallNodes[gi]

            for gri, graph in ipairs(group) do
                local graphName = graph.Name or ""
                local minX = graph.MinX
                local maxX = graph.MaxX

                for dsi, ds in ipairs(graph) do
                    local idBase = "hofdetail:graph:" .. gi .. ":" .. gri .. ":" .. dsi
                    if ds.Name then
                        local cityName = Locale.Lookup(ds.Name)
                        local cityKey = "hofdetail:graph:city:" .. gi .. ":" .. dsi
                        local cityNode = FindOrCreateEntity(playerNode, cityName, cityKey)
                        AddGraphEntry(cityNode, graphName, ds, minX, maxX, idBase)
                    else
                        AddGraphEntry(overallNode, graphName, ds, minX, maxX, idBase)
                    end
                end
            end
        end
    else
        -- Single group — flat display with entity nesting
        local group = g_Graphs[1]
        for gri, graph in ipairs(group) do
            local graphName = graph.Name or ""
            local minX = graph.MinX
            local maxX = graph.MaxX

            for dsi, ds in ipairs(graph) do
                local idBase = "hofdetail:graph:1:" .. gri .. ":" .. dsi
                if ds.Name then
                    local dsName = Locale.Lookup(ds.Name)
                    local entityKey = "hofdetail:graph:e:1:" .. dsi
                    local entityNode = FindOrCreateEntity(m_graphsTree, dsName, entityKey)
                    AddGraphEntry(entityNode, graphName, ds, minX, maxX, idBase)
                else
                    AddGraphEntry(m_graphsTree, graphName, ds, minX, maxX, idBase)
                end
            end
        end
    end

    mgr:RestoreFocus(m_graphsTree, capture)
end

-- ============================================================================
-- Reports tab: Context → Report Type → Row → Column values
-- ============================================================================
local function RebuildReportsTree()
    if not m_reportsTree then return end
    local capture = mgr:CaptureFocusKey(m_reportsTree)
    m_reportsTree:ClearChildren()

    if not g_Reports or #g_Reports == 0 then
        local noData = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "StaticText", {
            Label = function() return Locale.Lookup("LOC_GAMESUMMARY_NOREPORTDATA") end,
            FocusKey = "hofdetail:report:nodata",
        })
        noData:SetFocusSound(HOVER_SOUND)
        m_reportsTree:AddChild(noData)
        mgr:RestoreFocus(m_reportsTree, capture)
        return
    end

    local skipContextLevel = #g_Reports == 1

    for gi, group in ipairs(g_Reports) do
        local contextNode = nil
        if not skipContextLevel then
            local contextName = group.Name or ""
            contextNode = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "TreeItem", {
                Label = function() return contextName end,
                FocusKey = "hofdetail:report:ctx:" .. gi,
            })
            contextNode:SetFocusSound(HOVER_SOUND)
            m_reportsTree:AddChild(contextNode)
        end

        local parentForReports = contextNode or m_reportsTree

        for rpi, report in ipairs(group) do
            local reportName = report.Name or Locale.Lookup("LOC_GAMESUMMARY_UNKNOWN")
            local reportNode = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "TreeItem", {
                Label = function() return reportName end,
                FocusKey = "hofdetail:report:" .. gi .. ":" .. rpi,
            })
            reportNode:SetFocusSound(HOVER_SOUND)
            parentForReports:AddChild(reportNode)

            for ri, row in ipairs(report) do
                local rowName = row.Name or Locale.Lookup("LOC_GAMESUMMARY_UNKNOWN")

                local cellParts = {}
                for ci, column in ipairs(report.Columns) do
                    if not column.Empty or column.AlwaysShow then
                        local cell = row[ci]
                        local cellValue = cell and cell.Value or column.DefaultValue
                        if cellValue ~= nil then
                            local colName = Locale.Lookup(column.Name)
                            local displayVal = type(cellValue) == "number" and tostring(cellValue) or tostring(cellValue)
                            table.insert(cellParts, { name = colName, value = displayVal, colIndex = ci })
                        end
                    end
                end

                if #cellParts <= 3 then
                    local parts = { rowName }
                    for _, cp in ipairs(cellParts) do
                        table.insert(parts, cp.name .. ": " .. cp.value)
                    end
                    local capLabel = table.concat(parts, ", ")
                    local rowLeaf = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "StaticText", {
                        Label = function() return capLabel end,
                        FocusKey = "hofdetail:report:" .. gi .. ":" .. rpi .. ":r:" .. ri,
                    })
                    rowLeaf:SetFocusSound(HOVER_SOUND)
                    reportNode:AddChild(rowLeaf)
                else
                    local rowNode = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "TreeItem", {
                        Label = function() return rowName end,
                        FocusKey = "hofdetail:report:" .. gi .. ":" .. rpi .. ":r:" .. ri,
                    })
                    rowNode:SetFocusSound(HOVER_SOUND)
                    reportNode:AddChild(rowNode)

                    for _, cp in ipairs(cellParts) do
                        local capCellLabel = cp.name .. ": " .. cp.value
                        local cellLeaf = mgr:CreateWidget(MakeId("CAIHoFD_rep_"), "StaticText", {
                            Label = function() return capCellLabel end,
                            FocusKey = "hofdetail:report:" .. gi .. ":" .. rpi .. ":r:" .. ri .. ":c:" .. cp.colIndex,
                        })
                        cellLeaf:SetFocusSound(HOVER_SOUND)
                        rowNode:AddChild(cellLeaf)
                    end
                end
            end
        end
    end

    mgr:RestoreFocus(m_reportsTree, capture)
end

-- ============================================================================
-- Dropdown helpers
-- ============================================================================
-- ============================================================================
-- Build / Teardown
-- ============================================================================
local function BuildDetailPanel()
    if m_isDetailBuilt then return end

    -- Panel title includes victory banner text
    m_detailPanel = mgr:CreateWidget(DETAIL_PANEL_ID, "Panel", {
        Label = function()
            local title = Locale.Lookup("LOC_GAMESUMMARY_TITLE")
            if g_GameData then
                local victoryName = nil
                if g_GameData.VictorTeamId then
                    victoryName = GetVictoryDetails(g_GameData.VictoryType)
                    if victoryName then
                        victoryName = Locale.Lookup(victoryName)
                    end
                end
                if not victoryName then
                    victoryName = Locale.Lookup("LOC_GAMESUMMARY_DEFEAT")
                end
                title = title .. ", " .. victoryName
            end
            return title
        end,
    })

    -- Tabs
    m_detailTabs = mgr:CreateWidget(MakeId("CAIHoFD_tabs_"), "TabControl", {})
    m_detailPanel:AddChild(m_detailTabs)

    -- Tab 1: Overview
    local overviewPage = m_detailTabs:AddPage(function() return Locale.Lookup("LOC_GAMESUMMARY_OVERVIEW") end)
    m_overviewTree = mgr:CreateWidget(MakeId("CAIHoFD_ov_"), "Tree", {})
    overviewPage:AddChild(m_overviewTree)

    -- Tab 2: Reports
    local reportsPage = m_detailTabs:AddPage(function() return Locale.Lookup("LOC_GAMESUMMARY_REPORTS") end)
    m_reportsTree = mgr:CreateWidget(MakeId("CAIHoFD_rept_"), "Tree", {})
    reportsPage:AddChild(m_reportsTree)

    -- Tab 3: Graphs
    local graphsPage = m_detailTabs:AddPage(function() return Locale.Lookup("LOC_GAMESUMMARY_GRAPHS") end)
    m_graphsTree = mgr:CreateWidget(MakeId("CAIHoFD_grt_"), "Tree", {})
    graphsPage:AddChild(m_graphsTree)

    -- Tab sync
    local vanillaTabButtons = { Controls.OverviewTab, Controls.ReportsTab, Controls.GraphsTab }
    local isMirroringTab = false
    m_detailTabs:On("value_changed", function(_, pageIndex)
        if isMirroringTab then return end
        isMirroringTab = true
        local btn = vanillaTabButtons[pageIndex]
        if btn then btn:DoLeftClick() end
        isMirroringTab = false
    end)

    m_isDetailBuilt = true
end

local function PushDetailPanel()
    BuildDetailPanel()
    RebuildDetailOverview()
    RebuildGraphsTree()
    RebuildReportsTree()
    mgr:Push(m_detailPanel, PopupPriority.Current)
end

local function DestroyDetailPanel()
    if m_isDetailBuilt then
        mgr:RemoveFromStack(DETAIL_PANEL_ID)
        m_detailPanel = nil
        m_detailTabs = nil
        m_overviewTree = nil
        m_reportsTree = nil
        m_graphsTree = nil
        m_isDetailBuilt = false
    end
end

-- Wrap vanilla lifecycle
OnShow = WrapFunc(OnShow, function(orig)
    orig()
    if not mgr:GetWidgetById(DETAIL_PANEL_ID) then
        PushDetailPanel()
    end
end)

HandleExitRequest = WrapFunc(HandleExitRequest, function(orig)
    DestroyDetailPanel()
    orig()
end)

-- Wrap graph/report group selection to rebuild CAI trees
SelectGraphGroup = WrapFunc(SelectGraphGroup, function(orig, index)
    orig(index)
    RebuildGraphsTree()
end)

SelectReportGroup = WrapFunc(SelectReportGroup, function(orig, index)
    orig(index)
    RebuildReportsTree()
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