include("caiUtils")
include("CivilopediaScreen")

local mgr = ExposedMembers.CAI_UIManager

local m_state = {
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
    pushed = false,
    history = {
        pageIndex = 0,
        pages = {},
    },
}

local m_ui = {
    panel = nil,
    sectionsTree = nil,
    historyList = nil,
    articleTree = nil,
    pageNodes = {},
}

local MAX_HISTORY_CRUMBS = 10

local function PlayHover()
    UI.PlaySound("Main_Menu_Mouse_Over")
end

local function LookupOrEmpty(key)
    if not key or key == "" then return "" end
    return Locale.Lookup(key)
end

local function PageKey(sid, pid)
    return tostring(sid) .. "::" .. tostring(pid)
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
-- Sections / pages tree
-- ===========================================================================
local function FirstPageIdInGroup(sectionId, groupId)
    for _, page in ipairs(GetPages(sectionId) or {}) do
        if page.PageGroupId == groupId then
            return page.PageId
        end
    end
end

local function CreatePageNode(sectionId, pageId, label)
    local node = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaPage"),
        "TreeviewItem",
        {
            GetLabel = function() return label or "" end,
            OnFocusEnter = function()
                PlayHover()
                local curSid, curPid = GetCurrentPage()
                if curSid == sectionId and curPid == pageId then return end
                m_state.userSwitchedFocus = true
                NavigateTo(sectionId, pageId)
            end,
            OnClick = function(w)
                mgr:SetFocus(m_ui.articleTree)
            end
        })
    m_ui.pageNodes[PageKey(sectionId, pageId)] = node
    return node
end

local function CreateGroupNode(sectionId, group)
    local groupId = group.PageGroupId
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaGroup"),
        "TreeviewItem",
        {
            GetLabel = function() return LookupOrEmpty(group.TabName) end,
            OnFocusEnter = function(w, newPath, index)
                if not newPath or newPath[#newPath] ~= w then return end
                PlayHover()
                local firstPid = FirstPageIdInGroup(sectionId, groupId)
                if not firstPid then return end
                local curSid, curPid = GetCurrentPage()
                if curSid == sectionId and curPid == firstPid then return end
                m_state.userSwitchedFocus = true
                NavigateTo(sectionId, firstPid)
            end,
        })
end

local function CreateSectionNode(section)
    local sectionId = section.SectionId
    local pages = GetPages(sectionId) or {}
    local firstPid = pages[1] and pages[1].PageId or nil

    local node = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaSection"),
        "TreeviewItem",
        {
            GetLabel = function() return LookupOrEmpty(section.TabName or section.Name) end,
            OnFocusEnter = function(w, newPath, index)
                if not newPath or newPath[#newPath] ~= w then return end
                PlayHover()
                if not firstPid then return end
                local curSid, curPid = GetCurrentPage()
                if curSid == sectionId and curPid == firstPid then return end
                m_state.userSwitchedFocus = true
                NavigateTo(sectionId, firstPid)
            end,
        })

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
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId(idPrefix),
        "StaticText",
        {
            IsTreeviewItem = true,
            GetValue = function() return text end
        })
end

local function CreateRelatedButton(label, searchTerm)
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaLink"),
        "Button",
        {
            IsTreeviewItem = true,
            GetLabel = function() return label end,
            OnFocusEnter = PlayHover,
            OnClick = function()
                local results = CivilopediaSearch(searchTerm, 1)
                if results and #results > 0 then
                    NavigateTo(results[1].SectionId, results[1].PageId)
                end
                return true
            end,
        })
end

local function CreateChapterNode(chapter)
    local node = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaChapter"),
        "TreeviewItem",
        {
            IsExpanded = true,
            GetLabel = function() return chapter.header ~= "" and chapter.header or "" end
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
    local node = mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaStatBox"),
        "TreeviewItem",
        {
            IsExpanded = true,
            GetLabel = function() return box.title end
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
    -- lines. Pass 2: link-bearing groups as expandable sub-TreeviewItems.
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
            local sub = mgr:CreateUIWidget(
                mgr:GenerateWidgetId("CAIPediaStatGroup"),
                "TreeviewItem",
                {
                    IsExpanded = true,
                    GetLabel = function() return g.header end
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
        local quotesNode = mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAIPediaQuotes"),
            "TreeviewItem",
            {
                IsExpanded = true,
                GetLabel = function() return Locale.Lookup("LOC_CAI_PEDIA_QUOTES") end
            })
        for _, quote in ipairs(m_state.quotes) do
            local text = quote.text
            if text and text ~= "" then
                if quote.audio and quote.audio ~= "" then
                    local audioId = quote.audio
                    quotesNode:AddChild(mgr:CreateUIWidget(
                        mgr:GenerateWidgetId("CAIPediaQuote"),
                        "Button",
                        {
                            IsTreeviewItem = true,
                            GetLabel = function() return text end,
                            OnFocusEnter = PlayHover,
                            OnClick = function()
                                UI.PlaySound(audioId)
                                return true
                            end,
                        }))
                else
                    quotesNode:AddChild(CreateStaticText("CAIPediaQuote", text))
                end
            end
        end
        m_ui.articleTree:AddChild(quotesNode)
    end

    if #m_state.relatedLinks > 0 then
        local relatedNode = mgr:CreateUIWidget(
            mgr:GenerateWidgetId("CAIPediaRelated"),
            "TreeviewItem",
            {
                IsExpanded = true,
                GetLabel = function() return Locale.Lookup("LOC_CAI_PEDIA_RELATED") end
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

    if m_ui.articleTree.Children and #m_ui.articleTree.Children > 0 then
        m_ui.articleTree:SetFocusedChild(1)
        if not m_state.userSwitchedFocus and not m_state.isOpeningOnHistoryPage then
            m_ui.panel:SetFocusedChild(2)
            mgr:SetFocus(m_ui.articleTree)
        end
    end
    m_state.isOpeningOnHistoryPage = false
end

-- ===========================================================================
-- History / crumbs
-- ===========================================================================
local function GetPageTitle(sectionId, pageId)
    local page = GetPage(sectionId, pageId)
    if not page then return "" end
    return LookupOrEmpty(page.Title or page.TabName)
end

local function CreateHistoryButton(entry)
    return mgr:CreateUIWidget(
        mgr:GenerateWidgetId("CAIPediaHistoryButton"),
        "Button",
        {
            GetLabel = function() return entry.title end,
            GetValue = function(w)
                if entry.index == m_state.history.pageIndex then
                    return Locale.Lookup("LOC_CAI_STATE_SELECTED")
                end
            end,
            OnFocusEnter = PlayHover,
            OnClick = function()
                NavigateToPageTrailIndex(entry.index, false)
                return true
            end,
        })
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

    if m_ui.historyList.Children and #m_ui.historyList.Children > 0 then
        local focusIndex = m_state.history.pageIndex
        m_ui.historyList:SetFocusedChild(focusIndex)
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
local function SyncFocusToCurrentPage()
    local sid, pid = GetCurrentPage()
    if not sid or not pid then return end
    local node = m_ui.pageNodes[PageKey(sid, pid)]
    if not node then return end
    local path = mgr:BuildFocusIndexPath(m_ui.sectionsTree, node)
    if path and #path > 0 then
        mgr:SetFocusIndexPath(m_ui.sectionsTree, path)
    end
end

-- ===========================================================================
-- Root panel
-- ===========================================================================
local function EnsureRootBuilt()
    if m_ui.panel then return end

    m_ui.panel = mgr:CreateUIWidget("CAIPediaPanel", "Panel", {
        GetLabel = function() return Controls.WindowTitle:GetText() end,
    })
    m_ui.panel:AddInputBindings({
        {
            Key = Keys.VK_LEFT,
            MSG = KeyEvents.KeyDown,
            IsAlt = true,
            Action = function()
                OnNavBackward(); return true
            end,
        },
        {
            Key = Keys.VK_RIGHT,
            MSG = KeyEvents.KeyDown,
            IsAlt = true,
            Action = function()
                OnNavForward(); return true
            end,
        },
    })

    m_ui.sectionsTree = mgr:CreateUIWidget("CAIPediaSectionsTree", "Treeview", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PEDIA_SECTIONS") end,
    })

    m_ui.historyList = mgr:CreateUIWidget("CAIPediaHistoryList", "List", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_PEDIA_HISTORY") end,
        IsHidden = function(w) return not w.Children or #w.Children < 2 end,
    })

    m_ui.articleTree = mgr:CreateUIWidget("CAIPediaArticleTree", "Treeview", {
        GetLabel = function()
            local sid, pid = GetCurrentPage()
            for _, p in ipairs(GetPages(sid) or {}) do
                if p.PageId == pid then
                    return LookupOrEmpty(p.Title or p.TabName)
                end
            end
            return Locale.Lookup("LOC_CAI_PEDIA_ARTICLE")
        end,
        IsHidden = function(w) return not w.Children or #w.Children == 0 end,
    })

    m_ui.panel:AddChild(m_ui.sectionsTree)
    m_ui.panel:AddChild(m_ui.articleTree)
    m_ui.panel:AddChild(m_ui.historyList)

    BuildSectionsTree()
    RefreshHistoryList()
end

local function PushPanel()
    if not mgr:HasWidget(m_ui.panel) then
        mgr:Push(m_ui.panel)
    end
    m_state.pushed = true
end

local function PopPanel()
    if m_ui.panel and mgr:HasWidget(m_ui.panel) then
        mgr:RemoveFromStack(m_ui.panel:GetId())
    end
    m_state.pushed = false
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
    if not m_state.userSwitchedFocus then
        SyncFocusToCurrentPage()
    end
    m_state.userSwitchedFocus = false
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
    SyncFocusToCurrentPage()
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
    if m_state.pushed and mgr and mgr:HandleInput(input) then
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
end)

LuaEvents.OpenCivilopedia.Remove(_origOnOpenCivilopedia)
LuaEvents.OpenCivilopedia.Add(OnOpenCivilopedia)

OnClose = WrapFunc(OnClose, function(orig)
    PopPanel()
    orig()
end)

Controls.WindowCloseButton:RegisterCallback(Mouse.eLClick, OnClose)
