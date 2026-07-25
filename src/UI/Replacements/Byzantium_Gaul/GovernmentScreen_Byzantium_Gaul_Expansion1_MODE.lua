-- Copyright 2020, Firaxis Games
include("GovernmentScreen_Expansion1");

XP1_GetPolicyBGTexture = GetPolicyBGTexture;
XP1_PopulateLivePlayerData = PopulateLivePlayerData;
XP1_RealizeFilterTabs = RealizeFilterTabs;

-- ===========================================================================
function FilterGoldenPolicies(policy)
    local policyDef:table = GameInfo.Policies_XP1[policy.PolicyHash];
    if policyDef ~= nil and policyDef.RequiresGoldenAge then
        return true;
    end
    return false;
end

-- ===========================================================================
function GetPolicyBGTexture(policyType)
	local expansionPolicy:table = GameInfo.Policies_XP1[policyType];
	if expansionPolicy and expansionPolicy.RequiresGoldenAge then
		return "Governments_GoldenCard";
	end
	return XP1_GetPolicyBGTexture(policyType);
end

-- ===========================================================================
function PopulateLivePlayerData( ePlayer:number )
	
	if ePlayer == PlayerTypes.NONE then
		return;
	end

	XP1_PopulateLivePlayerData(ePlayer);

	if(ePlayer == Game.GetLocalPlayer() and m_kUnlockedPolicies) then
		local eraTable:table = Game.GetEras();
		if eraTable:HasGoldenAge(ePlayer) and Game.GetCurrentGameTurn() == eraTable:GetCurrentEraStartTurn() then
			for policyType, isUnlocked in pairs(m_kUnlockedPolicies) do
				if isUnlocked then
					local expansionPolicy:table = GameInfo.Policies_XP1[policyType];
					if expansionPolicy and expansionPolicy.RequiresGoldenAge then
						m_kNewPoliciesThisTurn[policyType] = true;
					end
				end
			end
		end
	end 
end

-- ===========================================================================
function RealizeFilterTabs()
    XP1_RealizeFilterTabs();
    CreatePolicyTabButton("LOC_GOVT_FILTER_GOLDEN", FilterGoldenPolicies);
end
