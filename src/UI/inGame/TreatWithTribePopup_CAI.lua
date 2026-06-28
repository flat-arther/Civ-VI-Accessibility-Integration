include("caiUtils")
include("TreatWithTribePopup")
local mgr = ExposedMembers.CAI_UIManager

local m_Dialog = nil ---@type DialogWidget|nil

local m_LocalPlotIndex = -1
local m_LocalSelectedTargetID = -1


local function BuildInciteDropdownOptions()
    local options = { { label = Locale.Lookup("LOC_DIPLOMACY_DEAL_SELECT_TARGET"), value = { id = -1, name = "", cost = -1 }, } }
    local iActivePlayer = Game.GetLocalPlayer()


    if iActivePlayer == -1 or m_LocalPlotIndex == -1 then
        return options
    end
    local pPlayer = Players[iActivePlayer]

    local pTribePlot = Map.GetPlotByIndex(m_LocalPlotIndex)
    local pBarbarianManager = Game.GetBarbarianManager()
    local tribeIndex = pBarbarianManager:GetTribeIndexAtLocation(pTribePlot:GetX(), pTribePlot:GetY())
    local tInciteTargets = pBarbarianManager:GetTribeInciteTargets(tribeIndex, iActivePlayer)

    if tInciteTargets then
        local inciteSourceID = pBarbarianManager:GetTribeInciteSourcePlayer(tribeIndex)
        local inciteTargetID = pBarbarianManager:GetTribeInciteTargetPlayer(tribeIndex)

        for _, eTargetPlayer in ipairs(tInciteTargets) do
            local bSkip = false
            if eTargetPlayer == inciteTargetID and iActivePlayer == inciteSourceID then
                bSkip = true
            end

            if not bSkip then
                local pOtherPlayerConfig = PlayerConfigurations[eTargetPlayer]
                local strOtherPlayerCivName = Locale.Lookup(pOtherPlayerConfig:GetCivilizationShortDescription())
                local strOtherPlayerLeaderName = Locale.Lookup(pOtherPlayerConfig:GetLeaderName())

                local otherPlayerCost = pBarbarianManager:GetTribeInciteCost(tribeIndex, iActivePlayer, eTargetPlayer)

                local labelText = strOtherPlayerCivName
                if strOtherPlayerCivName ~= strOtherPlayerLeaderName then
                    labelText = strOtherPlayerCivName .. " - " .. strOtherPlayerLeaderName
                end
                local strCost = Locale.Lookup("LOC_CAI_PRODUCTION_COST_GOLD", otherPlayerCost);
                table.insert(options, {
                    label = labelText,
                    value = { id = eTargetPlayer, name = labelText, cost = otherPlayerCost },
                    tooltip = function()
                        if (otherPlayerCost <= pPlayer:GetTreasury():GetGoldBalance()) then
                            return strCost
                        end
                        return strCost .. ", " .. Locale.Lookup("LOC_CAI_PRODUCTION_CANNOT_AFFORD")
                    end,
                    disabledPredicate = function()
                        return otherPlayerCost == 0 or otherPlayerCost > pPlayer:GetTreasury():GetGoldBalance()
                    end
                })
            end
        end
    end
    return options
end


local function RemoveDialog()
    if not m_Dialog then return end
    mgr:RemoveFromStack(m_Dialog:GetId())
    m_Dialog = nil
end

local function PushDialog()
    if not mgr then return end
    if m_Dialog then
        mgr:Push(m_Dialog)
    end
end

local function MakeButton(labelCtrl, descCtrl)
    if not mgr then return end

    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_TreatWithBarbTribeOperationBtn"), "Button", {
        Label = function() return labelCtrl:GetText() or "" end,
    })
    if descCtrl then
        btn:SetTooltip(function() return descCtrl:GetText() or "" end)
    end
    btn:On("activate", function(w)
        labelCtrl:DoLeftClick()
    end)
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    return btn
end

local function BuildDialog()
    if not mgr then return end
    local actionButtons = {}
    local bribeBtn = MakeButton(Controls.TreatOptionButtonBribe, Controls.TreatOptionBribeDescription)
    bribeBtn:SetDisabledPredicate(function() return Controls.BribeOption:IsHidden() end)
    bribeBtn:SetDisabledPredicate(function() return Controls.TreatOptionButtonBribe:IsDisabled() end)
    table.insert(actionButtons, bribeBtn)

    local hireBtn = MakeButton(Controls.TreatOptionButtonHire, Controls.TreatOptionHireDescription)
    hireBtn:SetHiddenPredicate(function() return Controls.HireOption:IsHidden() end)
    hireBtn:SetDisabledPredicate(function() return Controls.TreatOptionButtonHire:IsDisabled() end)
    table.insert(actionButtons, hireBtn)

    local ransomBtn = MakeButton(Controls.TreatOptionButtonRansom, Controls.TreatOptionRansomDescription)
    ransomBtn:SetHiddenPredicate(function() return Controls.RansomOption:IsHidden() end)
    ransomBtn:SetDisabledPredicate(function() return Controls.TreatOptionButtonRansom:IsDisabled() end)
    table.insert(actionButtons, ransomBtn)

    local inciteDD = mgr:CreateWidget(mgr:GenerateWidgetId("CAI_BarbInciteDD"), "Dropdown", {
        Label = function() return Controls.TreatOptionButtonIncite:GetText() or "" end,
        HiddenPredicate = function() return Controls.InciteTargetPulldown:IsHidden() end,
        Tooltip = function() return Controls.TreatOptionInciteDescription:GetText() or "" end
    })
    local ddOptions = BuildInciteDropdownOptions()
    inciteDD:SetOptions(ddOptions)
    inciteDD:SetFocusSound("Main_Menu_Mouse_Over")

    local selectedIdx = 1
    for i, opt in ipairs(ddOptions) do
        if opt.value and opt.value.id == m_LocalSelectedTargetID then
            selectedIdx = i
            break
        end
    end
    inciteDD:SetSelectedIndex(selectedIdx, true)

    inciteDD:On("value_changed", function(_, value)
        m_LocalSelectedTargetID = value.id
        SelectInciteTarget(value.id, value.name, value.cost)
        Controls.TreatOptionButtonIncite:DoLeftClick()
    end)

    local statusTxt = mgr:CreateWidget("CAI_TreatWithBarbStaticText", "StaticText", {
        Label = function() return Controls.SubheaderLabel:GetText() or "" end
    })
    statusTxt:SetFocusSound("Main_Menu_Mouse_Over")

    local function GetTitle() return Controls.HeaderLabel:GetText() or "" end
    m_Dialog = mgr.WidgetHelpers.MakeGeneralDialog(GetTitle, actionButtons, { statusTxt, inciteDD })
end

LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Remove(OnOpenTreatWithTribePopup);
OnOpenTreatWithTribePopup = WrapFunc(OnOpenTreatWithTribePopup, function(orig, plotIndex)
    m_LocalPlotIndex = plotIndex
    m_LocalSelectedTargetID = -1
    orig(plotIndex)
    RemoveDialog()
    BuildDialog()
    if m_Dialog then
        PushDialog()
    end
end)

ClosePopup = WrapFunc(ClosePopup, function(orig)
    RemoveDialog()
    orig()
end)

OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_Dialog and mgr:GetTop() == m_Dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Add(OnOpenTreatWithTribePopup);

Controls.TreatOptionButtonBribe:RegisterCallback(Mouse.eLClick, OnBribe);
Controls.TreatOptionButtonHire:RegisterCallback(Mouse.eLClick, OnHire);
Controls.TreatOptionButtonRansom:RegisterCallback(Mouse.eLClick, OnRansom);
Controls.TreatOptionButtonIncite:RegisterCallback(Mouse.eLClick, OnIncite);
