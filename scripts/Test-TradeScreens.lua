local H = dofile("scripts/test-support/TradeHarness.lua")
local count, snapshots = 0, {}
local function check(value, message) count=count+1; assert(value, message) end
local function find(root, predicate)
    if predicate(root) then return root end
    for _, child in ipairs(root.Children or {}) do local hit=find(child,predicate); if hit then return hit end end
end
local function key(root, value) return assert(find(root,function(w) return w.FocusKey==value end), value) end
local function snapshot(root, depth)
    depth=depth or 0
    snapshots[#snapshots+1]=string.rep(" ",depth) .. table.concat({root.FocusKey or "", tostring(root:GetLabel()),tostring(root:GetTooltip()),tostring(root:IsHidden()),tostring(root:IsDisabled())}, "\t")
    for _, child in ipairs(root.Children or {}) do snapshot(child,depth+1) end
end
local function activate(mgr,w)
    mgr:SetFocus(w)
    mgr:HandleInput(H.Key(Keys.VK_RETURN,{Message=KeyEvents.KeyDown}))
    mgr:HandleInput(H.Key(Keys.VK_RETURN))
end
for _, bts in ipairs({false,true}) do
    for _, kind in ipairs({"Origin","Route","Overview"}) do
        local mgr,s=H.Create(kind,bts,arg[1])
        local prefix=kind=="Overview" and "CAITradeOv" or "CAITrade" .. kind
        Open()
        local root=assert(mgr:GetWidgetById(prefix .. "_Panel"))
        snapshots[#snapshots+1]=kind .. ":" .. tostring(bts)
        snapshot(root)
        check(not s.hidden,"native screen opens")
        if kind=="Origin" then
            local row=key(root,"city:0:12")
            check(row:GetTooltip()=="tooltip:SAME","duplicate names retain native controls")
            mgr:SetFocus(row); Refresh()
            check(mgr:GetFocusedWidget().FocusKey=="city:0:12","origin refresh keeps identity")
            row=key(root,"city:0:12"); s.children[2].disabled=true
            check(row:IsDisabled(),"native disabled state is live")
            s.children[2].hidden=true; check(row:IsHidden(),"native hidden state is live")
            s.children[2].disabled=false; s.children[2].hidden=false
            activate(mgr,row)
            check(s.teleported==12,"correct same-name city relocated")
            check(s.clicks==(bts and 0 or 1),"integration-specific activation")
            check(mgr:GetWidgetById(prefix .. "_Panel")==nil,"origin closes after relocation")
            s.noButton=true; Open(); root=assert(mgr:GetWidgetById(prefix .. "_Panel"))
            activate(mgr,key(root,"city:0:11")); check(s.teleported==11,"missing control fallback")
        elseif kind=="Route" then
            local row=key(root,"route:1:21")
            check(row:GetTooltip():find("DISTANCE:10",1,true)~=nil,"route tooltip distance")
            mgr:SetFocus(row); RefreshStack()
            check(mgr:GetFocusedWidget().FocusKey=="route:1:21","route refresh preserves focus")
            local filter=find(root,function(w) return w.Id=="CAITradeRoute_Filter" end)
            filter:SetSelectedIndex(2)
            check(s.filter==2,"filter forwards ordinal")
            RefreshFilters(); check(s.filterCalls==1,"filter sync does not retrigger callback")
            activate(mgr,key(root,"route:1:21"))
            check(s.requests==0,"selection waits for confirmation")
            local dialog=assert(mgr:GetWidgetById("CAITradeRoute_Confirm")); snapshot(dialog)
            mgr:HandleInput(H.Key(Keys.VK_ESCAPE))
            check(mgr:GetWidgetById("CAITradeRoute_Confirm")==nil,"escape closes confirmation")
            check(s.requests==0,"cancel does not begin route")
            if bts then
                key(root,"sortkey:1"):SetChecked(true)
                find(root,function(w) return w.Id=="CAITradeRoute_SortDir" end):Activate()
                check(#s.sort==1 and s.sort[1].id==1 and s.sort[1].direction==SORT_ASCENDING,"BTS sort settings forwarded")
                find(root,function(w) return w.Id=="CAITradeRoute_BestSortedBtn" end):Activate()
            else activate(mgr,key(root,"route:1:21")) end
            dialog=assert(mgr:GetWidgetById("CAITradeRoute_Confirm"))
            local confirm=assert(find(dialog,function(w) return w.Id:match("^CAITradeRoute_Confirm%d")~=nil end))
            confirm:Activate()
            check(s.requests==1,"native request called exactly once")
            check(mgr:GetWidgetById("CAITradeRoute_Confirm")==nil,"confirm cleanup")
            if bts then
                check(s.automationCount==1 and s.automation[1]==7,"automation captures trader before deselection")
                check(#s.automation[3]==1,"best-route automation keeps sort")
                check(Controls.RepeatRouteCheckbox.checked==false and Controls.FromTopSortEntryCheckbox.checked==false,"native automation cleared")
                s.selected=s.unit; Open(); root=assert(mgr:GetWidgetById(prefix .. "_Panel"))
                activate(mgr,key(root,"route:1:21"))
                dialog=assert(mgr:GetWidgetById("CAITradeRoute_Confirm"))
                local repeatBox=assert(find(dialog,function(w) return w.Id:match("^CAITradeRoute_RepeatCb")~=nil end))
                repeatBox:SetChecked(true)
                assert(find(dialog,function(w) return w.Id:match("^CAITradeRoute_Confirm%d")~=nil end)):Activate()
                check(s.requests==2 and s.automationCount==2,"repeat route invokes one request and one automation")
                check(s.automation[3]==nil,"ordinary repeat does not use best-route settings")
            end
            Open(); s.empty=true; RefreshStack(); snapshot(assert(mgr:GetWidgetById(prefix .. "_Panel")))
        else
            local row=key(root,"route:0:11:1:21:7")
            mgr:SetFocus(row); Refresh()
            check(mgr:GetFocusedWidget().FocusKey==row.FocusKey,"overview refresh preserves route focus")
            -- Route rows contain expandable yield children; emit the activation event
            -- directly to test its domain action independently of tree expansion.
            key(root,row.FocusKey):Emit("activate")
            check(s.selectedUnit==s.unit,"running route selects live trader")
            if bts then
                local cancel=assert(find(root,function(w) return w:GetLabel()=="LOC_CAI_TRADE_OVERVIEW_CANCEL_AUTOMATION" end))
                cancel:Emit("activate"); check(s.cancelAuto==7 and not s.automated,"cancel automation preserved")
                find(root,function(w) return w.Id=="CAITradeOv_Filter" end):SetSelectedIndex(2)
                check(s.filter==2,"overview filter")
                find(root,function(w) return w.Id=="CAITradeOv_GroupBy" end):SetSelectedIndex(2)
                check(s.group==40,"group ordinal maps to native ID")
            end
            local tabs=find(root,function(w) return w.Id=="CAITradeOv_Tabs" end)
            tabs:SetActivePage(2); check(s.tab==1,"routes-to tab native callback"); snapshot(root)
            tabs:SetActivePage(3); check(s.tab==2,"available tab native callback"); snapshot(root)
            local routeKey=bts and "route:0:11:1:21:-1" or "route:0:11:1:21:7"
            key(root,routeKey):Emit("activate")
            if bts then check(s.freeTrader and s.freeTrader[3]==21,"available route finds free trader")
            else check(s.overviewDestination and s.overviewDestination[2]==21,"vanilla available route dispatches destination") end
            key(root,"choose:0:7"):Emit("activate"); check(s.selectedUnit==s.unit,"choose-route row")
            local produce=find(root,function(w) return w:GetLabel()=="LOC_CAI_TRADE_OVERVIEW_PRODUCE_TRADER" end)
            check(produce and produce:IsDisabled(),"produce trader remains readable disabled")
        end
        Close(); check(mgr:GetWidgetById(prefix .. "_Panel")==nil,"close removes root")
        Open(); check(mgr:GetWidgetById(prefix .. "_Panel")~=nil,"reopen rebuilds root")
        s.shutdown(); check(s.shutdownCalled and mgr:GetWidgetById(prefix .. "_Panel")==nil,"shutdown removes root and calls vanilla")
    end
end
for _, variant in ipairs({{"RULESET_SCENARIO_INDONESIA_KHMER",false,"TradeOverview_Indonesia_KhmerScenario"},{nil,true,"TradeOverview_BetterBalancedGame_CAIBase"}}) do
    local mgr,s=H.Create("Overview",true,arg[1],variant[1],variant[2])
    check(s.includes[variant[3]],"scenario/BBG dispatcher preserved")
    if variant[1] then check(not s.includes.TradeOverview_BetterTradeScreen_CAI,"scenario avoids mismatched BTS API") end
    Open(); Close()
end
if arg[2] then local f=assert(io.open(arg[2],"wb")); f:write(table.concat(snapshots,"\n")); f:close() end
print("Trade screens: " .. count .. " assertions passed (production widgets, mocked game boundary).")
