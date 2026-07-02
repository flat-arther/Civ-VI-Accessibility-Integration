include("caiUtils")
include("RockBandPopup")
local mgr = ExposedMembers.CAI_UIManager

local m_dialog = nil ---@type UIWidget|nil

local function RemoveRockBandDialog()
    if not mgr or not m_dialog then return end
    mgr:RemoveFromStack(m_dialog:GetId())
    m_dialog = nil
end

local function BuildRockBandDialog()
    RemoveRockBandDialog()
    if not mgr then return end

    local contentRows = {}

    local tierInfoRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRockBandTierInfo"), "StaticText", {
        Label = function()
            local parts = {}
            local title = Controls.TierTitle:GetText() or ""
            local level = Controls.TierLevel:GetText() or ""
            local desc = Controls.TierDescription:GetText() or ""

            if title ~= "" then table.insert(parts, title) end
            if level ~= "" then table.insert(parts, level) end
            if desc ~= "" then table.insert(parts, desc) end

            return table.concat(parts, ", ")
        end,
    })
    table.insert(contentRows, tierInfoRow)

    local rewardsInfoRow = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRockBandRewardsInfo"), "StaticText", {
        Label = function()
            local parts = {}

            local tourism = Controls.TourismTotal:GetText() or "0"
            table.insert(parts, tourism .. " " .. Locale.Lookup("LOC_ROCK_CONCERT_RESULT_TOURISM"))

            local albums = Controls.AlbumsSold:GetText() or "0"
            table.insert(parts, albums .. " " .. Locale.Lookup("LOC_ROCK_CONCERT_RESULT_ALBUMS"))


            if not Controls.LevelUpGroup:IsHidden() then
                table.insert(parts, Locale.Lookup("LOC_ROCK_CONCERT_RESULT_LEVEL_UP"))
            end

            if not Controls.PromotionGroup:IsHidden() then
                table.insert(parts, Locale.Lookup("LOC_ROCK_CONCERT_RESULT_PROMOTION"))
            end

            if not Controls.DiedGroup:IsHidden() then
                table.insert(parts, Locale.Lookup("LOC_ROCK_CONCERT_RESULT_UNIT_LOST"))
            end

            return table.concat(parts, ", ")
        end,
    })
    table.insert(contentRows, rewardsInfoRow)

    local buttons = {}
    local closeBtn = mgr:CreateWidget(mgr:GenerateWidgetId("CAIRockBandClose"), "Button", {
        Label = function() return Locale.Lookup("LOC_CONTINUE") end,
    })
    closeBtn:On("activate", function() Controls.CloseButton:DoLeftClick() end)
    table.insert(buttons, closeBtn)

    m_dialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Controls.HeaderLabel:GetText() or "" end,
        buttons,
        contentRows,
        1
    )

    if not m_dialog then return end
    mgr:Push(m_dialog, { priority = PopupPriority.Medium })
end

Open = WrapFunc(Open, function(orig, ownerID, unitID, resultID, totalTourism)
    orig(ownerID, unitID, resultID, totalTourism)
    if not mgr then return end
    BuildRockBandDialog()
end)

Close = WrapFunc(Close, function(orig)
    RemoveRockBandDialog()
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
