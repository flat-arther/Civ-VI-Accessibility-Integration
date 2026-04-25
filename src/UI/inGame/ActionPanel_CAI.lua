include("ActionPanel")
local endturnAction = Input.GetActionId("EndTurn")
local caiEndTurnAction = Input.GetActionId("SharedEndTurn")
ContextPtr:SetInputHandler(nil, true)
function InputActionTriggered(id)
    if id == caiEndTurnAction then
        OnInputActionTriggered(endturnAction)
    end
end

Events.InputActionTriggered.Add(InputActionTriggered)
