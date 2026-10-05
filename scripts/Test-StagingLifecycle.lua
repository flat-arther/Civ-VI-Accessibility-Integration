-- Production frontend accessibility blocks, with engine boundaries mocked.
local h = dofile("scripts/test-support/WidgetHarness.lua")
local assertions = 0
local function check(value, message)
    assertions = assertions + 1
    assert(value, message)
end
local function read(path)
    local f = assert(io.open(path, "rb"))
    local source = f:read("a"); f:close()
    return source
end
local function block(path, env, exports)
    local source = read(path)
    source = assert(source:match("%-%-#Accessibility integration(.-)%-%-#End of accessibility integration"))
    env.include = function() end
    env.WrapFunc = function(orig, wrapper)
        return function(...) return wrapper(orig, ...) end
    end
    setmetatable(env, { __index = _G })
    return assert(load(source .. "\n" .. (exports or ""), "@" .. path, "t", env))()
end

local function cloud(options)
    options = options or {}
    local state = { enabled = options.enabled == true, mods = {{Handle=7}}, transitions=0, adds=0, pops=0, leaves=0, diagnostics={} }
    if options.present then state.mods[#state.mods+1] = {Handle=42} end
    local env = {
        ExposedMembers = { CAI_CloudSaveLoadPending = options.pending ~= false },
        print = function(line) state.diagnostics[#state.diagnostics+1]=line end,
        CAILogging = { ShouldLog=function() return options.diagnostics == true end },
        DB = { ConfigurationChanges=function() return 12 end, ConfigurationQuery=function() return {} end },
        Controls = { JoiningLabel = { SetText = function() end } },
        ContextPtr = { IsHidden = function() return state.hidden == true end },
        UIManager = { DequeuePopup = function() state.hidden=true end },
        Network = { LeaveGame = function() state.leaves=state.leaves+1 end },
        Modding = {
            GetModHandle = function() if not options.missing then return 42 end end,
            IsModEnabled = function() return state.enabled end,
            EnableMod = function() state.enabled = not options.enableFails end,
        },
        GameConfiguration = { GetEnabledMods = function() return state.mods end,
            GetRuleSet=function() return "RULESET_STANDARD" end, GetGameState=function() return 0 end },
        Locale = { Lookup = function(tag) return tag end, ToUpper = function(s) return s end },
        HandleExitRequest = function() state.hidden=true end,
        OnBeforeMultiplayerInviteProcessing = function() state.hidden=true end,
        DoTransitionToStagingRoom = function() state.transitions=state.transitions+1; state.hidden=true end,
    }
    env.ExposedMembers.CAI_UIManager = { RemoveFromStack = function() state.pops=state.pops+1 end }
    env.GameConfiguration.AddEnabledMods = function(handle, replace)
        check(handle == 42, "cloud recovery must add only CAI")
        state.adds=state.adds+1
        -- true discarded the entire saved content set in the captured engine log.
        -- false is the candidate additive behavior; engine verification is pending.
        if replace or options.loseSavedContent then state.mods={} end
        if not options.omitMembership then state.mods[#state.mods+1] = {Handle=handle} end
        if options.synchronous then env.OnFinishedGameplayContentConfigure({Success=true}) end
    end
    env.CheckTransitionToStagingRoom = function()
        if not state.hidden then env.DoTransitionToStagingRoom() end
    end
    env.OnFinishedGameplayContentConfigure = function(event)
        if not state.hidden and event.Success then env.CheckTransitionToStagingRoom() end
    end
    env.TestLeaveComplete = block("src/UI/frontEnd/Multiplayer/JoiningRoom.lua", env, [[
        m_CAI_Dialog = { GetId = function() return "joining" end }
        return CAI_OnLeaveGameComplete
    ]])
    return env, state
end

local env, state = cloud()
-- The real load path leaves the old session AFTER setting the recovery marker.
-- Exercise both production functions, not just the eventual join callback.
local loadSource = read("src/UI/shared/LoadGameMenu.lua"):gsub("\r", "")
env.UITutorialManager = { EnableOverlay=function() end, HideAll=function() end }
env.m_kPopupDialog = { Close=function() end }
env.SaveFileTypes = { GAME_STATE=1, GAME_CONFIGURATION=2 }
env.ServerType = { SERVER_TYPE_FIRAXIS_CLOUD=1, SERVER_TYPE_NONE=0 }
env.serverType=1; env.g_FileType=1
env.Controls.ActionButton = { SetDisabled=function() end }
env.Network.LeaveGame = function() env.TestLeaveComplete() end
env.Network.LoadGame = function() state.loads=(state.loads or 0)+1 end
assert(load(assert(loadSource:match("(function OnLoadYes%(%)\n.-\nend)")), "vanilla load", "t", env))()
local loadWrapper = assert(loadSource:match("(OnLoadYes = WrapFunc%(OnLoadYes, function%(orig%).-)\n%-%- TILED_MAP"))
assert(load(loadWrapper, "CAI load marker", "t", env))()
env.OnLoadYes()
check(state.loads==1 and env.ExposedMembers.CAI_CloudSaveLoadPending==true,
    "preparatory leave must preserve the cloud recovery marker")
env.DoTransitionToStagingRoom()
check(state.transitions==0 and state.pops==0, "must retain joining dialog/focus while configuring")
check(state.enabled and state.adds==1 and state.mods[1].Handle==7, "must preserve save mods")
env.TestLeaveComplete()
env.DoTransitionToStagingRoom()
check(state.adds==1 and state.transitions==0, "late preparatory leave and duplicate join must not bypass barrier")
env.OnFinishedGameplayContentConfigure({Success=true})
check(state.transitions==1 and state.pops==1, "successful configure must open staging once")
env.OnFinishedGameplayContentConfigure({Success=true})
check(state.transitions==1, "late completion must not reopen staging")

env, state = cloud({enabled=true, present=true})
env.DoTransitionToStagingRoom()
check(state.adds==0 and state.transitions==1, "already enabled cloud save must not wait for a nonexistent event")
env, state = cloud({present=true})
env.DoTransitionToStagingRoom()
check(state.adds==1 and state.transitions==0, "disabled mod with existing membership still needs configuration")
env, state = cloud({pending=false})
env.DoTransitionToStagingRoom()
check(state.adds==0 and state.transitions==1, "ordinary joins must preserve vanilla transition")
env, state = cloud({synchronous=true})
env.DoTransitionToStagingRoom()
check(state.transitions==1, "synchronous completion must not lose or duplicate transition")
env, state = cloud({diagnostics=true})
env.DoTransitionToStagingRoom(); env.OnFinishedGameplayContentConfigure({Success=true})
local cloudTrace=table.concat(state.diagnostics,"\n")
check(cloudTrace:find("phase=before_recovery",1,true) and cloudTrace:find("phase=recovery_completed",1,true),
    "diagnostics must capture both sides of cloud configuration")
check(state.transitions==1 and state.adds==1, "diagnostics must not change cloud transition behavior")
env, state = cloud({loseSavedContent=true})
env.DoTransitionToStagingRoom(); env.OnFinishedGameplayContentConfigure({Success=true})
check(state.transitions==0 and state.leaves==1, "losing saved content must block staging even when CAI is present")
check(table.concat(state.diagnostics,"\n"):find("saved content removed",1,true), "lost content must be identified in log")
env, state = cloud()
state.mods={{Id="02A8BDDE-67EA-4D38-9540-26E685E3156E"}, {Id="113D9459-0A3B-4FCB-A49C-483F40303575"}}
env.DoTransitionToStagingRoom()
state.mods[1].Id=state.mods[1].Id:lower()
env.OnFinishedGameplayContentConfigure({Success=true})
check(state.transitions==1, "real log records without handles must match case-insensitive IDs")
check(table.concat(state.diagnostics,"\n"):find("preserved 2 saved content entries",1,true), "successful preservation must report original content count")
env, state = cloud()
state.mods={{Id="02A8BDDE-67EA-4D38-9540-26E685E3156E"}}
env.DoTransitionToStagingRoom()
state.mods[1].Id="replacement-content"
env.OnFinishedGameplayContentConfigure({Success=true})
check(state.transitions==0 and state.leaves==1, "mutating engine-owned records must not mutate the saved identity snapshot")
for _, cancel in ipairs({"HandleExitRequest", "OnBeforeMultiplayerInviteProcessing"}) do
    env, state = cloud()
    env.DoTransitionToStagingRoom(); env[cancel]()
    env.OnFinishedGameplayContentConfigure({Success=true})
    check(state.transitions==0 and env.ExposedMembers.CAI_CloudSaveLoadPending==nil, "cancelled load must not resume")
end
for _, options in ipairs({{missing=true}, {enableFails=true}, {omitMembership=true}, {}}) do
    env, state = cloud(options)
    env.DoTransitionToStagingRoom()
    if state.adds>0 then env.OnFinishedGameplayContentConfigure({Success=options.omitMembership == true}) end
    check(state.transitions==0 and state.leaves==1, "failed recovery must leave through deferred failure flow")
end

-- Use actual list, submenu, dropdown, button and leader-picker implementations.
local mgr = h.CreateManager()
CAI.GetConfigValue = function(_, _, default) return default end
Locale.Lookup = function(tag, ...)
    local parts = {tag}
    for _, value in ipairs({...}) do parts[#parts+1]=tostring(value) end
    return table.concat(parts, " ")
end
dofile("src/UI/shared/CAIControl.lua")
dofile("src/UI/uiManager/helpers/CAIWidgetHelpers_LeaderPicker.lua")
CAIWidgetHelpers_LeaderPicker.Install(mgr)
local ids = {0,1,2,3}
local parameters, entries, configs = {}, {}, {}
local missingColor, failQuery = false, false
local clicks, logs = 0, 0
local function control(text)
    local c = {text=text or "", hidden=false, disabled=false}
    local function alive() assert(not c.dead, "accessed recycled vanilla control") end
    function c:IsHidden() alive(); return self.hidden end
    function c:IsDisabled() alive(); return self.disabled end
    function c:GetText() alive(); return self.text end
    function c:GetToolTipString() alive(); return self.text end
    function c:DoLeftClick() alive(); clicks=clicks+1 end
    return c
end
local function entry(id)
    local e = {}
    for _, name in ipairs({"Root", "PlayerName", "AlternateName", "PlayerStatus", "AlternateStatus", "StatusLabel",
        "SlotTypePulldown", "AlternateSlotTypePulldown", "TeamPullDown", "PlayerPullDown", "ColorPullDown",
        "HandicapPullDown", "KickButton", "HotseatEditButton", "AddPlayerButton"}) do e[name]=control() end
    e.PlayerName.text="player "..id
    e.AddPlayerButton.hidden=true
    return e
end
for id=0,5 do
    entries[id]=entry(id)
    configs[id]={GetPlayerName=function() return "config "..id end, GetReady=function() return false end,
        GetTeam=function() return -1 end, GetSlotStatus=function() return 1 end, IsLocked=function() return false end}
    parameters[id]={Parameters={PlayerLeader={Value={Domain="Players:StandardPlayers", Value="LEADER_TEST", Name="Leader"}},
        PlayerColorAlternate={Value=0}, PlayerDifficulty={Value={Name="Prince"}, Values={{Name="Prince"}}}}}
end
local update, vanillaBuild
local traceEnabled, cloudMode, traceQueries = false, false, 0
local traceLines = {}
local stagingEnv = {
    CAILogging={ShouldLog=function() return traceEnabled end},
    DB={ConfigurationChanges=function() return 12 end, ConfigurationQuery=function()
        traceQueries=traceQueries+1; return {}
    end},
    ExposedMembers=ExposedMembers, g_PlayerEntries=entries, g_slotTypeData={}, m_teamColors={},
    PlayerConfigurations=configs, ReadyStatusStr="Ready", NotReadyStatusStr="Not ready",
    TeamTypes={NO_TEAM=-1}, SlotStatus={SS_TAKEN=1, SS_CLOSED=2}, NetPlayerTypes={INVALID_PLAYERID=-1},
    GameStateTypes={GAMESTATE_LAUNCHED=1},
    GetPlayerParameters=function(id) return parameters[id] end, GetPlayerInfo=function() return {} end,
    GetPlayerIcons=function() return {PlayerColor="TEST"} end,
    GetTeamCounts=function() end,
    CachedQuery=function() if failQuery then error("injected query failure") end; return missingColor and {} or {{PlayerColor="TEST"}} end,
    UI={GetPlayerColorValues=function() return 1,2 end},
    Network={GetLocalPlayerID=function() return 0 end},
    GameConfiguration={GetMultiplayerPlayerIDs=function() return ids end, IsHotseat=function() return false end,
        IsPlayByCloud=function() return cloudMode end, IsMatchMaking=function() return false end,
        GetValue=function() return false end, GetTeamName=function() return "No team" end, GetGameState=function() return 0 end,
        GetRuleSet=function() return "RULESET_STANDARD" end},
    ContextPtr={SetUpdate=function(_, fn) update=fn end, ClearUpdate=function() update=nil end},
    print=function(line) logs=logs+1; traceLines[#traceLines+1]=line end,
    BuildPlayerList=function() return vanillaBuild() end,
    CreatePlayerParameters=function(id, headless)
        check(headless==true, "diagnostic wrapper must forward constructor arguments")
        parameters[id]={Parameters={}}; return parameters[id]
    end,
    g_PlayerReady={},
    UpdatePlayerEntry=function() error("original vanilla failure") end,
}
local api = block(arg[1] or "src/UI/frontEnd/Multiplayer/StagingRoom.lua", stagingEnv, [[
    return {
        setRoots=function(panel, list) CAI_Panel=panel; CAI_PlayerList=list end,
        rebuild=CAI_RebuildPlayerList, queue=CAI_RequestPlayerListRefresh,
        color=CAI_BuildColorOptions,
        trace=CAI_TracePlayerSetup,
        setChat=function(widget, fn) CAI_ChatTarget=widget; CAI_RebuildChatTarget=fn end,
    }
]])
local panel=mgr:CreateWidget("staging-test", "Panel", {})
local list=mgr:CreateWidget("slots", "List", {})
local after=mgr:CreateWidget("after", "Button", {})
panel:AddChild(list); panel:AddChild(after); api.setRoots(panel,list)
api.rebuild(); mgr:Push(panel,{focus=list.Children[4]})
local function tabOut()
    check(mgr:HandleInput(h.Key(Keys.VK_TAB,{Message=KeyEvents.KeyDown})), "Tab must be handled")
    check(mgr:GetFocusedWidget()==after, "Tab must leave the player list")
end
ids={0,1}; api.rebuild()
check(mgr:GetFocusedWidget().FocusKey=="slot:1", "removed slot must fall back to remaining slot")
tabOut()
mgr:SetFocus(list.Children[1]); ids={0,1,2,3,4,5}; api.rebuild()
check(mgr:GetFocusedWidget().FocusKey=="slot:0", "growing list must preserve slot")
local kick=mgr:FindByFocusKey(list,"CAIStagingRoom_Kick_0")
mgr:SetFocus(kick); api.rebuild()
check(mgr:GetFocusedWidget().FocusKey=="CAIStagingRoom_Kick_0", "submenu focus must survive rebuild")
kick=mgr:GetFocusedWidget()
local old=entries[0]
entries[0]=entry(0); entries[0].PlayerName.text="replacement"
for _, c in pairs(old) do c.dead=true end
check(list.Children[1]:GetLabel():find("replacement",1,true)~=nil, "slot label must read new instance before rebuild")
list.Children[1]:GetTooltip()
for _, child in ipairs(list.Children[1].Children) do child:IsHidden(); child:IsDisabled(); child:GetTooltip() end
kick:Activate()
check(clicks==1, "existing button must activate replacement vanilla control")
entries[0].KickButton.disabled=true; kick:Activate()
check(clicks==1, "activation must honor replacement disabled state")
entries[0]=nil
check(list.Children[1]:IsHidden() and kick:IsDisabled(), "removed slot must hide and disable stale widgets")
kick:Activate(); check(clicks==1, "removed control must not trigger fallback action")
entries[0]=entry(0)
tabOut()
api.rebuild()
check(mgr:GetFocusedWidget()==after, "passive refresh must not steal focus outside the list")
mgr:SetFocus(list.Children[1])
local picker=mgr:CreateWidget("CAIStagingRoom_LeaderPicker", "Panel", {})
mgr:Push(picker)
vanillaBuild=function()
    check(mgr:GetWidgetById("CAIStagingRoom_LeaderPicker")==nil, "close old leader options before releasing parameters")
    stagingEnv.g_isBuildingPlayerList=true
    for _, c in pairs(entries[0]) do c.dead=true end
    check(list.Children[1]:IsHidden(), "partially rebuilt vanilla slot must not be navigable")
    list.Children[1]:GetLabel()
    local button=mgr:FindByFocusKey(list,"CAIStagingRoom_Kick_0")
    check(button:IsDisabled(), "partial rebuild must disable slot activation")
    entries[0]=entry(0)
    stagingEnv.g_isBuildingPlayerList=false
    return 33
end
check(stagingEnv.BuildPlayerList()==33 and update~=nil, "vanilla rebuild must finish before scheduling CAI refresh")
update()
check(mgr:GetFocusedWidget().FocusKey=="slot:0", "vanilla instance replacement must retain slot focus")
mgr:SetFocus(list.Children[1]); missingColor=true
check(#api.color(0)==0 and logs==1, "missing optional colour row must be logged and omitted")
api.color(0); check(logs==1, "repeated missing colour must not flood log")
api.rebuild(); check(#list.Children==6, "missing colour must not remove slots")
missingColor=false; check(#api.color(0)==4, "colour must recover from live data")
local oldRow=list.Children[1]
mgr:SetFocus(oldRow); failQuery=true
local oldFocus=mgr:GetFocusedWidget()
local ok=pcall(api.rebuild)
check(not ok and list.Children[1]==oldRow and mgr:GetFocusedWidget()==oldFocus, "failed construction must retain old rows/focus")
failQuery=false; tabOut()
local chat=mgr:CreateWidget("chat-target", "Dropdown", {FocusKey="chat-target"})
panel:AddChild(chat)
chat:SetOptions({{label="All", value=1}, {label="Team", value=2}})
chat:Open(); mgr:SetFocus(chat._list.Children[2])
api.setChat(chat, function() chat:SetOptions({{label="All",value=1}, {label="Team",value=2}}) end)
api.queue(true); update()
check(mgr:GetFocusedWidget().FocusKey=="chat-target:option:2", "chat refresh must restore open option focus")
mgr:SetFocus(after)
api.queue(false); check(update~=nil, "refresh must be deferred")
local flush=update; flush(); check(update==nil, "successful refresh must clear update callback")
local before=list.Children[1]
api.setChat(nil, function() error("injected chat refresh failure") end)
api.queue(true); ok=pcall(update)
check(not ok and list.Children[1]~=before, "chat failure must not prevent player list refresh")

-- Diagnostics must describe expected missing state without suppressing vanilla errors.
cloudMode=true
api.trace("disabled",0)
check(traceQueries==0, "logging off must perform no diagnostic queries")
traceEnabled=true
configs[0].GetLeaderTypeName=function() return "LEADER_TEST" end
configs[0].GetValue=function() return "Players:StandardPlayers" end
parameters[0]=nil
local constructed=stagingEnv.CreatePlayerParameters(0,true)
check(constructed==parameters[0], "diagnostics must preserve constructor return")
local traceText=table.concat(traceLines,"\n")
check(traceText:find("phase=before_create",1,true) and traceText:find("phase=after_create",1,true)
    and traceText:find("PlayerLeader=nil",1,true), "trace must identify missing parameter before and after creation")
local failure, message=pcall(stagingEnv.UpdatePlayerEntry,0)
check(not failure and message:find("original vanilla failure",1,true), "diagnostics must preserve original vanilla exception")
check(table.concat(traceLines,"\n"):find("phase=before_update",1,true), "trace must precede original update failure")
local count=traceQueries
api.trace("before_update",0)
check(traceQueries==count, "unchanged update diagnostics must be deduplicated")
parameters[0].Parameters.PlayerLeader={Domain="Players:StandardPlayers"}
api.trace("before_update",0)
check(traceQueries>count and table.concat(traceLines,"\n"):find("PlayerLeader=table",1,true),
    "trace must distinguish missing selected value from missing parameter")

-- Compile all changed authored blocks, including the load marker handoff.
for _, path in ipairs({"src/UI/shared/LoadGameMenu.lua", "src/UI/frontEnd/Multiplayer/JoiningRoom.lua",
    "src/UI/frontEnd/Multiplayer/StagingRoom.lua"}) do
    local source=assert(read(path):match("%-%-#Accessibility integration(.-)%-%-#End of accessibility integration"))
    check(load(source,"@"..path)~=nil, "authored block syntax: "..path)
end
print("Staging lifecycle: "..assertions.." assertions passed")
