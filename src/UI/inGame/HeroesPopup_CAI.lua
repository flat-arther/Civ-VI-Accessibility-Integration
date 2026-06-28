include("caiUtils")
include("HeroesPopup")
local mgr = ExposedMembers.CAI_UIManager
local m_dialog = nil ---@type DialogWidget|nil

local m_CachedHeroClass = -1
local m_CachedPopupType = ""

local function RemoveAccessibleHeroDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildAccessibleHeroDialog()
    RemoveAccessibleHeroDialog()
    if not mgr or m_CachedHeroClass == -1 then return end

    local kHeroDef = GameInfo.HeroClasses[m_CachedHeroClass]
    if not kHeroDef then return end

    local contentRows = {}

    local summaryRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHeroSummaryText"), "StaticText", {
        Label = function()
            local body = Controls.EventDescription:GetText() or ""
            local subDesc = Controls.HeroDescription:GetText() or ""
            return body .. " " .. subDesc
        end
    })
    table.insert(contentRows, summaryRow)

    if m_CachedPopupType == "DISCOVERED" then
        local detailsRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHeroDetailsText"), "StaticText", {
            Label = function()
                local textLines = {}
                local kAbilities = GetHeroClassUnitAbilities(kHeroDef.Index)
                if kAbilities and #kAbilities > 0 then
                    table.insert(textLines, "[NEWLINE]" .. Locale.Lookup("LOC_CAI_GP_HEROES_PASSIVES") .. ":")
                    for _, kAbility in pairs(kAbilities) do
                        local abName = Locale.Lookup(kAbility.Name)
                        local abDesc = Locale.Lookup(kAbility.Description)
                        table.insert(textLines, abName .. ": " .. abDesc)
                    end
                end

                -- Replicate Vanilla Command Flow
                local kCommands = GetHeroClassUnitCommands(kHeroDef.Index)
                if kCommands and #kCommands > 0 then
                    table.insert(textLines, "[NEWLINE]" .. Locale.Lookup("LOC_CAI_GP_HEROES_COMMANDS") .. ":")
                    for _, kCommand in pairs(kCommands) do
                        local cmdName = Locale.Lookup(kCommand.Name)
                        local cmdDesc = Locale.Lookup(kCommand.Description)
                        table.insert(textLines, cmdName .. ": " .. cmdDesc)
                    end
                end

                return table.concat(textLines, "[NEWLINE]")
            end
        })
        table.insert(contentRows, detailsRow)
    end

    local buttons = {}

    local lookAtBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHeroLookAt"), "Button", {
        Label = function() return Controls.LookAtHeroButton:GetText() or "" end,
        HiddenPredicate = function() return Controls.LookAtHeroButton:IsHidden() end
    })
    lookAtBtn:On("activate", function() Controls.LookAtHeroButton:DoLeftClick() end)

    local continueBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIHeroContinue"), "Button", {
        Label = function() return Controls.ContinueButton:GetText() or "" end,
    })
    continueBtn:On("activate", function() Controls.ContinueButton:DoLeftClick() end)
    table.insert(buttons, continueBtn)
    table.insert(buttons, lookAtBtn)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.EventTitle:GetText() or "" end,
        buttons,
        contentRows,
        1
    )

    if not m_dialog then return end
    mgr:Push(m_dialog)
end

Open = WrapFunc(Open, function(orig)
    orig()
    if not mgr then return end
    BuildAccessibleHeroDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveAccessibleHeroDialog()
    m_CachedHeroClass = -1
    m_CachedPopupType = ""
    orig()
end)

OnPlayerDiscoveredHero = WrapFunc(OnPlayerDiscoveredHero, function(orig, ePlayer, eClass, eSourceType, eSourceID)
    if ePlayer == Game.GetLocalPlayer() then
        m_CachedHeroClass = eClass
        m_CachedPopupType = "DISCOVERED"
    end
    orig(ePlayer, eClass, eSourceType, eSourceID)
end)

OnUnitKilledLifespanExpired = WrapFunc(OnUnitKilledLifespanExpired, function(orig, iPlayerID, eHeroClass, x, y)
    if iPlayerID == Game.GetLocalPlayer() then
        m_CachedHeroClass = eHeroClass
        m_CachedPopupType = "EXPIRED"
    end
    orig(iPlayerID, eHeroClass, x, y)
end)

OnUnitDamageChanged = WrapFunc(OnUnitDamageChanged, function(orig, iPlayerID, iUnitID, iDamage)
    if iDamage >= 100 and iPlayerID == Game.GetLocalPlayer() then
        local pPlayer = Players[iPlayerID]
        local pUnit = pPlayer and pPlayer:GetUnits():FindID(iUnitID)
        if pUnit then
            local eHeroClass = pUnit:GetHeroClassType()
            if eHeroClass ~= -1 then
                m_CachedHeroClass = eHeroClass
                m_CachedPopupType = "KILLED"
            end
        end
    end
    orig(iPlayerID, iUnitID, iDamage)
end)


OnLookAtHeroButton = WrapFunc(OnLookAtHeroButton, function(heroX, heroY)
    orig(heroX, heroY)
    local plot = Map.GetPlot(heroX, heroY)
    if plot then
        LuaEvents.CAICursorMoveTo(plot:GetIndex())
    end
end)
OnInputHandler = WrapFunc(OnInputHandler, function(orig, pInputStruct)
    if mgr and m_dialog and mgr:GetTop() == m_dialog and not ContextPtr:IsHidden() then
        local handled = mgr:HandleInput(pInputStruct)
        if handled then return handled end
    end
    return orig(pInputStruct)
end)
ContextPtr:SetInputHandler(OnInputHandler, true)
