-- CAIWidget_GameView.lua
-- Sentinel container that swaps the input context to World on focus enter
-- and back to Shell on focus leave. Wrap the playable world in this widget so
-- gameplay key bindings receive normal input while CAI focus is on the map.

---@class GameViewWidget : ContainerWidget
GameViewWidget = setmetatable({}, { __index = ContainerWidget })
GameViewWidget.__index = GameViewWidget

---@param mgr UIScreenManager
---@param id string
---@param props? table
---@return GameViewWidget
function GameViewWidget.Create(mgr, id, props)
    local w = ContainerWidget.New(GameViewWidget)
    w.Id = id
    w.Type = "GameView"
    w.Role = "GameView"
    w.Manager = mgr
    w:SetLabel(function() return Locale.Lookup("LOC_CAI_ROLE_GAME_VIEW") end)

    w:On("focus_enter", function()
        Input.SetActiveContext(InputContext.World)
    end)
    w:On("focus_leave", function()
        Input.SetActiveContext(InputContext.Shell)
    end)

    CAIWidgetRegistry.ApplyProps(w, props)
    return w
end

CAIWidgetRegistry.Register("GameView", GameViewWidget.Create)
