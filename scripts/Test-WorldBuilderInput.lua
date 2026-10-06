-- Production interface/edit widgets; engine placement is recorded, never executed.
-- Optional argument loads the previous WorldInput implementation for comparison.
local H=dofile("scripts/test-support/WidgetHarness.lua")
local mgr=H.CreateManager()
local count=0
local function check(value,label) count=count+1; assert(value,label) end
local s={cursor=12,active=true,edge=nil,visibility=nil,undo=false,redo=false,trace={},sight=0,owner=0,scanner=true}
local function record(name,...) local values={name}; for _,v in ipairs({...}) do values[#values+1]=tostring(v) end; s.trace[#s.trace+1]=table.concat(values,":") end
local function trace() return table.concat(s.trace,",") end
local function reset() s.trace={} end
Locale.Lookup=function(tag) return tag end
Locale.GetCurrentLanguage=function() return {Type="en_US"} end
local function plot(id)
    return {GetIndex=function() return id end,GetX=function() return id%10 end,GetY=function() return math.floor(id/10) end}
end
Map={IsPlot=function(id) return type(id)=="number" and id>=0 and id<100 end,
    GetPlot=function(x,y) if x>=0 and x<10 and y>=0 and y<10 then return plot(y*10+x) end end,
    GetPlotByIndex=function(id) if id>=0 and id<100 then return plot(id) end end}
UI={GetCursorNearestPlotEdge=function() return 5 end,LookAtPlot=function() end,PlaySound=function() end}
WorldBuilder={IsActive=function() return s.active end,CanUndo=function() return s.undo end,CanRedo=function() return s.redo end,
    Undo=function() record("undo") end,Redo=function() record("redo") end}
CAICursor={GetCoords=function() if s.cursor==nil then return end; return s.cursor%10,math.floor(s.cursor/10) end,
    MoveTo=function(_,id,reason) s.cursor=id; record("move",id,reason) end}
GetCurrentCAICursorPlotId=function() return s.cursor end
CAIWorldScanner={GetActiveState=function() if s.scanner then return {} end end,RebuildCategory=function(_,name) record("scan",name) end}
CAI.Info={GetWorldBuilderVisibilityPlayer=function() return s.visibility end,
    EditWorldBuilderVisibility=function(id,add) record("visibility",id,add) end,
    GetWorldBuilderEdgeDirection=function() return s.edge end}
CAI.WorldBuilderVisibilityManager={RecomputeSight=function() s.sight=s.sight+1; s.seenOwner=s.owner end}
for _,event in ipairs({"CAIWorldBuilderStatusBurstBegin","WorldInput_WBSelectPlot","WorldBuilder_SetPlacementStatus",
    "CAIWorldBuilderTools_Toggle","CAIWorldBuilderPlotEditor_Toggle","CAIWorldBuilderMapEditor_Toggle",
    "CAIWorldBuilderPlayerEditor_Toggle","InGame_OpenInGameOptionsMenu","CAIWorldBuilderQuickNav","CAIWorldBuilderSelectTool"}) do
    LuaEvents[event].Add(function(...) record(event,...) end)
end
local controller
if arg[1] then
    local f=assert(io.open(arg[1],"rb")); local source=f:read("a"):gsub("\r\n","\n"); f:close()
    local first=assert(source:find('local function WBPlacementSourcePlot()',1,true))
    local last=assert(source:find('local function FindInitialPlotId()',first,true))
    local brush=assert(source:match('\tif m_wbBrushLocked and WorldBuilder%.IsActive%(%) .-\n\tend'))
    local update=assert(source:match('\tif m_wbSightRefreshPending then.-\n\tend'))
    local body='local m_wbMarkedPlotId=nil\nlocal m_wbBrushLocked=false\nlocal m_caiWorldBuilderWidget=nil\n' .. source:sub(first,last-1)
    body=body .. '\nreturn { Build=function() CreateWorldBuilderWidget(); return m_caiWorldBuilderWidget end, GetMarkedPlot=GetWorldBuilderMarkedPlot, OnPlacementStatus=OnWorldBuilderPlacementStatus, OnCursorMoved=function(state) local plotId=state.toPlotId\n' .. brush .. '\nend, Update=function()\n' .. update .. '\nend }'
    controller=assert(load(body,"@WorldInput WB baseline","t",setmetatable({mgr=mgr},{__index=_G})))()
else
    dofile("src/UI/inGame/CAIWorldBuilderInput.lua")
    controller=CAIWorldBuilderInput.Create(mgr,{GetPlotId=GetCurrentCAICursorPlotId,
        GetCursor=function() return CAICursor end,GetScanner=function() return CAIWorldScanner end})
end
LuaEvents.WorldBuilder_SetPlacementStatus.Add(controller.OnPlacementStatus)
local root=assert(controller.Build()); mgr:Push(root, {priority=PopupPriority.Low})
local function press(key,options)
    options=options or {}; options.Message=options.Message or KeyEvents.KeyDown
    mgr:HandleInput(H.Key(key,options))
    if options.Message==KeyEvents.KeyDown then options.Message=KeyEvents.KeyUp; mgr:HandleInput(H.Key(key,options)) end
end
reset(); press(Keys.VK_RETURN)
check(trace()=="CAIWorldBuilderStatusBurstBegin,WorldInput_WBSelectPlot:12:5:true:false,WorldInput_WBSelectPlot:12:5:false:false,scan:validTargets","add retains native flag pair and scanner refresh")
s.edge=2; reset(); press(Keys.VK_DELETE)
check(trace()=="CAIWorldBuilderStatusBurstBegin,WorldInput_WBSelectPlot:12:2:true:true,WorldInput_WBSelectPlot:12:2:false:true,scan:validTargets","remove retains edge and native flag pair")
press(Keys.M); check(controller.GetMarkedPlot()==12,"mark cursor source")
s.cursor=23; reset(); press(Keys.VK_RETURN)
check(trace():find("WBSelectPlot:12:2",1,true)~=nil,"marked source survives cursor movement")
reset(); press(Keys.VK_F3); check(trace()=="CAIWorldBuilderPlotEditor_Toggle:12","plot editor uses marked source")
press(Keys.L,{Message=KeyEvents.KeyUp}); reset()
controller.OnCursorMoved({fromPlotId=12,toPlotId=23})
check(trace():find("WBSelectPlot:23:2",1,true)~=nil,"brush lock uses explicit destination over marked source")
reset(); controller.OnCursorMoved({fromPlotId=23,toPlotId=23}); check(trace()=="","stationary event does not paint")
CAI.Active=false; controller.OnCursorMoved({fromPlotId=12,toPlotId=23}); check(trace()=="","suspended accessibility does not paint")
CAI.Active=true; s.active=false; controller.OnCursorMoved({fromPlotId=12,toPlotId=23}); check(trace()=="","inactive World Builder does not paint")
s.active=true; press(Keys.L,{Message=KeyEvents.KeyUp}); reset(); controller.OnCursorMoved({fromPlotId=12,toPlotId=23}); check(trace()=="","unlocked brush does not paint")
press(Keys.M); check(controller.GetMarkedPlot()==nil,"unmark clears scanner source")
s.visibility=0; reset(); press(Keys.VK_RETURN)
check(trace()=="CAIWorldBuilderStatusBurstBegin,visibility:23:true,scan:validTargets","visibility uses result-aware bridge for player zero")
reset(); press(Keys.VK_DELETE); check(trace():find("visibility:23:false",1,true)~=nil,"visibility removal bridge")
s.visibility=nil; s.cursor=-1; reset(); press(Keys.VK_RETURN); check(trace()=="","invalid source produces no edits or status burst")
s.cursor=12
controller.OnPlacementStatus("unrelated"); controller.Update(); check(s.sight==0,"unknown status does not refresh sight")
controller.OnPlacementStatus("LOC_WORLDBUILDER_OWNERSHIP_SET"); check(s.sight==0,"ownership refresh deferred")
s.owner=7; controller.Update(); check(s.sight==1 and s.seenOwner==7,"next tick reads completed ownership")
controller.Update(); check(s.sight==1,"pending flag consumed once")
s.active=false; controller.OnPlacementStatus("LOC_WORLDBUILDER_OWNERSHIP_REMOVED"); controller.Update(); check(s.sight==1,"non-editor status ignored")
s.active=true; reset(); press(Keys.Z,{Control=true}); controller.Update()
check(s.sight==1 and trace():find("CANT_UNDO",1,true)~=nil,"unavailable undo leaves sight untouched")
s.undo=true; reset(); press(Keys.Z,{Control=true}); check(s.sight==1 and trace():find("undo",1,true)~=nil,"undo occurs before deferred sight")
controller.Update(); check(s.sight==2,"successful undo schedules sight")
reset(); press(Keys.Y,{Control=true}); controller.Update(); check(s.sight==2 and trace():find("CANT_REDO",1,true)~=nil,"unavailable redo leaves sight untouched")
s.redo=true; press(Keys.Y,{Control=true}); controller.Update(); check(s.sight==3,"successful redo schedules sight")
controller.OnPlacementStatus("LOC_WORLDBUILDER_OWNERSHIP_SET"); controller.OnPlacementStatus("LOC_WORLDBUILDER_OWNERSHIP_REMOVED"); controller.Update()
check(s.sight==4,"multiple ownership statuses coalesce into one tick")
local function edit(text)
    press(Keys.G,{Control=true})
    local box=assert(mgr:GetWidgetById("CAIWorldBuilderGoto_Edit")); box:SetText(text,true); box:Commit(); return box
end
reset(); edit("4 5"); check(s.cursor==54 and trace()=="move:54:jump","absolute coordinate commit moves once")
check(mgr:GetTop()==root,"coordinate commit returns to world widget")
reset(); edit("+1 -2"); check(s.cursor==35 and trace()=="move:35:jump","relative coordinates read live cursor")
edit(" 2"); check(s.cursor==25,"omitted x preserves current x")
edit("3 +1"); check(s.cursor==33,"mixed absolute and relative fields")
reset(); local box=edit("bad")
check(mgr:GetTop()==box and trace()=="","invalid coordinates keep editor open")
check(H.Speech[#H.Speech]=="LOC_CAI_WB_GOTO_INVALID","invalid format feedback")
box:SetText("99 99",true); box:Commit(); check(mgr:GetTop()==box and s.cursor==33,"out-of-bounds commit blocked")
check(H.Speech[#H.Speech]=="LOC_CAI_WB_GOTO_OUT_OF_BOUNDS","out-of-bounds feedback")
press(Keys.VK_ESCAPE,{Message=KeyEvents.KeyUp}); check(mgr:GetTop()==root and trace()=="","coordinate cancel does not move")
for pos=1,16 do
    local digit=pos>10 and tostring(pos-10) or tostring(pos%10)
    reset(); press(Keys[digit],{Shift=pos>10}); check(trace()=="CAIWorldBuilderSelectTool:" .. pos,"tool shortcut " .. pos)
end
for _,entry in ipairs({{Keys.VK_LEFT,"prev_param"},{Keys.VK_RIGHT,"next_param"},{Keys.VK_UP,"value_up"},{Keys.VK_DOWN,"value_down"},
    {Keys.VK_LEFT,"first_param",true},{Keys.VK_RIGHT,"last_param",true},{Keys.VK_UP,"first_value",true},{Keys.VK_DOWN,"last_value",true}}) do
    reset(); press(entry[1],{Shift=entry[3]}); check(trace()=="CAIWorldBuilderQuickNav:" .. entry[2],"quick navigation " .. entry[2])
end
for _,entry in ipairs({{Keys.VK_TAB,"CAIWorldBuilderTools_Toggle"},{Keys.VK_F1,"CAIWorldBuilderMapEditor_Toggle"},{Keys.VK_F2,"CAIWorldBuilderPlayerEditor_Toggle"}}) do
    reset(); press(entry[1]); check(trace()==entry[2],"editor shortcut " .. entry[2])
end
reset(); mgr:HandleInput(H.Key(Keys.VK_ESCAPE,{Message=KeyEvents.KeyDown})); check(trace()=="","pause waits for key-up")
mgr:HandleInput(H.Key(Keys.VK_ESCAPE)); check(trace()=="InGame_OpenInGameOptionsMenu","pause key-up forwards native event")
local overlay=mgr:CreateWidget("overlay","Panel",{}); overlay:AddChild(mgr:CreateWidget("overlay_button","Button",{})); mgr:Push(overlay)
reset(); press(Keys.VK_DELETE); press(Keys.VK_F1); check(trace()=="","editing shortcuts inactive under another panel")
mgr:RemoveFromStack("overlay")
-- Exercise the actual context hooks, not just the extracted controller.
local f=assert(io.open("src/UI/inGame/WorldInput_CAI.lua","rb")); local world=f:read("a"):gsub("\r\n","\n"); f:close()
local function contextFunction(name,env)
    local body=assert(world:match("local function " .. name .. "%b()%s*.-\nend"))
    return assert(load(body .. "\nreturn " .. name,"@WorldInput " .. name,"t",setmetatable(env,{__index=_G})))()
end
local update=contextFunction("OnUpdate",{
    worldBuilderInput={Update=function() record("sight update") end},
    MovementActions_CAI={UpdatePendingMovementResult=function() record("movement") end},
    UnitMoveLog_CAI={Update=function() record("log") end},RevealAnnouncements_CAI={UpdateVisibility=function() record("reveal") end},
    CheckInput=function() record("input") end,mgr={OnUpdate=function() record("manager") end},
})
reset(); update(); check(trace()=="sight update,movement,log,reveal,input,manager","context retains update order")
local moved=contextFunction("OnCAICursorMoved",{
    worldBuilderInput={OnCursorMoved=function() record("brush") end},
    UI={LookAtPlot=function() record("camera") end,PlaySound=function() record("sound") end},
    CURSOR_LONG_JUMP_HEXES=5,CAMERA_WHOOSH_SOUND="whoosh",
})
reset(); moved({toPlotId=-1,distance=1}); check(trace()=="","context rejects invalid plot before brush")
moved({toPlotId=23,distance=1}); check(trace()=="brush,camera","brush executes before camera")
reset(); moved({toPlotId=23,distance=6}); check(trace()=="brush,camera,sound","long jump sound order retained")
check(world:find('WorldBuilder_SetPlacementStatus.Add(worldBuilderInput.OnPlacementStatus)',1,true)~=nil
    and world:find('WorldBuilder_SetPlacementStatus.Remove(worldBuilderInput.OnPlacementStatus)',1,true)~=nil,"context registers and removes same callback")
-- Reload must replace the shared marked-plot reader with a fresh closure.
dofile("src/UI/inGame/CAIWorldBuilderInput.lua")
press(Keys.M); check(controller.GetMarkedPlot()==33,"old controller owns mark before reload")
local start=assert(world:find('local worldBuilderInput = CAIWorldBuilderInput.Create',1,true))
local finish=assert(world:find('local function FindInitialPlotId()',start,true))
local env=setmetatable({mgr=mgr},{__index=_G})
local fresh=assert(load(world:sub(start,finish-1) .. '\nreturn worldBuilderInput',"@WorldInput WB bridge","t",env))()
check(fresh.GetMarkedPlot()==nil and CAI.Info.GetWorldBuilderMarkedPlot()==nil,"reload publishes fresh empty mark")
local freshRoot=assert(fresh.Build()); mgr:RemoveFromStack(root:GetId()); mgr:Push(freshRoot)
s.cursor=44; press(Keys.M)
check(CAI.Info.GetWorldBuilderMarkedPlot()==44 and env.CAIWorldBuilderScannerSourcePlot()==44,"both bridges read new controller mark")
check(controller.GetMarkedPlot()==33,"new mark does not mutate old controller state")
print("World Builder input: " .. count .. " assertions passed (mocked placement, production widgets).")
