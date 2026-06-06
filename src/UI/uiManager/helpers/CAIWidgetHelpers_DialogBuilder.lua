-- CAIWidgetHelpers_DialogBuilder.lua
-- Dialog scaffolds: a generic dialog assembler and a vanilla-PopupDialog
-- wrapper. Both produce widgets ready to push onto the manager stack.
--
-- Functions take the owning manager as their first parameter. Screens should
-- not call these directly; use the manager-bound versions installed on
-- `mgr.WidgetHelpers` by Install(mgr).

CAIWidgetHelpers_DialogBuilder = {}
local DB = CAIWidgetHelpers_DialogBuilder

---Build a Dialog with optional content rows + a horizontal action button row.
---Dialog and button-row navigation are handled by DialogWidget; this helper
---is now a thin convenience for assembling rows + buttons in one call.
---
---@param mgr UIScreenManager
---@param titleFn fun():string
---@param actionButtons ButtonWidget[]
---@param contentRows? UIWidget[]
---@param defaultActionIndex? integer 1-based; clamped to button-row size
---@return DialogWidget|nil
function DB.MakeGeneralDialog(mgr, titleFn, actionButtons, contentRows, defaultActionIndex)
    if not mgr or not titleFn or not actionButtons then return nil end

    local d = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlg"), "Dialog", {
        Label = titleFn,
    })
    if contentRows then d:AddChildren(contentRows) end
    d:SetButtons(actionButtons, defaultActionIndex)
    return d
end

---Wrap a vanilla `PopupDialog` instance: walks PopupControls, converts each
---into the matching CAI widget, and returns a Dialog ready to push.
---@param mgr UIScreenManager
---@param popup table
---@return DialogWidget|nil
function DB.CreatePopupDialog(mgr, popup)
    if not mgr or not popup then return nil end
    local content, buttons = {}, {}

    for _, item in ipairs(popup.PopupControls) do
        local kind = item.Type
        local w
        if kind == "Text" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgText"), "StaticText", {
                Label = function() return item.Control:GetText() end,
            })
        elseif kind == "Check" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgCheck"), "Checkbox", {
                Label = function()
                    if item.Control.GetTextButton then
                        return item.Control:GetTextButton():GetText() or ""
                    end
                    return item.Control:GetText() or ""
                end,
            })
            w:SetValueGetter(function() return item.Control:IsChecked() end)
            w:On("value_changed", function() item.Callback() end)
            w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
        elseif kind == "EditBox" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgEdit"), "EditBox", {
                Label = function()
                    local p = item.Control:GetParent()
                    if not p or not p.EditLabel then return "" end
                    return p.EditLabel:GetText() or ""
                end,
            })
            w:SetText(item.Control:GetText() or "", true)
            w:SetValueSetter(function(_, text) item.Control:SetText(text) end)
            w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
        elseif kind == "Count" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgCount"), "StaticText", {
                Label = function()
                    local val
                    for _, child in ipairs(item.Control:GetChildren()) do
                        if child:GetID() == "Text" then
                            val = child; break
                        end
                    end
                    if not val then return "" end
                    return Locale.Lookup("LOC_CAI_DIALOG_COUNT", val:GetText()) or ""
                end,
            })
            w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
        elseif kind == "Button" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgBtn"), "Button", {
                Label = function() return item.Control:GetText() or "" end,
                Tooltip = function() return item.Control:GetToolTipString() or "" end,
            })
            w:SetDisabledPredicate(function() return item.Control:IsDisabled() end)
            w:On("activate", function() item.Control:DoLeftClick() end)
            w:On("focus_enter", function() UI.PlaySound("Main_Menu_Mouse_Over") end)
        end

        if w then
            w.SpeechSettings = w.SpeechSettings or {}
            w.SpeechSettings.Position = false
            if kind == "Button" then
                table.insert(buttons, w)
            else
                table.insert(content, w)
            end
        end
    end

    local titleFn = function() return popup.Controls.PopupTitle:GetText() end
    return DB.MakeGeneralDialog(mgr, titleFn, buttons, content)
end

---Bind dialog builder methods onto `mgr.WidgetHelpers`. Called once during
---manager init; screens then reach builders via `mgr.WidgetHelpers.MakeGeneralDialog`
---etc., without having to thread the manager through every call.
---@param mgr UIScreenManager
function DB.Install(mgr)
    if not mgr then return end
    mgr.WidgetHelpers = mgr.WidgetHelpers or {}
    local WH = mgr.WidgetHelpers
    WH.MakeGeneralDialog = function(titleFn, actionButtons, contentRows, defaultActionIndex)
        return DB.MakeGeneralDialog(mgr, titleFn, actionButtons, contentRows, defaultActionIndex)
    end
    WH.CreatePopupDialog = function(popup)
        return DB.CreatePopupDialog(mgr, popup)
    end
end
