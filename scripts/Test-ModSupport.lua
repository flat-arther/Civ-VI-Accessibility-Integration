-- Real query owner with engine-boundary mocks and actual screen include chains.
dofile('src/UI/shared/CAIModSupport.lua')
local count = 0
local function check(value, label)
    count = count + 1
    assert(value, label)
end
local function read(path)
    local file = assert(io.open(path, 'rb'))
    local source = file:read('a'); file:close()
    return source
end
local scenarios = {
    CivRoyale='CIV_ROYALE', Pirates='PIRATES', WarMachine='WARMACHINE',
    BlackDeath='BLACKDEATH', IndonesiaKhmer='INDONESIA_KHMER', Poland='POLAND',
    Vikings='VIKINGS', Australia='AUSTRALIA', Alexander='ALEXANDER', Nubia='NUBIA',
}
local rule, fallback, heroes
GameConfiguration = {
    GetRuleSet=function() return rule end,
    GetValue=function(key) if key=='RULESET' then return fallback end; return heroes end,
}
for name, suffix in pairs(scenarios) do
    rule = 'RULESET_SCENARIO_' .. suffix
    for other in pairs(scenarios) do
        check(CAIModSupport['Is'..other..'ScenarioActive']() == (name==other), name..' vs '..other)
    end
end
for _, value in ipairs({'RULESET_STANDARD','RULESET_EXPANSION_1','RULESET_EXPANSION_2','RULESET_CUSTOM'}) do
    rule = value
    for name in pairs(scenarios) do check(not CAIModSupport['Is'..name..'ScenarioActive'](), value..' is not '..name) end
end
rule = nil; fallback = 'RULESET_SCENARIO_PIRATES'
check(not CAIModSupport.IsPiratesScenarioActive(), 'nil ruleset remains authoritative when method exists')
GameConfiguration.GetRuleSet = nil
check(CAIModSupport.IsPiratesScenarioActive(), 'GetValue fallback')
GameConfiguration.GetValue = nil
check(CAIModSupport.GetRuleSet()==nil, 'no ruleset API')
GameConfiguration.GetRuleSet=function() return rule end
GameConfiguration.GetValue=function(key) assert(key=='GAMEMODE_HEROES'); return heroes end

local mods = {
    BetterTradeScreen='8d4fa23a-ef43-440c-8422-2bec11f8f5d7',
    BetterReportScreen='6f2888d4-79dc-415f-a8ff-f9d81d7afb53',
    ExtendedPolicyCards='382a187f-c8ba-4094-a6a7-0d5315661f33',
    QuickDeals='5aceed03-8639-4a81-8cbf-03f54d543502',
    DetailedMapTacks='4ecfcc62-5471-4435-b295-590df213e8d8',
    RealEraTracker='11B9FBBE-25BD-7E24-3909-67A060B2456C',
    Tutorial='17462E0F-1EE1-4819-AAAA-052B5896B02A',
    Babylon='8424840C-92EF-4426-A9B4-B4E0CB818049',
}
local active = {}
Modding={IsModActive=function(id) return active[id]==true end}
for name, id in pairs(mods) do
    active = {[id]=true}
    for other in pairs(mods) do
        check(CAIModSupport['Is'..other..'Active']() == (name==other), name..' vs '..other)
    end
    active = {}
    check(not CAIModSupport['Is'..name..'Active'](), name..' disable is live')
end
for _, suffix in ipairs({'240','217','231'}) do
    active = {['cb84075d-5007-4207-b662-c35a5f7be'..suffix]=true}
    check(CAIModSupport.IsBBGActive(), 'historical BBG '..suffix)
end
active = {}; check(not CAIModSupport.IsBBGActive(), 'BBG disabled')

-- Run the production screen's real bootstrap, stopping before widget construction.
local function includes(path)
    local source = read(path)
    local last = assert(source:find('local mgr', 1, true))
    local seen = {}
    local env = setmetatable({include=function(name) seen[name]=true end,
        IsExpansion1Active=function() return false end,
        IsExpansion2Active=function() return false end}, {__index=_ENV})
    assert(load(source:sub(1,last-1), '@'..path, 't', env))()
    return seen
end
for _, babylon in ipairs({false,true}) do
    for _, mode in ipairs({false,true}) do
        for _, bbg in ipairs({false,true}) do
            active = {[mods.Babylon]=babylon, ['cb84075d-5007-4207-b662-c35a5f7be240']=bbg}
            heroes = mode
            local seen = includes('src/UI/inGame/ProductionPanel_CAI.lua')
            check((seen.ProductionPanel_Babylon_Heroes==true)==(babylon and mode), 'Heroes requires its pack and mode')
            check(seen[bbg and 'ProductionPanel_BetterBalancedGame_CAIBase' or 'ProductionPanel'], 'BBG/base include preserved')
        end
    end
end
active = {['1B28771A-C749-434B-9053-D1380C553DE9']=true}; heroes=true
check(not includes('src/UI/inGame/ProductionPanel_CAI.lua').ProductionPanel_Babylon_Heroes, 'Rise and Fall is not Babylon')
local rankings = {WarMachine='WarMachine', Vikings='Vikings', Poland='Poland', IndonesiaKhmer='Indonesia_Khmer',
    BlackDeath='BlackDeath', Australia='Australia', Alexander='Alexander', Nubia='Nubia'}
active = {['cb84075d-5007-4207-b662-c35a5f7be240']=true}
for name, file in pairs(rankings) do
    rule = 'RULESET_SCENARIO_'..scenarios[name]
    local seen = includes('src/UI/inGame/WorldRankings_CAI.lua')
    check(seen['WorldRankings_'..file..'Scenario'], name..' native include')
    check(not seen.WorldRankings_BetterBalancedGame_CAIBase, name..' takes precedence over BBG')
end
rule = 'RULESET_STANDARD'
check(includes('src/UI/inGame/WorldRankings_CAI.lua').WorldRankings_BetterBalancedGame_CAIBase, 'BBG rankings selected')
active = {}
check(includes('src/UI/inGame/WorldRankings_CAI.lua').WorldRankings, 'base rankings selected')
Modding.IsModActive=function() error('registry failed') end
check(not pcall(CAIModSupport.IsQuickDealsActive), 'registry errors propagate')
-- Load complete category adapters without the retired MapInfo.IsActive aliases.
for _, scenario in ipairs({'CivRoyale', 'Pirates'}) do
    local registered
    local env = setmetatable({
        include=function() end,
        CAICivRoyaleMapInfo={}, CAIPiratesMapInfo={},
        CAIWorldScanner={RegisterCategoryDefinition=function(_, definition) registered=definition end},
    }, {__index=_ENV})
    rule = 'RULESET_SCENARIO_'..scenarios[scenario]
    local filename = scenario == 'CivRoyale' and 'civRoyale' or 'pirates'
    assert(loadfile('src/UI/inGame/WorldScanner/WorldScannerCategory_'..filename..'.lua', 't', env))()
    check(registered ~= nil, scenario..' category registered')
    for _, ruleset in ipairs({'RULESET_STANDARD', 'RULESET_EXPANSION_1', 'RULESET_EXPANSION_2',
        'RULESET_SCENARIO_CIV_ROYALE', 'RULESET_SCENARIO_PIRATES'}) do
        rule = ruleset
        check(registered.CanScan() == (ruleset == 'RULESET_SCENARIO_'..scenarios[scenario]),
            scenario..' scanner eligibility in '..ruleset)
    end
end
print('Mod support: '..count..' assertions passed')
