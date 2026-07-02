include("inGameHelpers_CAI")

local Utils = CAIWorldScannerUtils

local SUBCATEGORY_MY = "my"

local function GetMapTacConfig(playerID, pinID)
    local playerConfig = PlayerConfigurations[playerID]
    local playerPins = playerConfig ~= nil and playerConfig:GetMapPins() or nil
    return playerPins ~= nil and playerPins[pinID] or nil
end

local function IsVisibleMapTac(playerID, pinID, localPlayerID)
    local mapPinCfg = GetMapTacConfig(playerID, pinID)
    return mapPinCfg ~= nil and mapPinCfg:IsVisible(localPlayerID)
end

CAIWorldScannerCategory_MapTacs = {
    Id = "mapTacs",
    LabelKey = "LOC_CAI_WORLD_SCANNER_CATEGORY_MAP_TACS",
    SubCategoryOrder = { SUBCATEGORY_MY },
    SubCategoryLabels = {
        [SUBCATEGORY_MY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    },
}

local function ResetSubCategoryMetadata()
    CAIWorldScannerCategory_MapTacs.SubCategoryOrder = { SUBCATEGORY_MY }
    CAIWorldScannerCategory_MapTacs.SubCategoryLabels = {
        [SUBCATEGORY_MY] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_MY",
    }
end

local function EnsurePlayerSubCategory(playerID)
    local subCategoryId = "player:" .. tostring(playerID)
    if CAIWorldScannerCategory_MapTacs.SubCategoryLabels[subCategoryId] == nil then
        table.insert(CAIWorldScannerCategory_MapTacs.SubCategoryOrder, subCategoryId)
        CAIWorldScannerCategory_MapTacs.SubCategoryLabels[subCategoryId] = Utils.GetPlayerLabel(playerID)
    end
    return subCategoryId
end

local function BuildScannerLabel(mapPinCfg, playerID, localPlayerID)
    return BuildMapTacLabelWithOwner(mapPinCfg, playerID, localPlayerID) or "LOC_CAI_WORLD_SCANNER_UNKNOWN"
end

function CAIWorldScannerCategory_MapTacs.Scan(context)
    local out = {}
    local localPlayerID = Utils.GetLocalPlayerID(context)
    if localPlayerID == nil or localPlayerID == -1 then
        return out
    end

    ResetSubCategoryMetadata()

    for iPlayer = 0, GameDefines.MAX_MAJOR_CIVS - 1 do
        local playerConfig = PlayerConfigurations[iPlayer]
        local playerPins = playerConfig ~= nil and playerConfig:GetMapPins() or nil
        if playerPins ~= nil then
            for pinID, mapPinCfg in pairs(playerPins) do
                if mapPinCfg ~= nil and mapPinCfg:IsVisible(localPlayerID) then
                    local plot = Map.GetPlot(mapPinCfg:GetHexX(), mapPinCfg:GetHexY())
                    if plot ~= nil then
                        local label = BuildScannerLabel(mapPinCfg, iPlayer, localPlayerID)
                        out[#out + 1] = {
                            Id = "mapTac:" .. tostring(iPlayer) .. ":" .. tostring(pinID),
                            PlotIndex = plot:GetIndex(),
                            LabelKey = label,
                            SubCategoryId = iPlayer == localPlayerID and SUBCATEGORY_MY or EnsurePlayerSubCategory(iPlayer),
                            GroupId = label,
                            PlayerID = iPlayer,
                            PinID = pinID,
                            Validate = function(item, validateContext)
                                local validateLocalPlayerID = Utils.GetLocalPlayerID(validateContext)
                                if not IsVisibleMapTac(item.PlayerID, item.PinID, validateLocalPlayerID) then
                                    return false
                                end

                                local livePin = GetMapTacConfig(item.PlayerID, item.PinID)
                                local livePlot = livePin ~= nil and Map.GetPlot(livePin:GetHexX(), livePin:GetHexY()) or nil
                                return livePlot ~= nil and livePlot:GetIndex() == item.PlotIndex
                            end,
                        }
                    end
                end
            end
        end
    end

    return out
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_MapTacs)
