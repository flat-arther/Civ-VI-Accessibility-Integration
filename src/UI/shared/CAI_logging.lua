-- ===========================================================================
-- CAI_logging.lua
-- Shared logging helpers for CAI. Uses Lua.log via print(...) and stores the
-- current threshold in CAI config as an internal non-DB setting.
-- ===========================================================================

CAILogging = CAILogging or {}

CAILogging.Levels = {
    message = 1,
    warn = 2,
    error = 3,
    off = 99,
}

CAILogging.LevelNames = {
    [1] = "MESSAGE",
    [2] = "WARN",
    [3] = "ERROR",
    [99] = "OFF",
}

CAILogging.ConfigSection = "CAIInternal"
CAILogging.ConfigKey = "LogLevel"
CAILogging.DefaultLevel = CAILogging.Levels.message

local function NormalizeLevel(level)
    if type(level) == "number" then
        for _, knownLevel in pairs(CAILogging.Levels) do
            if level == knownLevel then
                return level
            end
        end
        return nil
    end

    if type(level) == "string" then
        return CAILogging.Levels[string.lower(level)]
    end

    return nil
end

function CAILogging.GetLevel()
    if CAI == nil or CAI.GetConfigValue == nil then
        return CAILogging.DefaultLevel
    end

    local stored = CAI.GetConfigValue(
        CAILogging.ConfigSection,
        CAILogging.ConfigKey,
        tostring(CAILogging.DefaultLevel)
    )

    return NormalizeLevel(tonumber(stored)) or NormalizeLevel(stored) or CAILogging.DefaultLevel
end

function CAILogging.SetLevel(level)
    local normalized = NormalizeLevel(level)
    if normalized == nil then
        print("[CAI][WARN] Ignoring invalid log level: " .. tostring(level))
        return false
    end

    if CAI ~= nil and CAI.SetConfigValue ~= nil then
        CAI.SetConfigValue(
            CAILogging.ConfigSection,
            CAILogging.ConfigKey,
            tostring(normalized)
        )
    end

    return true
end

function CAILogging.ShouldLog(level)
    local messageLevel = NormalizeLevel(level)
    if messageLevel == nil then
        return false
    end

    return messageLevel >= CAILogging.GetLevel()
end

function CAILogging.Log(level, msg)
    local normalized = NormalizeLevel(level)
    if normalized == nil then
        print("[CAI][WARN] Invalid log level used for message: " .. tostring(level))
        return false
    end

    if not CAILogging.ShouldLog(normalized) then
        return false
    end

    local levelName = CAILogging.LevelNames[normalized] or tostring(normalized)
    print("[CAI][" .. levelName .. "] " .. tostring(msg))
    return true
end

function CAILogging.Message(msg)
    return CAILogging.Log(CAILogging.Levels.message, msg)
end

function CAILogging.Warn(msg)
    return CAILogging.Log(CAILogging.Levels.warn, msg)
end

function CAILogging.Error(msg)
    return CAILogging.Log(CAILogging.Levels.error, msg)
end
