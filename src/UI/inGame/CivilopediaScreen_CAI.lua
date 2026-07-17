include("caiUtils")
include("CivilopediaScreen")

local mgr         = ExposedMembers.CAI_UIManager

local PANEL_ID    = "CAIPediaPanel"
local HOVER_SOUND = "Main_Menu_Mouse_Over"
local BODY_SEARCH_CONTEXT = "CAI_CivilopediaBody"
local BODY_PREVIEW_RADIUS = 180
local m_bodySearchText = {}


local m_state            = {
    userSwitchedFocus = false,
    isOpeningOnHistoryPage = false,
    pageHeader = "",
    pageSubHeader = "",
    chapters = {},
    currentChapter = nil,
    statBoxes = {},
    quotes = {},
    relatedLinks = {},
    suppressLinkCapture = false,
    history = {
        pageIndex = 0,
        pages = {},
    },
}

local m_ui               = {
    panel = nil,
    sectionsTree = nil,
    historyList = nil,
    articleTree = nil,
    pageNodes = {},
}

local MAX_HISTORY_CRUMBS = 10

local function LookupOrEmpty(key)
    if not key or key == "" then return "" end
    return Locale.Lookup(key)
end

local function PageKey(sid, pid)
    return tostring(sid) .. "::" .. tostring(pid)
end

-- ===========================================================================
-- Article title + body search index
-- ===========================================================================
-- CacheData() has already populated every page and page-layout mapping by the
-- time include("CivilopediaScreen") returns.  The page bodies themselves are
-- emitted only when a PageLayouts renderer runs, so execute each renderer with
-- its visual output helpers temporarily replaced by capture/no-op functions.
-- This builds the complete context during UI initialization rather than on the
-- first Ctrl+F search.
local function PopulateBodySearchData()
    Search.DestroyContext(BODY_SEARCH_CONTEXT)
    m_bodySearchText = {}
    if not Search.CreateContext(BODY_SEARCH_CONTEXT, "", "", "...") then
        LogWarn("Civilopedia body search failed to create context")
        return false
    end

    local body = nil
    local originals = {
        ShowFrontPageHeader = ShowFrontPageHeader,
        SetPageHeader = SetPageHeader,
        SetPageSubHeader = SetPageSubHeader,
        AddChapter = AddChapter,
        AddFullWidthChapter = AddFullWidthChapter,
        AddLeftColumnChapter = AddLeftColumnChapter,
        AddHeader = AddHeader,
        AddFullWidthHeader = AddFullWidthHeader,
        AddLeftColumnHeader = AddLeftColumnHeader,
        AddParagraph = AddParagraph,
        AddFullWidthParagraph = AddFullWidthParagraph,
        AddLeftColumnParagraph = AddLeftColumnParagraph,
        AddParagraphs = AddParagraphs,
        AddFullWidthParagraphs = AddFullWidthParagraphs,
        AddLeftColumnParagraphs = AddLeftColumnParagraphs,
        AddHeaderBody = AddHeaderBody,
        AddFullWidthHeaderBody = AddFullWidthHeaderBody,
        AddLeftColumnHeaderBody = AddLeftColumnHeaderBody,
        AddIconHeaderBody = AddIconHeaderBody,
        AddFullWidthIconHeaderBody = AddFullWidthIconHeaderBody,
        AddLeftColumnIconHeaderBody = AddLeftColumnIconHeaderBody,
        AddImage = AddImage,
        AddPortrait = AddPortrait,
        AddTallImage = AddTallImage,
        AddTallImageNoScale = AddTallImageNoScale,
        AddTallPortrait = AddTallPortrait,
        AddQuote = AddQuote,
        AddRightColumnStatBox = AddRightColumnStatBox,
    }

    local function append(value)
        if type(value) == "table" then
            for _, item in ipairs(value) do append(item) end
            return
        end
        if type(value) ~= "string" or value == "" then return end
        local text = Locale.StripTags(LookupOrEmpty(value))
        if text and text ~= "" then body[#body + 1] = text end
    end

    local function noOp() end
    local function captureChapter(_, paragraphs) append(paragraphs) end
    local function captureParagraph(paragraph) append(paragraph) end
    local function captureHeaderBody(_, paragraph) append(paragraph) end
    local function captureIconHeaderBody(_, _, paragraph) append(paragraph) end
    local function captureStatBox(_, populate)
        if not populate then return end
        local statBox = {}
        function statBox:AddSeparator() end
        function statBox:AddHeader() end
        function statBox:AddLabel(caption) append(caption) end
        function statBox:AddSmallLabel(caption) append(caption) end
        function statBox:AddIconLabel(_, caption) append(caption) end
        function statBox:AddIconNumberLabel(_, value, caption)
            append(caption)
            if value ~= nil then append(tostring(value)) end
        end
        function statBox:AddIconList(...)
            for i = 1, select("#", ...) do
                local icon = select(i, ...)
                if type(icon) == "table" then append(icon[2]) end
            end
        end
        populate(statBox)
    end

    ShowFrontPageHeader = noOp
    SetPageHeader = noOp
    SetPageSubHeader = noOp
    AddChapter = captureChapter
    AddFullWidthChapter = captureChapter
    AddLeftColumnChapter = captureChapter
    AddHeader = noOp
    AddFullWidthHeader = noOp
    AddLeftColumnHeader = noOp
    AddParagraph = captureParagraph
    AddFullWidthParagraph = captureParagraph
    AddLeftColumnParagraph = captureParagraph
    AddParagraphs = captureParagraph
    AddFullWidthParagraphs = captureParagraph
    AddLeftColumnParagraphs = captureParagraph
    AddHeaderBody = captureHeaderBody
    AddFullWidthHeaderBody = captureHeaderBody
    AddLeftColumnHeaderBody = captureHeaderBody
    AddIconHeaderBody = captureIconHeaderBody
    AddFullWidthIconHeaderBody = captureIconHeaderBody
    AddLeftColumnIconHeaderBody = captureIconHeaderBody
    AddImage = noOp
    AddPortrait = noOp
    AddTallImage = noOp
    AddTallImageNoScale = noOp
    AddTallPortrait = noOp
    AddQuote = captureParagraph
    AddRightColumnStatBox = captureStatBox

    local indexed = 0
    local failed = 0
    local buildOk, buildErr = pcall(function()
        for _, section in ipairs(GetSections() or {}) do
            for _, page in ipairs(GetPages(section.SectionId) or {}) do
                body = {}
                local template = _PageLayoutScriptTemplates[page.PageLayoutId]
                local view = template and PageLayouts[template] or nil
                local ok, err = false, "missing page layout"
                if view then ok, err = pcall(view, page) end

                if not ok then
                    failed = failed + 1
                    LogWarn("Civilopedia body search layout failed for "
                        .. tostring(page.SectionId) .. "|" .. tostring(page.PageId)
                        .. ": " .. tostring(err))
                end

                -- A failed/custom layout can still expose its standard
                -- configured chapter paragraphs through the support cache.
                if not ok or #body == 0 then
                    for _, chapter in ipairs(GetPageChapters(page.PageLayoutId) or {}) do
                        append(GetChapterBody(page.SectionId, page.PageId, chapter.ChapterId))
                    end
                end

                local key = page.SectionId .. "|" .. page.PageId
                local title = Locale.StripTags(LookupOrEmpty(page.Title or page.TabName))
                local bodyText = table.concat(body, " ")
                Search.AddData(
                    BODY_SEARCH_CONTEXT,
                    key,
                    title,
                    bodyText,
                    {})
                m_bodySearchText[key] = bodyText
                indexed = indexed + 1
            end
        end
    end)

    ShowFrontPageHeader = originals.ShowFrontPageHeader
    SetPageHeader = originals.SetPageHeader
    SetPageSubHeader = originals.SetPageSubHeader
    AddChapter = originals.AddChapter
    AddFullWidthChapter = originals.AddFullWidthChapter
    AddLeftColumnChapter = originals.AddLeftColumnChapter
    AddHeader = originals.AddHeader
    AddFullWidthHeader = originals.AddFullWidthHeader
    AddLeftColumnHeader = originals.AddLeftColumnHeader
    AddParagraph = originals.AddParagraph
    AddFullWidthParagraph = originals.AddFullWidthParagraph
    AddLeftColumnParagraph = originals.AddLeftColumnParagraph
    AddParagraphs = originals.AddParagraphs
    AddFullWidthParagraphs = originals.AddFullWidthParagraphs
    AddLeftColumnParagraphs = originals.AddLeftColumnParagraphs
    AddHeaderBody = originals.AddHeaderBody
    AddFullWidthHeaderBody = originals.AddFullWidthHeaderBody
    AddLeftColumnHeaderBody = originals.AddLeftColumnHeaderBody
    AddIconHeaderBody = originals.AddIconHeaderBody
    AddFullWidthIconHeaderBody = originals.AddFullWidthIconHeaderBody
    AddLeftColumnIconHeaderBody = originals.AddLeftColumnIconHeaderBody
    AddImage = originals.AddImage
    AddPortrait = originals.AddPortrait
    AddTallImage = originals.AddTallImage
    AddTallImageNoScale = originals.AddTallImageNoScale
    AddTallPortrait = originals.AddTallPortrait
    AddQuote = originals.AddQuote
    AddRightColumnStatBox = originals.AddRightColumnStatBox
    if not buildOk then
        Search.DestroyContext(BODY_SEARCH_CONTEXT)
        LogWarn("Civilopedia body search build failed: " .. tostring(buildErr))
        return false
    end
    Search.Optimize(BODY_SEARCH_CONTEXT)
    LogMessage("Civilopedia body search indexed " .. tostring(indexed)
        .. " pages; layout failures=" .. tostring(failed))
    return true
end

local function BuildBodySearchPreview(key, query, enginePreview)
    local text = m_bodySearchText[key]
    if not text or text == "" or not query or query == "" then return enginePreview end

    local matchStart, matchEnd = string.find(string.lower(text), string.lower(query), 1, true)
    if not matchStart then return enginePreview end

    local previewStart = math.max(1, matchStart - BODY_PREVIEW_RADIUS)
    if previewStart > 1 then
        local nextSpace = string.find(text, " ", previewStart, true)
        if nextSpace and nextSpace < matchStart then previewStart = nextSpace + 1 end
    end

    local previewEnd = math.min(#text, matchEnd + BODY_PREVIEW_RADIUS)
    if previewEnd < #text then
        local nextSpace = string.find(text, " ", previewEnd, true)
        if nextSpace then previewEnd = nextSpace - 1 end
    end

    local preview = string.sub(text, previewStart, previewEnd)
    if previewStart > 1 then preview = "... " .. preview end
    if previewEnd < #text then preview = preview .. " ..." end
    return preview
end

-- ===========================================================================
-- Capture helpers
-- ===========================================================================
local function StartChapter(headerKey)
    local chapter = { header = LookupOrEmpty(headerKey), paragraphs = {} }
    table.insert(m_state.chapters, chapter)
    m_state.currentChapter = chapter
    return chapter
end

local function EnsureChapter()
    if not m_state.currentChapter then
        local chapter = { header = "", paragraphs = {} }
        table.insert(m_state.chapters, chapter)
        m_state.currentChapter = chapter
    end
    return m_state.currentChapter
end

local function AppendParagraph(paragraphKey)
    local text = LookupOrEmpty(paragraphKey)
    if text == "" then return end
    local chapter = EnsureChapter()
    table.insert(chapter.paragraphs, text)
end

local function AppendParagraphs(paragraphs)
    local t = type(paragraphs)
    if t == "table" then
        for _, para in ipairs(paragraphs) do AppendParagraph(para) end
    elseif t == "string" then
        AppendParagraph(paragraphs)
    end
end

-- AddHeaderBody / AddIconHeaderBody pair a name with its description.
-- Vanilla pages emit these after an AddHeader (e.g. Civilization unique
-- ability), so we merge "Name: Description" into a single paragraph on the
-- currently open chapter rather than opening a new sibling chapter.
local function AppendHeaderBody(headerKey, bodyKey)
    local name = LookupOrEmpty(headerKey)
    local desc = LookupOrEmpty(bodyKey)
    local line
    if name ~= "" and desc ~= "" then
        line = name .. ": " .. desc
    elseif name ~= "" then
        line = name
    elseif desc ~= "" then
        line = desc
    else
        return
    end
    local chapter = EnsureChapter()
    table.insert(chapter.paragraphs, line)
end

-- ===========================================================================
-- Page title lookup + navigation feedback
-- ===========================================================================
local function GetPageTitle(sectionId, pageId)
    local page = GetPage(sectionId, pageId)
    if not page then return "" end
    return LookupOrEmpty(page.Title or page.TabName)
end

-- ===========================================================================
-- Sections / pages tree
-- ===========================================================================
local function FirstPageIdInGroup(sectionId, groupId)
    for _, page in ipairs(GetPages(sectionId) or {}) do
        if page.PageGroupId == groupId then
            return page.PageId
        end
    end
end

-- Navigate to a page because the user landed on its sections-tree node. This
-- marks the navigation as user-driven so the article rebuild leaves focus on
-- the node (the user is browsing the sections list), instead of jumping into
-- the article.
local function NavigateFromSectionFocus(sectionId, pageId)
    local curSid, curPid = GetCurrentPage()
    if curSid == sectionId and curPid == pageId then return end
    m_state.userSwitchedFocus = true
    NavigateTo(sectionId, pageId)
end

local function CreatePageNode(sectionId, pageId, label)
    local node = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaPage"),
        "TreeItem",
        {
            Label = function() return label or "" end,
        })
    node:SetFocusSound(HOVER_SOUND)
    node:On("focus_enter", function(w)
        if not w:IsFocused() then return end
        NavigateFromSectionFocus(sectionId, pageId)
    end)
    node:On("activate", function()
        if m_ui.articleTree and m_ui.articleTree.Children and #m_ui.articleTree.Children > 0 then
            mgr:SetFocus(m_ui.articleTree)
        end
    end)
    m_ui.pageNodes[PageKey(sectionId, pageId)] = node
    return node
end

local function CreateGroupNode(sectionId, group)
    local groupId = group.PageGroupId
    local node = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaGroup"),
        "TreeItem",
        {
            Label = function() return LookupOrEmpty(group.TabName) end,
        })
    node:SetFocusSound(HOVER_SOUND)
    node:On("focus_enter", function(w)
        if not w:IsFocused() then return end
        local firstPid = FirstPageIdInGroup(sectionId, groupId)
        if not firstPid then return end
        NavigateFromSectionFocus(sectionId, firstPid)
    end)
    return node
end

local function CreateSectionNode(section)
    local sectionId = section.SectionId
    local pages = GetPages(sectionId) or {}
    local firstPid = pages[1] and pages[1].PageId or nil

    local node = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaSection"),
        "TreeItem",
        {
            Label = function() return LookupOrEmpty(section.TabName or section.Name) end,
        })
    node:SetFocusSound(HOVER_SOUND)
    node:On("focus_enter", function(w)
        if not w:IsFocused() then return end
        if not firstPid then return end
        NavigateFromSectionFocus(sectionId, firstPid)
    end)

    local groupNodes = {}
    for _, page in ipairs(pages) do
        local groupId = page.PageGroupId
        local parentNode = node
        if groupId then
            if not groupNodes[groupId] then
                local group = GetPageGroup(sectionId, groupId)
                if group then
                    local gNode = CreateGroupNode(sectionId, group)
                    groupNodes[groupId] = gNode
                    node:AddChild(gNode)
                end
            end
            parentNode = groupNodes[groupId] or node
        end
        local pageLabel = LookupOrEmpty(page.Title or page.TabName)
        parentNode:AddChild(CreatePageNode(sectionId, page.PageId, pageLabel))
    end

    return node
end

local function BuildSectionsTree()
    m_ui.pageNodes = {}
    m_ui.sectionsTree:ClearChildren()
    for _, section in ipairs(GetSections() or {}) do
        m_ui.sectionsTree:AddChild(CreateSectionNode(section))
    end
end

-- ===========================================================================
-- Article tree
-- ===========================================================================
local function CreateStaticText(idPrefix, text)
    return mgr:CreateWidget(
        mgr:GenerateWidgetId(idPrefix),
        "StaticText",
        {
            Label = text,
        })
end

local function CreateRelatedButton(label, searchTerm)
    local btn = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaLink"),
        "Button",
        {
            Label = label,
        })
    btn:SetFocusSound(HOVER_SOUND)
    btn:On("activate", function()
        local results = CivilopediaSearch(searchTerm, 1)
        if results and #results > 0 then
            NavigateTo(results[1].SectionId, results[1].PageId)
        end
    end)
    return btn
end

local function CreateChapterNode(chapter)
    local node = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaChapter"),
        "TreeItem",
        {
            Label = function() return chapter.header ~= "" and chapter.header or "" end,
        })
    for _, para in ipairs(chapter.paragraphs) do
        node:AddChild(CreateStaticText("CAIPediaPara", para))
    end
    return node
end

-- Some icon entries carry a search term that doesn't resolve to a pedia page
-- (e.g. spy mission UnitOperation types). Verify the search succeeds so we
-- don't render a button whose Enter does nothing.
local function ResolvesToPage(searchTerm)
    if not searchTerm or searchTerm == "" then return false end
    local results = CivilopediaSearch(searchTerm, 1)
    return results ~= nil and #results > 0
end

-- Convert one captured stat-box entry into 0..N value records.
-- AddSeparator / AddHeader are handled by the caller.
local function EntryToValues(entry)
    local method = entry.method
    local args = entry.args

    if method == "AddLabel" or method == "AddSmallLabel" then
        local text = LookupOrEmpty(args[1])
        if text == "" then return {} end
        return { { kind = "text", text = text } }
    end

    if method == "AddIconLabel" then
        local icon, caption = args[1], args[2]
        local text = LookupOrEmpty(caption)
        if text == "" then return {} end
        if type(icon) == "table" and ResolvesToPage(icon[3]) then
            return { { kind = "link", text = text, searchTerm = icon[3] } }
        end
        return { { kind = "text", text = text } }
    end

    if method == "AddIconNumberLabel" then
        local _, value, caption = args[1], args[2], args[3]
        local cap = LookupOrEmpty(caption)
        local text = cap
        if value ~= nil then
            text = (cap ~= "" and (cap .. ": ") or "") .. tostring(value)
        end
        if text == "" then return {} end
        return { { kind = "text", text = text } }
    end

    if method == "AddIconList" then
        local out = {}
        for i = 1, 4 do
            local icon = args[i]
            if type(icon) == "table" then
                local tooltip = LookupOrEmpty(icon[2])
                if tooltip ~= "" then
                    if ResolvesToPage(icon[3]) then
                        table.insert(out, { kind = "link", text = tooltip, searchTerm = icon[3] })
                    else
                        table.insert(out, { kind = "text", text = tooltip })
                    end
                end
            end
        end
        return out
    end

    return {}
end

local function AppendValueChild(parent, v)
    if v.kind == "link" then
        parent:AddChild(CreateRelatedButton(v.text, v.searchTerm))
    else
        parent:AddChild(CreateStaticText("CAIPediaStatLine", v.text))
    end
end

local function GroupHasLinks(values)
    for _, v in ipairs(values) do
        if v.kind == "link" then return true end
    end
    return false
end

local function CreateStatBoxNode(box)
    local node = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaStatBox"),
        "TreeItem",
        {
            Label = function() return box.title end,
        })

    -- Group entries by AddHeader. Entries before the first AddHeader land in
    -- an implicit (headerless) group and are added flat under the box node.
    local groups = {}
    local current = { header = nil, values = {} }
    table.insert(groups, current)

    local i = 1
    while i <= #box.entries do
        local entry = box.entries[i]
        local method = entry.method

        if method == "AddHeader" then
            current = { header = LookupOrEmpty(entry.args[1]), values = {} }
            table.insert(groups, current)
            i = i + 1
        elseif method == "AddSeparator" then
            -- Separators close the current group; subsequent values without
            -- an AddHeader belong to a fresh implicit (headerless) group.
            current = { header = nil, values = {} }
            table.insert(groups, current)
            i = i + 1
        elseif method == "AddIconLabel" then
            -- Vanilla pages emit AddIconLabel followed by trailing
            -- AddLabel/AddSmallLabel calls describing the row's specifics
            -- (e.g. spy missions: name, turns, probability, target). Merge
            -- them into a single value so they read as one line.
            local primary = EntryToValues(entry)
            local extras = {}
            local j = i + 1
            while j <= #box.entries do
                local m = box.entries[j].method
                if m == "AddLabel" or m == "AddSmallLabel" then
                    local extraText = LookupOrEmpty(box.entries[j].args[1])
                    if extraText ~= "" then
                        table.insert(extras, extraText)
                    end
                    j = j + 1
                else
                    break
                end
            end
            if #extras > 0 and primary[1] then
                primary[1].text = primary[1].text .. ". " .. table.concat(extras, ". ")
            end
            for _, v in ipairs(primary) do
                table.insert(current.values, v)
            end
            i = j
        else
            for _, v in ipairs(EntryToValues(entry)) do
                table.insert(current.values, v)
            end
            i = i + 1
        end
    end

    -- Two passes so flat text always renders above expandable sub-groups.
    -- Pass 1: implicit headerless group + merged "Header: v1, v2" single
    -- lines. Pass 2: link-bearing groups as expandable sub-TreeItems.
    for _, g in ipairs(groups) do
        if #g.values > 0 then
            if g.header == nil then
                for _, v in ipairs(g.values) do
                    AppendValueChild(node, v)
                end
            elseif not GroupHasLinks(g.values) then
                local parts = {}
                for _, v in ipairs(g.values) do
                    table.insert(parts, v.text)
                end
                local line = g.header .. ": " .. table.concat(parts, ", ")
                node:AddChild(CreateStaticText("CAIPediaStatLine", line))
            end
        elseif g.header and g.header ~= "" then
            node:AddChild(CreateStaticText("CAIPediaStatLine", g.header))
        end
    end

    for _, g in ipairs(groups) do
        if #g.values > 0 and g.header ~= nil and GroupHasLinks(g.values) then
            local sub = mgr:CreateWidget(
                mgr:GenerateWidgetId("CAIPediaStatGroup"),
                "TreeItem",
                {
                    Label = function() return g.header end,
                })
            for _, v in ipairs(g.values) do
                AppendValueChild(sub, v)
            end
            node:AddChild(sub)
        end
    end

    if not node.Children or #node.Children == 0 then
        return nil
    end

    return node
end

local function CreateQuoteButton(text, audioId)
    local btn = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaQuote"),
        "Button",
        {
            Label = text,
        })
    btn:SetFocusSound(HOVER_SOUND)
    btn:On("activate", function()
        UI.PlaySound(audioId)
    end)
    return btn
end

-- Article-body expandables (chapters, stat boxes, stat sub-groups, quotes,
-- related links, and any future nesting) all start expanded so the player can
-- read everything without expanding each node, while keeping the option to
-- collapse a chapter. Set the field directly (no Expand()) so nothing is
-- spoken at build time. The sections tree is intentionally left collapsed.
local function ExpandAllTreeItems(widget)
    if not widget.Children then return end
    for _, child in ipairs(widget.Children) do
        if child.IsTreeItem then child:Expand(true) end
        ExpandAllTreeItems(child)
    end
end

local function RebuildArticleTree()
    if not m_ui.articleTree then return end
    m_ui.articleTree:ClearChildren()

    if m_state.pageSubHeader ~= "" then
        m_ui.articleTree:AddChild(CreateStaticText("CAIPediaSubHeader", m_state.pageSubHeader))
    end

    for _, chapter in ipairs(m_state.chapters) do
        if chapter.header == "" then
            -- Headerless chapter (e.g. Simple page layout skips a chapter
            -- header that matches the page title): inline the paragraphs as
            -- top-level lines instead of nesting them under an unlabeled
            -- expandable that the screen reader would announce as just
            -- "Collapsed".
            for _, para in ipairs(chapter.paragraphs) do
                m_ui.articleTree:AddChild(CreateStaticText("CAIPediaPara", para))
            end
        elseif #chapter.paragraphs > 0 then
            m_ui.articleTree:AddChild(CreateChapterNode(chapter))
        else
            m_ui.articleTree:AddChild(CreateStaticText("CAIPediaChapterHeader", chapter.header))
        end
    end

    for _, box in ipairs(m_state.statBoxes) do
        if box.entries and #box.entries > 0 then
            local boxNode = CreateStatBoxNode(box)
            if boxNode then
                m_ui.articleTree:AddChild(boxNode)
            end
        end
    end

    if #m_state.quotes > 0 then
        local quotesNode = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIPediaQuotes"),
            "TreeItem",
            {
                Label = function() return Locale.Lookup("LOC_CAI_PEDIA_QUOTES") end,
            })
        for _, quote in ipairs(m_state.quotes) do
            local text = quote.text
            if text and text ~= "" then
                if quote.audio and quote.audio ~= "" then
                    quotesNode:AddChild(CreateQuoteButton(text, quote.audio))
                else
                    quotesNode:AddChild(CreateStaticText("CAIPediaQuote", text))
                end
            end
        end
        m_ui.articleTree:AddChild(quotesNode)
    end

    if #m_state.relatedLinks > 0 then
        local relatedNode = mgr:CreateWidget(
            mgr:GenerateWidgetId("CAIPediaRelated"),
            "TreeItem",
            {
                Label = function() return Locale.Lookup("LOC_CAI_PEDIA_RELATED") end,
            })
        for _, link in ipairs(m_state.relatedLinks) do
            if link.label and link.label ~= "" and link.searchTerm then
                relatedNode:AddChild(CreateRelatedButton(link.label, link.searchTerm))
            end
        end
        if relatedNode.Children and #relatedNode.Children > 0 then
            m_ui.articleTree:AddChild(relatedNode)
        end
    end

    ExpandAllTreeItems(m_ui.articleTree)
end

-- ===========================================================================
-- History / crumbs
-- ===========================================================================
local function CreateHistoryButton(entry)
    local btn = mgr:CreateWidget(
        mgr:GenerateWidgetId("CAIPediaHistoryButton"),
        "Button",
        {
            Label = function() return entry.title end,
            ValueGetter = function()
                if entry.index == m_state.history.pageIndex then
                    return Locale.Lookup("LOC_CAI_STATE_SELECTED")
                end
            end,
        })
    btn:SetFocusSound(HOVER_SOUND)
    btn:On("activate", function()
        NavigateToPageTrailIndex(entry.index, false)
    end)
    return btn
end

local function RefreshHistoryList()
    if not m_ui.historyList then return end

    m_ui.historyList:ClearChildren()

    for index, page in ipairs(m_state.history.pages) do
        local title = page.title
        if title and title ~= "" then
            local entry = {
                index = index,
                title = title,
            }
            m_ui.historyList:AddChild(CreateHistoryButton(entry))
        end
    end

    -- Pre-position the remembered child so Tabbing into the history list lands
    -- on the current crumb (the manager resolves DefaultIndex when entered).
    if m_ui.historyList.Children and #m_ui.historyList.Children > 0 then
        local focusIndex = m_state.history.pageIndex
        if focusIndex < 1 then focusIndex = 1 end
        if focusIndex > #m_ui.historyList.Children then focusIndex = #m_ui.historyList.Children end
        m_ui.historyList:SetDefaultIndex(focusIndex)
    end
end

local function MirrorHistoryNavigate(sectionId, pageId)
    local title = GetPageTitle(sectionId, pageId)
    if title == "" then return end

    local history = m_state.history
    if #history.pages == MAX_HISTORY_CRUMBS then
        table.remove(history.pages, 1)
    end

    table.insert(history.pages, {
        sectionId = sectionId,
        pageId = pageId,
        title = title,
    })
    history.pageIndex = #history.pages
end

local function MirrorHistoryJump(index)
    local history = m_state.history
    if index < 1 or index > #history.pages then return end
    history.pageIndex = index
end

-- ===========================================================================
-- Focus sync
-- ===========================================================================
-- Move actual focus onto the sections-tree node for the current page. Used
-- both as a programmatic landing spot and (silently) to keep the sections
-- tree's remembered position aligned when focus jumps into the article.
local function FocusCurrentPageNode(silent)
    local sid, pid = GetCurrentPage()
    if not sid or not pid then return false end
    local node = m_ui.pageNodes[PageKey(sid, pid)]
    if not node then return false end
    mgr:SetFocus(node, { announce = not silent })
    return true
end

local function ArticleHasContent()
    return m_ui.articleTree and m_ui.articleTree.Children and #m_ui.articleTree.Children > 0
end

-- Decide where focus lands after a navigation rebuild. User-driven navigation
-- (arrowing the sections tree) leaves focus on the node. Programmatic
-- navigation (related links, history, ref jumps) announces "Jumping to X",
-- syncs the sections-tree remembered position, then drops focus into the
-- freshly built article. Initial-open navigation defers entirely to PushPanel.
local function ApplyNavigationFocus()
    if not (m_ui.panel and mgr:GetTop() == m_ui.panel) then
        m_state.userSwitchedFocus = false
        return
    end

    if m_state.userSwitchedFocus then
        m_state.userSwitchedFocus = false
        return
    end

    local sid, pid = GetCurrentPage()
    local title = GetPageTitle(sid, pid)
    if title ~= "" then
        Speak(Locale.Lookup("LOC_CAI_PEDIA_JUMPING", title), true)
    end

    if ArticleHasContent() then
        FocusCurrentPageNode(true) -- silent: keep sections tree aligned
        mgr:SetFocus(m_ui.articleTree)
    else
        FocusCurrentPageNode(false)
    end
end

-- ===========================================================================
-- Root panel
-- ===========================================================================
local function EnsureRootBuilt()
    if m_ui.panel then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Controls.WindowTitle:GetText() end,
    })
    m_ui.panel:AddInputBindings({
        {
            Key = Keys.VK_LEFT,
            MSG = KeyEvents.KeyDown,
            IsAlt = true,
            Description = "LOC_CAI_KB_NAVIGATE_BACK",
            Action = function()
                OnNavBackward(); return true
            end,
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = KeyEvents.KeyDown,
            IsAlt = true,
            Description = "LOC_CAI_KB_NAVIGATE_FORWARD",
            Action = function()
                OnNavForward(); return true
            end,
        },
        -- We need to add an input binding to make sure that the civ pedia can close on the load screen. Otherwise, the load screen input handler will take priority
        {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                OnClose()
                return true
            end
        }
    })

    m_ui.sectionsTree = mgr:CreateWidget("CAIPediaSectionsTree", "Tree", {
        Label = function() return Locale.Lookup("LOC_CAI_PEDIA_SECTIONS") end,
    })

    m_ui.sectionsTree:SetSearchQueryHandler(function(query, maxResults)
        local results = {}
        local seen = {}

        local function addResult(sectionId, pageId, preview)
            local k = sectionId .. "|" .. pageId
            if seen[k] then return end
            seen[k] = true
            local page = GetPage(sectionId, pageId)
            if not page then return end
            local title = LookupOrEmpty(page.Title or page.TabName)
            if title == "" then return end
            local labelParts = { title }
            for _, section in ipairs(GetSections() or {}) do
                if section.SectionId == sectionId then
                    local sectionName = LookupOrEmpty(section.TabName or section.Name)
                    if sectionName ~= "" then labelParts[#labelParts + 1] = sectionName end
                    break
                end
            end
            if page.PageGroupId then
                local group = GetPageGroup(sectionId, page.PageGroupId)
                local groupName = group and LookupOrEmpty(group.TabName or group.Name) or ""
                if groupName ~= "" then labelParts[#labelParts + 1] = groupName end
            end
            results[#results + 1] = {
                key = k,
                label = table.concat(labelParts, ", "),
                searchTitle = Locale.StripTags(title),
                tooltip = preview and preview ~= "" and preview or nil,
                useFirstTooltip = true,
                onActivate = function() NavigateTo(sectionId, pageId) end,
            }
        end

        for _, section in ipairs(GetSections() or {}) do
            local sectionId = section.SectionId
            local pages = GetPages(sectionId) or {}
            if sectionId == query then
                if pages[1] then addResult(sectionId, pages[1].PageId) end
            else
                for _, page in ipairs(pages) do
                    if page.PageId == query then
                        addResult(sectionId, page.PageId)
                    end
                end
            end
            if #results >= maxResults then return results end
        end

        if Search.HasContext(BODY_SEARCH_CONTEXT) then
            local raw = Search.Search(BODY_SEARCH_CONTEXT, query, maxResults)
            if raw then
                for _, hit in ipairs(raw) do
                    local sectionId, pageId = string.match(hit[1], "([^|]+)|([^|]+)")
                    if sectionId and pageId then
                        addResult(sectionId, pageId,
                            BuildBodySearchPreview(hit[1], query, hit[3]))
                    end
                    if #results >= maxResults then return results end
                end
            end
        end

        return results
    end)
    m_ui.sectionsTree:SetSearchQueryMode("raw")

    m_ui.historyList = mgr:CreateWidget("CAIPediaHistoryList", "List", {
        Label = function() return Locale.Lookup("LOC_CAI_PEDIA_HISTORY") end,
        HiddenPredicate = function(w) return not w.Children or #w.Children < 2 end,
    })

    m_ui.articleTree = mgr:CreateWidget("CAIPediaArticleTree", "Tree", {
        Label = function()
            local sid, pid = GetCurrentPage()
            for _, p in ipairs(GetPages(sid) or {}) do
                if p.PageId == pid then
                    return LookupOrEmpty(p.Title or p.TabName)
                end
            end
            return Locale.Lookup("LOC_CAI_PEDIA_ARTICLE")
        end,
        HiddenPredicate = function(w) return not w.Children or #w.Children == 0 end,
    })

    m_ui.panel:AddChild(m_ui.sectionsTree)
    m_ui.panel:AddChild(m_ui.articleTree)
    m_ui.panel:AddChild(m_ui.historyList)

    BuildSectionsTree()
    RefreshHistoryList()
end

-- Resolve the widget initial focus should land on when the panel is pushed.
local function ResolveInitialFocus()
    if not m_state.isOpeningOnHistoryPage and ArticleHasContent() then
        return m_ui.articleTree
    end
    local sid, pid = GetCurrentPage()
    local node = sid and pid and m_ui.pageNodes[PageKey(sid, pid)] or nil
    return node or m_ui.sectionsTree
end

local function PushPanel()
    if mgr:GetTop() ~= m_ui.panel then
        mgr:Push(m_ui.panel,
            { priority = PopupPriority.Civilopedia, focus = ResolveInitialFocus() })
    end
    m_state.isOpeningOnHistoryPage = false
end

local function PopPanel()
    if m_ui.panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_ui.panel = nil
    m_ui.articleTree = nil
    m_ui.historyList = nil
    m_ui.sectionsTree = nil
    m_ui.pageNodes = {}
end

-- ===========================================================================
-- Wraps: chapters / paragraphs / quotes / icons / stat boxes
-- ===========================================================================
SetPageHeader = WrapFunc(SetPageHeader, function(orig, caption)
    orig(caption)
    m_state.pageHeader = LookupOrEmpty(caption)
end)

SetPageSubHeader = WrapFunc(SetPageSubHeader, function(orig, caption)
    orig(caption)
    m_state.pageSubHeader = LookupOrEmpty(caption)
end)

local function HasParagraphs(paragraphs)
    local t = type(paragraphs)
    if t == "table" then return #paragraphs > 0 end
    if t == "string" then return paragraphs ~= "" end
    return false
end

AddFullWidthChapter = WrapFunc(AddFullWidthChapter, function(orig, header, paragraphs)
    orig(header, paragraphs)
    if not HasParagraphs(paragraphs) then return end
    StartChapter(header)
    AppendParagraphs(paragraphs)
end)

AddFullWidthHeader = WrapFunc(AddFullWidthHeader, function(orig, caption)
    orig(caption)
    StartChapter(caption)
end)

AddFullWidthParagraph = WrapFunc(AddFullWidthParagraph, function(orig, paragraph)
    orig(paragraph)
    AppendParagraph(paragraph)
end)

AddFullWidthParagraphs = WrapFunc(AddFullWidthParagraphs, function(orig, paragraphs)
    orig(paragraphs)
    AppendParagraphs(paragraphs)
end)

AddLeftColumnChapter = WrapFunc(AddLeftColumnChapter, function(orig, header, paragraphs)
    orig(header, paragraphs)
    if not HasParagraphs(paragraphs) then return end
    StartChapter(header)
    AppendParagraphs(paragraphs)
end)

AddLeftColumnHeader = WrapFunc(AddLeftColumnHeader, function(orig, caption)
    orig(caption)
    StartChapter(caption)
end)

AddLeftColumnParagraph = WrapFunc(AddLeftColumnParagraph, function(orig, paragraph)
    orig(paragraph)
    AppendParagraph(paragraph)
end)

AddLeftColumnParagraphs = WrapFunc(AddLeftColumnParagraphs, function(orig, paragraphs)
    orig(paragraphs)
    AppendParagraphs(paragraphs)
end)

AddLeftColumnHeaderBody = WrapFunc(AddLeftColumnHeaderBody, function(orig, header, body)
    orig(header, body)
    AppendHeaderBody(header, body)
end)

AddLeftColumnIconHeaderBody = WrapFunc(AddLeftColumnIconHeaderBody, function(orig, icon, header, body)
    orig(icon, header, body)
    AppendHeaderBody(header, body)
end)

AddQuote = WrapFunc(AddQuote, function(orig, quote, audio)
    orig(quote, audio)
    local text = LookupOrEmpty(quote)
    if text ~= "" then
        table.insert(m_state.quotes, { text = text, audio = audio })
    end
end)

HookupIcon = WrapFunc(HookupIcon, function(orig, icon_data, icon_control, button_control)
    orig(icon_data, icon_control, button_control)
    if m_state.suppressLinkCapture then return end
    if type(icon_data) == "table" then
        local tooltip = icon_data[2]
        local searchTerm = icon_data[3]
        if tooltip and ResolvesToPage(searchTerm) then
            table.insert(m_state.relatedLinks, {
                label = LookupOrEmpty(tooltip),
                searchTerm = searchTerm,
            })
        end
    end
end)

local STAT_BOX_METHODS = {
    "AddSeparator", "AddHeader", "AddLabel", "AddSmallLabel",
    "AddIconLabel", "AddIconNumberLabel", "AddIconList",
}

local function ResetCapturedArticleState()
    m_state.pageHeader = ""
    m_state.pageSubHeader = ""
    m_state.chapters = {}
    m_state.currentChapter = nil
    m_state.statBoxes = {}
    m_state.quotes = {}
    m_state.relatedLinks = {}
    m_state.suppressLinkCapture = false
end

AddRightColumnStatBox = WrapFunc(AddRightColumnStatBox, function(orig, title, populate_method)
    local entries = {}
    local function wrapped_populate(stat_box)
        for _, name in ipairs(STAT_BOX_METHODS) do
            local original = stat_box[name]
            if type(original) == "function" then
                stat_box[name] = function(self, ...)
                    table.insert(entries, { method = name, args = { ... } })
                    return original(self, ...)
                end
            end
        end
        if populate_method then populate_method(stat_box) end
    end

    local prevSuppress = m_state.suppressLinkCapture
    m_state.suppressLinkCapture = true
    orig(title, wrapped_populate)
    m_state.suppressLinkCapture = prevSuppress

    if #entries > 0 then
        table.insert(m_state.statBoxes, {
            title = LookupOrEmpty(title),
            entries = entries,
        })
    end
end)

-- ===========================================================================
-- Navigation / lifecycle
-- ===========================================================================
NavigateTo = WrapFunc(NavigateTo, function(orig, sectionId, pageId)
    local prevSid, prevPid = GetCurrentPage()
    local pageChanged = sectionId ~= prevSid or pageId ~= prevPid
    if pageChanged then
        ResetCapturedArticleState()
    end
    orig(sectionId, pageId)
    if pageChanged then
        MirrorHistoryNavigate(sectionId, pageId)
    end
    RefreshHistoryList()
    RebuildArticleTree()
    ApplyNavigationFocus()
end)

NavigateToPageTrailIndex = WrapFunc(NavigateToPageTrailIndex, function(orig, index, bUpdateScroll)
    local prevSid, prevPid = GetCurrentPage()
    local entry = m_state.history.pages[index]
    local targetSid = entry and entry.sectionId or nil
    local targetPid = entry and entry.pageId or nil
    local pageChanged = targetSid ~= nil and targetPid ~= nil and (targetSid ~= prevSid or targetPid ~= prevPid)
    if pageChanged then
        ResetCapturedArticleState()
    end
    orig(index, bUpdateScroll)
    MirrorHistoryJump(index)
    RefreshHistoryList()
    RebuildArticleTree()
    ApplyNavigationFocus()
end)

OnNavBackward = WrapFunc(OnNavBackward, function(orig)
    if m_state.history.pageIndex > 1 then
        orig()
    else
        Speak(Locale.Lookup("LOC_CAI_PEDIA_HISTORY_START"))
    end
end)

OnNavForward = WrapFunc(OnNavForward, function(orig)
    if m_state.history.pageIndex < #m_state.history.pages then
        orig()
    else
        Speak(Locale.Lookup("LOC_CAI_PEDIA_HISTORY_END"))
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr and m_ui.panel and mgr:GetTop() == m_ui.panel and mgr:HandleInput(input) then
        return true
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

local _origOnOpenCivilopedia = OnOpenCivilopedia
OnOpenCivilopedia = WrapFunc(OnOpenCivilopedia, function(orig, sectionIdOrSearch, pageId)
    EnsureRootBuilt()
    m_state.isOpeningOnHistoryPage = sectionIdOrSearch == nil and pageId == nil and #m_state.history.pages > 0
    orig(sectionIdOrSearch, pageId)
    PushPanel()
    UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
end)

LuaEvents.OpenCivilopedia.Remove(_origOnOpenCivilopedia)
LuaEvents.OpenCivilopedia.Add(OnOpenCivilopedia)

OnClose = WrapFunc(OnClose, function(orig)
    PopPanel()
    orig()
    UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr)
end)

local m_caiOpenCivilopediaId = Input.GetActionId("UI_CAIOpenCivilopedia")
local m_vanillaOpenCivilopedia = Input.GetActionId("OpenCivilopedia")
Events.InputActionTriggered.Remove(OnInputActionTriggered)
OnInputActionStarted = WrapFunc(OnInputActionTriggered, function(orig, actionId)
    if m_caiOpenCivilopediaId and actionId == m_caiOpenCivilopediaId then
        orig(m_vanillaOpenCivilopedia)
        return
    end
end)


Events.InputActionStarted.Add(OnInputActionStarted)

Shutdown = WrapFunc(Shutdown, function(orig)
    Search.DestroyContext(BODY_SEARCH_CONTEXT)
    orig()
end)
ContextPtr:SetShutdown(Shutdown)

PopulateBodySearchData()


Controls.WindowCloseButton:RegisterCallback(Mouse.eLClick, OnClose)
