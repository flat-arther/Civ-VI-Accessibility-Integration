-- Run descriptor actions with production widgets and explicit native callback spies.
-- Optional argument compares the same checks with the pre-extraction context.
local H=dofile('scripts/test-support/WidgetHarness.lua')
local mgr=H.CreateManager()
local count=0
local function check(v,label) count=count+1; assert(v,label) end
local function read(path) local f=assert(io.open(path,'rb')); local s=f:read('a'):gsub('\r\n','\n'); f:close(); return s end
local source=read('src/UI/inGame/CAIWorldInputModes.lua')
local state={valid=true,allowed=true,unit={},city={},district={},calls={},mode=nil}
local function record(name) state.calls[#state.calls+1]=name end
local plot={GetIndex=function() return 12 end,GetX=function() return 2 end,GetY=function() return 1 end}
Map={IsPlot=function(id) return id==12 end,GetPlotByIndex=function() return plot end}
CAICursor={GetPlotId=function() return state.plot or 12 end}
CAIInterfaceTargets={GetTargetAtPlot=function(p,live) check(p==plot and live,'authoritative live target lookup'); if state.valid then return {} end end}
MovementActions_CAI={ClearReadyForCombat=function() record('clear') end}
UI={GetHeadSelectedUnit=function() return state.unit end,GetHeadSelectedCity=function() return state.city end,
 GetHeadSelectedDistrict=function() return state.district end,SetInterfaceMode=function(mode) state.mode=mode end}
UnitOperationTypes={RANGE_ATTACK=1,PARAM_X='x',PARAM_Y='y'}
CityCommandTypes={RANGE_ATTACK=1}
UnitCommandTypes={PARAM_X='x',PARAM_Y='y',PARAM_NAME='name',EXECUTE_SCRIPT=5}
UnitManager={CanStartOperation=function(_,_,_,p) check(p.x==2 and p.y==1,'unit coordinates'); return state.allowed end,
 RequestCommand=function(unit,kind,p) check(unit==state.unit and kind==5 and p.x==2 and p.y==1,'scenario command parameters'); state.command=p; record('command') end}
CityManager={CanStartCommand=function(_,_,p) check(p.x==2 and p.y==1,'city coordinates'); return state.allowed end}
InterfaceModeTypes={SELECTION='SELECTION'}
for name in source:gmatch('InterfaceModeTypes%.([A-Z_]+)') do InterfaceModeTypes[name]=name end
local context={}
for name in source:gmatch('local [%w_]+ = context%.([%w_]+)') do
 local key=name; context[key]=function() record(key); return true end
end
context.ACTION_INTERFACE_PRIMARY='primary'; context.INPUT_ACTION_TRIGGERED='Triggered'; context.CITY_MANAGEMENT_WIDGET_ID='city'
context.IsSelectionAllowedAt=function(id) check(id==12,'selection plot'); return state.allowed end
context.IsTargetPlot=function(id) check(id==12,'pirates target plot'); return state.allowed end
context.OnPlacementKeyUp=function(input) check(input:GetKey()==Keys.VK_ESCAPE,'native cancel receives Escape'); record('cancel') end
context.g_unitCommandSubTypeNames={}
for name in source:gmatch('g_unitCommandSubTypeNames%.([A-Z_]+)') do context.g_unitCommandSubTypeNames[name]=name end
for name in source:gmatch('Mode = (INTERFACEMODE_[A-Z_]+)') do context[name]=name end
local function create(rule)
 GameConfiguration={GetRuleSet=function() return rule end}
 if arg[1] then
  local old=read(arg[1]); local a=assert(old:find('local function RunVanillaPlacementCancel()',1,true)); local b=assert(old:find('local function GetInterfaceWidgetData()',a,true))
  local body=old:sub(a,b-1)..'\nreturn {GetData=function(mode) return interfaceWidgets[mode] end,Build=function(mode) local d=interfaceWidgets[mode]; if d then return mgr:CreateWidget(d.WidgetId or "CAIWorldInputInterfaceMode","InterfaceMode",d.Properties) end end}'
  context.mgr=mgr; return assert(load(body,'baseline','t',setmetatable(context,{__index=_G})))()
 end
 dofile('src/UI/inGame/CAIWorldInputModes.lua'); return CAIWorldInputModes.Create(mgr,context)
end
for _,rule in ipairs({'standard','RULESET_SCENARIO_CIV_ROYALE','RULESET_SCENARIO_PIRATES'}) do
 local controller=create(rule)
 check(controller.Build('unknown')==nil,'unsupported mode')
 local modes={}; for _,name in pairs(InterfaceModeTypes) do modes[name]=true end
 if rule=='RULESET_SCENARIO_PIRATES' then for name in pairs(context) do if name:match('^INTERFACEMODE_') then modes[name]=true end end end
 for name in pairs(modes) do
  local data=controller.GetData(name)
  if data then
   local widget=assert(controller.Build(name)); check(widget.Type=='InterfaceMode','production widget'); check(type(data.Properties.GetLabel())=='string','localized label')
   local action=data.InputActions and data.InputActions.primary.Action
   if action then
    state.valid=false; state.calls={}; action()
    check(name=='MOVE_TO' or #state.calls==0,'invalid target blocks native action')
    state.valid=true; state.allowed=true; state.calls={}; state.command=nil; action(); check(#state.calls==1,'valid target executes once')
    if name=='DISTRICT_PLACEMENT' or name=='BUILDING_PLACEMENT' or name:find('RANGE_ATTACK') or name=='GRIEVING_GIFT' or name:match('^INTERFACEMODE_') then
     state.allowed=false; state.calls={}; action(); check(#state.calls==0,'native legality blocks action'); state.allowed=true
    end
    if name:match('^INTERFACEMODE_') then check(state.command.CommandSubType==name:gsub('INTERFACEMODE_',''),'pirates subtype') end
   else check(name=='CITY_MANAGEMENT','city management has no primary override') end
   state.calls={}; check(data.Properties.RegisterInputs[1].Action()==true,'cancel consumed'); check(#state.calls>=1,'cancel reaches native callback')
   widget:Destroy()
  end
 end
end
assert(loadfile('src/UI/inGame/WorldInput_CAI.lua'))
-- Exercise the production coastal raid reader with live target definitions.
do
 local helperSource=read('src/UI/inGame/interfaceInfoHelpers_CAI.lua')
 local first=assert(helperSource:find('local function BuildSimpleTargetValidityInterfaceInfo',1,true))
 local last=assert(helperSource:find('local function BuildCombatPreviewInterfaceInfo',first,true))
 local targetValid, improvement, district, pillaged=true, -1, -1, false
 local plot={GetImprovementType=function() return improvement end,
  GetDistrictType=function() return district end,IsImprovementPillaged=function() return pillaged end}
 local definitions={Improvements={},Districts={},Yields={}}
 for _,name in ipairs({'GOLD','FAITH','SCIENCE','CULTURE'}) do
  definitions.Yields['YIELD_'..name]={Name='LOC_'..name}
 end
 local env=setmetatable({
  CAIInterfaceTargets={GetTargetAtPlot=function() return targetValid and {} or nil end},
  GameInfo=definitions,
  Locale={Lookup=function(text) return 'localized:'..text end},
  UnitManager={CanStartOperation=function() error('reward reader must not query operation descriptions') end},
 },{__index=_G})
 local build=assert(load(helperSource:sub(first,last-1)..'\nreturn BuildCoastalRaidInterfaceInfo',
  '@coastal raid interface reader','t',env))()
 check(build(nil)==nil,'nil plot has no interface info')
 targetValid=false
 check(build(plot)[1]=='localized:LOC_CAI_PLOT_INTERFACE_INVALID_TARGET','invalid plot retains validity')
 targetValid=true
 local lines=build(plot)
 check(#lines==1 and lines[1]=='localized:LOC_CAI_PLOT_INTERFACE_VALID','capture-only target has no pillage yield')
 improvement=1
 for _,name in ipairs({'GOLD','FAITH','SCIENCE','CULTURE'}) do
  definitions.Improvements[1]={PlunderType='PLUNDER_'..name,PlunderAmount=999}
  lines=build(plot)
  check(#lines==2 and lines[2]=='localized:LOC_'..name,'live improvement reward type without amount: '..name)
 end
 definitions.Improvements[1]={PlunderType='PLUNDER_HEAL'}
 check(build(plot)[2]=='localized:LOC_TYPE_TRAIT_PILLAGE_AWARD_HEALING','healing reward localized')
 pillaged=true
 check(#build(plot)==1,'pillaged improvement has no reward')
 improvement=-1; district=2
 definitions.Districts[2]={PlunderType='PLUNDER_SCIENCE'}
 check(build(plot)[2]=='localized:LOC_SCIENCE','district reward type read live')
 definitions.Districts[2]={PlunderType='NO_PLUNDER'}
 check(#build(plot)==1,'no-plunder target has no yield')
 definitions.Districts[2]={}
 check(#build(plot)==1,'absent plunder type has no yield')
 district=-1; improvement=1; pillaged=false; targetValid=false
 check(#build(plot)==1,'invalid target never announces reward')
 check(helperSource:find('InterfaceInfoHelpers[InterfaceModeTypes.COASTAL_RAID] = BuildCoastalRaidInterfaceInfo',1,true)~=nil,
  'coastal mode uses reward reader')
end
print('World input modes: '..count..' assertions passed')
