include("caiUtils")
include("StatusMessagePanel")

AddGossip = WrapFunc(AddGossip, function(orig, subType, message, displayTime)
    orig(subType, message, displayTime)
    LuaEvents.CAIAppendToMessageBuffer(message, "gossip")
end)
