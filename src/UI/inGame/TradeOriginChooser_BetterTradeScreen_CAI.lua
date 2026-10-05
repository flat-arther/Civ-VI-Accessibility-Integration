include("CAITradeOrigin")
-- Accessibility layer for the Change Origin City screen as rewritten by the
-- Better Trade Screen mod (astog). Included by TradeOriginChooser_CAI.lua when
-- that mod is active. The base context script is already included by the
-- dispatcher.
--
-- Two meaningful differences from the vanilla screen:
--   1. BTS's AddCity takes a city id (number) instead of a city table.
--   2. BTS's city button click only marks a pending new origin and shows a
--      confirm button, instead of teleporting on click like vanilla. So the
--      row activation calls TeleportToCity directly rather than DoLeftClick.
-- Everything else (the Controls.CityStack button scan, Refresh/Open/Close
-- lifecycle, TeleportToCity) matches the vanilla CAI layer.

local origin = CAITradeOrigin.Create(ExposedMembers.CAI_UIManager, {
    GetControls = function() return Controls end,
    OnClose = function() OnClose() end,
    -- BTS button clicks mark a pending origin; preserve CAI's direct relocation.
    Activate = function(city) TeleportToCity(city) end,
})

AddCity = WrapFunc(AddCity, function(orig, cityID)
    orig(cityID)
    local city = Players[Game.GetLocalPlayer()]:GetCities():FindID(cityID)
    if not city then
        LogWarn("CAI BTS TradeOriginChooser: city disappeared while capturing origin row")
        return
    end
    origin.AddCity(city)
end)

Refresh = WrapFunc(Refresh, function(orig)
    local capture = origin.BeginRefresh()
    orig()
    origin.EndRefresh(capture)
end)

Open = WrapFunc(Open, function(orig)
    orig()
    if ExposedMembers.CAI_UIManager and not ContextPtr:IsHidden() then origin.Open() end
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
