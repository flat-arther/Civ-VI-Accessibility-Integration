-- ===========================================================================
-- CAISettings.lua
-- Metadata-driven settings backed by CAI.GetConfigValue / CAI.SetConfigValue.
-- ===========================================================================

CAISettings = CAISettings or {}

-- ===========================================================================
-- Internal helpers
-- ===========================================================================

local function GetDefinition(settingId)
    local rows = DB.ConfigurationQuery([[
        SELECT *
        FROM CAI_Settings
        WHERE SettingId = ?
    ]], settingId)

    if rows == nil or #rows == 0 then
        return nil
    end

    return rows[1]
end

local function ToBool(value)
    value = tostring(value):lower()
    return value == "true"
        or value == "1"
        or value == "yes"
        or value == "on"
end

local function ConvertValue(value, valueType, defaultValue)
    if valueType == "bool" then
        return ToBool(value)
    end

    if valueType == "number" then
        return tonumber(value) or tonumber(defaultValue) or 0
    end

    return tostring(value or defaultValue or "")
end

local function ClampNumber(value, def)
    local n = tonumber(value) or tonumber(def.DefaultValue) or 0

    if def.MinValue ~= nil then
        n = math.max(n, tonumber(def.MinValue) or n)
    end

    if def.MaxValue ~= nil then
        n = math.min(n, tonumber(def.MaxValue) or n)
    end

    return n
end

local function ToStoredString(value, def)
    if def.ValueType == "bool" then
        return ToBool(value) and "true" or "false"
    end

    if def.ValueType == "number" then
        return tostring(ClampNumber(value, def))
    end

    return tostring(value or "")
end

-- ===========================================================================
-- Metadata API
-- ===========================================================================

function CAISettings.GetDefinition(settingId)
    return GetDefinition(settingId)
end

function CAISettings.GetDefinitions()
    return DB.ConfigurationQuery([[
        SELECT *
        FROM CAI_Settings
        ORDER BY Section, SortIndex, SettingId
    ]]) or {}
end

function CAISettings.GetOptions(settingId)
    return DB.ConfigurationQuery([[
        SELECT *
        FROM CAI_SettingOptions
        WHERE SettingId = ?
        ORDER BY SortIndex, Value
    ]], settingId) or {}
end

function CAISettings.Exists(settingId)
    return GetDefinition(settingId) ~= nil
end

-- ===========================================================================
-- Value API
-- ===========================================================================

function CAISettings.Get(settingId)
    local def = GetDefinition(settingId)
    if def == nil then
        print("CAISettings.Get: unknown setting " .. tostring(settingId))
        return nil
    end

    local raw = CAI.GetConfigValue(def.Section, def.SettingId, def.DefaultValue)
    return ConvertValue(raw, def.ValueType, def.DefaultValue)
end

function CAISettings.Set(settingId, value)
    local def = GetDefinition(settingId)
    if def == nil then
        print("CAISettings.Set: unknown setting " .. tostring(settingId))
        return false
    end

    local storedValue = ToStoredString(value, def)
    local ok = CAI.SetConfigValue(def.Section, def.SettingId, storedValue)

    if ok and LuaEvents.CAISettingsChanged ~= nil then
        LuaEvents.CAISettingsChanged(
            settingId,
            ConvertValue(storedValue, def.ValueType, def.DefaultValue)
        )
    end

    return ok
end

function CAISettings.GetDefault(settingId)
    local def = GetDefinition(settingId)
    if def == nil then
        print("CAISettings.GetDefault: unknown setting " .. tostring(settingId))
        return nil
    end

    return ConvertValue(def.DefaultValue, def.ValueType, def.DefaultValue)
end

function CAISettings.Reset(settingId)
    local def = GetDefinition(settingId)
    if def == nil then
        print("CAISettings.Reset: unknown setting " .. tostring(settingId))
        return false
    end

    return CAISettings.Set(settingId, def.DefaultValue)
end

---Invoke a metadata action without persisting a meaningless setting value.
---@param settingId string
---@param actionValue? any
---@return boolean
function CAISettings.Invoke(settingId, actionValue)
    local def = GetDefinition(settingId)
    if def == nil then
        print("CAISettings.Invoke: unknown setting " .. tostring(settingId))
        return false
    end
    if def.UIType ~= "button" then
        print("CAISettings.Invoke: setting is not a button " .. tostring(settingId))
        return false
    end

    local value = actionValue
    if value == nil then value = def.ActionValue or def.DefaultValue end
    if LuaEvents.CAISettingsChanged ~= nil then
        LuaEvents.CAISettingsChanged(settingId, value)
    end
    return true
end

-- ===========================================================================
-- Typed helpers
-- ===========================================================================

function CAISettings.GetBool(settingId)
    return CAISettings.Get(settingId) == true
end

function CAISettings.SetBool(settingId, value)
    return CAISettings.Set(settingId, value and "true" or "false")
end

function CAISettings.ToggleBool(settingId)
    local value = not CAISettings.GetBool(settingId)
    CAISettings.SetBool(settingId, value)
    return value
end

function CAISettings.GetNumber(settingId)
    return tonumber(CAISettings.Get(settingId)) or 0
end

function CAISettings.SetNumber(settingId, value)
    return CAISettings.Set(settingId, tonumber(value) or 0)
end

function CAISettings.GetString(settingId)
    return tostring(CAISettings.Get(settingId) or "")
end

function CAISettings.SetString(settingId, value)
    return CAISettings.Set(settingId, tostring(value or ""))
end

-- ===========================================================================
-- UI helpers
-- ===========================================================================

function CAISettings.GetLabel(settingId)
    local def = GetDefinition(settingId)
    if def == nil or def.Label == nil or def.Label == "" then
        return tostring(settingId)
    end

    return Locale.Lookup(def.Label)
end

function CAISettings.GetTooltip(settingId)
    local def = GetDefinition(settingId)
    if def == nil or def.Tooltip == nil or def.Tooltip == "" then
        return nil
    end

    return Locale.Lookup(def.Tooltip)
end
