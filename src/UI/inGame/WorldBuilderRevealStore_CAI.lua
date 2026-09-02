-- ===========================================================================
--  WorldBuilderRevealStore_CAI  (GAMEPLAY context)
-- ===========================================================================
-- Bridge for World Builder per-player visibility persistence.
--
-- WorldBuilder.ConfigurationManager() is a Gameplay-context object; its
-- SetMapValue/GetMapValues only round-trip here, in the Gameplay Lua state
-- (from the UI context custom keys read back nil). This script owns that config
-- I/O and bridges the data to the UI context (WorldBuilderPlacement_CAI.lua)
-- through the shared ExposedMembers table:
--   * On load it reads every CAI_WB_REVEALED_P* key and publishes them to
--     ExposedMembers.CAI_WB_Reveal for the UI's LoadAllReveal to consume.
--   * ExposedMembers.CAI_WB_SaveReveal(player, serialized) lets the UI persist
--     an edit through this (Gameplay) context.
--
-- The config values are serialized with the .Civ6Map, so they survive save and
-- reload. Debug logging is verbose while this path is being validated.

print("CAI_WB_GP >>> WorldBuilderRevealStore_CAI GAMEPLAY script BEGIN parse")

local KEY_PREFIX = "CAI_WB_REVEALED_P"

-- Report the shared-table bridge state as seen from the gameplay context.
if ExposedMembers == nil then
    print("CAI_WB_GP >>> ExposedMembers is NIL in gameplay context")
else
    print("CAI_WB_GP >>> ExposedMembers present in gameplay context")
end

local function ConfigMgr()
    if WorldBuilder == nil or WorldBuilder.ConfigurationManager == nil then return nil end
    return WorldBuilder.ConfigurationManager()
end

-- Read every persisted reveal key and publish to the shared UI/Gameplay table.
local function PublishFromConfig()
    local mgr = ConfigMgr()
    if mgr == nil then
        print("CAI_WB_GP >>> PublishFromConfig: ConfigurationManager unavailable")
        return
    end
    local attribs = mgr:GetMapValues() or {}
    local total = 0
    for k, v in pairs(attribs) do
        total = total + 1
        print("CAI_WB_GP >>> GetMapValues key[" .. tostring(k) .. "] = '" .. tostring(v) .. "'")
    end
    print("CAI_WB_GP >>> GetMapValues returned " .. tostring(total) .. " total keys")
    local out = {}
    local n = 0
    for k, v in pairs(attribs) do
        if type(k) == "string" and string.sub(k, 1, #KEY_PREFIX) == KEY_PREFIX then
            out[k] = v
            n = n + 1
            print("CAI_WB_GP >>> LOAD " .. k .. " = '" .. tostring(v) .. "'")
        end
    end
    ExposedMembers.CAI_WB_Reveal = out
    print("CAI_WB_GP >>> published " .. tostring(n) .. " reveal keys to ExposedMembers.CAI_WB_Reveal")
end

-- Persist one player's serialized reveal string from the Gameplay context.
ExposedMembers.CAI_WB_SaveReveal = function(player, serialized)
    local mgr = ConfigMgr()
    if mgr == nil then
        print("CAI_WB_GP >>> SAVE: ConfigurationManager unavailable")
        return
    end
    local key = KEY_PREFIX .. tostring(player)
    mgr:SetMapValue(key, serialized)
    ExposedMembers.CAI_WB_Reveal = ExposedMembers.CAI_WB_Reveal or {}
    ExposedMembers.CAI_WB_Reveal[key] = serialized
    print("CAI_WB_GP >>> SAVE " .. key .. " = '" .. tostring(serialized) ..
        "' readback='" .. tostring(mgr:GetMapValues()[key]) .. "'")
end
print("CAI_WB_GP >>> ExposedMembers.CAI_WB_SaveReveal registered")

print("CAI_WB_GP >>> script loaded; WorldBuilder=" .. tostring(WorldBuilder ~= nil) ..
    " ConfigurationManager=" .. tostring(WorldBuilder ~= nil and WorldBuilder.ConfigurationManager ~= nil))
PublishFromConfig()

-- ---------------------------------------------------------------------------
-- TEMP SELF-TEST (remove once validated). Proves, independent of the UI and
-- the bridge, whether gameplay-context SetMapValue (a) accepts a custom key in
-- the same session and (b) persists it into the .Civ6Map across a reload.
--   * First run on a fresh map:  existing='nil', after-write readback='PERSISTED_OK'
--   * Save Map, exit, reload:     existing='PERSISTED_OK'  => it serialized.
-- ---------------------------------------------------------------------------
do
    local mgr = ConfigMgr()
    if mgr ~= nil then
        local existing = mgr:GetMapValues()["CAI_WB_SELFTEST_KEY"]
        print("CAI_WB_GP >>> SELFTEST existing before write = '" .. tostring(existing) .. "'")
        mgr:SetMapValue("CAI_WB_SELFTEST_KEY", "PERSISTED_OK")
        print("CAI_WB_GP >>> SELFTEST after write readback = '" ..
            tostring(mgr:GetMapValues()["CAI_WB_SELFTEST_KEY"]) .. "'")
    end
end

print("CAI_WB_GP >>> WorldBuilderRevealStore_CAI GAMEPLAY script END parse")
