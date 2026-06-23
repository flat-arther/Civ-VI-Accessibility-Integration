include("caiUtils")
include("MapPinPopup")
include("MapTacks")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID = "CAIMapPinPopup_Panel"

local m_panel       = nil
local m_nameEdit    = nil
local m_iconDD      = nil
local m_iconOptions = nil

-- ============================================================================
-- Icon label helpers
-- ============================================================================

local STOCK_ICON_LABELS = {
    ICON_MAP_PIN_STRENGTH = "LOC_CAI_MAP_PIN_ICON_STRENGTH",
    ICON_MAP_PIN_RANGED   = "LOC_CAI_MAP_PIN_ICON_RANGED",
    ICON_MAP_PIN_BOMBARD  = "LOC_CAI_MAP_PIN_ICON_BOMBARD",
    ICON_MAP_PIN_DISTRICT = "LOC_CAI_MAP_PIN_ICON_DISTRICT",
    ICON_MAP_PIN_CHARGES  = "LOC_CAI_MAP_PIN_ICON_CHARGES",
    ICON_MAP_PIN_DEFENSE  = "LOC_CAI_MAP_PIN_ICON_DEFENSE",
    ICON_MAP_PIN_MOVEMENT = "LOC_CAI_MAP_PIN_ICON_MOVEMENT",
    ICON_MAP_PIN_NO       = "LOC_CAI_MAP_PIN_ICON_NO",
    ICON_MAP_PIN_PLUS     = "LOC_CAI_MAP_PIN_ICON_PLUS",
    ICON_MAP_PIN_CIRCLE   = "LOC_CAI_MAP_PIN_ICON_CIRCLE",
    ICON_MAP_PIN_TRIANGLE = "LOC_CAI_MAP_PIN_ICON_TRIANGLE",
    ICON_MAP_PIN_SUN      = "LOC_CAI_MAP_PIN_ICON_SUN",
    ICON_MAP_PIN_SQUARE   = "LOC_CAI_MAP_PIN_ICON_SQUARE",
    ICON_MAP_PIN_DIAMOND  = "LOC_CAI_MAP_PIN_ICON_DIAMOND",
}

local function ResolveGameInfoName(typeKey)
    if not typeKey then return nil end
    local info
    if typeKey:find("^DISTRICT_") then
        info = GameInfo.Districts[typeKey]
    elseif typeKey:find("^BUILDING_") then
        info = GameInfo.Buildings[typeKey]
    elseif typeKey:find("^IMPROVEMENT_") then
        info = GameInfo.Improvements[typeKey]
    elseif typeKey:find("^UNIT_") then
        info = GameInfo.Units[typeKey]
    end
    if info and info.Name then
        return Locale.Lookup(info.Name)
    end
    return nil
end

local function GetIconLabel(pair)
    if pair.tooltip then
        local locText = Locale.Lookup(pair.tooltip)
        if locText and locText ~= "" and locText ~= pair.tooltip then return locText end
        local infoName = ResolveGameInfoName(pair.tooltip)
        if infoName then return infoName end
    end
    local stockKey = STOCK_ICON_LABELS[pair.name]
    if stockKey then return Locale.Lookup(stockKey) end
    return pair.name or "?"
end

-- ============================================================================
-- Build flattened icon option list for the dropdown
-- ============================================================================

local function BuildIconDropdownOptions()
    local playerID = Game.GetLocalPlayer()
    local sections = MapTacks.IconOptions(playerID)
    m_iconOptions = {}
    local options = {}
    for sectionIdx, section in ipairs(sections) do
        for iconIdx, pair in ipairs(section) do
            local flatIdx = #m_iconOptions + 1
            m_iconOptions[flatIdx] = { pair = pair, section = sectionIdx, index = iconIdx }
            table.insert(options, { label = GetIconLabel(pair), value = flatIdx })
        end
    end
    return options
end

local function FindIconIndex(iconName)
    if not m_iconOptions then return 1 end
    for i, entry in ipairs(m_iconOptions) do
        if entry.pair.name == iconName then return i end
    end
    return 1
end

-- ============================================================================
-- Panel build/teardown
-- ============================================================================

local function CommitName()
    if m_nameEdit then
        m_nameEdit:Commit()
    end
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_MAP_PIN_POPUP_TITLE") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                Controls.OkButton:DoLeftClick()
                return true
            end
        },
        {
            Key = Keys.VK_RETURN,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CONFIRM_MAP_PIN",
            Action = function()
                CommitName()
                Controls.OkButton:DoLeftClick()
                return true
            end
        },
    })

    -- Name edit
    local canRename = GameCapabilities.HasCapability("CAPABILITY_RENAME")
    if canRename then
        m_nameEdit = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_Name"), "EditBox", {
            Label = function() return Locale.Lookup("LOC_MAP_PIN_POPUP_TITLE") end,
            AlwaysEdit = true,
            HighlightOnEdit = true,
            EnterToCommit = false,
        })
        m_nameEdit:SetText(Controls.PinName:GetText() or "", true)
        m_nameEdit:SetValueSetter(function(_, text)
            Controls.PinName:SetText(text)
        end)
        m_panel:AddChild(m_nameEdit)
    end

    -- Icon dropdown
    local ddOptions = BuildIconDropdownOptions()
    m_iconDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_Icon"), "Dropdown", {
        Label = function() return Locale.Lookup("LOC_CAI_MAP_PIN_ICON_LABEL") end,
    })
    m_iconDD:SetOptions(ddOptions)
    local editPin = GetEditPinConfig()
    local currentIconName = editPin and editPin:GetIconName() or ""
    m_iconDD:SetSelectedIndex(FindIconIndex(currentIconName), true)
    m_iconDD:On("value_changed", function(_, value)
        local entry = m_iconOptions[value]
        if entry then
            OnIconOption(entry.index, entry.section)
        end
    end)
    m_panel:AddChild(m_iconDD)

    -- OK button
    local okBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_OK"), "Button", {
        Label = function() return Controls.OkButton:GetText() or Locale.Lookup("LOC_OK_BUTTON") end,
    })
    okBtn:On("activate", function()
        CommitName()
        Controls.OkButton:DoLeftClick()
    end)
    m_panel:AddChild(okBtn)

    -- Send to Chat button (multiplayer, conditionally visible)
    if GameConfiguration.IsNetworkMultiplayer() then
        local chatBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_Chat"), "Button", {
            Label = function() return Controls.SendToChatButton:GetText() or Locale.Lookup("LOC_MAP_PIN_SEND_TO_CHAT") end,
            Tooltip = function() return Controls.SendToChatButton:GetToolTipString() or "" end,
        })
        chatBtn:SetHiddenPredicate(function() return Controls.SendToChatButton:IsHidden() end)
        chatBtn:SetDisabledPredicate(function() return Controls.SendToChatButton:IsDisabled() end)
        chatBtn:On("activate", function()
            CommitName()
            Controls.SendToChatButton:DoLeftClick()
        end)
        m_panel:AddChild(chatBtn)
    end

    -- Delete button
    local delBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_Del"), "Button", {
        Label = function() return Controls.DeleteButton:GetText() or Locale.Lookup("LOC_DELETE_BUTTON") end,
    })
    delBtn:On("activate", function()
        Controls.DeleteButton:DoLeftClick()
    end)
    m_panel:AddChild(delBtn)
end

local function PushPanel()
    if m_panel then return end
    BuildPanel()
    mgr:Push(m_panel, { focus = m_nameEdit or m_iconDD })
end

local function PopPanel()
    if not m_panel then return end
    LuaEvents.CAIMapPinList_Refresh()
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
    m_nameEdit = nil
    m_iconDD = nil
    m_iconOptions = nil
end

-- ============================================================================
-- Open/close detection
-- ============================================================================

LuaEvents.MapPinPopup_RequestMapPin.Remove(RequestMapPin)

RequestMapPin = WrapFunc(RequestMapPin, function(orig, hexX, hexY)
    orig(hexX, hexY)
    if not ContextPtr:IsHidden() and mgr then
        PushPanel()
        Controls.PinName:DropFocus()
    end
end)

LuaEvents.MapPinPopup_RequestMapPin.Add(RequestMapPin)

ContextPtr:SetShowHideHandler(function(isHide)
    if isHide then
        PopPanel()
    end
end)

-- ============================================================================
-- Input handler
-- ============================================================================

local orig_OnInputHandler = OnInputHandler

ContextPtr:SetInputHandler(function(input)
    if mgr and m_panel then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return orig_OnInputHandler(input)
end, true)

ContextPtr:SetShutdown(function()
    PopPanel()
end)
