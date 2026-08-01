local SUBCATEGORY_LOCATIONS = "locations"
local GROUP_LOCATIONS = "tutorialLocations"

local function GetTutorialWorldAnchor()
    local anchor = ExposedMembers.CAI_TutorialWorldAnchor
    if anchor == nil
        or type(anchor.Header) ~= "string"
        or anchor.Header == ""
        or anchor.x == nil
        or anchor.y == nil then
        return nil
    end
    return anchor
end

local function GetAnchorPlotIndex(anchor)
    if anchor == nil then return nil end
    local plot = Map.GetPlot(anchor.x, anchor.y)
    return plot ~= nil and plot:GetIndex() or nil
end

CAIWorldScannerCategory_Tutorial = {
    Id = "tutorial",
    LabelKey = "LOC_CAI_MESSAGE_BUFFER_CAT_TUTORIAL",
    Contextual = true,
    SubCategoryOrder = { SUBCATEGORY_LOCATIONS },
    SubCategoryLabels = {
        [SUBCATEGORY_LOCATIONS] = "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TUTORIAL_LOCATIONS",
    },
    GroupLabelResolver = function()
        return "LOC_CAI_WORLD_SCANNER_SUBCATEGORY_TUTORIAL_LOCATIONS"
    end,
    CanScan = function()
        return GetAnchorPlotIndex(GetTutorialWorldAnchor()) ~= nil
    end,
}

function CAIWorldScannerCategory_Tutorial.Scan()
    local anchor = GetTutorialWorldAnchor()
    local plotIndex = GetAnchorPlotIndex(anchor)
    if plotIndex == nil then return {} end

    return {
        {
            Id = "tutorial:current",
            PlotIndex = plotIndex,
            LabelKey = anchor.Header,
            SubCategoryId = SUBCATEGORY_LOCATIONS,
            GroupId = GROUP_LOCATIONS,
            Validate = function(item)
                local liveAnchor = GetTutorialWorldAnchor()
                return liveAnchor ~= nil
                    and liveAnchor.Header == anchor.Header
                    and GetAnchorPlotIndex(liveAnchor) == item.PlotIndex
            end,
        },
    }
end

CAIWorldScanner:RegisterCategoryDefinition(CAIWorldScannerCategory_Tutorial)
