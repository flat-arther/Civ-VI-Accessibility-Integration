include("caiUtils")
include("MapPinListPanel")
include("inGameHelpers_CAI")
include("hexCoordUtils_CAI")

local mgr            = ExposedMembers.CAI_UIManager
local CAICursor       = ExposedMembers.CAICursor
local HexCoordUtils   = CAIHexCoordUtils

local PANEL_ID = "CAIMapPin_Panel"
local LIST_ID  = "CAIMapPin_List"

local m_panel  = nil
local m_list   = nil

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
-- Panel
-- ============================================================================

local function RefreshPanelList()
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

ContextPtr:SetShutdown(function()
    LuaEvents.CAIMapPinList_VisibilityChanged.Remove(OnVisibilityChanged)
    LuaEvents.CAIMapPinList_Refresh.Remove(OnRefreshRequest)
    PopPanel()
end)
