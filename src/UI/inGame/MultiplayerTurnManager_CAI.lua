include("caiUtils")
include("MultiplayerTurnManager")

Events.RemotePlayerTurnEnd.Remove(CheckWaitingForYou);
CheckWaitingForYou = WrapFunc(CheckWaitingForYou, function(orig)
    orig()
    local localPlayer = Players[Game.GetLocalPlayer()]
    if (GameConfiguration.IsNetworkMultiplayer() and localPlayer ~= nil and localPlayer:IsTurnActive() and Game.GetActivePlayerCount() == 1) then
        Speak(Controls.YourTurnLabel:GetText() or "")
    end
end)

Events.RemotePlayerTurnEnd.Add(CheckWaitingForYou);
