-- Optional baseline directory compares old screen helpers and writes their
-- output fixture. Normal verification needs only the committed fixture.
local H = dofile("scripts/test-support/WidgetHarness.lua")
local mgr=H.CreateManager()
include("CAIColumns")
include("CAIDescriptors")
Locale.Lookup=function(tag) assert(tag~=nil,"required localization tag"); return "loc:" .. tag end
local count=0
local function check(value,label) count=count+1; assert(value,label) end
local function read(path)
    local f=assert(io.open(path,"rb")); local s=f:read("a"); f:close(); return (s:gsub("\r\n","\n"))
end
local function equalArray(a,b)
    if #a~=#b then return false end
    for i,v in ipairs(a) do if v~=b[i] then return false end end
    return true
end
local function oldFunction(source,name)
    local definition=assert(source:match("local function " .. name .. "%b()%s*.-\nend"),name)
    return definition
end
-- Exercise the production domain selectors as well as the shared walker.
local bannerSource=read("src/UI/inGame/CityBannerManager_CAI.lua")
local banner=assert(load(oldFunction(bannerSource,"BuildBucketKeys") .. "\nreturn BuildBucketKeys","@banner selector"))()
local action={city={"city"},district={default={"default"},special={"special"},barbarian_clan={"clan"}}}
check(equalArray(banner({kind="city"},action),{"city"}),"city descriptor selection")
check(equalArray(banner({kind="district",bannerType="special"},action),{"special"}),"specific district descriptor")
check(equalArray(banner({kind="district",bannerType="other"},action),{"default"}),"default district descriptor")
check(equalArray(banner({kind="barbarian_clan",bannerType="special"},action),{"clan"}),"clan does not use district fallback")
check(#banner(nil,action)==0 and #banner({},nil)==0,"absent banner context or action")
check(#banner({kind="district"},{city={"unused"}})==0,"absent district definitions")
local ctx={enabled=true,tag="live"}
local calls=0
local groups={ dynamic=function(c) calls=calls+1; return {c.tag,{keys={"nested","nested"}}} end }
local definitions={"first",false,42,{when=function(c) return c.enabled end,keys={"conditional",{bucket="dynamic"}}},
    {when=function() return false end,keys={"excluded"}}, {key="single",keys={"shadowed"},bucket="dynamic"},
    {bucket="missing"}, "last"}
local result={"prefix"}
check(CAIDescriptors.AppendKeys(result,ctx,definitions,groups)==result,"append keeps output identity")
check(equalArray(result,{"prefix","first","conditional","live","nested","nested","single","last"}),"ordered nested groups, duplicates and field precedence")
check(calls==1,"only included dynamic reader executes")
ctx.enabled=false
check(equalArray(CAIDescriptors.AppendKeys({},ctx,definitions,groups),{"first","single","last"}),"false condition excludes nested readers")
check(calls==1,"excluded dynamic reader not queried")
ctx.enabled=true; ctx.tag="changed"
check(CAIDescriptors.AppendKeys({},ctx,definitions,groups)[3]=="changed","readers use live context")
check(equalArray(CAIDescriptors.AppendKeys({},ctx,definitions),{"first","conditional","single","last"}),"banner does not resolve plot groups")
check(CAIDescriptors.AppendKeys(result,ctx,nil)==result,"absent optional definitions")
check(equalArray(CAIDescriptors.AppendKeys({},ctx,{{key=false}}),{false}),"nonnil key retained")
check(#CAIDescriptors.AppendKeys({},ctx,{{keys={},bucket="dynamic"}},groups)==0,"empty keys take precedence over bucket")
check(not pcall(CAIDescriptors.AppendKeys,{},ctx,{{when=function() error("predicate") end}}),"predicate errors propagate")
check(not pcall(CAIDescriptors.AppendKeys,{},ctx,{{bucket="bad"}},{bad=function() error("reader") end}),"reader errors propagate")
local plotSource=read("src/UI/inGame/PlotToolTip_CAI.lua")
local plotEnv=setmetatable({PlotInfoBucketHelpers=groups},{__index=_G})
local plot=assert(load(oldFunction(plotSource,"BuildPlotInfoBucket") .. "\nreturn BuildPlotInfoBucket","@plot selector","t",plotEnv))()
check(equalArray(plot(ctx,definitions),CAIDescriptors.AppendKeys({},ctx,definitions,groups)),"plot binds dynamic group registry")
if arg[1] then
    for _, screen in ipairs({{"CityBannerManager_CAI","AppendBucketKeys"},{"PlotToolTip_CAI","AppendPlotInfoBucketKeys"}}) do
        local source=read(arg[1] .. "/" .. screen[1] .. ".lua")
        local old=assert(load(oldFunction(source,screen[2]) .. "\nreturn " .. screen[2],"@descriptor baseline","t",plotEnv))()
        for _, enabled in ipairs({false,true}) do
            for _, tag in ipairs({"one","two"}) do
                ctx.enabled,ctx.tag=enabled,tag
                check(equalArray(old({},ctx,definitions),CAIDescriptors.AppendKeys({},ctx,definitions,screen[1]=="PlotToolTip_CAI" and groups or nil)),"legacy descriptor comparison")
            end
        end
    end
end
local function currentCall(source,index)
    local n=0
    for call in source:gmatch("CAIColumns%.BuildSortOptions%b()") do
        n=n+1; if n==index then return "return " .. call end
    end
    error("Missing migrated caller " .. index)
end
local cases={
    {"CityStates_CAI","BuildTreeSortOptions",1},
    {"DiplomacyRibbon_CAI","BuildSortOptions",1},
    {"DiplomacyActionView_CAI","BuildSortOptions",1},
    {"GovernorPanel_CAI","BuildTreeSortOptions",1},
    {"GovernmentScreen_ExtendedPolicyCards_CAI","BuildSortOptions",1},
    {"GreatPeoplePopup_CAI","BuildGPSortOptions",1},
    {"GreatPeoplePopup_CAI","BuildHeroSortOptions",2},
    {"ReportScreen_BetterReportsScreen_CAI","BuildUnitSortOptions",1},
    {"ReportScreen_BetterReportsScreen_CAI","BuildPolicySortOptions",2},
    {"ReportScreen_BetterReportsScreen_CAI","BuildPolicySortOptions",3},
    {"ReportScreen_BetterReportsScreen_CAI","BuildMinorSortOptions",4},
    {"ReportScreen_BetterReportsScreen_CAI","BuildMinorSortOptions",5},
    {"qd_dealpopup_CAI","BuildSortOptions",1},
    {"GlobalResourcePopup_CAI","BuildTreeSortOptions",1},
    {"CAIUnitBrowser","CAIUnitList.BuildSortOptions",1},
}
local snapshots={}
for _, case in ipairs(cases) do
    local filename,fn,index=table.unpack(case)
    local source=read("src/UI/inGame/" .. filename .. ".lua")
    for _, state in ipairs({"initial","changed","empty"}) do
        local columns={}
        if state~="empty" then
            for _, key in ipairs({"name","type","category","plain","false","number"}) do
                local sortKey=function(record) return record[key] end
                if key=="plain" then sortKey=nil elseif key=="false" then sortKey=false end
                columns[#columns+1]={key=key,header=function() return state .. ":" .. key end,
                    sortLabel=function() return "sort:" .. state .. ":" .. key end,
                    sortKey=sortKey,sortAscendingDescription="up:" .. key,sortDescendingDescription="down:" .. key}
            end
        end
        local env=setmetatable({columns=columns,m_columns=columns,m_activeColumns=columns,m_governorColumns=columns,
            m_heroColumns=columns,m_tableColumns=columns,CAIUnitList={Columns=columns},tabKey="test",
            GetUnitColumns=function() return columns end,GetPolicyColumns=function() return columns end,
            GetMinorColumns=function() return columns end,BuildOfferColumns=function(tab) assert(tab=="test"); return columns end}, {__index=_G})
        local chunk=currentCall(source,index)
        if filename=="GlobalResourcePopup_CAI" then
            chunk=oldFunction(source,fn) .. "\nreturn " .. fn .. "()"
        end
        local actual=assert(load(chunk,"@" .. filename .. " migrated sort","t",env))()
        if arg[1] then
            local old=read(arg[1] .. "/" .. filename .. ".lua")
            local legacy
            if filename=="CAIUnitBrowser" then
                legacy=assert(old:match("    function CAIUnitList%.BuildSortOptions%b()%s*.-\n    end")) .. "\nreturn CAIUnitList.BuildSortOptions()"
            else
                legacy=oldFunction(old,fn) .. "\nreturn " .. fn .. "(" .. (fn=="BuildSortOptions" and filename=="qd_dealpopup_CAI" and "tabKey" or "columns") .. ")"
                if fn=="BuildGPSortOptions" then legacy=oldFunction(old,"ResolveColumnSortLabel") .. "\n" .. legacy end
            end
            local before=assert(load(legacy,"@" .. filename .. " baseline","t",env))()
            check(#before==#actual,filename .. " option count")
            for i, option in ipairs(before) do
                check(option.label==actual[i].label and option.value.column==actual[i].value.column and option.value.ascending==actual[i].value.ascending,filename .. " option " .. i)
            end
            actual=before -- Generate the fixture from the pre-refactor implementation.
        end
        snapshots[#snapshots+1]=filename .. ":" .. fn .. ":" .. index .. ":" .. state
        for _, option in ipairs(actual) do
            snapshots[#snapshots+1]=option.label .. "\t" .. tostring(option.value.column) .. "\t" .. tostring(option.value.ascending)
        end
    end
end
local snapshot=table.concat(snapshots,"\n") .. "\n"
local fixture="scripts/test-support/column-sort-snapshots.txt"
if arg[1] then
    local f=assert(io.open(fixture,"wb")); f:write(snapshot); f:close()
else
    local expected=read(fixture)
    check(snapshot==expected,"all 15 migrated caller snapshots match pre-refactor output")
end
local live="before"
local col={key="a",header=function() return live end,sortKey=function() end,sortAscendingDescription="up",sortDescendingDescription="down"}
local policy={natural={ascending=false},separator=", "}
local opts=CAIColumns.BuildSortOptions({col},policy)
check(opts[2].label=="before, loc:up","live label initial")
live="after"; opts=CAIColumns.BuildSortOptions({col},policy)
check(opts[2].label=="after, loc:up","live label refresh")
check(CAIColumns.Find({col,{key="a"}},"a")==col,"lookup returns first matching object")
check(CAIColumns.Find({col},"missing")==nil,"lookup miss")
check(CAIColumns.Find({},nil)==nil,"empty lookup")
local dropdown=mgr:CreateWidget("column_sort_test","Dropdown",{})
local chosen
dropdown:On("value_changed",function(_,value) chosen=value end)
dropdown:SetOptions(opts); dropdown:SetSelectedIndex(3)
check(chosen.column=="a" and chosen.ascending==false,"production dropdown receives sort value")
chosen=nil; dropdown:SetSelectedIndex(2,true)
check(chosen==nil,"silent synchronization does not sort again")
col.header=function() error("header failure") end
check(not pcall(CAIColumns.BuildSortOptions,{col},policy),"header errors propagate")
print("Descriptor/columns: " .. count .. " assertions passed.")
