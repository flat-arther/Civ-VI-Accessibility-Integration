-- Production manager/widgets and actual migrated synchronization call sites.
-- Optional baseline directory compares the removed screen-local helpers.
local H=dofile("scripts/test-support/WidgetHarness.lua")
local mgr=H.CreateManager()
include("CAIColumns")
local count=0
local function check(value,label) count=count+1; assert(value,label) end
local function read(path)
    local f=assert(io.open(path,"rb")); local text=f:read("a"); f:close(); return (text:gsub("\r\n","\n"))
end
local root=mgr:CreateWidget("lifecycle_parent","Panel",{})
local dropdown=mgr:CreateWidget("lifecycle_sort","Dropdown",{Label="sort"})
local other=mgr:CreateWidget("lifecycle_other","Button",{Label="other"})
root:AddChild(dropdown); root:AddChild(other); mgr:Push(root,{focus=other})
local options={
    {label="natural",value={ascending=false}},
    {label="up",value={column="name",ascending=true}},
    {label="down",value={column="name",ascending=false}},
    {label="duplicate down",value={column="name",ascending=false}},
}
dropdown:SetOptions(options)
local changes=0
dropdown:On("value_changed",function() changes=changes+1 end)
local cases={
    {"CityStates_CAI","SyncTreeSortDropdown"},
    {"DiplomacyActionView_CAI","SyncSortDropdown"},
    {"DiplomacyRibbon_CAI","SyncSortDropdown"},
    {"GovernorPanel_CAI","SyncTreeSortDropdown"},
    {"GreatPeoplePopup_CAI","SyncGPSortDropdown","m_ui.gpSort"},
    {"GreatPeoplePopup_CAI","SyncHeroSortDropdown","m_ui.heroSort"},
    {"GlobalResourcePopup_CAI","SyncTreeSortDropdown"},
    {"CAIUnitBrowser","CAIUnitList.SyncSortDropdown"},
}
local scenarios={
    {key="name",ascending=true,expected=2},
    {key="name",ascending=false,expected=3},
    {key=nil,ascending=true,expected=1},
    {key=nil,ascending=false,expected=1},
    {key="gone",ascending=false,expected=4},
    {key="name",ascending=true,expected=4,absent=true},
}
local callCount=0
for _, case in ipairs(cases) do
    local filename,fn,selector=table.unpack(case)
    local source=read("src/UI/inGame/" .. filename .. ".lua")
    local calls={}
    for call in source:gmatch("CAIColumns%.SyncSortSelection%b()") do
        if not selector or call:find(selector,1,true) then calls[#calls+1]=call end
    end
    check(#calls>0,filename .. " migrated calls present")
    callCount=callCount+#calls
    for _, scenario in ipairs(scenarios) do
        local widget=dropdown
        if scenario.absent then widget=nil end
        local env=setmetatable({
            m_ui={treeSort=widget,gpSort=widget,heroSort=widget},m_sort=widget,m_treeSort=widget,
            m_treeSortOptions=options,m_sortOptions=options,m_gpSortOptions=options,m_heroSortOptions=options,
            m_treeSortColumn=scenario.key,m_sortColumn=scenario.key,m_gpSortColumn=scenario.key,m_heroSortColumn=scenario.key,
            m_treeSortAscending=scenario.ascending,m_sortAscending=scenario.ascending,
            m_gpSortAscending=scenario.ascending,m_heroSortAscending=scenario.ascending,
            CAIUnitList={SortDropdown=widget,SortOptions=options,SortColumn=scenario.key,SortAscending=scenario.ascending},
        },{__index=_G})
        for _, call in ipairs(calls) do
            dropdown:SetSelectedIndex(4,true)
            assert(load(call,"@" .. filename .. " sync","t",env))()
            check(dropdown:GetSelectedIndex()==scenario.expected,filename .. " selection " .. tostring(scenario.key))
        end
        if arg[1] then
            local old=read(arg[1] .. "/" .. filename .. ".lua")
            local definition
            if filename=="CAIUnitBrowser" then
                definition=assert(old:match("    function CAIUnitList%.SyncSortDropdown%b()%s*.-\n    end"))
            else definition=assert(old:match("local function " .. fn .. "%b()%s*.-\nend")) end
            dropdown:SetSelectedIndex(4,true)
            assert(load(definition .. "\n" .. fn .. "()","@" .. filename .. " baseline","t",env))()
            check(dropdown:GetSelectedIndex()==scenario.expected,filename .. " baseline selection")
        end
    end
end
check(changes==0,"all sync paths suppress user-change events")
check(mgr:GetFocusedWidget()==other,"sync preserves sibling focus")
local before=#H.Speech
mgr:SetFocus(dropdown); before=#H.Speech
CAIColumns.SyncSortSelection(dropdown,options,"name",true)
check(#H.Speech==before,"focused sync does not announce a second value")
CAIColumns.SyncSortSelection(dropdown,{},"name",false)
check(dropdown:GetSelectedIndex()==2,"empty options keep existing selection")
CAIColumns.SyncSortSelection(nil,nil,"name",false)
check(true,"pre-build dropdown can precede option construction")
check(not pcall(CAIColumns.SyncSortSelection,dropdown,nil,"name",false),"missing required option array propagates")
local failure={SetSelectedIndex=function() error("native widget failure") end}
check(not pcall(CAIColumns.SyncSortSelection,failure,options,"name",true),"widget errors propagate")
dropdown:SetSelectedIndex(3)
check(changes==1,"user changes still emit exactly once")

-- Modal teardown is already implemented by the manager. Exercise its existing
-- ownership before deciding whether screen cleanup warrants another helper.
mgr:SetFocus(other)
local function dialog(id)
    local d=mgr:CreateWidget(id,"Dialog",{Label=id})
    local ok=mgr:CreateWidget(id .. "_ok","Button",{Label="ok"})
    d:SetButtons({ok},1)
    return d,ok
end
local first,firstButton=dialog("first_modal")
local destroyed,buttonDestroyed=0,0
first:On("destroy",function() destroyed=destroyed+1 end)
firstButton:On("destroy",function() buttonDestroyed=buttonDestroyed+1 end)
mgr:Push(first)
check(mgr:GetFocusedWidget()==firstButton,"dialog default focus")
local second,secondButton=dialog("second_modal")
mgr:Push(second)
check(mgr:GetTop()==second and mgr:GetFocusedWidget()==secondButton,"nested dialog focus")
before=#H.Speech
mgr:RemoveFromStack(second:GetId(),false)
check(mgr:GetFocusedWidget()==firstButton,"nested close returns to first dialog")
check(#H.Speech==before,"silent close suppresses intermediate speech")
check(second.Manager==nil and secondButton.Manager==nil,"manager destroys removed dialog subtree")
mgr:RemoveFromStack(first:GetId())
check(destroyed==1 and buttonDestroyed==1,"root and child destroyed once")
check(mgr:GetFocusedWidget()==other,"dialog close restores prior parent focus")
mgr:RemoveFromStack(first:GetId())
check(destroyed==1,"repeated close does not destroy twice")
local replacement,replacementButton=dialog("first_modal")
mgr:Push(replacement)
check(mgr:GetTop()==replacement and mgr:GetFocusedWidget()==replacementButton,"same-ID reopen uses new object")
-- A synchronous parent refresh may remove the saved return target.
other:Destroy()
mgr:RemoveFromStack(replacement:GetId())
check(mgr:GetFocusedWidget()==dropdown,"destroyed return target falls back to live sibling")
local overlay,overlayButton=dialog("overlay")
mgr:Push(overlay)
mgr:RemoveFromStack(root:GetId(),false)
check(mgr:GetTop()==overlay and mgr:GetFocusedWidget()==overlayButton,"underlying screen close leaves modal focus intact")
mgr:RemoveFromStack(overlay:GetId())
check(mgr:GetTop()==nil and mgr:GetFocusedWidget()==nil,"last root closes cleanly")
print("View lifecycle: " .. count .. " assertions passed across " .. callCount .. " migrated sync calls.")
