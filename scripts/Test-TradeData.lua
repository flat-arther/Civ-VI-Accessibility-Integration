local H = dofile("scripts/test-support/TradeHarness.lua")
local mgr,s = H.Create("Route",false)
dofile("src/UI/inGame/CAITradeData.lua")
dofile("src/UI/shared/CAICapturedDropdown.lua")
local count=0
local function check(actual,expected,label)
    count=count+1; assert(actual==expected,label .. ": " .. tostring(actual))
end
check(CAITradeData.ResolveCity(0,11),s.origin,"city lookup")
check(CAITradeData.ResolveCity(9,11),nil,"missing player")
check(CAITradeData.ResolveCity(0,99),nil,"missing city")
check(CAITradeData.HasTradeQuest(1),true,"active quest")
check(CAITradeData.HasTradeQuest(0),false,"inactive quest")
local getQuests=Game.GetQuestsManager
Game.GetQuestsManager=function() return nil end
check(CAITradeData.HasTradeQuest(1),false,"no quest manager")
Game.GetQuestsManager=getQuests
GameInfo.Quests.QUEST_SEND_TRADE_ROUTE=nil
check(CAITradeData.HasTradeQuest(1),false,"missing quest definition")
check(CAITradeData.DestinationName(s.destination),"DESTINATION, LOC_CAI_CITY_STATUS_CAPITAL","major capital")
Players[1].IsMajor=function() return false end
check(CAITradeData.DestinationName(s.destination),"DESTINATION","city-state capital suffix excluded")
check(CAITradeData.BuildAggregateYields({kYieldValues={2,-1,0},MajorityReligion=0,ReligionPressure=0}),
    "+2.0 FOOD[NEWLINE]-1.0 PRODUCTION","vanilla positive and negative yields")
check(CAITradeData.BuildAggregateYields({kYieldValues={0},MajorityReligion=1,ReligionPressure=3}),
    "LOC_CAI_TRADE_ROUTE_RELIGION_PRESSURE:3:religion","religion pressure")
GameInfo.Religions[1]=nil
check(CAITradeData.BuildAggregateYields({kYieldValues={},MajorityReligion=1,ReligionPressure=3}),"","missing religion")
local calls={}
local function getter(side)
    return function(info,tooltip)
        calls[#calls+1]=side .. ":" .. tostring(tooltip) .. ":" .. info.key
        return {[0]=5,[1]=0,[2]=-2,[4]=3,[5]=9},{[0]="first",[2]="negative",[4]=side,[5]="out of range"}
    end
end
local summary=CAITradeData.CreateYieldSummary(getter("origin"),getter("dest"),0,4)
check(summary({key="a"},false),"first[NEWLINE]origin","BTS positive sparse yields and bounds")
check(summary({key="b"},true),"first[NEWLINE]dest","BTS destination getter")
check(calls[1],"origin:true:a","origin tooltip flag and route")
check(calls[2],"dest:true:b","destination tooltip flag and route")
check(CAITradeData.RouteTooltip(s.origin,s.destination,"",""),"LOC_CAI_TRADE_ROUTE_DISTANCE:10","empty summaries")
check(CAITradeData.RouteTooltip(s.origin,s.destination,"food","gold"),
    "LOC_CAI_TRADE_ROUTE_DISTANCE:10[NEWLINE]LOC_ROUTECHOOSER_RECEIVES_RESOURCE:same food[NEWLINE]LOC_ROUTECHOOSER_RECEIVES_RESOURCE:destination gold","both summaries")
check(CAITradeData.BuildPlayerHeaderTooltip(0),"","own player tooltip empty")
check(CAITradeData.BuildPlayerHeaderTooltip(1),"LOC_TRADE_OVERVIEW_TOOLTIP_TOURISM_BONUS +30.0%[NEWLINE]LOC_TRADE_OVERVIEW_TOOLTIP_DIPLOMATIC_VIS_BONUS","foreign active trade bonuses")
local getTrade=s.destination.GetTrade
s.destination.GetTrade=function() return {HasTradeRouteFrom=function() return false end} end
check(CAITradeData.BuildPlayerHeaderTooltip(1),"LOC_TRADE_OVERVIEW_TOOLTIP_NO_TOURISM_BONUS +30.0%[NEWLINE]LOC_TRADE_OVERVIEW_TOOLTIP_NO_DIPLOMATIC_VIS_BONUS","foreign inactive trade bonuses")
s.destination.GetTrade=getTrade
Game.GetLocalPlayer=function() return -1 end
check(CAITradeData.BuildPlayerHeaderTooltip(1),"","observer header tooltip empty")
local entries={}
CAICapturedDropdown.AddUniqueText(entries,"All")
CAICapturedDropdown.AddUniqueText(entries,"Gold")
CAICapturedDropdown.AddUniqueText(entries,"All")
check(#entries,2,"duplicate native filter labels")
check(CAICapturedDropdown.FindSelection(entries,"Gold",1),2,"native selected label")
check(CAICapturedDropdown.FindSelection(entries,"missing",2),2,"missing label retains previous")
check(CAICapturedDropdown.FindSelection(entries,nil,2),2,"nil label retains previous")
local dropdown=mgr:CreateWidget("test_trade_filter","Dropdown",{})
local events=0
dropdown:On("value_changed",function() events=events+1 end)
CAICapturedDropdown.Sync(nil,entries,2)
CAICapturedDropdown.Sync(dropdown,entries,2)
check(events,0,"sync is silent")
check(dropdown:GetSelectedIndex(),2,"sync selected index")
dropdown:SetSelectedIndex(1)
check(events,1,"user selection emits once")
CAICapturedDropdown.Sync(dropdown,{},1)
check(events,1,"empty sync is silent")
print("Trade data/dropdowns: " .. count .. " assertions passed.")
