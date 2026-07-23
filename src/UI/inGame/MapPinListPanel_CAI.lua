include("caiUtils")
include("MapPinListPanel")
include("inGameHelpers_CAI")
include("hexCoordUtils_CAI")

local mgr                    = ExposedMembers.CAI_UIManager
local CAICursor              = ExposedMembers.CAICursor
local HexCoordUtils          = CAIHexCoordUtils

local PANEL_ID               = "CAIMapPin_Panel"
local LIST_ID                = "CAIMapPin_List"

local BOOKMARK_SLOT_COUNT    = 10
local BOOKMARK_CONFIG_PREFIX = "CAI_MAP_PIN_BOOKMARK_SLOT_"

local m_mapPinActions        = {}

local m_panel                = nil
local m_list                 = nil
local m_deleteDialog         = nil
local RefreshPanelList

-- ============================================================================
-- Map-pin bookmarks
-- ============================================================================

local function GetLocalPlayerConfig()
    local playerID = Game.GetLocalPlayer()
    if playerID == nil or playerID < 0 then return nil end
    return PlayerConfigurations[playerID]
end

local function GetBookmarkConfigKey(slot)
    return BOOKMARK_CONFIG_PREFIX .. tostring(slot)
end

local function GetBookmarkPinID(playerConfig, slot)
    -- An unset PlayerConfiguration value returns no values rather than one nil.
    -- Capture it first so tonumber always receives an argument.
    local rawPinID = playerConfig:GetValue(GetBookmarkConfigKey(slot))
    local pinID = tonumber(rawPinID)
    if pinID == nil or pinID < 0 then return nil end
    return pinID
end

local function SetBookmarkPinID(playerConfig, slot, pinID)
    playerConfig:SetValue(GetBookmarkConfigKey(slot), pinID or -1)
end

local function GetBookmarkName(slot)
    return Locale.Lookup("LOC_CAI_BOOKMARK", slot)
end

local function ClearOtherSlotsForPin(playerConfig, slot, pinID)
    for otherSlot = 1, BOOKMARK_SLOT_COUNT do
        if otherSlot ~= slot and GetBookmarkPinID(playerConfig, otherSlot) == pinID then
            SetBookmarkPinID(playerConfig, otherSlot, nil)
        end
    end
end

local function ClearBookmarksForPin(playerConfig, pinID)
    for slot = 1, BOOKMARK_SLOT_COUNT do
        if GetBookmarkPinID(playerConfig, slot) == pinID then
            SetBookmarkPinID(playerConfig, slot, nil)
        end
    end
end

local function AssignBookmark(slot)
    local playerConfig = GetLocalPlayerConfig()
    local cursorX, cursorY = nil, nil
    if CAICursor ~= nil then
        cursorX, cursorY = CAICursor:GetCoords()
    end
    if playerConfig == nil or cursorX == nil or cursorY == nil then
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_UNAVAILABLE"))
        return
    end

    -- Vanilla MapPinPopup uses GetMapPin(x, y) for both editing an existing
    -- owned pin and creating the default pin when the tile has none.
    local targetPin = playerConfig:GetMapPin(cursorX, cursorY)
    if targetPin == nil then
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_UNAVAILABLE"))
        return
    end

    local targetPinID = targetPin:GetID()
    local previousPinID = GetBookmarkPinID(playerConfig, slot)

    -- Mutate the live object before deleting another pin; DeleteMapPin may
    -- invalidate MapPinConfiguration objects returned earlier in this call.
    targetPin:SetName(GetBookmarkName(slot))
    ClearOtherSlotsForPin(playerConfig, slot, targetPinID)

    if previousPinID ~= nil and previousPinID ~= targetPinID then
        local previousPin = playerConfig:GetMapPinID(previousPinID)
        if previousPin ~= nil then
            playerConfig:DeleteMapPin(previousPinID)
        end
    end

    SetBookmarkPinID(playerConfig, slot, targetPinID)
    Network.BroadcastPlayerInfo()
    UI.PlaySound("Map_Pin_Add")
    Speak(Locale.Lookup("LOC_CAI_BOOKMARK_ASSIGNED", slot))
end

local function ResolveBookmark(slot)
    local playerConfig = GetLocalPlayerConfig()
    if playerConfig == nil then
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_UNAVAILABLE"))
        return nil
    end

    local pinID = GetBookmarkPinID(playerConfig, slot)
    local mapPin = pinID ~= nil and playerConfig:GetMapPinID(pinID) or nil
    if mapPin == nil then
        if pinID ~= nil then
            SetBookmarkPinID(playerConfig, slot, nil)
            Network.BroadcastPlayerInfo()
        end
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_EMPTY", slot))
        return nil
    end

    return mapPin
end

local function JumpToBookmark(slot)
    local mapPin = ResolveBookmark(slot)
    if mapPin == nil then return end

    local plot = Map.GetPlot(mapPin:GetHexX(), mapPin:GetHexY())
    if plot == nil then
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_UNAVAILABLE"))
        return
    end

    LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
end

local function SpeakBookmarkDirection(slot)
    local mapPin = ResolveBookmark(slot)
    if mapPin == nil then return end

    local cursorX, cursorY = nil, nil
    if CAICursor ~= nil then
        cursorX, cursorY = CAICursor:GetCoords()
    end
    if cursorX == nil or cursorY == nil then
        Speak(Locale.Lookup("LOC_CAI_BOOKMARK_UNAVAILABLE"))
        return
    end

    local direction = HexCoordUtils.directionString(
        cursorX,
        cursorY,
        mapPin:GetHexX(),
        mapPin:GetHexY()
    )
    Speak(direction)
end

local function OnMapPinInputActionStarted(actionID)
    local action = m_mapPinActions[actionID]
    if action ~= nil then action() end
end

for slot = 1, BOOKMARK_SLOT_COUNT do
    local capturedSlot = slot
    local assignActionID = Input.GetActionId("CAIMapPinBookmarkAssign" .. tostring(slot))
    local jumpActionID = Input.GetActionId("CAIMapPinBookmarkJump" .. tostring(slot))
    local directionActionID = Input.GetActionId("CAIMapPinBookmarkDirection" .. tostring(slot))
    if assignActionID ~= nil then
        m_mapPinActions[assignActionID] = function() AssignBookmark(capturedSlot) end
    end
    if jumpActionID ~= nil then
        m_mapPinActions[jumpActionID] = function() JumpToBookmark(capturedSlot) end
    end
    if directionActionID ~= nil then
        m_mapPinActions[directionActionID] = function() SpeakBookmarkDirection(capturedSlot) end
    end
end

-- ============================================================================
-- Pin label: name, icon, direction
-- ============================================================================

local function BuildPinLabel(mapPinCfg)
    local dirText = ""
    if CAICursor then
        local cursorX, cursorY = CAICursor:GetCoords()
        if cursorX ~= nil and cursorY ~= nil then
            local hexX = mapPinCfg:GetHexX()
            local hexY = mapPinCfg:GetHexY()
            dirText = HexCoordUtils.directionString(cursorX, cursorY, hexX, hexY)
        end
    end

    local parts = { BuildMapTacLabel(mapPinCfg) }
    if dirText ~= "" then table.insert(parts, dirText) end
    return table.concat(parts, ", ")
end

-- ============================================================================
-- Delete confirmation
-- ============================================================================

local function CloseDeleteDialog()
    local dialog = m_deleteDialog
    m_deleteDialog = nil
    if mgr and dialog and mgr:GetWidgetById(dialog:GetId()) then
        mgr:RemoveFromStack(dialog:GetId())
    end
end

local function DeleteOwnedMapPin(pinID)
    local playerConfig = GetLocalPlayerConfig()
    local mapPin = playerConfig and playerConfig:GetMapPinID(pinID) or nil
    if mapPin == nil then
        Speak(Locale.Lookup("LOC_CAI_MAP_TAC_UNAVAILABLE"))
        return
    end

    ClearBookmarksForPin(playerConfig, pinID)
    playerConfig:DeleteMapPin(pinID)
    Network.BroadcastPlayerInfo()
    UI.PlaySound("Map_Pin_Remove")
    if m_panel then RefreshPanelList() end
end

local function ShowDeleteConfirmation(pinID)
    if not mgr then return end
    if m_deleteDialog and mgr:GetWidgetById(m_deleteDialog:GetId()) then return end

    local playerConfig = GetLocalPlayerConfig()
    local mapPin = playerConfig and playerConfig:GetMapPinID(pinID) or nil
    if mapPin == nil then
        Speak(Locale.Lookup("LOC_CAI_MAP_TAC_UNAVAILABLE"))
        return
    end
    local pinLabel = BuildMapTacLabel(mapPin)

    local message = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinDelete_Message"), "StaticText", {
        Label = function() return Locale.Lookup("LOC_CAI_MAP_TAC_DELETE_CONFIRMATION_BODY", pinLabel) end,
    })

    local yesButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinDelete_Yes"), "Button", {
        Label = function() return Locale.Lookup("LOC_YES") end,
    })
    yesButton:On("activate", function()
        CloseDeleteDialog()
        DeleteOwnedMapPin(pinID)
    end)

    local noButton = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPinDelete_No"), "Button", {
        Label = function() return Locale.Lookup("LOC_NO") end,
    })
    noButton:On("activate", function()
        CloseDeleteDialog()
    end)

    m_deleteDialog = mgr.WidgetHelpers.MakeGeneralDialog(
        function() return Locale.Lookup("LOC_CAI_MAP_TAC_DELETE_CONFIRMATION_TITLE") end,
        { yesButton, noButton },
        { message },
        1
    )
    if not m_deleteDialog then return end

    m_deleteDialog:On("focus_leave", function()
        CloseDeleteDialog()
    end)
    m_deleteDialog:AddInputBinding({
        Key = Keys.VK_ESCAPE,
        MSG = KeyEvents.KeyUp,
        Description = "LOC_CAI_KB_CLOSE",
        Action = function()
            CloseDeleteDialog()
            return true
        end,
    })
    mgr:Push(m_deleteDialog, { priority = PopupPriority.Current })
end

local function FindOwnedMapPinAtCursor()
    local playerConfig = GetLocalPlayerConfig()
    local cursorX, cursorY = nil, nil
    if CAICursor ~= nil then
        cursorX, cursorY = CAICursor:GetCoords()
    end
    if playerConfig == nil or cursorX == nil or cursorY == nil then return nil end

    local mapPins = playerConfig:GetMapPins()
    if mapPins == nil then return nil end
    for _, mapPin in pairs(mapPins) do
        if mapPin:GetHexX() == cursorX and mapPin:GetHexY() == cursorY then
            return mapPin
        end
    end
    return nil
end

local function DeleteMapTacUnderCursor()
    -- The focused list row owns raw Delete while the list is open. Do not let
    -- the world action open a second dialog for the navigation-cursor plot.
    if m_panel then return end

    local mapPin = FindOwnedMapPinAtCursor()
    if mapPin == nil then
        Speak(Locale.Lookup("LOC_CAI_MAP_TAC_NONE_AT_CURSOR"))
        return
    end
    ShowDeleteConfirmation(mapPin:GetID())
end

local deleteMapTacActionID = Input.GetActionId("CAIDeleteMapTac")
if deleteMapTacActionID ~= nil then
    m_mapPinActions[deleteMapTacActionID] = DeleteMapTacUnderCursor
end

-- ============================================================================
-- Panel
-- ============================================================================

RefreshPanelList = function()
    if not m_list then return end

    local capture = mgr:CaptureFocusKey(m_list)
    m_list:ClearChildren()

    local localPlayerID = Game.GetLocalPlayer()

    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local pPlayerConfig = PlayerConfigurations[iPlayer]
        if pPlayerConfig then
            local pPlayerPins = pPlayerConfig:GetMapPins()
            if pPlayerPins then
                for _, mapPinCfg in pairs(pPlayerPins) do
                    if mapPinCfg and mapPinCfg:IsVisible(localPlayerID) then
                        local pinID = mapPinCfg:GetID()
                        local uniqueKey = "pin_" .. tostring(iPlayer) .. "_" .. tostring(pinID)
                        local w = mgr:CreateWidget(mgr:GenerateWidgetId("CAIMapPin_Entry"), "MenuItem", {
                            Label    = function() return BuildPinLabel(mapPinCfg) end,
                            FocusKey = uniqueKey,
                        })
                        w:SetFocusSound("Main_Menu_Mouse_Over")

                        w:On("activate", function()
                            local cfg = GetMapPinConfig(iPlayer, pinID)
                            if cfg then
                                local plot = Map.GetPlot(cfg:GetHexX(), cfg:GetHexY())
                                if plot then
                                    LuaEvents.CAICursorMoveTo(plot:GetIndex(), "jump")
                                end
                            end
                        end)

                        if iPlayer == localPlayerID then
                            w:AddInputBindings({
                                {
                                    Key = Keys.VK_RETURN,
                                    MSG = KeyEvents.KeyUp,
                                    IsControl = true,
                                    Description = "LOC_CAI_KB_EDIT_MAP_PIN",
                                    Action = function()
                                        OnMapPinEntryEdit(iPlayer, pinID)
                                        return true
                                    end
                                },
                                {
                                    Key = Keys.VK_DELETE,
                                    MSG = KeyEvents.KeyUp,
                                    Description = "LOC_CAI_KB_DELETE_MAP_TAC",
                                    Action = function()
                                        ShowDeleteConfirmation(pinID)
                                        return true
                                    end
                                }
                            })
                        end

                        m_list:AddChild(w)
                    end
                end
            end
        end
    end

    mgr:RestoreFocus(m_list, capture)
end

local function ClosePanel()
    LuaEvents.CAIMapPinList_RequestClose()
end

local function BuildPanel()
    m_panel = mgr:CreateWidget(PANEL_ID, "Panel", {
        Label = function() return Locale.Lookup("LOC_HUD_MAP_PIN_LIST") end,
    })
    m_panel:AddInputBindings({
        {
            Key = Keys.VK_ESCAPE,
            MSG = KeyEvents.KeyUp,
            Description = "LOC_CAI_KB_CLOSE",
            Action = function()
                ClosePanel()
                return true
            end
        }
    })

    m_list = mgr:CreateWidget(LIST_ID, "List", {
        Label = function() return Locale.Lookup("LOC_HUD_MAP_PIN_LIST") end,
    })
    m_panel:AddChild(m_list)

    RefreshPanelList()
end

local function PushPanel()
    if m_panel then return end
    BuildPanel()
    mgr:Push(m_panel)
end

local function PopPanel()
    CloseDeleteDialog()
    if mgr and m_panel then
        mgr:RemoveFromStack(PANEL_ID)
    end
    m_panel = nil
    m_list = nil
end

local function OnVisibilityChanged(isVisible)
    if not mgr then return end
    if isVisible then
        PushPanel()
    else
        PopPanel()
    end
end

-- ============================================================================
-- Vanilla wraps
-- ============================================================================

BuildMapPinList = WrapFunc(BuildMapPinList, function(orig)
    orig()
    if mgr and m_panel then
        RefreshPanelList()
    end
end)

ContextPtr:SetInputHandler(function(input)
    if mgr and mgr:GetWidgetById(PANEL_ID) then
        if mgr:HandleInput(input) then
            return true
        end
    end
    return false
end, true)

local function OnRefreshRequest()
    if m_panel then
        RefreshPanelList()
    end
end

LuaEvents.CAIMapPinList_VisibilityChanged.Add(OnVisibilityChanged)
LuaEvents.CAIMapPinList_Refresh.Add(OnRefreshRequest)

local function OnShutdown()
    Events.InputActionStarted.Remove(OnMapPinInputActionStarted)
    LuaEvents.CAIMapPinList_VisibilityChanged.Remove(OnVisibilityChanged)
    LuaEvents.CAIMapPinList_Refresh.Remove(OnRefreshRequest)
    PopPanel()
end

Events.InputActionStarted.Add(OnMapPinInputActionStarted)
ContextPtr:SetShutdown(OnShutdown)
