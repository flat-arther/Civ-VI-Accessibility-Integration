local H = dofile('scripts/test-support/WidgetHarness.lua')
local mgr = H.CreateManager()
local install = dofile('scripts/test-support/CAIAccessors.lua')
local count = 0
local function check(value, label) count = count + 1; assert(value, label) end
local getters = {
    UIManager='GetUIManager', AudioManager='GetAudioManager', Cursor='GetCursor', Info='GetInfo',
    WorldBuilderVisibilityManager='GetWorldBuilderVisibilityManager',
    WorldClimateHistoryManager='GetWorldClimateHistoryManager', UnitNumbers='GetUnitNumbers',
    RealEraTracker='GetRealEraTracker', QuickDeals='GetQuickDeals', Reports='GetReports',
    WorldRankings='GetWorldRankings', TutorialState='GetTutorialState', TutorialWorldAnchor='GetTutorialWorldAnchor',
}
local native = function() return 'native' end
local api = { Output=native, Active=false, CloudSaveLoadPending=true, WorldBuilderInjectedMapPath='map' }
check(install(api)==api, 'alias retains native root identity')
for field, getter in pairs(getters) do
    check(api[getter](api)==nil, getter..' returns nil before publication')
    local first, replacement = {}, {}
    api[field]=first; check(api[getter](api)==first, getter..' reads published instance')
    local fromOtherContext=api[getter]
    install(api)
    check(api[getter](api)==first, getter..' include does not reset instance')
    api[field]=replacement
    check(fromOtherContext(api)==replacement, getter..' existing context sees replacement')
    api[field]=nil; check(fromOtherContext(api)==nil, getter..' existing context sees teardown')
end
check(api.Output==native and api.Output()=='native', 'native methods preserved')
check(api.Active==false and api.CloudSaveLoadPending and api.WorldBuilderInjectedMapPath=='map', 'include preserves flags and frontend/world handoff')
check(api:GetMessageBuffer()==nil, 'message buffer optional before in-game initialization')
local player=1
local buffers={{},{}}
api.MessageBuffer={GetActive=function() return buffers[player] end}
check(api:GetMessageBuffer()==buffers[1], 'message getter returns active buffer')
player=2; check(api:GetMessageBuffer()==buffers[2], 'message getter follows local player')
api.MessageBuffer={GetActive=function() return 'reloaded' end}
check(api:GetMessageBuffer()=='reloaded', 'message provider replacement is live')
api.MessageBuffer=nil; check(api:GetMessageBuffer()==nil, 'message provider cleared')

-- Execute actual manager audio publication and shutdown, including Options' preserve path.
local audioStopped, tutorialStopped = 0, 0
CAIAudioManager={New=function()
    return {Initialize=function(_,owner) check(owner==mgr,'audio owner passed intact') end,
        Shutdown=function() audioStopped=audioStopped+1 end}
end}
mgr:InitializeAudioManager()
check(CAI:GetAudioManager()==mgr:GetAudioManager(), 'manager publishes audio on CAI')
mgr.TutorialManager={Shutdown=function() tutorialStopped=tutorialStopped+1 end}
mgr:ShutDown(false,true)
check(CAI:GetUIManager()==mgr and CAI:GetAudioManager()==mgr.AudioManager, 'preserved shutdown retains services')
check(audioStopped==0 and tutorialStopped==0, 'preserved shutdown skips service shutdown')
mgr:ShutDown(false)
check(CAI:GetUIManager()==nil and CAI:GetAudioManager()==nil, 'ordinary shutdown clears services')
check(audioStopped==1 and tutorialStopped==1, 'ordinary shutdown stops each service once')
local stale=mgr:CreateWidget('stale','Panel',{})
mgr.Stack={stale}
check(mgr:RemoveFromStack('stale')==nil and #mgr.Stack==1, 'late hide ignores stale manager')
local replacement=UIScreenManager:New(); CAI.UIManager=replacement
check(mgr:RemoveFromStack('stale')==nil and CAI:GetUIManager()==replacement, 'late hide preserves replacement manager')
mgr:ShutdownAudioManager()
check(CAI:GetAudioManager()==nil, 'empty audio shutdown is safe')
-- The real bootstrap publishes a fresh manager and audio instance under CAI.
LoadCAISuspendedFlag=function() return true end
CAIAudioManager.New=function()
    return {Initialize=function() end, Shutdown=function() end}
end
CAIUITutorialManager={New=function() return {Shutdown=function() end} end}
CAIUITutorialCatalog={New=function() return {} end}
local charHandler
CAI.RegisterGlobalCharInputHandler=function(fn) charHandler=fn end
local published
LuaEvents.CAIUIManagerInitialized.Add(function(value) published=value end)
UIScreenManager:Init()
local fresh=CAI:GetUIManager()
check(fresh~=replacement and published==fresh, 'bootstrap publishes fresh manager before event')
check(CAI.Active==false, 'bootstrap restores suspended flag inside CAI')
check(CAI:GetAudioManager()==fresh:GetAudioManager(), 'bootstrap publishes fresh audio')
check(type(charHandler)=='function', 'bootstrap keeps native character registration')
fresh:ShutDown(false)
check(CAI:GetUIManager()==nil and CAI:GetAudioManager()==nil, 'bootstrapped services clear on shutdown')
for key in pairs(ExposedMembers) do check(key=='CAI', 'CAI systems are not published at the shared root: '..key) end

-- All getters are installed on the shared root before dependent modules load.
local f=assert(io.open('src/UI/shared/caiUtils.lua','rb')); local source=f:read('a'); f:close()
local includeCount=0
local context={ExposedMembers={CAI=api}, include=function()
    includeCount=includeCount+1
    check(type(api.GetUIManager)=='function' and type(api.GetMessageBuffer)=='function','getters precede includes')
end}
local endHeader=assert(source:find('-- ===========================================================================',1,true))
assert(load(source:sub(1,endHeader-1),'@caiUtils initialization','t',context))()
check(context.CAI==api and includeCount==5, 'context alias shares exactly the native table')
print('CAI namespace: '..count..' assertions passed')
