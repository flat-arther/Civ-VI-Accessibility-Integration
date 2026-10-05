-- Native dropdown captures use text labels and ordinal CAI option values.
-- Extra fields (for example a native group ID) remain owned by the caller.
CAICapturedDropdown = {}

function CAICapturedDropdown.AddUniqueText(entries, text, limit)
    for index = 1, limit or #entries do
        if entries[index].text == text then return end
    end
    entries[#entries + 1] = { text = text }
end

function CAICapturedDropdown.FindSelection(entries, selectedText, previous)
    if selectedText then
        for index, entry in ipairs(entries) do
            if entry.text == selectedText then return index end
        end
    end
    return previous
end

---@param widget DropdownWidget|nil
function CAICapturedDropdown.Sync(widget, entries, selected)
    -- Captures arrive before the accessible panel has been created.
    if not widget then return end
    local options = {}
    for index, entry in ipairs(entries) do
        options[#options + 1] = { label = entry.text, value = index }
    end
    widget:SetOptions(options)
    widget:SetSelectedIndex(selected, true)
end
