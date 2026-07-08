include("caiUtils")
include("WorldCongressBetweenTurns")

local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local m_CAIPlayerInstances = {}

LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Remove(OnShow)
OnShow = WrapFunc(OnShow, function(orig, stageNum)
    m_CAIPlayerInstances = {}

    local oldGetInstance = InstanceManager.GetInstance

    InstanceManager.GetInstance = function(self, ...)
        local instance = oldGetInstance(self, ...)
        table.insert(m_CAIPlayerInstances, instance)
        return instance
    end

    orig(stageNum)

    InstanceManager.GetInstance = oldGetInstance
end)
LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Add(OnShow)

OnHide = WrapFunc(OnHide, function(orig)
    m_CAIPlayerInstances = {}
    orig()
end)

OnWorldCongressStageChange = WrapFunc(OnWorldCongressStageChange, function(orig, playerID, stageNum)
    if playerID == Game.GetLocalPlayer() then
        m_CAIPlayerInstances = {}
    end

    orig(playerID, stageNum)
end)

function info.GetCongressStatus()
    local parts = {}

    table.insert(parts, Controls.Title:GetText() or "")
    table.insert(parts, Controls.Status:GetText() or "")
    if #m_CAIPlayerInstances > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_WC_BETWEEN_TURNS_PLAYERS"))

        for _, instance in ipairs(m_CAIPlayerInstances) do
            local name = ""
            local status = ""

            if instance.LeaderIcon and instance.LeaderIcon.Portrait then
                name = instance.LeaderIcon.Portrait:GetToolTipString() or ""
            end

            if instance.Label then
                status = instance.Label:GetText() or ""
            end

            table.insert(parts, name .. ": " .. status)
        end
    end

    return table.concat(parts, "[NEWLINE]")
end
