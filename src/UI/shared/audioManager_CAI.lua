-- ===========================================================================
-- CAIAudioManager.lua
-- Shared raw-audio manager for CAI.
-- Loads sound definitions from configuration DB rows, resolves files from the
-- mod root, stores loaded sounds by id and tag, and services delayed playback.
-- ===========================================================================

CAIAudioManager = CAIAudioManager or {}

local AUDIO_DEFINITION_QUERY = [[
    SELECT SoundId, RelativePath, Tag
    FROM CAI_AudioDefinitions
    ORDER BY Tag, SoundId
]]

local function GetTime()
    return Automation.GetTime()
end

local function NormalizePath(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function NormalizeTagKey(tag)
    return tostring(tag or ""):gsub("[^%w_]", "_")
end

local function BuildTagSettingId(prefix, tag)
    return prefix .. "_" .. NormalizeTagKey(tag)
end

local function ClampVolumeScalar(volume)
    if volume < 0 then return 0 end
    if volume > 1 then return 1 end
    return volume
end

local function GetTagCandidates(tag)
    local candidates = {}
    local current = NormalizeTagKey(tag)
    if current == "" then
        return candidates
    end

    while current ~= "" do
        table.insert(candidates, current)
        local cut = string.match(current, "^(.*)_[^_]+$")
        if cut == nil or cut == "" then
            break
        end
        current = cut
    end

    return candidates
end

function CAIAudioManager:New()
    local mgr = setmetatable({}, { __index = CAIAudioManager })
    mgr.Owner = nil
    mgr.ModRoot = nil
    mgr.IsInitialized = false
    mgr.SettingsHooked = false
    mgr.SettingsChangedListener = nil
    mgr.DefinitionsById = {}
    mgr.LoadedSoundsById = {}
    mgr.SoundsByTag = {}
    mgr.Queue = {}
    return mgr
end

function CAIAudioManager:ResolveModRoot()
    local filePath = UIManager:GetFilePath("audioManager_CAI.lua")
    if filePath == nil or filePath == "" then
        print("CAIAudioManager.ResolveModRoot: UIManager:GetFilePath returned no path for audioManager_CAI.lua")
        return nil
    end

    local normalizedPath = NormalizePath(filePath)
    local modRoot = string.match(normalizedPath, "^(.*)/UI/")
    if modRoot == nil or modRoot == "" then
        print("CAIAudioManager.ResolveModRoot: unable to derive mod root from " .. tostring(normalizedPath))
        return nil
    end

    return modRoot
end

function CAIAudioManager:BuildFullPath(relativePath)
    if self.ModRoot == nil or self.ModRoot == "" then
        print("CAIAudioManager.BuildFullPath: ModRoot is not initialized")
        return nil
    end

    if relativePath == nil or relativePath == "" then
        print("CAIAudioManager.BuildFullPath: missing RelativePath")
        return nil
    end

    return self.ModRoot .. "/" .. NormalizePath(relativePath)
end

function CAIAudioManager:GetDefinitionRows()
    local rows = DB.ConfigurationQuery(AUDIO_DEFINITION_QUERY)
    if rows == nil then
        print("CAIAudioManager.GetDefinitionRows: DB.ConfigurationQuery returned nil")
        return {}
    end

    return rows
end

function CAIAudioManager:LoadDefinitions()
    self.DefinitionsById = {}

    local rows = self:GetDefinitionRows()
    for _, row in ipairs(rows) do
        if row.SoundId == nil or row.SoundId == "" then
            print("CAIAudioManager.LoadDefinitions: skipping row with missing SoundId")
        elseif row.RelativePath == nil or row.RelativePath == "" then
            print("CAIAudioManager.LoadDefinitions: skipping " .. tostring(row.SoundId) .. " because RelativePath is missing")
        elseif row.Tag == nil or row.Tag == "" then
            print("CAIAudioManager.LoadDefinitions: skipping " .. tostring(row.SoundId) .. " because Tag is missing")
        else
            self.DefinitionsById[row.SoundId] = {
                SoundId = row.SoundId,
                RelativePath = NormalizePath(row.RelativePath),
                Tag = row.Tag,
            }
        end
    end
end

function CAIAudioManager:ApplyTagVolume(record)
    if record == nil or record.Handle == nil then return end
    CAI.SetSoundVolume(record.Handle, self:GetTagVolumeScalar(record.Tag))
end

function CAIAudioManager:UnloadSounds()
    self.Queue = {}

    for soundId, record in pairs(self.LoadedSoundsById) do
        CAI.StopSound(record.Handle)
        local destroyed = CAI.DestroySound(record.Handle)
        if not destroyed then
            print("CAIAudioManager.UnloadSounds: failed to destroy " .. tostring(soundId))
        end
    end

    self.LoadedSoundsById = {}
    self.SoundsByTag = {}
end

function CAIAudioManager:LoadSounds()
    self:UnloadSounds()
    self:LoadDefinitions()

    for soundId, def in pairs(self.DefinitionsById) do
        local fullPath = self:BuildFullPath(def.RelativePath)
        if fullPath == nil then
            print("CAIAudioManager.LoadSounds: unable to build full path for " .. tostring(soundId))
        else
            local handle = CAI.LoadSound(fullPath)
            if handle == nil then
                print("CAIAudioManager.LoadSounds: failed to load " .. tostring(soundId) .. " from " .. tostring(fullPath))
            else
                local record = {
                    SoundId = soundId,
                    RelativePath = def.RelativePath,
                    FullPath = fullPath,
                    Tag = def.Tag,
                    Handle = handle,
                }

                self.LoadedSoundsById[soundId] = record
                if self.SoundsByTag[def.Tag] == nil then
                    self.SoundsByTag[def.Tag] = {}
                end
                table.insert(self.SoundsByTag[def.Tag], record)
                self:ApplyTagVolume(record)
            end
        end
    end
end

function CAIAudioManager:GetSound(soundId)
    return self.LoadedSoundsById[soundId]
end

function CAIAudioManager:GetSoundsByTag(tag)
    return self.SoundsByTag[tag] or {}
end

function CAIAudioManager:FindTagSettingId(prefix, tag)
    for _, candidate in ipairs(GetTagCandidates(tag)) do
        local settingId = BuildTagSettingId(prefix, candidate)
        if CAISettings.Exists(settingId) then
            return settingId
        end
    end

    return nil
end

function CAIAudioManager:GetTagEnabledSettingId(tag)
    return self:FindTagSettingId("AudioTagEnabled", tag)
end

function CAIAudioManager:GetTagVolumeSettingId(tag)
    return self:FindTagSettingId("AudioTagVolume", tag)
end

function CAIAudioManager:IsTagEnabled(tag)
    local settingId = self:GetTagEnabledSettingId(tag)
    if settingId == nil then
        return true
    end

    return CAISettings.GetBool(settingId)
end

function CAIAudioManager:GetTagVolumeScalar(tag)
    local settingId = self:GetTagVolumeSettingId(tag)
    if settingId == nil then
        return 1
    end

    return ClampVolumeScalar(CAISettings.GetNumber(settingId) / 100)
end

function CAIAudioManager:ClearQueuedSound(soundId)
    for i = #self.Queue, 1, -1 do
        if self.Queue[i].SoundId == soundId then
            table.remove(self.Queue, i)
        end
    end
end

function CAIAudioManager:ClearQueuedTag(tag)
    local bucket = self.SoundsByTag[tag]
    if bucket == nil then return end

    for _, record in ipairs(bucket) do
        self:ClearQueuedSound(record.SoundId)
    end
end

function CAIAudioManager:ShouldSkipPlay(record, options)
    if record == nil or record.Handle == nil then
        return false
    end

    if options ~= nil and options.SkipIfPlaying and CAI.IsSoundPlaying(record.Handle) then
        return true
    end

    return false
end

function CAIAudioManager:Play(soundId, options)
    local record = self:GetSound(soundId)
    if record == nil then
        print("CAIAudioManager.Play: unknown or unloaded sound " .. tostring(soundId))
        return false
    end

    if not self:IsTagEnabled(record.Tag) then
        return false
    end

    if self:ShouldSkipPlay(record, options) then
        return false
    end

    CAI.PlaySound(record.Handle)
    return true
end

function CAIAudioManager:QueueSound(soundId, delaySeconds, options)
    local record = self:GetSound(soundId)
    if record == nil then
        print("CAIAudioManager.QueueSound: unknown or unloaded sound " .. tostring(soundId))
        return false
    end

    if not self:IsTagEnabled(record.Tag) then
        return false
    end

    table.insert(self.Queue, {
        SoundId = soundId,
        DueTime = GetTime() + (delaySeconds or 0),
        Options = options,
    })
    return true
end

function CAIAudioManager:StopSound(soundId)
    local record = self:GetSound(soundId)
    if record == nil then
        print("CAIAudioManager.StopSound: unknown or unloaded sound " .. tostring(soundId))
        return false
    end

    self:ClearQueuedSound(soundId)
    CAI.StopSound(record.Handle)
    return true
end

function CAIAudioManager:PauseSound(soundId)
    local record = self:GetSound(soundId)
    if record == nil then
        print("CAIAudioManager.PauseSound: unknown or unloaded sound " .. tostring(soundId))
        return false
    end

    self:ClearQueuedSound(soundId)
    CAI.PauseSound(record.Handle)
    return true
end

function CAIAudioManager:SetSoundVolume(soundId, volume)
    local record = self:GetSound(soundId)
    if record == nil then
        print("CAIAudioManager.SetSoundVolume: unknown or unloaded sound " .. tostring(soundId))
        return false
    end

    CAI.SetSoundVolume(record.Handle, volume)
    return true
end

function CAIAudioManager:SetTagVolume(tag, volume)
    local bucket = self.SoundsByTag[tag]
    if bucket == nil then
        print("CAIAudioManager.SetTagVolume: unknown tag " .. tostring(tag))
        return false
    end

    for _, record in ipairs(bucket) do
        CAI.SetSoundVolume(record.Handle, volume)
    end

    return true
end

function CAIAudioManager:StopTag(tag)
    local bucket = self.SoundsByTag[tag]
    if bucket == nil then
        print("CAIAudioManager.StopTag: unknown tag " .. tostring(tag))
        return false
    end

    self:ClearQueuedTag(tag)
    for _, record in ipairs(bucket) do
        CAI.StopSound(record.Handle)
    end

    return true
end

function CAIAudioManager:PauseTag(tag)
    local bucket = self.SoundsByTag[tag]
    if bucket == nil then
        print("CAIAudioManager.PauseTag: unknown tag " .. tostring(tag))
        return false
    end

    self:ClearQueuedTag(tag)
    for _, record in ipairs(bucket) do
        CAI.PauseSound(record.Handle)
    end

    return true
end

function CAIAudioManager:ApplySettings()
    for _, record in pairs(self.LoadedSoundsById) do
        self:ApplyTagVolume(record)
    end

    for tag, _ in pairs(self.SoundsByTag) do
        if not self:IsTagEnabled(tag) then
            self:StopTag(tag)
        end
    end
end

function CAIAudioManager:OnSettingsChanged(settingId)
    if string.find(tostring(settingId), "^AudioTagEnabled_") ~= nil
        or string.find(tostring(settingId), "^AudioTagVolume_") ~= nil then
        self:ApplySettings()
    end
end

function CAIAudioManager:HookSettingsChanged()
    if self.SettingsHooked then
        return
    end

    self.SettingsChangedListener = function(settingId)
        self:OnSettingsChanged(settingId)
    end
    LuaEvents.CAISettingsChanged.Add(self.SettingsChangedListener)
    self.SettingsHooked = true
end

function CAIAudioManager:UnhookSettingsChanged()
    if not self.SettingsHooked then
        return
    end

    LuaEvents.CAISettingsChanged.Remove(self.SettingsChangedListener)
    self.SettingsChangedListener = nil
    self.SettingsHooked = false
end

function CAIAudioManager:Update()
    if #self.Queue == 0 then return end

    local now = GetTime()
    for i = #self.Queue, 1, -1 do
        local item = self.Queue[i]
        if now >= item.DueTime then
            self:Play(item.SoundId, item.Options)
            table.remove(self.Queue, i)
        end
    end
end

function CAIAudioManager:Initialize(owner)
    if self.IsInitialized then
        self.Owner = owner
        self:ApplySettings()
        return
    end

    self.Owner = owner
    self.ModRoot = self:ResolveModRoot()
    if self.ModRoot == nil then
        print("CAIAudioManager.Initialize: audio manager has no mod root")
        return
    end

    self:LoadSounds()
    self:ApplySettings()
    self:HookSettingsChanged()
    self.IsInitialized = true
end

function CAIAudioManager:Shutdown()
    self:UnhookSettingsChanged()
    self:UnloadSounds()
    self.DefinitionsById = {}
    self.Owner = nil
    self.ModRoot = nil
    self.IsInitialized = false
end
