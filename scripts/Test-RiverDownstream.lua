-- Run from the repository root with a standalone Lua interpreter.
-- Tests the production resolver with a mocked map; changes no game state.
-- Mocked map/visibility APIs validate the resolver against vanilla DoRiver transitions.
-- The live readout still requires in-game verification.
dofile("src/UI/shared/textProcessing.lua")
include = function(name)
 assert(name == "textProcessing", "Unexpected geometry dependency: " .. name)
 dofile("src/UI/shared/textProcessing.lua")
end

FlowDirectionTypes={FLOWDIRECTION_NORTH=0,FLOWDIRECTION_NORTHEAST=1,FLOWDIRECTION_SOUTHEAST=2,FLOWDIRECTION_SOUTH=3,FLOWDIRECTION_SOUTHWEST=4,FLOWDIRECTION_NORTHWEST=5,NO_FLOWDIRECTION=-1}
DirectionTypes={DIRECTION_NORTHEAST=0,DIRECTION_EAST=1,DIRECTION_SOUTHEAST=2,DIRECTION_SOUTHWEST=3,DIRECTION_WEST=4,DIRECTION_NORTHWEST=5}
local deltas={{0,1},{1,0},{1,-1},{0,-1},{-1,0},{-1,1}}
local edgeNames={'NE','E','SE','SW','W','NW'}
local corners={{0,2},{1,1},{1,-1},{0,-2},{-1,-1},{-1,1}}
local flowForward={2,3,4,5,0,1}
local flowReverse={5,0,1,2,3,4}
local world, writes, missing, wrapWidth, nextPlotIndex
local function key(q,r) return q..':'..r end
local function getPlot(q,r)
 if wrapWidth then q=q%wrapWidth end
 local k=key(q,r)
 if missing[k] then return nil end
 if world[k] then return world[k] end
 nextPlotIndex=nextPlotIndex+1
 local p={q=q,r=r,index=nextPlotIndex,flags={},flows={},riverTypes={},revealed=true,water=false}
 function p:GetIndex() return self.index end
 function p:IsRiver() return true end
 function p:IsRiverAdjacent() return true end
 function p:IsRiverSide() return true end
 function p:IsRiverCrossing() return true end
 function p:IsRiverCrossingToPlot() return false end
 function p:GetX() return self.q end
 function p:GetY() return self.r end
 function p:IsWater() return self.water end
 function p:IsLake() return self.lake or false end
 function p:IsWOfRiver() return self.flags.E or false end
 function p:IsNWOfRiver() return self.flags.SE or false end
 function p:IsNEOfRiver() return self.flags.SW or false end
 function p:GetRiverEFlowDirection() return self.flows.E end
 function p:GetRiverSEFlowDirection() return self.flows.SE end
 function p:GetRiverSWFlowDirection() return self.flows.SW end
 world[k]=p
 return p
end
Map={GetAdjacentPlot=function(q,r,d) local v=deltas[d+1];return getPlot(q+v[1],r+v[2]) end}
Map.GetPlotByIndex=function(index) for _,plot in pairs(world)do if plot.index==index then return plot end end end
local function setRiver(p,name,present,flow)
 p.flags[name]=present;p.flows[name]=flow
 writes[#writes+1]={owner=p,edge=name,flow=flow}
end
TerrainBuilder={SetWOfRiver=function(p,b,f)setRiver(p,'E',b,f)end,SetNWOfRiver=function(p,b,f)setRiver(p,'SE',b,f)end,SetNEOfRiver=function(p,b,f)setRiver(p,'SW',b,f)end}
local function reset() world={};writes={};missing={};_rivers={};nextRiverID=1;wrapWidth=nil;nextPlotIndex=0 end
-- Extract the actual mutation/recursive-start stage from the checked-in vanilla source.
local withoutVanilla=arg and arg[1]=='--without-vanilla'
local VanillaFirstRiverStep
if withoutVanilla then
 print('SKIP: vanilla-source transition checks (--without-vanilla); production geometry/readout checks still run')
else
local file=assert(io.open('decompiled/Assets/Maps/Utility/RiversLakes.lua','rb'))
local source=file:read('*a');file:close()
local first=assert(source:find('function DoRiver(',1,true))
local last=assert(source:find('-- Storing X,Y positions as locals',first,true))
local chunk=source:sub(first,last-1):gsub('function DoRiver%(', 'local function VanillaFirstRiverStep(',1)
VanillaFirstRiverStep=assert(load(chunk..'\nreturn riverPlot\nend\nreturn VanillaFirstRiverStep'))()
end

-- Exercise the tooltip's actual initial includes against the already registered VFS.
-- Descriptor expansion is shared; the river resolver still lives in hexCoordUtils.
local bootstrapFile=assert(io.open('src/UI/inGame/PlotToolTip_CAI.lua','rb'))
local bootstrapSource=bootstrapFile:read('*a');bootstrapFile:close()
local bootstrapEnd=assert(bootstrapSource:find('local function IsBarbarianClansModeActive()',1,true))
local bootstrapEnv=setmetatable({include=function(name)
 if name=='hexCoordUtils_CAI' then dofile('src/UI/inGame/hexCoordUtils_CAI.lua')
 elseif name=='CAIDescriptors' then dofile('src/UI/shared/CAIDescriptors.lua')
 else assert(name=='caiUtils' or name=='interfaceInfoHelpers_CAI' or name=='inGameHelpers_CAI' or name=='Civ6Common' or name=='CivRoyaleMapInfo_CAI','Unexpected new VFS dependency: '..name) end
end},{__index=_ENV})
local loadedHex=assert(load(bootstrapSource:sub(1,bootstrapEnd-1)..'\nreturn HexCoordUtils','@PlotToolTip_CAI bootstrap','t',bootstrapEnv))()
assert(loadedHex==CAIHexCoordUtils and type(loadedHex.FindNextDownstreamPlot)=='function')
print('Tooltip bootstrap passed using the existing VFS modules')
local function FindDownstreamBorderingPlot(plot,segment,canInspect,perimeter)
 if segment.dir==nil then segment.dir='LOC_CAI_DIR_'..edgeNames[segment.edgeIndex] end
 if segment.startCorner==nil then
  segment.startCorner=segment.endCorner==segment.edgeIndex and segment.edgeIndex%6+1 or segment.edgeIndex
 end
 local result=CAIHexCoordUtils.FindNextDownstreamPlot(plot,segment,perimeter or {segment},canInspect)
 if result.status=='continuation' then return result,result.status end
 return nil,result.status
end

local function endpoints(record)
 local edgeIndex=({E=2,SE=3,SW=4})[record.edge]
 local start=record.flow==flowForward[edgeIndex] and edgeIndex or edgeIndex%6+1
 local finish=start==edgeIndex and edgeIndex%6+1 or edgeIndex
 local p=record.owner
 local function vertex(i) return {2*p.q+p.r+corners[i][1],3*p.r+corners[i][2]} end
 return vertex(start),vertex(finish)
end
local function sharesEdge(plot,record)
 if plot==record.owner then return true end
 local direction=({E=1,SE=2,SW=3})[record.edge]
 return plot==Map.GetAdjacentPlot(record.owner.q,record.owner.r,direction)
end
local function incomingRelativeTo(plot,record)
 local canonical=({E=2,SE=3,SW=4})[record.edge]
 local edgeIndex=plot==record.owner and canonical or (canonical+2)%6+1
 local finish=record.flow==flowForward[edgeIndex] and edgeIndex%6+1 or edgeIndex
 return {edgeIndex=edgeIndex,endCorner=finish}
end
local checks=0
local function check(v,message) checks=checks+1;assert(v,message) end
local canInspect=function(p)return p.revealed end
-- Use vanilla DoRiver's actual first-step mutation/returned recursive start.
-- For each travel bearing, test both legal turns and both sides' roles.
if VanillaFirstRiverStep then
for flow=0,5 do
 for _,turn in ipairs({-1,1}) do
  reset()
  local recursiveStart=VanillaFirstRiverStep(getPlot(0,0),flow,flow,1)
  local incoming=writes[#writes]
  check(recursiveStart~=nil,'Vanilla incoming step stopped unexpectedly')
  VanillaFirstRiverStep(recursiveStart,(flow+turn+6)%6,flow,1)
  local outgoing=writes[#writes]
  check(outgoing~=incoming,'Vanilla did not create next edge')
  local _,incomingEnd=endpoints(incoming)
  local outgoingStart=endpoints(outgoing)
  check(incomingEnd[1]==outgoingStart[1] and incomingEnd[2]==outgoingStart[2],'Geometry disagrees with vanilla recursive continuation')
  local other=Map.GetAdjacentPlot(incoming.owner.q,incoming.owner.r,({E=1,SE=2,SW=3})[incoming.edge])
  local current=sharesEdge(incoming.owner,outgoing) and other or incoming.owner
  check(not sharesEdge(current,outgoing),'Chosen current plot still borders next edge')
  local segment=incomingRelativeTo(current,incoming)
  local result,status=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(status=='continuation','Failed to find vanilla continuation: '..status)
  check(sharesEdge(result.plot,outgoing),'Recommended next plot does not border next edge')
  check(sharesEdge(result.alternate,outgoing),'Alternate plot does not border next edge')
  check(not sharesEdge(result.plot,incoming),'Recommended step crosses the incoming river edge')
  check(sharesEdge(result.alternate,incoming),'Alternate step should cross incoming river edge')
  check(result.plot==Map.GetAdjacentPlot(current.q,current.r,result.direction),'Cursor direction does not reach target plot')
  print('Vanilla flow '..flow..', turn '..turn..': same-bank cursor '..edgeNames[result.direction+1])
  -- Trace back from vanilla's second edge to its genuine predecessor.
  local otherOutgoing=Map.GetAdjacentPlot(outgoing.owner.q,outgoing.owner.r,({E=1,SE=2,SW=3})[outgoing.edge])
  local upstreamCurrent=sharesEdge(outgoing.owner,incoming) and otherOutgoing or outgoing.owner
  local upstreamSegment=incomingRelativeTo(upstreamCurrent,outgoing)
  upstreamSegment.dir='LOC_CAI_DIR_'..edgeNames[upstreamSegment.edgeIndex]
  upstreamSegment.startCorner=upstreamSegment.endCorner==upstreamSegment.edgeIndex and upstreamSegment.edgeIndex%6+1 or upstreamSegment.edgeIndex
  local upstream=CAIHexCoordUtils.FindNextUpstreamPlot(upstreamCurrent,upstreamSegment,{upstreamSegment},canInspect)
  check(upstream.status=='continuation','Failed to trace vanilla predecessor upstream')
  check(sharesEdge(upstream.plot,incoming) and sharesEdge(upstream.alternate,incoming),'Upstream plots must border the actual predecessor')
  check(not sharesEdge(upstream.plot,outgoing) and sharesEdge(upstream.alternate,outgoing),'Upstream cursor must remain on the current bank')
  check(upstream.plot==Map.GetAdjacentPlot(upstreamCurrent.q,upstreamCurrent.r,upstream.direction),'Upstream cursor step must reach its plot')
  local owner=outgoing.owner
  local outgoingFlow=outgoing.flow
  local name=outgoing.edge
  owner.flags[name]=false
  local none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none==nil and reason=='no_continuation','Absent edge should not guess a target')
  owner.flags[name]=true;owner.flows[name]=(outgoingFlow+3)%6
  none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none==nil and reason=='no_continuation','Incoming tributary should not become downstream target')
  owner.flows[name]=-1
  none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none==nil and reason=='unknown_flow','Unknown flow should not guess a target')
  owner.flows[name]=outgoingFlow;result.plot.revealed=false
  none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none==nil and reason=='unrevealed','Unrevealed target must remain unknown')
  result.plot.revealed=true;result.plot.water=true
  none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none~=nil and reason=='continuation' and none.plot==result.plot,'Cursor may follow a known edge onto a revealed water plot')
  result.plot.water=false;missing[key(result.plot.q,result.plot.r)]=true
  none,reason=FindDownstreamBorderingPlot(current,segment,canInspect)
  check(none==nil and reason=='map_edge','Missing neighbour must be distinguished')
 end
end
-- Exact SE/SW example: next external edge is W neighbour's SE flowing SW.
end
reset()
local current=getPlot(0,0)
local west=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_WEST)
west.flags.SE=true;west.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
local result,status=FindDownstreamBorderingPlot(current,{edgeIndex=4,endCorner=5},canInspect)
check(status=='continuation' and result.direction==DirectionTypes.DIRECTION_WEST,'SE/SW must recommend west when outgoing continuation exists')
check(result.alternate==Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_SOUTHWEST),'SE/SW other bank must be southwest')
print('SE/SW example: confirmed outgoing edge -> west cursor step; southwest is the other bank')

-- Actual directed perimeter flow can continue across named-river boundaries.
reset()
current=getPlot(0,0)
local tributary={dir='LOC_CAI_DIR_NE',startCorner=1,endCorner=2,river='tributary'}
local trunk1={dir='LOC_CAI_DIR_E',startCorner=2,endCorner=3,river='main river'}
local trunk2={dir='LOC_CAI_DIR_SE',startCorner=3,endCorner=4,river='main river'}
local perimeter={tributary,trunk1,trunk2}
local southwest=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_SOUTHWEST)
southwest.flags.E=true;southwest.flows.E=FlowDirectionTypes.FLOWDIRECTION_SOUTH
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,tributary,perimeter,canInspect)
check(result.status=='continuation' and result.direction==DirectionTypes.DIRECTION_SOUTHWEST,'Confluence must follow real flow into the next plot across a name change')
-- A real fork: one outgoing edge remains on the perimeter, another exits it.
local northeast=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
northeast.flags.SE=true;northeast.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,tributary,perimeter,canInspect)
check(result.status=='ambiguous' and result.plot==nil,'Outgoing perimeter plus external edge is ambiguous')
northeast.flags.SE=false
local unknown={dir='LOC_CAI_DIR_E'}
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,tributary,{tributary,unknown},canInspect)
check(result.status=='unknown_flow','Unknown touching perimeter segment must prevent guessed continuation')
local circle={}
for i,name in ipairs(edgeNames) do circle[i]={dir='LOC_CAI_DIR_'..name,startCorner=i,endCorner=i%6+1} end
reset();current=getPlot(0,0)
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,circle[1],circle,canInspect)
check(result.status=='cycle','Closed perimeter loop must terminate')
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,{dir='LOC_CAI_DIR_E'},{{dir='LOC_CAI_DIR_E'}},canInspect)
check(result.status=='unknown_flow','Unknown starting flow must remain unknown')
-- Do not inspect a concealed external edge, even at an interior junction.
reset();current=getPlot(0,0)
northeast=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
northeast.revealed=false
northeast.IsNWOfRiver=function() error('Unrevealed river data was inspected') end
result=CAIHexCoordUtils.FindNextDownstreamPlot(current,tributary,perimeter,canInspect)
check(result.status=='unrevealed','Unrevealed branch must prevent an unverified route')
reset();wrapWidth=5
current=getPlot(0,0);west=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_WEST)
west.flags.SE=true;west.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
result,status=FindDownstreamBorderingPlot(current,{edgeIndex=4,endCorner=5},canInspect)
check(status=='continuation' and result.direction==DirectionTypes.DIRECTION_WEST and result.plot.q==4,'Wrapped-map target should be resolved through Map.GetAdjacentPlot')
local savedGetter=west.GetRiverSEFlowDirection
west.GetRiverSEFlowDirection=nil
local none,why=FindDownstreamBorderingPlot(current,{edgeIndex=4,endCorner=5},canInspect)
check(none==nil and why=='unknown_flow','Missing external flow getter must not guess')
west.GetRiverSEFlowDirection=savedGetter;west.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTH
none,why=FindDownstreamBorderingPlot(current,{edgeIndex=4,endCorner=5},canInspect)
check(none==nil and why=='unknown_flow','Geometrically incompatible flow must remain unknown')
print('Junctions/forks, unknown perimeter flow, cycles, visibility, wrapping and getter failures passed')


-- Backtrack a directed perimeter across names; never choose between tributaries.
reset();current=getPlot(0,0)
local start={dir='LOC_CAI_DIR_NE',startCorner=1,endCorner=2,river='tributary'}
local middle={dir='LOC_CAI_DIR_E',startCorner=2,endCorner=3,river='main'}
local finish={dir='LOC_CAI_DIR_SE',startCorner=3,endCorner=4,river='main'}
local upstreamPerimeter={start,middle,finish}
local nw=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHWEST)
nw.flags.E=true;nw.flows.E=FlowDirectionTypes.FLOWDIRECTION_SOUTH
result=CAIHexCoordUtils.FindNextUpstreamPlot(current,finish,upstreamPerimeter,canInspect)
check(result.status=='continuation' and result.direction==DirectionTypes.DIRECTION_NORTHWEST,'Upstream must trace incoming perimeter connections across river names')
local ne=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
ne.flags.SE=true;ne.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
result=CAIHexCoordUtils.FindNextUpstreamPlot(current,finish,upstreamPerimeter,canInspect)
check(result.status=='ambiguous' and result.plot==nil,'Two incoming tributaries must not produce a guessed upstream route')
ne.flags.SE=false
result=CAIHexCoordUtils.FindNextUpstreamPlot(current,finish,{finish,{dir='LOC_CAI_DIR_E'}},canInspect)
check(result.status=='unknown_flow','Unknown upstream perimeter flow must prevent a cursor direction')
nw.GetRiverEFlowDirection=nil
result=CAIHexCoordUtils.FindNextUpstreamPlot(current,finish,upstreamPerimeter,canInspect)
check(result.status=='unknown_flow','Missing upstream external getter must prevent a cursor direction')
reset();current=getPlot(0,0)
result=CAIHexCoordUtils.FindNextUpstreamPlot(current,circle[1],circle,canInspect)
check(result.status=='cycle','Upstream perimeter cycles must terminate')

-- Exhaust all 729 absent/forward/reverse perimeter arrangements with each
-- external corner edge absent, incoming, or outgoing. Any returned target
-- must border a real outgoing edge and be reached by its announced cursor step.
local canonical={{2,'E'},{3,'SE'},{4,'SW'}}
local external={
 {owner=5,edge='E',flow=0,a=5,b=0},
 {owner=0,edge='SE',flow=1,a=0,b=1},
 {owner=1,edge='SW',flow=2,a=1,b=2},
 {owner=3,edge='E',flow=3,a=2,b=3},
 {owner=4,edge='SE',flow=4,a=3,b=4},
 {owner=5,edge='SW',flow=5,a=4,b=5},
}
for arrangement=0,728 do
 local states={};local n=arrangement
 for i=1,6 do states[i]=n%3;n=math.floor(n/3)end
 for corner,edge in ipairs(external)do
  for outsideState=0,2 do
   reset();current=getPlot(0,0)
   local perimeter={}
   for i=1,6 do
    if states[i]~=0 then
     local owner=current
     local name=({[1]='SW',[2]='E',[3]='SE',[4]='SW',[5]='E',[6]='SE'})[i]
     if i==1 or i==5 or i==6 then owner=Map.GetAdjacentPlot(0,0,i-1)end
     owner.flags[name]=true
     owner.flows[name]=states[i]==1 and flowForward[i] or flowReverse[i]
     perimeter[#perimeter+1]={dir='LOC_CAI_DIR_'..edgeNames[i],startCorner=states[i]==1 and i or i%6+1,endCorner=states[i]==1 and i%6+1 or i}
    end
   end
   local owner=Map.GetAdjacentPlot(0,0,edge.owner)
   owner.flags[edge.edge]=outsideState~=0
   owner.flows[edge.edge]=outsideState==1 and edge.flow or (edge.flow+3)%6
   for _,segment in ipairs(perimeter)do
    local u=CAIHexCoordUtils.FindNextUpstreamPlot(current,segment,perimeter,canInspect)
    if u.status=='continuation' then
     check(outsideState==2,'An upstream target requires an actual incoming external edge')
     local a=Map.GetAdjacentPlot(0,0,edge.a)
     local b=Map.GetAdjacentPlot(0,0,edge.b)
     check((u.plot==a and u.alternate==b) or (u.plot==b and u.alternate==a),'Upstream plot must border the incoming edge')
     check(u.plot==Map.GetAdjacentPlot(0,0,u.direction),'Upstream cursor step must reach the returned plot')
    else
     check(u.plot==nil,'Unresolved upstream route must not guess a plot')
    end
    local r=CAIHexCoordUtils.FindNextDownstreamPlot(current,segment,perimeter,canInspect)
    if r.status=='continuation' then
     check(outsideState==1,'A downstream target requires an actual outgoing external edge')
     local a=Map.GetAdjacentPlot(0,0,edge.a)
     local b=Map.GetAdjacentPlot(0,0,edge.b)
     check((r.plot==a and r.alternate==b) or (r.plot==b and r.alternate==a),'Next plot must border the known external edge')
     check(r.plot==Map.GetAdjacentPlot(0,0,r.direction),'Announced cursor step must reach the returned plot')
    else
     check(r.plot==nil,'Unresolved continuation must not provide a guessed target')
    end
   end
  end
 end
end
print('All 729 perimeter arrangements and external-edge directions passed')

-- Exercise the actual speech formatter and resolver together, not a copied formatter.
local function TestRiverReadout()
 local orderDownstream=true
 CAISettings={GetBool=function(id)assert(id=='OrderGeographyRiversDownstream');return orderDownstream end}
 info={IsPlotVisible=canInspect}
 IsExpansion2Active=function()return true end
 local IS_XP2_TOOLTIP=true
 LogMessage=function()end
 local labels={LOC_CAI_WORLD_SCANNER_GROUP_RIVERS='Rivers',LOC_TOOLTIP_RIVER='River',LOC_DIRECTION_NORTH='north',LOC_DIRECTION_NORTH_EAST='northeast',LOC_DIRECTION_EAST='east',LOC_DIRECTION_SOUTH_EAST='southeast',LOC_DIRECTION_SOUTH='south',LOC_DIRECTION_SOUTH_WEST='southwest',LOC_DIRECTION_WEST='west',LOC_DIRECTION_NORTH_WEST='northwest'}
 for _,name in ipairs(edgeNames)do labels['LOC_CAI_DIR_'..name]=name end
 Locale={Lookup=function(tag,a,b,c)
  if labels[tag] then return labels[tag] end
  if tag:match('^River %d+$') then return tag end
  if tag=='LOC_CAI_RIVER_DESTINATION_COAST' then return 'leads to coast' end
  if tag=='LOC_CAI_RIVER_DESTINATION_LAKE' then return 'leads to lake' end
  if tag=='LOC_CAI_RIVER_WITH_DESTINATION' then return a..': '..b end
  if tag=='LOC_CAI_RIVER_DESCRIPTION_WITH_DESTINATION' then return a..', '..b end
  if tag=='LOC_CAI_PLOT_RIVER_WITH_DIRECTIONS' then return a..', '..b end
  if tag=='LOC_CAI_PLOT_RIVER_FLOW' then return a..', flows '..b end
  if tag=='LOC_CAI_PLOT_RIVER_FLOW_FROM_TO' then return a..', flows from '..b..' to '..c end
  error('Unexpected localization '..tag)
 end}
 RiverManager={EnumerateRivers=function(index)
  local records={}
  -- Adjacent-plot lookups create mock plots. Snapshot before those lookups so
  -- adding hash keys cannot skip existing river owners during pairs traversal.
  local owners={}
  for _,owner in pairs(world)do owners[#owners+1]=owner end
  for _,owner in ipairs(owners)do
   for _,entry in ipairs({{'E',1},{'SE',2},{'SW',3}})do
    if owner.flags[entry[1]] then
     local other=Map.GetAdjacentPlot(owner.q,owner.r,entry[2])
     if other then
      local id=owner.riverTypes[entry[1]] or 1
      if not records[id] then records[id]={Name='River '..id,TypeID=id,Edges={}} end
      table.insert(records[id].Edges,{owner.index,other.index})
     end
    end
   end
  end
  local touching={}
  for _,record in pairs(records)do
   for _,pair in ipairs(record.Edges)do
    if pair[1]==index or pair[2]==index then touching[#touching+1]=record;break end
   end
  end
  return touching
 end}
 local tooltipFile=assert(io.open('src/UI/inGame/PlotToolTip_CAI.lua','rb'))
 local tooltipSource=tooltipFile:read('*a');tooltipFile:close()
 local begin=assert(tooltipSource:find('local RIVER_SELF_EDGES =',1,true))
 local finish=assert(tooltipSource:find('---@type table<string, fun(data:table, plot:table, arg:string|nil):string|string[]|nil>',begin,true))
 assert(not tooltipSource:find('include("CAIRiverNavigation")',1,true))
 local riverFunctions='local HexCoordUtils=CAIHexCoordUtils\nlocal IS_XP2_TOOLTIP=true\n'..tooltipSource:sub(begin,finish-1)..'\nreturn GetNamedRiverString'
 local GetNamedRiverString=assert(load(riverFunctions,'@PlotToolTip_CAI river functions','t',_ENV))()
 local data={IsVisible=true,IsRiver=true,RiverNames={'River 1'}}
 local function equal(actual,expected)
  check(actual==expected,tostring(actual)..' != '..expected)
 end
 reset();local p=getPlot(0,0)
 p.flags.SE=true;p.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
 p.flags.SW=true;p.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 local w=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_WEST)
 w.flags.SE=true;w.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
 local e=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_EAST)
 e.flags.SW=true;e.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE SW, flows from east to west')
 orderDownstream=false
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE SW, flows from east to west')
 e.flags.SW=false
 w.revealed=false
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE SW, flows northwest')
 w.revealed=true;w.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE SW, flows northwest')
 w.flows.SE=-1
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE SW, flows northwest')
 reset();p=getPlot(0,0)
 p.flags.SE=true;p.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 local ne=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
 ne.flags.SE=true;ne.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
 equal(GetNamedRiverString(data,p),'Rivers: River 1, E SE, flows northeast')
 orderDownstream=true
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE E, flows northeast')
 -- Reported four-edge bend: the cursor continuation replaces segment southwest.
 reset();p=getPlot(0,0)
 p.flags.SE=true;p.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 ne=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
 ne.flags.SW=true;ne.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 local nw=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHWEST)
 nw.flags.SE=true;nw.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST
 nw.flags.SW=true;nw.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE E NE NW, flows west')
 local sw=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_SOUTHWEST)
 sw.flags.E=true;sw.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 equal(GetNamedRiverString(data,p),'Rivers: River 1, SE E NE NW, flows from southwest to west')
 orderDownstream=false
 equal(GetNamedRiverString(data,p),'Rivers: River 1, NE E SE NW, flows from southwest to west')
 orderDownstream=true
 -- A mouth without an outgoing edge keeps the final game-provided flow.
 reset();p=getPlot(0,0)
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST).water=true
 Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_EAST).water=true
 equal(GetNamedRiverString(data,p),'Rivers: River 1, E, flows north, leads to coast')
 local e=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_EAST)
 e.flags.SW=true;e.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 equal(GetNamedRiverString(data,p),'Rivers: River 1, E, flows from southeast to north, leads to coast')
 e.revealed=false
 e.IsNEOfRiver=function()error('Hidden upstream edge was inspected')end
 equal(GetNamedRiverString(data,p),'Rivers: River 1, E, flows north')
 -- A distinct incoming named river joins the main river before leaving this plot.
 reset();p=getPlot(0,0)
 ne=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
 ne.flags.SW=true;ne.flows.SW=FlowDirectionTypes.FLOWDIRECTION_SOUTHEAST;ne.riverTypes.SW=1
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_SOUTH;p.riverTypes.E=2
 p.flags.SE=true;p.flows.SE=FlowDirectionTypes.FLOWDIRECTION_SOUTHWEST;p.riverTypes.SE=2
 local sw=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_SOUTHWEST)
 sw.flags.E=true;sw.flows.E=FlowDirectionTypes.FLOWDIRECTION_SOUTH;sw.riverTypes.E=2
 equal(GetNamedRiverString(data,p),'Rivers: River 1, NE, flows southwest. River 2, E SE, flows southwest')
 ne.flags.SE=true;ne.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST;ne.riverTypes.SE=1
 check(GetNamedRiverString(data,p):find('River 1, NE, flows southeast',1,true)~=nil,'A fork must retain the actual segment flow without choosing a cursor direction')
 -- Visibility callback is the existing observer/World Builder-aware plot check.
 info.IsPlotVisible=function()return false end
 check(GetNamedRiverString(data,p):find('River 1, NE, flows southeast',1,true)~=nil,'Hidden continuation must retain the actual segment flow')
 -- Every bearing and bank must identify the downstream mouth, never nearby source water.
 info.IsPlotVisible=canInspect
 local cornerDirections={{5,0},{0,1},{1,2},{2,3},{3,4},{4,5}}
 for edgeIndex=1,6 do
  for _,forward in ipairs({true,false})do
   for _,lake in ipairs({false,true})do
    reset()
    local p=getPlot(0,0)
    local neighbor=Map.GetAdjacentPlot(0,0,edgeIndex-1)
    local canonical=({4,2,3,4,2,3})[edgeIndex]
    local owner=(edgeIndex==1 or edgeIndex>=5)and neighbor or p
    local edge=edgeNames[canonical]
    owner.flags[edge]=true;owner.flows[edge]=forward and flowForward[edgeIndex]or flowReverse[edgeIndex]
    local segment={dir='LOC_CAI_DIR_'..edgeNames[edgeIndex],startCorner=forward and edgeIndex or edgeIndex%6+1,endCorner=forward and edgeIndex%6+1 or edgeIndex}
    check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='unknown','Dry endpoint is not a known destination')
    local directions=cornerDirections[segment.endCorner]
    local mouth=Map.GetAdjacentPlot(0,0,directions[1])
    mouth.water=true;mouth.lake=lake
    local kind=lake and 'lake'or 'coast'
    check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)==kind,'Mouth mismatch for edge '..edgeIndex)
    check(CAIHexCoordUtils.GetRiverZoneDestination({p.index},1,canInspect)==kind,'Named scanner destination must match B')
    check(CAIHexCoordUtils.GetRiverZoneDestination({p.index},nil,canInspect)==kind,'Generic scanner destination must match B')
    check(CAIHexCoordUtils.GetRiverZoneDestination({p.index},99,canInspect)=='unknown','Another named river must not inherit this mouth')
    -- Poison hidden APIs: reveal gates must run before any state read.
    mouth.revealed=false
    mouth.IsWater=function()error('Hidden mouth water was inspected')end
    mouth.IsLake=function()error('Hidden mouth lake was inspected')end
    mouth.IsWOfRiver=function()error('Hidden mouth river was inspected')end
    mouth.IsNWOfRiver=mouth.IsWOfRiver;mouth.IsNEOfRiver=mouth.IsWOfRiver
    check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='unknown','Hidden mouth must stay unknown')
    check(CAIHexCoordUtils.GetRiverZoneDestination({p.index},1,canInspect)=='unknown','Scanner must hide an unrevealed mouth')
   end
  end
 end
 -- Trace a bend using two actual vanilla mutations, from either bank of the first edge.
 if VanillaFirstRiverStep then
 for flow=0,5 do
  for _,turn in ipairs({-1,1})do
   reset()
   local recursiveStart=VanillaFirstRiverStep(getPlot(0,0),flow,flow,1)
   local incoming=writes[#writes]
   VanillaFirstRiverStep(recursiveStart,(flow+turn+6)%6,flow,1)
   local outgoing=writes[#writes]
   local outSegment=incomingRelativeTo(outgoing.owner,outgoing)
   local directions=cornerDirections[outSegment.endCorner]
   -- The third plot at the downstream corner is not either bank of the last edge.
   local canonical=({E=2,SE=3,SW=4})[outgoing.edge]
   local third=directions[1]==canonical-1 and directions[2]or directions[1]
   Map.GetAdjacentPlot(outgoing.owner.q,outgoing.owner.r,third).water=true
   for _,bank in ipairs({incoming.owner,Map.GetAdjacentPlot(incoming.owner.q,incoming.owner.r,({E=1,SE=2,SW=3})[incoming.edge])})do
    local segment=incomingRelativeTo(bank,incoming)
    segment.dir='LOC_CAI_DIR_'..edgeNames[segment.edgeIndex]
    segment.startCorner=segment.endCorner==segment.edgeIndex and segment.edgeIndex%6+1 or segment.edgeIndex
    check(CAIHexCoordUtils.GetRiverDestination(bank,segment,canInspect)=='coast','Vanilla bend must reach its mouth')
   end
  end
 end
 end
 -- Uncertain topology must not become a destination just because water is nearby.
 reset()
 local p=getPlot(0,0)
 local segment={dir='LOC_CAI_DIR_E',startCorner=3,endCorner=2}
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 local ne=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
 ne.flags.SW=true;ne.flows.SW=FlowDirectionTypes.FLOWDIRECTION_NORTHWEST
 ne.flags.SE=true;ne.flows.SE=FlowDirectionTypes.FLOWDIRECTION_NORTHEAST
 ne.water=true
 check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='unknown','Outgoing fork remains unknown beside water')
 reset();p=getPlot(0,0)
 for edgeIndex=1,6 do
  local neighbor=Map.GetAdjacentPlot(0,0,edgeIndex-1)
  local owner=(edgeIndex==1 or edgeIndex>=5)and neighbor or p
  local edge=edgeNames[({4,2,3,4,2,3})[edgeIndex]]
  owner.flags[edge]=true;owner.flows[edge]=flowForward[edgeIndex]
 end
 segment={dir='LOC_CAI_DIR_E',startCorner=2,endCorner=3}
 check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='unknown','Directed cycle must stop without claiming a destination')
 reset();p=getPlot(0,0)
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST).water=true
 p.GetRiverEFlowDirection=nil
 segment={dir='LOC_CAI_DIR_E',startCorner=3,endCorner=2}
 check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='unknown','Missing flow getter cannot infer a water destination')
 reset();wrapWidth=8;p=getPlot(7,0)
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 Map.GetAdjacentPlot(7,0,DirectionTypes.DIRECTION_EAST).water=true
 check(CAIHexCoordUtils.GetRiverDestination(p,segment,canInspect)=='coast','Destination tracing must honor horizontal wrapping')
 -- Validate the scanner's live label hook, including tile counts and reveal changes.
 reset()
 local p=getPlot(0,0)
 p.flags.E=true;p.flows.E=FlowDirectionTypes.FLOWDIRECTION_NORTH
 local mouth=Map.GetAdjacentPlot(0,0,DirectionTypes.DIRECTION_NORTHEAST)
 mouth.water=true;mouth.lake=true
 RiverManager.GetRiverNameByType=function(id)assert(id==1);return 'River 1'end
 local scannerFile=assert(io.open('src/UI/inGame/WorldScanner/WorldScannerCategory_geography.lua','rb'))
 local scannerSource=scannerFile:read('*a');scannerFile:close()
 local first=assert(scannerSource:find('local function UpdateRiverZoneLabel(',1,true))
 local last=assert(scannerSource:find('local function CollectRiver(',first,true))
 local env=setmetatable({HexCoordUtils=CAIHexCoordUtils,
  Utils={IsPlotRevealed=function(_,plot)return canInspect(plot)end,ResolveText=function(text)return text end},
  ZoneUtils={MakeTileCountLabel=function(label,indices)return label..', '..#indices..' tiles'end}}, {__index=_ENV})
 local updateLabel=assert(load(scannerSource:sub(first,last-1)..'return UpdateRiverZoneLabel','@Scanner river label','t',env))()
 local item={ZonePlotIndices={p.index},RiverType=1}
 updateLabel(item,{})
 check(item.LabelKey=='River 1: leads to lake, 1 tiles','Scanner destination follows the name before tile count')
 check(GetNamedRiverString(data,p)=='Rivers: River 1, E, flows north, leads to lake','B must append a lake destination after flow directions')
 mouth.revealed=false;updateLabel(item,{})
 check(item.LabelKey=='River 1, 1 tiles','Scanner must omit an unknown destination without leaving punctuation')
 check(GetNamedRiverString(data,p)=='Rivers: River 1, E, flows north','B must omit an unknown destination without leaving punctuation')
 mouth.revealed=true;mouth.lake=false;updateLabel(item,{})
 check(item.LabelKey=='River 1: leads to coast, 1 tiles','Scanner label must recalculate water state')
 IsExpansion2Active=function()return false end
 check(GetNamedRiverString({IsVisible=true,IsRiver=true},p)=='River, E, leads to coast','Generic non-XP2 geography must append the destination after directions')
 IsExpansion2Active=function()return true end
 print('Full Geography/B formatter, destination and live scanner integration checks passed')
end
TestRiverReadout()

-- The shared location reader must use live cursor state across context changes.
local savedMembers, savedLookup, savedDirection = ExposedMembers, Map.GetPlotByIndex, CAIHexCoordUtils.directionString
ExposedMembers = {}
Map.GetPlotByIndex = function(id)
 if id == 7 then return { GetX=function()return 3 end, GetY=function()return 4 end } end
end
CAIHexCoordUtils.directionString = function(x,y,tx,ty)return x..':'..y..'>'..tx..':'..ty end
check(CAIHexCoordUtils.relativePlotLocation(nil)=='','missing location id')
check(CAIHexCoordUtils.relativePlotLocation(9)=='','missing location plot')
check(CAIHexCoordUtils.relativePlotLocation(7)=='','cursor not initialized')
check(CAIHexCoordUtils.appendRelativePlotLocation('city',7)=='city','no direction leaves label unchanged')
ExposedMembers.CAICursor={GetCoords=function()return 1,2 end}
check(CAIHexCoordUtils.relativePlotLocation(7)=='1:2>3:4','cursor becomes available')
ExposedMembers.CAICursor={GetCoords=function()return 5,6 end}
check(CAIHexCoordUtils.appendRelativePlotLocation('city',7)=='city, 5:6>3:4','replacement cursor read live')
ExposedMembers.CAICursor={GetCoords=function()return nil,nil end}
check(CAIHexCoordUtils.relativePlotLocation(7)=='','cursor coordinates not initialized')
ExposedMembers, Map.GetPlotByIndex, CAIHexCoordUtils.directionString = savedMembers, savedLookup, savedDirection
print('Production upstream/downstream navigation checks passed: '..checks..' assertions'..(withoutVanilla and ' (vanilla-source checks skipped)' or ' against vanilla transitions and edge cases'))
