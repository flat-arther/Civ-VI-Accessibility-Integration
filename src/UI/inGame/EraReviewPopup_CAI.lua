include("caiUtils")
include("EraReviewPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function GetPlayerAgeKey(gameEras, playerID)
    if gameEras:HasHeroicGoldenAge(playerID) then
        return "LOC_ERA_PROGRESS_HEROIC_AGE"
    elseif gameEras:HasGoldenAge(playerID) then
        return "LOC_ERA_PROGRESS_GOLDEN_AGE"
    elseif gameEras:HasDarkAge(playerID) then
        return "LOC_ERA_PROGRESS_DARK_AGE"
    else
        return "LOC_ERA_PROGRESS_NORMAL_AGE"
    end
end

local function BuildDialog()
    RemoveDialog()
    if not mgr or ContextPtr:IsHidden() then return end

    local effectsRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewEffects"), "StaticText", {
        Label = function() return Controls.EraEffects:GetText() or "" end,
    })

    local contentRows = { effectsRow }

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then return end

    local gameEras = Game.GetEras()
    local localPlayer = Players[localPlayerID]
    local aPlayers = PlayerManager.GetAliveMajors()

    for _, pPlayer in ipairs(aPlayers) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID then
            local playerConfig = PlayerConfigurations[playerID]
            local isMet = localPlayer and localPlayer:GetDiplomacy():HasMet(playerID)
            if isMet then
                local leaderName = Locale.Lookup(playerConfig:GetLeaderName())
                local civName = Locale.Lookup(playerConfig:GetCivilizationDescription())
                local ageName = Locale.Lookup(GetPlayerAgeKey(gameEras, playerID))
                local label = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderName, civName) .. ", " .. ageName
                local civRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewCiv"), "StaticText", {
                    Label = label,
                })
                table.insert(contentRows, civRow)
            end
        end
    end

    local continueBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewContinue"), "Button", {
        Label = function() return Controls.Continue:GetText() or Locale.Lookup("LOC_CONTINUE") end,
    })
    continueBtn:On("activate", function() Controls.Continue:DoLeftClick() end)

    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIEraReviewClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CAI_ERA_REVIEW_CLOSE") end,
    })
    closeBtn:On("activate", function() Controls.Close:DoLeftClick() end)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.Title:GetText() or "" end,
        { continueBtn, closeBtn },
        contentRows,
        1
    )
    if not m_dialog then return end

    mgr:Push(m_dialog, { priority = PopupPriority.MediumHigh })
end

LuaEvents.EraReviewPopup_Show.Remove(OnShowEraReviewPopup);
OnShowEraReviewPopup = WrapFunc(OnShowEraReviewPopup, function(orig)
    orig()
    BuildDialog()
end)
LuaEvents.EraReviewPopup_Show.Add(OnShowEraReviewPopup);

OnClose = WrapFunc(OnClose, function(orig)
    RemoveDialog()
    orig()
end)

OnContinue = WrapFunc(OnContinue, function(orig)
    RemoveDialog()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
-- Reregister the existing button callbacks to trigger our wrapped functions
Controls.Close:RegisterCallback(Mouse.eLClick, OnClose);
Controls.Continue:RegisterCallback(Mouse.eLClick, OnContinue);
