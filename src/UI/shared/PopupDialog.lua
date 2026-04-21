include("PopupDialog_Base")
include ("caiUtils")
local DialogWidget = nil ---@type UIWidget|nil
local mgr = ExposedMembers.CAI_UIManager
PopupDialog.Open = WrapFunc(PopupDialog.Open, function(orig, self, optionalID)
    orig(self, optionalID)
	if ContextPtr:IsHidden() then return end
    DialogWidget = nil
        DialogWidget = mgr.WidgetTemplateHelpers:CreatePopupDialog(self)
		if not DialogWidget then return end
    if not mgr:HasWidget(DialogWidget) then
        mgr:Push(DialogWidget)
    end
end)


PopupDialog.Close = WrapFunc(PopupDialog.Close, function(orig, self)
    orig(self)
    if mgr:GetTop() == DialogWidget then
        mgr:Pop()
    end
end)
