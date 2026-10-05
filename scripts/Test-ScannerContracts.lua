local H=dofile('scripts/test-support/WidgetHarness.lua')
local mgr=H.CreateManager()
local count=0
local function check(v,label) count=count+1; assert(v,label) end
local function read(path) local f=assert(io.open(path,'rb')); local s=f:read('a'):gsub('\r\n','\n'); f:close(); return s end
local function button(parent,id,key)
 local w=mgr:CreateWidget(id,'Button',{Label=id,FocusKey=key}); parent:AddChild(w); return w
end
local root=mgr:CreateWidget('return-root','Panel',{})
local first=button(root,'first','first')
local list=mgr:CreateWidget('return-list','List',{FocusKey='list'}); root:AddChild(list)
local original=button(list,'original','target')
mgr:Push(root,{focus=original})
local token=mgr:CaptureReturnFocus(root)
local temp=button(root,'temporary','temp'); mgr:SetFocus(temp)
check(mgr:RestoreReturnFocus(root,token) and mgr:GetFocusedWidget()==original,'returns to active nested target')
original:Destroy(); local rebuilt=button(list,'rebuilt','target')
mgr:SetFocus(temp)
local before=#H.Speech
check(mgr:RestoreReturnFocus(root,token) and mgr:GetFocusedWidget()==rebuilt,'stable key survives rebuilt target')
check(#H.Speech>before,'explicit return announces')
rebuilt:SetHiddenPredicate(function() return true end)
local fallback=button(list,'fallback','fallback')
mgr:SetFocus(temp); mgr:RestoreReturnFocus(root,token)
check(mgr:GetFocusedWidget()==fallback,'hidden target falls back within surviving parent')
rebuilt:Destroy(); mgr:SetFocus(temp); mgr:RestoreReturnFocus(root,token)
check(mgr:GetFocusedWidget()==fallback,'destroyed target falls back')
list:Destroy(); mgr:SetFocus(temp); mgr:RestoreReturnFocus(root,token)
check(mgr:GetFocusedWidget()==first,'destroyed ancestor falls back to root default')
local noKey=button(root,'identity',nil); mgr:SetFocus(noKey); local identity=mgr:CaptureReturnFocus(root)
mgr:SetFocus(temp); mgr:RestoreReturnFocus(root,identity)
check(mgr:GetFocusedWidget()==noKey,'unkeyed target uses live identity')
local other=mgr:CreateWidget('other','Panel',{}); local otherButton=button(other,'other-button','other'); mgr:Push(other)
local inactive=mgr:CaptureReturnFocus(root)
check(mgr:GetFocusedWidget()==otherButton,'inactive capture does not steal focus')
check(not mgr:RestoreReturnFocus(root,inactive) and mgr:GetFocusedWidget()==otherButton,'inactive restore does not steal focus')
check(not mgr:RestoreReturnFocus(other,inactive),'token bound to its root')
mgr:Pop(); mgr:SetFocus(temp); mgr:RestoreReturnFocus(root,inactive)
check(mgr:GetFocusedWidget()==noKey,'inactive capture preserves default descendant')
check(not mgr:RestoreReturnFocus(root,nil),'nil return capture is a no-op')
local empty=mgr:CreateWidget('empty','Panel',{}); mgr:Push(empty)
local rootToken=mgr:CaptureReturnFocus(empty)
check(rootToken~=nil and mgr:CaptureFocusKey(empty)==nil,'root focus differs from rebuild capture')
check(mgr:RestoreReturnFocus(empty,rootToken) and mgr:GetFocusedWidget()==empty,'empty root return')
mgr:Pop(); empty:Destroy(); check(not mgr:RestoreReturnFocus(empty,rootToken),'destroyed root no-op')
-- Production settings -> category-manager replacement -> original owner.
include('CAICollection')
dofile('src/UI/uiManager/helpers/CAIWidgetHelpers_Settings.lua')
CAISettings.GetDefinitions=function() return {} end
CAIWorldScannerCategoryConfig={IsConfigured=function() return true end,GetEntries=function() return {} end}
dofile('src/UI/inGame/WorldScanner/WorldScannerCategoryManager.lua')
local settings=CAIWidgetHelpers_Settings; local categories=CAIWorldScannerCategoryManager
mgr:SetFocus(noKey)
check(settings.OpenSettings(mgr),'settings opens')
local saved=settings.GetSettingsReturnFocus(mgr)
check(categories.Open(mgr,settings.GetSettingsOwnerRoot(mgr),saved),'category manager opens')
settings.CloseSettings(mgr,false)
check(mgr:GetFocusedWidget().FocusKey=='category-action:add','replacement receives prepared focus')
categories.Close(); check(mgr:GetFocusedWidget()==noKey,'replacement closes to original owner focus')
check(settings.OpenSettings(mgr),'settings reopens')
noKey:Destroy(); settings.CloseSettings(mgr)
check(mgr:GetFocusedWidget()==first,'settings removed return target safely falls back')
-- Direct inactive-parent category management capture.
other=mgr:CreateWidget('other-again','Panel',{}); otherButton=button(other,'other-again-button','other')
 mgr:SetFocus(first); mgr:Push(other)
check(categories.Open(mgr,root),'inactive category parent opens without changing top')
check(mgr:GetFocusedWidget()==otherButton,'opening does not steal other root focus')
mgr:Pop(); categories.Close(); check(mgr:GetFocusedWidget()==first,'inactive parent cache restored')
-- Only the optional DMT bridge is protected; ordinary labels remain available.
local helper=read('src/UI/inGame/inGameHelpers_CAI.lua')
local a=assert(helper:find('function BuildMapTacLabelWithDMT(',1,true)); local b=assert(helper:find('\n---@param plot table|nil',a,true))
assert(load(helper:sub(a,b-1),'DMT label helper'))()
BuildMapTacLabel=function() return 'pin' end
local pin={GetHexX=function() return 3 end,GetHexY=function() return 4 end}
ExposedMembers.CAIInfo=nil; check(BuildMapTacLabelWithDMT(pin,2,2)=='pin','absent DMT')
local warnings={}; LogWarn=function(s) warnings[#warnings+1]=s end
ExposedMembers.CAIInfo={GetMapPinSubject=function(p,x,y) check(p==2 and x==3 and y==4,'DMT arguments'); error('external failure') end}
check(BuildMapTacLabelWithDMT(pin,2,2)=='pin' and #warnings==1,'external failure retains pin and logs')
ExposedMembers.CAIInfo.GetMapPinSubject=function() return {YieldToolTip='yield',CanPlace=false,CanPlaceToolTip='blocked'} end
check(BuildMapTacLabelWithDMT(pin,2,2)=='pin[NEWLINE]yield[NEWLINE]blocked','DMT successful payload')
ExposedMembers.CAIInfo.GetMapPinSubject=function() return nil end
check(BuildMapTacLabelWithDMT(pin,2,2)=='pin','DMT cache miss')
BuildMapTacLabel=function() error('internal label failure') end
local ok,err=pcall(BuildMapTacLabelWithDMT,pin,2,2); check(not ok and err:find('internal label failure',1,true),'internal label errors propagate')
print('Scanner focus contracts: '..count..' assertions passed')
