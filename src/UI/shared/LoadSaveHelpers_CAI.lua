-- shared helpers for the load and save menu screens

function SafeText(ctrl)
    if ctrl and ctrl.GetText then
        return ctrl:GetText() or ""
    end
    return ""
end

function SafeTooltip(ctrl)
    if ctrl and ctrl.GetToolTipString then
        return ctrl:GetToolTipString() or ""
    end
    return ""
end

function LookupBundleOrText(value)
    if value then
        local text = Locale.LookupBundle(value)
        if text == nil or text == "" then
            text = Locale.Lookup(value)
        end
        return text or ""
    end
    return ""
end

function GetEntryLabel(idx, entry)
    local instance = g_FileEntryInstanceList and g_FileEntryInstanceList[idx] or nil
    if instance and instance.ButtonText and instance.ButtonText.GetText then
        local text = instance.ButtonText:GetText()
        if text and text ~= "" then
            return text
        end
    end
    if entry and entry.DisplayName and entry.DisplayName ~= "" then
        return entry.DisplayName
    end
    if entry then
        return GetDisplayName(entry)
    end
    return ""
end

function IsDirectoryView()
    if not g_FileList or #g_FileList == 0 then return false end
    for _, entry in ipairs(g_FileList) do
        if entry.IsDirectory then return true end
    end
    return false
end

-- ---------------------------------------------------------------------------
-- Add detail rows as children of a TreeItem
-- ---------------------------------------------------------------------------
function AddDetailChild(parent, label, value)
    if not value or value == "" then return end
    local text = label and label ~= "" and (label .. ", " .. value) or value
    parent:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAILoadDetail"), "MenuItem", {
        Label = function() return text end,
    }))
end

function PopulateTreeItemDetails(treeItem, entry)
    local displayName = entry.DisplayName or GetDisplayName(entry)
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_FILE_NAME"), displayName)
    if entry.CurrentTurn then
        AddDetailChild(treeItem, nil, Locale.Lookup("LOC_LOADSAVE_CURRENT_TURN", entry.CurrentTurn))
    end
    if entry.DisplaySaveTime and entry.DisplaySaveTime ~= "" then
        AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_SAVE_TIME"), entry.DisplaySaveTime)
    end
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_ERA"), LookupBundleOrText(entry.HostEraName))
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_CIV"), LookupBundleOrText(entry.HostCivilizationName))
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_LEADER"), LookupBundleOrText(entry.HostLeaderName))
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_DIFFICULTY"), LookupBundleOrText(entry.HostDifficultyName))
    AddDetailChild(treeItem, Locale.Lookup("LOC_CAI_LABEL_SPEED"), LookupBundleOrText(entry.GameSpeedName))

    local rulesetName = LookupBundleOrText(entry.RulesetName)
    AddDetailChild(treeItem, Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_RULESET_TYPE_TITLE"), rulesetName)

    if entry.EnabledGameModes then
        local modeNames = {}
        local enabledModes = Modding.GetGameModesFromConfigurationString(entry.EnabledGameModes)
        for _, v in ipairs(enabledModes) do
            if v and v.Name and v.Name ~= "" then
                table.insert(modeNames, v.Name)
            end
        end
        if #modeNames > 0 then
            AddDetailChild(treeItem, Locale.Lookup("LOC_MULTIPLAYER_LOBBY_GAMEMODES_OFFICIAL"),
                table.concat(modeNames, ", "))
        end
    end

    AddDetailChild(treeItem, Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_TYPE_TITLE"),
        LookupBundleOrText(entry.MapScriptName))
    AddDetailChild(treeItem, Locale.Lookup("LOC_LOADSAVE_GAME_OPTIONS_MAP_SIZE_TITLE"),
        LookupBundleOrText(entry.MapSizeName))

    if entry.SavedByVersion and entry.SavedByVersion ~= "" then
        AddDetailChild(treeItem, Locale.Lookup("LOC_LOADSAVE_SAVED_BY_VERSION_TITLE"), entry.SavedByVersion)
    end

    if entry.TunerActive == true then
        AddDetailChild(treeItem, Locale.Lookup("LOC_LOADSAVE_TUNER_ACTIVE_TITLE"), Locale.Lookup("LOC_YES_BUTTON"))
    end

    local mods
    if g_FileType == SaveFileTypes.GAME_CONFIGURATION then
        mods = entry.EnabledMods or {}
    else
        mods = entry.RequiredMods or {}
    end

    if #mods > 0 then
        local modErrors = Modding.CheckRequirements(mods, g_GameType)
        if not Challenges.IsNullChallengeUuid(entry.GameChallengeUuid) then
            for _, v in ipairs(mods) do
                if modErrors and modErrors[v.Id] == "NotAllowed" then
                    modErrors[v.Id] = nil
                end
            end
        end

        local modTitles = {}
        for _, v in ipairs(mods) do
            local title = nil
            local modHandle = Modding.GetModHandle(v.Id)
            if modHandle then
                local modInfo = Modding.GetModInfo(modHandle)
                if modInfo and modInfo.Name then
                    title = Locale.Lookup(modInfo.Name)
                end
            end
            if not title or title == "" then
                title = LookupBundleOrText(v.Title)
            end
            if title and title ~= "" then
                if modErrors and modErrors[v.Id] then
                    table.insert(modTitles, title .. ", " .. Locale.Lookup("LOC_GAME_START_ERROR_TITLE"))
                else
                    table.insert(modTitles, title)
                end
            end
        end

        table.sort(modTitles, function(a, b) return Locale.Compare(a, b) == -1 end)

        if #modTitles > 0 then
            local modsNode = mgr:CreateWidget(mgr:GenerateWidgetId("CAILoadMods"), "TreeItem", {
                Label = function() return Locale.Lookup("LOC_MAIN_MENU_ADDITIONAL_CONTENT") end,
            })
            for _, title in ipairs(modTitles) do
                modsNode:AddChild(mgr:CreateWidget(mgr:GenerateWidgetId("CAILoadMod"), "MenuItem", {
                    Label = function() return title end,
                }))
            end
            treeItem:AddChild(modsNode)
        end
    end
end

-- ---------------------------------------------------------------------------
-- Directory dropdown helpers
-- ---------------------------------------------------------------------------
function BuildDirectoryOptions()
    local options = {}
    local selectedIdx = 0
    local usingVolumeName = nil

    if g_CurrentDirectorySegments then
        for i = #g_CurrentDirectorySegments, 1, -1 do
            local v = g_CurrentDirectorySegments[i]
            local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.SegmentName
            table.insert(options, { label = displayName, value = { type = "level", level = i } })
            if i == #g_CurrentDirectorySegments then
                selectedIdx = #options
            end
            if i == 1 then
                usingVolumeName = v.SegmentName
            end
        end
    end

    if g_VolumeList == nil then
        g_VolumeList = UI.GetVolumes(SaveLocations.LOCAL_STORAGE)
    end

    if g_VolumeList then
        for _, v in ipairs(g_VolumeList) do
            if usingVolumeName == nil or usingVolumeName ~= v.VolumeName then
                local displayName = (v.DisplayName ~= nil and v.DisplayName ~= "") and v.DisplayName or v.VolumeName
                table.insert(options, { label = displayName, value = { type = "volume", name = v.VolumeName } })
            end
        end
    end

    return options, selectedIdx
end

-- ---------------------------------------------------------------------------
-- Sort dropdown helpers
-- ---------------------------------------------------------------------------
function BuildSortOptions()
    return {
        { label = Locale.Lookup("LOC_SORTBY_LASTMODIFIED"), value = { func = SortByLastModified, index = 1 } },
        { label = Locale.Lookup("LOC_SORTBY_NAME"),         value = { func = SortByName, index = 2 } },
    }
end

function GetCurrentSortIndex()
    local currentLabel = ""
    local button = Controls.SortByPullDown and Controls.SortByPullDown:GetButton()
    if button then currentLabel = button:GetText() or "" end
    if currentLabel == Locale.Lookup("LOC_SORTBY_NAME") then return 2 end
    return 1
end

function MakeSimpleBtn(ctrl)
    local btn = mgr:CreateWidget(mgr:GenerateWidgetId("LoadSave_Button"), "Button", {
        Label = function() return ctrl:GetText() or "" end
    })
    btn:On("activate", function(w)
        ctrl:DoLeftClick()
    end)
    btn:SetFocusSound("Main_Menu_Mouse_Over")
    return btn
end
