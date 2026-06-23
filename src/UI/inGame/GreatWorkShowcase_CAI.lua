-- GreatWorkShowcase_CAI.lua
-- Accessibility overlay for the Great Work Showcase / detail view.
-- Rides the wildcard include("GreatWorkShowcase_", true) from the base file.

include("caiUtils")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID = "CAIGreatWorkShowcase_Panel"

local m_ui = { panel = nil }

-- ---------------------------------------------------------------------------
-- Content helper — reads from vanilla controls after they are updated
-- ---------------------------------------------------------------------------

local function GetWorkDetailsLabel()
    local parts = {}

    if not Controls.MusicDetails:IsHidden() then
        local name   = Controls.MusicName:GetText() or ""
        local author = Controls.MusicAuthor:GetText() or ""
        if name   ~= "" then table.insert(parts, name) end
        if author ~= "" then table.insert(parts, author) end
    elseif not Controls.WritingDetails:IsHidden() then
        local name = Controls.WritingName:GetText() or ""
        if name ~= "" then table.insert(parts, name) end
        if not Controls.WritingQuote:IsHidden() then
            local quote  = Controls.WritingQuote:GetText() or ""
            local author = Controls.WritingAuthor:GetText() or ""
            if quote  ~= "" then table.insert(parts, quote) end
            if author ~= "" then table.insert(parts, author) end
        end
    elseif not Controls.GreatWorkBanner:IsHidden() then
        local name = Controls.GreatWorkName:GetText() or ""
        if name ~= "" then table.insert(parts, name) end
    end

    local createdBy    = Controls.CreatedBy:GetText() or ""
    local createdDate  = Controls.CreatedDate:GetText() or ""
    local createdPlace = Controls.CreatedPlace:GetText() or ""
    if createdBy    ~= "" then table.insert(parts, createdBy) end
    if createdDate  ~= "" then table.insert(parts, createdDate) end
    if createdPlace ~= "" then table.insert(parts, createdPlace) end

    return table.concat(parts, ". ")
end

-- ---------------------------------------------------------------------------
-- Panel
-- ---------------------------------------------------------------------------

local function BuildPanel()
    if not mgr then return end

    m_ui.panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function()
            local header = Controls.GreatWorkHeader:GetText() or ""
            if header ~= "" then return header end
            return Locale.Lookup("LOC_GREAT_WORKS_SCREEN_TITLE")
        end,
    })

    local details = mgr:CreateWidget("CAIGWShowcase_Details", "StaticText", {
        Label = function() return GetWorkDetailsLabel() end,
    })
    m_ui.panel:AddChild(details)

    local prevBtn = mgr:CreateWidget("CAIGWShowcase_Prev", "Button", {
        Label           = function()
            return Locale.Lookup("LOC_CAI_GREAT_WORKS_PREVIOUS")
        end,
        HiddenPredicate = function()
            return Controls.PreviousGreatWork:IsHidden()
        end,
    })
    prevBtn:SetFocusSound("Main_Menu_Mouse_Over")
    prevBtn:On("activate", function() Controls.PreviousGreatWork:DoLeftClick() end)
    m_ui.panel:AddChild(prevBtn)

    local nextBtn = mgr:CreateWidget("CAIGWShowcase_Next", "Button", {
        Label           = function()
            return Locale.Lookup("LOC_CAI_GREAT_WORKS_NEXT")
        end,
        HiddenPredicate = function()
            return Controls.NextGreatWork:IsHidden()
        end,
    })
    nextBtn:SetFocusSound("Main_Menu_Mouse_Over")
    nextBtn:On("activate", function() Controls.NextGreatWork:DoLeftClick() end)
    m_ui.panel:AddChild(nextBtn)

    local backBtn = mgr:CreateWidget("CAIGWShowcase_Back", "Button", {
        Label = function()
            return Controls.ViewGreatWorks:GetText()
                or Locale.Lookup("LOC_GREAT_WORKS_VIEW_GREAT_WORKS")
        end,
        HiddenPredicate = function()
            return Controls.ViewGreatWorks:IsHidden()
        end,
    })
    backBtn:SetFocusSound("Main_Menu_Mouse_Over")
    backBtn:On("activate", function() Controls.ViewGreatWorks:DoLeftClick() end)
    m_ui.panel:AddChild(backBtn)

    m_ui.panel:AddInputBindings({
        {
            Key    = Keys.VK_LEFT,
            MSG    = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_PREVIOUS_GREAT_WORK",
            Action = function()
                if not Controls.PreviousGreatWork:IsHidden() then
                    OnPreviousGreatWork()
                    return true
                end
                return false
            end,
        },
        {
            Key    = Keys.VK_RIGHT,
            MSG    = KeyEvents.KeyDown,
            Description = "LOC_CAI_KB_NEXT_GREAT_WORK",
            Action = function()
                if not Controls.NextGreatWork:IsHidden() then
                    OnNextGreatWork()
                    return true
                end
                return false
            end,
        },
    })
end

local function PushPanel()
    if not mgr or not m_ui.panel then return end
    if not mgr:GetWidgetById(PANEL_ID) then
        mgr:Push(m_ui.panel, PopupPriority.Low)
    end
end

local function PopPanel()
    if mgr and m_ui.panel then mgr:RemoveFromStack(PANEL_ID) end
    m_ui = { panel = nil }
end

-- ---------------------------------------------------------------------------
-- Vanilla wraps
-- ---------------------------------------------------------------------------

ShowScreen = WrapFunc(ShowScreen, function(orig)
    orig()
    if not m_ui.panel then BuildPanel() end
    PushPanel()
end)

HideScreen = WrapFunc(HideScreen, function(orig)
    PopPanel()
    orig()
end)

OnPreviousGreatWork = WrapFunc(OnPreviousGreatWork, function(orig)
    orig()
    if m_ui.panel and not ContextPtr:IsHidden() then
        mgr:Refocus()
    end
end)

OnNextGreatWork = WrapFunc(OnNextGreatWork, function(orig)
    orig()
    if m_ui.panel and not ContextPtr:IsHidden() then
        mgr:Refocus()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, input)
    if mgr then
        local top = mgr:GetTop()
        if top == m_ui.panel then
            if mgr:HandleInput(input) then return true end
        end
    end
    return orig(input)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
