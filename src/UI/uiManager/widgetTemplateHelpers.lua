---@ class WidgetTemplateHelpers
---@field Manager UIScreenManager
WidgetTemplateHelpers = {}

---Sets the text of an Edit widget, normalizing [NEWLINE] and \r\n into real newlines
---@param w UIWidget
---@param text string|nil
function WidgetTemplateHelpers:SetEditBoxText(w, text)
    if not w then return end
    text = text or ""
    text = string.gsub(text, "%[NEWLINE%]", "\n")
    text = string.gsub(text, "\r\n", "\n")
    w.EditBuffer = text
    w.EditCursor = 0
    w.EditSelStart = nil
    if w.EditActive then w.EditOriginal = text end
    if w.OnSetText then w:OnSetText(text) end
end

---Creates a popup dialog widget, given a PopupDialog instance
---@param popup table
---@return UIWidget|nil
function WidgetTemplateHelpers:CreatePopupDialog(popup)
    local mgr = self.Manager
    if not mgr or not popup then return end
    local dlgContent = {} -- array of dialog content widgets: text, checkboxes and edit boxes
local buttonRow = {} -- array of dialog action button widgets: The ok cancel buttons

for _, item in ipairs(popup.PopupControls) do
    local type = item.Type
    local w
    if type == "Text" then
        w = mgr:CreateUIWidget("StaticText", {
            GetLabel = function ()
            return item.Control:GetText()
        end
    })
    elseif type == "Check" then
        w = mgr:CreateUIWidget("Checkbox", {
            GetLabel = function()
                if item.Control.GetTextButton then
                    return item.Control:GetTextButton():GetText() or ""
                end
                return item.Control:GetText() or ""
            end,
            GetValue = function()
			return item.Control:IsChecked()
				and Locale.Lookup("LOC_OPTIONS_ENABLED")
				or Locale.Lookup("LOC_OPTIONS_DISABLED")
		end,
        Toggle = function()
            item.Callback()
        end,
        OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end
        })
    elseif type == "EditBox" then
        w = mgr:CreateUIWidget("Edit", {
            GetLabel = function()
                local p = item.Control:GetParent()
                if not p or not p.EditLabel then return "" end
                local text = p.EditLabel:GetText()
                return text or ""
            end,
            GetValue = function()
                return item.Control:GetText()
                end,
                OnSetText  = function(w, text)
                    item.Control:SetText(text)
                end,
                OnCommit   = function(w, text)
                    item.Control:SetText(text)
                    -- These don't really have callbacks, they rely on the ok button for commits
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end
        })
    elseif type == "Count" then
        w = mgr:CreateUIWidget("StaticText", {
            GetLabel = function()
                local p = item.Control:GetParent()
                if not p or not p.Text then return "" end
                local text = p.Text:GetText()
                return Locale.Lookup("LOC_CAI_DIALOG_COUNT", text) or ""
            end,
            OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end
        })
    elseif type == "Button" then
        w = mgr:CreateUIWidget("Button", {
            GetLabel = function()
                return item.Control:GetText() or ""
            end,
            GetTooltip = function()
            return item.Control:GetToolTipString() or ""
            end,
            IsDisabled = function()
                return item.Control:IsDisabled()
            end,
            OnClick = function() 
                    item.Callback() 
                end,
                OnFocusEnter = function()
                    UI.PlaySound("Main_Menu_Mouse_Over")
                end
        })
end
if w then
    w.SpeechSettings["Position"] = false
    if type ~= "Button" then
    table.insert(dlgContent, w)
    else
        table.insert(buttonRow, w)
    end
end
end
local function GetTitle() return popup.Controls.PopupTitle:GetText() end
local d = self:MakeGeneralDialog(GetTitle, buttonRow, dlgContent)
return d
end

---Creates a general dialog given a ui manager, a title function, and action button widgets
---@param titleFunc function
---@param actionButtons UIWidget[]
---@param dlgContent UIWidget[]
---@return UIWidget|nil
function WidgetTemplateHelpers:MakeGeneralDialog(titleFunc, actionButtons, dlgContent)
    local mgr = self.Manager
    if not mgr or not titleFunc or not actionButtons then return end
    local d = mgr:CreateUIWidget("Dialog", {
        DefaultIndex = 2,
        GetLabel = titleFunc,
    })
    d:AddInputBindings({
            { Key = Keys.VK_UP, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_DOWN, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end }
        })
    local buttonRow = mgr:CreateUIWidget("Panel", {
        WrapAround = false,
    SpeechSettings = {
        Position = false,
        Role = false
    },
    OnFocusLeave = function(w) w.FocusedChild = nil end, -- Need to clear the button row's focus when leaving it so that next time focus resets to the first action button
})
buttonRow:AddInputBindings({
            { Key = Keys.VK_LEFT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(-1) end },
            { Key = Keys.VK_RIGHT, MSG = KeyEvents.KeyDown, Action = function(w) return w:Navigate(1) end },
    })
-- if there are any extra controls, make sure they are added before the action buttons
if dlgContent and #dlgContent > 0 then
    d:AddChildren(dlgContent)
end
buttonRow:AddChildren(actionButtons)
d:AddChild(buttonRow)
return d
end
