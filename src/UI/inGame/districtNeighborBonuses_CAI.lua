-- Read-only adjacency changes for existing districts around a placement preview.
-- Detailed Map Tacks' hypothetical plot records informed this approach. No pins
-- are created, and all plot state and applied modifier subjects are read live.
CAIDistrictNeighborBonuses = {}

local rulesByDistrict
local modifierEffects = {}
local relevantEffects = {
    EFFECT_DISTRICT_ADJACENCY = true,
    EFFECT_FEATURE_ADJACENCY = true,
    EFFECT_IMPROVEMENT_ADJACENCY = true,
    EFFECT_ADJUST_DISTRICT_YIELD_MODIFIER = true,
    EFFECT_ADJUST_DISTRICT_YIELD_BASED_ON_ADJACENCY_BONUS = true,
    EFFECT_ADJUST_PLAYER_FEAUTE_REQUIRED_FOR_SPECIALTY_DISTRICTS = true,
    EFFECT_ADJUST_VALID_FEATURES_DISTRICTS = true,
}

local function MatchesDistrict(actual, requested)
    if requested == nil or actual == requested then return true end
    local replacement = GameInfo.DistrictReplaces[actual]
    return replacement ~= nil and replacement.ReplacesDistrictType == requested
end

local function ReadTraits(playerID)
    local config = PlayerConfigurations[playerID]
    local traits = {}
    for row in GameInfo.CivilizationTraits() do
        if row.CivilizationType == config:GetCivilizationTypeName() then traits[row.TraitType] = true end
    end
    for row in GameInfo.LeaderTraits() do
        if row.LeaderType == config:GetLeaderTypeName() then traits[row.TraitType] = true end
    end
    return traits
end

local function GetRules(districtType)
    if rulesByDistrict == nil then
        rulesByDistrict = {}
        for row in GameInfo.District_Adjacencies() do
            local rules = rulesByDistrict[row.DistrictType] or {}
            rules[#rules + 1] = GameInfo.Adjacency_YieldChanges[row.YieldChangeId]
            rulesByDistrict[row.DistrictType] = rules
        end
    end
    return rulesByDistrict[districtType] or {}
end

local function RuleIsActive(rule, player, exclusions)
    if exclusions[rule.ID] then return false end
    if rule.PrereqTech and not player:GetTechs():HasTech(GameInfo.Technologies[rule.PrereqTech].Index) then return false end
    if rule.ObsoleteTech and player:GetTechs():HasTech(GameInfo.Technologies[rule.ObsoleteTech].Index) then return false end
    if rule.PrereqCivic and not player:GetCulture():HasCivic(GameInfo.Civics[rule.PrereqCivic].Index) then return false end
    if rule.ObsoleteCivic and player:GetCulture():HasCivic(GameInfo.Civics[rule.ObsoleteCivic].Index) then return false end
    return true
end

local function SubjectMatches(subjectID, neighbor, playerID)
    if GameEffects.GetObjectsPlayerId(subjectID) ~= playerID then return false end
    local objectType = GameEffects.GetObjectType(subjectID)
    if objectType == "LOC_MODIFIER_OBJECT_PLAYER" then return true end
    if objectType == "LOC_MODIFIER_OBJECT_DISTRICT" then
        local description = GameEffects.GetObjectString(subjectID)
        local districtID = tonumber(description:match("District:%s*(%d+)"))
        return neighbor.District ~= nil and districtID == neighbor.District:GetID()
    end
    if objectType == "LOC_MODIFIER_OBJECT_CITY" then
        local description = GameEffects.GetObjectString(subjectID)
        local cityID = tonumber(description:match("City:%s*(%d+)"))
        if cityID ~= nil then return cityID == neighbor.City:GetID() end
        -- BRS uses the untranslated city name; retain that fallback for object
        -- descriptions that do not expose a City field.
        return GameEffects.GetObjectName(subjectID) == neighbor.City:GetName()
    end
    return false
end

local function ReadModifiers(playerID)
    local modifiers = {}
    for _, instanceID in ipairs(GameEffects.GetModifiers()) do
        local effect = modifierEffects[instanceID]
        if effect == nil then
            local definition = GameEffects.GetModifierDefinition(instanceID)
            local row = GameInfo.Modifiers[definition.Id]
            -- Runtime-only modifier definitions need not have database rows.
            local dynamic = row and GameInfo.DynamicModifiers[row.ModifierType]
            effect = dynamic and relevantEffects[dynamic.EffectType] and dynamic.EffectType or false
            modifierEffects[instanceID] = effect
        end
        if effect and GameEffects.GetModifierActive(instanceID) then
            local ownerRequirements = GameEffects.GetModifierOwnerRequirementSet(instanceID)
            if ownerRequirements == nil or GameEffects.GetRequirementSetState(ownerRequirements) == "Met" then
                local subjects = {}
                for _, subjectID in ipairs(GameEffects.GetModifierSubjects(instanceID) or {}) do
                    if GameEffects.GetObjectsPlayerId(subjectID) == playerID then
                        subjects[#subjects + 1] = subjectID
                    end
                end
                if #subjects > 0 then
                    local definition = GameEffects.GetModifierDefinition(instanceID)
                    modifiers[#modifiers + 1] = {
                        ModifierId = definition.Id,
                        Effect = effect,
                        Arguments = definition.Arguments,
                        Subjects = subjects,
                    }
                end
            end
        end
    end
    return modifiers
end

local function AppliesTo(modifier, neighbor, playerID)
    if not MatchesDistrict(neighbor.Info.DistrictType, modifier.Arguments.DistrictType) then return false end
    for _, subjectID in ipairs(modifier.Subjects) do
        if SubjectMatches(subjectID, neighbor, playerID) then return true end
    end
    return false
end

local function KeepFeature(feature, district, city, modifiers)
    if not feature.Removable then return true end
    for row in GameInfo.District_RequiredFeatures() do
        if row.DistrictType == district.DistrictType and row.FeatureType == feature.FeatureType then return true end
    end
    if GameInfo.Features_XP2 then
        local expansion = GameInfo.Features_XP2[feature.FeatureType]
        if expansion and expansion.ValidDistrictPlacement then return true end
    end
    for _, modifier in ipairs(modifiers) do
        local args = modifier.Arguments
        if args.FeatureType == feature.FeatureType
            and AppliesTo(modifier, { Info = district, City = city }, city:GetOwner()) then
            if modifier.Effect == "EFFECT_ADJUST_VALID_FEATURES_DISTRICTS"
                and MatchesDistrict(district.DistrictType, args.DistrictType) then return true end
            if modifier.Effect == "EFFECT_ADJUST_PLAYER_FEAUTE_REQUIRED_FOR_SPECIALTY_DISTRICTS"
                and district.RequiresPopulation and not district.Coast then return true end
        end
    end
    return false
end

local function ReadPlot(plot, playerID)
    local feature = GameInfo.Features[plot:GetFeatureType()]
    local resource = GameInfo.Resources[plot:GetResourceType()]
    if resource and not Players[playerID]:GetResources():IsResourceVisible(resource.Hash) then resource = nil end
    local district = GameInfo.Districts[plot:GetDistrictType()]
    local improvement = GameInfo.Improvements[plot:GetImprovementType()]
    return {
        Owner = plot:GetOwner(),
        District = district and district.DistrictType ~= "DISTRICT_WONDER" and district.DistrictType or nil,
        Feature = feature and feature.FeatureType,
        Improvement = improvement and improvement.ImprovementType,
        Resource = resource and resource.ResourceType,
        ResourceClass = resource and resource.ResourceClassType,
        SeaResource = resource ~= nil and GameInfo.Terrains[plot:GetTerrainType()].Water,
    }
end

local function MatchesRule(record, rule, playerID)
    if rule.OtherDistrictAdjacent then return record.District ~= nil and record.Owner == playerID end
    if rule.AdjacentDistrict then return record.District == rule.AdjacentDistrict end
    if rule.AdjacentFeature then return record.Feature == rule.AdjacentFeature end
    if rule.AdjacentImprovement then return record.Improvement == rule.AdjacentImprovement end
    if rule.AdjacentResource then return record.Resource ~= nil end
    if rule.AdjacentSeaResource then return record.SeaResource end
    if rule.AdjacentResourceClass and rule.AdjacentResourceClass ~= "NO_RESOURCECLASS" then
        return record.ResourceClass == rule.AdjacentResourceClass
    end
    -- Terrain, rivers, self bonuses and wonders cannot change on a valid district
    -- placement tile, so those rules cancel in the before/after difference.
    return false
end

local function RuleChange(rule, ring, before, after, playerID)
    local beforeMatch = MatchesRule(before, rule, playerID) and 1 or 0
    local afterMatch = MatchesRule(after, rule, playerID) and 1 or 0
    if beforeMatch == afterMatch then return 0 end
    local count = 0
    for _, record in ipairs(ring) do
        if MatchesRule(record, rule, playerID) then count = count + 1 end
    end
    return rule.YieldChange * (math.floor((count - beforeMatch + afterMatch) / rule.TilesRequired)
        - math.floor(count / rule.TilesRequired))
end

local function AddYield(yields, yieldType, amount)
    if amount ~= 0 then yields[yieldType] = (yields[yieldType] or 0) + amount end
end

local function CalculateChanges(neighbor, ring, before, after, playerID, exclusions, modifiers)
    local changes, percentages, mirrors = {}, {}, {}
    local appliedMirrors = {}
    for _, rule in ipairs(GetRules(neighbor.Info.DistrictType)) do
        if RuleIsActive(rule, Players[playerID], exclusions) then
            AddYield(changes, rule.YieldType, RuleChange(rule, ring, before, after, playerID))
        end
    end
    for _, modifier in ipairs(modifiers) do
        if AppliesTo(modifier, neighbor, playerID) then
            local args, effect = modifier.Arguments, modifier.Effect
            if effect == "EFFECT_ADJUST_DISTRICT_YIELD_MODIFIER" then
                AddYield(percentages, args.YieldType, tonumber(args.Amount))
            elseif effect == "EFFECT_ADJUST_DISTRICT_YIELD_BASED_ON_ADJACENCY_BONUS" then
                -- Heartbeat of Steam attaches the same player-district mirror
                -- through every city. Count its definition once per recipient,
                -- after eligibility checks; additive modifiers still stack.
                if not appliedMirrors[modifier.ModifierId] then
                    appliedMirrors[modifier.ModifierId] = true
                    mirrors[#mirrors + 1] = args
                end
            elseif effect == "EFFECT_DISTRICT_ADJACENCY" or effect == "EFFECT_FEATURE_ADJACENCY"
                or effect == "EFFECT_IMPROVEMENT_ADJACENCY" then
                local rule = {
                    YieldChange = tonumber(args.Amount), TilesRequired = tonumber(args.TilesRequired) or 1,
                    OtherDistrictAdjacent = effect == "EFFECT_DISTRICT_ADJACENCY",
                    AdjacentFeature = effect == "EFFECT_FEATURE_ADJACENCY" and args.FeatureType or nil,
                    AdjacentImprovement = effect == "EFFECT_IMPROVEMENT_ADJACENCY" and args.ImprovementType or nil,
                }
                AddYield(changes, args.YieldType, RuleChange(rule, ring, before, after, playerID))
            end
        end
    end
    for yieldType, amount in pairs(changes) do
        changes[yieldType] = amount * (1 + (percentages[yieldType] or 0) / 100)
    end
    -- Mirrors read the adjusted adjacency, not other mirrored yields. This keeps
    -- Work Ethic / Hildegard independent of modifier enumeration order.
    local mirrored = {}
    for _, args in ipairs(mirrors) do
        AddYield(mirrored, args.YieldTypeToGrant, changes[args.YieldTypeToMirror] or 0)
    end
    for yieldType, amount in pairs(mirrored) do AddYield(changes, yieldType, amount) end
    return changes
end

function CAIDistrictNeighborBonuses.GetChanges(city, candidate, districtInfo)
    local playerID = city:GetOwner()
    local visibility = PlayersVisibility[playerID]
    local neighbors = {}
    for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
        local plot = Map.GetAdjacentPlot(candidate:GetX(), candidate:GetY(), direction)
        if plot and plot:GetOwner() == playerID and visibility:IsRevealed(plot:GetIndex()) then
            local district = CityManager.GetDistrictAt(plot:GetX(), plot:GetY())
            if district and not GameInfo.Districts[district:GetType()].InternalOnly then
                neighbors[#neighbors + 1] = {
                    Plot = plot, District = district, City = district:GetCity(),
                    Info = GameInfo.Districts[district:GetType()],
                }
            end
        end
    end
    if #neighbors == 0 then return {} end

    local modifiers = ReadModifiers(playerID)
    local before = ReadPlot(candidate, playerID)
    local feature = GameInfo.Features[candidate:GetFeatureType()]
    local after = {
        Owner = playerID, District = districtInfo.DistrictType,
        Feature = feature and KeepFeature(feature, districtInfo, city, modifiers) and feature.FeatureType or nil,
    }
    local exclusions, traits = {}, ReadTraits(playerID)
    for row in GameInfo.ExcludedAdjacencies() do
        if traits[row.TraitType] then exclusions[row.YieldChangeId] = true end
    end

    local records = { [candidate:GetIndex()] = before }
    local results = {}
    for _, neighbor in ipairs(neighbors) do
        local ring = {}
        for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
            local plot = Map.GetAdjacentPlot(neighbor.Plot:GetX(), neighbor.Plot:GetY(), direction)
            if plot and visibility:IsRevealed(plot:GetIndex()) then
                local index = plot:GetIndex()
                if records[index] == nil then records[index] = ReadPlot(plot, playerID) end
                ring[#ring + 1] = records[index]
            end
        end
        results[#results + 1] = {
            District = neighbor.Info, Instance = neighbor.District, City = neighbor.City, Plot = neighbor.Plot,
            Yields = CalculateChanges(neighbor, ring, before, after, playerID, exclusions, modifiers),
        }
    end
    return results
end

function CAIDistrictNeighborBonuses.GetLines(city, candidate, districtInfo)
    local lines = {}
    for _, result in ipairs(CAIDistrictNeighborBonuses.GetChanges(city, candidate, districtInfo)) do
        local yields = {}
        for row in GameInfo.Yields() do
            local amount = result.Yields[row.YieldType] or 0
            if amount ~= 0 then
                yields[#yields + 1] = Locale.Lookup("LOC_CAI_DISTRICT_NEIGHBOR_YIELD_CHANGE", amount, row.Name)
            end
        end
        if #yields > 0 then
            local name = Locale.Lookup(result.District.Name)
            if result.City:GetID() ~= city:GetID() then name = name .. " (" .. Locale.Lookup(result.City:GetName()) .. ")" end
            if result.Instance:IsPillaged() then
                name = name .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_PILLAGED_TEXT")
            elseif not result.Instance:IsComplete() then
                name = name .. " " .. Locale.Lookup("LOC_TOOLTIP_PLOT_CONSTRUCTION_TEXT")
            end
            lines[#lines + 1] = Locale.Lookup("LOC_CAI_DISTRICT_NEIGHBOR_BONUSES", name,
                table.concat(yields, ", "))
        end
    end
    return lines
end

-- Cache only static definitions/instance classifications, never displayed yields,
-- active state or subjects. Reclassify instance IDs at each placement session.
Events.InterfaceModeChanged.Add(function()
    modifierEffects = {}
end)
