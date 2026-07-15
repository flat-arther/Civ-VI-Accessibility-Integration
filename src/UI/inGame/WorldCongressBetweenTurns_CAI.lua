include("caiUtils")
include("WorldCongressBetweenTurns")

local info = ExposedMembers.CAIInfo or {}
ExposedMembers.CAIInfo = info

local m_CAICongressRoster = {}

local function GetPlayerName(playerID)
    return LeaderIcon:GetToolTipString(playerID)
end

LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Remove(OnShow)
OnShow = WrapFunc(OnShow, function(orig, stageNum)
    m_CAICongressRoster = {}
    local playerInstances = {}

    local oldGetInstance = InstanceManager.GetInstance

    InstanceManager.GetInstance = function(self, ...)
        local instance = oldGetInstance(self, ...)
        table.insert(playerInstances, instance)
        return instance
    end

    orig(stageNum)

    InstanceManager.GetInstance = oldGetInstance

    local players = PlayerManager.GetAliveMajors()
    if #playerInstances ~= #players then
        print("CAI World Congress between-turn roster mismatch: "
            .. tostring(#players) .. " players, " .. tostring(#playerInstances) .. " rows")
    end

    for i, player in ipairs(players) do
        local instance = playerInstances[i]
        if instance then
            table.insert(m_CAICongressRoster, {
                PlayerID = player:GetID(),
                Instance = instance,
            })
        end
    end
end)
LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Add(OnShow)

OnHide = WrapFunc(OnHide, function(orig)
    m_CAICongressRoster = {}
    orig()
end)

function info.GetCongressStatus()
    local parts = {}

    table.insert(parts, Controls.Title:GetText() or "")
    table.insert(parts, Controls.Status:GetText() or "")
    if #m_CAICongressRoster > 0 then
        table.insert(parts, Locale.Lookup("LOC_CAI_WC_BETWEEN_TURNS_PLAYERS"))

        for _, entry in ipairs(m_CAICongressRoster) do
            table.insert(parts, GetPlayerName(entry.PlayerID) .. ": " .. (entry.Instance.Label:GetText() or ""))
        end
    end

    return table.concat(parts, "[NEWLINE]")
end
