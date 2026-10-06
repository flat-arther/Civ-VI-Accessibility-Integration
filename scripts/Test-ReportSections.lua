-- Load the shared Reports host and each real variant with production widgets.
-- Optional arguments: previous shared host path, then snapshot output path.
if arg[1]=='--current' then arg[1]=nil end
local H=dofile('scripts/test-support/WidgetHarness.lua')
local count=0
local snapshots={}
local function check(v,label) count=count+1; assert(v,label) end
local function read(path) local f=assert(io.open(path,'rb')); local s=f:read('a'):gsub('\r\n','\n'); f:close(); return s end
local function run(path)
 local source=read(path)
 if path:find('BetterReportsScreen',1,true) then
  -- The unchanged vendored vanilla data routine contains Firaxis annotations.
  for _,kind in ipairs({'table','number','string','boolean'}) do source=source:gsub('([%w_]+)%s*:%s*'..kind..'%f[^%w_]','%1') end
 end
 assert(load(source,'@'..path))()
end
for _,brs in ipairs({false,true}) do
 for _,xp2 in ipairs({false,true}) do
  local mgr=H.CreateManager()
  Locale.Lookup=function(tag,...) local parts={tostring(tag)}; for _,v in ipairs({...}) do parts[#parts+1]=tostring(v) end; return table.concat(parts,':') end
  table.count=function(t) local n=0; for _ in pairs(t) do n=n+1 end; return n end
  CAI.GetConfigValue=function(_,_,default) return default end
  IsExpansion2Active=function() return xp2 end
  Modding={IsModActive=function(id) return brs and id=='6f2888d4-79dc-415f-a8ff-f9d81d7afb53' end}
  IsCAITutorialControlAllowed=function() return true end
  GameCapabilities={HasCapability=function() return true end}
  local hidden=true; local nativeOpens,nativeCloses,providerCalls=0,0,0
  ContextPtr={IsHidden=function() return hidden end,SetInputHandler=function() end,SetShutdown=function() end}
  Controls={TabContainer={GetChildren=function() return {} end}}
  local playerID=0
  local flows={COAL={extracted=16,imports=3,bonus=0,units=2,power=3,reserved=1,stock=10,cap=50},IRON={extracted=0,imports=0,bonus=0,units=0,power=0,reserved=0,stock=4,cap=50}}
  local resources={}
  local defs={}
  for i,name in ipairs({'COAL','IRON','SILK','WHEAT'}) do
   local row={Index=i,ResourceType=name,Name=name,ResourceClassType=i<3 and 'RESOURCECLASS_STRATEGIC' or (i==3 and 'RESOURCECLASS_LUXURY' or 'RESOURCECLASS_BONUS')}
   defs[i]=row
  end
  GameInfo={Resources=setmetatable(defs,{__call=function(t) local i=0; return function() i=i+1; return t[i] end end}),Gossips={A={GroupType='DIPLO'},B={GroupType='CITY'}}}
  local function entry(text,control,amount) return {EntryText=text,ControlText=control,Amount=amount} end
  local data={
   [1]={IsStrategic=true,Stockpile=10,Maximum=50,Total=14,EntryList={entry('City','LOC_HUD_REPORTS_TRADE_OWNED',15),entry('Suzerain','LOC_CITY_STATES_SUZERAIN',3),entry('LOC_PRODUCTION_PANEL_UNITS_TOOLTIP','-',-2),entry('LOC_UI_PEDIA_POWER_COST','-',-3),entry('Deal','Foreign',1)}},
   [3]={IsLuxury=true,Total=1,EntryList={entry('SilkCity','LOC_HUD_REPORTS_TRADE_OWNED',1)}},
   [4]={IsBonus=true,Total=0,EntryList={}},
  }
  for method,key in pairs({GetResourceAccumulationPerTurn='extracted',GetResourceImportPerTurn='imports',GetBonusResourcePerTurn='bonus',GetUnitResourceDemandPerTurn='units',GetPowerResourceDemandPerTurn='power',GetReservedResourceAmount='reserved',GetResourceAmount='stock',GetResourceStockpileCap='cap'}) do
   local field=key; resources[method]=function(_,resource) return flows[resource] and flows[resource][field] or 0 end
  end
  local cityName='Home'
  resources.GetResourceAllocationCities=function(_,i) return i==3 and {{CityID=7}} or {} end
  local diplomacy={HasMet=function(_,id) return id==1 or id==2 end}
  Players={[0]={GetDiplomacy=function() return diplomacy end,GetResources=function() return resources end,GetCities=function() return {FindID=function() return {GetName=function() return cityName end} end} end}}
  PlayerConfigurations={}
  for i=1,4 do local id=i; Players[i]={IsMajor=function() return id~=4 end}; PlayerConfigurations[i]={GetLeaderName=function() return 'Leader'..id end} end
  local logs={[1]={{'new',11,'A',1},{'old',3,'B',1},{'unknown',12,'MISSING',1}},[2]={{'other',9,'B',2}}}
  Game={GetLocalPlayer=function() return playerID end,GetGossipManager=function() return {GetRecentVisibleGossipStrings=function(_,turn,localID,targetID) check(turn==0 and localID==playerID and targetID<3,'visible gossip query'); return logs[targetID] end} end}
  local function provider() providerCalls=providerCalls+1; return {},{},data,{},{} end
  GetData=provider
  ViewYieldsPage=function() end; ViewResourcesPage=function() end; ViewCityStatusPage=function() end; ViewGossipPage=function() end
  ViewDealsPage=brs and function() end or nil
  RefreshGossip=function() end; AddTabSection=function() end; OnInputHandler=function() return false end; OnShutdown=function() end
  Open=function(tab) nativeOpens=nativeOpens+1; hidden=false; m_kCurrentTab=tab; if not brs then if tab==2 then ViewResourcesPage() elseif tab==4 then ViewGossipPage() end end end
  Close=function() nativeCloses=nativeCloses+1; hidden=true end
  local nativeInclude=include
  include=function(name)
   if name=='CAIReportResources' or name=='CAIReportGossip' then run('src/UI/inGame/'..name..'.lua')
   elseif name=='ReportScreen_Vanilla_CAI' or name=='ReportScreen_BetterReportsScreen_CAI' then run('src/UI/inGame/'..name..'.lua')
   elseif name=='ReportScreen' or name=='ReportScreen_Expansion1' or name=='ReportScreen_Expansion2' or name=='hexCoordUtils_CAI' or name=='inGameHelpers_CAI' then return
   else nativeInclude(name) end
  end
  run(arg[1] or 'src/UI/inGame/ReportScreen_CAI.lua')
  if brs then CAIReports_DataSource=provider end -- engine data mocked; copied routine remains unchanged
  Open(2)
  check(nativeOpens==1 and providerCalls==1,'native open and data provider called once')
  local panel=assert(mgr:GetWidgetById('CAIReports_Panel')); local tree=assert(mgr:FindByFocusKey(panel,'reports:tab:2:tree'))
  check(mgr:GetTop()==panel,'report pushed')
  local function find(key) return mgr:FindByFocusKey(tree,key) end
  local function snapshot(w,prefix)
   snapshots[#snapshots+1]=prefix..'/'..tostring(w.FocusKey)..'='..w.Type..':'..tostring(w:GetLabel())..':'..tostring(w:GetTooltip())
   for _,child in ipairs(w.Children or {}) do snapshot(child,prefix..'/'..tostring(w.FocusKey)) end
  end
  snapshot(tree,tostring(brs)..':'..tostring(xp2))
  check(find('res:group:strategic') and find('res:group:luxury') and not find('res:group:bonus'),'resource category inclusion')
  check(find('res:3'):GetTooltip():find('Home',1,true),'amenity tooltip')
  cityName='Renamed'; check(find('res:3'):GetTooltip():find('Renamed',1,true),'amenity tooltip reads live city name')
  if xp2 then
   check(find('res:2')~=nil,'stockpile-only resource synthesized')
   check(find('res:1'):GetLabel():find('+14',1,true),'XP2 net flow')
   check(find('res:1:accumulation:extracted:misc'):GetLabel():find('+1',1,true),'unattributed extraction retained')
   check(find('res:1:consumption:units') and find('res:1:consumption:power') and find('res:1:reserved'),'consumption and reserve')
   check(find('res:1:entry:5') and not find('res:1:entry:3'),'fallback details omit duplicate unit cost')
  else check(not find('res:2') and find('res:1:entry:3'),'base resource entries retained') end
  mgr:SetFocus(find('res:1:entry:1')); local speech=#H.Speech
  RebuildResourcesTree(tree)
  check(mgr:GetFocusedWidget().FocusKey=='res:1:entry:1' and #H.Speech==speech,'resource stable focus restored silently')
  flows.COAL.extracted=20; RebuildResourcesTree(tree)
  if xp2 then check(find('res:1'):GetLabel():find('+18',1,true),'flow refreshed from live player') end
  Close(); check(nativeCloses==1 and mgr:GetTop()==nil,'native close and stack cleanup')
  Open(4)
  panel=assert(mgr:GetWidgetById('CAIReports_Panel')); local list=assert(mgr:FindByFocusKey(panel,'reports:tab:4:list'))
  check(#list.Children==3 and list.Children[1]:GetLabel():find('new',1,true),'known gossip newest first')
  snapshot(list,tostring(brs)..':'..tostring(xp2))
  local playerFilter=assert(mgr:FindByFocusKey(panel,'gossip:filter:player'))
  local groupFilter=assert(mgr:FindByFocusKey(panel,'gossip:filter:type'))
  mgr:SetFocus(playerFilter); playerFilter:SetSelectedIndex(2)
  check(#list.Children==2 and mgr:GetFocusedWidget()==playerFilter,'player filter preserves dropdown focus')
  groupFilter:SetSelectedIndex(3)
  check(#list.Children==1 and list.Children[1]:GetLabel():find('old',1,true),'combined gossip filters')
  Close(); Open(4)
  panel=mgr:GetWidgetById('CAIReports_Panel'); list=mgr:FindByFocusKey(panel,'reports:tab:4:list')
  check(#list.Children==1,'gossip filters survive reopen')
  logs[1]={{'updated',15,'B',1}}; GatherGossip(); FilterCAIGossip()
  local entry={tree=list,page=list.Parent,filtersBuilt=true}; RebuildGossipTab(entry)
  check(#list.Children==1 and list.Children[1]:GetLabel():find('updated',1,true),'gossip refresh replaces data')
  playerID=-1; RefreshCAIData(); GatherGossip(); FilterCAIGossip(); RebuildGossipTab(entry)
  check(#list.Children==0,'no-player gossip empties')
  Close()
 end
end
if arg[2] then local f=assert(io.open(arg[2],'wb')); f:write(table.concat(snapshots,'\n')); f:close() end
print('Reports sections: '..count..' assertions passed; '..#snapshots..' snapshot lines')
