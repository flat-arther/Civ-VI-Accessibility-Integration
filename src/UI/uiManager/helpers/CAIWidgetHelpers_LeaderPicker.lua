-- CAIWidgetHelpers_LeaderPicker.lua
-- A leader picker presented as a button instead of a dropdown. The button
-- speaks the same label/value/tooltip a leader dropdown would; activating it
-- pushes a transient panel holding a sort dropdown and a list of leaders. Each
-- leader row activates the selection (and closes the panel); F2 on a row speaks
-- that leader's accessibility description (same behaviour as the diplomacy
-- action view).
--
-- Screens reach this through the manager-bound helper installed by Install(mgr):
-- `mgr.WidgetHelpers.CreateLeaderPickerButton(config)`.
--
-- config fields:
--   id                string   button widget id
--   panelId           string   picker panel widget id (one panel open at a
--                              time per screen, so all buttons on a screen may
--                              share this id)
--   focusKey          string?  button focus key
--   label             fun():string   button label / panel title
--   tooltip           fun():string   button tooltip
--   getSelectedLabel  fun():string   spoken button value (selected leader)
--   getOptions        fun():LeaderOption[], integer   options + selected index
--   onSelect          fun(value)     commit the chosen leader value
--   hiddenPredicate   fun():boolean?
--   disabledPredicate fun():boolean?
--   focusSound        string?
--
-- Each LeaderOption is { label, tooltip, value, leaderName, civName, leaderType,
--   disabledPredicate? }. leaderName/civName drive the sort; leaderType keys the
-- F2 description lookup and the stable row focus key.

CAIWidgetHelpers_LeaderPicker = {}
local LP = CAIWidgetHelpers_LeaderPicker

-- Sort by leader name or civilization name, ascending or descending. Remembered
-- across opens within a session so the player's chosen order sticks.
local SORTS = {
    { field = "leader", asc = true,  fieldKey = "LOC_CAI_LABEL_LEADER",    dirKey = "LOC_CAI_SORT_A_TO_Z" },
    { field = "leader", asc = false, fieldKey = "LOC_CAI_LABEL_LEADER",    dirKey = "LOC_CAI_SORT_Z_TO_A" },
    { field = "civ",    asc = true,  fieldKey = "LOC_CAI_LABEL_CIV", dirKey = "LOC_CAI_SORT_A_TO_Z" },
    { field = "civ",    asc = false, fieldKey = "LOC_CAI_LABEL_CIV", dirKey = "LOC_CAI_SORT_Z_TO_A" },
}

-- The chosen sort persists across sessions through the CAI config store.
local SORT_SECTION = "LeaderPicker"
local SORT_KEY = "SortIndex"

local function LoadSortIndex()
    local stored = tonumber(CAI.GetConfigValue(SORT_SECTION, SORT_KEY, 1)) or 1
    if stored < 1 or stored > #SORTS then return 1 end
    return math.floor(stored)
end

local function SaveSortIndex(index)
    if not CAI.SetConfigValue(SORT_SECTION, SORT_KEY, index) then
        LogError("LeaderPicker failed to save sort index " .. tostring(index))
    end
end

local g_sortIndex = LoadSortIndex()

local function SpeakLeaderDescription(leaderType)
    -- Mirrors DiplomacyActionView: descriptions live in LeaderDescStrings_CAI.xml
    -- keyed by leader type; a missing tag Locale.Lookups back to itself.
    if leaderType and leaderType ~= "" then
        local tag = "LOC_CAI_LEADERDESC_" .. leaderType
        local desc = Locale.Lookup(tag)
        if desc ~= nil and desc ~= "" and desc ~= tag then
            Speak(desc)
            return
        end
    end
    Speak(Locale.Lookup("LOC_CAI_LEADERDESC_NONE"))
end

local function BuildSortOptions()
    local options = {}
    for i, s in ipairs(SORTS) do
        options[i] = {
            label = Locale.Lookup(s.fieldKey) .. "[NEWLINE]" .. Locale.Lookup(s.dirKey),
            value = i,
        }
    end
    return options
end

local function OptionSortKey(option, field)
    if field == "civ" then return option.civName or "" end
    return option.leaderName or ""
end

-- Random / random-pool entries stay pinned to the top of the list whatever the
-- sort, so the defaults are always reachable first.
local function IsRandomOption(option)
    local leaderType = option.leaderType or (type(option.value) == "table" and option.value.Value) or ""
    return type(leaderType) == "string" and leaderType:sub(1, 6) == "RANDOM"
end

---@param mgr UIScreenManager
---@param config table
---@return ButtonWidget
function LP.CreateLeaderPickerButton(mgr, config)
    local panelId = config.panelId

    local function OpenPicker()
        -- Guard against double-open (rapid activation) landing two panels.
        if mgr:GetWidgetById(panelId) then return end

        local panel = mgr:CreateWidget(panelId, "Panel", {
            Label = config.label,
        })
        local list

        local function RebuildList()
            local capture = mgr:CaptureFocusKey(list)
            list:ClearChildren()

            local options = select(1, config.getOptions())
            local sortDef = SORTS[g_sortIndex] or SORTS[1]
            local decorated = {}
            for i, opt in ipairs(options) do
                decorated[i] = { opt = opt, idx = i, random = IsRandomOption(opt) }
            end
            table.sort(decorated, function(a, b)
                -- Random options always sort ahead of real leaders, in natural order.
                if a.random ~= b.random then return a.random end
                if a.random then return a.idx < b.idx end
                local cmp = Locale.Compare(OptionSortKey(a.opt, sortDef.field), OptionSortKey(b.opt, sortDef.field))
                if cmp == 0 then return a.idx < b.idx end
                if sortDef.asc then return cmp == -1 end
                return cmp == 1
            end)

            for _, d in ipairs(decorated) do
                local opt = d.opt
                local leaderType = opt.leaderType or (type(opt.value) == "table" and opt.value.Value) or nil
                local row = mgr:CreateWidget(mgr:GenerateWidgetId(panelId .. "_Row"), "Button", {
                    Label = function() return opt.label or "" end,
                    Tooltip = function() return opt.tooltip or "" end,
                    FocusKey = panelId .. ":leader:" .. tostring(leaderType or d.idx),
                })
                if opt.disabledPredicate then row:SetDisabledPredicate(opt.disabledPredicate) end
                if config.focusSound then row:SetFocusSound(config.focusSound) end
                row:On("activate", function()
                    config.onSelect(opt.value)
                    mgr:RemoveFromStack(panelId)
                end)
                row:AddInputBindings({ {
                    Key = Keys.VK_F2,
                    MSG = KeyEvents.KeyUp,
                    Description = "LOC_CAI_KB_LEADER_DESCRIPTION",
                    Action = function()
                        SpeakLeaderDescription(leaderType)
                        return true
                    end,
                } })
                list:AddChild(row)
            end

            if capture then mgr:RestoreFocus(list, capture) end
        end

        local sort = mgr:CreateWidget(panelId .. "_Sort", "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_LABEL_SORT_BY") end,
            FocusKey = panelId .. ":sort",
        })
        sort:SetOptions(BuildSortOptions())
        sort:SetSelectedIndex(g_sortIndex, true)
        if config.focusSound then sort:SetFocusSound(config.focusSound) end
        sort:On("value_changed", function(_, value)
            g_sortIndex = value
            SaveSortIndex(value)
            RebuildList()
        end)

        list = mgr:CreateWidget(panelId .. "_List", "List", {
            Label = function() return Locale.Lookup("LOC_CAI_DIPLOMACY_LEADERS") end,
        })

        -- List first, sort dropdown second.
        panel:AddChild(list)
        panel:AddChild(sort)
        RebuildList()

        panel:AddInputBindings({ {
            Key = Keys.VK_ESCAPE,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                mgr:RemoveFromStack(panelId)
                return true
            end,
        } })

        -- Land on the currently selected leader when the list has one.
        local options, selectedIndex = config.getOptions()
        local focus = list
        local selected = options and selectedIndex and options[selectedIndex]
        local selectedType = selected and (selected.leaderType or (type(selected.value) == "table" and selected.value.Value))
        if selectedType then
            focus = panelId .. ":leader:" .. tostring(selectedType)
        end
        mgr:Push(panel, { focus = focus })
    end

    local button = mgr:CreateWidget(config.id, "Button", {
        Label = config.label,
        Tooltip = config.tooltip,
        HiddenPredicate = config.hiddenPredicate,
        DisabledPredicate = config.disabledPredicate,
        FocusKey = config.focusKey,
    })
    -- Speak the selected leader as the button's value, like a dropdown does.
    button:SetValueGetter(function()
        if config.getSelectedLabel then return config.getSelectedLabel() or "" end
        local options, selectedIndex = config.getOptions()
        local opt = options and selectedIndex and options[selectedIndex]
        return opt and opt.label or ""
    end)
    if config.focusSound then button:SetFocusSound(config.focusSound) end
    button:On("activate", OpenPicker)

    button.RemoveLeaderPicker = function()
        mgr:RemoveFromStack(panelId)
    end

    return button
end

---Remove any open leader picker panel for the given panel id. Screens call this
---from their own teardown so the transient picker never lingers over a closed
---parent screen.
---@param mgr UIScreenManager
---@param panelId string
function LP.RemovePanel(mgr, panelId)
    if mgr and panelId then
        mgr:RemoveFromStack(panelId)
    end
end

---Bind leader-picker methods onto `mgr.WidgetHelpers`.
---@param mgr UIScreenManager
function LP.Install(mgr)
    if not mgr then
        LogWarn("LeaderPicker Install called with nil manager")
        return
    end
    mgr.WidgetHelpers = mgr.WidgetHelpers or {}
    local WH = mgr.WidgetHelpers
    WH.CreateLeaderPickerButton = function(config)
        return LP.CreateLeaderPickerButton(mgr, config)
    end
    WH.RemoveLeaderPickerPanel = function(panelId)
        return LP.RemovePanel(mgr, panelId)
    end
    LogMessage("LeaderPicker installed on manager")
end
