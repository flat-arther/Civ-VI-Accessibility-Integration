include("CAITradeOrigin")
include("caiUtils")
include("TradeOriginChooser")

-- Better Trade Screen (astog) replaces this context with a different API
-- (notably AddCity takes a city id, not a city table). Hand off to the
-- mod-specific accessibility layer and skip the vanilla wrappers below.
if IsBetterTradeScreenActive() then
    include("TradeOriginChooser_BetterTradeScreen_CAI")
    return
end

local origin = CAITradeOrigin.Create(CAI:GetUIManager(), {
    GetControls = function() return Controls end,
    OnClose = function() OnClose() end,
    Activate = function(city, button)
        if button then
            button:DoLeftClick()
        else
            LogWarn("CAI TradeOriginChooser: missing live city button; falling back to TeleportToCity")
            TeleportToCity(city)
        end
    end,
})

AddCity = WrapFunc(AddCity, function(orig, city)
    orig(city)
    origin.AddCity(city)
end)

Refresh = WrapFunc(Refresh, function(orig)
    local capture = origin.BeginRefresh()
    orig()
    origin.EndRefresh(capture)
end)

Open = WrapFunc(Open, function(orig)
    orig()
    if CAI:GetUIManager() and not ContextPtr:IsHidden() then origin.Open() end
end)

Close = WrapFunc(Close, function(orig)
    origin.Close()
    orig()
end)

OnShutdown = WrapFunc(OnShutdown, function(orig)
    origin.Close()
    orig()
end)
ContextPtr:SetShutdown(OnShutdown)
ContextPtr:SetInputHandler(origin.HandleInput, true)
