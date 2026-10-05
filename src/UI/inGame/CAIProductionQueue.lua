-- Production queue presentation and keyboard operations. Native operations stay in the host.
CAIProductionQueue = {}

---@param mgr UIScreenManager
---@param context CAIProductionQueueContext
---@return CAIProductionQueueController
function CAIProductionQueue.Create(mgr, context)
    local MAX_QUEUE_SIZE = 7
    local pendingFocusIndex

    local function RemoveCurrentProductionFromQueue()
        if not context.HasCurrentProduction() then return true end
        local name = context.ReadCurrentName()
        if name == "" then return true end
        UI.PlaySound("Play_UI_Click")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_CURRENT_REMOVED", name))
        context.RemoveQueueItem(0)
        return true
    end

    local function MakeQueueEntryDescription(entry)
        if not entry then return "" end
        if entry.Directive == CityProductionDirectives.TRAIN and entry.UnitType then
            local def = GameInfo.Units[entry.UnitType]; if def then return Locale.Lookup(def.Name) end
        elseif entry.Directive == CityProductionDirectives.CONSTRUCT and entry.BuildingType then
            local def = GameInfo.Buildings[entry.BuildingType]; if def then return Locale.Lookup(def.Name) end
        elseif entry.Directive == CityProductionDirectives.ZONE and entry.DistrictType then
            local def = GameInfo.Districts[entry.DistrictType]; if def then return Locale.Lookup(def.Name) end
        elseif entry.Directive == CityProductionDirectives.PROJECT and entry.ProjectType then
            local def = GameInfo.Projects[entry.ProjectType]; if def then return Locale.Lookup(def.Name) end
        end
        return ""
    end

    local function GetQueueRowCount()
        local city = context.GetCity()
        if not city then return 0 end
        local pBQ = city:GetBuildQueue(); if not pBQ then return 0 end
        local count = 0
        for i = 1, MAX_QUEUE_SIZE do
            if pBQ:GetAt(i) ~= nil then count = i end
        end
        return count
    end

    local function GetFocusedQueueRow()
        local f = mgr:GetFocusedWidget()
        if f and f._caiQueueIndex then return f end
        return nil
    end

    local function GetFocusedQueueListIndex()
        local list = context.GetList()
        if not list or not list.Children then return nil end
        local focused = mgr:GetFocusedWidget()
        for i, child in ipairs(list.Children) do
            if child == focused then return i end
        end
        return nil
    end

    local function RemoveFocusedQueueItem()
        local row = GetFocusedQueueRow()
        if not row or not row._caiQueueIndex then return false end
        pendingFocusIndex = GetFocusedQueueListIndex()
        UI.PlaySound("Play_UI_Click")
        Speak(Locale.Lookup("LOC_CAI_PRODUCTION_QUEUE_REMOVED", row._caiQueueName or ""))
        context.RemoveQueueItem(row._caiQueueIndex)
        return true
    end

    local function MoveQueueSelection(direction)
        local row = GetFocusedQueueRow()
        local idx = row and row._caiQueueIndex or -1
        local name = row and row._caiQueueName or ""
        if idx == -1 then return false end

        local target = idx + direction
        if target < 0 or target > GetQueueRowCount() then
            if name ~= "" then
                local key = direction < 0 and "LOC_CAI_PRODUCTION_QUEUE_ALREADY_FIRST" or
                    "LOC_CAI_PRODUCTION_QUEUE_ALREADY_LAST"
                Speak(Locale.Lookup(key, name))
            end
            return true
        end

        local queueOffset = context.HasCurrentProduction() and 1 or 0
        pendingFocusIndex = target + queueOffset
        context.SwapQueueItem(idx, target)
        if name ~= "" then
            local key = direction < 0 and "LOC_CAI_PRODUCTION_QUEUE_MOVED_UP" or "LOC_CAI_PRODUCTION_QUEUE_MOVED_DOWN"
            Speak(Locale.Lookup(key, name))
        end
        return true
    end

    local function AddQueueBindings(row, removeAction)
        row:AddInputBindings({
            { Key = Keys.VK_DELETE, MSG = KeyEvents.KeyUp, Description = "LOC_CAI_KB_REMOVE_FROM_QUEUE", Action = removeAction },
            {
                Key = Keys.VK_UP,
                IsShift = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_KB_MOVE_QUEUE_UP",
                Action = function() return MoveQueueSelection(-1) end,
            },
            {
                Key = Keys.VK_DOWN,
                IsShift = true,
                MSG = KeyEvents.KeyDown,
                Description = "LOC_CAI_KB_MOVE_QUEUE_DOWN",
                Action = function() return MoveQueueSelection(1) end,
            },
        })
    end

    local function CreateQueueRow(queueIndex, name)
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelQueueRow"), "MenuItem", {
            Label    = function() return name end,
            FocusKey = "queue:" .. tostring(queueIndex),
        })
        row:SetFocusSound("Main_Menu_Mouse_Over")
        row._caiQueueIndex = queueIndex
        row._caiQueueName = name
        AddQueueBindings(row, RemoveFocusedQueueItem)
        return row
    end

    local function CreateQueueCurrentRow()
        local currentName = context.ReadCurrentName()
        local row = mgr:CreateWidget(mgr:GenerateWidgetId("CAIProductionPanelQueueCurrent"), "MenuItem", {
            Label    = function() return context.ReadCurrentLabel() end,
            Tooltip  = context.ReadCurrentTooltip,
            FocusKey = "current",
        })
        row:SetFocusSound("Main_Menu_Mouse_Over")
        row._caiQueueIndex = 0
        row._caiQueueName = currentName
        AddQueueBindings(row, RemoveCurrentProductionFromQueue)
        return row
    end

    local function RebuildQueuePage()
        local list = context.GetList(); if not list then return end
        local capture = mgr:CaptureFocusKey(list)
        list:ClearChildren()

        local city = context.GetCity()
        if city then
            if context.HasCurrentProduction() then
                list:AddChild(CreateQueueCurrentRow())
            end
            local pBQ = city:GetBuildQueue()
            if pBQ then
                for i = 1, MAX_QUEUE_SIZE do
                    local e = pBQ:GetAt(i)
                    if e then
                        local desc = MakeQueueEntryDescription(e)
                        if desc ~= "" then list:AddChild(CreateQueueRow(i, desc)) end
                    end
                end
            end
        end

        if pendingFocusIndex then
            local idx = pendingFocusIndex
            pendingFocusIndex = nil
            if list.Children and list.Children[idx] then
                mgr:SetFocus(list.Children[idx])
                return
            end
        end
        mgr:RestoreFocus(list, capture)
    end

    return {
        Rebuild = RebuildQueuePage,
        Reset = function() pendingFocusIndex = nil end,
    }
end
