include("caiUtils")
include("EraProgressPanel")

local mgr = ExposedMembers.CAI_UIManager

local PANEL_ID    = "CAIEraProgress_Panel"
local TREE_ID     = "CAIEraProgress_Tree"
local HOVER_SOUND = "Main_Menu_Mouse_Over"

local m_panel = nil
local m_tree  = nil

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

local function GetNextEraTypeLabel(gameEras, playerID)
    local score = gameEras:GetPlayerCurrentScore(playerID)
    local goldenThreshold = gameEras:GetPlayerGoldenAgeThreshold(playerID)
    local darkThreshold = gameEras:GetPlayerDarkAgeThreshold(playerID)

    if score >= goldenThreshold then
        return Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE")
    elseif score >= darkThreshold then
        return Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE")
    else
        return Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE")
    end
end

local function NormalizeText(text)
    if not text then return "" end
    text = tostring(text)
    text = string.gsub(text, "%[ENDCOLOR%]", "")
    text = string.gsub(text, "%[COLOR_[^%]]+%]", "")
    text = string.gsub(text, "%[COLOR:%s*[^%]]+%]", "")
    text = string.gsub(text, "%[NEWLINE%]", ", ")
    text = string.gsub(text, "%[ICON_[^%]]+%]", "")
    text = string.gsub(text, "[,%s]+,", ",")
    text = string.gsub(text, "^[,%s]+", "")
    text = string.gsub(text, "[,%s]+$", "")
    return text
end

local function JoinNonEmpty(parts, separator)
    local out = {}
    for _, part in ipairs(parts) do
        if part and part ~= "" then
            table.insert(out, part)
        end
    end
    return table.concat(out, separator)
end

local function MakeId(prefix)
    return mgr:GenerateWidgetId(prefix)
end

local function MakeLeaf(focusKey, labelFn)
    local w = mgr:CreateWidget(MakeId("CAIEraP_"), "StaticText", {
        FocusKey = focusKey,
        Label = labelFn,
    })
    w:SetFocusSound(HOVER_SOUND)
    return w
end

local function MakeNode(focusKey, labelFn)
    local w = mgr:CreateWidget(MakeId("CAIEraP_"), "TreeItem", {
        FocusKey = focusKey,
        Label = labelFn,
    })
    w:SetFocusSound(HOVER_SOUND)
    return w
end

local function AddThresholdChildren(parent, breakdownFn)
    local pGameEras = Game.GetEras()
    local pid = Game.GetLocalPlayer()
    if pid < 0 then return end

    local baseline = pGameEras:GetPlayerThresholdBaseline(pid)
    local baselineChild = MakeLeaf("era:breakdown:baseline", function()
        return Locale.Lookup("LOC_ERA_REVIEW_POPUP_THRESHOLD_BASELINE") .. ", " .. baseline
    end)
    parent:AddChild(baselineChild)

    local breakdown = breakdownFn(pid)
    for _, source in ipairs(breakdown) do
        for sourceString, sourceValue in pairs(source) do
            local prefix = sourceValue >= 0 and "+" or ""
            local child = MakeLeaf(MakeId("era:breakdown:"), function()
                return sourceString .. ", " .. prefix .. sourceValue
            end)
            parent:AddChild(child)
        end
    end
end

local function PopPanel()
    if mgr and m_panel and mgr:GetWidgetById(PANEL_ID) then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_tree  = nil
end

local function BuildPanel()
    if not mgr then return end
    PopPanel()

    local localPlayerID = Game.GetLocalPlayer()
    if localPlayerID == nil or localPlayerID < 0 then return end

    local gameEras = Game.GetEras()
    local currentEraIndex = gameEras:GetCurrentEra()
    local isFinalEra = (currentEraIndex == gameEras:GetFinalEra())

    m_tree = mgr:CreateWidget(TREE_ID, "Tree", {})

    -- 1. Summary node (expandable, children = score breakdown)
    local summaryNode = MakeNode("era:summary", function()
        local pGameEras = Game.GetEras()
        local pid = Game.GetLocalPlayer()
        if pid < 0 then return "" end

        local eraIdx = pGameEras:GetCurrentEra()
        local eraDef = GameInfo.Eras[eraIdx]
        local eraName = Locale.Lookup("LOC_ERA_PROGRESS_THE_ERA", eraDef.Name)
        local ageName = Locale.Lookup(GetPlayerAgeKey(pGameEras, pid))
        local score = pGameEras:GetPlayerCurrentScore(pid)

        local parts = { eraName, ageName, Locale.Lookup("LOC_CAI_ERA_PROGRESS_SCORE", score) }

        local final = (eraIdx == pGameEras:GetFinalEra())
        if not final then
            local currentTurn = Game.GetCurrentGameTurn()
            local countdown = pGameEras:GetNextEraCountdown() + 1
            local minTurn, maxTurn
            if countdown > 0 then
                minTurn = countdown
                maxTurn = countdown
            else
                local inactiveLen = GlobalParameters.NEXT_ERA_TURN_COUNTDOWN
                minTurn = pGameEras:GetCurrentEraMinimumEndTurn() - currentTurn
                if minTurn < inactiveLen then minTurn = inactiveLen end
                maxTurn = pGameEras:GetCurrentEraMaximumEndTurn() - currentTurn
                if maxTurn < 0 then maxTurn = 0 end
            end
            if minTurn == maxTurn then
                table.insert(parts, Locale.Lookup("LOC_CAI_ERA_PROGRESS_TURNS_EXACT", maxTurn))
            else
                table.insert(parts, Locale.Lookup("LOC_CAI_ERA_PROGRESS_TURNS_RANGE", minTurn, maxTurn))
            end
        end

        return JoinNonEmpty(parts, ", ")
    end)
    summaryNode:SetTooltip(function()
        local text = Controls.EraEffects:GetText()
        if not text or text == "" then return "" end
        return NormalizeText(text)
    end)

    -- Score breakdown as children of summary
    local prevBreakdown = gameEras:GetPlayerPreviousEraScoreBreakdown(localPlayerID)
    local prevTotal = 0
    for _, source in ipairs(prevBreakdown) do
        for _, val in pairs(source) do
            prevTotal = prevTotal + val
        end
    end
    if prevTotal > 0 then
        local prevChild = MakeLeaf("era:score:prev", function()
            return Locale.Lookup("LOC_ERAS_PREVIOUS_ERA_TOTAL_SCORE") .. ", " .. prevTotal
        end)
        summaryNode:AddChild(prevChild)
    end

    local curBreakdown = gameEras:GetPlayerCurrentEraScoreBreakdown(localPlayerID)
    for i, source in ipairs(curBreakdown) do
        for sourceStr, sourceVal in pairs(source) do
            if sourceVal > 0 then
                local capturedStr = sourceStr
                local capturedVal = sourceVal
                local child = MakeLeaf("era:score:cur:" .. i, function()
                    return capturedStr .. ", " .. capturedVal
                end)
                summaryNode:AddChild(child)
            end
        end
    end

    m_tree:AddChild(summaryNode)

    -- 2. Threshold nodes (hidden in final era)
    if not isFinalEra then
        local isDramaticAges = HasCapability("CAPABILITY_DRAMATICAGES")

        -- Dark Age threshold
        local darkNode = MakeNode("era:threshold:dark", function()
            local pGameEras = Game.GetEras()
            local pid = Game.GetLocalPlayer()
            if pid < 0 then return "" end
            local darkThresh = pGameEras:GetPlayerDarkAgeThreshold(pid)
            local displayMax = darkThresh - 1
            if displayMax < 0 then displayMax = 0 end
            local label = Locale.Lookup("LOC_ERA_REVIEW_HAVE_DARK_AGE_LABEL") .. ", 0 - " .. displayMax
            if GetNextEraTypeLabel(pGameEras, pid) == Locale.Lookup("LOC_ERA_PROGRESS_DARK_AGE") then
                label = label .. ", " .. Locale.Lookup("LOC_CAI_ERA_PROGRESS_PROJECTED")
            end
            return label
        end)
        AddThresholdChildren(darkNode, function(pid)
            return Game.GetEras():GetPlayerDarkAgeThresholdBreakdown(pid)
        end)
        m_tree:AddChild(darkNode)

        -- Normal Age threshold (hidden in Dramatic Ages)
        if not isDramaticAges then
            local normalNode = MakeNode("era:threshold:normal", function()
                local pGameEras = Game.GetEras()
                local pid = Game.GetLocalPlayer()
                if pid < 0 then return "" end
                local darkThresh = pGameEras:GetPlayerDarkAgeThreshold(pid)
                local goldenThresh = pGameEras:GetPlayerGoldenAgeThreshold(pid)
                local label = Locale.Lookup("LOC_ERA_REVIEW_HAVE_NORMAL_AGE_LABEL") .. ", " .. darkThresh .. " - " .. (goldenThresh - 1)
                if GetNextEraTypeLabel(pGameEras, pid) == Locale.Lookup("LOC_ERA_PROGRESS_NORMAL_AGE") then
                    label = label .. ", " .. Locale.Lookup("LOC_CAI_ERA_PROGRESS_PROJECTED")
                end
                return label
            end)
            m_tree:AddChild(normalNode)
        end

        -- Golden/Heroic Age threshold
        local goldenNode = MakeNode("era:threshold:golden", function()
            local pGameEras = Game.GetEras()
            local pid = Game.GetLocalPlayer()
            if pid < 0 then return "" end
            local goldenThresh = pGameEras:GetPlayerGoldenAgeThreshold(pid)

            local goldenLabel
            if pGameEras:HasDarkAge(pid) then
                goldenLabel = Locale.Lookup("LOC_ERA_REVIEW_HAVE_HEROIC_AGE_LABEL")
            else
                goldenLabel = Locale.Lookup("LOC_ERA_REVIEW_HAVE_GOLDEN_AGE_LABEL")
            end
            local label = goldenLabel .. ", " .. goldenThresh .. "+"
            if GetNextEraTypeLabel(pGameEras, pid) == Locale.Lookup("LOC_ERA_PROGRESS_GOLDEN_AGE") then
                label = label .. ", " .. Locale.Lookup("LOC_CAI_ERA_PROGRESS_PROJECTED")
            end
            return label
        end)
        AddThresholdChildren(goldenNode, function(pid)
            return Game.GetEras():GetPlayerGoldenAgeThresholdBreakdown(pid)
        end)
        m_tree:AddChild(goldenNode)
    end

    -- 3. Civilization ages node
    local localPlayer = Players[localPlayerID]
    local aPlayers = PlayerManager.GetAliveMajors()

    local heroicPlayers = {}
    local goldenPlayers = {}
    local normalPlayers = {}
    local darkPlayers   = {}
    local unmetPlayers  = {}

    for _, pPlayer in ipairs(aPlayers) do
        local playerID = pPlayer:GetID()
        if playerID ~= localPlayerID then
            if localPlayer and localPlayer:GetDiplomacy():HasMet(playerID) then
                if gameEras:HasHeroicGoldenAge(playerID) then
                    table.insert(heroicPlayers, playerID)
                elseif gameEras:HasGoldenAge(playerID) then
                    table.insert(goldenPlayers, playerID)
                elseif gameEras:HasDarkAge(playerID) then
                    table.insert(darkPlayers, playerID)
                else
                    table.insert(normalPlayers, playerID)
                end
            else
                table.insert(unmetPlayers, playerID)
            end
        end
    end

    local hasCivs = (#heroicPlayers + #goldenPlayers + #normalPlayers + #darkPlayers + #unmetPlayers) > 0

    if hasCivs then
        local civsNode = MakeNode("era:civs", function()
            return Locale.Lookup("LOC_ERAS_CURRENT_AGE_BY_CIV")
        end)

        local function AddCivRow(playerID, ageKey)
            local playerConfig = PlayerConfigurations[playerID]
            local leaderName = Locale.Lookup(playerConfig:GetLeaderName())
            local civName = Locale.Lookup(playerConfig:GetCivilizationDescription())
            local ageName = Locale.Lookup(ageKey)
            local label = Locale.Lookup("LOC_DIPLOMACY_DEAL_PLAYER_PANEL_TITLE", leaderName, civName) .. ", " .. ageName

            local civChild = MakeLeaf("era:civ:" .. playerID, label)
            civsNode:AddChild(civChild)
        end

        local function AddUnmetRow(playerID)
            local label = Locale.Lookup("LOC_DIPLOPANEL_UNMET_PLAYER")
            local civChild = MakeLeaf("era:civ:" .. playerID, label)
            civsNode:AddChild(civChild)
        end

        for _, pid in ipairs(heroicPlayers) do AddCivRow(pid, "LOC_ERA_PROGRESS_HEROIC_AGE") end
        for _, pid in ipairs(goldenPlayers) do AddCivRow(pid, "LOC_ERA_PROGRESS_GOLDEN_AGE") end
        for _, pid in ipairs(normalPlayers) do AddCivRow(pid, "LOC_ERA_PROGRESS_NORMAL_AGE") end
        for _, pid in ipairs(darkPlayers)   do AddCivRow(pid, "LOC_ERA_PROGRESS_DARK_AGE") end
        for _, pid in ipairs(unmetPlayers)  do AddUnmetRow(pid) end

        m_tree:AddChild(civsNode)
    end

    -- Build panel
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Controls.Title:GetText() or Locale.Lookup("LOC_ERA_PROGRESS_TITLE") end,
    })
    m_panel:AddChild(m_tree)

    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Action = function()
                Close()
                return true
            end,
        },
    })
end

local function PushPanel()
    if not mgr then return end
    if not m_panel then BuildPanel() end
    if not m_panel then return end
    mgr:Push(m_panel, PopupPriority.Low)
end

-- ============================================================================
-- Lifecycle wraps
-- ============================================================================
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

Refresh = WrapFunc(Refresh, function(orig)
    orig()
    if mgr and m_panel and mgr:GetTop() == m_panel then
        mgr:Refocus()
    end
end)

-- ============================================================================
-- Input handler
-- ============================================================================
local function HandleInput(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return false
end
ContextPtr:SetInputHandler(HandleInput, true)
