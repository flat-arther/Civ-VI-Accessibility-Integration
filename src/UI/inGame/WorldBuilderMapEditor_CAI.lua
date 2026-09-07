-- ===========================================================================
--  WorldBuilderMapEditor_CAI
--  Accessible replacement for the World Builder Map Editor modal.
--
--  Vanilla is a modal with (in Advanced mode) three tabs: General, Mod, Text.
--  The Mod tab is empty in vanilla (no controls in ViewMapModPage / ModInstance),
--  so it is not exposed here. Two tabs are presented:
--
--    * General - a Map metadata list (the ID as a button that generates a new
--        ID on activate, then read-only Width / Height), followed by the Is Mod
--        checkbox and edit boxes for Ruleset, Map Script, Reference Map, and
--        Reference Alpha.
--    * Text - the map/scenario localization editor: a language Dropdown, then a
--        List of key/string entries. Delete removes the focused entry (system
--        entries 1-4 cannot be removed, matching vanilla's disabled Remove).
--        Enter opens an editor Dialog (Tag + String) whose OK button commits.
--        The Add button below the list opens that same editor for a new entry.
--
--  Everything drives the real data path so vanilla behaviour (validation, the
--  status-line feedback spoken by WorldBuilderLaunchBar_CAI, the copy-system-
--  strings-into-a-new-language side effect) is preserved: WorldBuilder.* /
--  WorldBuilder.ModManager() / StrategicView_* and the base's own global
--  On*Edited handlers. This avoids reaching into the base's per-tab control
--  instances, which exist only while their tab is the one currently built.
-- ===========================================================================

include("caiUtils")
include("WorldBuilderMapEditor")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID   = "CAIWorldBuilderMapEditor_Panel"
local FOCUS_SOUND = "Main_Menu_Mouse_Over"

-- Entries 1-4 are the fixed system strings, shown by their specific annotation.
-- Entries 5+ are custom keys (vanilla disables Remove below index 5), shown by
-- their localization tag; they all share the generic "for mod creator's use
-- (optional)" annotation, which we surface as the Add button's tooltip instead.
local SYSTEM_ANNOTATIONS = {
    "LOC_WORLDBUILDER_MAPEDIT_MODTITLE",
    "LOC_WORLDBUILDER_MAPEDIT_MODDESC",
    "LOC_WORLDBUILDER_MAPEDIT_MAPTITLE",
    "LOC_WORLDBUILDER_MAPEDIT_MAPDESC",
}
local FIRST_CUSTOM_INDEX = 5
local ADDL_ANNOTATION    = "LOC_WORLDBUILDER_MAPEDIT_ADDLDATA"
local MAX_TEXT_CHARS     = 64 -- vanilla SetMaxCharacters on both text fields

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------
local m_panel      = nil   -- pushed root Panel
local m_tabs       = nil   -- TabControl
local m_idButton   = nil   -- General ID button (regenerates + re-announces on activate)
local m_textList   = nil   -- Text tab entry List
local m_langType   = nil   -- currently edited language locale (== curLang.Type)
local m_dialog     = nil   -- open entry editor Dialog
local RefreshTextList

-- ===========================================================================
--  Text data helpers (drive WorldBuilder.ModManager() directly)
-- ===========================================================================

-- Enumerate all key/string pairs for a language, mirroring vanilla's index walk.
local function EnumerateEntries(lang)
    local entries = {}
    local i = 1
    while true do
        local key, text = WorldBuilder.ModManager():GetKeyStringPairByIndex(i, lang)
        if key == nil then break end
        entries[#entries + 1] = { Key = key, Text = text, Index = i }
        i = i + 1
    end
    return entries
end

-- Vanilla copies the four system strings from the current game language into a
-- language that lacks them the first time it is selected. Replicate so switching
-- to an untranslated language still shows the system slots.
local function EnsureSystemStrings(lang)
    local curLang = Locale.GetCurrentLanguage()
    for i = 1, 4 do
        local key, text = WorldBuilder.ModManager():GetKeyStringPairByIndex(i, lang)
        if key == nil or text == nil then
            key, text = WorldBuilder.ModManager():GetKeyStringPairByIndex(i, curLang.Type)
            if key ~= nil then
                WorldBuilder.ModManager():SetString(key, text, lang)
            end
        end
    end
end

-- ===========================================================================
--  Text entry editor Dialog (Enter on a row, or the Add button)
-- ===========================================================================

local function CloseEntryDialog()
    local dialog = m_dialog
    m_dialog = nil
    if mgr and dialog and mgr:GetWidgetById(dialog:GetId()) then
        mgr:RemoveFromStack(dialog:GetId())
    end
end

-- entry == nil means a brand-new entry (Add). Otherwise editing entry in place.
local function OpenEntryEditor(entry)
    if not mgr or not m_panel then return end
    if m_dialog and mgr:GetWidgetById(m_dialog:GetId()) then return end

    local isNew   = entry == nil
    local titleFn = function() return Locale.Lookup("LOC_CAI_WB_EDIT_LOCALIZATION") end

    -- Live buffers mirrored from each AlwaysEdit box's text_changed, read on OK.
    local tagBuf = isNew and "" or (entry.Key or "")
    local strBuf = isNew and "" or (entry.Text or "")

    local tagEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Tag"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TEXT_TAG") end,
    })
    tagEdit:SetText(tagBuf, true)
    tagEdit:SetAlwaysEdit(true)
    tagEdit:SetEnterToCommit(false)
    tagEdit:SetHighlightOnEdit(true)
    tagEdit:SetMaxCharacters(MAX_TEXT_CHARS)
    tagEdit:SetFocusSound(FOCUS_SOUND)
    tagEdit:On("text_changed", function(_, t) tagBuf = t end)

    local strEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Str"), "EditBox", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TEXT_STRING") end,
    })
    strEdit:SetText(strBuf, true)
    strEdit:SetAlwaysEdit(true)
    strEdit:SetEnterToCommit(false)
    strEdit:SetHighlightOnEdit(true)
    strEdit:SetMaxCharacters(MAX_TEXT_CHARS)
    strEdit:SetFocusSound(FOCUS_SOUND)
    strEdit:On("text_changed", function(_, t) strBuf = t end)

    local okBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_OK"), "Button", {
        Label = function() return Locale.Lookup("LOC_OK") end,
    })
    okBtn:On("activate", function()
        if isNew then
            -- An empty tag has nothing to key on; treat as cancel.
            if tagBuf ~= "" then
                WorldBuilder.ModManager():SetString(tagBuf, strBuf, m_langType)
            end
            -- Focus was on the Add button before the dialog; closing returns to it
            -- and the rebuild does not steal focus, so Shift+Tab lands on the list.
            CloseEntryDialog()
            RefreshTextList()
        else
            WorldBuilder.ModManager():SetKeyStringPairByIndex(entry.Index, tagBuf, strBuf, m_langType)
            -- Update the captured entry so the row's live label reflects the edit,
            -- then just close: focus returns to that same row and announces it.
            entry.Key = tagBuf
            entry.Text = strBuf
            CloseEntryDialog()
        end
    end)

    local cancelBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Cancel"), "Button", {
        Label = function() return Locale.Lookup("LOC_CANCEL") end,
    })
    cancelBtn:On("activate", function() CloseEntryDialog() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(titleFn, { okBtn, cancelBtn }, { tagEdit, strEdit }, 1)
    if not m_dialog then return end

    m_dialog:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        MSG = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function() CloseEntryDialog() return true end,
    })
    mgr:Push(m_dialog, { priority = PopupPriority.Current, focus = tagEdit })
end

-- ===========================================================================
--  Text tab: language dropdown + entry list + add button
-- ===========================================================================

local function DeleteEntry(entry)
    if entry == nil or entry.Index < FIRST_CUSTOM_INDEX then return end
    WorldBuilder.ModManager():RemoveString(entry.Key, m_langType)
    RefreshTextList()
end

-- Rebuild the entry rows for the current language, restoring the captured
-- position: when focus was inside the list (delete) that speaks the new landing
-- once; when focus was outside it (Add button, language dropdown) focus is left
-- untouched. Edits don't rebuild - they update the row's live label in place.
RefreshTextList = function()
    if not m_textList then return end

    local capture = mgr:CaptureFocusKey(m_textList)
    m_textList:ClearChildren()

    for _, e in ipairs(EnumerateEntries(m_langType)) do
        local entry = e
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Entry"), "MenuItem", {
            -- System entries (1-4) read their specific annotation; custom entries
            -- (5+) read their localization tag (the unique key). The string
            -- follows when present. The generic custom annotation is the Add tooltip.
            Label = function()
                local head
                if entry.Index <= #SYSTEM_ANNOTATIONS then
                    head = Locale.Lookup(SYSTEM_ANNOTATIONS[entry.Index])
                else
                    head = entry.Key
                end
                local text = entry.Text
                if text ~= nil and text ~= "" then
                    return head .. ": " .. text
                end
                return head
            end,
            FocusKey = "wbtext:" .. entry.Key,
        })
        row:SetFocusSound(FOCUS_SOUND)
        row:On("activate", function() OpenEntryEditor(entry) end)

        -- Only custom entries (index >= 5) can be deleted, matching vanilla's
        -- disabled Remove for the four system strings.
        if entry.Index >= FIRST_CUSTOM_INDEX then
            row:AddInputBinding({
                Key = Keys.VK_DELETE,
                MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_WB_DELETE_TEXT",
                Action = function() DeleteEntry(entry) return true end,
            })
        end

        m_textList:AddChild(row)
    end

    -- Path/fallback restore already speaks the landing (delete); a nil capture
    -- (focus outside the list) is a no-op that leaves focus where it was.
    mgr:RestoreFocus(m_textList, capture)
end

local function BuildTextPage(page)
    -- Languages: mirror vanilla's list built from Locale.GetLanguages(); identity
    -- is the locale string (== Locale.GetCurrentLanguage().Type).
    local languages = Locale.GetLanguages()
    local curType = Locale.GetCurrentLanguage().Type
    local options, selected = {}, 1
    for i, v in ipairs(languages) do
        options[i] = { label = Locale.Lookup("{1: title}", v.Name), value = v.Locale }
        if v.Locale == curType then selected = i end
    end
    m_langType = languages[selected].Locale
    EnsureSystemStrings(m_langType)

    local langDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Lang"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_OPTIONS_LANGUAGE") end,
    })
    langDD:SetOptions(options)
    langDD:SetSelectedIndex(selected, true)
    langDD:SetFocusSound(FOCUS_SOUND)
    langDD:On("value_changed", function(_, value)
        m_langType = value
        EnsureSystemStrings(m_langType)
        RefreshTextList()
    end)
    page:AddChild(langDD)

    m_textList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_List"), "List", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_TEXT") end,
    })
    page:AddChild(m_textList)
    RefreshTextList()

    local addBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Add"), "Button", {
        Label   = function() return Locale.Lookup("LOC_WORLDBUILDER_ADD_BUTTON") end,
        Tooltip = function() return Locale.Lookup(ADDL_ANNOTATION) end,
    })
    addBtn:SetFocusSound(FOCUS_SOUND)
    addBtn:On("activate", function() OpenEntryEditor(nil) end)
    page:AddChild(addBtn)
end

-- ===========================================================================
--  General tab: Map metadata list, then the Is Mod checkbox, then edit fields
-- ===========================================================================

local function MapValues()
    return WorldBuilder.ConfigurationManager():GetMapValues()
end

-- A read-only "Label: value" line as StaticText.
local function AddMetaText(list, labelTag, value)
    local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Meta"), "StaticText", {
        Label = function() return Locale.Lookup(labelTag) .. ": " .. tostring(value) end,
    })
    w:SetFocusSound(FOCUS_SOUND)
    list:AddChild(w)
    return w
end

-- Editable field: an always-edit EditBox that commits only on Enter (not on focus
-- leave), through one of the base's global On*Edited handlers. Matches vanilla,
-- which puts no max-length or numeric restriction on these fields and validates
-- Reference Alpha only on commit (tonumber + 0..1 range -> status line).
local function AddEditField(page, labelTag, seedValue, commitFn)
    local edit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Edit"), "EditBox", {
        Label = function() return Locale.Lookup(labelTag) end,
    })
    edit:SetText(seedValue or "", true)
    edit:SetAlwaysEdit(true)
    edit:SetCommitOnFocusLeave(false) -- Enter commits; moving focus away does not
    edit:SetValueSetter(function(_, text)
        -- Each commit is a fresh user action: reset the launch bar's status-line
        -- de-dupe so committing the same value twice (e.g. a repeated "Reference
        -- map file not found") is spoken every time, not swallowed as a repeat.
        LuaEvents.CAIWorldBuilderStatusBurstBegin()
        commitFn(text)
    end)
    edit:SetFocusSound(FOCUS_SOUND)
    page:AddChild(edit)
    return edit
end

local function BuildGeneralPage(page)
    -- Map metadata: read-only details grouped as a List. The ID row is a button
    -- (activate = generate a new ID); Width / Height are static text.
    local metaList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_MetaList"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_WB_MAP_METADATA") end,
    })

    m_idButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_ID"), "Button", {
        Label   = function()
            return Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_ID") .. ": " .. WorldBuilder.GetID()
        end,
        Tooltip = function() return Locale.Lookup("LOC_CAI_WB_GENERATE_ID_TT") end,
    })
    m_idButton:SetFocusSound(FOCUS_SOUND)
    m_idButton:On("activate", function()
        WorldBuilder.SetID(WorldBuilder.GenerateID())
        m_idButton:Announce()
    end)
    metaList:AddChild(m_idButton)

    AddMetaText(metaList, "LOC_WORLDBUILDER_ATTRIBUTE_WIDTH",  MapValues().Width)
    AddMetaText(metaList, "LOC_WORLDBUILDER_ATTRIBUTE_HEIGHT", MapValues().Height)
    page:AddChild(metaList)

    -- Is Mod
    local isModCheck = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_IsMod"), "Checkbox", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_IS_MOD") end,
        Tooltip = function() return Locale.Lookup("LOC_WORLDBUILDER_ATTRIBUTE_IS_MOD_TT") end,
    })
    isModCheck:SetChecked(WorldBuilder.IsMod(), true)
    isModCheck:SetValueSetter(function(_, v) WorldBuilder.SetMod(v) end)
    isModCheck:SetFocusSound(FOCUS_SOUND)
    page:AddChild(isModCheck)

    -- Ruleset / Map Script
    AddEditField(page, "LOC_WORLDBUILDER_ATTRIBUTE_RULESET", tostring(MapValues().Ruleset),
        function(text) OnRulesetEdited(text) end)
    AddEditField(page, "LOC_WORLDBUILDER_ATTRIBUTE_MAP_SCRIPT", tostring(MapValues().MapScript),
        function(text) OnMapScriptEdited(text) end)

    -- Reference Map path + alpha (visual tracing aid; commit paths report loaded /
    -- not-found / bad-alpha via the status line spoken by WorldBuilderLaunchBar_CAI)
    AddEditField(page, "LOC_WORLDBUILDER_ATTRIBUTE_REFERENCE_MAP", "",
        function(text) OnMapReferenceEdited(text) end)
    local alpha = StrategicView_GetReferenceMapAlpha()
    if alpha == nil or alpha < 0.0 or alpha > 1.0 then alpha = 0.5 end
    AddEditField(page, "LOC_WORLDBUILDER_ATTRIBUTE_REFERENCE_ALPHA", tostring(alpha),
        function(text) OnMapReferenceAlphaEdited(text) end)
end

-- ===========================================================================
--  Panel build / open / close
-- ===========================================================================

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_MAP_EDITOR") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                -- Mirror the vanilla close path; our show-handler tears down the panel.
                LuaEvents.WorldBuilder_ShowMapEditor(false)
                return true
            end,
        },
    })

    m_tabs = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWBME_Tabs"), "TabControl", {
        Label = function() return Locale.Lookup("LOC_WORLDBUILDER_MAP_EDITOR") end,
    })
    local generalPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_GENERAL") end)
    BuildGeneralPage(generalPage)
    local textPage = m_tabs:AddPage(function() return Locale.Lookup("LOC_WORLDBUILDER_TAB_TEXT") end)
    BuildTextPage(textPage)
    m_panel:AddChild(m_tabs)
end

local function OpenPanel()
    if m_panel or not mgr then return end
    BuildPanel()
    mgr:Push(m_panel, { focus = m_tabs })
end

local function ClosePanel()
    if not m_panel then return end
    CloseEntryDialog()
    m_tabs     = nil
    m_idButton = nil
    m_textList = nil
    m_langType = nil
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
end

-- ===========================================================================
--  Vanilla lifecycle bridge
-- ===========================================================================

-- Same show/hide semantics as the base OnShowMapEditor (nil or true = show).
local function OnShowMapEditorCAI(bShow)
    if bShow == nil or bShow == true then
        OpenPanel()
    else
        ClosePanel()
    end
end
LuaEvents.WorldBuilder_ShowMapEditor.Add(OnShowMapEditorCAI)

-- The Player Editor hides the Map Editor when it opens; close our panel too.
local function OnShowPlayerEditorCAI(bShow)
    if bShow == nil or bShow == true then ClosePanel() end
end
LuaEvents.WorldBuilder_ShowPlayerEditor.Add(OnShowPlayerEditorCAI)

-- Forward input to the manager while our panel is open. Wrapping the base global
-- (rather than calling ContextPtr:SetInputHandler ourselves) survives the base
-- OnInit re-registering OnInputHandler after this file's top-level code runs.
OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel then
        if mgr:HandleInput(pInputStruct) then return true end
    end
    return orig(pInputStruct)
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    LuaEvents.WorldBuilder_ShowMapEditor.Remove(OnShowMapEditorCAI)
    LuaEvents.WorldBuilder_ShowPlayerEditor.Remove(OnShowPlayerEditorCAI)
    ClosePanel()
    orig()
end)
