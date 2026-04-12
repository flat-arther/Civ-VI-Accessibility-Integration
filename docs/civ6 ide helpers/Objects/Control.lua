---@meta


---**Contexts:** UI
---@class Control
local Control = {}
---@type table<userdata, table>
Control.__instances = {}
---Name of the object's class; differs between UI and Gameplay context
Control.TypeName = "Control"
---**Contexts:** UI
---
---*Action*
function Control:SetOffset() end
---**Contexts:** UI
---
---*Action*
function Control:SetOffsetX() end
---**Contexts:** UI
---
---*Action*
function Control:SetOffsetY() end
---**Contexts:** UI
---
---*Action*
function Control:SetOffsetVal() end
---**Contexts:** UI
---
---*Query*
function Control:GetOffsetX() end
---**Contexts:** UI
---
---*Query*
function Control:GetOffsetY() end
---**Contexts:** UI
---
---*Query*
function Control:GetOffsetVal() end
---**Contexts:** UI
---
---*Query*
function Control:GetScreenOffset() end
---**Contexts:** UI
---
---*Action*
function Control:SetAnchor() end
---**Contexts:** UI
---
---*Action*
function Control:SetAllChildrenVisible() end
---**Contexts:** UI
---
---*Action*
function Control:SetHide() end
---**Contexts:** UI
---
---*Action*
function Control:SetShow() end
---**Contexts:** UI
---
---*Action*
function Control:SetNoClip() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsHidden() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsVisible() end
---**Contexts:** UI
---
---*Query*
function Control:GetNumChildren() end
---**Contexts:** UI
---
---*Query*
function Control:GetChildren() end
---**Contexts:** UI
---
---*Query*
function Control:ReprocessAnchoring() end
---**Contexts:** UI
---
---*Query*
function Control:GetSizeX() end
---**Contexts:** UI
---
---*Query*
function Control:GetSizeY() end
---**Contexts:** UI
---
---*Query*
function Control:GetSizeVal() end
---**Contexts:** UI
---
---*Action*
function Control:SetSize() end
---**Contexts:** UI
---
---*Action*
function Control:SetSizeX() end
---**Contexts:** UI
---
---*Action*
function Control:SetSizeY() end
---**Contexts:** UI
---
---*Action*
function Control:SetSizeVal() end
---**Contexts:** UI
---
---*Action*
function Control:DoAutoSize() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentRelativeSizeX() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentRelativeSizeY() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentRelativeSizeVal() end
---**Contexts:** UI
---
---*Action*
function Control:SetParentRelativeSize() end
---**Contexts:** UI
---
---*Action*
function Control:SetParentRelativeSizeX() end
---**Contexts:** UI
---
---*Action*
function Control:SetParentRelativeSizeY() end
---**Contexts:** UI
---
---*Action*
function Control:SetParentRelativeSizeVal() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentRelativeOffset() end
---**Contexts:** UI
---
---*Action*
function Control:SetColor() end
---**Contexts:** UI
---
---*Action*
function Control:SetColorByName() end
---**Contexts:** UI
---
---*Action*
function Control:SetAlpha() end
---**Contexts:** UI
---
---*Query*
function Control:GetAlpha() end
---**Contexts:** UI
---
---*Action*
function Control:SortChildren() end
---**Contexts:** UI
---
---*Action*
function Control:AddChildAtIndex() end
---**Contexts:** UI
---
---*Action*
function Control:BranchResetAnimation() end
---**Contexts:** UI
---
---*Action*
function Control:SetID() end
---**Contexts:** UI
---
---*Query*
function Control:GetID() end
---**Contexts:** UI
---
---*Action*
function Control:SetDisabled() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsDisabled() end
---**Contexts:** UI
---
---*Action*
function Control:SetEnabled() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsEnabled() end
---**Contexts:** UI
---
---*Action*
function Control:SetModal() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsModal() end
---**Contexts:** UI
---
---*Action*
function Control:SetTag() end
---**Contexts:** UI
---
---*Query*
function Control:GetTag() end
---**Contexts:** UI
---
---*Query*
function Control:CalculateVisibilityBox() end
---**Contexts:** UI
---
---*Action*
function Control:SetToolTipCallback() end
---**Contexts:** UI
---
---*Action*
function Control:ClearToolTipCallback() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:IsToolTipEnabled() end
---**Contexts:** UI
---
---*Action*
function Control:EnableToolTip() end
---**Contexts:** UI
---
---*Action*
function Control:SetToolTipType() end
---**Contexts:** UI
---
---*Action*
function Control:SetToolTipString() end
---**Contexts:** UI
---
---*Action*
function Control:LocalizeAndSetToolTip() end
---**Contexts:** UI
---
---*Query*
function Control:GetToolTipString() end
---**Contexts:** UI
---
---*Action*
function Control:ChangeParent() end
---**Contexts:** UI
---
---*Query*
function Control:GetParent() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentByType() end
---**Contexts:** UI
---
---*Query*
function Control:GetParentByID() end
---**Contexts:** UI
---
---*Action*
function Control:Reparent() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function Control:HasMouseOver() end
---**Contexts:** UI
---
---*Action*
function Control:DestroyChild() end
---**Contexts:** UI
---
---*Action*
function Control:ReleaseChild() end
---**Contexts:** UI
---
---*Action*
function Control:SetConsumeMouseOver() end
---**Contexts:** UI
---
---*Action*
function Control:SetConsumeMouseButton() end
---**Contexts:** UI
---
---*Action*
function Control:SetConsumeMouseWheel() end
---**Contexts:** UI
---
---*Query*
function Control:GetConsumeMouseOver() end
---**Contexts:** UI
---
---*Query*
function Control:GetConsumeMouseButton() end
---**Contexts:** UI
---
---*Query*
function Control:GetConsumeMouseWheel() end
---**Contexts:** UI
---
---*Action*
function Control:DestroyAllChildren() end
---**Contexts:** UI
---
---*Action*
function Control:RegisterMouseEnterCallback() end
---**Contexts:** UI
---
---*Action*
function Control:RegisterMouseExitCallback() end
---**Contexts:** UI
---
---*Action*
function Control:RegisterMouseOverCallback() end
---**Contexts:** UI
---
---*Action*
function Control:RegisterWhenShown() end
---**Contexts:** UI
---
---*Action*
function Control:RegisterWhenHidden() end
---**Contexts:** UI
---
---*Action*
function Control:ClearMouseEnterCallback() end
---**Contexts:** UI
---
---*Action*
function Control:ClearMouseExitCallback() end
---**Contexts:** UI
---
---*Action*
function Control:ClearMouseOverCallback() end

z_dontRef_types.Control = Control