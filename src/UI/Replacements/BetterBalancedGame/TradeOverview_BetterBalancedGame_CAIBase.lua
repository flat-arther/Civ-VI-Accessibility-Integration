-- ===========================================================================
-- CAI VENDORED COPY -- DO NOT EDIT BY HAND.
-- Verbatim copy of Better Balanced Game's ui/replacements/tradeoverview_bbg.lua
-- (BBG workshop item 2312050357). BBG does export this file via <ImportFiles>,
-- but we vendor it (as with the other BBG bases) so CAI does not depend on BBG's
-- import criteria and load order. Registered in CAI's <Files> +
-- <ImportFiles id="CAIInGame">, and included from TradeOverview_CAI.lua when BBG
-- is active, so BBG's Available-Routes grouping is present for the CAI
-- accessibility layer to wrap. Re-copy from BBG when BBG updates this file.
-- ===========================================================================

include("TradeOverview");

print("TradeOverview BBG overide loaded")

-- Show Available Routes Tab
function ViewAvailableRoutes()
	-- Update Tabs
	SetMyRoutesTabSelected(false);
	SetRoutesToCitiesTabSelected(false);
	SetAvailableRoutesTabSelected(true);

	local localPlayerID = Game.GetLocalPlayer();
	if (localPlayerID == -1) then
		return;
	end

	local tradeManager:table = Game.GetTradeManager();

	-- Update Header
	Controls.HeaderLabel:SetText(Locale.ToUpper("LOC_TRADE_OVERVIEW_AVAILABLE_ROUTES"));
	Controls.ActiveRoutesLabel:SetHide(true);

	-- Determine if a trade unit in a city can trade with any other player cities
	local pLocalPlayer:table = Players[localPlayerID];
	local pLocalPlayerCities:table = pLocalPlayer:GetCities();
	local hasTradeRouteWithPlayer:boolean = false;
	local hasTradeRouteWithCityStates:boolean = false;
	local players:table = Game.GetPlayers();
	for i, destinationPlayer in ipairs(players) do
		local playerHeader:table = nil;
		hasTradeRouteWithPlayer = false;

		local cities:table = destinationPlayer:GetCities();
		for j, destinationCity in cities:Members() do
            for _, originCity in pLocalPlayerCities:Members() do
	            if tradeManager:CanStartRoute(originCity:GetOwner(), originCity:GetID(), destinationCity:GetOwner(), destinationCity:GetID(), true) then
					-- Add Civ/CityState Header
					local pPlayerInfluence:table = destinationPlayer:GetInfluence();
					if not pPlayerInfluence:CanReceiveInfluence() then
						-- If first available route with this city add a city header
						if not hasTradeRouteWithPlayer then
							hasTradeRouteWithPlayer = true;
							CreatePlayerHeader(destinationPlayer);
						end
					else
						-- If first available route to a city state then add a city state header
						if not hasTradeRouteWithCityStates then
							hasTradeRouteWithCityStates = true;
							CreateCityStateHeader();
						end
					end
					
					-- Add Route
					AddRoute(pLocalPlayer, originCity, destinationPlayer, destinationCity, -1);
				end
			end
		end
	end
end

