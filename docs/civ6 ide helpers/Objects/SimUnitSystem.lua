---@meta


---**Contexts:** UI
SimUnitSystem = {}
---**Contexts:** UI
---
---*Action*
function SimUnitSystem.SetVisMemberDamage() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param memberID number 
---@return table visArtState 
function SimUnitSystem.GetVisMemberArtState(Unit, memberID) end
---**Contexts:** UI
---
---*Action*
function SimUnitSystem.SetVisMemberHeading() end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param heading number 
function SimUnitSystem.SetVisHexHeading(Unit, heading) end
---**Contexts:** UI
---
---*Action*
function SimUnitSystem.SetVisMemberAnimationState() end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param unitMemberID number 
---@param artAttachmentID number 
---@param amount number 
function SimUnitSystem.ChangeVisMemberArtAttachment(Unit, unitMemberID, artAttachmentID, amount) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param heading number 
function SimUnitSystem.SetVisFormation(Unit, heading) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@param unitMemberID number 
---@return table visState 
function SimUnitSystem.GetVisMemberState(Unit, unitMemberID) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number heading 
function SimUnitSystem.GetVisHeading(Unit) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param entranceAnim string 
---@param exitAnim string 
function SimUnitSystem.SetAnimationState(Unit, entranceAnim, exitAnim) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param unitMemberID number 
---@param artAttachmentID number 
---@param amount number 
function SimUnitSystem.ChangeVisMemberArtAttachmentTint(Unit, unitMemberID, artAttachmentID, amount) end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number count 
function SimUnitSystem.GetVisMemberCount(Unit) end
---**Contexts:** UI
---
---*Action*
function SimUnitSystem.SetVisMemberPitchRoll() end
---**Contexts:** UI
---
---*Query*
---@param Unit Unit 
---@return number heading 
function SimUnitSystem.GetVisHexHeading(Unit) end
---**Contexts:** UI
---
---*Action*
---@param Unit Unit 
---@param unitMemberID number 
---@param amount number 
function SimUnitSystem.ChangeVisMemberArtVariation(Unit, unitMemberID, amount) end