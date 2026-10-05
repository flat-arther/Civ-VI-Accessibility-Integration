-- Production scanner traversal/model checks; optional baseline skips the new error policy.
local count=0
local function check(v,label) count=count+1; assert(v,label) end
LogMessage=function() end; LogWarn=function() end; LogError=function() end
Locale={Lookup=function(s) return s end,Compare=function(a,b) return a==b and 0 or (a<b and -1 or 1) end}
GetWorldBuilderRevealGate=function() return false end
PlayerTypes={OBSERVER=-1}
local reads,reveals=0,0
local plots={}
for i=0,3 do local id=i; plots[i]={GetIndex=function() return id end,GetX=function() return id end,GetY=function() return 0 end} end
Map={GetPlotCount=function() return 4 end,GetPlotByIndex=function(i) reads=reads+1; return plots[i] end,
 GetPlotDistance=function(x,y,a,b) return math.abs(x-a)+math.abs(y-b) end}
PlayersVisibility={[0]={IsRevealed=function(_,p) reveals=reveals+1; return p:GetIndex()~=2 end},
 [1]={IsRevealed=function(_,p) reveals=reveals+1; return p:GetIndex()==2 end}}
dofile('src/UI/inGame/WorldScanner/WorldScannerCategoryUtils.lua')
CAIWorldScannerZoneUtils={}
dofile(arg[1] or 'src/UI/inGame/WorldScanner/WorldScannerCore.lua')
local C=CAIWorldScannerCore
local context={ObserverID=0,SortOriginX=0,SortOriginY=0}
local trace={}
local function mark(s) trace[#trace+1]=s end
local function item(id) return {Id=tostring(id),PlotIndex=id,LabelKey='plot'..id,GroupId='group',SubCategoryId='sub',Validate=function() error('must not validate fresh items') end} end
local function extractor(id,hidden)
 return {Id=id,LabelKey=id,ExtractHiddenPlots=hidden,SubCategoryOrder={'sub'},SubCategoryLabels={sub='sub'},
  CanScan=function(c) check(c==context,'CanScan context'); mark(id..':can'); return true end,
  BeginExtract=function(...) check(select('#',...)==0,'BeginExtract no args'); mark(id..':begin') end,
  PlotExtract=function(i,p,c,collect,revealed) check(p==plots[i] and c==context,'extract arguments'); mark(id..':'..i..':'..tostring(revealed)); collect(item(i)) end,
  EndExtract=function(c,collect) check(c==context and type(collect)=='function','EndExtract arguments'); mark(id..':end') end}
end
local a=extractor('a',false); local b=extractor('b',true)
local scan={Id='scan',Scan=function(c) check(c==context,'Scan context'); mark('scan'); return {item(1)} end}
local skipped={Id='skipped',CanScan=function() return false end,Scan=function() error('ineligible scanned') end}
local empty={Id='empty',Scan=function() return nil end}
local results=C.BuildAllCategories({a,b,scan,skipped,empty},context)
check(reveals==4,'one reveal pass shared across extractors')
check(results.a.TotalItems==3 and results.b.TotalItems==4,'reveal and hidden extraction contracts')
check(results.scan.TotalItems==1 and results.skipped==nil and results.empty==nil,'scan, gate and nil results')
check(table.concat(trace,',')=='a:can,b:can,a:begin,b:begin,a:0:true,a:1:true,a:3:true,b:0:true,b:1:true,b:2:false,b:3:true,a:end,b:end,scan','batch callback ordering')
check(#results.a.LeafMemberships['1']==2,'membership includes all and named subcategory')
local group=results.a.SubCategories[1].Groups[1]
check(group.Items[1].Id=='0' and group.Items[3].Id=='3','distance order retained')
trace={}; reveals=0; local single=C.BuildCategory(a,context)
check(single.TotalItems==results.a.TotalItems and reveals==4,'single build matches batch')
check(table.concat(trace,',')=='a:can,a:begin,a:0:true,a:1:true,a:3:true,a:end','single callback ordering')
local scored={Id='scored',Scan=function() local x,y=item(0),item(3); x.SortValue=2; y.SortValue=9; return {x,y} end}
check(C.BuildCategory(scored,context).SubCategories[1].Groups[1].Items[1].Id=='3','metric ordering before distance')
local scanner={Categories={{Definition=skipped,Category=false},{Definition=a,Category=results.a}},CategoryIndex=2,SubCategoryIndex=1,GroupIndex=1,ItemIndex=2}
local focus=C.CaptureFocus(scanner)
check(focus.CategoryId=='a' and focus.ItemId=='1','model identity capture')
scanner.Categories={{Definition=a,Category=C.BuildCategory(a,context)},{Definition=skipped,Category=false}}
C.RestoreFocus(scanner,focus)
check(scanner.CategoryIndex==1 and C.GetCurrentItem(scanner).Id=='1','model restore across reordered slots')
check(C.PruneItem(scanner.Categories[1].Category,'1'),'prune indexed item')
local pruned=scanner.Categories[1].Category
check(pruned.TotalItems==2 and pruned.SubCategories[2].TotalItems==2 and pruned.LeafMemberships['1']==nil,'prune all memberships')
C.RestoreFocus(scanner,focus); check(C.GetCurrentItem(scanner).Id=='0','removed model selection fallback')
context.ObserverID=1
local changed=C.BuildCategory(a,context)
check(changed.TotalItems==1 and changed.SubCategories[1].Groups[1].Items[1].Id=='2','observer change uses live reveal state')
context.ObserverID=0
if not arg[1] then
 -- Both build paths must propagate every bundled callback failure unchanged.
 local marker={}
 for _,phase in ipairs({'CanScan','BeginExtract','PlotExtract','EndExtract','Scan'}) do
  for _,batch in ipairs({false,true}) do
   local d={Id='broken'}
   if phase=='BeginExtract' or phase=='EndExtract' then d.PlotExtract=function() end end
   d[phase]=function() error(marker) end
   local ok,err=pcall(function() if batch then C.BuildAllCategories({d},context) else C.BuildCategory(d,context) end end)
   check(not ok and err==marker,phase..' propagates in '..tostring(batch))
  end
 end
end
print('Scanner core: '..count..' assertions passed')
