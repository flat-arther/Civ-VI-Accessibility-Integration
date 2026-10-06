-- Full WorldRankings host, production tree/table widgets, mocked native/game boundary.
-- Optional previous host path (or --current) and snapshot output path.
if arg[1]=='--current' then arg[1]=nil end
local H=dofile('scripts/test-support/WidgetHarness.lua')
local count,snapshots=0,{}
local function check(v,label) count=count+1; assert(v,label) end
local function run(path) local f=assert(io.open(path,'rb')); local s=f:read('a'); f:close(); assert(load(s,'@'..path))() end
for _,mode in ipairs({'base','xp2','bbg','warmachine'}) do
 local mgr=H.CreateManager()
 local xp2=mode=='xp2' or mode=='bbg'
 local bbg=mode=='bbg'
 local expectedInclude=mode=='warmachine' and 'WorldRankings_WarMachineScenario' or (bbg and 'WorldRankings_BetterBalancedGame_CAIBase' or (xp2 and 'WorldRankings_Expansion2' or 'WorldRankings'))
 local rule=mode=='warmachine' and 'RULESET_SCENARIO_WARMACHINE' or 'RULESET_STANDARD'
 local vt=bbg and 'VICTORY_TRADITIONAL_DOMINATION' or 'VICTORY_CUSTOM'
 local setting='tree'
 Locale.Lookup=function(tag,...) local p={tostring(tag)}; for _,v in ipairs({...}) do p[#p+1]=tostring(v) end; return table.concat(p,':') end
 CAI.GetConfigValue=function() return setting end; CAI.SetConfigValue=function(_,_,v) setting=v; return true end
 CAIModSupport={IsBBGActive=function() return bbg end}
 IsExpansion2Active=function() return xp2 end
 GameConfiguration={GetRuleSet=function() return rule end,IsAnyMultiplayer=function() return true end,GetValue=function() return 60 end}
 local playerID=0
 local met=true
 local points={[0]=3,[1]=7,[2]=5}
 Players={}; PlayerConfigurations={}; Teams={[0]={0,1},[1]={2}}
 for i=0,2 do
  local id=i
  Players[id]={GetTeam=function() return id==2 and 1 or 0 end,IsAlive=function() return true end,
   GetDiplomacy=function() return {HasMet=function() return met end} end,
   GetStats=function() return {GetDiplomaticVictoryPoints=function() return points[id] end,GetDiplomaticVictoryPointsTooltip=function() return ' source '..id..' [NEWLINE] second ' end} end}
  PlayerConfigurations[id]={IsHuman=function() return id==0 end,GetLeaderName=function() return 'Leader'..id end,GetCivilizationDescription=function() return 'Civ'..id end,GetPlayerName=function() return 'Human'..id end}
 end
 g_LocalPlayerID=0; g_LocalPlayer=Players[0]
 local reqMet=false
 Game={GetLocalPlayer=function() return playerID end,GetMaxGameTurns=function() return 500 end,IsVictoryEnabled=function() return true end,
  GetVictoryRequirements=function(_,victory) return victory==vt and not bbg and 9 or -1 end}
 GameEffects={GetRequirementSetInnerRequirements=function() return {11} end,GetRequirementTextKey=function(_,context) check(context=='VictoryProgress','requirement context'); return 'req' end,
  GetRequirementText=function() return 'requirement' end,GetRequirementState=function() return reqMet and 'Met' or 'Unmet' end}
 GlobalParameters={DIPLOMATIC_VICTORY_POINTS_REQUIRED=20}
 local scoring={{Index=0,Name='Cities'},{Index=1,Name='People'}}
 local cats={[0]=scoring[1],[1]=scoring[2]}
 setmetatable(cats,{__call=function() local i=0; return function() i=i+1; return scoring[i] end end})
 local victories={{VictoryType=vt,Name='Custom',Description='custom advice'},{VictoryType='VICTORY_DIPLOMATIC',Name='Diplo',Description='diplo advice'}}
 local catalog={}; for _,v in ipairs(victories) do catalog[v.VictoryType]=v end
 setmetatable(catalog,{__call=function() local i=0; return function() i=i+1; return victories[i] end end})
 GameInfo={ScoringCategories=cats,Victories=catalog}
 GetAliveMajorTeamIDs=function() return {0,1} end; IsAliveAndMajor=function() return true end; IsCustomVictoryType=function() return true end
 local pd={{PlayerID=0,PlayerScore=100,Categories={{CategoryID=0,CategoryScore=60},{CategoryID=1,CategoryScore=40}}},
  {PlayerID=1,PlayerScore=70,Categories={{CategoryID=0,CategoryScore=70}}},
  {PlayerID=2,PlayerScore=200,Categories={{CategoryID=1,CategoryScore=200}}}}
 local function scores() return {{TeamID=0,TeamScore=170,PlayerData={pd[1],pd[2]}},{TeamID=1,TeamScore=200,PlayerData={pd[3]}}} end
 GatherScoreData=scores; GatherGenericData=scores
 local function control(text,hidden,tooltip)
  return {IsHidden=function() return hidden==true end,GetText=function() return text end,GetToolTipString=function() return tooltip or '' end}
 end
 local function instance()
  local t={Value=control('progress'),Details=control('native detail'),Hidden=control('secret',true),CivName=control('ignored name'),PlayerStackIM={Value=control('ignored nested')}}
  t.Cycle=t; return t
 end
 local captureScore,captureGeneric=true,true
 local nativeScore,nativeGeneric,nativeClose=0,0,0
 PopulateScoreInstance=function() end
 PopulateScoreTeamInstance=function(inst,td) PopulateScoreInstance(instance(),td.PlayerData[2]) end
 PopulateGenericInstance=function() end
 PopulateGenericTeamInstance=function(inst,td,victory) for _,p in ipairs(td.PlayerData) do PopulateGenericInstance(instance(),p,victory,false) end end
 PopulateTradDomInstance=bbg and function() end or nil
 PopulateTradDomTeamInstance=bbg and function(inst,td,victory) for _,p in ipairs(td.PlayerData) do PopulateTradDomInstance(instance(),p,victory,false) end end or nil
 Controls={Title=control('Rankings')}
 local active='ScoreView'
 for _,name in ipairs({'OverallView','ScoreView','ScienceView','CultureView','DominationView','ReligionView','GenericView'}) do local key=name; Controls[key]={IsHidden=function() return active~=key end} end
 local hidden=true
 ContextPtr={IsHidden=function() return hidden end,SetInputHandler=function() end,SetShutdown=function() end}
 AddTab=function() end; AddExtraTab=nil; BASE_AddTab=nil
 PopulateTabs=function()
  AddTab(Locale.Lookup('LOC_WORLD_RANKINGS_SCORE_TAB'),function() ViewScore() end)
  AddTab(Locale.Lookup(bbg and 'LOC_TOOLTIP_TRADITIONAL_DOMINATION_BUTTON' or 'Custom'),function() if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end end)
  if xp2 then AddTab(Locale.Lookup('LOC_TOOLTIP_DIPLOMACY_CONGRESS_BUTTON'),function() ViewGeneric('VICTORY_DIPLOMATIC') end) end
 end
 ViewScore=function()
  nativeScore=nativeScore+1; active='ScoreView'
  if captureScore then PopulateScoreInstance(instance(),pd[3]); PopulateScoreTeamInstance(instance(),scores()[1]) end
 end
 ViewGeneric=function(victory)
  nativeGeneric=nativeGeneric+1; active='GenericView'
  if captureGeneric then PopulateGenericTeamInstance(instance(),scores()[1],victory); PopulateGenericInstance(instance(),pd[3],victory,true) end
 end
 ViewTraditionalDomination=bbg and function(victory)
  nativeGeneric=nativeGeneric+1; active='GenericView'
  if captureGeneric then PopulateTradDomTeamInstance(instance(),scores()[1],victory); PopulateTradDomInstance(instance(),pd[3],victory,true) end
 end or nil
 ViewDiplomatic=nil
 for _,name in ipairs({'ViewOverall','ViewScience','ViewCulture','ViewDomination','ViewReligion','OpenCulture','OnShutdown','LateInitialize'}) do _G[name]=function() end end
 Open=function() hidden=false; PopulateTabs(); ViewScore() end
 Close=function() nativeClose=nativeClose+1; hidden=true end
 local nativeInclude=include; local included
 include=function(name)
  if name=='CAIRankingsScore' or name=='CAIRankingsGeneric' then run('src/UI/inGame/'..name..'.lua')
  elseif name=='CAIModSupport' then return
  elseif name:match('^WorldRankings') then included=name
  else nativeInclude(name) end
 end
 run(arg[1] or 'src/UI/inGame/WorldRankings_CAI.lua')
 check(included==expectedInclude,'native include priority '..mode)
 Open(); check(nativeScore==1,'native Score called once')
 local panel=assert(mgr:GetWidgetById('CAIWorldRank_Panel')); local tree=assert(mgr:GetWidgetById('CAIWorldRank_Tree1',true))
 local function snapshot(w,label)
  snapshots[#snapshots+1]=mode..':'..label..':'..w.Type..':'..tostring(w.FocusKey)..':'..tostring(w:GetLabel())..':'..tostring(w:GetTooltip())
  for _,child in ipairs(w.Children or {}) do snapshot(child,label) end
 end
 snapshot(tree,'score-captured')
 check(tree.Children[1].FocusKey=='player:2' and tree.Children[2].Children[1].FocusKey=='team:0:player:1','native ordering and filtered team membership')
 check(#tree.Children[2].Children==1,'native capture omits uncaptured teammate')
 local leaf=assert(mgr:FindByFocusKey(tree,'team:0:player:1:cat:0')); mgr:SetFocus(leaf)
 local before=#H.Speech; ViewScore()
 check(mgr:GetFocusedWidget().FocusKey==leaf.FocusKey and #H.Speech==before,'Score rebuild preserves focus silently')
 local toggle=assert(mgr:GetWidgetById('CAIWorldRank_SwitchView',true)); toggle:Activate()
 local dataTable=assert(mgr:GetWidgetById('CAIWorldRank_Table1',true))
 check(setting=='table','view switch saved')
 local rows=dataTable.RowsProvider(); check(#rows==2 and rows[2].CategoryTotals[0]==70,'Score table uses captured team subset')
 check(dataTable:GetSort()=='total','Score default sort')
 snapshot(dataTable,'score-table')
 toggle:Activate(); check(setting=='tree','return to tree')
 captureScore=false; ViewScore(); check(#tree.Children[2].Children==2,'Score fallback includes both teammates')
 snapshot(tree,'score-fallback')
 met=false; check(tree.Children[1]:GetLabel():find('LOC_DIPLOPANEL_UNMET_PLAYER',1,true),'unmet player identity hidden'); met=true
 if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end
 local generic=assert(mgr:GetWidgetById('CAIWorldRank_Tree2',true))
 check(nativeGeneric==1 and generic.Children[1].FocusKey=='team:0','generic native capture and team')
 snapshot(generic,'generic-captured')
 local row=assert(mgr:FindByFocusKey(generic,'team:0:player:0'))
 check(row:GetLabel():find('progress',1,true) and not row:GetLabel():find('secret',1,true),'visible native presentation retained')
 if bbg then
  check(mgr:FindByFocusKey(generic,'team:0:player:0:detail:1')~=nil,'BBG retains captured details')
  check(generic.Children[#generic.Children]:GetLabel():find('60',1,true),'BBG advisor threshold')
 else
  local req=assert(mgr:FindByFocusKey(generic,'team:0:player:0:req:1'))
  check(req:GetLabel():find('INCOMPLETE_REQ',1,true),'unmet requirement'); reqMet=true
  check(req:GetLabel():find('COMPLETE_REQ',1,true) and not req:GetLabel():find('INCOMPLETE_REQ',1,true),'live requirement state')
 end
 local api=CAI.WorldRankings
 check(api.RegisterGenericVictoryAdapter(vt,{GetRows=function(_,captured) check(#captured==2,'adapter receives captured rows'); return {} end}),'adapter registered')
 if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end
 check(#generic.Children==1,'empty adapter result overrides captured rows')
 api.RegisterGenericVictoryAdapter(vt,{GetRows=function() error('external adapter failure') end})
 if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end
 check(#generic.Children==3,'external adapter failure falls back to capture')
 api.RegisterGenericVictoryAdapter(vt,{GetRows=function() return 'invalid' end})
 if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end
 check(#generic.Children==3,'invalid adapter return falls back to capture')
 api.RegisterGenericVictoryAdapter(vt,{GetRows=function() return nil end})
 captureGeneric=false
 if bbg then ViewTraditionalDomination(vt) else ViewGeneric(vt) end
 check(#generic.Children==3,'nil adapter uses native data fallback')
 if xp2 then
  ViewGeneric('VICTORY_DIPLOMATIC')
  local diplo=assert(mgr:GetWidgetById('CAIWorldRank_Tree3',true))
  check(diplo.Children[1].FocusKey=='team:0','fallback diplomatic order uses best teammate')
  local player=assert(mgr:FindByFocusKey(diplo,'team:0:player:1'))
  check(player:GetLabel():find('DIPLO_POINTS:7:20',1,true),'XP2 diplomatic points')
  points[1]=9; check(player:GetLabel():find('DIPLO_POINTS:9:20',1,true),'live diplomatic readout')
  snapshot(diplo,'diplomatic-fallback')
 end
 Close(); check(nativeClose==1 and mgr:GetTop()==nil,'native close and panel cleanup')
end
if arg[2] then local f=assert(io.open(arg[2],'wb')); f:write(table.concat(snapshots,'\n')); f:close() end
print('World Rankings: '..count..' assertions passed; '..#snapshots..' snapshot lines')
