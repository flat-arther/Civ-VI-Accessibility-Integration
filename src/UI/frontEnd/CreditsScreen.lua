-- ===========================================================================
--	Credits
--
--	Format: [#]Text
--	Where # is  1: Major title
--				2: Minor title
--				3: Heading
--				4: Name
--				i: Image
-- ===========================================================================
include( "InstanceManager" );


-- ===========================================================================
--	Variables
-- ===========================================================================
local m_BlankIM		:table = InstanceManager:new("BlankInstance",		"Top",	Controls.CreditsList);
local m_EntryIM		:table = InstanceManager:new("EntryInstance",		"Text", Controls.CreditsList);
local m_HeadingIM	:table = InstanceManager:new("HeadingInstance",		"Text", Controls.CreditsList);
local m_ImageIM		:table = InstanceManager:new("ImageInstance",		"Image",Controls.CreditsList);
local m_MajorTitleIM:table = InstanceManager:new("MajorTitleInstance",	"Text", Controls.CreditsList);
local m_MinorTitleIM:table = InstanceManager:new("MinorTitleInstance",	"Text", Controls.CreditsList);
local m_TurboMode   :boolean = false;

CreditsData = nil;
CreditsIndex = 1;

-- ===========================================================================
function OnClose()

	-- Stop the scrolling to prevent callbacks while the screen is closed.
	Controls.SlideAnim:Stop();

	-- Cleanup instances.
	removeEntries();

	UIManager:DequeuePopup( ContextPtr );
end

-- ===========================================================================
function OnCreditScrollComplete()
	if ContextPtr:IsVisible() and CreditsData ~= nil then
		CreditsIndex = CreditsIndex + 1;
		if(CreditsIndex > #CreditsData) then
			CreditsIndex = 1;
		end

		DisplayCredits(CreditsIndex);
	end
end
-- ===========================================================================
--	Key Down Processing
-- ===========================================================================
function OnInputHandler( pInputStruct:table )
	local uiMsg = pInputStruct:GetMessageType();
    
	if uiMsg == KeyEvents.KeyDown then
		local key:number = pInputStruct:GetKey();
		-- "T"urbo mode... for debugging.
		if key == Keys.T and pInputStruct:IsShiftDown() and pInputStruct:IsAltDown() then
			m_TurboMode = true;
			Controls.SlideAnim:SetSpeed(0.05);
		end

		-- "R"everse (fast)... more debugging.
		if key == Keys.R and pInputStruct:IsShiftDown() and pInputStruct:IsAltDown() then
			Controls.SlideAnim:SetSpeed( -0.004 );
		end
	end
	
	if uiMsg == KeyEvents.KeyUp then
		local key:number = pInputStruct:GetKey();
        if( key == Keys.VK_RETURN or key == Keys.VK_ESCAPE ) then
			OnClose();
        end

		-- Allow for pausing via spacebar
		if key == Keys.VK_SPACE then
			if Controls.SlideAnim:IsStopped() then
				Controls.SlideAnim:Play();
			else
 				Controls.SlideAnim:Stop();
			end
		end

		if key == Keys.T then
            if m_TurboMode then
                Controls.SlideAnim:SetSpeed(0.0015);
                m_TurboMode = false;
            end
		end

    end
    return true;
end


-- ===========================================================================
--	Game Engine Event
-- ===========================================================================
function OnUpdateUI( type:number, tag:string, iData1:number, iData2:number, strData1:string)
	if type == SystemUpdateUI.ScreenResize then
		Resize();
	end
end


-- ===========================================================================
-- ===========================================================================
function OnShow()

	CreditsData = DB.ConfigurationQuery("SELECT * FROM Credits ORDER BY SortOrder ASC");
	if(CreditsData and #CreditsData > 0) then
		local choice = Controls.CreditsChoice;
		if(#CreditsData == 1) then
			choice:SetHide(true);
		else
			choice:ClearEntries();
			for i,v in ipairs(CreditsData) do
				local entry = {};
				choice:BuildEntry( "InstanceOne", entry );
				entry.Button:SetText(Locale.Lookup(v.DisplayName));
				entry.Button:RegisterCallback(Mouse.eLClick, function()	
					DisplayCredits(i);
				end);
			end
			choice:CalculateInternals();
			choice:SetHide(false);
		end

		DisplayCredits(1);
	end

    m_TurboMode = false;
end

-- ===========================================================================
function Resize()
	Controls.BackButton:ReprocessAnchoring();	
	Controls.InitialSpace:ReprocessAnchoring();
	Controls.CreditsList:CalculateSize();
	Controls.MajorScroll:CalculateSize();
	ContextPtr:ReprocessAnchoring();
end

-- ===========================================================================
function DisplayCredits(creditsIndex)
	CreditsIndex = creditsIndex;
	local credits = CreditsData[CreditsIndex];

	-- Update the drop-down to reflect the current selection.
	local button = Controls.CreditsChoice:GetButton();
	button:LocalizeAndSetText(credits.DisplayName);

	removeEntries();
	if(credits) then
		removeEntries();
		local initialSpaceSize1 = -Controls.InitialSpace:GetSizeY();
		Controls.SlideAnim:SetRelativeEndVal(0, 0);
   		Controls.SlideAnim:SetToBeginning();
		Controls.CreditsList:CalculateSize();		
		Controls.MajorScroll:CalculateInternalSize();

		generateCredits(credits.Credits);
			
		Controls.CreditsList:CalculateSize();		
		Controls.CreditsList:ReprocessAnchoring();		
		Controls.MajorScroll:CalculateInternalSize();

		Resize();

		local sizeY = -Controls.CreditsList:GetSizeY();
		Controls.SlideAnim:SetRelativeEndVal(0, sizeY );
   		Controls.SlideAnim:SetToBeginning();
   		Controls.SlideAnim:Play();

		local speed = math.abs(65/sizeY);
		Controls.SlideAnim:SetSpeed(speed);
	end
end

----------------------------------------------------------------        
---------------------------------------------------------------- 
function removeEntries()
	m_BlankIM:DestroyInstances();
	m_MajorTitleIM:DestroyInstances();
	m_MinorTitleIM:DestroyInstances();
	m_HeadingIM:DestroyInstances();
	m_ImageIM:DestroyInstances();
	m_EntryIM:DestroyInstances();
end
----------------------------------------------------------------        
---------------------------------------------------------------- 
function generateCredits(creditsKey)
	if Locale.HasTextKey(creditsKey) then
		local creditsFile:string  = Locale.Lookup(creditsKey);
		
		if creditsFile then		
			local creditsTable:table = makeTable(creditsFile);
			if creditsTable then
				generateEntries(creditsTable);
			end
		end
	end
end

----------------------------------------------------------------        
---------------------------------------------------------------- 
function generateEntries(creditsTable)
	--print each line out, with header information formatting string
	for key,currentLine in ipairs(creditsTable) do	

		local indexOpen		:number = 1;  --currentLine.find("\[");	
		if indexOpen ~= nil and indexOpen > 0 then
			local creditHeader	:string = string.upper( string.sub(currentLine, indexOpen+1, indexOpen+1) );
			local creditLine	:string = string.sub(currentLine, 4);

			if creditLine == "" then
				local blankInstance = m_BlankIM:GetInstance();
			elseif creditHeader == "1" then	
				local majorTitle = m_MajorTitleIM:GetInstance();
				majorTitle.Text:SetText( Locale.ToUpper(creditLine) );	-- Make upp for small caps action
			elseif creditHeader == "2" then	
				local minorTitle = m_MinorTitleIM:GetInstance();
				minorTitle.Text:SetText( Locale.ToUpper(creditLine) );	-- Make upp for small caps action
			elseif creditHeader == "3" then	
				local heading = m_HeadingIM:GetInstance();
				heading.Text:SetText(creditLine);
			elseif creditHeader == "I" then
				local entry = m_ImageIM:GetInstance();
				entry.Image:SetTexture(creditLine);
			else
				-- Default (formally "4")
				local entry = m_EntryIM:GetInstance();
				entry.Text:SetText(creditLine);
			end
		end
	end		
end
----------------------------------------------------------------        
---------------------------------------------------------------- 
function makeTable(creditsFile)
	
	local i = 0;
	local prev_i = 1;
	local t = {};
	while true do
		local nChars = 1;
		local crlf = string.find(creditsFile, "\r\n", i+1, true)
		if (crlf ~= nil) then
			-- handle CRLF line ending
			nChars = 2;
			i = crlf;
		else
			-- handle LF line ending
			i = string.find(creditsFile, "\n", i+1, true)
		end

		if i == nil then 
			local line :string = string.sub(creditsFile, prev_i);		
			table.insert(t, line);
			break;
		end

		local line :string = string.sub(creditsFile, prev_i, i - 1);		
		table.insert(t, line);
		prev_i = i + nChars;				-- past linefeed/newline 		
	end
	
	return t;
	
end


-- ===========================================================================
--	Initialize
-- ===========================================================================
function Initialize()

	ContextPtr:SetShowHandler( OnShow );	
	ContextPtr:SetInputHandler( OnInputHandler, true );

	Events.SystemUpdateUI.Add( OnUpdateUI );

	Controls.BackButton:RegisterCallback( Mouse.eLClick, OnClose );
	Controls.BackButton:RegisterCallback( Mouse.eMouseEnter, function() UI.PlaySound("Main_Menu_Mouse_Over"); end);

	Controls.SlideAnim:RegisterEndCallback( OnCreditScrollComplete );
	
end
--#Accessibility integration
include("caiUtils")
local mgr = ExposedMembers.CAI_UIManager

local CAI_PANEL_ID = "CAICredits_Panel"
local CAI_HOVER_SOUND = "Main_Menu_Mouse_Over"
local CAI_READING_LINE = 0.5
local CAI_LINE_WEIGHTS = {
	["1"] = 56,
	["2"] = 46,
	["3"] = 44,
	["4"] = 38,
	["I"] = 30,
	["BLANK"] = 40,
}

local m_caiPanel = nil
local m_caiDropdown = nil
local m_caiTree = nil
local m_caiTokens = {}
local m_caiNarration = {}
local m_caiNarrationIndex = 1
local m_caiLastProgress = 0
local m_caiPausedByTree = false
local m_caiClosing = false

local BASE_OnInputHandler = OnInputHandler

local function CAI_TrimCreditText(text)
	text = tostring(text or "")
	text = string.gsub(text, "\194\160", " ")
	-- ASCII whitespace only; %s is locale-sensitive and corrupts UTF-8 (0xA0).
	return (text:gsub("^[ \t\r\n]+", ""):gsub("[ \t\r\n]+$", ""))
end

local function CAI_IsFocusWithin(widget)
	local focused = mgr:GetFocusedWidget()
	while focused do
		if focused == widget then return true end
		focused = focused.Parent
	end
	return false
end

local function CAI_ParseCredits(credits)
	local tokens = {}
	if not credits or not Locale.HasTextKey(credits.Credits) then return tokens end

	local localized = Locale.Lookup(credits.Credits)
	for sourceIndex, rawLine in ipairs(makeTable(localized)) do
		local kind = "4"
		local text = rawLine
		if string.sub(rawLine, 1, 1) == "[" and string.sub(rawLine, 3, 3) == "]" then
			kind = string.upper(string.sub(rawLine, 2, 2))
			text = string.sub(rawLine, 4)
		end
		text = CAI_TrimCreditText(text)

		local weightKey = kind
		if text == "" then weightKey = "BLANK" end
		if not CAI_LINE_WEIGHTS[weightKey] then weightKey = "4" end
		tokens[#tokens + 1] = {
			Kind = kind,
			Text = text,
			SourceIndex = sourceIndex,
			Weight = CAI_LINE_WEIGHTS[weightKey],
			IsDecorative = kind == "I" or text == "",
		}
	end
	return tokens
end

local function CAI_SetNarrationCursor(progress)
	m_caiNarrationIndex = 1
	while m_caiNarrationIndex <= #m_caiNarration
		and m_caiNarration[m_caiNarrationIndex].Progress <= progress do
		m_caiNarrationIndex = m_caiNarrationIndex + 1
	end
	m_caiLastProgress = progress
end

local function CAI_PrepareNarration(credits, currentProgress)
	m_caiTokens = CAI_ParseCredits(credits)
	m_caiNarration = {}

	local totalWeight = 0
	for _, token in ipairs(m_caiTokens) do
		totalWeight = totalWeight + token.Weight
	end
	if totalWeight <= 0 then
		CAI_SetNarrationCursor(currentProgress or 0)
		return
	end

	local listHeight = math.abs(Controls.CreditsList:GetSizeY())
	local initialHeight = math.abs(Controls.InitialSpace:GetSizeY())
	local viewportHeight = math.abs(Controls.MajorScroll:GetSizeY())
	local contentHeight = math.max(1, listHeight - initialHeight)
	local readingY = viewportHeight * CAI_READING_LINE
	local accumulatedWeight = 0

	for _, token in ipairs(m_caiTokens) do
		local centerWeight = accumulatedWeight + (token.Weight * 0.5)
		if not token.IsDecorative then
			local contentY = (centerWeight / totalWeight) * contentHeight
			local progress = (initialHeight + contentY - readingY) / math.max(1, listHeight)
			m_caiNarration[#m_caiNarration + 1] = {
				Progress = math.max(0, math.min(1, progress)),
				Text = token.Text,
			}
		end
		accumulatedWeight = accumulatedWeight + token.Weight
	end

	CAI_SetNarrationCursor(currentProgress or 0)
end

local function CAI_OnSlideProgress(control, progress)
	if m_caiClosing or control:IsStopped()
		or not ContextPtr:IsVisible() or CAI_IsFocusWithin(m_caiTree) then
		return
	end

	if progress < m_caiLastProgress then
		CAI_SetNarrationCursor(progress)
	end

	while m_caiNarrationIndex <= #m_caiNarration
		and m_caiNarration[m_caiNarrationIndex].Progress <= progress do
		Speak(m_caiNarration[m_caiNarrationIndex].Text, false, false)
		m_caiNarrationIndex = m_caiNarrationIndex + 1
	end
	m_caiLastProgress = progress
end

local function CAI_AddStatic(parent, token)
	local capturedText = token.Text
	local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAICredits_Text_"), "StaticText", {
		Label = function() return capturedText end,
		FocusKey = "credits:" .. CreditsIndex .. ":line:" .. token.SourceIndex,
	})
	row:SetFocusSound(CAI_HOVER_SOUND)
	parent:AddChild(row)
end

local function CAI_RebuildTree()
	if not m_caiTree then return end
	local capture = mgr:CaptureFocusKey(m_caiTree)
	m_caiTree:ClearChildren()

	local currentSection = nil
	local index = 1
	while index <= #m_caiTokens do
		local token = m_caiTokens[index]
		if not token.IsDecorative then
			if token.Kind == "1" then
				currentSection = nil
				CAI_AddStatic(m_caiTree, token)
			elseif token.Kind == "2" then
				local capturedText = token.Text
				currentSection = mgr:CreateWidget(mgr:GenerateWidgetId("CAICredits_Section_"), "TreeItem", {
					Label = function() return capturedText end,
					FocusKey = "credits:" .. CreditsIndex .. ":line:" .. token.SourceIndex,
				})
				currentSection:SetFocusSound(CAI_HOVER_SOUND)
				m_caiTree:AddChild(currentSection)
			elseif token.Kind == "3" then
				local blockLines = { token.Text }
				local nextIndex = index + 1
				while nextIndex <= #m_caiTokens do
					local nextToken = m_caiTokens[nextIndex]
					if not nextToken.IsDecorative and nextToken.Kind ~= "4" then break end
					if not nextToken.IsDecorative then
						blockLines[#blockLines + 1] = nextToken.Text
					end
					nextIndex = nextIndex + 1
				end
				CAI_AddStatic(currentSection or m_caiTree, {
					Text = table.concat(blockLines, "[NEWLINE]"),
					SourceIndex = token.SourceIndex,
				})
				index = nextIndex - 1
			else
				local blockLines = { token.Text }
				local nextIndex = index + 1
				while nextIndex <= #m_caiTokens do
					local nextToken = m_caiTokens[nextIndex]
					if not nextToken.IsDecorative and nextToken.Kind ~= "4" then break end
					if not nextToken.IsDecorative then
						blockLines[#blockLines + 1] = nextToken.Text
					end
					nextIndex = nextIndex + 1
				end
				CAI_AddStatic(currentSection or m_caiTree, {
					Text = table.concat(blockLines, "[NEWLINE]"),
					SourceIndex = token.SourceIndex,
				})
				index = nextIndex - 1
			end
		end
		index = index + 1
	end

	mgr:RestoreFocus(m_caiTree, capture)
end

local function CAI_SyncSelection()
	if m_caiDropdown and CreditsData and #CreditsData > 0 then
		m_caiDropdown:SetSelectedIndex(CreditsIndex, true)
	end
	CAI_RebuildTree()
end

local function CAI_BuildPanel()
	if m_caiPanel then return end
	m_caiClosing = false

	m_caiPanel = mgr:CreateWidget(CAI_PANEL_ID, "Panel", {
		Label = function() return Locale.Lookup("LOC_MAIN_MENU_CREDITS") end,
	})

	m_caiDropdown = mgr:CreateWidget(mgr:GenerateWidgetId("CAICredits_Dropdown_"), "Dropdown", {
		Label = function() return Locale.Lookup("LOC_CAI_CREDITS_PACKAGE") end,
		FocusKey = "credits:package",
	})
	m_caiDropdown:SetFocusSound(CAI_HOVER_SOUND)
	local options = {}
	for index, credits in ipairs(CreditsData or {}) do
		options[#options + 1] = {
			label = Locale.Lookup(credits.DisplayName),
			value = index,
		}
	end
	m_caiDropdown:SetOptions(options)
	if #options > 0 then m_caiDropdown:SetSelectedIndex(CreditsIndex, true) end
	m_caiDropdown:On("value_changed", function(_, index)
		DisplayCredits(index)
	end)
	m_caiPanel:AddChild(m_caiDropdown)

	m_caiTree = mgr:CreateWidget(mgr:GenerateWidgetId("CAICredits_Tree_"), "Tree", {
		Label = function()
			local credits = CreditsData and CreditsData[CreditsIndex]
			return credits and Locale.Lookup(credits.DisplayName) or ""
		end,
		FocusKey = "credits:tree",
	})
	m_caiTree:SetFocusSound(CAI_HOVER_SOUND)
	m_caiTree:On("focus_enter", function()
		if not Controls.SlideAnim:IsStopped() then
			m_caiPausedByTree = true
			Controls.SlideAnim:Stop()
		end
		if CAI and CAI.Silence then CAI.Silence() end
	end)
	m_caiTree:On("focus_leave", function()
		if not m_caiClosing and not CAI_IsFocusWithin(m_caiTree) and m_caiPausedByTree then
			m_caiPausedByTree = false
			Controls.SlideAnim:Play()
		end
	end)
	m_caiPanel:AddChild(m_caiTree)

	CAI_RebuildTree()
end

local function CAI_PushPanel()
	CAI_BuildPanel()
	if m_caiPanel and not mgr:GetWidgetById(CAI_PANEL_ID) then
		mgr:Push(m_caiPanel, { priority = PopupPriority.Current, focus = m_caiDropdown })
	end
end

local function CAI_DestroyPanel()
	m_caiClosing = true
	m_caiPausedByTree = false
	if m_caiPanel then mgr:RemoveFromStack(CAI_PANEL_ID) end
	m_caiPanel = nil
	m_caiDropdown = nil
	m_caiTree = nil
end

DisplayCredits = WrapFunc(DisplayCredits, function(orig, creditsIndex)
	if CAI and CAI.Silence then CAI.Silence() end
	orig(creditsIndex)
	CAI_PrepareNarration(CreditsData and CreditsData[CreditsIndex], 0)
	CAI_SyncSelection()
end)

Resize = WrapFunc(Resize, function(orig)
	orig()
	if CreditsData and CreditsData[CreditsIndex] then
		CAI_PrepareNarration(CreditsData[CreditsIndex], Controls.SlideAnim:GetProgress())
	end
end)

OnShow = WrapFunc(OnShow, function(orig)
	orig()
	CAI_PushPanel()
end)

OnClose = WrapFunc(OnClose, function(orig)
	CAI_DestroyPanel()
	orig()
end)

Initialize = WrapFunc(Initialize, function(orig)
	orig()
	Controls.SlideAnim:RegisterAnimCallback(CAI_OnSlideProgress)
	ContextPtr:SetInputHandler(function(input)
		if mgr:HandleInput(input) then return true end
		if input:GetMessageType() == KeyEvents.KeyUp
			and input:GetKey() == Keys.VK_RETURN then
			return true
		end
		if input:GetMessageType() == KeyEvents.KeyUp
			and input:GetKey() == Keys.VK_SPACE then
			if CAI_IsFocusWithin(m_caiTree) then return true end
			if Controls.SlideAnim:IsStopped() then
				Controls.SlideAnim:Play()
				UI.PlaySound("Play_UI_Click")
				Speak(Locale.Lookup("LOC_CAI_CREDITS_RESUMED"), true, false)
			else
				Controls.SlideAnim:Stop()
				if CAI and CAI.Silence then CAI.Silence() end
				UI.PlaySound("Play_UI_Click")
				Speak(Locale.Lookup("LOC_CAI_CREDITS_PAUSED"), true, false)
			end
			return true
		end
		return BASE_OnInputHandler(input)
	end, true)
	ContextPtr:SetShutdown(function()
		m_caiClosing = true
		Controls.SlideAnim:ClearAnimCallback()
		CAI_DestroyPanel()
	end)
end)
--#End of accessibility integration

Initialize();
