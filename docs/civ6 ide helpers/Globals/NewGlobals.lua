---@meta


function StrategicView_ClearReferenceMap() end
---@param referenceMap string
function StrategicView_SetReferenceMap(referenceMap) end
---@param normalizedAlpha number
function StrategicView_SetReferenceMapAlpha(normalizedAlpha) end
---@return number unknown
function ReferenceCurrentGameCoreEvent() end
--Don't use this, I've only gotten it to crash my game
function LookUpControl() end
---@return number normalizedAlpha
function StrategicView_GetReferenceMapAlpha() end
--Don't use this, it always returns false
---@param value any
---@return boolean
function IsNull(value) end
---@return number amount
function GetTickCount() end
---@return string trace
function traceback() end

TypeInfo = getmetatable
hpairs = pairs
include = require