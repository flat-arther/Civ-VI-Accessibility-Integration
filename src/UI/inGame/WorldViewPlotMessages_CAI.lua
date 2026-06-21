include("caiUtils")
include("WorldViewPlotMessages")

AddMessage = WrapFunc(AddMessage, function(orig, messageType, delay, plotIndex, text, turnAdded)
    orig(messageType, delay, plotIndex, text, turnAdded)
    --if messageType == EventSubTypes.DAMAGE then return end
    Speak(text)
end)
