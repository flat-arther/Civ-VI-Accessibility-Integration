-- Shared game boundary for production-widget tests. Each test runs in its own Lua process.
local Harness = { Speech = {} }

function Harness.Run(path, transform)
    local file = assert(io.open(path, "rb"))
    local source = file:read("a")
    file:close()
    if transform then source = transform(source) end
    assert(load(source, "@" .. path))()
end

local function event()
    local listeners = {}
    return setmetatable({
        Add = function(fn) listeners[fn] = true end,
        Remove = function(fn) listeners[fn] = nil end,
    }, { __call = function(_, ...) for fn in pairs(listeners) do fn(...) end end })
end

local function events()
    return setmetatable({}, { __index = function(t, key)
        local value = event(); rawset(t, key, value); return value
    end })
end

function Harness.Key(key, options)
    options = options or {}
    return {
        GetKey = function() return key end,
        GetMessageType = function() return options.Message or KeyEvents.KeyUp end,
        IsShiftDown = function() return options.Shift == true end,
        IsControlDown = function() return options.Control == true end,
        IsAltDown = function() return options.Alt == true end,
    }
end

function Harness.CreateManager(ignoredIncludes)
    Harness.Run("src/UI/shared/textProcessing.lua")
    Events, LuaEvents = events(), events()
    Speak = function(text) Harness.Speech[#Harness.Speech + 1] = text end
    SpeakLines = function(lines) for _, line in ipairs(lines) do Speak(line) end end
    ProcessText = function(text) return text end
    LogMessage, LogWarn = function() end, function() end
    LogError = function(message) error(message) end
    Locale = { Lookup = function(tag) return tag end, Compare = function(a, b) return a == b and 0 or (a < b and -1 or 1) end }
    WrapFunc = function(original, wrapper) return function(...) return wrapper(original, ...) end end
    Keys = setmetatable({}, { __index = function(t, key) rawset(t, key, key); return key end })
    KeyEvents = { KeyUp = 1, KeyDown = 2, Char = 3 }
    InputContext = { Shell = 1, World = 2 }
    Input = { SetActiveContext = function() end, GetActionId = function(name) return name end }
    Mouse = { eLClick = 1 }
    PopupPriority = { Low = 100, Medium = 500, High = 1000, Current = 9999 }
    Automation = { GetTime = function() return 1 end }
    CAISettings = { GetBool = function() return false end, GetNumber = function() return 1 end }
    CAI = { IsImeComposing = function() return false end, Silence = function() end }
    dofile('scripts/test-support/CAIAccessors.lua')(CAI)
    CAI.Active = true
    ExposedMembers = { CAI = CAI }
    IsCAIActive = function() return true end
    IsExpansion1Active, IsExpansion2Active = function() return false end, function() return false end

    local loaded = {}
    local helpers = { Navigation = true, Search = true, Tree = true, EditBox = true }
    local ignored = { caiUtils = true, InputSupport = true, Civ6Common = true, audioManager_CAI = true,
        CAIUITutorialManager = true, CAIUITutorialCatalog = true }
    for name in pairs(ignoredIncludes or {}) do ignored[name] = true end
    include = function(name)
        if loaded[name] then return end
        loaded[name] = true
        if ignored[name] then return end
        if name == "CAIModSupport" or name == "CAIControl" or name == "CAICollection" or name == "CAIColumns" or name == "CAIDescriptors" or name == "textProcessing" then
            Harness.Run("src/UI/shared/" .. name .. ".lua")
            return
        end
        if name:match("^CAIWidgetHelpers_") then
            if helpers[name:match("^CAIWidgetHelpers_(.+)")] then
                Harness.Run("src/UI/uiManager/helpers/" .. name .. ".lua")
            else
                _G[name] = setmetatable({}, { __index = function() return function() end end })
            end
        elseif name:match("^CAIWidget_") or name == "CAIWidgetRegistry" then
            Harness.Run("src/UI/uiManager/" .. name .. ".lua")
        else
            error("Unexpected include: " .. name)
        end
    end
    Harness.Run("src/UI/uiManager/CAIUIScreenManager.lua", function(source)
        local result, count = source:gsub("UIScreenManager:Init%(%)%s*%-%-#endregion%s*$", "-- Test owns initialization.")
        assert(count == 1, "manager bootstrap must be explicitly replaced")
        return result
    end)
    local mgr = UIScreenManager:New()
    CAI.UIManager = mgr
    return mgr
end

return Harness
