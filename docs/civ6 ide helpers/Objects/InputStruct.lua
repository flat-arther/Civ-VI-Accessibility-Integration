---@meta


---**Contexts:** UI
---@class InputStruct
local InputStruct = {}
---@type table<userdata, table>
InputStruct.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
InputStruct.TypeName = "InputStruct"
---**Contexts:** UI
---
---*Query*
function InputStruct:GetFlags() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetKey() end
---**Contexts:** UI
---
---*Query*
---@return KeyEvents keyEvent 
function InputStruct:GetMessageType() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetMouseDX() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetMouseDY() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetTouchID() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetWheel() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetX() end
---**Contexts:** UI
---
---*Query*
function InputStruct:GetY() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsShiftDown() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsControlDown() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsLButtonDown() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsRButtonDown() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsMButtonDown() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function InputStruct:IsAnyButtonDown() end

z_dontRef_types.InputStruct = InputStruct