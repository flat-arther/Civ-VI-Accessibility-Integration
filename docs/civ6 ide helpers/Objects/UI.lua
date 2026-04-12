---@meta


---**Contexts:** UI
UI = {}
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsUnitSelected() end
---**Contexts:** UI
---
---*Action*
function UI.SetFixedTiltMode() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.HasOutdatedDriver() end
---**Contexts:** UI
---
---*Query*
---@return TypedDataVariantParameters TypedDataVariantParameters 
function UI.GetGameParameters() end
---**Contexts:** UI
---
---*Action*
function UI.LinePlotUnit() end
---**Contexts:** UI
---
---*Query*
function UI.CanShowModal() end
---**Contexts:** UI
---
---*Action*
function UI.ShowFullscreenMap() end
---**Contexts:** UI
---
---*Action*
function UI.LoadSoundBankGroup() end
---**Contexts:** UI
---
---*Query*
function UI.GetMapZoom() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.Is2KCloudAvailable() end
---**Contexts:** UI
---
---*Action*
function UI.SetMapZoom() end
---**Contexts:** UI
---
---*Action*
---
---Prints a message to MapSearch.log.
---@param message string 
function UI.MapSearch_LogEnd(message) end
---**Contexts:** UI
---
---*Action*
function UI.SetLeaderPosition() end
---**Contexts:** UI
---
---*Query*
---@param mapX number 
---@param mapY number 
---@return number worldX 
---@return number worldY 
---@return number worldZ 
function UI.GridToWorld(mapX, mapY) end
---**Contexts:** UI
---
---*Query*
function UI.WorldWrapEnabled() end
---**Contexts:** UI
---
---*Query*
function UI.GetNormalEraSoundSwitchValue() end
---**Contexts:** UI
---
---*Action*
function UI.RequestPlayerOperation() end
---**Contexts:** UI
---
---*Query*
function UI.GetTextControl() end
---**Contexts:** UI
---
---*Action*
function UI.SetARXTagsContentByClass() end
---**Contexts:** UI
---
---*Action*
function UI.MakeSaveGameMetaData() end
---**Contexts:** UI
---
---*Query*
function UI.GetHeadSelectedDistrict() end
---**Contexts:** UI
---
---*Action*
function UI.AddNumberToPath() end
---**Contexts:** UI
---
---*Query*
function UI.GetARXDeviceType() end
---**Contexts:** UI
---
---*Action*
function UI.OnNaturalWonderRevealed() end
---**Contexts:** UI
---
---*Action*
---
---Same as Autoprofiler.RunCommand; runs a command in the debug console
---@param command string See https://docs.google.com/document/d/1nb2VnsaCdLU4arKtzU0kHv5WtMRT3c6krpl9nOam3XU
function UI.DebugCommand(command) end
---**Contexts:** UI
---
---*Action*
function UI.ClearTemporaryPlotVisibility() end
---**Contexts:** UI
---
---*Query*
function UI.GetLockedWorldRect() end
---**Contexts:** UI
---
---*Query*
function UI.GetMapLookAtWorldTarget() end
---**Contexts:** UI
---
---*Action*
function UI.LookAtPlotScreenPosition() end
---**Contexts:** UI
---
---*Action*
function UI.SetLookAtTimeScale() end
---**Contexts:** UI
---
---*Action*
function UI.SelectClosestReadyUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsInFrontEnd() end
---**Contexts:** UI
---
---*Query*
function UI.GetLastSaveName() end
---**Contexts:** UI
---
---*Query*
function UI.HasARX() end
---**Contexts:** UI
---
---*Action*
function UI.SelectUnitID() end
---**Contexts:** UI
---
---*Action*
function UI.SetLeaderSceneControl() end
---**Contexts:** UI
---
---*Action*
function UI.PlayLeaderSceneEffect() end
---**Contexts:** UI
---
---*Query*
function UI.GetWorldFromNormalizedScreenPos_NoWrap() end
---**Contexts:** UI
---
---*Action*
function UI.SkipNextAutoEndTurn() end
---**Contexts:** UI
---
---*Query*
function UI.TouchEnableChanged() end
---**Contexts:** UI
---
---*Query*
function UI.ReferenceCurrentEvent() end
---**Contexts:** UI
---
---*Query*
function UI.MapSearch_LogBegin() end
---**Contexts:** UI
---
---*Query*
function UI.GetHeadSelectedCity() end
---**Contexts:** UI
---
---*Action*
function UI.ApplyFileQueryCivImage() end
---**Contexts:** UI
---
---*Action*
function UI.AddTemporaryPlotVisibility() end
---**Contexts:** UI
---
---*Action*
function UI.HighlightPlots() end
---**Contexts:** UI
---
---*Action*
function UI.SetSoundStateValue() end
---**Contexts:** UI
---
---*Query*
function UI.IsCityIDSelected() end
---**Contexts:** UI
---
---*Query*
function UI.GetAmbientTimeOfDaySpeed() end
---**Contexts:** UI
---
---*Action*
function UI.AssertMsg() end
---**Contexts:** UI
---
---*Action*
function UI.SelectNextReadyUnit() end
---**Contexts:** UI
---
---*Query*
function UI.HasSentTurnComplete() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsWorldRenderViewAvailable() end
---**Contexts:** UI
---
---*Query*
function UI.GetPlayerColorValues() end
---**Contexts:** UI
---
---*Action*
function UI.SetAmbientTimeOfDaySpeed() end
---**Contexts:** UI
---
---*Query*
function UI.GetCursorPlotID() end
---**Contexts:** UI
---
---*Query*
function UI.GetAppVersion() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectCityID() end
---**Contexts:** UI
---
---*Action*
function UI.SpinMap() end
---**Contexts:** UI
---
---*Action*
function UI.EnableTimeOfDayOverride() end
---**Contexts:** UI
---
---*Action*
function UI.RequestAction() end
---**Contexts:** UI
---
---*Action*
function UI.StopInGameMusic() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsARXDisplayPortrait() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsFileListQueryComplete() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsResyncLoadInProgress() end
---**Contexts:** UI
---
---*Action*
function UI.LinePlotPlot() end
---**Contexts:** UI
---
---*Action*
function UI.EnqueueNotificationSound() end
---**Contexts:** UI
---
---*Query*
function UI.GetCursorPlotCoord() end
---**Contexts:** UI
---
---*Action*
function UI.CloseAllFileListQueries() end
---**Contexts:** UI
---
---*Action*
function UI.SelectPrevReadyUnit() end
---**Contexts:** UI
---
---*Query*
function UI.ReferenceEventID() end
---**Contexts:** UI
---
---*Query*
function UI.CanShowPopup() end
---**Contexts:** UI
---
---*Action*
function UI.RebuildSelectionList() end
---**Contexts:** UI
---
---*Action*
function UI.ApplyFileQueryLeaderImage() end
---**Contexts:** UI
---
---*Action*
---@param x number 
---@param y number 
function UI.SetMinimapSize(x, y) end
---**Contexts:** UI
---
---*Action*
function UI.DeselectAllUnits() end
---**Contexts:** UI
---
---*Query*
function UI.ArePlayerColorsConflicting() end
---**Contexts:** UI
---
---*Query*
function UI.GetLookAtTimeScale() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsInMarketingMode() end
---**Contexts:** UI
---
---*Query*
function UI.GetColorValueFromHexLiteral() end
---**Contexts:** UI
---
---*Action*
function UI.SetPushDataIDSeen() end
---**Contexts:** UI
---
---*Action*
function UI.CloseFileListQuery() end
---**Contexts:** UI
---
---*Query*
function UI.GetColorValue() end
---**Contexts:** UI
---
---*Action*
function UI.RefreshColorSet() end
---**Contexts:** UI
---
---*Action*
function UI.SetExitOnClose() end
---**Contexts:** UI
---
---*Query*
function UI.AreCloudSavesEnabled() end
---**Contexts:** UI
---
---*Action*
function UI.SetPauseEventID() end
---**Contexts:** UI
---
---*Action*
function UI.SetWorldRenderView() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsInGame() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.CanEndTurn() end
---**Contexts:** UI
---
---*Query*
function UI.GetManualSaveUsageSize() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectAll() end
---**Contexts:** UI
---
---*Action*
function UI.SetFixedTiltAngle() end
---**Contexts:** UI
---
---*Query*
function UI.CanStartPlayerOperation() end
---**Contexts:** UI
---
---*Query*
function UI.QuerySaveGameList() end
---**Contexts:** UI
---
---*Query*
function UI.ShouldCivPlayModMusic() end
---**Contexts:** UI
---
---*Query*
function UI.HotReloadSounds() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsAmbientTimeOfDayAnimating() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsAnyModalInterfaceVisible() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsTurnTimerElapsed() end
---**Contexts:** UI
---
---*Action*
function UI.FocusMap() end
---**Contexts:** UI
---
---*Query*
function UI.CheckUserSetup() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectCity() end
---**Contexts:** UI
---
---*Query*
function UI.GetMaxMSAACount() end
---**Contexts:** UI
---
---*Query*
function UI.GetPlotCoordFromWorld() end
---**Contexts:** UI
---
---*Query*
function UI.CanHaveMSAAQuality() end
---**Contexts:** UI
---
---*Action*
function UI.LookAtPosition() end
---**Contexts:** UI
---
---*Query*
function UI.GetSaveGameModificationTimeRaw() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsGameCoreBusy() end
---**Contexts:** UI
---
---*Query*
function UI.GetPushData() end
---**Contexts:** UI
---
---*Action*
function UI.LinearToSRGB() end
---**Contexts:** UI
---
---*Query*
function UI.GetLineControl() end
---**Contexts:** UI
---
---*Action*
function UI.TruncatePathLevels() end
---**Contexts:** UI
---
---*Action*
function UI.SelectNextCity() end
---**Contexts:** UI
---
---*Query*
function UI.GetPathLevels() end
---**Contexts:** UI
---
---*Query*
function UI.SetPushDataIDClosed() end
---**Contexts:** UI
---
---*Query*
function UI.SetRestoreMapZoom() end
---**Contexts:** UI
---
---*Action*
function UI.DarkenLightenColor() end
---**Contexts:** UI
---
---*Query*
function UI.LeaderQualityAllowsMotionBlur() end
---**Contexts:** UI
---
---*Action*
function UI.PanMap() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectDistrict() end
---**Contexts:** UI
---
---*Action*
function UI.SetSoundSwitchValue() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsVendorNVIDIA() end
---**Contexts:** UI
---
---*Query*
function UI.GetMinimapWorldRect() end
---**Contexts:** UI
---
---*Query*
function UI.GetPlotCoordFromNormalizedScreenPos() end
---**Contexts:** UI
---
---*Query*
function UI.GetWorldFromNormalizedScreenPos() end
---**Contexts:** UI
---
---*Action*
function UI.ToggleGrid() end
---**Contexts:** UI
---
---*Query*
function UI.GetAmbientTimeOfDay() end
---**Contexts:** UI
---
---*Query*
function UI.CalculateEdgeSplineSegments() end
---**Contexts:** UI
---
---*Query*
function UI.GetRegionCenter() end
---**Contexts:** UI
---
---*Query*
function UI.GetColorChannels() end
---**Contexts:** UI
---
---*Query*
function UI.QueryGlobalParameterInt() end
---**Contexts:** UI
---
---*Action*
function UI.RestoreMapZoom() end
---**Contexts:** UI
---
---*Query*
function UI.GetColors() end
---**Contexts:** UI
---
---*Action*
function UI.UnloadSoundBankGroup() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.HasUnknownDevice() end
---**Contexts:** UI
---
---*Action*
function UI.StopModCivLeaderMusic() end
---**Contexts:** UI
---
---*Action*
function UI.PauseModCivMusic() end
---**Contexts:** UI
---
---*Action*
function UI.SetLeaderImageControl() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsPlayersLeaderAnimated() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectUnitID() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsVendorAMD() end
---**Contexts:** UI
---
---*Query*
function UI.HasFeature() end
---**Contexts:** UI
---
---*Action*
function UI.SelectUnit() end
---**Contexts:** UI
---
---*Action*
function UI.FillPlaylistWithAllCivs() end
---**Contexts:** UI
---
---*Action*
function UI.SelectNextUnit() end
---**Contexts:** UI
---
---*Action*
function UI.SelectDistrict() end
---**Contexts:** UI
---
---*Query*
function UI.HasUnsupportedDevice() end
---**Contexts:** UI
---
---*Query*
function UI.GetSaveLocationPath() end
---**Contexts:** UI
---
---*Query*
function UI.GetAmbienceClipDistance() end
---**Contexts:** UI
---
---*Action*
function UI.SetAmbientTimeOfDayAnimating() end
---**Contexts:** UI
---
---*Action*
function UI.SelectCity() end
---**Contexts:** UI
---
---*Action*
function UI.SetSelectedUnitUIArt() end
---**Contexts:** UI
---
---*Query*
function UI.GetPlayerColors() end
---**Contexts:** UI
---
---*Query*
function UI.GetDefaultCloudSaveLocation() end
---**Contexts:** UI
---
---*Action*
function UI.PlayModCivLeaderMusic() end
---**Contexts:** UI
---
---*Query*
function UI.GetWorldRenderView() end
---**Contexts:** UI
---
---*Action*
function UI.ReleaseEventID() end
---**Contexts:** UI
---
---*Action*
function UI.RebuildColorDB() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsDistrictIDSelected() end
---**Contexts:** UI
---
---*Action*
function UI.PlaySound() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsMovementPathOn() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsFullscreenMapEnabled() end
---**Contexts:** UI
---
---*Query*
function UI.GetSaveGameMetaData() end
---**Contexts:** UI
---
---*Query*
function UI.GetCursorNearestPlotEdge() end
---**Contexts:** UI
---
---*Query*
function UI.GetCivilizationSoundSwitchValueByLeader() end
---**Contexts:** UI
---
---*Action*
function UI.SetAmbienceClipDistance() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsAnyPopupInterfaceVisible() end
---**Contexts:** UI
---
---*Query*
function UI.GetElapsedTime() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.LeaderQualityRequiresRestart() end
---**Contexts:** UI
---
---*Query*
function UI.GetEraSoundSwitchValue() end
---**Contexts:** UI
---
---*Action*
function UI.Screenshot() end
---**Contexts:** UI
---
---*Action*
function UI.ResumeModCivMusic() end
---**Contexts:** UI
---
---*Action*
function UI.ReleasePauseEvent() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsFixedTiltModeOn() end
---**Contexts:** UI
---
---*Query*
function UI.GridToHex() end
---**Contexts:** UI
---
---*Action*
function UI.ApplyFileQueryPreviewImage() end
---**Contexts:** UI
---
---*Action*
function UI.ClearControl() end
---**Contexts:** UI
---
---*Query*
function UI.GetRegionClusterPositions() end
---**Contexts:** UI
---
---*Action*
function UI.SetARXTagContentByID() end
---**Contexts:** UI
---
---*Action*
function UI.SetCycleAdvanceTimer() end
---**Contexts:** UI
---
---*Query*
function UI.GetVolumes() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectAllCities() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsAtMaxSaveCount() end
---**Contexts:** UI
---
---*Action*
function UI.SetARXTagPropertyByID() end
---**Contexts:** UI
---
---*Action*
function UI.DragMap() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsFinalRelease() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsProcessingMessages() end
---**Contexts:** UI
---
---*Action*
function UI.AddWorldViewText() end
---**Contexts:** UI
---
---*Action*
function UI.PartitionRegions() end
---**Contexts:** UI
---
---*Query*
function UI.GetHeadSelectedUnit() end
---**Contexts:** UI
---
---*Action*
function UI.RemoveTemporaryPlotVisibility() end
---**Contexts:** UI
---
---*Action*
function UI.SelectDistrictID() end
---**Contexts:** UI
---
---*Action*
function UI.ClearAllControls() end
---**Contexts:** UI
---
---*Query*
function UI.GetInterfaceMode() end
---**Contexts:** UI
---
---*Action*
function UI.StartStopMenuMusic() end
---**Contexts:** UI
---
---*Action*
function UI.SkipSong() end
---**Contexts:** UI
---
---*Action*
function UI.SetMinimapImageControl() end
---**Contexts:** UI
---
---*Query*
function UI.DataError() end
---**Contexts:** UI
---
---*Action*
function UI.LookAtPlot() end
---**Contexts:** UI
---
---*Action*
function UI.SetARXTagsPropertyByClass() end
---**Contexts:** UI
---
---*Action*
function UI.DeleteSavedGame() end
---**Contexts:** UI
---
---*Action*
function UI.SetInterfaceMode() end
---**Contexts:** UI
---
---*Action*
function UI.SelectPrevCity() end
---**Contexts:** UI
---
---*Query*
function UI.GetInterfaceModeParameter() end
---**Contexts:** UI
---
---*Action*
function UI.DisableTimeOfDayOverride() end
---**Contexts:** UI
---
---*Query*
function UI.SanitizeText() end
---**Contexts:** UI
---
---*Query*
function UI.SRGBToLinear() end
---**Contexts:** UI
---
---*Action*
function UI.PlayLeaderAnimation() end
---**Contexts:** UI
---
---*Action*
function UI.SetAmbientTimeOfDay() end
---**Contexts:** UI
---
---*Action*
function UI.LineUnitUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsInterfaceTypeVisibile() end
---**Contexts:** UI
---
---*Action*
function UI.PartitionPath() end
---**Contexts:** UI
---
---*Action*
function UI.SelectCityID() end
---**Contexts:** UI
---
---*Query*
function UI.GetCivilizationSoundSwitchValue() end
---**Contexts:** UI
---
---*Query*
function UI.IsDistrictSelected() end
---**Contexts:** UI
---
---*Action*
function UI.TextPlot() end
---**Contexts:** UI
---
---*Query*
function UI.GetNormalizedScreenPosFromPlotCoord() end
---**Contexts:** UI
---
---*Query*
function UI.GetAspyrAppVersion() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsUnitIDSelected() end
---**Contexts:** UI
---
---*Query*
function UI.GetWorldZ() end
---**Contexts:** UI
---
---*Query*
function UI.HexToGrid() end
---**Contexts:** UI
---
---*Action*
function UI.SetMapZoomCurveModifier() end
---**Contexts:** UI
---
---*Action*
function UI.SelectPrevUnit() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsCitySelected() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectAllDistricts() end
---**Contexts:** UI
---
---*Query*
function UI.HexToWorld() end
---**Contexts:** UI
---
---*Action*
function UI.LookAt() end
---**Contexts:** UI
---
---*Action*
function UI.SetGamepadCursorPlotID() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsAnyInterfaceInGroupVisible() end
---**Contexts:** UI
---
---*Query*
---@return boolean  
function UI.IsLeaderAnimated() end
---**Contexts:** UI
---
---*Query*
function UI.QueryGlobalParameterFloat() end
---**Contexts:** UI
---
---*Action*
function UI.ToggleMovementPath() end
---**Contexts:** UI
---
---*Action*
function UI.DeselectDistrictID() end