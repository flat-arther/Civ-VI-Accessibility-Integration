---@meta


---**Contexts:** Gameplay, UI
---@class QuestsManager
local QuestsManager = {}
---@type table<userdata, table>
QuestsManager.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
QuestsManager.TypeName = "QuestsManager"
---**Contexts:** UI
---
---*Query*
function QuestsManager:GetActiveQuestDescription() end
---**Contexts:** UI
---
---*Query*
function QuestsManager:GetActiveQuestName() end
---**Contexts:** UI
---
---*Query*
function QuestsManager:GetActiveQuestReward() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param playerID number 
---@param minorID number 
---@param questType string 
---@return boolean  
function QuestsManager:HasActiveQuestFromPlayer(playerID, minorID, questType) end

z_dontRef_types.QuestsManager = QuestsManager