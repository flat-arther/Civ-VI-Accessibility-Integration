-- Mock only the game boundary; screens, widgets, manager and dialogs are production code.
local H = dofile("scripts/test-support/WidgetHarness.lua")
local T = {}
function T.Create(kind, bts, sourceRoot, ruleset, bbg)
    local mgr = H.CreateManager()
    H.Run("src/UI/uiManager/helpers/CAIWidgetHelpers_DialogBuilder.lua")
    CAIWidgetHelpers_DialogBuilder.Install(mgr)
    local s = { hidden = true, tab = 0, requests = 0, automated = true, includes = {}, clicks = 0 }
    local function control(text)
        return { text = text or "", GetText = function(c) return c.text end,
            GetToolTipString = function(c) return "tooltip:" .. c.text end,
            IsHidden = function(c) return c.hidden == true end, IsDisabled = function(c) return c.disabled == true end,
            RegisterCallback = function(c, _, fn) c.click = fn end,
            DoLeftClick = function(c) if c.click then c.click() end end,
            SetCheck = function(c, value) c.checked = value end }
    end
    Locale.Lookup = function(tag, ...) local p = {tag}; for _, v in ipairs({...}) do p[#p+1] = tostring(v) end; return table.concat(p, ":") end
    Locale.ToUpper, Locale.ToPercent = string.upper, function(v) return tostring(v * 100) .. "%" end
    Round = function(v) return math.floor(v * 10 + .5) / 10 end
    local function collection(items)
        return { FindID = function(_, id) return items[id] end, Members = function() return pairs(items) end }
    end
    local function city(owner, id, name)
        return { GetOwner = function() return owner end, GetID = function() return id end,
            GetName = function() return name end, GetX = function() return id end, GetY = function() return 0 end,
            IsCapital = function() return true end, GetTrade = function() return {
                HasActiveTradingPost = function() return true end, HasTradeRouteFrom = function() return true end } end }
    end
    s.origin, s.second, s.destination = city(0, 11, "same"), city(0, 12, "same"), city(1, 21, "destination")
    s.unit = { GetID = function() return 7 end, GetOwner = function() return 0 end,
        GetX = function() return 11 end, GetY = function() return 0 end,
        GetUnitType = function() return 1 end, GetMovesRemaining = function() return 2 end }
    s.selected = s.unit
    Players, PlayerConfigurations = {}, {}
    for id = 0, 1 do
        local cities = id == 0 and {[11]=s.origin,[12]=s.second} or {[21]=s.destination}
        Players[id] = { GetID = function() return id end, GetCities = function() return collection(cities) end,
            GetUnits = function() return collection({[7]=s.unit}) end, IsMajor = function() return true end,
            GetInfluence = function() return {CanReceiveInfluence = function() return false end} end,
            GetTrade = function() return {GetNumOutgoingRoutes=function() return 1 end, GetOutgoingRouteCapacity=function() return 3 end} end,
            GetCulture = function() return {GetExtraTradeRouteTourismModifier=function() return 5 end} end,
            GetDiplomacy = function() return {GetVisibilityOn=function() return 1 end} end }
        PlayerConfigurations[id] = {GetPlayerName=function() return "player" .. id end}
    end
    Game = {GetLocalPlayer=function() return 0 end, GetQuestsManager=function() return {
        HasActiveQuestFromPlayer=function(_, _, owner) return owner == 1 end} end,
        GetReligion=function() return {GetName=function() return "religion" end} end}
    GameInfo = {Yields={}, Religions={[1]={Index=1}}, Quests={QUEST_SEND_TRADE_ROUTE={Index=5}}, Units={[1]={MakeTradeRoute=true}}}
    SORT_BY_ID = {}
    for i, name in ipairs({"FOOD","PRODUCTION","GOLD","SCIENCE","CULTURE","FAITH","TURNS_TO_COMPLETE","DESTINATION_NAME"}) do
        SORT_BY_ID[name] = i
        GameInfo.Yields[i-1] = {Name=name}; GameInfo.Yields["YIELD_" .. name] = {Name=name}
    end
    START_INDEX, END_INDEX, SORT_ASCENDING, SORT_DESCENDING = 1, 6, 1, 2
    GlobalParameters = {TOURISM_TRADE_ROUTE_BONUS=25}
    Map = {GetPlotDistance=function() return 10 end, GetPlot=function() return {GetIndex=function() return 99 end} end}
    ActivityTypes, UnitManager = {ACTIVITY_AWAKE=1}, {GetActivityType=function() return 1 end}
    InterfaceModeTypes = {SELECTION=1}
    UI = {GetHeadSelectedUnit=function() return s.selected end, SetInterfaceMode=function() end}
    ContextPtr = {IsHidden=function() return s.hidden end, SetInputHandler=function(_, fn) s.input=fn end,
        SetShutdown=function(_, fn) s.shutdown=fn end}
    origSetInputHandler = ContextPtr.SetInputHandler
    Controls = {}
    for _, name in ipairs({"Title","FilterButton","BeginRouteLabel","BeginRouteButton","CancelButton",
        "RepeatRouteCheckbox","FromTopSortEntryCheckbox","MyRoutesButton","RoutesToCitiesButton","AvailableRoutesButton",
        "MyRoutesTabLabel","MyRoutesTabSelectedLabel","RoutesToCitiesTabLabel","RoutesToCitiesTabSelectedLabel",
        "AvailableRoutesTabLabel","AvailableRoutesTabSelectedLabel","OverviewFilterButton","OverviewGroupByButton"}) do Controls[name]=control(name) end
    Controls.FilterButton.text, Controls.OverviewFilterButton.text, Controls.OverviewGroupByButton.text = "All", "All", "Player"
    s.children = {}; Controls.CityStack = {GetChildren=function() return s.children end}
    IsBetterTradeScreenActive=function() return bts end
    GameConfiguration = {GetRuleSet=function() return ruleset or "RULESET_STANDARD" end}
    CAIModSupport = {IsBBGActive=function() return bbg end}
    local noop = function() end
    Close=function() s.hidden=true end
    OnClose=function() Close() end
    OnShutdown=function() s.shutdownCalled=true end
    TeleportToCity=function(c) s.teleported=c:GetID(); Close() end
    SelectUnit=function(unit) s.selectedUnit=unit end
    SelectFreeTrader=function(unit, owner, id) s.freeTrader={unit,owner,id} end
    OnTradeRouteSelected=function(owner,id) s.destinationSelected={owner,id} end
    RequestTradeRoute=function() s.requests=s.requests+1; s.selected=nil; Close() end
    Controls.BeginRouteButton.click=function() RequestTradeRoute() end
    Controls.CancelButton.click=function() s.cancelled=true end
    GetOriginCity=function() return s.origin end
    GetYieldsForRoute=function(_, _, dest) return {kYieldValues={2,-1,0,0,0,0}, MajorityReligion=1, ReligionPressure=3,
        HasPathBonus=true, TooltipText=dest and "dest details" or "origin details"} end
    GetYieldsForOriginCity=function() return {2,-1,0,0,0,1}, {"food","negative","zero","zero","zero","faith"} end
    GetYieldsForDestinationCity=function() return {0,3,0,0,0,0}, {"zero","production"} end
    GetAdvancedRouteInfo=function() return 10,2,20 end
    GetRouteHasTradingPost=function() return true end
    IsTraderAutomated=function() return s.automated end
    CancelAutomatedTrader=function(id) s.cancelAuto=id; s.automated=false end
    AutomateTrader=function(id, enabled, settings) s.automation={id,enabled,settings}; s.automationCount=(s.automationCount or 0)+1 end
    InsertSortEntry=function(id, direction, settings) settings[#settings+1]={id=id,direction=direction} end
    SortTradeRoutes=function(routes, settings) s.sort=settings; return routes end
    IsCAIEscapeKeyUp=function(input) return input:GetKey()==Keys.VK_ESCAPE and input:GetMessageType()==KeyEvents.KeyUp end
    IsCAITutorialScreenCloseAllowed=function() return s.tutorialBlocked~=true end
    AnnounceCAITutorialScreenCloseBlocked=function() s.blocked=true end
    OnInputHandler=function(input) if IsCAIEscapeKeyUp(input) then Close(); return true end; return false end
    AddFilter, AddGroupByEntry = noop, noop
    RefreshFilters=function() AddFilter("All"); AddFilter("Gold"); AddFilter("All") end
    OnFilterSelected=function(_, idx)
        s.filterCalls=(s.filterCalls or 0)+1
        s.filter=idx; Controls.FilterButton.text=idx==1 and "All" or "Gold"; Controls.OverviewFilterButton.text=Controls.FilterButton.text
        if kind=="Route" then RefreshStack(); RefreshFilters() else Refresh() end
    end
    OnGroupBySelected=function(_, id) s.group=id; Controls.OverviewGroupByButton.text=id==10 and "Player" or "City"; Refresh() end
    local function route()
        return {OriginCityPlayer=0,OriginCityID=11,DestinationCityPlayer=1,DestinationCityID=21,
            TraderUnitID=(s.tab~=2) and 7 or nil}
    end
    AddRouteInstanceFromRouteInfo = nil
    if kind=="Origin" then
        AddCity=function(value)
            local c=bts and Players[0]:GetCities():FindID(value) or value
            if s.noButton then return end
            local button=control(string.upper(c:GetName())); button.CData={}
            button.click=function() s.clicks=s.clicks+1; if not bts then TeleportToCity(c) end end
            s.children[#s.children+1]=button
        end
        Refresh=function() s.children={}; for _, c in ipairs({s.origin,s.second}) do AddCity(bts and c:GetID() or c) end end
    elseif kind=="Route" then
        AddCityToDestinationStack, AddRouteToDestinationStack = noop, noop
        RefreshStack=function() if not s.empty then if bts then AddRouteToDestinationStack(route()) else AddCityToDestinationStack(s.destination) end end end
        Refresh=function() RefreshFilters(); RefreshStack() end
    else
        CreatePlayerHeader, CreateCityStateHeader, CreateUnusedRoutesHeader, CreateCityHeader = noop,noop,noop,noop
        AddRoute, AddChooseRouteButton, AddProduceTradeUnitButton = noop,noop,noop
        if bts and not ruleset then AddRouteInstanceFromRouteInfo=noop end
        AddChooseRouteButtonInstance, AddProduceTradeUnitButtonInstance = noop,noop
        Refresh=function()
            CreatePlayerHeader(Players[1])
            if AddRouteInstanceFromRouteInfo then AddRouteInstanceFromRouteInfo(route())
            else AddRoute(Players[0],s.origin,Players[1],s.destination,7) end
            CreateUnusedRoutesHeader()
            if AddRouteInstanceFromRouteInfo then AddChooseRouteButtonInstance(s.unit); AddProduceTradeUnitButtonInstance()
                AddFilter("All"); AddFilter("Gold"); AddFilter("All"); AddGroupByEntry("Player",10); AddGroupByEntry("City",40)
            else AddChooseRouteButton(s.unit); AddProduceTradeUnitButton() end
        end
        OnMyRoutesButton=function() s.tab=0; Refresh() end
        OnRoutesToCitiesButton=function() s.tab=1; Refresh() end
        OnAvailableRoutesButton=function() s.tab=2; Refresh() end
    end
    Open=function() s.hidden=false; Refresh() end
    LuaEvents.TradeOverview_SelectRouteFromOverview.Add(function(owner,id) s.overviewDestination={owner,id} end)
    local baseInclude=include
    include=function(name)
        s.includes[name]=true
        if name=="CAIModSupport" then return end
        if name=="CAICapturedDropdown" then H.Run("src/UI/shared/" .. name .. ".lua")
        elseif name:match("^CAITrade") then H.Run("src/UI/inGame/" .. name .. ".lua")
        elseif name:match("_BetterTradeScreen_CAI$") then H.Run((sourceRoot or "src/UI/inGame") .. "/" .. name .. ".lua")
        elseif name:match("^Trade") then return
        else baseInclude(name) end
    end
    H.Run((sourceRoot or "src/UI/inGame") .. "/Trade" .. (kind=="Overview" and "Overview" or kind .. "Chooser") .. "_CAI.lua")
    return mgr,s
end
T.Key=H.Key
return T
