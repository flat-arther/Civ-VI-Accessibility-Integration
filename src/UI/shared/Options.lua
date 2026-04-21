include("caiUtils")
include("Options_Base")
include("UIScreenManager")
local mgr = ExposedMembers.CAI_UIManager
local OptionsPanel    = nil   ---@type UIWidget
local OptionsList     = nil   ---@type UIWidget
local TabBar          = nil   ---@type UIWidget
local m_activeTabIdx      = 1
local m_ignoreNextBinding = false
local m_bindingPopup      = nil ---@type UIWidget|nil
local m_ctrlData      = {}
local m_resModes      = {}

---Capture dropdown options and handler when PopulateComboBox is called
PopulateComboBox = WrapFunc(PopulateComboBox, function(orig, ctrl, vals, sel, handler, locked)
    orig(ctrl, vals, sel, handler, locked)
    m_ctrlData[ctrl] = {values = vals, handler = handler}
end)

---Capture toggle handler when PopulateCheckBox is called
PopulateCheckBox = WrapFunc(PopulateCheckBox, function(orig, ctrl, val, handler, locked)
    orig(ctrl, val, handler, locked)
    m_ctrlData[ctrl] = {handler = handler}
end)

---Capture commit handler when PopulateEditBox is called
PopulateEditBox = WrapFunc(PopulateEditBox, function(orig, ctrl, val, handler, locked)
    orig(ctrl, val, handler, locked)
    m_ctrlData[ctrl] = {handler = handler}
end)

---Capture resolution modes on each AdjustResolutionPulldown call
AdjustResolutionPulldown = WrapFunc(AdjustResolutionPulldown, function(orig, window_mode, is_in_game)
    orig(window_mode, is_in_game)
    m_resModes = {}
    for _, v in ipairs(Options.GetAvailableDisplayModes()) do
        local lbl = v.Width .. "x" .. v.Height
        if window_mode == FULLSCREEN_OPTION then lbl = lbl .. " (" .. v.RefreshRate .. " Hz)" end
        table.insert(m_resModes, {label=lbl, w=v.Width, h=v.Height, hz=v.RefreshRate})
    end
end)

-- ============================================================
-- Widget factory helpers
-- ============================================================

---Standard dropdown backed by a PopulateComboBox-registered control
local function W_Dropdown(labelText, ctrl)
    local data = m_ctrlData[ctrl]
    if not data then return nil end
    return mgr:CreateUIWidget("DropdownMenu", {
        GetLabel     = function() return labelText end,
        GetValue     = function() return ctrl:GetButton():GetText() end,
        GetTooltip   = function() return ctrl:GetToolTipString() end,
        IsDisabled   = function() return ctrl:IsDisabled() end,
        IsHidden     = function() return ctrl:IsHidden() end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function(w)
            local optList = mgr:CreateUIWidget("List")
            optList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
                mgr:Pop()
                return true
            end})
            local currentText = ctrl:GetButton():GetText()
            local selectedChild = nil
            for _, opt in ipairs(data.values) do
                local optLabel = type(opt[1]) == "string" and Locale.Lookup(opt[1]) or tostring(opt[1])
                local child = mgr:CreateUIWidget("MenuItem", {
                    GetLabel     = function() return optLabel end,
                    OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                    OnClick      = function()
                        if data.handler then data.handler(opt[2]) end
                        mgr:Pop()
                    end,
                })
                optList:AddChild(child)
                if not selectedChild and optLabel == currentText then
                    selectedChild = child
                end
            end
            if selectedChild then
                optList.FocusedChild = selectedChild
            end
            mgr:Push(optList)
        end,
    })
end

---Checkbox widget backed by a PopulateCheckBox-registered control
local function W_Checkbox(ctrl)
    local data = m_ctrlData[ctrl]
    if not data then return nil end
    return mgr:CreateUIWidget("Checkbox", {
        GetLabel     = function() return ctrl:GetText() end,
        GetTooltip   = function() return ctrl:GetToolTipString() end,
        GetValue     = function()
            return ctrl:IsSelected() and Locale.Lookup("LOC_OPTIONS_ENABLED")
                                      or Locale.Lookup("LOC_OPTIONS_DISABLED")
        end,
        IsDisabled   = function() return ctrl:IsDisabled() end,
        IsHidden     = function() return ctrl:IsHidden() end,
        Toggle       = function(w)
            local selected = not ctrl:IsSelected()
            ctrl:SetSelected(selected)
            if data.handler then data.handler(selected) end
        end,
    })
end

---Edit box widget backed by a PopulateEditBox-registered control
local function W_EditBox(labelText, ctrl)
    local data = m_ctrlData[ctrl]
    if not data then return nil end
    return mgr:CreateUIWidget("Edit", {
        GetLabel   = function() return labelText end,
        GetValue   = function() return ctrl:GetText() end,
        IsDisabled = function() return ctrl:IsDisabled() end,
        OnSetText  = function(w, text)
            ctrl:SetText(text)
        end,
        OnCommit   = function(w, text)
            ctrl:SetText(text)
            if data.handler then data.handler(text) end
            Controls.ConfirmButton:SetDisabled(false)
        end,
    })
end

---Stepped slider (fires the registered callback via SetStepAndCall)
local function W_SteppedSlider(labelText, sliderCtrl, valueLabelCtrl)
    return mgr:CreateUIWidget("Slider", {
        GetLabel   = function() return labelText end,
        GetValue   = function()
            return valueLabelCtrl and valueLabelCtrl:GetText()
                or tostring(math.floor(sliderCtrl:GetValue() * 100)) .. "%"
        end,
        GetTooltip = function() return sliderCtrl:GetToolTipString() end,
        IsDisabled = function() return sliderCtrl:IsDisabled() end,
        Increment  = function() sliderCtrl:SetStepAndCall(math.min(sliderCtrl:GetStep() + 1, sliderCtrl:GetNumSteps())) end,
        Decrement  = function() sliderCtrl:SetStepAndCall(math.max(sliderCtrl:GetStep() - 1, 0)) end,
    })
end

---Continuous audio-volume slider (directly writes the option on change)
local function W_VolSlider(labelText, sliderCtrl, audioGroup, audioKey, soundKey)
    local function ApplyVolume(delta)
        local v = math.max(0.0, math.min(sliderCtrl:GetValue() + delta, 1.0))
        sliderCtrl:SetValue(v)
        Options.SetAudioOption(audioGroup, audioKey, v * 100.0, 0)
        if soundKey then UI.PlaySound(soundKey) end
        Controls.ConfirmButton:SetDisabled(false)
    end
    return mgr:CreateUIWidget("Slider", {
        GetLabel   = function() return labelText end,
        GetValue   = function() return tostring(math.floor(sliderCtrl:GetValue() * 100)) .. "%" end,
        Increment  = function() ApplyVolume(0.01) end,
        Decrement  = function() ApplyVolume(-0.01) end,
    })
end

---Appends a widget to OptionsList (silently ignores nil)
local function Add(widget)
    if widget then OptionsList:AddChild(widget) end
end

-- ============================================================
-- Spec dispatch helpers
-- ============================================================

---Dispatches one spec entry to the appropriate widget factory.
---If s.adv is true, the returned widget's IsHidden is overridden to track
---Controls.AdvancedOptionsContainer so navigation skips it when collapsed.
local function BuildFromSpec(s)
    if s.when and not s.when() then return nil end
    local lbl = s.label and Locale.Lookup(s.label) or (s.labelFn and s.labelFn()) or nil
    local w
    if     s.type == "D" then w = W_Dropdown(lbl, s.ctrl)
    elseif s.type == "C" then w = W_Checkbox(s.ctrl)
    elseif s.type == "E" then w = W_EditBox(lbl, s.ctrl)
    elseif s.type == "S" then w = W_SteppedSlider(lbl, s.ctrl, s.val)
    elseif s.type == "V" then w = W_VolSlider(lbl, s.ctrl, s.grp, s.key, s.snd)
    elseif s.type == "X" then w = s.build()
    end
    if w and s.adv then
        w.IsHidden = function() return Controls.AdvancedOptionsContainer:IsHidden() end
    end
    return w
end

---Iterates a spec table and adds each resulting widget to OptionsList
local function AddSpecs(specs)
    for _, s in ipairs(specs) do Add(BuildFromSpec(s)) end
end

-- ============================================================
-- Tab spec tables
-- ============================================================

local gameTabSpecs = {
    {type="D", label="LOC_OPTIONS_QUICK_COMBAT",            ctrl=Controls.QuickCombatPullDown},
    {type="D", label="LOC_OPTIONS_QUICK_MOVEMENT",          ctrl=Controls.QuickMovementPullDown},
    {type="D", label="LOC_OPTIONS_AUTO_END_TURN",           ctrl=Controls.AutoEndTurnPullDown},
    {type="D", label="LOC_OPTIONS_CITY_RANGE_ATTACK",       ctrl=Controls.CityRangeAttackTurnBlockingPullDown},
    {type="D", label="LOC_OPTIONS_TUNER",                   ctrl=Controls.TunerPullDown},
    {type="D", labelFn=function() return Controls.AutoDownloadLabel:GetText() end,
               ctrl=Controls.AutoDownloadPullDown,
               when=function() return not Controls.AutoDownloadPullDown:IsHidden() end},
    {type="D", label="LOC_OPTIONS_TUTORIAL",                ctrl=Controls.TutorialPullDown},
    {type="D", label="LOC_OPTIONS_TURNS_BETWEEN_AUTOSAVES", ctrl=Controls.SaveFrequencyPullDown},
    {type="D", label="LOC_OPTIONS_AUTOSAVES_TO_KEEP",       ctrl=Controls.SaveKeepPullDown},
    {type="X", build=function()  -- Time-of-day slider (continuous; replicates callback inline)
        return mgr:CreateUIWidget("Slider", {
            GetLabel   = function() return Locale.Lookup("LOC_OPTIONS_TIME_OF_DAY") end,
            GetValue   = function() return Controls.TODText:GetText() end,
            GetTooltip = function() return Controls.TODSlider:GetToolTipString() end,
            Increment  = function()
                local v = math.min(Controls.TODSlider:GetValue() + (1 / TIME_SCALE), 1.0)
                Controls.TODSlider:SetValue(v)
                local fTime = v * TIME_SCALE
                Options.SetGraphicsOption("General", "DefaultTimeOfDay", fTime, 0)
                UI.SetAmbientTimeOfDay(fTime)
                UpdateTimeLabel(fTime)
                Controls.ConfirmButton:SetDisabled(false)
            end,
            Decrement  = function()
                local v = math.max(Controls.TODSlider:GetValue() - (1 / TIME_SCALE), 0.0)
                Controls.TODSlider:SetValue(v)
                local fTime = v * TIME_SCALE
                Options.SetGraphicsOption("General", "DefaultTimeOfDay", fTime, 0)
                UI.SetAmbientTimeOfDay(fTime)
                UpdateTimeLabel(fTime)
                Controls.ConfirmButton:SetDisabled(false)
            end,
        })
    end},
    {type="C", ctrl=Controls.TimeOfDayCheckbox},
    {type="E", label="LOC_OPTIONS_LAN_PLAYER_NAME", ctrl=Controls.LANPlayerNameEdit},
    {type="E", label="LOC_OPTIONS_WEBHOOK_URL",     ctrl=Controls.PBCTurnWebhookEdit},
    {type="D", label="LOC_OPTIONS_WEBHOOK_FREQ",    ctrl=Controls.TurnWebhookFreqPullDown},
}

local graphicsBaseSpecs = {
    {type="X", build=function()  -- Adapter pulldown (lazy; not via PopulateComboBox)
        return mgr:CreateUIWidget("DropdownMenu", {
            GetLabel     = function() return Locale.Lookup("LOC_OPTIONS_VIDEO_ADAPTER_TEXT") end,
            GetValue     = function() return Controls.AdapterPullDown:GetButton():GetText() end,
            GetTooltip   = function() return Controls.AdapterPullDown:GetToolTipString() end,
            IsDisabled   = function() return Controls.AdapterPullDown:IsDisabled() end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick      = function()
                local adapters = Options.GetAvailableDisplayAdapters()
                local ddList = mgr:CreateUIWidget("List")
                ddList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function() mgr:Pop(); return true end})
                local currentText = Controls.AdapterPullDown:GetButton():GetText()
                local selectedChild = nil
                for i, v in pairs(adapters) do
                    local child = mgr:CreateUIWidget("MenuItem", {
                        GetLabel     = function() return v end,
                        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                        OnClick      = function()
                            Controls.AdapterPullDown:GetButton():SetText(v)
                            Options.SetAppOption("Video", "DeviceID", i)
                            Controls.ConfirmButton:SetDisabled(false)
                            _PromptRestartApp = true
                            mgr:Pop()
                        end,
                    })
                    ddList:AddChild(child)
                    if not selectedChild and v == currentText then
                        selectedChild = child
                    end
                end
                if selectedChild then
                    ddList.FocusedChild = selectedChild
                end
                mgr:Push(ddList)
            end,
        })
    end},
    {type="C", ctrl=Controls.MultiGPUCheckbox},
    {type="X", build=function()  -- Resolution pulldown (lazy; uses m_resModes)
        return mgr:CreateUIWidget("DropdownMenu", {
            GetLabel     = function() return Locale.Lookup("LOC_OPTIONS_VIDEO_RESOLUTION_TEXT") end,
            GetValue     = function() return Controls.ResolutionPullDown:GetButton():GetText() end,
            GetTooltip   = function() return Controls.ResolutionPullDown:GetToolTipString() end,
            IsDisabled   = function() return Controls.ResolutionPullDown:IsDisabled() end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick      = function()
                local ddList = mgr:CreateUIWidget("List")
                ddList:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function() mgr:Pop(); return true end})
                local curW = tonumber(Options.GetAppOption("Video", "RenderWidth"))
                local curH = tonumber(Options.GetAppOption("Video", "RenderHeight"))
                local selectedChild = nil
                for _, mode in ipairs(m_resModes) do
                    local child = mgr:CreateUIWidget("MenuItem", {
                        GetLabel     = function() return mode.label end,
                        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
                        OnClick      = function()
                            Options.SetAppOption("Video", "RenderWidth",  mode.w)
                            Options.SetAppOption("Video", "RenderHeight", mode.h)
                            Options.SetGraphicsOption("Video", "RefreshRateInHz", mode.hz)
                            Controls.ResolutionPullDown:GetButton():SetText(mode.label)
                            Controls.ConfirmButton:SetDisabled(false)
                            _PromptResolutionAck = (Options.GetAppOption("Video", "FullScreen") == FULLSCREEN_OPTION)
                            mgr:Pop()
                        end,
                    })
                    ddList:AddChild(child)
                    if not selectedChild and tonumber(mode.w) == curW and tonumber(mode.h) == curH then
                        selectedChild = child
                    end
                end
                if selectedChild then
                    ddList.FocusedChild = selectedChild
                end
                mgr:Push(ddList)
            end,
        })
    end},
    {type="D", label="LOC_OPTIONS_VIDEO_UI_UPSCALE_TEXT",  ctrl=Controls.UIScalePulldown},
    {type="D", label="LOC_OPTIONS_VIDEO_WINDOW_MODE_TEXT", ctrl=Controls.FullScreenPullDown},
    {type="D", label="LOC_OPTIONS_VIDEO_MSAA_TEXT",        ctrl=Controls.MSAAPullDown},
    {type="S", label="LOC_OPTIONS_VIDEO_PERFORMANCE_TEXT", ctrl=Controls.PerformanceSlider, val=Controls.PerformanceValue},
    {type="S", label="LOC_OPTIONS_VIDEO_MEMORY_TEXT",      ctrl=Controls.MemorySlider,      val=Controls.MemoryValue},
    {type="X", build=function()  -- Advanced toggle button
        return mgr:CreateUIWidget("Button", {
            GetLabel     = function() return Controls.AdvancedGraphicsOptions:GetText() end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick      = function() OnToggleAdvancedOptions() end,
        })
    end},
}

-- adv=true: IsHidden delegates to Controls.AdvancedOptionsContainer so navigation
-- skips these entries when the advanced section is collapsed
local graphicsAdvSpecs = {
    {adv=true, type="C", ctrl=Controls.VSyncEnabledCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_PERFORMANCE_TICK_INTERVAL_TEXT", ctrl=Controls.TickIntervalPullDown},
    {adv=true, type="C", ctrl=Controls.AssetTextureResolutionCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_VIDEO_VFX_DETAIL_LEVEL_TEXT",    ctrl=Controls.VFXDetailLevelPullDown},
    {adv=true, type="C", ctrl=Controls.LightingBloomEnabledCheckbox},
    {adv=true, type="C", ctrl=Controls.LightingDynamicLightingEnabledCheckbox},
    {adv=true, type="C", ctrl=Controls.ShadowsEnabledCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_SHADOWS_RESOLUTION_TEXT",        ctrl=Controls.ShadowsResolutionPullDown},
    {adv=true, type="C", ctrl=Controls.CloudShadowsEnabledCheckbox},
    {adv=true, type="C", ctrl=Controls.SSOverlayEnabledCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_TERRAIN_QUALITY_TOOLTIP",        ctrl=Controls.TerrainQualityPullDown},
    {adv=true, type="C", ctrl=Controls.TerrainSynthesisCheckbox},
    {adv=true, type="C", ctrl=Controls.TerrainTextureResolutionCheckbox},
    {adv=true, type="C", ctrl=Controls.TerrainShaderCheckbox},
    {adv=true, type="C", ctrl=Controls.TerrainAOEnabledCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_LIGHTING_AO_RENDER_RESOLUTION_TOOLTIP", ctrl=Controls.TerrainAOResolutionPullDown},
    {adv=true, type="C", ctrl=Controls.TerrainClutterCheckbox},
    {adv=true, type="C", ctrl=Controls.WaterResolutionCheckbox},
    {adv=true, type="C", ctrl=Controls.WaterShaderCheckbox},
    {adv=true, type="D", label="LOC_OPTIONS_REFLECTION_PASSES_TOOLTIP", ctrl=Controls.ReflectionPassesPullDown},
    {adv=true, type="D", label="LOC_OPTIONS_LEADER_QUALITY_TOOLTIP",    ctrl=Controls.LeaderQualityPullDown},
    {adv=true, type="C", ctrl=Controls.MotionBlurEnabledCheckbox},
}

local audioTabSpecs = {
    {type="V", label="LOC_OPTIONS_MASTER_VOLUME", ctrl=Controls.MasterVolSlider, grp="Sound", key="Master Volume",   snd="Bus_Feedback_Master"},
    {type="V", label="LOC_OPTIONS_MUSIC_VOLUME",  ctrl=Controls.MusicVolSlider,  grp="Sound", key="Music Volume",    snd=nil},
    {type="V", label="LOC_OPTIONS_EFFECTS_VOLUME",ctrl=Controls.SFXVolSlider,    grp="Sound", key="SFX Volume",      snd="Bus_Feedback_SFX"},
    {type="V", label="LOC_OPTIONS_AMBIENT_VOLUME",ctrl=Controls.AmbVolSlider,    grp="Sound", key="Ambience Volume", snd="Bus_Feedback_Ambience"},
    {type="V", label="LOC_OPTIONS_SPEECH_VOLUME", ctrl=Controls.SpeechVolSlider, grp="Sound", key="Speech Volume",   snd="Bus_Feedback_Speech"},
    {type="C", ctrl=Controls.MuteFocusCheckbox},
}

local interfaceTabSpecs = {
    {type="D", label="LOC_OPTIONS_INTERFACE_CLOCK_FORMAT",                  ctrl=Controls.ClockFormat},
    {type="D", label="LOC_OPTIONS_INTERFACE_PLAYBYCLOUD_END_TURN_BEHAVIOR", ctrl=Controls.PlayByCloudEndTurnBehavior},
    {type="D", label="LOC_OPTIONS_INTERFACE_PLAYBYCLOUD_READY_BEHAVIOR",    ctrl=Controls.PlayByCloudClientReadyBehavior},
    {type="D", label="LOC_OPTIONS_INTERFACE_COLOR_BLINDNESS_ADAPTATION",    ctrl=Controls.ColorblindAdaptation},
    {type="D", label="LOC_OPTIONS_INTERFACE_LIGHTING",                      ctrl=Controls.RGBControl},
    {type="D", label="LOC_OPTIONS_STRATEGIC_VIEW_START",                    ctrl=Controls.StartInStrategicView},
    {type="D", label="LOC_OPTIONS_INTERFACE_GRAB_MOUSE",                    ctrl=Controls.MouseGrabPullDown},
    {type="D", label="LOC_OPTIONS_INTERFACE_EDGE_SCROLL",                   ctrl=Controls.EdgeScrollPullDown},
    {type="D", label="LOC_OPTIONS_INTERFACE_OPEN_TO_PROD_QUEUE",            ctrl=Controls.AutoProdQueuePullDown},
    {type="D", label="LOC_OPTIONS_INTERFACE_FORCE_CLICK_TO_DRAG",           ctrl=Controls.ReplaceDragWithClickPullDown},
    {type="D", label="LOC_OPTIONS_AUTO_UNIT_CYCLING",                       ctrl=Controls.UnitCyclingPullDown},
    {type="D", label="LOC_OPTIONS_RIBBON_STATS_LABEL",                      ctrl=Controls.RibbonStatsPullDown},
    {type="S", label="LOC_OPTIONS_CHAT_TEXT_SIZE",         ctrl=Controls.ChatTextSizeSlider,     val=Controls.ChatTextValue},
    {type="S", label="LOC_OPTIONS_INTERFACE_MINIMAP_SIZE", ctrl=Controls.MinimapSizeSlider,      val=nil},
    {type="S", label="LOC_OPTIONS_PLOT_TOOLTIP_DELAY",     ctrl=Controls.PlotToolTipDelaySlider, val=Controls.PlotToolTipDelayValue},
    {type="X", build=function()  -- Scroll speed (continuous)
        return mgr:CreateUIWidget("Slider", {
            GetLabel   = function() return Locale.Lookup("LOC_OPTIONS_SCROLL_SPEED") end,
            GetValue   = function() return Controls.ScrollSpeedValue:GetText() end,
            Increment  = function()
                local v = math.min(Controls.ScrollSpeedSlider:GetValue() + 0.01, 1.0)
                Controls.ScrollSpeedSlider:SetValue(v)
                local adj = math.clamp(MIN_SCROLL_SPEED + MAX_SCROLL_SPEED * v, MIN_SCROLL_SPEED, MAX_SCROLL_SPEED)
                Options.SetUserOption("Interface", "ScrollSpeed", adj)
                Controls.ConfirmButton:SetDisabled(false)
                Controls.ScrollSpeedValue:LocalizeAndSetText("LOC_OPTIONS_SCROLL_SPEED_VALUE", adj * 100)
            end,
            Decrement  = function()
                local v = math.max(Controls.ScrollSpeedSlider:GetValue() - 0.01, 0.0)
                Controls.ScrollSpeedSlider:SetValue(v)
                local adj = math.clamp(MIN_SCROLL_SPEED + MAX_SCROLL_SPEED * v, MIN_SCROLL_SPEED, MAX_SCROLL_SPEED)
                Options.SetUserOption("Interface", "ScrollSpeed", adj)
                Controls.ConfirmButton:SetDisabled(false)
                Controls.ScrollSpeedValue:LocalizeAndSetText("LOC_OPTIONS_SCROLL_SPEED_VALUE", adj * 100)
            end,
        })
    end},
    {type="X", build=function()  -- Scroll text speed (continuous)
        return mgr:CreateUIWidget("Slider", {
            GetLabel   = function() return Locale.Lookup("LOC_OPTIONS_SCROLL_TEXT_SPEED") end,
            GetValue   = function() return Controls.ScrollTextSpeedValue:GetText() end,
            Increment  = function()
                local v = math.min(Controls.ScrollTextSpeedSlider:GetValue() + 0.01, 1.0)
                Controls.ScrollTextSpeedSlider:SetValue(v)
                local adj = math.clamp(MIN_SCROLL_TEXT_SPEED + MAX_SCROLL_SPEED * v, MIN_SCROLL_TEXT_SPEED, MAX_SCROLL_TEXT_SPEED)
                Options.SetUserOption("Interface", "ScrollTextSpeed", adj)
                Controls.ConfirmButton:SetDisabled(false)
                Controls.ScrollTextSpeedValue:LocalizeAndSetText("LOC_OPTIONS_SCROLL_TEXT_SPEED_VALUE", adj * 100)
            end,
            Decrement  = function()
                local v = math.max(Controls.ScrollTextSpeedSlider:GetValue() - 0.01, 0.0)
                Controls.ScrollTextSpeedSlider:SetValue(v)
                local adj = math.clamp(MIN_SCROLL_TEXT_SPEED + MAX_SCROLL_SPEED * v, MIN_SCROLL_TEXT_SPEED, MAX_SCROLL_TEXT_SPEED)
                Options.SetUserOption("Interface", "ScrollTextSpeed", adj)
                Controls.ConfirmButton:SetDisabled(false)
                Controls.ScrollTextSpeedValue:LocalizeAndSetText("LOC_OPTIONS_SCROLL_TEXT_SPEED_VALUE", adj * 100)
            end,
        })
    end},
    {type="C", ctrl=Controls.TouchInputCheckbox},
    {type="C", ctrl=Controls.HistoricMomentsAnimCheckbox},
    {type="X", build=function()
        return mgr:CreateUIWidget("Button", {
            GetLabel     = function() return Controls.SwitchUILayout:GetText() end,
            IsHidden     = function() return Controls.SwitchUILayout:IsHidden() end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
            OnClick      = function() OnSwitchUILayout() end,
        })
    end},
}

local appTabSpecs = {
    {type="D", label="LOC_OPTIONS_APP_SHOW_MOVIE", ctrl=Controls.ShowIntroPullDown},
    {type="C", ctrl=Controls.WarnAboutModsCheckbox},
}

local langTabSpecs = {
    {type="D", label="LOC_OPTIONS_DISPLAY_LANGUAGE", ctrl=Controls.DisplayLanguagePullDown},
    {type="D", label="LOC_OPTIONS_SPOKEN_LANGUAGE",  ctrl=Controls.SpokenLanguagePullDown},
    {type="C", ctrl=Controls.EnableSubtitlesCheckbox},
}

-- ============================================================
-- Tab content builders
-- ============================================================

local function BuildGameTab()        AddSpecs(gameTabSpecs) end
local function BuildAudioTab()       AddSpecs(audioTabSpecs) end
local function BuildInterfaceTab()   AddSpecs(interfaceTabSpecs) end
local function BuildApplicationTab() AddSpecs(appTabSpecs) end
local function BuildLanguageTab()    AddSpecs(langTabSpecs) end

local function BuildGraphicsTab()
    AddSpecs(graphicsBaseSpecs)
    AddSpecs(graphicsAdvSpecs)  -- adv widgets report IsHidden from AdvancedOptionsContainer
end

local function BuildKeyBindingsTab()
    local actions = {}
    local count = Input.GetActionCount()
    for i = 0, count - 1 do
        local actionId = Input.GetActionId(i)
        if Input.ShouldShowActionKeybinding(actionId) then
            table.insert(actions, {
                id   = actionId,
                name = Locale.Lookup(Input.GetActionName(actionId)),
                cat  = Locale.Lookup(Input.GetActionCategory(actionId)),
                desc = Locale.Lookup(Input.GetActionDescription(actionId)) or "",
            })
        end
    end
    table.sort(actions, function(a, b)
        local r = Locale.Compare(a.cat, b.cat)
        if r == 0 then return Locale.Compare(a.name, b.name) == -1 end
        return r == -1
    end)

    local unbound = Locale.Lookup("LOC_CAI_KEYBINDING_UNBOUND")
    local altPrefix = Locale.Lookup("LOC_CAI_KEYBINDING_ALT")
    local currentCat = nil
    for _, action in ipairs(actions) do
        if action.cat ~= currentCat then
            currentCat = action.cat
            local catName = currentCat
            Add(mgr:CreateUIWidget("StaticText", {
                GetLabel = function() return catName end,
            }))
        end

        local actionId = action.id
        local sub = mgr:CreateUIWidget("SubMenu", {
            GetLabel   = function() return action.name end,
            GetValue   = function()
                local p = Input.GetGestureDisplayString(actionId, 0)
                local a = Input.GetGestureDisplayString(actionId, 1)
                if p and a then return p .. ", " .. altPrefix .. ": " .. a end
                if p then return p end
                if a then return altPrefix .. ": " .. a end
                return unbound
            end,
            GetTooltip = function() return action.desc end,
            OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        })

        local function StartBinding(index)
            m_ignoreNextBinding = true
            StartActiveKeyBinding(actionId, index)
            -- Push a key capture popup onto the manager stack
            local prompt = Locale.Lookup("LOC_CAI_KEYBINDING_PRESS_KEY", action.name)
            local capturePopup = mgr:CreateUIWidget("Panel", {
                GetLabel = function() return prompt end,
                SpeechSettings = { Role = false },
            })
            -- Escape cancels binding. All other input falls through (returns
            -- false) so the engine's gesture recorder can capture the key
            -- combo. This is safe because HandleInput only walks the parent
            -- chain — the popup is a stack root with no parent, so input
            -- cannot leak to widgets below.
            capturePopup.OnHandleInput = function(w, input)
                if input:GetMessageType() == KeyEvents.KeyUp
                        and input:GetKey() == Keys.VK_ESCAPE then
                    StopActiveKeyBinding()
                    return true
                end
                return false
            end
            m_bindingPopup = capturePopup
            mgr:Push(capturePopup)
        end

        sub:AddChild(mgr:CreateUIWidget("MenuItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_KEYBINDING_SET_PRIMARY") end,
            GetValue = function() return Input.GetGestureDisplayString(actionId, 0) or unbound end,
            OnClick  = function() StartBinding(0) end,
        }))
        sub:AddChild(mgr:CreateUIWidget("MenuItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_KEYBINDING_SET_ALT") end,
            GetValue = function() return Input.GetGestureDisplayString(actionId, 1) or unbound end,
            OnClick  = function() StartBinding(1) end,
        }))
        sub:AddChild(mgr:CreateUIWidget("MenuItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_KEYBINDING_CLEAR_PRIMARY") end,
            IsHidden = function() return not Input.GetGestureDisplayString(actionId, 0) end,
            OnClick  = function()
                Input.ClearGesture(actionId, 0)
                Controls.ConfirmButton:SetDisabled(false)
                RefreshKeyBinding()
            end,
        }))
        sub:AddChild(mgr:CreateUIWidget("MenuItem", {
            GetLabel = function() return Locale.Lookup("LOC_CAI_KEYBINDING_CLEAR_ALT") end,
            IsHidden = function() return not Input.GetGestureDisplayString(actionId, 1) end,
            OnClick  = function()
                Input.ClearGesture(actionId, 1)
                Controls.ConfirmButton:SetDisabled(false)
                RefreshKeyBinding()
            end,
        }))

        Add(sub)
    end
end

-- ============================================================
-- Panel management
-- ============================================================

local tabBuilders = {
    BuildGameTab, BuildGraphicsTab, BuildAudioTab, BuildInterfaceTab,
    BuildApplicationTab, BuildLanguageTab, BuildKeyBindingsTab
}

---Clears all OptionsList children and rebuilds content for tabIdx.
---Does NOT call SetFocus — the list's GetDefaultChild will pick up the first
---visible child when the user navigates into it naturally.
local function RebuildTabContent(tabIdx)
    if not OptionsList then return end
    OptionsList:ClearChildren()
    OptionsList.FocusedChild = nil
    local builder = tabBuilders[tabIdx]
    if builder then builder() end
end

---Builds the static panel skeleton: OptionsPanel with TabBar, OptionsList, action buttons
local function BuildBasePanel()
    OptionsPanel = mgr:CreateUIWidget("Dialog", {
        GetLabel = function() return Locale.Lookup("LOC_CAI_OPTIONS_DIALOG") end,
        SpeechSettings = { Role = false }
    })
    OptionsPanel:AddInputBinding({Key = Keys.VK_ESCAPE, Action = function()
        OnCancel()
        return true
    end})

    -- Tab bar as first child of OptionsPanel (not inside OptionsList)
    TabBar = mgr:CreateUIWidget("TabBar")
    OptionsPanel:AddChild(TabBar)

    for i, tab in ipairs(m_tabs) do
        local tabBtn   = tab[1]
        local titleKey = tab[3]
        local tabIdx   = i
        TabBar:AddChild(mgr:CreateUIWidget("Tab", {
            GetLabel     = function() return Locale.Lookup(titleKey) end,
            OnFocusEnter = function(w)
                UI.PlaySound("Main_Menu_Mouse_Over")
                -- Rebuild list content only when switching to a different tab
                if tabIdx ~= m_activeTabIdx then
                    OnSelectTab(tabIdx)
                end
            end,
            OnClick      = function() OnSelectTab(tabIdx) end,
        }))
    end

    -- Options list as second child of OptionsPanel
    OptionsList = mgr:CreateUIWidget("List")
    OptionsPanel:AddChild(OptionsList)

    -- Action buttons as direct Panel children (below the list)
    OptionsPanel:AddChild(mgr:CreateUIWidget("Button", {
        GetLabel     = function() return Controls.ConfirmButton:GetText() end,
        IsDisabled   = function() return Controls.ConfirmButton:IsDisabled() end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function() OnConfirm() end,
    }))
    OptionsPanel:AddChild(mgr:CreateUIWidget("Button", {
        GetLabel     = function() return Controls.ResetButton:GetText() end,
        IsHidden     = function() return Controls.ResetButton:IsHidden() end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function() OnReset() end,
    }))
    OptionsPanel:AddChild(mgr:CreateUIWidget("Button", {
        GetLabel     = function() return Controls.WindowCloseButton:GetText() end,
        OnFocusEnter = function() UI.PlaySound("Main_Menu_Mouse_Over") end,
        OnClick      = function() OnCancel() end,
    }))
end

---Pops OptionsPanel and any dropdowns above it from the manager stack
local function CloseOptions()
    while #mgr.Stack > 0 and mgr.Stack[#mgr.Stack] ~= OptionsPanel do
        mgr:Pop()
    end
    if #mgr.Stack > 0 then mgr:Pop() end
    OptionsPanel = nil
    OptionsList  = nil
    TabBar       = nil
end

---Pops the key capture popup if it's on the stack
local function PopBindingPopup()
    if m_bindingPopup and mgr:HasWidget(m_bindingPopup) then
        mgr:Pop()
    end
    m_bindingPopup = nil
end

Initialize = WrapFunc(Initialize, function(orig)
    orig()
    -- BindRecordedGesture is defined by InitializeKeyBinding called inside orig().
    -- Wrap it to discard the activation keypress so the user's intended key is recorded.
    -- After the real binding, pop the capture popup.
    BindRecordedGesture = WrapFunc(BindRecordedGesture, function(orig_bgr, gesture)
        if m_ignoreNextBinding then
            m_ignoreNextBinding = false
            return
        end
        orig_bgr(gesture)
        PopBindingPopup()
    end)
    -- Wrap StopActiveKeyBinding to also pop the popup on cancel
    StopActiveKeyBinding = WrapFunc(StopActiveKeyBinding, function(orig_stop)
        orig_stop()
        PopBindingPopup()
    end)
    BuildBasePanel()
end)

OnShow = WrapFunc(OnShow, function(orig)
    orig()  -- populates m_ctrlData via the wrapped Populate* helpers
    ContextPtr:SetInputHandler(function(input)
        return mgr:HandleInput(input)
    end, true)
    if not OptionsPanel then BuildBasePanel() end
    RebuildTabContent(m_activeTabIdx)
    if not mgr:HasWidget(OptionsPanel) then
        mgr:Push(OptionsPanel)
    end
end)

OnSelectTab = WrapFunc(OnSelectTab, function(orig, tab)
    orig(tab)
    local idx = type(tab) == "number" and tab or nil
    if not idx then
        for i, t in ipairs(m_tabs) do
            if t == tab then idx = i; break end
        end
    end
    if not idx or idx == m_activeTabIdx then return end
    m_activeTabIdx = idx
    if OptionsList then RebuildTabContent(idx) end
end)

OnCancel = WrapFunc(OnCancel, function(orig)
    orig()
    CloseOptions()
end)



Initialize();