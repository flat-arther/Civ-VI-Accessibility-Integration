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
    if not mgr or not titleFn or not actionButtons then
        LogWarn("DialogBuilder MakeGeneralDialog missing required inputs")
        return nil
    end

    local d = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlg"), "Dialog", {
        Label = titleFn,
    })
    if not d then
        LogError("DialogBuilder MakeGeneralDialog failed to create dialog widget")
        return nil
    end
    if contentRows then d:AddChildren(contentRows) end
    d:SetButtons(actionButtons, defaultActionIndex)
    LogMessage("DialogBuilder MakeGeneralDialog created dialog with contentRows="
        .. tostring(contentRows and #contentRows or 0)
        .. ", buttons=" .. tostring(#actionButtons))
    return d
end

---Wrap a vanilla `PopupDialog` instance: walks PopupControls, converts each
---into the matching CAI widget, and returns a Dialog ready to push.
---@param mgr UIScreenManager
---@param popup table
---@return DialogWidget|nil
function DB.CreatePopupDialog(mgr, popup)
    if not mgr or not popup then
        LogWarn("DialogBuilder CreatePopupDialog missing manager or popup")
        return nil
    end
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
            w:SetChecked(item.Control:IsChecked(), true)
            w:SetValueSetter(function() item.Control:DoLeftClick() end)
            w:SetFocusSound("Main_Menu_Mouse_Over")
        elseif kind == "EditBox" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgEdit"), "EditBox", {
                Label = function()
                    local val
                    for _, child in ipairs(item.Control:GetChildren()) do
                        if child:GetID() == "EditLabel" then
                            val = child; break
                        end
                    end
                    if not val then return "" end
                    return val:GetText() or ""
                end,
            })
            w:SetText(item.Control:GetText() or "", true)
            w:On("text_changed", function(w, text)
                item.Control:SetText(text)
            end)
            w:SetMaxCharacters(32) -- Tends to be the default for popupdialogs.
            w:SetAlwaysEdit(true)
            w:SetFocusSound("Main_Menu_Mouse_Over")
            w:SetEnterToCommit(false)
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
            w:SetFocusSound("Main_Menu_Mouse_Over")
        elseif kind == "Button" then
            w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIDlgBtn " .. item.Control:GetText()), "Button", {
                Label = function() return item.Control:GetText() or "" end,
                Tooltip = function() return item.Control:GetToolTipString() or "" end,
            })
            w:SetDisabledPredicate(function() return item.Control:IsDisabled() end)
            w:On("activate", function() item.Control:DoLeftClick() end)
            w:SetFocusSound("Main_Menu_Mouse_Over")
        else
            LogWarn("DialogBuilder CreatePopupDialog unsupported popup control type " .. tostring(kind))
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
    LogMessage("DialogBuilder CreatePopupDialog converted popup controls, content="
        .. tostring(#content) .. ", buttons=" .. tostring(#buttons))
    return DB.MakeGeneralDialog(mgr, titleFn, buttons, content, 1)
end

---Bind dialog builder methods onto `mgr.WidgetHelpers`. Called once during
---manager init; screens then reach builders via `mgr.WidgetHelpers.MakeGeneralDialog`
---etc., without having to thread the manager through every call.
---@param mgr UIScreenManager
function DB.Install(mgr)
    if not mgr then
        LogWarn("DialogBuilder Install called with nil manager")
        return
    end
    mgr.WidgetHelpers = mgr.WidgetHelpers or {}
    local WH = mgr.WidgetHelpers
    WH.MakeGeneralDialog = function(titleFn, actionButtons, contentRows, defaultActionIndex)
        return DB.MakeGeneralDialog(mgr, titleFn, actionButtons, contentRows, defaultActionIndex)
    end
    WH.CreatePopupDialog = function(popup)
        return DB.CreatePopupDialog(mgr, popup)
    end
    LogMessage("DialogBuilder installed on manager")
end
