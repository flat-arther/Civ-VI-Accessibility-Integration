---@meta


---**Contexts:** UI
AutoProfiler = {}
---**Contexts:** UI
---
---*Action*
---@param count number 
function AutoProfiler.SetLookAtCount(count) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function AutoProfiler.GetWaitForLandmarks() end
---**Contexts:** UI
---
---*Query*
---@return string testName 
function AutoProfiler.GetTestName() end
---**Contexts:** UI
---
---*Action*
---@param frames number 
function AutoProfiler.SetLookAtFrames(frames) end
---**Contexts:** UI
---
---*Query*
---@return number frames 
function AutoProfiler.GetLookAtFrames() end
---**Contexts:** UI
---
---*Query*
---@return number GPUStallThreshold 
function AutoProfiler.GetGPUStallThreshold() end
---**Contexts:** UI
---
---*Action*
---@param filePath string 
function AutoProfiler.SetFilePath(filePath) end
---**Contexts:** UI
---
---*Action*
---@param GPUStallThreshold number 
function AutoProfiler.SetGPUStallThreshold(GPUStallThreshold) end
---**Contexts:** UI
---
---*Action*
---
---Runs a debug console command.
---@param command string commands
function AutoProfiler.RunCommand(command) end
---**Contexts:** UI
---
---*Query*
---@return string state 
function AutoProfiler.GetStateString() end
---**Contexts:** UI
---
---*Action*
function AutoProfiler.Start() end
---**Contexts:** UI
---
---*Action*
---@param testName string 
function AutoProfiler.SetTestName(testName) end
---**Contexts:** UI
---
---*Action*
---@param waitForLandmarks boolean 
function AutoProfiler.SetWaitForLandmarks(waitForLandmarks) end
---**Contexts:** UI
---
---*Action*
---@param zoom number 
function AutoProfiler.SetCameraZoom(zoom) end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function AutoProfiler.GetWaitForTerrain() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function AutoProfiler.IsIdle() end
---**Contexts:** UI
---
---*Query*
---@return number zoom 
function AutoProfiler.GetCameraZoom() end
---**Contexts:** UI
---
---*Action*
---@param waitForTerrain boolean 
function AutoProfiler.SetWaitForTerrain(waitForTerrain) end
---**Contexts:** UI
---
---*Query*
---@return number testTimeRemaining 
function AutoProfiler.GetTimeRemaining() end
---**Contexts:** UI
---
---*Action*
---@param summaryColumnName string 
function AutoProfiler.AddColumn(summaryColumnName) end
---**Contexts:** UI
---
---*Query*
---@return number count 
function AutoProfiler.GetLookAtCount() end