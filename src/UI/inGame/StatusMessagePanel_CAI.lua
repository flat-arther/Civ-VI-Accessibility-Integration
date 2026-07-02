include("caiUtils")
include("StatusMessagePanel")

OnStatusMessage = WrapFunc(OnStatusMessage, function(orig, message, displayTime, type, subType)
    orig(message, displayTime, type, subType)
    Speak(message)
end)
