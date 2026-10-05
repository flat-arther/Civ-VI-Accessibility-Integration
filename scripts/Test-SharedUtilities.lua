dofile("src/UI/shared/CAIControl.lua")
dofile("src/UI/shared/CAICollection.lua")
local assertions = 0
local function check(actual, expected, label)
    assertions = assertions + 1
    assert(actual == expected, label .. ": got " .. tostring(actual))
end
check(CAICollection.CountEntries(nil), 0, "missing collection")
check(CAICollection.CountEntries({}), 0, "empty collection")
check(CAICollection.CountEntries({ [2] = false, [9] = "a", named = 0 }), 3, "sparse dictionary")
local keys = CAICollection.Keys({ a = false, b = 1 })
table.sort(keys)
check(table.concat(keys, ","), "a,b", "collection keys")
check(#CAICollection.Keys(nil), 0, "missing collection keys")
check(CAICollection.Invert({ a = "b" }).b, "a", "inverted collection")
check(CAIControl.IsHidden(nil), false, "absent hidden state")
check(CAIControl.IsVisible(nil), false, "absent visibility")
check(CAIControl.IsDisabled(nil), false, "absent disabled state")
check(CAIControl.IsVisible({}), true, "control without visibility method")
check(CAIControl.IsDisabled({}), false, "control without disabled method")
check(CAIControl.ReadText(nil), nil, "absent text control")
check(CAIControl.ReadTooltip({}), nil, "non-tooltip control")
local control = {
    text = "", tooltip = "", hidden = false, disabled = false,
    GetText = function(self) return self.text end,
    GetToolTipString = function(self) return self.tooltip end,
    IsHidden = function(self) return self.hidden end,
    IsDisabled = function(self) return self.disabled end,
}
check(CAIControl.ReadText(control), nil, "empty text")
check(CAIControl.ReadTooltip(control), nil, "empty tooltip")
control.text, control.tooltip = " 张 ", "[ICON_Gold] 1,000"
check(CAIControl.ReadText(control), " 张 ", "live untrimmed text")
check(CAIControl.ReadTooltip(control), "[ICON_Gold] 1,000", "live markup")
control.hidden, control.disabled = true, true
check(CAIControl.IsHidden(control), true, "live hidden state")
check(CAIControl.IsVisible(control), false, "hidden visibility")
check(CAIControl.IsDisabled(control), true, "live disabled state")
control.GetText = function() error("broken native getter") end
check(pcall(CAIControl.ReadText, control), false, "getter failures propagate")
check(CAIControl.Text(nil), "", "text fallback")
check(CAIControl.Tooltip(nil), "", "tooltip fallback")
Locale = { Compare = function(a, b) return a == b and 0 or (a < b and -1 or 1) end }
check(CAICollection.CompareValues(nil, 1), 1, "missing values last")
check(CAICollection.CompareValues(10, 2), 1, "numeric order")
check(CAICollection.CompareValues("b", "a"), 1, "localized order")
check(CAICollection.CompareTypedValues(false, true), -1, "boolean order")
check(CAICollection.CompareTypedValues(true, true), 0, "boolean equality")
Locale.Lookup = function(tag) return tag end
local caption = { GetToolTipString = function() return "" end }
local value = { GetText = function() return 4 end }
check(CAIControl.TooltipWithValue(caption, value, "fallback", true), "fallback: 4", "tooltip fallback and numeric conversion")
check(CAIControl.TooltipWithValue(nil, value), "4", "optional tooltip")
check(pcall(CAIControl.TooltipWithValue, nil, value, nil, true), false, "required controls fail")
check(pcall(CAIControl.TooltipWithValue, {}, value), false, "required method fails")

for _, path in ipairs(arg) do
    local file = assert(io.open(path, "rb"))
    local source = file:read("a"); file:close()
    for _, kind in ipairs({ "table", "number", "string", "boolean", "ifunction" }) do
        source = source:gsub("([%w_]+)%s*:" .. kind .. "(%s*[,)=;])", "%1%2")
    end
    local chunk, message = load(source, "@" .. path)
    check(chunk ~= nil, true, "caller syntax: " .. tostring(message))
    for _, module in ipairs({ "CAIControl", "CAICollection" }) do
        if source:find(module .. ".", 1, true) then
            check(source:find('include("' .. module .. '")', 1, true) ~= nil, true, "explicit include " .. path)
        end
    end
end
print("Shared utilities: " .. assertions .. " assertions passed")
