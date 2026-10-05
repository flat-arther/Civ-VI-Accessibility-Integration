include("CAIColumns")
-- Owns the accessible unit browser and the sorting used by world unit cycling.
-- UnitPanel supplies context-local reads and owns engine/Lua event subscriptions.
include("inGameHelpers_CAI")

CAIUnitBrowser = {}

---@class CAIUnitBrowserDependencies
---@field Manager UIScreenManager
---@field Cursor table
---@field GetSelectedUnit fun():table|nil
---@field GetParkCharges fun(unit:table):number|nil
---@field GetSummary fun(record:table):table
---@field GetActivitySortRank fun(unit:table):number
---@field CountAdjacentEnemies fun(unit:table|nil):number
---@field ScenarioChargeKeys table|nil

---@class CAIUnitBrowserInstance
---@field Open fun()
---@field Close fun()
---@field Cycle fun(direction:number, readyOnly:boolean)
---@field OnCursorMoved fun()
---@field OnUnitsChanged fun(playerID:number)
---@field OnUnitStateChanged fun(playerID:number|nil)

---@param dependencies CAIUnitBrowserDependencies
---@return CAIUnitBrowserInstance
function CAIUnitBrowser.Create(dependencies)
    local mgr = dependencies.Manager
    local CAICursor = dependencies.Cursor
    local GetSelectedUnit = dependencies.GetSelectedUnit
    local GetParkCharges = dependencies.GetParkCharges
    local g_PropertyKeys = dependencies.ScenarioChargeKeys
    local UNIT_LIST_ID = "CAIUnitPanelUnitList"
    local UnitList = nil
    local CAIUnitList

    local function RemoveUnitList()
        if UnitList and mgr then
            mgr:RemoveFromStack(UNIT_LIST_ID)
        end
        UnitList = nil
        if CAIUnitList ~= nil then
            CAIUnitList.Panel = nil
            CAIUnitList.Table = nil
            CAIUnitList.List = nil
            CAIUnitList.FilterDropdown = nil
            CAIUnitList.SortDropdown = nil
            CAIUnitList.SwitchButton = nil
            CAIUnitList.Records = {}
            CAIUnitList.LastRecord = nil
        end
    end

    local function BindCivilopediaShortcut(item, getUnitID)
        item:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsShift = true,
            Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
            Action = function()
                local unitID = getUnitID()
                local resolved = Players[Game.GetLocalPlayer()]:GetUnits():FindID(unitID)
                if resolved == nil then
                    return true
                end

                local unitInfo = GameInfo.Units[resolved:GetUnitType()]
                if unitInfo ~= nil then
                    RemoveUnitList()
                    LuaEvents.OpenCivilopedia(unitInfo.UnitType)
                end
                return true
            end,
        })
    end

    local function GetUnitListName(unit)
        if unit == nil then
            return nil
        end

        local unitName = unit:GetName()
        local localizedName = unitName ~= nil and unitName ~= "" and Locale.Lookup(unitName) or nil
        if localizedName == nil or localizedName == "" then
            local unitInfo = GameInfo.Units[unit:GetUnitType()]
            if unitInfo ~= nil and unitInfo.Name ~= nil and unitInfo.Name ~= "" then
                localizedName = Locale.Lookup(unitInfo.Name)
            end
        end

        local formatted = FormatOwnedName(nil, localizedName, GetUnitFormationSuffix(unit))
        return GetNumberedUnitName(unit, formatted)
    end

    CAIUnitList = {
        ViewMode = "table",
        FilterKey = "all",
        -- Distance is the default so world unit cycling starts from nearest-first.
        -- Sort state lives on this private instance table and is intentionally never
        -- reset on close, so the player's chosen sort is remembered.
        SortColumn = "distance",
        SortAscending = true,
        LastRecord = nil,
        Records = {},
        Columns = {},
        FilterDefinitions = {
            { Key = "all",      Label = "LOC_CAI_UNIT_CAT_ALL" },
            { Key = "military", Label = "LOC_CAI_UNIT_DOMAIN_MILITARY" },
            { Key = "naval",    Label = "LOC_CAI_UNIT_DOMAIN_NAVAL" },
            { Key = "air",      Label = "LOC_CAI_UNIT_DOMAIN_AIR" },
            { Key = "support",  Label = "LOC_CAI_UNIT_DOMAIN_SUPPORT" },
            { Key = "civilian", Label = "LOC_CAI_UNIT_DOMAIN_CIVILIAN" },
            { Key = "trade",    Label = "LOC_CAI_UNIT_DOMAIN_TRADE" },
        },
    }

    -- Record build/resolve/categorize and select+jump activation are shared with the
    -- Better Report Screen Units tab via inGameHelpers_CAI; these delegate so there is
    -- one implementation. Activation passes RemoveUnitList as the teardown so the
    -- Ctrl+U list closes before the map selection/jump (the report passes its own).
    function CAIUnitList.RecordKey(record)
        return UnitRecordFocusKey(record.PlayerID, record.UnitID)
    end

    function CAIUnitList.Resolve(record)
        return ResolveUnitRecord(record)
    end

    function CAIUnitList.GetCategory(unit)
        return CategorizeUnit(unit)
    end

    function CAIUnitList.BuildRecords()
        return BuildLocalUnitRecords()
    end

    function CAIUnitList.GetFilteredRecords()
        local records = {}
        for _, record in ipairs(CAIUnitList.Records) do
            local unit = CAIUnitList.Resolve(record)
            if unit ~= nil and (CAIUnitList.FilterKey == "all"
                or CAIUnitList.GetCategory(unit) == CAIUnitList.FilterKey) then
                records[#records + 1] = record
            end
        end
        return records
    end

    function CAIUnitList.GetName(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and GetUnitListName(unit) or ""
    end

    function CAIUnitList.GetSelectedState(record)
        local unit = CAIUnitList.Resolve(record)
        local selected = GetSelectedUnit()
        if unit ~= nil and selected ~= nil
            and selected:GetOwner() == unit:GetOwner()
            and selected:GetID() == unit:GetID() then
            return Locale.Lookup("LOC_CAI_STATE_SELECTED")
        end
        return ""
    end

    function CAIUnitList.GetDirection(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil or CAICursor == nil then return "" end
        local cursorX, cursorY = CAICursor:GetCoords()
        if cursorX == nil or cursorY == nil then return "" end
        return CAIHexCoordUtils.directionString(cursorX, cursorY, unit:GetX(), unit:GetY())
    end

    function CAIUnitList.GetDistance(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil then return nil end
        -- The panel measures from the cursor. Unit cycling temporarily overrides the
        -- origin (CAIUnitList.DistanceOrigin) with a fixed anchor so its ordering is
        -- stable while the selection/cursor moves; see OnCAICycleSelectedUnit.
        local originX, originY
        if CAIUnitList.DistanceOrigin ~= nil then
            originX, originY = CAIUnitList.DistanceOrigin.X, CAIUnitList.DistanceOrigin.Y
        elseif CAICursor ~= nil then
            originX, originY = CAICursor:GetCoords()
        end
        if originX == nil or originY == nil then return nil end
        return Map.GetPlotDistance(originX, originY, unit:GetX(), unit:GetY())
    end

    function CAIUnitList.GetActivity(record)
        local unit = CAIUnitList.Resolve(record)
        local status = CAI_GetUnitActivityStatus(unit)
        return status or ""
    end

    function CAIUnitList.GetActivityStatusOrder(status)
        if CAIUnitList.ActivityStatusOrder == nil then
            local labels = {
                Locale.Lookup("LOC_CAI_UNIT_EMBARKED"),
                Locale.Lookup("LOC_UNITCOMMAND_AUTOMATE_DESCRIPTION"),
                Locale.Lookup("LOC_UNITFLAG_ACTIVITY_HEALING"),
                Locale.Lookup("LOC_CAI_WORLDTRACKER_UNIT_SLEEP"),
                Locale.Lookup("LOC_UNITOPERATION_SKIP_TURN_DESCRIPTION"),
                Locale.Lookup("LOC_CAI_WORLDTRACKER_UNIT_FORTIFIED"),
                Locale.Lookup("LOC_CAI_UNIT_ACTIVITY_MOVING"),
                Locale.Lookup("LOC_READY_BUTTON"),
                Locale.Lookup("LOC_NOT_READY"),
            }
            table.sort(labels, function(a, b) return Locale.Compare(a, b) < 0 end)
            CAIUnitList.ActivityStatusOrder = {}
            for index, label in ipairs(labels) do
                if CAIUnitList.ActivityStatusOrder[label] == nil then
                    CAIUnitList.ActivityStatusOrder[label] = index
                end
            end
        end
        return CAIUnitList.ActivityStatusOrder[status] or 99
    end

    function CAIUnitList.GetActivitySortKey(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil then return nil end
        local status = CAI_GetUnitActivityStatus(unit)
        local rank = dependencies.GetActivitySortRank(unit)
        return rank * 100 + CAIUnitList.GetActivityStatusOrder(status)
    end

    function CAIUnitList.GetHealth(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil then return nil end
        local maximum = unit:GetMaxDamage()
        if maximum == nil or maximum <= 0 then return 0 end
        return maximum - (unit:GetDamage() or 0)
    end

    function CAIUnitList.GetCurrentMoves(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and unit:GetMovementMovesRemaining() or nil
    end

    function CAIUnitList.GetMaxMoves(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and unit:GetMaxMoves() or nil
    end

    function CAIUnitList.GetMeleeStrength(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetCombat() or 0) or nil
    end

    function CAIUnitList.GetRangedStrength(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetRangedCombat() or 0) or nil
    end

    function CAIUnitList.GetBombardStrength(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetBombardCombat() or 0) or nil
    end

    function CAIUnitList.GetReligiousStrength(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetReligiousStrength() or 0) or nil
    end

    function CAIUnitList.GetAntiAirStrength(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetAntiAirCombat() or 0) or nil
    end

    function CAIUnitList.GetRange(record)
        local unit = CAIUnitList.Resolve(record)
        return unit ~= nil and (unit:GetRange() or 0) or nil
    end

    function CAIUnitList.GetChargeCount(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil then return nil end
        local greatPerson = unit:GetGreatPerson()
        local count = math.max(unit:GetBuildCharges() or 0, unit:GetDisasterCharges() or 0,
            unit:GetSpreadCharges() or 0, unit:GetReligiousHealCharges() or 0,
            unit:GetActionCharges() or 0,
            greatPerson ~= nil and (greatPerson:GetActionCharges() or 0) or 0,
            GetParkCharges(unit) or 0)
        if GameConfiguration.GetRuleSet() == "RULESET_SCENARIO_BLACKDEATH"
            and g_PropertyKeys ~= nil and g_PropertyKeys.Charges ~= nil and g_PropertyKeys.MaxCharges ~= nil then
            local usedCharges = unit:GetProperty(g_PropertyKeys.Charges)
            local maxCharges = unit:GetProperty(g_PropertyKeys.MaxCharges)
            if usedCharges ~= nil and maxCharges ~= nil then count = math.max(count, maxCharges - usedCharges) end
        end
        return math.max(0, count)
    end

    function CAIUnitList.GetPromotionCount(record)
        local unit = CAIUnitList.Resolve(record)
        local experience = unit ~= nil and unit:GetExperience() or nil
        local promotions = experience ~= nil and experience:GetPromotions() or nil
        return promotions ~= nil and #promotions or 0
    end

    function CAIUnitList.GetAdjacentEnemies(record)
        return dependencies.CountAdjacentEnemies(CAIUnitList.Resolve(record))
    end

    function CAIUnitList.GetTooltip(record)
        local unit = CAIUnitList.Resolve(record)
        if unit == nil then
            LogWarn("CAI UnitPanel unit list could not resolve unit " .. tostring(record.UnitID))
            return ""
        end
        local parts = {}
        local direction = CAIUnitList.GetDirection(record)
        CAIText.AppendIfNonEmpty(parts, direction)
        local summary = dependencies.GetSummary(record)
        for summaryIndex, summaryPart in ipairs(summary) do
            if summaryIndex > 1 then parts[#parts + 1] = summaryPart end
        end
        return table.concat(parts, "[NEWLINE]")
    end

    function CAIUnitList.ActivateRecord(record)
        return SelectUnitRecord(record, RemoveUnitList)
    end

    function CAIUnitList.JumpToRecord(record)
        return JumpToUnitRecord(record)
    end

    function CAIUnitList.OpenCivilopedia(record)
        return OpenUnitRecordCivilopedia(record, RemoveUnitList)
    end

    function CAIUnitList.BuildColumns()
        local columns = {
            {
                key = "name",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_NAME") end,
                getCell = CAIUnitList.GetName,
                sortKey = CAIUnitList.GetName,
                sortAscendingDescription = "LOC_CAI_SORT_A_TO_Z",
                sortDescendingDescription = "LOC_CAI_SORT_Z_TO_A",
            },
            {
                key = "distance",
                header = function() return Locale.Lookup("LOC_CAI_REPORTS_DISTANCE") end,
                getCell = CAIUnitList.GetDirection,
                getTooltip = function(record)
                    local distance = CAIUnitList.GetDistance(record)
                    return distance ~= nil and Locale.Lookup("LOC_CAI_WORLD_SCANNER_DISTANCE", distance) or ""
                end,
                sortKey = CAIUnitList.GetDistance,
                sortAscendingDescription = "LOC_CAI_SORT_NEAREST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_FARTHEST_FIRST",
            },
            {
                key = "activity",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_ACTIVITY") end,
                getCell = CAIUnitList.GetActivity,
                sortKey = CAIUnitList.GetActivitySortKey,
                sortAscendingDescription = "LOC_CAI_SORT_READY_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_NOT_READY_FIRST",
            },
            {
                key = "health",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_HEALTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetHealth(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetHealth,
                sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            },
            {
                key = "current_moves",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_CURRENT_MOVES") end,
                getCell = function(record)
                    local value = CAIUnitList.GetCurrentMoves(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetCurrentMoves,
                sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            },
            {
                key = "max_moves",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_MAX_MOVES") end,
                getCell = function(record)
                    local value = CAIUnitList.GetMaxMoves(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetMaxMoves,
                sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            },
            -- Civ V Access's Military Overview keeps combat and ranged strength
            -- in independent raw-number columns. Civ VI exposes three additional
            -- native strength types, so each gets the same independent treatment;
            -- never combine these values into a sum or highest-strength proxy.
            {
                key = "melee_strength",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_STRENGTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetMeleeStrength(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetMeleeStrength,
                sortAscendingDescription = "LOC_CAI_SORT_WEAKEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_STRONGEST_FIRST",
            },
            {
                key = "ranged_strength",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_RANGED_STRENGTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetRangedStrength(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetRangedStrength,
                sortAscendingDescription = "LOC_CAI_SORT_WEAKEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_STRONGEST_FIRST",
            },
            {
                key = "bombard_strength",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_BOMBARD_STRENGTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetBombardStrength(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetBombardStrength,
                sortAscendingDescription = "LOC_CAI_SORT_WEAKEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_STRONGEST_FIRST",
            },
            {
                key = "religious_strength",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_RELIGIOUS_STRENGTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetReligiousStrength(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetReligiousStrength,
                sortAscendingDescription = "LOC_CAI_SORT_WEAKEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_STRONGEST_FIRST",
            },
            {
                key = "anti_air_strength",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_ANTI_AIR_STRENGTH") end,
                getCell = function(record)
                    local value = CAIUnitList.GetAntiAirStrength(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetAntiAirStrength,
                sortAscendingDescription = "LOC_CAI_SORT_WEAKEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_STRONGEST_FIRST",
            },
            {
                key = "range",
                header = function() return Locale.Lookup("LOC_CAI_ICON_RANGE_ALIAS") end,
                getCell = function(record)
                    local value = CAIUnitList.GetRange(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetRange,
                sortAscendingDescription = "LOC_CAI_SORT_LOWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_HIGHEST_FIRST",
            },
            {
                key = "charges",
                header = function() return Locale.Lookup("LOC_HUD_UNIT_PANEL_CHARGES") end,
                getCell = function(record)
                    local value = CAIUnitList.GetChargeCount(record)
                    return value ~= nil and tostring(value) or ""
                end,
                sortKey = CAIUnitList.GetChargeCount,
                sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
            },
            {
                key = "promotions",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_PROMOTIONS") end,
                getCell = function(record) return tostring(CAIUnitList.GetPromotionCount(record)) end,
                sortKey = CAIUnitList.GetPromotionCount,
                sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
            },
            {
                key = "adjacent_enemies",
                header = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_COLUMN_ADJACENT_ENEMIES") end,
                getCell = function(record) return tostring(CAIUnitList.GetAdjacentEnemies(record)) end,
                sortKey = CAIUnitList.GetAdjacentEnemies,
                sortAscendingDescription = "LOC_CAI_SORT_FEWEST_FIRST",
                sortDescendingDescription = "LOC_CAI_SORT_MOST_FIRST",
            },
        }
        return columns
    end

    function CAIUnitList.GetColumn(columnKey)
        return CAIColumns.Find(CAIUnitList.Columns, columnKey)
    end

    -- World unit cycling reads the sorted list even when the panel was never
    -- opened, so the columns (which own the sort keys) must be available on demand.
    function CAIUnitList.EnsureColumns()
        if CAIUnitList.Columns == nil or #CAIUnitList.Columns == 0 then
            CAIUnitList.Columns = CAIUnitList.BuildColumns()
        end
    end

    -- Returns the local player's units in the current sort order. When readyOnly is
    -- true the pool is limited to units awaiting orders (comma/period); otherwise it
    -- includes every unit (shift+comma/period). The panel's category filter is not
    -- applied here; that filter is a panel-only view setting.
    function CAIUnitList.GetSortedUnits(readyOnly, sortColumn, sortAscending)
        CAIUnitList.EnsureColumns()
        local units = {}
        for _, record in ipairs(CAIUnitList.SortRecords(CAIUnitList.BuildRecords(), sortColumn, sortAscending)) do
            local unit = CAIUnitList.Resolve(record)
            if unit ~= nil and (not readyOnly or unit:IsReadyToMove()) then
                units[#units + 1] = unit
            end
        end
        return units
    end

    -- sortColumn/sortAscending default to the panel's remembered sort. World unit
    -- cycling passes an override when the follow-panel-sort setting is off.
    function CAIUnitList.SortRecords(records, sortColumn, sortAscending)
        if sortColumn == nil then sortColumn = CAIUnitList.SortColumn end
        if sortAscending == nil then sortAscending = CAIUnitList.SortAscending end
        local column = CAIUnitList.GetColumn(sortColumn)
        if column == nil or column.sortKey == nil then return records end
        local decorated = {}
        for naturalIndex, record in ipairs(records) do
            decorated[#decorated + 1] = {
                Record = record,
                NaturalIndex = naturalIndex,
                Value = column.sortKey(record),
            }
        end
        table.sort(decorated, function(a, b)
            local aValue = a.Value
            local bValue = b.Value
            if aValue == nil or bValue == nil then
                if aValue == bValue then return a.NaturalIndex < b.NaturalIndex end
                return aValue ~= nil
            end
            local comparison = 0
            if type(aValue) == "number" and type(bValue) == "number" then
                comparison = aValue == bValue and 0 or (aValue < bValue and -1 or 1)
            else
                comparison = Locale.Compare(tostring(aValue), tostring(bValue))
            end
            if comparison == 0 then return a.NaturalIndex < b.NaturalIndex end
            if sortAscending then return comparison < 0 end
            return comparison > 0
        end)
        for index, entry in ipairs(decorated) do records[index] = entry.Record end
        return records
    end

    function CAIUnitList.CreateListItem(record)
        local item = mgr:CreateWidget(mgr:GenerateWidgetId("CAIUnitListItem"), "MenuItem", {
            FocusKey = CAIUnitList.RecordKey(record),
            Label = function() return CAIUnitList.GetName(record) end,
            Tooltip = function() return CAIUnitList.GetTooltip(record) end,
            StateGetter = function() return CAIUnitList.GetSelectedState(record) end,
        })
        item.UnitListRecord = record
        item:On("focus_enter", function() CAIUnitList.LastRecord = record end)
        item:On("activate", function() return CAIUnitList.ActivateRecord(record) end)
        item:AddInputBinding({
            Key = Keys.VK_RETURN,
            IsControl = true,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_JUMP_CURSOR_TO_UNIT",
            Action = function() return CAIUnitList.JumpToRecord(record) end,
        })
        BindCivilopediaShortcut(item, function() return record.UnitID end)
        return item
    end

    function CAIUnitList.RebuildList()
        if CAIUnitList.List == nil then return end
        local capture = mgr:CaptureFocusKey(CAIUnitList.List)
        CAIUnitList.List:ClearChildren()
        for _, record in ipairs(CAIUnitList.SortRecords(CAIUnitList.GetFilteredRecords())) do
            CAIUnitList.List:AddChild(CAIUnitList.CreateListItem(record))
        end
        mgr:RestoreFocus(CAIUnitList.List, capture)
    end

    function CAIUnitList.RebuildViews(rebuildRecords)
        if UnitList == nil then return end
        if rebuildRecords then
            CAIUnitList.Records = CAIUnitList.BuildRecords()
            if #CAIUnitList.Records == 0 then
                RemoveUnitList()
                Speak(Locale.Lookup("LOC_CAI_UNIT_NO_UNITS"))
                return
            end
        end
        if CAIUnitList.ViewMode == "table" then
            if CAIUnitList.Table ~= nil then CAIUnitList.Table:Rebuild() end
        else
            CAIUnitList.RebuildList()
        end
    end

    function CAIUnitList.GetFocusedRecord()
        if CAIUnitList.ViewMode == "table" and CAIUnitList.Table ~= nil then
            return CAIUnitList.Table:GetFocusedRow() or CAIUnitList.LastRecord
        end
        local focused = mgr:GetFocusedWidget()
        return focused ~= nil and focused.UnitListRecord or CAIUnitList.LastRecord
    end

    function CAIUnitList.SetViewMode(viewMode)
        if viewMode ~= "table" and viewMode ~= "list" then return false end
        local record = CAIUnitList.GetFocusedRecord()
        CAIUnitList.ViewMode = viewMode
        local target = viewMode == "table" and CAIUnitList.Table or CAIUnitList.List
        if target == nil then return false end
        if viewMode == "table" then
            CAIUnitList.Table:Rebuild()
        else
            CAIUnitList.RebuildList()
        end
        if record ~= nil then
            local focusKey = viewMode == "table"
                and (tostring(CAIUnitList.Table.Id) .. ":row:" .. CAIUnitList.RecordKey(record) .. ":name")
                or CAIUnitList.RecordKey(record)
            mgr:PrepareFocus(target, focusKey)
        end
        mgr:SetFocus(target)
        return true
    end

    function CAIUnitList.BuildFilterOptions()
        local options = {}
        for _, definition in ipairs(CAIUnitList.FilterDefinitions) do
            options[#options + 1] = { label = Locale.Lookup(definition.Label), value = definition.Key }
        end
        return options
    end

    function CAIUnitList.GetFilterLabel()
        for _, definition in ipairs(CAIUnitList.FilterDefinitions) do
            if definition.Key == CAIUnitList.FilterKey then
                return Locale.Lookup(definition.Label)
            end
        end
        return Locale.Lookup("LOC_CAI_UNIT_CAT_ALL")
    end

    function CAIUnitList.SyncSortDropdown()
        if CAIUnitList.SortDropdown == nil then return end
        for index, option in ipairs(CAIUnitList.SortOptions or {}) do
            local value = option.value
            if value.column == CAIUnitList.SortColumn
                and (value.column == nil or value.ascending == CAIUnitList.SortAscending) then
                CAIUnitList.SortDropdown:SetSelectedIndex(index, true)
                return
            end
        end
    end

    function CAIUnitList.BuildPanel()
        local playerID = Game.GetLocalPlayer()
        if playerID == nil or playerID < 0 or Players[playerID] == nil then return nil end
        CAIUnitList.Records = CAIUnitList.BuildRecords()
        if #CAIUnitList.Records == 0 then return nil end

        CAIUnitList.ViewMode = "table"
        CAIUnitList.LastRecord = nil
        CAIUnitList.Columns = CAIUnitList.BuildColumns()
        if CAIUnitList.GetColumn(CAIUnitList.SortColumn) == nil then
            CAIUnitList.SortColumn = "distance"
            CAIUnitList.SortAscending = true
        end
        local panel = mgr:CreateWidget(UNIT_LIST_ID, "Panel", {
            Label = function() return Locale.Lookup("LOC_TECH_FILTER_UNITS") end,
        })
        CAIUnitList.Panel = panel

        CAIUnitList.Table = mgr:CreateWidget(UNIT_LIST_ID .. "_Table", "DataTable", {
            Label = CAIUnitList.GetFilterLabel,
            HiddenPredicate = function() return CAIUnitList.ViewMode ~= "table" end,
        })
        CAIUnitList.Table:SetColumns(CAIUnitList.Columns)
        CAIUnitList.Table:SetRowsProvider(CAIUnitList.GetFilteredRecords)
        CAIUnitList.Table:SetRowKeyGetter(CAIUnitList.RecordKey)
        CAIUnitList.Table:SetRowLabelGetter(CAIUnitList.GetName)
        CAIUnitList.Table:SetDefaultSort(CAIUnitList.SortColumn ~= nil
            and { column = CAIUnitList.SortColumn, ascending = CAIUnitList.SortAscending }
            or nil)
        CAIUnitList.Table:On("row_activate", function(_, record) return CAIUnitList.ActivateRecord(record) end)
        CAIUnitList.Table:On("row_focus_enter", function(_, record)
            if record ~= nil then CAIUnitList.LastRecord = record end
        end)
        CAIUnitList.Table:On("sort_changed", function(_, columnKey, ascending)
            CAIUnitList.SortColumn = columnKey
            CAIUnitList.SortAscending = ascending == true
            CAIUnitList.SyncSortDropdown()
        end)
        CAIUnitList.Table:AddInputBindings({
            {
                Key = Keys.VK_RETURN,
                IsControl = true,
                MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_JUMP_CURSOR_TO_UNIT",
                Action = function(w)
                    local record = w:GetFocusedRow()
                    return record ~= nil and CAIUnitList.JumpToRecord(record) or false
                end,
            },
            {
                Key = Keys.VK_RETURN,
                IsShift = true,
                MSG = KeyEvents.KeyUp,
                Description = "LOC_CAI_KB_OPEN_CIVILOPEDIA",
                Action = function(w)
                    local record = w:GetFocusedRow()
                    return record ~= nil and CAIUnitList.OpenCivilopedia(record) or false
                end,
            },
        })
        CAIUnitList.Table:Rebuild()
        panel:AddChild(CAIUnitList.Table)

        CAIUnitList.List = mgr:CreateWidget(UNIT_LIST_ID .. "_List", "List", {
            Label = CAIUnitList.GetFilterLabel,
            HiddenPredicate = function() return CAIUnitList.ViewMode ~= "list" end,
        })
        panel:AddChild(CAIUnitList.List)

        CAIUnitList.FilterDropdown = mgr:CreateWidget(UNIT_LIST_ID .. "_Filter", "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_FILTER") end,
            FocusKey = "unit:list:filter",
        })
        local filterOptions = CAIUnitList.BuildFilterOptions()
        CAIUnitList.FilterDropdown:SetOptions(filterOptions)
        for index, option in ipairs(filterOptions) do
            if option.value == CAIUnitList.FilterKey then
                CAIUnitList.FilterDropdown:SetSelectedIndex(index, true)
                break
            end
        end
        CAIUnitList.FilterDropdown:On("value_changed", function(_, filterKey)
            CAIUnitList.FilterKey = filterKey
            CAIUnitList.RebuildViews(false)
        end)
        panel:AddChild(CAIUnitList.FilterDropdown)

        CAIUnitList.SortDropdown = mgr:CreateWidget(UNIT_LIST_ID .. "_Sort", "Dropdown", {
            Label = function() return Locale.Lookup("LOC_CAI_UNIT_LIST_SORT") end,
            FocusKey = "unit:list:sort",
            HiddenPredicate = function() return CAIUnitList.ViewMode ~= "list" end,
        })
        CAIUnitList.SortOptions = CAIColumns.BuildSortOptions(CAIUnitList.Columns, {
            natural = { ascending = false }, separator = ", ", includeColumn = function(column) return column.sortKey ~= nil end,
        })
        CAIUnitList.SortDropdown:SetOptions(CAIUnitList.SortOptions)
        CAIUnitList.SyncSortDropdown()
        CAIUnitList.SortDropdown:On("value_changed", function(_, sort)
            CAIUnitList.SortColumn = sort.column
            CAIUnitList.SortAscending = sort.ascending == true
            CAIUnitList.Table:SetDefaultSort(sort.column ~= nil
                and { column = sort.column, ascending = sort.ascending }
                or nil)
            CAIUnitList.RebuildList()
        end)
        panel:AddChild(CAIUnitList.SortDropdown)

        CAIUnitList.SwitchButton = mgr:CreateWidget(UNIT_LIST_ID .. "_Switch", "Button", {
            Label = function()
                return Locale.Lookup(CAIUnitList.ViewMode == "table"
                    and "LOC_CAI_REPORTS_SWITCH_TO_LIST"
                    or "LOC_CAI_REPORTS_SWITCH_TO_TABLE")
            end,
            FocusKey = "unit:list:switch",
        })
        CAIUnitList.SwitchButton:On("activate", function()
            return CAIUnitList.SetViewMode(CAIUnitList.ViewMode == "table" and "list" or "table")
        end)
        panel:AddChild(CAIUnitList.SwitchButton)

        panel:AddInputBindings({
            {
                Key = Keys.VK_ESCAPE,
                Description = "LOC_CAI_KB_CLOSE",
                Action = function() RemoveUnitList(); return true end,
            },
            {
                Key = Keys["1"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_TABLE",
                Action = function() return CAIUnitList.SetViewMode("table") end,
            },
            {
                Key = Keys["2"],
                IsAlt = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_REPORTS_SWITCH_TO_LIST",
                Action = function() return CAIUnitList.SetViewMode("list") end,
            },
        })
        return panel
    end

    function CAIUnitList.OnUnitsChanged(playerID)
        if UnitList == nil then return end
        if playerID == Game.GetLocalPlayer() then
            CAIUnitList.RebuildViews(true)
        elseif CAIUnitList.SortColumn == "adjacent_enemies" then
            CAIUnitList.RebuildViews(false)
        end
    end

    function CAIUnitList.OnUnitStateChanged(playerID)
        if UnitList ~= nil and (playerID == nil or playerID == Game.GetLocalPlayer()
            or CAIUnitList.SortColumn == "adjacent_enemies") then
            CAIUnitList.RebuildViews(false)
        end
    end

    local function OpenUnitList()
        if mgr == nil then return end
        if UnitList ~= nil then RemoveUnitList() end
        UnitList = CAIUnitList.BuildPanel()
        if UnitList == nil then
            Speak(Locale.Lookup("LOC_CAI_UNIT_NO_UNITS"))
            return
        end

        local selectedUnit = GetSelectedUnit()
        local focusHint = nil
        if selectedUnit ~= nil and selectedUnit:GetOwner() == Game.GetLocalPlayer() then
            focusHint = tostring(CAIUnitList.Table.Id) .. ":row:"
                .. UnitRecordFocusKey(selectedUnit:GetOwner(), selectedUnit:GetID()) .. ":name"
        end
        mgr:Push(UnitList, { priority = PopupPriority.Low, focus = focusHint })
    end

    local function OnCAICycleSelectedUnit(direction, readyOnly)
        local selected = GetSelectedUnit()

        -- The follow-panel-sort setting decides whether cycling honours the panel's
        -- remembered sort or always falls back to distance (nearest first).
        local followSort = CAISettings.GetBool("UnitCyclingFollowPanelSort")
        local sortColumn, sortAscending
        if followSort then
            sortColumn = CAIUnitList.SortColumn
            sortAscending = CAIUnitList.SortAscending
        else
            sortColumn = "distance"
            sortAscending = true
        end

        -- Distance sort needs a fixed origin during a cycling run; otherwise the list
        -- re-centres on each newly selected unit and cycling stalls on the two
        -- mutually-nearest units. With no selection yet, measure from the cursor and
        -- start a fresh run; once a unit is selected, anchor on it and keep that
        -- origin until the selection changes by something other than this cycling.
        if sortColumn == "distance" then
            if selected == nil then
                CAIUnitList.CycleOrigin = nil
                CAIUnitList.CycleAnchorKey = nil
                CAIUnitList.DistanceOrigin = nil
            else
                local selectedKey = tostring(selected:GetOwner()) .. ":" .. tostring(selected:GetID())
                if CAIUnitList.CycleOrigin == nil or CAIUnitList.CycleAnchorKey ~= selectedKey then
                    CAIUnitList.CycleOrigin = { X = selected:GetX(), Y = selected:GetY() }
                end
                CAIUnitList.DistanceOrigin = CAIUnitList.CycleOrigin
            end
        end

        local units = CAIUnitList.GetSortedUnits(readyOnly, sortColumn, sortAscending)
        CAIUnitList.DistanceOrigin = nil

        if #units == 0 then
            CAIUnitList.CycleOrigin = nil
            CAIUnitList.CycleAnchorKey = nil
            Speak(Locale.Lookup(readyOnly and "LOC_CAI_NO_READY_UNITS" or "LOC_CAI_UNIT_NO_UNITS"))
            return
        end

        local currentIndex = nil
        if selected ~= nil then
            for index, unit in ipairs(units) do
                if unit:GetOwner() == selected:GetOwner() and unit:GetID() == selected:GetID() then
                    currentIndex = index
                    break
                end
            end
        end

        local wrap = CAISettings.GetBool("WrapUnitCycling")
        local nextIndex
        if currentIndex == nil then
            -- Selection is outside this pool (e.g. cycling ready units while a
            -- non-ready unit is selected); step in from the appropriate end.
            nextIndex = direction > 0 and 1 or #units
        else
            nextIndex = currentIndex + direction
            if nextIndex < 1 or nextIndex > #units then
                if not wrap then
                    -- No further unit in this direction; keep the current selection.
                    Speak(Locale.Lookup("LOC_CAI_NO_MORE_UNITS", GetUnitListName(selected)))
                    return
                end
                nextIndex = ((nextIndex - 1) % #units) + 1
            end
        end

        local chosen = units[nextIndex]
        if selected ~= nil and chosen:GetOwner() == selected:GetOwner()
            and chosen:GetID() == selected:GetID() then
            -- Only the current unit qualifies (e.g. a single unit in the pool).
            Speak(Locale.Lookup("LOC_CAI_NO_MORE_UNITS", GetUnitListName(selected)))
            return
        end

        UI.SelectUnit(chosen)
        UI.PlaySound("Play_UI_Click")

        -- Remember what we selected so the next press is recognised as a continuation
        -- of the same cycling run and keeps the anchored distance origin.
        CAIUnitList.CycleAnchorKey = tostring(chosen:GetOwner()) .. ":" .. tostring(chosen:GetID())
    end

    return {
        Open = OpenUnitList,
        Close = RemoveUnitList,
        Cycle = OnCAICycleSelectedUnit,
        OnUnitsChanged = CAIUnitList.OnUnitsChanged,
        OnUnitStateChanged = CAIUnitList.OnUnitStateChanged,
        OnCursorMoved = function()
            if UnitList ~= nil and CAIUnitList.SortColumn == "distance" then
                CAIUnitList.RebuildViews(false)
            end
        end,
    }
end
