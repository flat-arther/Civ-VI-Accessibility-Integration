---@meta


---**Contexts:** UI
---@class CacheGameGossipManager
local CacheGameGossipManager = {}
---@type table<userdata, table>
CacheGameGossipManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
CacheGameGossipManager.TypeName = "CacheGameGossipManager"
---**Contexts:** UI
---
---*Query*
---@param earliestTurn number 
---@param player1ID number 
---@param player2ID number 
---@return table gossipStrings 
function CacheGameGossipManager.GetRecentVisibleGossipStrings(earliestTurn, player1ID, player2ID) end

z_dontRef_types.CacheGameGossipManager = CacheGameGossipManager