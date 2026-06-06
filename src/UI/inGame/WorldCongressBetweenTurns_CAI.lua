include("caiUtils")
include("WorldCongressBetweenTurns")

local mgr = ExposedMembers.CAI_UIManager
local m_panel = nil ---@type UIWidget|nil
local PANEL_ID = "CAIWorldCongressBetweenTurns"

local function FindChildDeep(root, id)
    if not root or not root.GetChildren then return nil end
    for _, child in ipairs(root:GetChildren()) do
        if child:GetID() == id then return child end
        local found = FindChildDeep(child, id)
        if found then return found end
    end
    return nil
end

local function RemovePanel()
    if not mgr or not m_panel then return end
    mgr:RemoveFromStack(PANEL_ID)
    m_panel = nil
end

local function BuildPanel()
    RemovePanel()
    if not mgr or not ContextPtr:IsVisible() then return end

    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Controls.Title:GetText() or "" end,
    })

    local status = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCBTStatus"), "StaticText", {
        Label = function() return Controls.Status:GetText() or "" end,
    })
    m_panel:AddChild(status)

    local playerList = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCBTPlayers"), "List", {
        Label = function() return Locale.Lookup("LOC_CAI_WC_BETWEEN_TURNS_PLAYERS") end,
    })

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID < 0 then return end
    local pDiplomacy = Players[localPlayerID]:GetDiplomacy()
    local aPlayers = PlayerManager.GetAliveMajors()
    local playerChildren = Controls.PlayersStack:GetChildren() or {}

    for i, pPlayer in ipairs(aPlayers) do
        local playerID = pPlayer:GetID()
        local pConfig = PlayerConfigurations[playerID]
        local isLocal = playerID == localPlayerID
        local hasMet = isLocal or pDiplomacy:HasMet(playerID)

        local playerName
        if hasMet or (GameConfiguration.IsAnyMultiplayer() and pConfig:IsHuman()) then
            playerName = Locale.Lookup(pConfig:GetLeaderName())
        else
            playerName = Locale.Lookup("LOC_DIPLO_UNKNOWN_LEADER")
        end

        -- Find the matching vanilla instance to read status label
        local instanceRoot = playerChildren[i]
        local labelCtrl = instanceRoot and FindChildDeep(instanceRoot, "Label") or nil

        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCBT_P"), "MenuItem", {
            Label = function()
                local statusText = labelCtrl and labelCtrl:GetText() or ""
                return playerName .. ": " .. statusText
            end,
        })
        item.FocusKey = "bt:player:" .. playerID
        playerList:AddChild(item)
    end

    m_panel:AddChild(playerList)

    local hideBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIWCBTHide"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_WC_BETWEEN_TURNS_HIDE") end,
    })
    hideBtn:On("activate", function() OnHide() end)
    hideBtn:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
    m_panel:AddChild(hideBtn)

    mgr:Push(m_panel, { priority = PopupPriority.WorldCongressBetweenTurns })
end

OnShow = WrapFunc(OnShow, function(orig, stageNum)
    orig(stageNum)
    BuildPanel()
end)

OnHide = WrapFunc(OnHide, function(orig)
    RemovePanel()
    orig()
end)

OnRemotePlayerTurnEnd = WrapFunc(OnRemotePlayerTurnEnd, function(orig, playerID)
    orig(playerID)
    if mgr and m_panel then
        mgr:Refocus()
    end
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_panel and mgr:GetTop() == m_panel and ContextPtr:IsVisible() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
