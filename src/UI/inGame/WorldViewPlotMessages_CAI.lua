include("caiUtils")
include("WorldViewPlotMessages")



AddMessage = WrapFunc(AddMessage, function(orig, messageType, delay, plotIndex, text, turnAdded)
    orig(messageType, delay, plotIndex, text, turnAdded)
    if messageType == EventSubTypes.DAMAGE then return end
    local plot = Map.GetPlotByIndex(plotIndex)
    local shouldSpeak = false
    local improvementIndex = plot:GetImprovementType()
    local improvementInfo = improvementIndex ~= nil and GameInfo.Improvements[improvementIndex]
    if improvementInfo ~= nil then
        if improvementInfo.Goody then
            -- We queue goodyhut messages because there is no way to gate them by units at this moment. Use a goodyhut reward event to speak and clear the variable
            m_Queued = { message = text, location = { x = plot:GetX(), y = plot:GetY() } }
        elseif improvementInfo.ImprovementType == "IMPROVEMENT_BARBARIAN_CAMP" then
            --these we can speak imediatly
            if text:find("%[COLOR_FLOAT_GOLD%]") then shouldSpeak = true end
        end
    end
    if shouldSpeak then
        LuaEvents.CAIAppendToMessageBuffer(text, "notification", { x = plot:GetX(), plot:GetY() })
    end
end)

function OnGoodyHutReward(playerID, unitID, goodyTypeHash, goodySubTypeHash)
    if playerID == Game.GetLocalPlayer() and m_Queued ~= nil and m_Queued ~= "" then
        LuaEvents.CAIAppendToMessageBuffer(m_Queued.message, "notification", m_Queued.location)
        m_Queued = nil
    end
end

Events.GoodyHutReward.Add(OnGoodyHutReward)
