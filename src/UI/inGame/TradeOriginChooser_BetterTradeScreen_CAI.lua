-- Accessibility layer for the Change Origin City screen as rewritten by the
-- Better Trade Screen mod (astog). Included by TradeOriginChooser_CAI.lua when
-- that mod is active. The base context script is already included by the
-- dispatcher.
--
-- Two meaningful differences from the vanilla screen:
--   1. BTS's AddCity takes a city id (number) instead of a city table.
--   2. BTS's city button click only marks a pending new origin and shows a
--      confirm button, instead of teleporting on click like vanilla. So the
--      row activation calls TeleportToCity directly rather than DoLeftClick.
-- Everything else (the Controls.CityStack button scan, Refresh/Open/Close
-- lifecycle, TeleportToCity) matches the vanilla CAI layer.

local mgr        = ExposedMembers.CAI_UIManager

local PANEL_ID   = "CAITradeOrigin_Panel"
local LIST_ID    = "CAITradeOrigin_List"
local HOVER_SOUND = "Main_Menu_Mouse_Over"

local m_panel    = nil
local m_list     = nil
local m_rows     = {}

local function GetPanelTitle()
    if Controls.Title then
        local text = Controls.Title:GetText()
        if text and text ~= "" then
            return text
        end
    end
    return Locale.ToUpper(Locale.Lookup("LOC_UNITOPERATION_MOVE_TO_DESCRIPTION"))
end

local function FindNewCityButton(city, usedControls)
    if not Controls.CityStack then
        return nil
    end

    local expectedText = Locale.ToUpper(city:GetName())
    local children = Controls.CityStack:GetChildren() or {}
    for i = #children, 1, -1 do
        local child = children[i]
        local controlKey = child and (child.CData or child)
        if child and not child:IsHidden() and not usedControls[controlKey] then
            local text = child:GetText()
            if text == expectedText then
                usedControls[controlKey] = true
                return child
            end
        end
    end

    return nil
end

local function PopulateList(capture)
    if not m_list then
        return
    end

    capture = capture or mgr:CaptureFocusKey(m_list)
    m_list:ClearChildren()

    for _, row in ipairs(m_rows) do
        local city = row.city
        local button = row.button
        local owner = city:GetOwner()
        local cityID = city:GetID()

        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAITradeOrigin_City"), "MenuItem", {
            Label = function()
                if button then
                    local text = button:GetText()
                    if text and text ~= "" then
                        return text
                    end
                end
                return Locale.ToUpper(city:GetName())
            end,
            Tooltip = function()
                if button then
                    return button:GetToolTipString() or ""
                end
                return ""
            end,
            HiddenPredicate = function()
                return button ~= nil and button:IsHidden()
            end,
            DisabledPredicate = function()
                return button ~= nil and button:IsDisabled()
            end,
            FocusKey = "city:" .. owner .. ":" .. cityID,
        })
        item:SetFocusSound(HOVER_SOUND)
        item:On("activate", function()
            -- BTS's city button click only marks a pending origin and shows a
            -- separate confirm button (ChangeOriginCityButton) instead of
            -- teleporting like vanilla does. Call TeleportToCity directly so
            -- activating a city performs the move in one step, matching the
            -- vanilla CAI screen behavior.
            TeleportToCity(city)
        end)
        m_list:AddChild(item)
    end

    mgr:RestoreFocus(m_list, capture)
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = GetPanelTitle,
    })

    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = GetPanelTitle,
    })
    m_panel:AddChild(m_list)
end

local function PushPanel()
    if not mgr then
        return
    end

    if m_panel then
        PopulateList()
        return
    end

    BuildPanel()
    PopulateList(nil)
    mgr:Push(m_panel, PopupPriority.Low)
end

local function PopPanel()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_list = nil
end

-- BTS AddCity takes a city id, not a city table.
AddCity = WrapFunc(AddCity, function(orig, cityID)
    orig(cityID)

    local city = Players[Game.GetLocalPlayer()]:GetCities():FindID(cityID)
    if not city then return end

    local usedControls = {}
    for _, row in ipairs(m_rows) do
        if row.button then
            usedControls[row.button.CData or row.button] = true
        end
    end

    table.insert(m_rows, {
        city = city,
        button = FindNewCityButton(city, usedControls),
    })
end)

Refresh = WrapFunc(Refresh, function(orig)
    local capture = nil
    if mgr and m_list then
        capture = mgr:CaptureFocusKey(m_list)
    end

    m_rows = {}
    orig()

    if m_list then
        PopulateList(capture)
    end
end)

Open = WrapFunc(Open, function(orig)
    orig()
    if mgr and not ContextPtr:IsHidden() then
        PushPanel()
    end
end)

Close = WrapFunc(Close, function(orig)
    PopPanel()
    orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    PopPanel()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)

local function CAI_OnInputHandler(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end

    if input:GetMessageType() == KeyEvents.KeyUp and input:GetKey() == Keys.VK_ESCAPE then
        OnClose()
        return true
    end

    return false
end
ContextPtr:SetInputHandler(CAI_OnInputHandler, true)
