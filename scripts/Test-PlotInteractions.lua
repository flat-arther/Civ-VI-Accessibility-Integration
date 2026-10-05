-- Real plot-action controller and widgets with a mocked game boundary.
-- Optional argument: pre-extraction WorldInput source for differential runs.
local H=dofile("scripts/test-support/WidgetHarness.lua")
local mgr=H.CreateManager()
local count=0
local function check(value,label) count=count+1; assert(value,label) end
local state={plotID=5,localPlayer=0,allowed=true,units={},cityOwner=0,city=false,met=false,
    minor=false,capital=false,visibility={},xp2=true,clans=false,revealed=true,districts={},improvement=-1,
    stock={},targets=true,cityStrike=false,districtStrike=false,mode=1,trace={}}
local function record(name,...) local t={name}; for _,v in ipairs({...}) do t[#t+1]=tostring(v) end; state.trace[#state.trace+1]=table.concat(t,":") end
Locale.Lookup=function(tag,...) local t={tag}; for _,v in ipairs({...}) do t[#t+1]=tostring(v) end; return table.concat(t,":") end
InterfaceModeTypes={SELECTION=1,ICBM_STRIKE=2,CITY_RANGE_ATTACK=3,DISTRICT_RANGE_ATTACK=4}
CityCommandTypes={RANGE_ATTACK=1,WMD_STRIKE=2,PARAM_WMD_TYPE="wmd",PARAM_X0="x",PARAM_Y0="y"}
CityCommandResults={PLOTS="plots"}
CivilizationLevelTypes={CIVILIZATION_LEVEL_FULL_CIV=0}
PlayerTypes={OBSERVER=1000}; MapLayers={ANY=0}
local plot={GetX=function() return 4 end,GetY=function() return 6 end,GetIndex=function() return 5 end,
    GetImprovementType=function() return state.improvement end}
local city={GetOwner=function() return state.cityOwner end,GetID=function() return 9 end,
    GetName=function() return "city" end,IsCapital=function() return state.capital end}
local function unit(id,owner) return {GetOwner=function() return owner end,GetID=function() return id end} end
local function district(kind) return {GetType=function() return kind end,GetX=plot.GetX,GetY=plot.GetY} end
Game={GetLocalPlayer=function() return state.localPlayer end,GetLocalObserver=function() return 0 end,
    GetBarbarianManager=function() return {GetTribeIndexAtLocation=function() return 3 end,GetTribeNameType=function() return 1 end} end}
GameConfiguration={GetValue=function() return state.clans end}
Map={GetPlotByIndex=function(id) if id==5 then return plot end end,GetPlot=function() return plot end}
Units={GetUnitsInPlotLayerID=function() return state.units end}
Cities={GetPlotPurchaseCity=function() return city end}
CityManager={GetCityAt=function() if state.city then return city end end,
    CanStartCommand=function(subject) return subject==city and state.cityStrike or subject~=city and state.districtStrike end,
    GetCommandTargets=function() if state.targets then return {plots={8}} end end}
local player={GetDiplomacy=function() return {HasMet=function() return state.met end,GetVisibilityOn=function() return 1 end} end,
    GetCities=function() return {FindID=function() return city end} end,
    GetDistricts=function() return {Members=function() return ipairs(state.districts) end} end,
    GetWMDs=function() return {GetWeaponCount=function(_,id) return state.stock[id] or 0 end} end}
Players={[0]=player,[1]=player}
PlayerConfigurations={[1]={GetCivilizationLevelTypeID=function() return state.minor and 1 or 0 end}}
PlayersVisibility={[0]={IsRevealed=function() return state.revealed end}}
local weapons={{Index=0,WeaponType="WMD_NUCLEAR_DEVICE"},{Index=1,WeaponType="WMD_THERMONUCLEAR_DEVICE"},{Index=2,WeaponType="unsupported"}}
GameInfo={Districts={DISTRICT_CITY_CENTER={Index=0},[1]={Name="encampment"}},
    Improvements={[0]={ImprovementType="IMPROVEMENT_BARBARIAN_CAMP",WeaponSlots=0},[1]={Name="silo",WeaponSlots=1}},
    BarbarianTribeNames={[1]={TribeDisplayName="clan"}},Visibilities_XP2=setmetatable({},{__index=function() return state.visibility end}),
    WMDs=function() local i=0; return function() i=i+1; return weapons[i] end end}
IsExpansion2Active=function() return state.xp2 end
UI={GetInterfaceMode=function() return state.mode end,
    SetInterfaceMode=function(mode,params) state.mode=mode; state.params=params; record("mode",mode) end,
    DeselectAllUnits=function() record("deselect units") end,DeselectAllCities=function() record("deselect cities") end,
    DeselectAll=function() record("deselect all") end,SelectUnit=function(u) record("unit",u:GetID()) end,
    SelectCity=function() record("city") end,SelectDistrict=function() record("district") end,
    PlaySound=function() record("click") end}
UILens={SetActive=function(name) record("lens",name) end}
for _,name in ipairs({"CityBannerManager_RaiseMinorCivPanel","CAIOpenOverviewForEnemyCity","CityBannerManager_TalkToLeader","CityBannerManager_OpenTreatWithTribePopup"}) do
    LuaEvents[name].Add(function(...) record(name,...) end)
end
ContextPtr={}
UITutorialManager={AddControlToAlwaysReceiveInput=function(_,context) assert(context==ContextPtr); state.always=true end,
    RemoveControlToAlwaysReceiveInput=function(_,context) assert(context==ContextPtr); state.always=false end}
GetCurrentCAICursorPlotId=function() return state.plotID end
IsCAITutorialPlotSelectionAllowed=function() return state.allowed end
FormatOwnedUnitDisplayName=function(u) return "unit" .. u:GetID() end
local controller
if arg[1] then
    local f=assert(io.open(arg[1],"rb")); local source=f:read("a"); f:close()
    local first=assert(source:find('local PLOT_INTERACT_LIST_ID',1,true))
    local last=assert(source:find('local function SetCAIMapZoom',first,true))
    local env=setmetatable({mgr=mgr},{__index=_G})
    controller=assert(load(source:sub(first,last-1) .. '\nreturn {Primary=OnPlotPrimaryAction,Secondary=OnPlotSecondaryAction}',"@legacy plot actions","t",env))()
else
    dofile("src/UI/inGame/CAIPlotInteractions.lua")
    controller=CAIPlotInteractions.Create(mgr,{
        GetPlotId=GetCurrentCAICursorPlotId,
        HasInterfaceWidget=function() return m_caiCurrentInterfaceWidget~=nil end,
        IsPlotSelectionAllowed=IsCAITutorialPlotSelectionAllowed,FormatUnitName=FormatOwnedUnitDisplayName,
        SetAlwaysReceiveInput=function(enabled)
            if enabled then UITutorialManager:AddControlToAlwaysReceiveInput(ContextPtr)
            else UITutorialManager:RemoveControlToAlwaysReceiveInput(ContextPtr) end
        end,
    })
end
local root=mgr:CreateWidget("world","Panel",{})
local focus=mgr:CreateWidget("world_focus","Button",{Label="world"})
root:AddChild(focus); mgr:Push(root)
local function list() return mgr:GetWidgetById("CAIWorldInputPlotInteractList") end
local function trace() return table.concat(state.trace,",") end
local function resetTrace() state.trace={} end
check(controller.Secondary()==false,"empty secondary unhandled")
check(controller.Primary()==true and not list(),"empty primary handled without list")
check(H.Speech[#H.Speech]=="LOC_CAI_TILE_INTERACT_NO_ACTIONS","empty feedback localized")
state.mode=3; check(controller.Primary()==false and controller.Secondary()==false,"target modes bypass plot actions")
state.mode=1; m_caiCurrentInterfaceWidget={}
check(controller.Primary()==false and controller.Secondary()==false,"active interface has priority")
m_caiCurrentInterfaceWidget=nil
for _,id in ipairs({-1,99}) do state.plotID=id; check(controller.Primary()==true and not list(),"invalid plot has no actions") end
state.plotID=5; state.units={unit(10,0)}; state.allowed=false
resetTrace(); controller.Primary(); check(trace()=="","tutorial excludes gameplay selection")
state.allowed=true; state.localPlayer=-1; controller.Primary(); check(trace()=="","no local player excludes selection")
state.localPlayer=0; controller.Primary()
check(trace()=="click,deselect units,deselect cities,unit:10","single unit executes native selection in order")
state.units={unit(11,1)}; resetTrace(); controller.Primary(); check(trace()=="","foreign unit is not selectable")
state.units={unit(10,0),unit(12,0)}; controller.Primary()
check(list() and #list().Children==2 and state.always,"multiple actions build tutorial-enabled list")
local old=list(); controller.Primary()
check(list()~=old and old.Manager==nil and #mgr.Stack==2,"reopening replaces list without stack duplicates")
resetTrace(); list().Children[2]:Activate()
check(trace()=="click,deselect units,deselect cities,unit:12","list retains action identity")
check(not list() and not state.always and mgr:GetFocusedWidget()==focus,"activation closes list and restores world focus")
controller.Primary(); mgr:HandleInput(H.Key(Keys.VK_ESCAPE))
check(not list() and not state.always,"escape cleans tutorial override")
controller.Primary(); mgr:CloseSuspendModals()
check(not list() and not state.always,"suspend closes list")
check(next(mgr._suspendClosers)==nil,"suspend closer unregistered")
state.units={}; state.city=true; resetTrace(); controller.Primary()
check(trace()=="click,city","owned city selected")
state.cityOwner=1; resetTrace(); controller.Primary(); check(trace()=="","unmet foreign city excluded")
state.met=true; controller.Primary()
check(trace()=="click,CityBannerManager_TalkToLeader:1","met major opens diplomacy")
state.minor=true; resetTrace(); controller.Primary()
check(trace()=="click,CityBannerManager_RaiseMinorCivPanel:1","met minor opens city-state panel")
check(controller.Secondary()==false,"no espionage visibility cannot open city view")
state.visibility={EspionageViewCapital=true}; state.capital=false
check(controller.Secondary()==false,"capital-only visibility excludes noncapital")
state.capital=true; resetTrace(); check(controller.Secondary()==true,"capital view handled")
check(trace()=="click,CAIOpenOverviewForEnemyCity:1:9","secondary opens espionage view")
state.xp2=false; check(controller.Secondary()==false,"base game excludes espionage view")
state.xp2=true; state.capital=false; state.visibility={EspionageViewAll=true}
controller.Primary(); check(#list().Children==2,"diplomacy precedes available city view")
check(list().Children[2]:GetLabel():find("VIEW_CITY",1,true)~=nil,"city view row label")
mgr:CloseSuspendModals()
state.cityOwner=0; state.cityStrike=true; resetTrace(); controller.Primary()
check(#list().Children==2,"owned city has selection and strike")
list().Children[2]:Activate(); check(trace()=="click,city,mode:3","city strike enters native targeting")
state.mode=1; state.city=false; state.cityStrike=false; state.clans=true; state.improvement=0
resetTrace(); controller.Primary(); check(trace()=="click,CityBannerManager_OpenTreatWithTribePopup:5","revealed clan action")
state.revealed=false; resetTrace(); controller.Primary(); check(trace()=="","unrevealed clan excluded")
state.clans=false; state.improvement=-1; state.districts={district(0),district(1)}; state.districtStrike=true
resetTrace(); controller.Primary(); check(trace()=="click,deselect all,district,mode:4","non-city-center district targets natively")
state.mode=1; state.districts={}; state.improvement=1; state.stock={[0]=1,[1]=2,[2]=8}
resetTrace(); controller.Primary(); check(#list().Children==2,"stocked supported silo weapons only")
-- Native strike mode can change while the list is open; activation must reset it.
state.mode=2; list().Children[2]:Activate()
check(trace()=="click,mode:1,city,lens:Default,mode:2","silo targeting setup order")
check(state.params.wmd==1 and state.params.x==4 and state.params.y==6,"silo source and weapon parameters")
state.mode=1; state.targets=false; resetTrace(); controller.Primary(); check(trace()=="" and not list(),"unavailable command targets excluded")
state.targets=true; state.cityOwner=1; controller.Primary(); check(trace()=="","foreign purchase city silo excluded")
-- Native context wiring remains outside the module.
local f=assert(io.open("src/UI/inGame/WorldInput_CAI.lua","rb")); local world=f:read("a"); f:close()
check(world:find('return plotInteractions.Primary()',1,true)~=nil and world:find('return plotInteractions.Secondary()',1,true)~=nil,"both native action dispatchers bind controller")
check(world:find('include(GetWorldInputIncludeName())',1,true)~=nil,"scenario base dispatch retained")
print("Plot interactions: " .. count .. " assertions passed (mocked game boundary, production widgets).")
