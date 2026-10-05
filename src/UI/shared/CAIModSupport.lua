-- Mod-registry queries available in frontend and in-game contexts.
CAIModSupport = {}

local BBG_MOD_IDS = {
    "cb84075d-5007-4207-b662-c35a5f7be240", -- iElden (current)
    "cb84075d-5007-4207-b662-c35a5f7be217", -- codenaugh
    "cb84075d-5007-4207-b662-c35a5f7be231", -- beta
}

function CAIModSupport.IsBBGActive()
    for _, id in ipairs(BBG_MOD_IDS) do
        if Modding.IsModActive(id) then return true end
    end
    return false
end
