include("caiUtils")
include("MapPinPopup")
include("MapTacks")
include("inGameHelpers_CAI")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID = "CAIMapPinPopup_Panel"

local m_panel       = nil
local m_nameEdit    = nil
local m_iconDD      = nil
local m_iconOptions = nil
local m_visibilityDD = nil
local m_visibilityOptions = nil
local m_visibilityCommitted = nil
local m_visibilityPending = nil
local m_editPinPlayerID = nil
local m_editPinID = nil
local m_visibilityChangedByCAI = false
local m_nativeConfirmInProgress = false

local m_vanillaOnOk = OnOk
local m_vanillaOnSendToChatButton = OnSendToChatButton

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
            table.insert(options, { label = GetMapTacIconLabel(pair.name) or pair.name or "?", value = flatIdx })
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
-- Multiplayer visibility transaction
-- ============================================================================

local function BuildVisibilityOptions()
    local options = {
        {
            label = Locale.Lookup("LOC_DIPLO_TO_ALL"),
            value = ChatTargetTypes.CHATTARGET_ALL,
        },
    }

    local localPlayerID = Game.GetLocalPlayer()
    local localPlayer = PlayerConfigurations[localPlayerID]
    local localTeam = localPlayer and localPlayer:GetTeam() or TeamTypes.NO_TEAM
    if localTeam ~= TeamTypes.NO_TEAM and GameConfiguration.GetTeamPlayerCount(localTeam, true) > 1 then
        table.insert(options, {
            label = Locale.Lookup("LOC_DIPLO_TO_TEAM"),
            value = ChatTargetTypes.CHATTARGET_TEAM,
        })
    end

    table.insert(options, {
        label = Locale.Lookup("LOC_DIPLO_TO_SELF"),
        value = localPlayerID,
    })

    for _, playerID in ipairs(GameConfiguration.GetParticipatingPlayerIDs()) do
        local playerConfig = PlayerConfigurations[playerID]
        if playerID ~= localPlayerID and playerConfig and playerConfig:IsHuman() then
            table.insert(options, {
                label = Locale.Lookup("LOC_DIPLO_TO_PLAYER", playerConfig:GetPlayerName()),
                value = playerID,
            })
        end
    end

    return options
end

local function FindVisibilityIndex(visibility)
    for index, option in ipairs(m_visibilityOptions or {}) do
        if option.value == visibility then return index end
    end
    return 1
end

local function GetTransactionPin()
    if m_editPinPlayerID == nil or m_editPinID == nil then return nil end
    local playerConfig = PlayerConfigurations[m_editPinPlayerID]
    return playerConfig and playerConfig:GetMapPinID(m_editPinID) or nil
end

local function SetLiveVisibility(visibility)
    m_visibilityChangedByCAI = true
    m_visibilityPending = visibility

    local editPin = GetTransactionPin()
    if editPin and editPin:GetVisibility() ~= visibility then
        editPin:SetVisibility(visibility)
        Network.BroadcastPlayerInfo()
    end

    ShowHideSendToChatButton()
end

local function CommitCurrentVisibility()
    local editPin = GetTransactionPin()
    if editPin then
        m_visibilityPending = editPin:GetVisibility()
        m_visibilityCommitted = m_visibilityPending
    end
end

local function RestoreCommittedVisibility()
    local editPin = GetTransactionPin()
    if editPin and m_visibilityCommitted ~= nil
        and editPin:GetVisibility() ~= m_visibilityCommitted then
        editPin:SetVisibility(m_visibilityCommitted)
        Network.BroadcastPlayerInfo()
    end
end

-- ============================================================================
-- Panel build/teardown
-- ============================================================================

local function CommitName()
    if m_nameEdit then
        m_nameEdit:Commit()
    end
end

local function ConfirmAndClose()
    CommitName()
    m_visibilityCommitted = m_visibilityPending
    m_vanillaOnOk()
end

local function SendToChat()
    CommitName()
    CommitCurrentVisibility()
    m_vanillaOnSendToChatButton()
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
                OnCancel()
                return true
            end
        },
        {
            Key = Keys.VK_RETURN,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CONFIRM_MAP_PIN",
            Action = function()
                ConfirmAndClose()
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

    -- Visibility commits to the live pin immediately so the native Send to
    -- Chat state can react. Closing without OK restores the last committed
    -- value; sending the pin advances that committed baseline.
    if GameConfiguration.IsAnyMultiplayer() then
        m_visibilityOptions = BuildVisibilityOptions()
        m_visibilityDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_Visibility"), "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_MAP_PIN_VISIBILITY_LABEL") end,
        })
        m_visibilityDD:SetOptions(m_visibilityOptions)
        m_visibilityDD:SetSelectedIndex(FindVisibilityIndex(m_visibilityPending), true)
        m_visibilityDD:SetValueSetter(function(_, visibility)
            SetLiveVisibility(visibility)
        end)
        m_panel:AddChild(m_visibilityDD)
    end

    -- OK button
    local okBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinPopup_OK"), "Button", {
        Label = function() return Controls.OkButton:GetText() or Locale.Lookup("LOC_OK_BUTTON") end,
    })
    okBtn:On("activate", function()
        ConfirmAndClose()
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
            SendToChat()
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

    local editPin = GetEditPinConfig()
    if editPin then
        m_editPinPlayerID = editPin:GetPlayerID()
        m_editPinID = editPin:GetID()
        m_visibilityCommitted = editPin:GetVisibility()
        m_visibilityPending = m_visibilityCommitted
    end

    BuildPanel()
    mgr:Push(m_panel, { focus = m_nameEdit or m_iconDD })
end

local function PopPanel()
    if not m_panel then return end
    if not m_nativeConfirmInProgress then
        RestoreCommittedVisibility()
    end
    LuaEvents.CAIMapPinList_Refresh()
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
    m_nameEdit = nil
    m_iconDD = nil
    m_iconOptions = nil
    m_visibilityDD = nil
    m_visibilityOptions = nil
    m_visibilityCommitted = nil
    m_visibilityPending = nil
    m_editPinPlayerID = nil
    m_editPinID = nil
    m_visibilityChangedByCAI = false
    m_nativeConfirmInProgress = false
end

-- Preserve the native mouse/keyboard confirmation path. It owns its private
-- visibility target and should not be rolled back by the CAI transaction.
local function NativeConfirmAndClose()
    if m_visibilityChangedByCAI then
        m_visibilityCommitted = m_visibilityPending
        m_vanillaOnOk()
        return
    end

    m_nativeConfirmInProgress = true
    m_vanillaOnOk()
    if m_panel then m_nativeConfirmInProgress = false end
end

local function NativeSendToChat()
    CommitCurrentVisibility()
    m_vanillaOnSendToChatButton()
end

Controls.OkButton:RegisterCallback(Mouse.eLClick, NativeConfirmAndClose)
Controls.PinName:RegisterCommitCallback(NativeConfirmAndClose)
Controls.SendToChatButton:RegisterCallback(Mouse.eLClick, NativeSendToChat)

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
