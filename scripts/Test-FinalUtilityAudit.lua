-- Shared contracts retained by the final audit; optional pre-change source directory.
local H = dofile('scripts/test-support/WidgetHarness.lua')
local mgr = H.CreateManager()
dofile('src/UI/shared/CAISetupParameters.lua')
dofile('src/UI/inGame/CAIGameState.lua')
local checks = 0
local function check(value, message) checks = checks + 1; assert(value, message) end
Locale.Lookup = function(value) return 'localized:' .. value end
Locale.ToNumber = function(value, pattern) return pattern .. ':' .. value end
local P = CAISetupParameters
local values = { false, true, 0, 1, '1', {}, {Value=1}, {Value=2}, {QueryId=1,QueryIndex=1},
    {QueryId=1,QueryIndex=2}, {QueryId=2,QueryIndex=1}, {QueryIndex=1}, {Value=1,QueryId=1,QueryIndex=1} }
check(P.ValueMatches(nil,nil), 'nil identity')
check(not P.ValueMatches(nil,{}), 'nil and table differ')
check(P.ValueMatches({Value=1},{Value=1}), 'values match')
check(not P.ValueMatches({Value=1},{Value='1'}), 'value types preserved')
check(P.ValueMatches({QueryId=1},{QueryId=1}), 'absent query indexes match')
check(not P.ValueMatches({QueryId=1},{Value=1}), 'query identity has priority')
check(P.ValueMatches({QueryId=1,QueryIndex=2,Value=1},{QueryId=1,QueryIndex=2,Value=9}), 'query identity ignores value')
check(P.Compare({SortIndex=1,Name='z'},{SortIndex=2,Name='a'}), 'sort index precedes label')
check(P.Compare({Name='a'},{SortIndex=0,Name='b'}), 'missing sort index defaults to zero')
check(not P.Compare({},{}), 'equal sort is strict')
for _, value in ipairs({{}, {Invalid=false}, {Invalid=true}, {Invalid=true,InvalidReason=''}, {Invalid=true,InvalidReason='reason'}}) do
    local expected = not value.Invalid and '' or value.InvalidReason == '' and ''
        or 'localized:' .. (value.InvalidReason or 'LOC_SETUP_ERROR_INVALID_OPTION')
    check(P.InvalidReason(value)==expected, 'invalid reason fallback and empty text')
end
check(P.InvalidReason(nil)=='', 'absent parameter')
for _, value in ipairs({0, -3.5, 'text', false}) do
    check(CAIText.FormatNumberOrText(value)==(type(value)=='number' and '#,###.##:'..value or tostring(value)), 'number/text format')
end
check(CAIText.FormatNumberOrText(nil)=='nil', 'nil display preserved')
check(CAIText.SafeKey('sound: a-b')=='sound__a_b', 'setting identifier sanitation')
check(CAIText.SafeKey(false)=='', 'false identifier fallback')
dofile('src/UI/shared/CAISettings.lua')
local configValue
CAI.GetConfigValue=function(section,key,default)
    assert(section=='UI' and key=='ReplayGraphGroupByValue' and default=='false')
    return configValue
end
for _, value in ipairs({'true','TRUE','1','yes','on',true,1,'false','0','',false,0}) do
    configValue=value
    local normalized=tostring(value):lower()
    check(CAISettings.ReadConfigBool('UI','ReplayGraphGroupByValue')==
        (normalized=='true' or normalized=='1' or normalized=='yes' or normalized=='on'),'raw config bool parsing')
end
configValue=nil; check(not CAISettings.ReadConfigBool('UI','ReplayGraphGroupByValue'),'missing raw flag')
local written
CAI.SetConfigValue=function(section,key,value) written=section..':'..key..':'..value end
CAISettings.WriteConfigBool('UI','ReplayGraphGroupByValue',true)
check(written=='UI:ReplayGraphGroupByValue:true','raw true serialization')
CAISettings.WriteConfigBool('UI','ReplayGraphGroupByValue',false)
check(written=='UI:ReplayGraphGroupByValue:false','raw false serialization')
CAI.GetConfigValue=nil; CAI.SetConfigValue=nil
check(not CAISettings.ReadConfigBool('UI','ReplayGraphGroupByValue'),'unavailable config reader')
check(pcall(CAISettings.WriteConfigBool,'UI','ReplayGraphGroupByValue',true),'unavailable config writer')
Game = {}
check(CAIGameState.GetReligionName(nil)==nil, 'no religion id')
check(CAIGameState.GetReligionName(-1)==nil, 'negative religion id')
check(CAIGameState.GetReligionName(1)==nil, 'religion API unavailable')
Game.GetReligion=function() return nil end
check(CAIGameState.GetReligionName(1)==nil, 'religion object unavailable')
Game.GetReligion=function() return {} end
check(CAIGameState.GetReligionName(1)==nil, 'name API unavailable')
local name='first'
Game.GetReligion=function() return {GetName=function(_,id) check(id==1,'religion id forwarded'); return name end} end
check(CAIGameState.GetReligionName(1)=='localized:first','religion name localized')
name='second'; check(CAIGameState.GetReligionName(1)=='localized:second','name read live')
name=''; check(CAIGameState.GetReligionName(1)==nil,'empty name omitted')
Game.GetReligion=function() error('religion failure') end
check(not pcall(CAIGameState.GetReligionName,1),'religion failures propagate')
-- Use both actual widgets so their helper wiring is exercised.
for _, kind in ipairs({'TreeItem','SubMenu'}) do
    local root=mgr:CreateWidget('audit_'..kind,kind,{})
    local child=mgr:CreateWidget('audit_child_'..kind,'TreeItem',{})
    local leaf=mgr:CreateWidget('audit_leaf_'..kind,'Button',{})
    root:AddChild(child); child:AddChild(leaf)
    root.IsExpanded=true; child.IsExpanded=true
    child._lastFocusedChild=leaf; child._lastFocusedKey='saved-key'
    local events=0; child:On('collapsed',function() events=events+1 end)
    root:Collapse(true)
    check(not root.IsExpanded and not child.IsExpanded,kind..' collapse descends')
    check(child._lastFocusedChild==nil,kind..' descendant child cache cleared')
    check(child._lastFocusedKey=='saved-key',kind..' key cache preserved')
    check(events==0,kind..' descendants collapse silently')
end
-- Optional differential verification against real removed frontend helpers.
if arg[1] then
    local function read(path) local f=assert(io.open(path,'rb')); local s=f:read('a'):gsub('\r\n','\n'); f:close(); return s end
    local function previous(file,name)
        local s=read(arg[1]..'/audit-before-'..file)
        local a=assert(s:find('local function '..name..'(',1,true)); local b=assert(s:find('\nend',a,true))
        return assert(load(s:sub(a,b+3)..'\nreturn '..name,'@prior '..name,'t',setmetatable({CAI_Lookup=Locale.Lookup},{__index=_G})))()
    end
    for _, file in ipairs({'ScenarioSetup.lua','HostGame.lua','StagingRoom.lua'}) do
        local old=previous(file,'CAI_ValueMatches')
        for _,a in ipairs(values) do for _,b in ipairs(values) do
            check(P.ValueMatches(a,b)==old(a,b),file..' value matching preserved')
        end end
    end
    local records={{},{Name='a'},{Name='b',SortIndex=0},{Name='z',SortIndex=-1},{Name='a',SortIndex=2}}
    for _, pair in ipairs({{'AdvancedSetup.lua','CAI_SortParams'},{'ScenarioSetup.lua','CAI_SortParameters'},{'HostGame.lua','CAI_SortParams'}}) do
        local old=previous(pair[1],pair[2])
        for _,a in ipairs(records) do for _,b in ipairs(records) do check(P.Compare(a,b)==old(a,b),'sort preserved') end end
    end
    for _, pair in ipairs({{'AdvancedSetup.lua','src/UI/frontEnd/'},{'ScenarioSetup.lua','src/UI/frontEnd/'},
        {'HostGame.lua','src/UI/frontEnd/Multiplayer/'},{'StagingRoom.lua','src/UI/frontEnd/Multiplayer/'},
        {'GameSummaries_GameDetails.lua','src/UI/frontEnd/'},{'GameSummaries.lua','src/UI/frontEnd/'},
        {'Lobby.lua','src/UI/frontEnd/Multiplayer/'}}) do
        local old=read(arg[1]..'/audit-before-'..pair[1]); local current=read(pair[2]..pair[1])
        local function outside(s)
            local a=assert(s:find('--#Accessibility integration',1,true)); local b=assert(s:find('--#End of accessibility integration',1,true))
            return s:sub(1,a-1)..s:sub(b)
        end
        check(outside(old)==outside(current),pair[1]..' vanilla source unchanged')
    end
end
print('Final utility audit: '..checks..' assertions passed')
