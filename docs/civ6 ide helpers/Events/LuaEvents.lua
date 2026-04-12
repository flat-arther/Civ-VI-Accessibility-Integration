---@meta


LuaEvents = {}
---@overload fun(popupData: table)
LuaEvents.EventPopupRequest = {}
---*Query*
---@return number amount
function LuaEvents.EventPopupRequest.Count() end
---*Action*
function LuaEvents.EventPopupRequest.RemoveAll() end
---*Action*
---@param popupData table
function LuaEvents.EventPopupRequest.Call(popupData) end
---*Action*
---@param func fun(popupData: table)
---@return fun(popupData: table)
function LuaEvents.EventPopupRequest.Add(func) end
---@param func function
function LuaEvents.EventPopupRequest.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_OpenChooseCivic = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_OpenChooseCivic.Count() end
---*Action*
function LuaEvents.WorldTracker_OpenChooseCivic.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_OpenChooseCivic.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_OpenChooseCivic.Add(func) end
---@param func function
function LuaEvents.WorldTracker_OpenChooseCivic.Remove(func) end

---@overload fun()
LuaEvents.GameDebug_AddValue = {}
---*Query*
---@return number amount
function LuaEvents.GameDebug_AddValue.Count() end
---*Action*
function LuaEvents.GameDebug_AddValue.RemoveAll() end
---*Action*
function LuaEvents.GameDebug_AddValue.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GameDebug_AddValue.Add(func) end
---@param func function
function LuaEvents.GameDebug_AddValue.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_DisableMapDrag = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_DisableMapDrag.Count() end
---*Action*
function LuaEvents.Tutorial_DisableMapDrag.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_DisableMapDrag.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_DisableMapDrag.Add(func) end
---@param func function
function LuaEvents.Tutorial_DisableMapDrag.Remove(func) end

---@overload fun()
LuaEvents.ChatPanel_PlayerTargetChanged = {}
---*Query*
---@return number amount
function LuaEvents.ChatPanel_PlayerTargetChanged.Count() end
---*Action*
function LuaEvents.ChatPanel_PlayerTargetChanged.RemoveAll() end
---*Action*
function LuaEvents.ChatPanel_PlayerTargetChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ChatPanel_PlayerTargetChanged.Add(func) end
---@param func function
function LuaEvents.ChatPanel_PlayerTargetChanged.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_AdvisorLower = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_AdvisorLower.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_AdvisorLower.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_AdvisorLower.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_AdvisorLower.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_AdvisorLower.Remove(func) end

---@overload fun()
LuaEvents.AutomationStart = {}
---*Query*
---@return number amount
function LuaEvents.AutomationStart.Count() end
---*Action*
function LuaEvents.AutomationStart.RemoveAll() end
---*Action*
function LuaEvents.AutomationStart.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationStart.Add(func) end
---@param func function
function LuaEvents.AutomationStart.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_Opened = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_Opened.Count() end
---*Action*
function LuaEvents.GovernorPanel_Opened.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_Opened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_Opened.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_Opened.Remove(func) end

---@overload fun()
LuaEvents.GreatPeopleHeroPanel_SizeChanged = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeopleHeroPanel_SizeChanged.Count() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_SizeChanged.RemoveAll() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_SizeChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeopleHeroPanel_SizeChanged.Add(func) end
---@param func function
function LuaEvents.GreatPeopleHeroPanel_SizeChanged.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_CloseAllLaunchBarScreens = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_CloseAllLaunchBarScreens.Count() end
---*Action*
function LuaEvents.Tutorial_CloseAllLaunchBarScreens.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_CloseAllLaunchBarScreens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_CloseAllLaunchBarScreens.Add(func) end
---@param func function
function LuaEvents.Tutorial_CloseAllLaunchBarScreens.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ChooseProduction = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ChooseProduction.Count() end
---*Action*
function LuaEvents.CityPanel_ChooseProduction.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ChooseProduction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ChooseProduction.Add(func) end
---@param func function
function LuaEvents.CityPanel_ChooseProduction.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenReligionPanel = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenReligionPanel.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenReligionPanel.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenReligionPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenReligionPanel.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenReligionPanel.Remove(func) end

---@overload fun()
LuaEvents.AutomationTestComplete = {}
---*Query*
---@return number amount
function LuaEvents.AutomationTestComplete.Count() end
---*Action*
function LuaEvents.AutomationTestComplete.RemoveAll() end
---*Action*
function LuaEvents.AutomationTestComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationTestComplete.Add(func) end
---@param func function
function LuaEvents.AutomationTestComplete.Remove(func) end

---@overload fun()
LuaEvents.NaturalWonderPopup_Closed = {}
---*Query*
---@return number amount
function LuaEvents.NaturalWonderPopup_Closed.Count() end
---*Action*
function LuaEvents.NaturalWonderPopup_Closed.RemoveAll() end
---*Action*
function LuaEvents.NaturalWonderPopup_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NaturalWonderPopup_Closed.Add(func) end
---@param func function
function LuaEvents.NaturalWonderPopup_Closed.Remove(func) end

---@overload fun()
LuaEvents.DiploPopup_ShowMakeDeal = {}
---*Query*
---@return number amount
function LuaEvents.DiploPopup_ShowMakeDeal.Count() end
---*Action*
function LuaEvents.DiploPopup_ShowMakeDeal.RemoveAll() end
---*Action*
function LuaEvents.DiploPopup_ShowMakeDeal.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploPopup_ShowMakeDeal.Add(func) end
---@param func function
function LuaEvents.DiploPopup_ShowMakeDeal.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseReportsList = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseReportsList.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseReportsList.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseReportsList.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseReportsList.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseReportsList.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_LiveCityDataChanged = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_LiveCityDataChanged.Count() end
---*Action*
function LuaEvents.CityPanel_LiveCityDataChanged.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_LiveCityDataChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_LiveCityDataChanged.Add(func) end
---@param func function
function LuaEvents.CityPanel_LiveCityDataChanged.Remove(func) end

---@overload fun()
LuaEvents.EnterCrossPlayLobby = {}
---*Query*
---@return number amount
function LuaEvents.EnterCrossPlayLobby.Count() end
---*Action*
function LuaEvents.EnterCrossPlayLobby.RemoveAll() end
---*Action*
function LuaEvents.EnterCrossPlayLobby.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EnterCrossPlayLobby.Add(func) end
---@param func function
function LuaEvents.EnterCrossPlayLobby.Remove(func) end

---@overload fun()
LuaEvents.WorldRankings_Close = {}
---*Query*
---@return number amount
function LuaEvents.WorldRankings_Close.Count() end
---*Action*
function LuaEvents.WorldRankings_Close.RemoveAll() end
---*Action*
function LuaEvents.WorldRankings_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldRankings_Close.Add(func) end
---@param func function
function LuaEvents.WorldRankings_Close.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_DragMapEnd = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_DragMapEnd.Count() end
---*Action*
function LuaEvents.WorldInput_DragMapEnd.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_DragMapEnd.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_DragMapEnd.Add(func) end
---@param func function
function LuaEvents.WorldInput_DragMapEnd.Remove(func) end

---@overload fun()
LuaEvents.CloseAnyQueuedMy2KPopup = {}
---*Query*
---@return number amount
function LuaEvents.CloseAnyQueuedMy2KPopup.Count() end
---*Action*
function LuaEvents.CloseAnyQueuedMy2KPopup.RemoveAll() end
---*Action*
function LuaEvents.CloseAnyQueuedMy2KPopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CloseAnyQueuedMy2KPopup.Add(func) end
---@param func function
function LuaEvents.CloseAnyQueuedMy2KPopup.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_SetOverViewState = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_SetOverViewState.Count() end
---*Action*
function LuaEvents.CityPanel_SetOverViewState.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_SetOverViewState.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_SetOverViewState.Add(func) end
---@param func function
function LuaEvents.CityPanel_SetOverViewState.Remove(func) end

---@overload fun()
LuaEvents.ActionPanel_ActivateNotification = {}
---*Query*
---@return number amount
function LuaEvents.ActionPanel_ActivateNotification.Count() end
---*Action*
function LuaEvents.ActionPanel_ActivateNotification.RemoveAll() end
---*Action*
function LuaEvents.ActionPanel_ActivateNotification.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ActionPanel_ActivateNotification.Add(func) end
---@param func function
function LuaEvents.ActionPanel_ActivateNotification.Remove(func) end

---@overload fun()
LuaEvents.FileListQueryComplete = {}
---*Query*
---@return number amount
function LuaEvents.FileListQueryComplete.Count() end
---*Action*
function LuaEvents.FileListQueryComplete.RemoveAll() end
---*Action*
function LuaEvents.FileListQueryComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.FileListQueryComplete.Add(func) end
---@param func function
function LuaEvents.FileListQueryComplete.Remove(func) end

---@overload fun()
LuaEvents.ResearchChooser_RaiseTechTree = {}
---*Query*
---@return number amount
function LuaEvents.ResearchChooser_RaiseTechTree.Count() end
---*Action*
function LuaEvents.ResearchChooser_RaiseTechTree.RemoveAll() end
---*Action*
function LuaEvents.ResearchChooser_RaiseTechTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ResearchChooser_RaiseTechTree.Add(func) end
---@param func function
function LuaEvents.ResearchChooser_RaiseTechTree.Remove(func) end

---@overload fun()
LuaEvents.MapPinPopup_SendPinToChat = {}
---*Query*
---@return number amount
function LuaEvents.MapPinPopup_SendPinToChat.Count() end
---*Action*
function LuaEvents.MapPinPopup_SendPinToChat.RemoveAll() end
---*Action*
function LuaEvents.MapPinPopup_SendPinToChat.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapPinPopup_SendPinToChat.Add(func) end
---@param func function
function LuaEvents.MapPinPopup_SendPinToChat.Remove(func) end

---@overload fun()
LuaEvents.WorldCongress_OpenDiplomacyActionViewLite = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongress_OpenDiplomacyActionViewLite.Count() end
---*Action*
function LuaEvents.WorldCongress_OpenDiplomacyActionViewLite.RemoveAll() end
---*Action*
function LuaEvents.WorldCongress_OpenDiplomacyActionViewLite.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongress_OpenDiplomacyActionViewLite.Add(func) end
---@param func function
function LuaEvents.WorldCongress_OpenDiplomacyActionViewLite.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_TalkToLeader = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_TalkToLeader.Count() end
---*Action*
function LuaEvents.CityBannerManager_TalkToLeader.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_TalkToLeader.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_TalkToLeader.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_TalkToLeader.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenEraProgressPanel = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenEraProgressPanel.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenEraProgressPanel.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenEraProgressPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenEraProgressPanel.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenEraProgressPanel.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_FilterKeysActive = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_FilterKeysActive.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_FilterKeysActive.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_FilterKeysActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_FilterKeysActive.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_FilterKeysActive.Remove(func) end

---@overload fun()
LuaEvents.NewGameInitialized = {}
---*Query*
---@return number amount
function LuaEvents.NewGameInitialized.Count() end
---*Action*
function LuaEvents.NewGameInitialized.RemoveAll() end
---*Action*
function LuaEvents.NewGameInitialized.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NewGameInitialized.Add(func) end
---@param func function
function LuaEvents.NewGameInitialized.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_SetEmergencies = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_SetEmergencies.Count() end
---*Action*
function LuaEvents.WorldTracker_SetEmergencies.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_SetEmergencies.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_SetEmergencies.Add(func) end
---@param func function
function LuaEvents.WorldTracker_SetEmergencies.Remove(func) end

---@overload fun()
LuaEvents.ReportsList_OpenGossip = {}
---*Query*
---@return number amount
function LuaEvents.ReportsList_OpenGossip.Count() end
---*Action*
function LuaEvents.ReportsList_OpenGossip.RemoveAll() end
---*Action*
function LuaEvents.ReportsList_OpenGossip.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ReportsList_OpenGossip.Add(func) end
---@param func function
function LuaEvents.ReportsList_OpenGossip.Remove(func) end

---@overload fun()
LuaEvents.Launchbar_ToggleClimateScreen = {}
---*Query*
---@return number amount
function LuaEvents.Launchbar_ToggleClimateScreen.Count() end
---*Action*
function LuaEvents.Launchbar_ToggleClimateScreen.RemoveAll() end
---*Action*
function LuaEvents.Launchbar_ToggleClimateScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Launchbar_ToggleClimateScreen.Add(func) end
---@param func function
function LuaEvents.Launchbar_ToggleClimateScreen.Remove(func) end

---@overload fun()
LuaEvents.WorldCongress_ShowEmergency = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongress_ShowEmergency.Count() end
---*Action*
function LuaEvents.WorldCongress_ShowEmergency.RemoveAll() end
---*Action*
function LuaEvents.WorldCongress_ShowEmergency.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongress_ShowEmergency.Add(func) end
---@param func function
function LuaEvents.WorldCongress_ShowEmergency.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Count() end
---*Action*
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Add(func) end
---@param func function
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationAdded.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseCityStates = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseCityStates.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseCityStates.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseCityStates.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseCityStates.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseCityStates.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_PurchasePlot = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_PurchasePlot.Count() end
---*Action*
function LuaEvents.CityPanel_PurchasePlot.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_PurchasePlot.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_PurchasePlot.Add(func) end
---@param func function
function LuaEvents.CityPanel_PurchasePlot.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_DisableActionForAll = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_DisableActionForAll.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableActionForAll.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableActionForAll.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_DisableActionForAll.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_DisableActionForAll.Remove(func) end

---@overload fun()
LuaEvents.GovPan_PostOpen = {}
---*Query*
---@return number amount
function LuaEvents.GovPan_PostOpen.Count() end
---*Action*
function LuaEvents.GovPan_PostOpen.RemoveAll() end
---*Action*
function LuaEvents.GovPan_PostOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovPan_PostOpen.Add(func) end
---@param func function
function LuaEvents.GovPan_PostOpen.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenGreatPeoplePopup = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenGreatPeoplePopup.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenGreatPeoplePopup.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ChoosePurchase = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ChoosePurchase.Count() end
---*Action*
function LuaEvents.CityPanel_ChoosePurchase.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ChoosePurchase.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ChoosePurchase.Add(func) end
---@param func function
function LuaEvents.CityPanel_ChoosePurchase.Remove(func) end

---@overload fun()
LuaEvents.TechTree_CloseTechTree = {}
---*Query*
---@return number amount
function LuaEvents.TechTree_CloseTechTree.Count() end
---*Action*
function LuaEvents.TechTree_CloseTechTree.RemoveAll() end
---*Action*
function LuaEvents.TechTree_CloseTechTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechTree_CloseTechTree.Add(func) end
---@param func function
function LuaEvents.TechTree_CloseTechTree.Remove(func) end

---@overload fun()
LuaEvents.AutoProfilerBenchmarkFinished = {}
---*Query*
---@return number amount
function LuaEvents.AutoProfilerBenchmarkFinished.Count() end
---*Action*
function LuaEvents.AutoProfilerBenchmarkFinished.RemoveAll() end
---*Action*
function LuaEvents.AutoProfilerBenchmarkFinished.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutoProfilerBenchmarkFinished.Add(func) end
---@param func function
function LuaEvents.AutoProfilerBenchmarkFinished.Remove(func) end

---@overload fun()
LuaEvents.PlayerChange_Show = {}
---*Query*
---@return number amount
function LuaEvents.PlayerChange_Show.Count() end
---*Action*
function LuaEvents.PlayerChange_Show.RemoveAll() end
---*Action*
function LuaEvents.PlayerChange_Show.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlayerChange_Show.Add(func) end
---@param func function
function LuaEvents.PlayerChange_Show.Remove(func) end

---@overload fun()
LuaEvents.AdvisorPopup_ClearActive = {}
---*Query*
---@return number amount
function LuaEvents.AdvisorPopup_ClearActive.Count() end
---*Action*
function LuaEvents.AdvisorPopup_ClearActive.RemoveAll() end
---*Action*
function LuaEvents.AdvisorPopup_ClearActive.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AdvisorPopup_ClearActive.Add(func) end
---@param func function
function LuaEvents.AdvisorPopup_ClearActive.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ResumeCongress = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ResumeCongress.Count() end
---*Action*
function LuaEvents.NotificationPanel_ResumeCongress.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ResumeCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ResumeCongress.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ResumeCongress.Remove(func) end

---@overload fun()
LuaEvents.MyScreen_Closed = {}
---*Query*
---@return number amount
function LuaEvents.MyScreen_Closed.Count() end
---*Action*
function LuaEvents.MyScreen_Closed.RemoveAll() end
---*Action*
function LuaEvents.MyScreen_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MyScreen_Closed.Add(func) end
---@param func function
function LuaEvents.MyScreen_Closed.Remove(func) end

---@overload fun()
LuaEvents.WorldCrisisTracker_EmergencyClicked = {}
---*Query*
---@return number amount
function LuaEvents.WorldCrisisTracker_EmergencyClicked.Count() end
---*Action*
function LuaEvents.WorldCrisisTracker_EmergencyClicked.RemoveAll() end
---*Action*
function LuaEvents.WorldCrisisTracker_EmergencyClicked.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCrisisTracker_EmergencyClicked.Add(func) end
---@param func function
function LuaEvents.WorldCrisisTracker_EmergencyClicked.Remove(func) end

---@overload fun()
LuaEvents.AutomationGameEnded = {}
---*Query*
---@return number amount
function LuaEvents.AutomationGameEnded.Count() end
---*Action*
function LuaEvents.AutomationGameEnded.RemoveAll() end
---*Action*
function LuaEvents.AutomationGameEnded.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationGameEnded.Add(func) end
---@param func function
function LuaEvents.AutomationGameEnded.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_Open = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_Open.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_Open.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_Open.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_Open.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_Open.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_Realize = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_Realize.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_Realize.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_Realize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_Realize.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_Realize.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenTradeOverview = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenTradeOverview.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenTradeOverview.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenTradeOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenTradeOverview.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenTradeOverview.Remove(func) end

---@overload fun()
LuaEvents.ProductionManager_SelectedIndexChanged = {}
---*Query*
---@return number amount
function LuaEvents.ProductionManager_SelectedIndexChanged.Count() end
---*Action*
function LuaEvents.ProductionManager_SelectedIndexChanged.RemoveAll() end
---*Action*
function LuaEvents.ProductionManager_SelectedIndexChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionManager_SelectedIndexChanged.Add(func) end
---@param func function
function LuaEvents.ProductionManager_SelectedIndexChanged.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_PurchaseGoldOpen = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_PurchaseGoldOpen.Count() end
---*Action*
function LuaEvents.CityPanel_PurchaseGoldOpen.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_PurchaseGoldOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_PurchaseGoldOpen.Add(func) end
---@param func function
function LuaEvents.CityPanel_PurchaseGoldOpen.Remove(func) end

---@overload fun()
LuaEvents.Raise_State_Transition = {}
---*Query*
---@return number amount
function LuaEvents.Raise_State_Transition.Count() end
---*Action*
function LuaEvents.Raise_State_Transition.RemoveAll() end
---*Action*
function LuaEvents.Raise_State_Transition.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Raise_State_Transition.Add(func) end
---@param func function
function LuaEvents.Raise_State_Transition.Remove(func) end

---@overload fun()
LuaEvents.Religion_CloseReligion = {}
---*Query*
---@return number amount
function LuaEvents.Religion_CloseReligion.Count() end
---*Action*
function LuaEvents.Religion_CloseReligion.RemoveAll() end
---*Action*
function LuaEvents.Religion_CloseReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Religion_CloseReligion.Add(func) end
---@param func function
function LuaEvents.Religion_CloseReligion.Remove(func) end

---@overload fun()
LuaEvents.PantheonChooser_CloseReligion = {}
---*Query*
---@return number amount
function LuaEvents.PantheonChooser_CloseReligion.Count() end
---*Action*
function LuaEvents.PantheonChooser_CloseReligion.RemoveAll() end
---*Action*
function LuaEvents.PantheonChooser_CloseReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PantheonChooser_CloseReligion.Add(func) end
---@param func function
function LuaEvents.PantheonChooser_CloseReligion.Remove(func) end

---@overload fun()
LuaEvents.ShowEnemyCityDetails = {}
---*Query*
---@return number amount
function LuaEvents.ShowEnemyCityDetails.Count() end
---*Action*
function LuaEvents.ShowEnemyCityDetails.RemoveAll() end
---*Action*
function LuaEvents.ShowEnemyCityDetails.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ShowEnemyCityDetails.Add(func) end
---@param func function
function LuaEvents.ShowEnemyCityDetails.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderLaunchBar_OpenMapEditor = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.Count() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.Add(func) end
---@param func function
function LuaEvents.WorldBuilderLaunchBar_OpenMapEditor.Remove(func) end

---@overload fun()
LuaEvents.RockBandMoviePopup_OpenRockBandPopup = {}
---*Query*
---@return number amount
function LuaEvents.RockBandMoviePopup_OpenRockBandPopup.Count() end
---*Action*
function LuaEvents.RockBandMoviePopup_OpenRockBandPopup.RemoveAll() end
---*Action*
function LuaEvents.RockBandMoviePopup_OpenRockBandPopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.RockBandMoviePopup_OpenRockBandPopup.Add(func) end
---@param func function
function LuaEvents.RockBandMoviePopup_OpenRockBandPopup.Remove(func) end

---@overload fun()
LuaEvents.ToggleCivilopedia = {}
---*Query*
---@return number amount
function LuaEvents.ToggleCivilopedia.Count() end
---*Action*
function LuaEvents.ToggleCivilopedia.RemoveAll() end
---*Action*
function LuaEvents.ToggleCivilopedia.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ToggleCivilopedia.Add(func) end
---@param func function
function LuaEvents.ToggleCivilopedia.Remove(func) end

---@overload fun()
LuaEvents.GreatPeoplePopup_ClearHeroes = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeoplePopup_ClearHeroes.Count() end
---*Action*
function LuaEvents.GreatPeoplePopup_ClearHeroes.RemoveAll() end
---*Action*
function LuaEvents.GreatPeoplePopup_ClearHeroes.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeoplePopup_ClearHeroes.Add(func) end
---@param func function
function LuaEvents.GreatPeoplePopup_ClearHeroes.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_CityPanelOverview = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_CityPanelOverview.Count() end
---*Action*
function LuaEvents.CityBannerManager_CityPanelOverview.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_CityPanelOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_CityPanelOverview.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_CityPanelOverview.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_SetLoadGameServerType = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_SetLoadGameServerType.Count() end
---*Action*
function LuaEvents.MainMenu_SetLoadGameServerType.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_SetLoadGameServerType.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_SetLoadGameServerType.Add(func) end
---@param func function
function LuaEvents.MainMenu_SetLoadGameServerType.Remove(func) end

---@overload fun()
LuaEvents.GreatPeople_CloseGreatPeople = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeople_CloseGreatPeople.Count() end
---*Action*
function LuaEvents.GreatPeople_CloseGreatPeople.RemoveAll() end
---*Action*
function LuaEvents.GreatPeople_CloseGreatPeople.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeople_CloseGreatPeople.Add(func) end
---@param func function
function LuaEvents.GreatPeople_CloseGreatPeople.Remove(func) end

---@overload fun()
LuaEvents.LeaderPicker_Initialize = {}
---*Query*
---@return number amount
function LuaEvents.LeaderPicker_Initialize.Count() end
---*Action*
function LuaEvents.LeaderPicker_Initialize.RemoveAll() end
---*Action*
function LuaEvents.LeaderPicker_Initialize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LeaderPicker_Initialize.Add(func) end
---@param func function
function LuaEvents.LeaderPicker_Initialize.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerCivicEdited = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerCivicEdited.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerCivicEdited.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerCivicEdited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerCivicEdited.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerCivicEdited.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ViewDiploIntel = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ViewDiploIntel.Count() end
---*Action*
function LuaEvents.Tutorial_ViewDiploIntel.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ViewDiploIntel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ViewDiploIntel.Add(func) end
---@param func function
function LuaEvents.Tutorial_ViewDiploIntel.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_ViewingPlayerDefeat = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_ViewingPlayerDefeat.Count() end
---*Action*
function LuaEvents.EndGameMenu_ViewingPlayerDefeat.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_ViewingPlayerDefeat.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_ViewingPlayerDefeat.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_ViewingPlayerDefeat.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_TouchPlotTooltipShow = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_TouchPlotTooltipShow.Count() end
---*Action*
function LuaEvents.WorldInput_TouchPlotTooltipShow.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_TouchPlotTooltipShow.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_TouchPlotTooltipShow.Add(func) end
---@param func function
function LuaEvents.WorldInput_TouchPlotTooltipShow.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerTechEdited = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerTechEdited.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerTechEdited.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerTechEdited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerTechEdited.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerTechEdited.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_CloseAllPartialScreens = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_CloseAllPartialScreens.Count() end
---*Action*
function LuaEvents.Tutorial_CloseAllPartialScreens.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_CloseAllPartialScreens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_CloseAllPartialScreens.Add(func) end
---@param func function
function LuaEvents.Tutorial_CloseAllPartialScreens.Remove(func) end

---@overload fun()
LuaEvents.HistoricMoments_Opened = {}
---*Query*
---@return number amount
function LuaEvents.HistoricMoments_Opened.Count() end
---*Action*
function LuaEvents.HistoricMoments_Opened.RemoveAll() end
---*Action*
function LuaEvents.HistoricMoments_Opened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HistoricMoments_Opened.Add(func) end
---@param func function
function LuaEvents.HistoricMoments_Opened.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenDisloyalCityChooser = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenDisloyalCityChooser.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenDisloyalCityChooser.Remove(func) end

---@overload fun()
LuaEvents.AutomationGameStarted = {}
---*Query*
---@return number amount
function LuaEvents.AutomationGameStarted.Count() end
---*Action*
function LuaEvents.AutomationGameStarted.RemoveAll() end
---*Action*
function LuaEvents.AutomationGameStarted.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationGameStarted.Add(func) end
---@param func function
function LuaEvents.AutomationGameStarted.Remove(func) end

---@overload fun()
LuaEvents.MyScreen_Opened = {}
---*Query*
---@return number amount
function LuaEvents.MyScreen_Opened.Count() end
---*Action*
function LuaEvents.MyScreen_Opened.RemoveAll() end
---*Action*
function LuaEvents.MyScreen_Opened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MyScreen_Opened.Add(func) end
---@param func function
function LuaEvents.MyScreen_Opened.Remove(func) end

---@overload fun()
LuaEvents.PlotInfo_ShowYieldIcons = {}
---*Query*
---@return number amount
function LuaEvents.PlotInfo_ShowYieldIcons.Count() end
---*Action*
function LuaEvents.PlotInfo_ShowYieldIcons.RemoveAll() end
---*Action*
function LuaEvents.PlotInfo_ShowYieldIcons.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlotInfo_ShowYieldIcons.Add(func) end
---@param func function
function LuaEvents.PlotInfo_ShowYieldIcons.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderToolsPalette_SetTabHeader = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderToolsPalette_SetTabHeader.Count() end
---*Action*
function LuaEvents.WorldBuilderToolsPalette_SetTabHeader.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderToolsPalette_SetTabHeader.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderToolsPalette_SetTabHeader.Add(func) end
---@param func function
function LuaEvents.WorldBuilderToolsPalette_SetTabHeader.Remove(func) end

---@overload fun()
LuaEvents.AdvisorPopup_ShowDetails = {}
---*Query*
---@return number amount
function LuaEvents.AdvisorPopup_ShowDetails.Count() end
---*Action*
function LuaEvents.AdvisorPopup_ShowDetails.RemoveAll() end
---*Action*
function LuaEvents.AdvisorPopup_ShowDetails.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AdvisorPopup_ShowDetails.Add(func) end
---@param func function
function LuaEvents.AdvisorPopup_ShowDetails.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_ShowPiratesIntro = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_ShowPiratesIntro.Count() end
---*Action*
function LuaEvents.MainMenu_ShowPiratesIntro.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_ShowPiratesIntro.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_ShowPiratesIntro.Add(func) end
---@param func function
function LuaEvents.MainMenu_ShowPiratesIntro.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.Count() end
---*Action*
function LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.Add(func) end
---@param func function
function LuaEvents.DiplomacyRibbon_OpenDiplomacyActionView.Remove(func) end

---@overload fun()
LuaEvents.TopPanel_OpenReportsScreen = {}
---*Query*
---@return number amount
function LuaEvents.TopPanel_OpenReportsScreen.Count() end
---*Action*
function LuaEvents.TopPanel_OpenReportsScreen.RemoveAll() end
---*Action*
function LuaEvents.TopPanel_OpenReportsScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TopPanel_OpenReportsScreen.Add(func) end
---@param func function
function LuaEvents.TopPanel_OpenReportsScreen.Remove(func) end

---@overload fun()
LuaEvents.AutomationRunTest = {}
---*Query*
---@return number amount
function LuaEvents.AutomationRunTest.Count() end
---*Action*
function LuaEvents.AutomationRunTest.RemoveAll() end
---*Action*
function LuaEvents.AutomationRunTest.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationRunTest.Add(func) end
---@param func function
function LuaEvents.AutomationRunTest.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_ToggleResearchPanel = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_ToggleResearchPanel.Count() end
---*Action*
function LuaEvents.WorldTracker_ToggleResearchPanel.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_ToggleResearchPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_ToggleResearchPanel.Add(func) end
---@param func function
function LuaEvents.WorldTracker_ToggleResearchPanel.Remove(func) end

---@overload fun()
LuaEvents.RockBandMoviePopup_Closed = {}
---*Query*
---@return number amount
function LuaEvents.RockBandMoviePopup_Closed.Count() end
---*Action*
function LuaEvents.RockBandMoviePopup_Closed.RemoveAll() end
---*Action*
function LuaEvents.RockBandMoviePopup_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.RockBandMoviePopup_Closed.Add(func) end
---@param func function
function LuaEvents.RockBandMoviePopup_Closed.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ResearchOpen = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ResearchOpen.Count() end
---*Action*
function LuaEvents.Tutorial_ResearchOpen.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ResearchOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ResearchOpen.Add(func) end
---@param func function
function LuaEvents.Tutorial_ResearchOpen.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_MakeTradeRouteDestination = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_MakeTradeRouteDestination.Count() end
---*Action*
function LuaEvents.WorldInput_MakeTradeRouteDestination.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_MakeTradeRouteDestination.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_MakeTradeRouteDestination.Add(func) end
---@param func function
function LuaEvents.WorldInput_MakeTradeRouteDestination.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_RemoveUnitMoveRestrictions = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Count() end
---*Action*
function LuaEvents.Tutorial_RemoveUnitMoveRestrictions.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Add(func) end
---@param func function
function LuaEvents.Tutorial_RemoveUnitMoveRestrictions.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderMapTools_SetTabHeader = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderMapTools_SetTabHeader.Count() end
---*Action*
function LuaEvents.WorldBuilderMapTools_SetTabHeader.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderMapTools_SetTabHeader.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderMapTools_SetTabHeader.Add(func) end
---@param func function
function LuaEvents.WorldBuilderMapTools_SetTabHeader.Remove(func) end

---@overload fun()
LuaEvents.PBCNotificationPopup_ShowYourTurn = {}
---*Query*
---@return number amount
function LuaEvents.PBCNotificationPopup_ShowYourTurn.Count() end
---*Action*
function LuaEvents.PBCNotificationPopup_ShowYourTurn.RemoveAll() end
---*Action*
function LuaEvents.PBCNotificationPopup_ShowYourTurn.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PBCNotificationPopup_ShowYourTurn.Add(func) end
---@param func function
function LuaEvents.PBCNotificationPopup_ShowYourTurn.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderRiverHighlight = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderRiverHighlight.Count() end
---*Action*
function LuaEvents.WorldBuilderRiverHighlight.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderRiverHighlight.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderRiverHighlight.Add(func) end
---@param func function
function LuaEvents.WorldBuilderRiverHighlight.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_GoalMarkComplete = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_GoalMarkComplete.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalMarkComplete.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalMarkComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_GoalMarkComplete.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_GoalMarkComplete.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ProductionOpen = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ProductionOpen.Count() end
---*Action*
function LuaEvents.Tutorial_ProductionOpen.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ProductionOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ProductionOpen.Add(func) end
---@param func function
function LuaEvents.Tutorial_ProductionOpen.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_RaiseHostGame = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_RaiseHostGame.Count() end
---*Action*
function LuaEvents.MainMenu_RaiseHostGame.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_RaiseHostGame.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_RaiseHostGame.Add(func) end
---@param func function
function LuaEvents.MainMenu_RaiseHostGame.Remove(func) end

---@overload fun()
LuaEvents.InGame_CloseInGameOptionsMenu = {}
---*Query*
---@return number amount
function LuaEvents.InGame_CloseInGameOptionsMenu.Count() end
---*Action*
function LuaEvents.InGame_CloseInGameOptionsMenu.RemoveAll() end
---*Action*
function LuaEvents.InGame_CloseInGameOptionsMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGame_CloseInGameOptionsMenu.Add(func) end
---@param func function
function LuaEvents.InGame_CloseInGameOptionsMenu.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.Count() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.Add(func) end
---@param func function
function LuaEvents.WorldBuilderLaunchBar_OpenInGameMenu.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_OpenGreatWorksOverview = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_OpenGreatWorksOverview.Count() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatWorksOverview.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatWorksOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_OpenGreatWorksOverview.Add(func) end
---@param func function
function LuaEvents.LaunchBar_OpenGreatWorksOverview.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenWorldCongressProposeEmergencies.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_DisableMapSelect = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_DisableMapSelect.Count() end
---*Action*
function LuaEvents.Tutorial_DisableMapSelect.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_DisableMapSelect.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_DisableMapSelect.Add(func) end
---@param func function
function LuaEvents.Tutorial_DisableMapSelect.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ShowMapEditor = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ShowMapEditor.Count() end
---*Action*
function LuaEvents.WorldBuilder_ShowMapEditor.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ShowMapEditor.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ShowMapEditor.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ShowMapEditor.Remove(func) end

---@overload fun()
LuaEvents.MultiSelectWindow_Initialize = {}
---*Query*
---@return number amount
function LuaEvents.MultiSelectWindow_Initialize.Count() end
---*Action*
function LuaEvents.MultiSelectWindow_Initialize.RemoveAll() end
---*Action*
function LuaEvents.MultiSelectWindow_Initialize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MultiSelectWindow_Initialize.Add(func) end
---@param func function
function LuaEvents.MultiSelectWindow_Initialize.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Count() end
---*Action*
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Add(func) end
---@param func function
function LuaEvents.WorldCongressPopup_OnSpecialSessionNotificationDismissed.Remove(func) end

---@overload fun()
LuaEvents.NaturalWonderPopup_Shown = {}
---*Query*
---@return number amount
function LuaEvents.NaturalWonderPopup_Shown.Count() end
---*Action*
function LuaEvents.NaturalWonderPopup_Shown.RemoveAll() end
---*Action*
function LuaEvents.NaturalWonderPopup_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NaturalWonderPopup_Shown.Add(func) end
---@param func function
function LuaEvents.NaturalWonderPopup_Shown.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_Toggle = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_Toggle.Count() end
---*Action*
function LuaEvents.GovernorPanel_Toggle.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_Toggle.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_Toggle.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_Toggle.Remove(func) end

---@overload fun()
LuaEvents.ProjectBuiltPopup_Shown = {}
---*Query*
---@return number amount
function LuaEvents.ProjectBuiltPopup_Shown.Count() end
---*Action*
function LuaEvents.ProjectBuiltPopup_Shown.RemoveAll() end
---*Action*
function LuaEvents.ProjectBuiltPopup_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProjectBuiltPopup_Shown.Add(func) end
---@param func function
function LuaEvents.ProjectBuiltPopup_Shown.Remove(func) end

---@overload fun()
LuaEvents.HeroesPopup_ShowNewHero = {}
---*Query*
---@return number amount
function LuaEvents.HeroesPopup_ShowNewHero.Count() end
---*Action*
function LuaEvents.HeroesPopup_ShowNewHero.RemoveAll() end
---*Action*
function LuaEvents.HeroesPopup_ShowNewHero.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HeroesPopup_ShowNewHero.Add(func) end
---@param func function
function LuaEvents.HeroesPopup_ShowNewHero.Remove(func) end

---@overload fun()
LuaEvents.TunerEnterDebugMode = {}
---*Query*
---@return number amount
function LuaEvents.TunerEnterDebugMode.Count() end
---*Action*
function LuaEvents.TunerEnterDebugMode.RemoveAll() end
---*Action*
function LuaEvents.TunerEnterDebugMode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TunerEnterDebugMode.Add(func) end
---@param func function
function LuaEvents.TunerEnterDebugMode.Remove(func) end

---@overload fun()
LuaEvents.OnViewPowerLens = {}
---*Query*
---@return number amount
function LuaEvents.OnViewPowerLens.Count() end
---*Action*
function LuaEvents.OnViewPowerLens.RemoveAll() end
---*Action*
function LuaEvents.OnViewPowerLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnViewPowerLens.Add(func) end
---@param func function
function LuaEvents.OnViewPowerLens.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_CinemaSequence = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_CinemaSequence.Count() end
---*Action*
function LuaEvents.DiploScene_CinemaSequence.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_CinemaSequence.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_CinemaSequence.Add(func) end
---@param func function
function LuaEvents.DiploScene_CinemaSequence.Remove(func) end

---@overload fun()
LuaEvents.RockBandMoviePopup_Shown = {}
---*Query*
---@return number amount
function LuaEvents.RockBandMoviePopup_Shown.Count() end
---*Action*
function LuaEvents.RockBandMoviePopup_Shown.RemoveAll() end
---*Action*
function LuaEvents.RockBandMoviePopup_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.RockBandMoviePopup_Shown.Add(func) end
---@param func function
function LuaEvents.RockBandMoviePopup_Shown.Remove(func) end

---@overload fun()
LuaEvents.CivicChooser_ForceHideWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.CivicChooser_ForceHideWorldTracker.Count() end
---*Action*
function LuaEvents.CivicChooser_ForceHideWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.CivicChooser_ForceHideWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicChooser_ForceHideWorldTracker.Add(func) end
---@param func function
function LuaEvents.CivicChooser_ForceHideWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.MultiplayerPopup = {}
---*Query*
---@return number amount
function LuaEvents.MultiplayerPopup.Count() end
---*Action*
function LuaEvents.MultiplayerPopup.RemoveAll() end
---*Action*
function LuaEvents.MultiplayerPopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MultiplayerPopup.Add(func) end
---@param func function
function LuaEvents.MultiplayerPopup.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_HideYieldIcons = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_HideYieldIcons.Count() end
---*Action*
function LuaEvents.Tutorial_HideYieldIcons.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_HideYieldIcons.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_HideYieldIcons.Add(func) end
---@param func function
function LuaEvents.Tutorial_HideYieldIcons.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_RefreshTabs = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_RefreshTabs.Count() end
---*Action*
function LuaEvents.DiploScene_RefreshTabs.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_RefreshTabs.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_RefreshTabs.Add(func) end
---@param func function
function LuaEvents.DiploScene_RefreshTabs.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleManageCitizens = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleManageCitizens.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleManageCitizens.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleManageCitizens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleManageCitizens.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleManageCitizens.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_LeaderSelect = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_LeaderSelect.Count() end
---*Action*
function LuaEvents.DiploScene_LeaderSelect.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_LeaderSelect.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_LeaderSelect.Add(func) end
---@param func function
function LuaEvents.DiploScene_LeaderSelect.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowTechBoost = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowTechBoost.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowTechBoost.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowTechBoost.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowTechBoost.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowTechBoost.Remove(func) end

---@overload fun()
LuaEvents.ReportsList_OpenYields = {}
---*Query*
---@return number amount
function LuaEvents.ReportsList_OpenYields.Count() end
---*Action*
function LuaEvents.ReportsList_OpenYields.RemoveAll() end
---*Action*
function LuaEvents.ReportsList_OpenYields.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ReportsList_OpenYields.Add(func) end
---@param func function
function LuaEvents.ReportsList_OpenYields.Remove(func) end

---@overload fun()
LuaEvents.PlayerChange_Close = {}
---*Query*
---@return number amount
function LuaEvents.PlayerChange_Close.Count() end
---*Action*
function LuaEvents.PlayerChange_Close.RemoveAll() end
---*Action*
function LuaEvents.PlayerChange_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlayerChange_Close.Add(func) end
---@param func function
function LuaEvents.PlayerChange_Close.Remove(func) end

---@overload fun()
LuaEvents.Multiplayer_ExitShell = {}
---*Query*
---@return number amount
function LuaEvents.Multiplayer_ExitShell.Count() end
---*Action*
function LuaEvents.Multiplayer_ExitShell.RemoveAll() end
---*Action*
function LuaEvents.Multiplayer_ExitShell.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Multiplayer_ExitShell.Add(func) end
---@param func function
function LuaEvents.Multiplayer_ExitShell.Remove(func) end

---@overload fun()
LuaEvents.ActionPanel_ObserverModeTurnBegin = {}
---*Query*
---@return number amount
function LuaEvents.ActionPanel_ObserverModeTurnBegin.Count() end
---*Action*
function LuaEvents.ActionPanel_ObserverModeTurnBegin.RemoveAll() end
---*Action*
function LuaEvents.ActionPanel_ObserverModeTurnBegin.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ActionPanel_ObserverModeTurnBegin.Add(func) end
---@param func function
function LuaEvents.ActionPanel_ObserverModeTurnBegin.Remove(func) end

---@overload fun()
LuaEvents.GreatWorks_OpenGreatWorks = {}
---*Query*
---@return number amount
function LuaEvents.GreatWorks_OpenGreatWorks.Count() end
---*Action*
function LuaEvents.GreatWorks_OpenGreatWorks.RemoveAll() end
---*Action*
function LuaEvents.GreatWorks_OpenGreatWorks.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatWorks_OpenGreatWorks.Add(func) end
---@param func function
function LuaEvents.GreatWorks_OpenGreatWorks.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderToolsPalette_ChangeTool = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderToolsPalette_ChangeTool.Count() end
---*Action*
function LuaEvents.WorldBuilderToolsPalette_ChangeTool.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderToolsPalette_ChangeTool.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderToolsPalette_ChangeTool.Add(func) end
---@param func function
function LuaEvents.WorldBuilderToolsPalette_ChangeTool.Remove(func) end

---@overload fun()
LuaEvents.AutoPlayStart = {}
---*Query*
---@return number amount
function LuaEvents.AutoPlayStart.Count() end
---*Action*
function LuaEvents.AutoPlayStart.RemoveAll() end
---*Action*
function LuaEvents.AutoPlayStart.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutoPlayStart.Add(func) end
---@param func function
function LuaEvents.AutoPlayStart.Remove(func) end

---@overload fun()
LuaEvents.CongressButton_ResumeCongress = {}
---*Query*
---@return number amount
function LuaEvents.CongressButton_ResumeCongress.Count() end
---*Action*
function LuaEvents.CongressButton_ResumeCongress.RemoveAll() end
---*Action*
function LuaEvents.CongressButton_ResumeCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CongressButton_ResumeCongress.Add(func) end
---@param func function
function LuaEvents.CongressButton_ResumeCongress.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseCivicsTree.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseCivicsTree.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.OnRaisePopupInGame = {}
---*Query*
---@return number amount
function LuaEvents.OnRaisePopupInGame.Count() end
---*Action*
function LuaEvents.OnRaisePopupInGame.RemoveAll() end
---*Action*
function LuaEvents.OnRaisePopupInGame.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnRaisePopupInGame.Add(func) end
---@param func function
function LuaEvents.OnRaisePopupInGame.Remove(func) end

---@overload fun()
LuaEvents.SetKickPlayer = {}
---*Query*
---@return number amount
function LuaEvents.SetKickPlayer.Count() end
---*Action*
function LuaEvents.SetKickPlayer.RemoveAll() end
---*Action*
function LuaEvents.SetKickPlayer.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.SetKickPlayer.Add(func) end
---@param func function
function LuaEvents.SetKickPlayer.Remove(func) end

---@overload fun()
LuaEvents.MapSearch_PanelClosed = {}
---*Query*
---@return number amount
function LuaEvents.MapSearch_PanelClosed.Count() end
---*Action*
function LuaEvents.MapSearch_PanelClosed.RemoveAll() end
---*Action*
function LuaEvents.MapSearch_PanelClosed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapSearch_PanelClosed.Add(func) end
---@param func function
function LuaEvents.MapSearch_PanelClosed.Remove(func) end

---@overload fun()
LuaEvents.UnitPanel_PromoteUnit = {}
---*Query*
---@return number amount
function LuaEvents.UnitPanel_PromoteUnit.Count() end
---*Action*
function LuaEvents.UnitPanel_PromoteUnit.RemoveAll() end
---*Action*
function LuaEvents.UnitPanel_PromoteUnit.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitPanel_PromoteUnit.Add(func) end
---@param func function
function LuaEvents.UnitPanel_PromoteUnit.Remove(func) end

---@overload fun()
LuaEvents.PantheonChooser_OpenReligion = {}
---*Query*
---@return number amount
function LuaEvents.PantheonChooser_OpenReligion.Count() end
---*Action*
function LuaEvents.PantheonChooser_OpenReligion.RemoveAll() end
---*Action*
function LuaEvents.PantheonChooser_OpenReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PantheonChooser_OpenReligion.Add(func) end
---@param func function
function LuaEvents.PantheonChooser_OpenReligion.Remove(func) end

---@overload fun()
LuaEvents.CityStatePicker_SetParameterValues = {}
---*Query*
---@return number amount
function LuaEvents.CityStatePicker_SetParameterValues.Count() end
---*Action*
function LuaEvents.CityStatePicker_SetParameterValues.RemoveAll() end
---*Action*
function LuaEvents.CityStatePicker_SetParameterValues.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityStatePicker_SetParameterValues.Add(func) end
---@param func function
function LuaEvents.CityStatePicker_SetParameterValues.Remove(func) end

---@overload fun()
LuaEvents.TurnBlockerChooseProduction = {}
---*Query*
---@return number amount
function LuaEvents.TurnBlockerChooseProduction.Count() end
---*Action*
function LuaEvents.TurnBlockerChooseProduction.RemoveAll() end
---*Action*
function LuaEvents.TurnBlockerChooseProduction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TurnBlockerChooseProduction.Add(func) end
---@param func function
function LuaEvents.TurnBlockerChooseProduction.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerAddedRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerAddedRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerAddedRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerAddedRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerAddedRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerAddedRemove.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_ShowAdditionalContent = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_ShowAdditionalContent.Count() end
---*Action*
function LuaEvents.MainMenu_ShowAdditionalContent.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_ShowAdditionalContent.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_ShowAdditionalContent.Add(func) end
---@param func function
function LuaEvents.MainMenu_ShowAdditionalContent.Remove(func) end

---@overload fun()
LuaEvents.SetCityCiv = {}
---*Query*
---@return number amount
function LuaEvents.SetCityCiv.Count() end
---*Action*
function LuaEvents.SetCityCiv.RemoveAll() end
---*Action*
function LuaEvents.SetCityCiv.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.SetCityCiv.Add(func) end
---@param func function
function LuaEvents.SetCityCiv.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_LaunchError = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_LaunchError.Count() end
---*Action*
function LuaEvents.MainMenu_LaunchError.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_LaunchError.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_LaunchError.Add(func) end
---@param func function
function LuaEvents.MainMenu_LaunchError.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderModeChangeRequest = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderModeChangeRequest.Count() end
---*Action*
function LuaEvents.WorldBuilderModeChangeRequest.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderModeChangeRequest.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderModeChangeRequest.Add(func) end
---@param func function
function LuaEvents.WorldBuilderModeChangeRequest.Remove(func) end

---@overload fun()
LuaEvents.Lobby_RaiseHostGame = {}
---*Query*
---@return number amount
function LuaEvents.Lobby_RaiseHostGame.Count() end
---*Action*
function LuaEvents.Lobby_RaiseHostGame.RemoveAll() end
---*Action*
function LuaEvents.Lobby_RaiseHostGame.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Lobby_RaiseHostGame.Add(func) end
---@param func function
function LuaEvents.Lobby_RaiseHostGame.Remove(func) end

---@overload fun()
LuaEvents.JoiningRoom_Showing = {}
---*Query*
---@return number amount
function LuaEvents.JoiningRoom_Showing.Count() end
---*Action*
function LuaEvents.JoiningRoom_Showing.RemoveAll() end
---*Action*
function LuaEvents.JoiningRoom_Showing.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.JoiningRoom_Showing.Add(func) end
---@param func function
function LuaEvents.JoiningRoom_Showing.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenMyScreen = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenMyScreen.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenMyScreen.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenMyScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenMyScreen.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenMyScreen.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerTechEditedRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerTechEditedRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerTechEditedRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerTechEditedRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerTechEditedRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerTechEditedRemove.Remove(func) end

---@overload fun()
LuaEvents.Government_CloseGovernment = {}
---*Query*
---@return number amount
function LuaEvents.Government_CloseGovernment.Count() end
---*Action*
function LuaEvents.Government_CloseGovernment.RemoveAll() end
---*Action*
function LuaEvents.Government_CloseGovernment.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Government_CloseGovernment.Add(func) end
---@param func function
function LuaEvents.Government_CloseGovernment.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_TouchPlotTooltipHide = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_TouchPlotTooltipHide.Count() end
---*Action*
function LuaEvents.WorldInput_TouchPlotTooltipHide.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_TouchPlotTooltipHide.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_TouchPlotTooltipHide.Add(func) end
---@param func function
function LuaEvents.WorldInput_TouchPlotTooltipHide.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_RouteConsidered = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_RouteConsidered.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_RouteConsidered.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_RouteConsidered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_RouteConsidered.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_RouteConsidered.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseMyScreen = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseMyScreen.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseMyScreen.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseMyScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseMyScreen.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseMyScreen.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_GoalAdd = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_GoalAdd.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalAdd.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalAdd.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_GoalAdd.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_GoalAdd.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_EmergencyClicked = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_EmergencyClicked.Count() end
---*Action*
function LuaEvents.NotificationPanel_EmergencyClicked.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_EmergencyClicked.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_EmergencyClicked.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_EmergencyClicked.Remove(func) end

---@overload fun()
LuaEvents.HistoricMoments_Closed = {}
---*Query*
---@return number amount
function LuaEvents.HistoricMoments_Closed.Count() end
---*Action*
function LuaEvents.HistoricMoments_Closed.RemoveAll() end
---*Action*
function LuaEvents.HistoricMoments_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HistoricMoments_Closed.Add(func) end
---@param func function
function LuaEvents.HistoricMoments_Closed.Remove(func) end

---@overload fun()
LuaEvents.TechCivicCompletedPopup_CivicShown = {}
---*Query*
---@return number amount
function LuaEvents.TechCivicCompletedPopup_CivicShown.Count() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_CivicShown.RemoveAll() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_CivicShown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechCivicCompletedPopup_CivicShown.Add(func) end
---@param func function
function LuaEvents.TechCivicCompletedPopup_CivicShown.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowReligionTab = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowReligionTab.Count() end
---*Action*
function LuaEvents.CityPanel_ShowReligionTab.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowReligionTab.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowReligionTab.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowReligionTab.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PaintOpCompleted = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PaintOpCompleted.Count() end
---*Action*
function LuaEvents.WorldBuilder_PaintOpCompleted.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PaintOpCompleted.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PaintOpCompleted.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PaintOpCompleted.Remove(func) end

---@overload fun()
LuaEvents.GlobalReportsList_OpenResources = {}
---*Query*
---@return number amount
function LuaEvents.GlobalReportsList_OpenResources.Count() end
---*Action*
function LuaEvents.GlobalReportsList_OpenResources.RemoveAll() end
---*Action*
function LuaEvents.GlobalReportsList_OpenResources.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GlobalReportsList_OpenResources.Add(func) end
---@param func function
function LuaEvents.GlobalReportsList_OpenResources.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_SecretSocietyJoined = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_SecretSocietyJoined.Count() end
---*Action*
function LuaEvents.NotificationPanel_SecretSocietyJoined.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_SecretSocietyJoined.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_SecretSocietyJoined.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_SecretSocietyJoined.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_SetMinimapSize = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_SetMinimapSize.Count() end
---*Action*
function LuaEvents.WorldTracker_SetMinimapSize.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_SetMinimapSize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_SetMinimapSize.Add(func) end
---@param func function
function LuaEvents.WorldTracker_SetMinimapSize.Remove(func) end

---@overload fun()
LuaEvents.TradeOriginChooser_SetTradeUnitStatus = {}
---*Query*
---@return number amount
function LuaEvents.TradeOriginChooser_SetTradeUnitStatus.Count() end
---*Action*
function LuaEvents.TradeOriginChooser_SetTradeUnitStatus.RemoveAll() end
---*Action*
function LuaEvents.TradeOriginChooser_SetTradeUnitStatus.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeOriginChooser_SetTradeUnitStatus.Add(func) end
---@param func function
function LuaEvents.TradeOriginChooser_SetTradeUnitStatus.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowBreakdownTab = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowBreakdownTab.Count() end
---*Action*
function LuaEvents.CityPanel_ShowBreakdownTab.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowBreakdownTab.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowBreakdownTab.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowBreakdownTab.Remove(func) end

---@overload fun()
LuaEvents.EspionageChooser_ShowMissionBriefing = {}
---*Query*
---@return number amount
function LuaEvents.EspionageChooser_ShowMissionBriefing.Count() end
---*Action*
function LuaEvents.EspionageChooser_ShowMissionBriefing.RemoveAll() end
---*Action*
function LuaEvents.EspionageChooser_ShowMissionBriefing.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EspionageChooser_ShowMissionBriefing.Add(func) end
---@param func function
function LuaEvents.EspionageChooser_ShowMissionBriefing.Remove(func) end

---@overload fun()
LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType = {}
---*Query*
---@return number amount
function LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.Count() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.RemoveAll() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.Add(func) end
---@param func function
function LuaEvents.InGameTopOptionsMenu_SetLoadGameServerType.Remove(func) end

---@overload fun()
LuaEvents.DiploPopup_ShowMakeDemand = {}
---*Query*
---@return number amount
function LuaEvents.DiploPopup_ShowMakeDemand.Count() end
---*Action*
function LuaEvents.DiploPopup_ShowMakeDemand.RemoveAll() end
---*Action*
function LuaEvents.DiploPopup_ShowMakeDemand.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploPopup_ShowMakeDemand.Add(func) end
---@param func function
function LuaEvents.DiploPopup_ShowMakeDemand.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenPantheonChooser = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenPantheonChooser.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenPantheonChooser.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenPantheonChooser.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenPantheonChooser.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenPantheonChooser.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_ShowEnemyCityOverview = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_ShowEnemyCityOverview.Count() end
---*Action*
function LuaEvents.CityBannerManager_ShowEnemyCityOverview.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_ShowEnemyCityOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_ShowEnemyCityOverview.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_ShowEnemyCityOverview.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseTechTree = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseTechTree.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseTechTree.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseTechTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseTechTree.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseTechTree.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_ProductionToggle = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_ProductionToggle.Count() end
---*Action*
function LuaEvents.CityBannerManager_ProductionToggle.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_ProductionToggle.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_ProductionToggle.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_ProductionToggle.Remove(func) end

---@overload fun()
LuaEvents.TunerExitDebugMode = {}
---*Query*
---@return number amount
function LuaEvents.TunerExitDebugMode.Count() end
---*Action*
function LuaEvents.TunerExitDebugMode.RemoveAll() end
---*Action*
function LuaEvents.TunerExitDebugMode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TunerExitDebugMode.Add(func) end
---@param func function
function LuaEvents.TunerExitDebugMode.Remove(func) end

---@overload fun()
LuaEvents.GovernmentScreen_PolicyTabOpen = {}
---*Query*
---@return number amount
function LuaEvents.GovernmentScreen_PolicyTabOpen.Count() end
---*Action*
function LuaEvents.GovernmentScreen_PolicyTabOpen.RemoveAll() end
---*Action*
function LuaEvents.GovernmentScreen_PolicyTabOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernmentScreen_PolicyTabOpen.Add(func) end
---@param func function
function LuaEvents.GovernmentScreen_PolicyTabOpen.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_SetTradeUnitStatus = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_SetTradeUnitStatus.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_SetTradeUnitStatus.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_SetTradeUnitStatus.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_SetTradeUnitStatus.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_SetTradeUnitStatus.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_OpenGreatWorksShowcase = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_OpenGreatWorksShowcase.Count() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatWorksShowcase.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatWorksShowcase.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_OpenGreatWorksShowcase.Add(func) end
---@param func function
function LuaEvents.LaunchBar_OpenGreatWorksShowcase.Remove(func) end

---@overload fun()
LuaEvents.UnitFlagManager_PointerExited = {}
---*Query*
---@return number amount
function LuaEvents.UnitFlagManager_PointerExited.Count() end
---*Action*
function LuaEvents.UnitFlagManager_PointerExited.RemoveAll() end
---*Action*
function LuaEvents.UnitFlagManager_PointerExited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitFlagManager_PointerExited.Add(func) end
---@param func function
function LuaEvents.UnitFlagManager_PointerExited.Remove(func) end

---@overload fun()
LuaEvents.PiratesIntro_StartMatchMaking = {}
---*Query*
---@return number amount
function LuaEvents.PiratesIntro_StartMatchMaking.Count() end
---*Action*
function LuaEvents.PiratesIntro_StartMatchMaking.RemoveAll() end
---*Action*
function LuaEvents.PiratesIntro_StartMatchMaking.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PiratesIntro_StartMatchMaking.Add(func) end
---@param func function
function LuaEvents.PiratesIntro_StartMatchMaking.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseGreatPeoplePopup = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseGreatPeoplePopup.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseGreatPeoplePopup.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseGreatPeoplePopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseGreatPeoplePopup.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseGreatPeoplePopup.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_ConfirmWarDialog = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_ConfirmWarDialog.Count() end
---*Action*
function LuaEvents.WorldInput_ConfirmWarDialog.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_ConfirmWarDialog.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_ConfirmWarDialog.Add(func) end
---@param func function
function LuaEvents.WorldInput_ConfirmWarDialog.Remove(func) end

---@overload fun()
LuaEvents.AutomationComplete = {}
---*Query*
---@return number amount
function LuaEvents.AutomationComplete.Count() end
---*Action*
function LuaEvents.AutomationComplete.RemoveAll() end
---*Action*
function LuaEvents.AutomationComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationComplete.Add(func) end
---@param func function
function LuaEvents.AutomationComplete.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_ToggleManager = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_ToggleManager.Count() end
---*Action*
function LuaEvents.ProductionPanel_ToggleManager.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_ToggleManager.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_ToggleManager.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_ToggleManager.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenEspionageEscape = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenEspionageEscape.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenEspionageEscape.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenEspionageEscape.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenEspionageEscape.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenEspionageEscape.Remove(func) end

---@overload fun()
LuaEvents.AutoPlayEnd = {}
---*Query*
---@return number amount
function LuaEvents.AutoPlayEnd.Count() end
---*Action*
function LuaEvents.AutoPlayEnd.RemoveAll() end
---*Action*
function LuaEvents.AutoPlayEnd.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutoPlayEnd.Add(func) end
---@param func function
function LuaEvents.AutoPlayEnd.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_RaiseTechTree = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_RaiseTechTree.Count() end
---*Action*
function LuaEvents.LaunchBar_RaiseTechTree.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_RaiseTechTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_RaiseTechTree.Add(func) end
---@param func function
function LuaEvents.LaunchBar_RaiseTechTree.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_ListModeChanged = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_ListModeChanged.Count() end
---*Action*
function LuaEvents.ProductionPanel_ListModeChanged.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_ListModeChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_ListModeChanged.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_ListModeChanged.Remove(func) end

---@overload fun()
LuaEvents.PrideMoments_ToggleTimeline = {}
---*Query*
---@return number amount
function LuaEvents.PrideMoments_ToggleTimeline.Count() end
---*Action*
function LuaEvents.PrideMoments_ToggleTimeline.RemoveAll() end
---*Action*
function LuaEvents.PrideMoments_ToggleTimeline.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PrideMoments_ToggleTimeline.Add(func) end
---@param func function
function LuaEvents.PrideMoments_ToggleTimeline.Remove(func) end

---@overload fun()
LuaEvents.DiploPopup_DealUpdated = {}
---*Query*
---@return number amount
function LuaEvents.DiploPopup_DealUpdated.Count() end
---*Action*
function LuaEvents.DiploPopup_DealUpdated.RemoveAll() end
---*Action*
function LuaEvents.DiploPopup_DealUpdated.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploPopup_DealUpdated.Add(func) end
---@param func function
function LuaEvents.DiploPopup_DealUpdated.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_Resize = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_Resize.Count() end
---*Action*
function LuaEvents.LaunchBar_Resize.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_Resize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_Resize.Add(func) end
---@param func function
function LuaEvents.LaunchBar_Resize.Remove(func) end

---@overload fun()
LuaEvents.EspionagePopup_MissionBriefingClosed = {}
---*Query*
---@return number amount
function LuaEvents.EspionagePopup_MissionBriefingClosed.Count() end
---*Action*
function LuaEvents.EspionagePopup_MissionBriefingClosed.RemoveAll() end
---*Action*
function LuaEvents.EspionagePopup_MissionBriefingClosed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EspionagePopup_MissionBriefingClosed.Add(func) end
---@param func function
function LuaEvents.EspionagePopup_MissionBriefingClosed.Remove(func) end

---@overload fun()
LuaEvents.CityPanelCulture_ToggleLoyalty = {}
---*Query*
---@return number amount
function LuaEvents.CityPanelCulture_ToggleLoyalty.Count() end
---*Action*
function LuaEvents.CityPanelCulture_ToggleLoyalty.RemoveAll() end
---*Action*
function LuaEvents.CityPanelCulture_ToggleLoyalty.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanelCulture_ToggleLoyalty.Add(func) end
---@param func function
function LuaEvents.CityPanelCulture_ToggleLoyalty.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_MakeTradeRouteDestination = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_MakeTradeRouteDestination.Count() end
---*Action*
function LuaEvents.CityBannerManager_MakeTradeRouteDestination.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_MakeTradeRouteDestination.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_MakeTradeRouteDestination.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_MakeTradeRouteDestination.Remove(func) end

---@overload fun()
LuaEvents.RelicScreen_RelicScreenOpened = {}
---*Query*
---@return number amount
function LuaEvents.RelicScreen_RelicScreenOpened.Count() end
---*Action*
function LuaEvents.RelicScreen_RelicScreenOpened.RemoveAll() end
---*Action*
function LuaEvents.RelicScreen_RelicScreenOpened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.RelicScreen_RelicScreenOpened.Add(func) end
---@param func function
function LuaEvents.RelicScreen_RelicScreenOpened.Remove(func) end

---@overload fun()
LuaEvents.GreatPeopleHeroPanel_Show = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeopleHeroPanel_Show.Count() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_Show.RemoveAll() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_Show.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeopleHeroPanel_Show.Add(func) end
---@param func function
function LuaEvents.GreatPeopleHeroPanel_Show.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Count() end
---*Action*
function LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Add(func) end
---@param func function
function LuaEvents.WorldCongressPopup_ShowWorldCongressBetweenTurns.Remove(func) end

---@overload fun()
LuaEvents.ActionPanel_OpenChooseResearch = {}
---*Query*
---@return number amount
function LuaEvents.ActionPanel_OpenChooseResearch.Count() end
---*Action*
function LuaEvents.ActionPanel_OpenChooseResearch.RemoveAll() end
---*Action*
function LuaEvents.ActionPanel_OpenChooseResearch.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ActionPanel_OpenChooseResearch.Add(func) end
---@param func function
function LuaEvents.ActionPanel_OpenChooseResearch.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_OpenManager = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_OpenManager.Count() end
---*Action*
function LuaEvents.ProductionPanel_OpenManager.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_OpenManager.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_OpenManager.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_OpenManager.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ContinentTypeEdited = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ContinentTypeEdited.Count() end
---*Action*
function LuaEvents.WorldBuilder_ContinentTypeEdited.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ContinentTypeEdited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ContinentTypeEdited.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ContinentTypeEdited.Remove(func) end

---@overload fun()
LuaEvents.ReportsList_OpenResources = {}
---*Query*
---@return number amount
function LuaEvents.ReportsList_OpenResources.Count() end
---*Action*
function LuaEvents.ReportsList_OpenResources.RemoveAll() end
---*Action*
function LuaEvents.ReportsList_OpenResources.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ReportsList_OpenResources.Add(func) end
---@param func function
function LuaEvents.ReportsList_OpenResources.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ExitFSMap = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ExitFSMap.Count() end
---*Action*
function LuaEvents.WorldBuilder_ExitFSMap.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ExitFSMap.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ExitFSMap.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ExitFSMap.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowRelicCreated = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowRelicCreated.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowRelicCreated.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowRelicCreated.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowRelicCreated.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowRelicCreated.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseGreatWorksOverview = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseGreatWorksOverview.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseGreatWorksOverview.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseGreatWorksOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseGreatWorksOverview.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseGreatWorksOverview.Remove(func) end

---@overload fun()
LuaEvents.TunerMapRButtonDown = {}
---*Query*
---@return number amount
function LuaEvents.TunerMapRButtonDown.Count() end
---*Action*
function LuaEvents.TunerMapRButtonDown.RemoveAll() end
---*Action*
function LuaEvents.TunerMapRButtonDown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TunerMapRButtonDown.Add(func) end
---@param func function
function LuaEvents.TunerMapRButtonDown.Remove(func) end

---@overload fun()
LuaEvents.ReportsList_OpenCityStatus = {}
---*Query*
---@return number amount
function LuaEvents.ReportsList_OpenCityStatus.Count() end
---*Action*
function LuaEvents.ReportsList_OpenCityStatus.RemoveAll() end
---*Action*
function LuaEvents.ReportsList_OpenCityStatus.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ReportsList_OpenCityStatus.Add(func) end
---@param func function
function LuaEvents.ReportsList_OpenCityStatus.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_DisableActions = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_DisableActions.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableActions.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableActions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_DisableActions.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_DisableActions.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_SceneOpened = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_SceneOpened.Count() end
---*Action*
function LuaEvents.DiploScene_SceneOpened.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_SceneOpened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_SceneOpened.Add(func) end
---@param func function
function LuaEvents.DiploScene_SceneOpened.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_OpenOverview = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_OpenOverview.Count() end
---*Action*
function LuaEvents.CityPanel_OpenOverview.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_OpenOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_OpenOverview.Add(func) end
---@param func function
function LuaEvents.CityPanel_OpenOverview.Remove(func) end

---@overload fun()
LuaEvents.EraProgressPanel_Close = {}
---*Query*
---@return number amount
function LuaEvents.EraProgressPanel_Close.Count() end
---*Action*
function LuaEvents.EraProgressPanel_Close.RemoveAll() end
---*Action*
function LuaEvents.EraProgressPanel_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EraProgressPanel_Close.Add(func) end
---@param func function
function LuaEvents.EraProgressPanel_Close.Remove(func) end

---@overload fun()
LuaEvents.NaturalDisasterPopup_Closed = {}
---*Query*
---@return number amount
function LuaEvents.NaturalDisasterPopup_Closed.Count() end
---*Action*
function LuaEvents.NaturalDisasterPopup_Closed.RemoveAll() end
---*Action*
function LuaEvents.NaturalDisasterPopup_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NaturalDisasterPopup_Closed.Add(func) end
---@param func function
function LuaEvents.NaturalDisasterPopup_Closed.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ViewDiploRelationship = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ViewDiploRelationship.Count() end
---*Action*
function LuaEvents.Tutorial_ViewDiploRelationship.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ViewDiploRelationship.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ViewDiploRelationship.Add(func) end
---@param func function
function LuaEvents.Tutorial_ViewDiploRelationship.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_ChatContainerSizeChanged = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_ChatContainerSizeChanged.Count() end
---*Action*
function LuaEvents.WorldTracker_ChatContainerSizeChanged.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_ChatContainerSizeChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_ChatContainerSizeChanged.Add(func) end
---@param func function
function LuaEvents.WorldTracker_ChatContainerSizeChanged.Remove(func) end

---@overload fun()
LuaEvents.HostGame_ShowStagingRoom = {}
---*Query*
---@return number amount
function LuaEvents.HostGame_ShowStagingRoom.Count() end
---*Action*
function LuaEvents.HostGame_ShowStagingRoom.RemoveAll() end
---*Action*
function LuaEvents.HostGame_ShowStagingRoom.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HostGame_ShowStagingRoom.Add(func) end
---@param func function
function LuaEvents.HostGame_ShowStagingRoom.Remove(func) end

---@overload fun()
LuaEvents.RefreshTechBoostList = {}
---*Query*
---@return number amount
function LuaEvents.RefreshTechBoostList.Count() end
---*Action*
function LuaEvents.RefreshTechBoostList.RemoveAll() end
---*Action*
function LuaEvents.RefreshTechBoostList.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.RefreshTechBoostList.Add(func) end
---@param func function
function LuaEvents.RefreshTechBoostList.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_WBMouseOverPlot = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_WBMouseOverPlot.Count() end
---*Action*
function LuaEvents.WorldInput_WBMouseOverPlot.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_WBMouseOverPlot.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_WBMouseOverPlot.Add(func) end
---@param func function
function LuaEvents.WorldInput_WBMouseOverPlot.Remove(func) end

---@overload fun()
LuaEvents.Government_OpenGovernment = {}
---*Query*
---@return number amount
function LuaEvents.Government_OpenGovernment.Count() end
---*Action*
function LuaEvents.Government_OpenGovernment.RemoveAll() end
---*Action*
function LuaEvents.Government_OpenGovernment.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Government_OpenGovernment.Add(func) end
---@param func function
function LuaEvents.Government_OpenGovernment.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_HideCongress = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_HideCongress.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_HideCongress.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_HideCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_HideCongress.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_HideCongress.Remove(func) end

---@overload fun()
LuaEvents.UIDebugModeEntered = {}
---*Query*
---@return number amount
function LuaEvents.UIDebugModeEntered.Count() end
---*Action*
function LuaEvents.UIDebugModeEntered.RemoveAll() end
---*Action*
function LuaEvents.UIDebugModeEntered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UIDebugModeEntered.Add(func) end
---@param func function
function LuaEvents.UIDebugModeEntered.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ClearAllUnitHexRestrictions = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ClearAllUnitHexRestrictions.Count() end
---*Action*
function LuaEvents.Tutorial_ClearAllUnitHexRestrictions.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ClearAllUnitHexRestrictions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ClearAllUnitHexRestrictions.Add(func) end
---@param func function
function LuaEvents.Tutorial_ClearAllUnitHexRestrictions.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CheckPopupsOpen = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CheckPopupsOpen.Count() end
---*Action*
function LuaEvents.LaunchBar_CheckPopupsOpen.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CheckPopupsOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CheckPopupsOpen.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CheckPopupsOpen.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerRemoved = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerRemoved.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerRemoved.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerRemoved.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerRemoved.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerRemoved.Remove(func) end

---@overload fun()
LuaEvents.PBCNotificationPopup_ShowUnseenComplete = {}
---*Query*
---@return number amount
function LuaEvents.PBCNotificationPopup_ShowUnseenComplete.Count() end
---*Action*
function LuaEvents.PBCNotificationPopup_ShowUnseenComplete.RemoveAll() end
---*Action*
function LuaEvents.PBCNotificationPopup_ShowUnseenComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PBCNotificationPopup_ShowUnseenComplete.Add(func) end
---@param func function
function LuaEvents.PBCNotificationPopup_ShowUnseenComplete.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_WBSelectPlot = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_WBSelectPlot.Count() end
---*Action*
function LuaEvents.WorldInput_WBSelectPlot.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_WBSelectPlot.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_WBSelectPlot.Add(func) end
---@param func function
function LuaEvents.WorldInput_WBSelectPlot.Remove(func) end

---@overload fun()
LuaEvents.WorldRankings_CloseCityStates = {}
---*Query*
---@return number amount
function LuaEvents.WorldRankings_CloseCityStates.Count() end
---*Action*
function LuaEvents.WorldRankings_CloseCityStates.RemoveAll() end
---*Action*
function LuaEvents.WorldRankings_CloseCityStates.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldRankings_CloseCityStates.Add(func) end
---@param func function
function LuaEvents.WorldRankings_CloseCityStates.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_RefreshOverviewRows = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_RefreshOverviewRows.Count() end
---*Action*
function LuaEvents.DiploScene_RefreshOverviewRows.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_RefreshOverviewRows.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_RefreshOverviewRows.Add(func) end
---@param func function
function LuaEvents.DiploScene_RefreshOverviewRows.Remove(func) end

---@overload fun()
LuaEvents.JoiningRoom_ShowStagingRoom = {}
---*Query*
---@return number amount
function LuaEvents.JoiningRoom_ShowStagingRoom.Count() end
---*Action*
function LuaEvents.JoiningRoom_ShowStagingRoom.RemoveAll() end
---*Action*
function LuaEvents.JoiningRoom_ShowStagingRoom.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.JoiningRoom_ShowStagingRoom.Add(func) end
---@param func function
function LuaEvents.JoiningRoom_ShowStagingRoom.Remove(func) end

---@overload fun()
LuaEvents.StartKickVote = {}
---*Query*
---@return number amount
function LuaEvents.StartKickVote.Count() end
---*Action*
function LuaEvents.StartKickVote.RemoveAll() end
---*Action*
function LuaEvents.StartKickVote.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StartKickVote.Add(func) end
---@param func function
function LuaEvents.StartKickVote.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_ReOpen = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_ReOpen.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_ReOpen.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_ReOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_ReOpen.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_ReOpen.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_AssignDetails = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_AssignDetails.Count() end
---*Action*
function LuaEvents.GovernorPanel_AssignDetails.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_AssignDetails.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_AssignDetails.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_AssignDetails.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_OnSetMinimapCollapsed = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_OnSetMinimapCollapsed.Count() end
---*Action*
function LuaEvents.WorldTracker_OnSetMinimapCollapsed.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_OnSetMinimapCollapsed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_OnSetMinimapCollapsed.Add(func) end
---@param func function
function LuaEvents.WorldTracker_OnSetMinimapCollapsed.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ShowPlayerEditorRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ShowPlayerEditorRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_ShowPlayerEditorRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ShowPlayerEditorRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ShowPlayerEditorRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ShowPlayerEditorRemove.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressBetweenTurns_ResumeCongress = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Count() end
---*Action*
function LuaEvents.WorldCongressBetweenTurns_ResumeCongress.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Add(func) end
---@param func function
function LuaEvents.WorldCongressBetweenTurns_ResumeCongress.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_DisableSettleHintLens = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_DisableSettleHintLens.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableSettleHintLens.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableSettleHintLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_DisableSettleHintLens.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_DisableSettleHintLens.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_HideWorldPointer = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_HideWorldPointer.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_HideWorldPointer.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_HideWorldPointer.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_HideWorldPointer.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_HideWorldPointer.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowOverviewPanel = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowOverviewPanel.Count() end
---*Action*
function LuaEvents.CityPanel_ShowOverviewPanel.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowOverviewPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowOverviewPanel.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowOverviewPanel.Remove(func) end

---@overload fun()
LuaEvents.StagingRoom_EnsureHostGame = {}
---*Query*
---@return number amount
function LuaEvents.StagingRoom_EnsureHostGame.Count() end
---*Action*
function LuaEvents.StagingRoom_EnsureHostGame.RemoveAll() end
---*Action*
function LuaEvents.StagingRoom_EnsureHostGame.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StagingRoom_EnsureHostGame.Add(func) end
---@param func function
function LuaEvents.StagingRoom_EnsureHostGame.Remove(func) end

---@overload fun()
LuaEvents.CivicsChooser_RaiseCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.CivicsChooser_RaiseCivicsTree.Count() end
---*Action*
function LuaEvents.CivicsChooser_RaiseCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.CivicsChooser_RaiseCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicsChooser_RaiseCivicsTree.Add(func) end
---@param func function
function LuaEvents.CivicsChooser_RaiseCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.GreatWorkCreated_OpenGreatWorksOverview = {}
---*Query*
---@return number amount
function LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Count() end
---*Action*
function LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.RemoveAll() end
---*Action*
function LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Add(func) end
---@param func function
function LuaEvents.GreatWorkCreated_OpenGreatWorksOverview.Remove(func) end

---@overload fun()
LuaEvents.PlotInfo_UpdatePlotTooltip = {}
---*Query*
---@return number amount
function LuaEvents.PlotInfo_UpdatePlotTooltip.Count() end
---*Action*
function LuaEvents.PlotInfo_UpdatePlotTooltip.RemoveAll() end
---*Action*
function LuaEvents.PlotInfo_UpdatePlotTooltip.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlotInfo_UpdatePlotTooltip.Add(func) end
---@param func function
function LuaEvents.PlotInfo_UpdatePlotTooltip.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseEspionage = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseEspionage.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseEspionage.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseEspionage.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseEspionage.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseEspionage.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_CloseDiploActionView = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_CloseDiploActionView.Count() end
---*Action*
function LuaEvents.Tutorial_CloseDiploActionView.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_CloseDiploActionView.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_CloseDiploActionView.Add(func) end
---@param func function
function LuaEvents.Tutorial_CloseDiploActionView.Remove(func) end

---@overload fun()
LuaEvents.CityStatePicker_SetParameterValue = {}
---*Query*
---@return number amount
function LuaEvents.CityStatePicker_SetParameterValue.Count() end
---*Action*
function LuaEvents.CityStatePicker_SetParameterValue.RemoveAll() end
---*Action*
function LuaEvents.CityStatePicker_SetParameterValue.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityStatePicker_SetParameterValue.Add(func) end
---@param func function
function LuaEvents.CityStatePicker_SetParameterValue.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ViewDiploAccessLevel = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ViewDiploAccessLevel.Count() end
---*Action*
function LuaEvents.Tutorial_ViewDiploAccessLevel.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ViewDiploAccessLevel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ViewDiploAccessLevel.Add(func) end
---@param func function
function LuaEvents.Tutorial_ViewDiploAccessLevel.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenEspionage = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenEspionage.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenEspionage.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenEspionage.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenEspionage.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenEspionage.Remove(func) end

---@overload fun()
LuaEvents.ActionPanel_EndObserverMode = {}
---*Query*
---@return number amount
function LuaEvents.ActionPanel_EndObserverMode.Count() end
---*Action*
function LuaEvents.ActionPanel_EndObserverMode.RemoveAll() end
---*Action*
function LuaEvents.ActionPanel_EndObserverMode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ActionPanel_EndObserverMode.Add(func) end
---@param func function
function LuaEvents.ActionPanel_EndObserverMode.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_GoalAutoRemove = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_GoalAutoRemove.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalAutoRemove.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalAutoRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_GoalAutoRemove.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_GoalAutoRemove.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleOverviewPower = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleOverviewPower.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewPower.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewPower.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleOverviewPower.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleOverviewPower.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_Open = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_Open.Count() end
---*Action*
function LuaEvents.ProductionPanel_Open.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_Open.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_Open.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_Open.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenCityStatesSendEnvoys.Remove(func) end

---@overload fun()
LuaEvents.TutorialGoals_Showing = {}
---*Query*
---@return number amount
function LuaEvents.TutorialGoals_Showing.Count() end
---*Action*
function LuaEvents.TutorialGoals_Showing.RemoveAll() end
---*Action*
function LuaEvents.TutorialGoals_Showing.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialGoals_Showing.Add(func) end
---@param func function
function LuaEvents.TutorialGoals_Showing.Remove(func) end

---@overload fun()
LuaEvents.Launchbar_Expansion2_ClimateScreen_Close = {}
---*Query*
---@return number amount
function LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.Count() end
---*Action*
function LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.RemoveAll() end
---*Action*
function LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.Add(func) end
---@param func function
function LuaEvents.Launchbar_Expansion2_ClimateScreen_Close.Remove(func) end

---@overload fun()
LuaEvents.EraReviewPopup_Show = {}
---*Query*
---@return number amount
function LuaEvents.EraReviewPopup_Show.Count() end
---*Action*
function LuaEvents.EraReviewPopup_Show.RemoveAll() end
---*Action*
function LuaEvents.EraReviewPopup_Show.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EraReviewPopup_Show.Add(func) end
---@param func function
function LuaEvents.EraReviewPopup_Show.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_GoalRemove = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_GoalRemove.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalRemove.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_GoalRemove.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_GoalRemove.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowAmenitiesTab = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowAmenitiesTab.Count() end
---*Action*
function LuaEvents.CityPanel_ShowAmenitiesTab.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowAmenitiesTab.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowAmenitiesTab.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowAmenitiesTab.Remove(func) end

---@overload fun()
LuaEvents.TutorialGoals_Hiding = {}
---*Query*
---@return number amount
function LuaEvents.TutorialGoals_Hiding.Count() end
---*Action*
function LuaEvents.TutorialGoals_Hiding.RemoveAll() end
---*Action*
function LuaEvents.TutorialGoals_Hiding.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialGoals_Hiding.Add(func) end
---@param func function
function LuaEvents.TutorialGoals_Hiding.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ProductionClose = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ProductionClose.Count() end
---*Action*
function LuaEvents.CityPanel_ProductionClose.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ProductionClose.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ProductionClose.Add(func) end
---@param func function
function LuaEvents.CityPanel_ProductionClose.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_AdvisorRaise = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_AdvisorRaise.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_AdvisorRaise.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_AdvisorRaise.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_AdvisorRaise.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_AdvisorRaise.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowCitizensTab = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowCitizensTab.Count() end
---*Action*
function LuaEvents.CityPanel_ShowCitizensTab.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowCitizensTab.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowCitizensTab.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowCitizensTab.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenWorldRankingsCulture.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenArtifactPanel = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenArtifactPanel.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenArtifactPanel.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenArtifactPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenArtifactPanel.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenArtifactPanel.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_SlowNextTurnEnable = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_SlowNextTurnEnable.Count() end
---*Action*
function LuaEvents.Tutorial_SlowNextTurnEnable.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_SlowNextTurnEnable.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_SlowNextTurnEnable.Add(func) end
---@param func function
function LuaEvents.Tutorial_SlowNextTurnEnable.Remove(func) end

---@overload fun()
LuaEvents.OpenCivilopedia = {}
---*Query*
---@return number amount
function LuaEvents.OpenCivilopedia.Count() end
---*Action*
function LuaEvents.OpenCivilopedia.RemoveAll() end
---*Action*
function LuaEvents.OpenCivilopedia.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OpenCivilopedia.Add(func) end
---@param func function
function LuaEvents.OpenCivilopedia.Remove(func) end

---@overload fun()
LuaEvents.UnitFlagManager_PointerEntered = {}
---*Query*
---@return number amount
function LuaEvents.UnitFlagManager_PointerEntered.Count() end
---*Action*
function LuaEvents.UnitFlagManager_PointerEntered.RemoveAll() end
---*Action*
function LuaEvents.UnitFlagManager_PointerEntered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitFlagManager_PointerEntered.Add(func) end
---@param func function
function LuaEvents.UnitFlagManager_PointerEntered.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_GovernmentOpenPolicies = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_GovernmentOpenPolicies.Count() end
---*Action*
function LuaEvents.NotificationPanel_GovernmentOpenPolicies.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_GovernmentOpenPolicies.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_GovernmentOpenPolicies.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_GovernmentOpenPolicies.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleOverviewLoyalty = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleOverviewLoyalty.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewLoyalty.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewLoyalty.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleOverviewLoyalty.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleOverviewLoyalty.Remove(func) end

---@overload fun()
LuaEvents.Religion_OpenReligion = {}
---*Query*
---@return number amount
function LuaEvents.Religion_OpenReligion.Count() end
---*Action*
function LuaEvents.Religion_OpenReligion.RemoveAll() end
---*Action*
function LuaEvents.Religion_OpenReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Religion_OpenReligion.Add(func) end
---@param func function
function LuaEvents.Religion_OpenReligion.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ShowHousingTab = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ShowHousingTab.Count() end
---*Action*
function LuaEvents.CityPanel_ShowHousingTab.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ShowHousingTab.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ShowHousingTab.Add(func) end
---@param func function
function LuaEvents.CityPanel_ShowHousingTab.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_RaiseMinorCivPanel = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_RaiseMinorCivPanel.Count() end
---*Action*
function LuaEvents.CityBannerManager_RaiseMinorCivPanel.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_RaiseMinorCivPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_RaiseMinorCivPanel.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_RaiseMinorCivPanel.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseReligionPanel = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseReligionPanel.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseReligionPanel.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseReligionPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseReligionPanel.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseReligionPanel.Remove(func) end

---@overload fun()
LuaEvents.OnViewReligionLens = {}
---*Query*
---@return number amount
function LuaEvents.OnViewReligionLens.Count() end
---*Action*
function LuaEvents.OnViewReligionLens.RemoveAll() end
---*Action*
function LuaEvents.OnViewReligionLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnViewReligionLens.Add(func) end
---@param func function
function LuaEvents.OnViewReligionLens.Remove(func) end

---@overload fun()
LuaEvents.CityStatePicker_Initialize = {}
---*Query*
---@return number amount
function LuaEvents.CityStatePicker_Initialize.Count() end
---*Action*
function LuaEvents.CityStatePicker_Initialize.RemoveAll() end
---*Action*
function LuaEvents.CityStatePicker_Initialize.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityStatePicker_Initialize.Add(func) end
---@param func function
function LuaEvents.CityStatePicker_Initialize.Remove(func) end

---@overload fun()
LuaEvents.EditHotseatPlayer_UpdatePlayer = {}
---*Query*
---@return number amount
function LuaEvents.EditHotseatPlayer_UpdatePlayer.Count() end
---*Action*
function LuaEvents.EditHotseatPlayer_UpdatePlayer.RemoveAll() end
---*Action*
function LuaEvents.EditHotseatPlayer_UpdatePlayer.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EditHotseatPlayer_UpdatePlayer.Add(func) end
---@param func function
function LuaEvents.EditHotseatPlayer_UpdatePlayer.Remove(func) end

---@overload fun()
LuaEvents.DiploPopup_TalkToLeader = {}
---*Query*
---@return number amount
function LuaEvents.DiploPopup_TalkToLeader.Count() end
---*Action*
function LuaEvents.DiploPopup_TalkToLeader.RemoveAll() end
---*Action*
function LuaEvents.DiploPopup_TalkToLeader.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploPopup_TalkToLeader.Add(func) end
---@param func function
function LuaEvents.DiploPopup_TalkToLeader.Remove(func) end

---@overload fun()
LuaEvents.UpdateFiraxisLiveState = {}
---*Query*
---@return number amount
function LuaEvents.UpdateFiraxisLiveState.Count() end
---*Action*
function LuaEvents.UpdateFiraxisLiveState.RemoveAll() end
---*Action*
function LuaEvents.UpdateFiraxisLiveState.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UpdateFiraxisLiveState.Add(func) end
---@param func function
function LuaEvents.UpdateFiraxisLiveState.Remove(func) end

---@overload fun()
LuaEvents.GovernorDetailsPanel_OpenDetails = {}
---*Query*
---@return number amount
function LuaEvents.GovernorDetailsPanel_OpenDetails.Count() end
---*Action*
function LuaEvents.GovernorDetailsPanel_OpenDetails.RemoveAll() end
---*Action*
function LuaEvents.GovernorDetailsPanel_OpenDetails.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorDetailsPanel_OpenDetails.Add(func) end
---@param func function
function LuaEvents.GovernorDetailsPanel_OpenDetails.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_CityPanelOpen = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_CityPanelOpen.Count() end
---*Action*
function LuaEvents.Tutorial_CityPanelOpen.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_CityPanelOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_CityPanelOpen.Add(func) end
---@param func function
function LuaEvents.Tutorial_CityPanelOpen.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ShowMapEditorRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ShowMapEditorRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_ShowMapEditorRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ShowMapEditorRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ShowMapEditorRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ShowMapEditorRemove.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ModeChanged = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ModeChanged.Count() end
---*Action*
function LuaEvents.WorldBuilder_ModeChanged.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ModeChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ModeChanged.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ModeChanged.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_UserNotificationActivate = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_UserNotificationActivate.Count() end
---*Action*
function LuaEvents.NotificationPanel_UserNotificationActivate.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_UserNotificationActivate.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_UserNotificationActivate.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_UserNotificationActivate.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_OpenTreatWithTribePopup = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Count() end
---*Action*
function LuaEvents.CityBannerManager_OpenTreatWithTribePopup.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_OpenTreatWithTribePopup.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_GrievanceTalkToLeader = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_GrievanceTalkToLeader.Count() end
---*Action*
function LuaEvents.NotificationPanel_GrievanceTalkToLeader.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_GrievanceTalkToLeader.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_GrievanceTalkToLeader.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_GrievanceTalkToLeader.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerEditedRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerEditedRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerEditedRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerEditedRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerEditedRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerEditedRemove.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_CloseManager = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_CloseManager.Count() end
---*Action*
function LuaEvents.ProductionPanel_CloseManager.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_CloseManager.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_CloseManager.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_CloseManager.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerRemovedRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerRemovedRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerRemovedRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerRemovedRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerRemovedRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerRemovedRemove.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_ClosePantheonChooser = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_ClosePantheonChooser.Count() end
---*Action*
function LuaEvents.LaunchBar_ClosePantheonChooser.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_ClosePantheonChooser.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_ClosePantheonChooser.Add(func) end
---@param func function
function LuaEvents.LaunchBar_ClosePantheonChooser.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_ToggleWorldRankings = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_ToggleWorldRankings.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_ToggleWorldRankings.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_ToggleWorldRankings.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_ToggleWorldRankings.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_ToggleWorldRankings.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_UserRequestClose = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_UserRequestClose.Count() end
---*Action*
function LuaEvents.MainMenu_UserRequestClose.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_UserRequestClose.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_UserRequestClose.Add(func) end
---@param func function
function LuaEvents.MainMenu_UserRequestClose.Remove(func) end

---@overload fun()
LuaEvents.FileListQueryResults = {}
---*Query*
---@return number amount
function LuaEvents.FileListQueryResults.Count() end
---*Action*
function LuaEvents.FileListQueryResults.RemoveAll() end
---*Action*
function LuaEvents.FileListQueryResults.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.FileListQueryResults.Add(func) end
---@param func function
function LuaEvents.FileListQueryResults.Remove(func) end

---@overload fun()
LuaEvents.AutomationAppUpdateComplete = {}
---*Query*
---@return number amount
function LuaEvents.AutomationAppUpdateComplete.Count() end
---*Action*
function LuaEvents.AutomationAppUpdateComplete.RemoveAll() end
---*Action*
function LuaEvents.AutomationAppUpdateComplete.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationAppUpdateComplete.Add(func) end
---@param func function
function LuaEvents.AutomationAppUpdateComplete.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_Expansion1_ToggleEraProgress.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_AddUnitHexRestriction = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_AddUnitHexRestriction.Count() end
---*Action*
function LuaEvents.Tutorial_AddUnitHexRestriction.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_AddUnitHexRestriction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_AddUnitHexRestriction.Add(func) end
---@param func function
function LuaEvents.Tutorial_AddUnitHexRestriction.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseAllExcept = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseAllExcept.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseAllExcept.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseAllExcept.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseAllExcept.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseAllExcept.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ProductionOpenForQueue = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ProductionOpenForQueue.Count() end
---*Action*
function LuaEvents.CityPanel_ProductionOpenForQueue.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ProductionOpenForQueue.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ProductionOpenForQueue.Add(func) end
---@param func function
function LuaEvents.CityPanel_ProductionOpenForQueue.Remove(func) end

---@overload fun()
LuaEvents.TunerMapLButtonUp = {}
---*Query*
---@return number amount
function LuaEvents.TunerMapLButtonUp.Count() end
---*Action*
function LuaEvents.TunerMapLButtonUp.RemoveAll() end
---*Action*
function LuaEvents.TunerMapLButtonUp.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TunerMapLButtonUp.Add(func) end
---@param func function
function LuaEvents.TunerMapLButtonUp.Remove(func) end

---@overload fun()
LuaEvents.ClimateScreen_Opened = {}
---*Query*
---@return number amount
function LuaEvents.ClimateScreen_Opened.Count() end
---*Action*
function LuaEvents.ClimateScreen_Opened.RemoveAll() end
---*Action*
function LuaEvents.ClimateScreen_Opened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ClimateScreen_Opened.Add(func) end
---@param func function
function LuaEvents.ClimateScreen_Opened.Remove(func) end

---@overload fun()
LuaEvents.UIDebugModeExited = {}
---*Query*
---@return number amount
function LuaEvents.UIDebugModeExited.Count() end
---*Action*
function LuaEvents.UIDebugModeExited.RemoveAll() end
---*Action*
function LuaEvents.UIDebugModeExited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UIDebugModeExited.Add(func) end
---@param func function
function LuaEvents.UIDebugModeExited.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_PlotToolTipsOn = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_PlotToolTipsOn.Count() end
---*Action*
function LuaEvents.Tutorial_PlotToolTipsOn.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_PlotToolTipsOn.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_PlotToolTipsOn.Add(func) end
---@param func function
function LuaEvents.Tutorial_PlotToolTipsOn.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenRazeCityChooser = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenRazeCityChooser.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenRazeCityChooser.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenRazeCityChooser.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenRazeCityChooser.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenRazeCityChooser.Remove(func) end

---@overload fun()
LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies = {}
---*Query*
---@return number amount
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies.Count() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies.RemoveAll() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies.Add(func) end
---@param func function
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenPolicies.Remove(func) end

---@overload fun()
LuaEvents.NaturalDisasterPopup_Shown = {}
---*Query*
---@return number amount
function LuaEvents.NaturalDisasterPopup_Shown.Count() end
---*Action*
function LuaEvents.NaturalDisasterPopup_Shown.RemoveAll() end
---*Action*
function LuaEvents.NaturalDisasterPopup_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NaturalDisasterPopup_Shown.Add(func) end
---@param func function
function LuaEvents.NaturalDisasterPopup_Shown.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_HeroDiscovered = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_HeroDiscovered.Count() end
---*Action*
function LuaEvents.NotificationPanel_HeroDiscovered.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_HeroDiscovered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_HeroDiscovered.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_HeroDiscovered.Remove(func) end

---@overload fun()
LuaEvents.ChatPanel_OnShown = {}
---*Query*
---@return number amount
function LuaEvents.ChatPanel_OnShown.Count() end
---*Action*
function LuaEvents.ChatPanel_OnShown.RemoveAll() end
---*Action*
function LuaEvents.ChatPanel_OnShown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ChatPanel_OnShown.Add(func) end
---@param func function
function LuaEvents.ChatPanel_OnShown.Remove(func) end

---@overload fun()
LuaEvents.ActionPanel_OpenChooseCivic = {}
---*Query*
---@return number amount
function LuaEvents.ActionPanel_OpenChooseCivic.Count() end
---*Action*
function LuaEvents.ActionPanel_OpenChooseCivic.RemoveAll() end
---*Action*
function LuaEvents.ActionPanel_OpenChooseCivic.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ActionPanel_OpenChooseCivic.Add(func) end
---@param func function
function LuaEvents.ActionPanel_OpenChooseCivic.Remove(func) end

---@overload fun()
LuaEvents.HostGame_SetLoadGameServerType = {}
---*Query*
---@return number amount
function LuaEvents.HostGame_SetLoadGameServerType.Count() end
---*Action*
function LuaEvents.HostGame_SetLoadGameServerType.RemoveAll() end
---*Action*
function LuaEvents.HostGame_SetLoadGameServerType.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HostGame_SetLoadGameServerType.Add(func) end
---@param func function
function LuaEvents.HostGame_SetLoadGameServerType.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_ResumeCongress = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_ResumeCongress.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_ResumeCongress.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_ResumeCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_ResumeCongress.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_ResumeCongress.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ForceHideWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ForceHideWorldTracker.Count() end
---*Action*
function LuaEvents.Tutorial_ForceHideWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ForceHideWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ForceHideWorldTracker.Add(func) end
---@param func function
function LuaEvents.Tutorial_ForceHideWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes = {}
---*Query*
---@return number amount
function LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes.Count() end
---*Action*
function LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes.RemoveAll() end
---*Action*
function LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes.Add(func) end
---@param func function
function LuaEvents.StrategicView_MapPlacement_ClearDistrictPlacementShadowHexes.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowCivicBoost = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowCivicBoost.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowCivicBoost.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowCivicBoost.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowCivicBoost.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowCivicBoost.Remove(func) end

---@overload fun()
LuaEvents.GovernorAssignmentChooser_Close = {}
---*Query*
---@return number amount
function LuaEvents.GovernorAssignmentChooser_Close.Count() end
---*Action*
function LuaEvents.GovernorAssignmentChooser_Close.RemoveAll() end
---*Action*
function LuaEvents.GovernorAssignmentChooser_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorAssignmentChooser_Close.Add(func) end
---@param func function
function LuaEvents.GovernorAssignmentChooser_Close.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerAdded = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerAdded.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerAdded.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerAdded.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerAdded.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerAdded.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_ConfirmWarDialog = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_ConfirmWarDialog.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_ConfirmWarDialog.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_ConfirmWarDialog.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_ConfirmWarDialog.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_ConfirmWarDialog.Remove(func) end

---@overload fun()
LuaEvents.DiploBasePopup_HideUI = {}
---*Query*
---@return number amount
function LuaEvents.DiploBasePopup_HideUI.Count() end
---*Action*
function LuaEvents.DiploBasePopup_HideUI.RemoveAll() end
---*Action*
function LuaEvents.DiploBasePopup_HideUI.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploBasePopup_HideUI.Add(func) end
---@param func function
function LuaEvents.DiploBasePopup_HideUI.Remove(func) end

---@overload fun()
LuaEvents.PlotInfo_HideYieldIcons = {}
---*Query*
---@return number amount
function LuaEvents.PlotInfo_HideYieldIcons.Count() end
---*Action*
function LuaEvents.PlotInfo_HideYieldIcons.RemoveAll() end
---*Action*
function LuaEvents.PlotInfo_HideYieldIcons.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlotInfo_HideYieldIcons.Add(func) end
---@param func function
function LuaEvents.PlotInfo_HideYieldIcons.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_Close = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_Close.Count() end
---*Action*
function LuaEvents.GovernorPanel_Close.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_Close.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_Close.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_ClosedDetails = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_ClosedDetails.Count() end
---*Action*
function LuaEvents.GovernorPanel_ClosedDetails.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_ClosedDetails.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_ClosedDetails.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_ClosedDetails.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_HideIngameUI = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_HideIngameUI.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_HideIngameUI.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_HideIngameUI.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_HideIngameUI.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_HideIngameUI.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ShowYieldIcons = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ShowYieldIcons.Count() end
---*Action*
function LuaEvents.Tutorial_ShowYieldIcons.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ShowYieldIcons.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ShowYieldIcons.Add(func) end
---@param func function
function LuaEvents.Tutorial_ShowYieldIcons.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_HeroExpired = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_HeroExpired.Count() end
---*Action*
function LuaEvents.NotificationPanel_HeroExpired.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_HeroExpired.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_HeroExpired.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_HeroExpired.Remove(func) end

---@overload fun()
LuaEvents.GreatPeopleHeroPanel_Close = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeopleHeroPanel_Close.Count() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_Close.RemoveAll() end
---*Action*
function LuaEvents.GreatPeopleHeroPanel_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeopleHeroPanel_Close.Add(func) end
---@param func function
function LuaEvents.GreatPeopleHeroPanel_Close.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_ShowIngameUI = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_ShowIngameUI.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_ShowIngameUI.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_ShowIngameUI.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_ShowIngameUI.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_ShowIngameUI.Remove(func) end

---@overload fun()
LuaEvents.MinimapPanel_ToggleGrid = {}
---*Query*
---@return number amount
function LuaEvents.MinimapPanel_ToggleGrid.Count() end
---*Action*
function LuaEvents.MinimapPanel_ToggleGrid.RemoveAll() end
---*Action*
function LuaEvents.MinimapPanel_ToggleGrid.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MinimapPanel_ToggleGrid.Add(func) end
---@param func function
function LuaEvents.MinimapPanel_ToggleGrid.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_DisableMapCancel = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_DisableMapCancel.Count() end
---*Action*
function LuaEvents.Tutorial_DisableMapCancel.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_DisableMapCancel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_DisableMapCancel.Add(func) end
---@param func function
function LuaEvents.Tutorial_DisableMapCancel.Remove(func) end

---@overload fun()
LuaEvents.CityStates_ConfirmWarDialog = {}
---*Query*
---@return number amount
function LuaEvents.CityStates_ConfirmWarDialog.Count() end
---*Action*
function LuaEvents.CityStates_ConfirmWarDialog.RemoveAll() end
---*Action*
function LuaEvents.CityStates_ConfirmWarDialog.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityStates_ConfirmWarDialog.Add(func) end
---@param func function
function LuaEvents.CityStates_ConfirmWarDialog.Remove(func) end

---@overload fun()
LuaEvents.CityBannerManager_UpdateRangeStrike = {}
---*Query*
---@return number amount
function LuaEvents.CityBannerManager_UpdateRangeStrike.Count() end
---*Action*
function LuaEvents.CityBannerManager_UpdateRangeStrike.RemoveAll() end
---*Action*
function LuaEvents.CityBannerManager_UpdateRangeStrike.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityBannerManager_UpdateRangeStrike.Add(func) end
---@param func function
function LuaEvents.CityBannerManager_UpdateRangeStrike.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_IsQueueOpen = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_IsQueueOpen.Count() end
---*Action*
function LuaEvents.ProductionPanel_IsQueueOpen.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_IsQueueOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_IsQueueOpen.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_IsQueueOpen.Remove(func) end

---@overload fun()
LuaEvents.Advisor_ToggleTimeline = {}
---*Query*
---@return number amount
function LuaEvents.Advisor_ToggleTimeline.Count() end
---*Action*
function LuaEvents.Advisor_ToggleTimeline.RemoveAll() end
---*Action*
function LuaEvents.Advisor_ToggleTimeline.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Advisor_ToggleTimeline.Add(func) end
---@param func function
function LuaEvents.Advisor_ToggleTimeline.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_OpenGreatPeoplePopup = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_OpenGreatPeoplePopup.Count() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatPeoplePopup.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_OpenGreatPeoplePopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_OpenGreatPeoplePopup.Add(func) end
---@param func function
function LuaEvents.LaunchBar_OpenGreatPeoplePopup.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_OpenWorldCongressResults = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_OpenWorldCongressResults.Count() end
---*Action*
function LuaEvents.NotificationPanel_OpenWorldCongressResults.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_OpenWorldCongressResults.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_OpenWorldCongressResults.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_OpenWorldCongressResults.Remove(func) end

---@overload fun()
LuaEvents.WorldCongress_OpenDiplomacyActionView = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongress_OpenDiplomacyActionView.Count() end
---*Action*
function LuaEvents.WorldCongress_OpenDiplomacyActionView.RemoveAll() end
---*Action*
function LuaEvents.WorldCongress_OpenDiplomacyActionView.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongress_OpenDiplomacyActionView.Add(func) end
---@param func function
function LuaEvents.WorldCongress_OpenDiplomacyActionView.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_FilterKeysDisabled = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_FilterKeysDisabled.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_FilterKeysDisabled.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_FilterKeysDisabled.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_FilterKeysDisabled.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_FilterKeysDisabled.Remove(func) end

---@overload fun()
LuaEvents.CityPanelTabRefresh = {}
---*Query*
---@return number amount
function LuaEvents.CityPanelTabRefresh.Count() end
---*Action*
function LuaEvents.CityPanelTabRefresh.RemoveAll() end
---*Action*
function LuaEvents.CityPanelTabRefresh.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanelTabRefresh.Add(func) end
---@param func function
function LuaEvents.CityPanelTabRefresh.Remove(func) end

---@overload fun()
LuaEvents.CityPanelOverview_Opened = {}
---*Query*
---@return number amount
function LuaEvents.CityPanelOverview_Opened.Count() end
---*Action*
function LuaEvents.CityPanelOverview_Opened.RemoveAll() end
---*Action*
function LuaEvents.CityPanelOverview_Opened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanelOverview_Opened.Add(func) end
---@param func function
function LuaEvents.CityPanelOverview_Opened.Remove(func) end

---@overload fun()
LuaEvents.TradeOverview_SelectRouteFromOverview = {}
---*Query*
---@return number amount
function LuaEvents.TradeOverview_SelectRouteFromOverview.Count() end
---*Action*
function LuaEvents.TradeOverview_SelectRouteFromOverview.RemoveAll() end
---*Action*
function LuaEvents.TradeOverview_SelectRouteFromOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeOverview_SelectRouteFromOverview.Add(func) end
---@param func function
function LuaEvents.TradeOverview_SelectRouteFromOverview.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenCityStates = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenCityStates.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenCityStates.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenCityStates.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenCityStates.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenCityStates.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_CancelManagerSelection = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_CancelManagerSelection.Count() end
---*Action*
function LuaEvents.ProductionPanel_CancelManagerSelection.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_CancelManagerSelection.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_CancelManagerSelection.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_CancelManagerSelection.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ClearAllHexMoveRestrictions = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Count() end
---*Action*
function LuaEvents.Tutorial_ClearAllHexMoveRestrictions.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Add(func) end
---@param func function
function LuaEvents.Tutorial_ClearAllHexMoveRestrictions.Remove(func) end

---@overload fun()
LuaEvents.FullscreenMap_Closed = {}
---*Query*
---@return number amount
function LuaEvents.FullscreenMap_Closed.Count() end
---*Action*
function LuaEvents.FullscreenMap_Closed.RemoveAll() end
---*Action*
function LuaEvents.FullscreenMap_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.FullscreenMap_Closed.Add(func) end
---@param func function
function LuaEvents.FullscreenMap_Closed.Remove(func) end

---@overload fun()
LuaEvents.OnViewPlagueLens = {}
---*Query*
---@return number amount
function LuaEvents.OnViewPlagueLens.Count() end
---*Action*
function LuaEvents.OnViewPlagueLens.RemoveAll() end
---*Action*
function LuaEvents.OnViewPlagueLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnViewPlagueLens.Add(func) end
---@param func function
function LuaEvents.OnViewPlagueLens.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerCivicEditedRemove = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerCivicEditedRemove.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerCivicEditedRemove.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerCivicEditedRemove.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerCivicEditedRemove.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerCivicEditedRemove.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_ShowWorldPointer = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_ShowWorldPointer.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_ShowWorldPointer.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_ShowWorldPointer.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_ShowWorldPointer.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_ShowWorldPointer.Remove(func) end

---@overload fun()
LuaEvents.MinimapPanel_RefreshMinimapOptions = {}
---*Query*
---@return number amount
function LuaEvents.MinimapPanel_RefreshMinimapOptions.Count() end
---*Action*
function LuaEvents.MinimapPanel_RefreshMinimapOptions.RemoveAll() end
---*Action*
function LuaEvents.MinimapPanel_RefreshMinimapOptions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MinimapPanel_RefreshMinimapOptions.Add(func) end
---@param func function
function LuaEvents.MinimapPanel_RefreshMinimapOptions.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowCivicDiscovered = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowCivicDiscovered.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowCivicDiscovered.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowCivicDiscovered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowCivicDiscovered.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowCivicDiscovered.Remove(func) end

---@overload fun()
LuaEvents.InGame_OpenInGameOptionsMenu = {}
---*Query*
---@return number amount
function LuaEvents.InGame_OpenInGameOptionsMenu.Count() end
---*Action*
function LuaEvents.InGame_OpenInGameOptionsMenu.RemoveAll() end
---*Action*
function LuaEvents.InGame_OpenInGameOptionsMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGame_OpenInGameOptionsMenu.Add(func) end
---@param func function
function LuaEvents.InGame_OpenInGameOptionsMenu.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ContextDisableItems = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ContextDisableItems.Count() end
---*Action*
function LuaEvents.Tutorial_ContextDisableItems.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ContextDisableItems.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ContextDisableItems.Add(func) end
---@param func function
function LuaEvents.Tutorial_ContextDisableItems.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_PurchaseFaithOpen = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_PurchaseFaithOpen.Count() end
---*Action*
function LuaEvents.CityPanel_PurchaseFaithOpen.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_PurchaseFaithOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_PurchaseFaithOpen.Add(func) end
---@param func function
function LuaEvents.CityPanel_PurchaseFaithOpen.Remove(func) end

---@overload fun()
LuaEvents.GameDebug_Return = {}
---*Query*
---@return number amount
function LuaEvents.GameDebug_Return.Count() end
---*Action*
function LuaEvents.GameDebug_Return.RemoveAll() end
---*Action*
function LuaEvents.GameDebug_Return.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GameDebug_Return.Add(func) end
---@param func function
function LuaEvents.GameDebug_Return.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_OnChatShown = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_OnChatShown.Count() end
---*Action*
function LuaEvents.WorldTracker_OnChatShown.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_OnChatShown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_OnChatShown.Add(func) end
---@param func function
function LuaEvents.WorldTracker_OnChatShown.Remove(func) end

---@overload fun()
LuaEvents.ClimateScreen_Closed = {}
---*Query*
---@return number amount
function LuaEvents.ClimateScreen_Closed.Count() end
---*Action*
function LuaEvents.ClimateScreen_Closed.RemoveAll() end
---*Action*
function LuaEvents.ClimateScreen_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ClimateScreen_Closed.Add(func) end
---@param func function
function LuaEvents.ClimateScreen_Closed.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseGovernmentPanel = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseGovernmentPanel.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseGovernmentPanel.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseGovernmentPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseGovernmentPanel.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseGovernmentPanel.Remove(func) end

---@overload fun()
LuaEvents.LeaderPicker_SetParameterValues = {}
---*Query*
---@return number amount
function LuaEvents.LeaderPicker_SetParameterValues.Count() end
---*Action*
function LuaEvents.LeaderPicker_SetParameterValues.RemoveAll() end
---*Action*
function LuaEvents.LeaderPicker_SetParameterValues.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LeaderPicker_SetParameterValues.Add(func) end
---@param func function
function LuaEvents.LeaderPicker_SetParameterValues.Remove(func) end

---@overload fun()
LuaEvents.TechTree_OpenTechTree = {}
---*Query*
---@return number amount
function LuaEvents.TechTree_OpenTechTree.Count() end
---*Action*
function LuaEvents.TechTree_OpenTechTree.RemoveAll() end
---*Action*
function LuaEvents.TechTree_OpenTechTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechTree_OpenTechTree.Add(func) end
---@param func function
function LuaEvents.TechTree_OpenTechTree.Remove(func) end

---@overload fun()
LuaEvents.AutomationStopTest = {}
---*Query*
---@return number amount
function LuaEvents.AutomationStopTest.Count() end
---*Action*
function LuaEvents.AutomationStopTest.RemoveAll() end
---*Action*
function LuaEvents.AutomationStopTest.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationStopTest.Add(func) end
---@param func function
function LuaEvents.AutomationStopTest.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_OpenLite = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_OpenLite.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_OpenLite.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_OpenLite.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_OpenLite.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_OpenLite.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_Closed = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_Closed.Count() end
---*Action*
function LuaEvents.EndGameMenu_Closed.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_Closed.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_Closed.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleOverviewCitizens = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleOverviewCitizens.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewCitizens.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewCitizens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleOverviewCitizens.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleOverviewCitizens.Remove(func) end

---@overload fun()
LuaEvents.TopPanel_OpenDiplomacyActionView = {}
---*Query*
---@return number amount
function LuaEvents.TopPanel_OpenDiplomacyActionView.Count() end
---*Action*
function LuaEvents.TopPanel_OpenDiplomacyActionView.RemoveAll() end
---*Action*
function LuaEvents.TopPanel_OpenDiplomacyActionView.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TopPanel_OpenDiplomacyActionView.Add(func) end
---@param func function
function LuaEvents.TopPanel_OpenDiplomacyActionView.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_SimpleInGameMenu = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_SimpleInGameMenu.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_SimpleInGameMenu.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_SimpleInGameMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_SimpleInGameMenu.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_SimpleInGameMenu.Remove(func) end

---@overload fun()
LuaEvents.MapPinPopup_RequestMapPin = {}
---*Query*
---@return number amount
function LuaEvents.MapPinPopup_RequestMapPin.Count() end
---*Action*
function LuaEvents.MapPinPopup_RequestMapPin.RemoveAll() end
---*Action*
function LuaEvents.MapPinPopup_RequestMapPin.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapPinPopup_RequestMapPin.Add(func) end
---@param func function
function LuaEvents.MapPinPopup_RequestMapPin.Remove(func) end

---@overload fun()
LuaEvents.MapSelect_ClearMapData = {}
---*Query*
---@return number amount
function LuaEvents.MapSelect_ClearMapData.Count() end
---*Action*
function LuaEvents.MapSelect_ClearMapData.RemoveAll() end
---*Action*
function LuaEvents.MapSelect_ClearMapData.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapSelect_ClearMapData.Add(func) end
---@param func function
function LuaEvents.MapSelect_ClearMapData.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_CloseGoals = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_CloseGoals.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_CloseGoals.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_CloseGoals.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_CloseGoals.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_CloseGoals.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_OpenHistoricMoments = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_OpenHistoricMoments.Count() end
---*Action*
function LuaEvents.EndGameMenu_OpenHistoricMoments.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_OpenHistoricMoments.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_OpenHistoricMoments.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_OpenHistoricMoments.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleOverviewReligion = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleOverviewReligion.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewReligion.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewReligion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleOverviewReligion.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleOverviewReligion.Remove(func) end

---@overload fun()
LuaEvents.ResearchChooser_ForceHideWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.ResearchChooser_ForceHideWorldTracker.Count() end
---*Action*
function LuaEvents.ResearchChooser_ForceHideWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.ResearchChooser_ForceHideWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ResearchChooser_ForceHideWorldTracker.Add(func) end
---@param func function
function LuaEvents.ResearchChooser_ForceHideWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_StartPositionChanged = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_StartPositionChanged.Count() end
---*Action*
function LuaEvents.WorldBuilder_StartPositionChanged.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_StartPositionChanged.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_StartPositionChanged.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_StartPositionChanged.Remove(func) end

---@overload fun()
LuaEvents.CivicsPanel_RaiseCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.CivicsPanel_RaiseCivicsTree.Count() end
---*Action*
function LuaEvents.CivicsPanel_RaiseCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.CivicsPanel_RaiseCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicsPanel_RaiseCivicsTree.Add(func) end
---@param func function
function LuaEvents.CivicsPanel_RaiseCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_CloseChoosers = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_CloseChoosers.Count() end
---*Action*
function LuaEvents.LaunchBar_CloseChoosers.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_CloseChoosers.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_CloseChoosers.Add(func) end
---@param func function
function LuaEvents.LaunchBar_CloseChoosers.Remove(func) end

---@overload fun()
LuaEvents.MapSelect_PopulatedMaps = {}
---*Query*
---@return number amount
function LuaEvents.MapSelect_PopulatedMaps.Count() end
---*Action*
function LuaEvents.MapSelect_PopulatedMaps.RemoveAll() end
---*Action*
function LuaEvents.MapSelect_PopulatedMaps.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapSelect_PopulatedMaps.Add(func) end
---@param func function
function LuaEvents.MapSelect_PopulatedMaps.Remove(func) end

---@overload fun()
LuaEvents.UnitFlagManager_DrawRangeAttackPreview = {}
---*Query*
---@return number amount
function LuaEvents.UnitFlagManager_DrawRangeAttackPreview.Count() end
---*Action*
function LuaEvents.UnitFlagManager_DrawRangeAttackPreview.RemoveAll() end
---*Action*
function LuaEvents.UnitFlagManager_DrawRangeAttackPreview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitFlagManager_DrawRangeAttackPreview.Add(func) end
---@param func function
function LuaEvents.UnitFlagManager_DrawRangeAttackPreview.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_ProductionClicked = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_ProductionClicked.Count() end
---*Action*
function LuaEvents.ProductionPanel_ProductionClicked.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_ProductionClicked.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_ProductionClicked.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_ProductionClicked.Remove(func) end

---@overload fun()
LuaEvents.CivicsTree_OpenCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.CivicsTree_OpenCivicsTree.Count() end
---*Action*
function LuaEvents.CivicsTree_OpenCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.CivicsTree_OpenCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicsTree_OpenCivicsTree.Add(func) end
---@param func function
function LuaEvents.CivicsTree_OpenCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_SecretSocietyDiscovered = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_SecretSocietyDiscovered.Count() end
---*Action*
function LuaEvents.NotificationPanel_SecretSocietyDiscovered.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_SecretSocietyDiscovered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_SecretSocietyDiscovered.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_SecretSocietyDiscovered.Remove(func) end

---@overload fun()
LuaEvents.MapTacks_Function = {}
---*Query*
---@return number amount
function LuaEvents.MapTacks_Function.Count() end
---*Action*
function LuaEvents.MapTacks_Function.RemoveAll() end
---*Action*
function LuaEvents.MapTacks_Function.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapTacks_Function.Add(func) end
---@param func function
function LuaEvents.MapTacks_Function.Remove(func) end

---@overload fun()
LuaEvents.StagingRoom_SetPlayerID = {}
---*Query*
---@return number amount
function LuaEvents.StagingRoom_SetPlayerID.Count() end
---*Action*
function LuaEvents.StagingRoom_SetPlayerID.RemoveAll() end
---*Action*
function LuaEvents.StagingRoom_SetPlayerID.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StagingRoom_SetPlayerID.Add(func) end
---@param func function
function LuaEvents.StagingRoom_SetPlayerID.Remove(func) end

---@overload fun()
LuaEvents.FullscreenMap_Shown = {}
---*Query*
---@return number amount
function LuaEvents.FullscreenMap_Shown.Count() end
---*Action*
function LuaEvents.FullscreenMap_Shown.RemoveAll() end
---*Action*
function LuaEvents.FullscreenMap_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.FullscreenMap_Shown.Add(func) end
---@param func function
function LuaEvents.FullscreenMap_Shown.Remove(func) end

---@overload fun()
LuaEvents.MapSearch_PanelOpened = {}
---*Query*
---@return number amount
function LuaEvents.MapSearch_PanelOpened.Count() end
---*Action*
function LuaEvents.MapSearch_PanelOpened.RemoveAll() end
---*Action*
function LuaEvents.MapSearch_PanelOpened.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapSearch_PanelOpened.Add(func) end
---@param func function
function LuaEvents.MapSearch_PanelOpened.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_TutorialEndHideBulkUI = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_TutorialEndHideBulkUI.Count() end
---*Action*
function LuaEvents.Tutorial_TutorialEndHideBulkUI.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_TutorialEndHideBulkUI.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_TutorialEndHideBulkUI.Add(func) end
---@param func function
function LuaEvents.Tutorial_TutorialEndHideBulkUI.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_GovernmentOpenGovernments = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_GovernmentOpenGovernments.Count() end
---*Action*
function LuaEvents.NotificationPanel_GovernmentOpenGovernments.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_GovernmentOpenGovernments.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_GovernmentOpenGovernments.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_GovernmentOpenGovernments.Remove(func) end

---@overload fun()
LuaEvents.GovernorAssignmentChooser_RequestAssignment = {}
---*Query*
---@return number amount
function LuaEvents.GovernorAssignmentChooser_RequestAssignment.Count() end
---*Action*
function LuaEvents.GovernorAssignmentChooser_RequestAssignment.RemoveAll() end
---*Action*
function LuaEvents.GovernorAssignmentChooser_RequestAssignment.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorAssignmentChooser_RequestAssignment.Add(func) end
---@param func function
function LuaEvents.GovernorAssignmentChooser_RequestAssignment.Remove(func) end

---@overload fun()
LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview = {}
---*Query*
---@return number amount
function LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Count() end
---*Action*
function LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.RemoveAll() end
---*Action*
function LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Add(func) end
---@param func function
function LuaEvents.UnitPanel_CivRoyaleScenarioShowUnitFlagCombatPreview.Remove(func) end

---@overload fun()
LuaEvents.ChangeMPLobbyMode = {}
---*Query*
---@return number amount
function LuaEvents.ChangeMPLobbyMode.Count() end
---*Action*
function LuaEvents.ChangeMPLobbyMode.RemoveAll() end
---*Action*
function LuaEvents.ChangeMPLobbyMode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ChangeMPLobbyMode.Add(func) end
---@param func function
function LuaEvents.ChangeMPLobbyMode.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowTechDiscovered = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowTechDiscovered.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowTechDiscovered.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowTechDiscovered.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowTechDiscovered.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowTechDiscovered.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns.Count() end
---*Action*
function LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns.Add(func) end
---@param func function
function LuaEvents.WorldCongressPopup_HideWorldCongressBetweenTurns.Remove(func) end

---@overload fun()
LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList = {}
---*Query*
---@return number amount
function LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList.Count() end
---*Action*
function LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList.RemoveAll() end
---*Action*
function LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList.Add(func) end
---@param func function
function LuaEvents.CivicBoostUnlockedPopup_RefreshCivicBoostList.Remove(func) end

---@overload fun()
LuaEvents.Civ6Common_ConfirmWarDialog = {}
---*Query*
---@return number amount
function LuaEvents.Civ6Common_ConfirmWarDialog.Count() end
---*Action*
function LuaEvents.Civ6Common_ConfirmWarDialog.RemoveAll() end
---*Action*
function LuaEvents.Civ6Common_ConfirmWarDialog.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Civ6Common_ConfirmWarDialog.Add(func) end
---@param func function
function LuaEvents.Civ6Common_ConfirmWarDialog.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_EnableActions = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_EnableActions.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableActions.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableActions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_EnableActions.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_EnableActions.Remove(func) end

---@overload fun()
LuaEvents.ProjectBuiltPopup_Closed = {}
---*Query*
---@return number amount
function LuaEvents.ProjectBuiltPopup_Closed.Count() end
---*Action*
function LuaEvents.ProjectBuiltPopup_Closed.RemoveAll() end
---*Action*
function LuaEvents.ProjectBuiltPopup_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProjectBuiltPopup_Closed.Add(func) end
---@param func function
function LuaEvents.ProjectBuiltPopup_Closed.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_ShowCivRoyaleIntro = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_ShowCivRoyaleIntro.Count() end
---*Action*
function LuaEvents.MainMenu_ShowCivRoyaleIntro.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_ShowCivRoyaleIntro.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_ShowCivRoyaleIntro.Add(func) end
---@param func function
function LuaEvents.MainMenu_ShowCivRoyaleIntro.Remove(func) end

---@overload fun()
LuaEvents.WorldInput_DragMapBegin = {}
---*Query*
---@return number amount
function LuaEvents.WorldInput_DragMapBegin.Count() end
---*Action*
function LuaEvents.WorldInput_DragMapBegin.RemoveAll() end
---*Action*
function LuaEvents.WorldInput_DragMapBegin.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldInput_DragMapBegin.Add(func) end
---@param func function
function LuaEvents.WorldInput_DragMapBegin.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ToggleInGameOptionsMenu = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ToggleInGameOptionsMenu.Count() end
---*Action*
function LuaEvents.Tutorial_ToggleInGameOptionsMenu.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ToggleInGameOptionsMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ToggleInGameOptionsMenu.Add(func) end
---@param func function
function LuaEvents.Tutorial_ToggleInGameOptionsMenu.Remove(func) end

---@overload fun()
LuaEvents.Automation_AddToNarrationQueue = {}
---*Query*
---@return number amount
function LuaEvents.Automation_AddToNarrationQueue.Count() end
---*Action*
function LuaEvents.Automation_AddToNarrationQueue.RemoveAll() end
---*Action*
function LuaEvents.Automation_AddToNarrationQueue.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Automation_AddToNarrationQueue.Add(func) end
---@param func function
function LuaEvents.Automation_AddToNarrationQueue.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_GoalsLoadFromDisk = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_GoalsLoadFromDisk.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalsLoadFromDisk.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_GoalsLoadFromDisk.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_GoalsLoadFromDisk.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_GoalsLoadFromDisk.Remove(func) end

---@overload fun()
LuaEvents.GreatWorksOverview_ViewGreatWork = {}
---*Query*
---@return number amount
function LuaEvents.GreatWorksOverview_ViewGreatWork.Count() end
---*Action*
function LuaEvents.GreatWorksOverview_ViewGreatWork.RemoveAll() end
---*Action*
function LuaEvents.GreatWorksOverview_ViewGreatWork.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatWorksOverview_ViewGreatWork.Add(func) end
---@param func function
function LuaEvents.GreatWorksOverview_ViewGreatWork.Remove(func) end

---@overload fun()
LuaEvents.MinimapPanel_CloseAllLenses = {}
---*Query*
---@return number amount
function LuaEvents.MinimapPanel_CloseAllLenses.Count() end
---*Action*
function LuaEvents.MinimapPanel_CloseAllLenses.RemoveAll() end
---*Action*
function LuaEvents.MinimapPanel_CloseAllLenses.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MinimapPanel_CloseAllLenses.Add(func) end
---@param func function
function LuaEvents.MinimapPanel_CloseAllLenses.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_OpenPantheonChooser = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_OpenPantheonChooser.Count() end
---*Action*
function LuaEvents.LaunchBar_OpenPantheonChooser.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_OpenPantheonChooser.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_OpenPantheonChooser.Add(func) end
---@param func function
function LuaEvents.LaunchBar_OpenPantheonChooser.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_AddUnitMoveRestriction = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_AddUnitMoveRestriction.Count() end
---*Action*
function LuaEvents.Tutorial_AddUnitMoveRestriction.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_AddUnitMoveRestriction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_AddUnitMoveRestriction.Add(func) end
---@param func function
function LuaEvents.Tutorial_AddUnitMoveRestriction.Remove(func) end

---@overload fun()
LuaEvents.CivicChooser_RestoreWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.CivicChooser_RestoreWorldTracker.Count() end
---*Action*
function LuaEvents.CivicChooser_RestoreWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.CivicChooser_RestoreWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicChooser_RestoreWorldTracker.Add(func) end
---@param func function
function LuaEvents.CivicChooser_RestoreWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction = {}
---*Query*
---@return number amount
function LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction.Count() end
---*Action*
function LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction.RemoveAll() end
---*Action*
function LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction.Add(func) end
---@param func function
function LuaEvents.FrontEndPopup_CloseConfirmationWithoutAction.Remove(func) end

---@overload fun()
LuaEvents.PBCNotifyRemind_ShowOptions = {}
---*Query*
---@return number amount
function LuaEvents.PBCNotifyRemind_ShowOptions.Count() end
---*Action*
function LuaEvents.PBCNotifyRemind_ShowOptions.RemoveAll() end
---*Action*
function LuaEvents.PBCNotifyRemind_ShowOptions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PBCNotifyRemind_ShowOptions.Add(func) end
---@param func function
function LuaEvents.PBCNotifyRemind_ShowOptions.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_OpenGoals = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_OpenGoals.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_OpenGoals.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_OpenGoals.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_OpenGoals.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_OpenGoals.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_GovernmentOpenMyGovernment = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_GovernmentOpenMyGovernment.Count() end
---*Action*
function LuaEvents.LaunchBar_GovernmentOpenMyGovernment.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_GovernmentOpenMyGovernment.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_GovernmentOpenMyGovernment.Add(func) end
---@param func function
function LuaEvents.LaunchBar_GovernmentOpenMyGovernment.Remove(func) end

---@overload fun()
LuaEvents.GreatWorks_CloseGreatWorks = {}
---*Query*
---@return number amount
function LuaEvents.GreatWorks_CloseGreatWorks.Count() end
---*Action*
function LuaEvents.GreatWorks_CloseGreatWorks.RemoveAll() end
---*Action*
function LuaEvents.GreatWorks_CloseGreatWorks.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatWorks_CloseGreatWorks.Add(func) end
---@param func function
function LuaEvents.GreatWorks_CloseGreatWorks.Remove(func) end

---@overload fun()
LuaEvents.MapPinPopup_RequestChatPlayerTarget = {}
---*Query*
---@return number amount
function LuaEvents.MapPinPopup_RequestChatPlayerTarget.Count() end
---*Action*
function LuaEvents.MapPinPopup_RequestChatPlayerTarget.RemoveAll() end
---*Action*
function LuaEvents.MapPinPopup_RequestChatPlayerTarget.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapPinPopup_RequestChatPlayerTarget.Add(func) end
---@param func function
function LuaEvents.MapPinPopup_RequestChatPlayerTarget.Remove(func) end

---@overload fun()
LuaEvents.DiploPopup_HideDeal = {}
---*Query*
---@return number amount
function LuaEvents.DiploPopup_HideDeal.Count() end
---*Action*
function LuaEvents.DiploPopup_HideDeal.RemoveAll() end
---*Action*
function LuaEvents.DiploPopup_HideDeal.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploPopup_HideDeal.Add(func) end
---@param func function
function LuaEvents.DiploPopup_HideDeal.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_CloseIfPopups = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_CloseIfPopups.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_CloseIfPopups.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_CloseIfPopups.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_CloseIfPopups.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_CloseIfPopups.Remove(func) end

---@overload fun()
LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes = {}
---*Query*
---@return number amount
function LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes.Count() end
---*Action*
function LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes.RemoveAll() end
---*Action*
function LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes.Add(func) end
---@param func function
function LuaEvents.StrategicView_MapPlacement_AddDistrictPlacementShadowHexes.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.Count() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.Add(func) end
---@param func function
function LuaEvents.WorldBuilderLaunchBar_OpenPlayerEditor.Remove(func) end

---@overload fun()
LuaEvents.AutomationPostGameInitialization = {}
---*Query*
---@return number amount
function LuaEvents.AutomationPostGameInitialization.Count() end
---*Action*
function LuaEvents.AutomationPostGameInitialization.RemoveAll() end
---*Action*
function LuaEvents.AutomationPostGameInitialization.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationPostGameInitialization.Add(func) end
---@param func function
function LuaEvents.AutomationPostGameInitialization.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_EnableActionForAll = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_EnableActionForAll.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableActionForAll.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableActionForAll.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_EnableActionForAll.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_EnableActionForAll.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_ShowPlayerEditor = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_ShowPlayerEditor.Count() end
---*Action*
function LuaEvents.WorldBuilder_ShowPlayerEditor.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_ShowPlayerEditor.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_ShowPlayerEditor.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_ShowPlayerEditor.Remove(func) end

---@overload fun()
LuaEvents.OnPlagueLensOn = {}
---*Query*
---@return number amount
function LuaEvents.OnPlagueLensOn.Count() end
---*Action*
function LuaEvents.OnPlagueLensOn.RemoveAll() end
---*Action*
function LuaEvents.OnPlagueLensOn.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnPlagueLensOn.Add(func) end
---@param func function
function LuaEvents.OnPlagueLensOn.Remove(func) end

---@overload fun()
LuaEvents.OnViewLoyaltyLens = {}
---*Query*
---@return number amount
function LuaEvents.OnViewLoyaltyLens.Count() end
---*Action*
function LuaEvents.OnViewLoyaltyLens.RemoveAll() end
---*Action*
function LuaEvents.OnViewLoyaltyLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.OnViewLoyaltyLens.Add(func) end
---@param func function
function LuaEvents.OnViewLoyaltyLens.Remove(func) end

---@overload fun()
LuaEvents.AutomationMainMenuStarted = {}
---*Query*
---@return number amount
function LuaEvents.AutomationMainMenuStarted.Count() end
---*Action*
function LuaEvents.AutomationMainMenuStarted.RemoveAll() end
---*Action*
function LuaEvents.AutomationMainMenuStarted.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.AutomationMainMenuStarted.Add(func) end
---@param func function
function LuaEvents.AutomationMainMenuStarted.Remove(func) end

---@overload fun()
LuaEvents.UnitPanel_CancelMission = {}
---*Query*
---@return number amount
function LuaEvents.UnitPanel_CancelMission.Count() end
---*Action*
function LuaEvents.UnitPanel_CancelMission.RemoveAll() end
---*Action*
function LuaEvents.UnitPanel_CancelMission.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitPanel_CancelMission.Add(func) end
---@param func function
function LuaEvents.UnitPanel_CancelMission.Remove(func) end

---@overload fun()
LuaEvents.TopPanel_CloseReportsScreen = {}
---*Query*
---@return number amount
function LuaEvents.TopPanel_CloseReportsScreen.Count() end
---*Action*
function LuaEvents.TopPanel_CloseReportsScreen.RemoveAll() end
---*Action*
function LuaEvents.TopPanel_CloseReportsScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TopPanel_CloseReportsScreen.Add(func) end
---@param func function
function LuaEvents.TopPanel_CloseReportsScreen.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_PlotToolTipsOff = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_PlotToolTipsOff.Count() end
---*Action*
function LuaEvents.Tutorial_PlotToolTipsOff.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_PlotToolTipsOff.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_PlotToolTipsOff.Add(func) end
---@param func function
function LuaEvents.Tutorial_PlotToolTipsOff.Remove(func) end

---@overload fun()
LuaEvents.InGameTopOptionsMenu_Show = {}
---*Query*
---@return number amount
function LuaEvents.InGameTopOptionsMenu_Show.Count() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_Show.RemoveAll() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_Show.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGameTopOptionsMenu_Show.Add(func) end
---@param func function
function LuaEvents.InGameTopOptionsMenu_Show.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_RemoveUnitHexRestriction = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_RemoveUnitHexRestriction.Count() end
---*Action*
function LuaEvents.Tutorial_RemoveUnitHexRestriction.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_RemoveUnitHexRestriction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_RemoveUnitHexRestriction.Add(func) end
---@param func function
function LuaEvents.Tutorial_RemoveUnitHexRestriction.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_Shown = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_Shown.Count() end
---*Action*
function LuaEvents.EndGameMenu_Shown.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_Shown.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_Shown.Remove(func) end

---@overload fun()
LuaEvents.MultiSelectWindow_SetParameterValues = {}
---*Query*
---@return number amount
function LuaEvents.MultiSelectWindow_SetParameterValues.Count() end
---*Action*
function LuaEvents.MultiSelectWindow_SetParameterValues.RemoveAll() end
---*Action*
function LuaEvents.MultiSelectWindow_SetParameterValues.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MultiSelectWindow_SetParameterValues.Add(func) end
---@param func function
function LuaEvents.MultiSelectWindow_SetParameterValues.Remove(func) end

---@overload fun()
LuaEvents.CivRoyaleIntro_StartMatchMaking = {}
---*Query*
---@return number amount
function LuaEvents.CivRoyaleIntro_StartMatchMaking.Count() end
---*Action*
function LuaEvents.CivRoyaleIntro_StartMatchMaking.RemoveAll() end
---*Action*
function LuaEvents.CivRoyaleIntro_StartMatchMaking.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivRoyaleIntro_StartMatchMaking.Add(func) end
---@param func function
function LuaEvents.CivRoyaleIntro_StartMatchMaking.Remove(func) end

---@overload fun()
LuaEvents.Mods_UpdateHostGameSettings = {}
---*Query*
---@return number amount
function LuaEvents.Mods_UpdateHostGameSettings.Count() end
---*Action*
function LuaEvents.Mods_UpdateHostGameSettings.RemoveAll() end
---*Action*
function LuaEvents.Mods_UpdateHostGameSettings.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Mods_UpdateHostGameSettings.Add(func) end
---@param func function
function LuaEvents.Mods_UpdateHostGameSettings.Remove(func) end

---@overload fun()
LuaEvents.WonderBuiltPopup_Shown = {}
---*Query*
---@return number amount
function LuaEvents.WonderBuiltPopup_Shown.Count() end
---*Action*
function LuaEvents.WonderBuiltPopup_Shown.RemoveAll() end
---*Action*
function LuaEvents.WonderBuiltPopup_Shown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WonderBuiltPopup_Shown.Add(func) end
---@param func function
function LuaEvents.WonderBuiltPopup_Shown.Remove(func) end

---@overload fun()
LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups = {}
---*Query*
---@return number amount
function LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups.Count() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups.RemoveAll() end
---*Action*
function LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups.Add(func) end
---@param func function
function LuaEvents.TutorialUIRoot_EnableTechAndCivicPopups.Remove(func) end

---@overload fun()
LuaEvents.ProductionPanel_Close = {}
---*Query*
---@return number amount
function LuaEvents.ProductionPanel_Close.Count() end
---*Action*
function LuaEvents.ProductionPanel_Close.RemoveAll() end
---*Action*
function LuaEvents.ProductionPanel_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ProductionPanel_Close.Add(func) end
---@param func function
function LuaEvents.ProductionPanel_Close.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseEraProgressPanel = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseEraProgressPanel.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseEraProgressPanel.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseEraProgressPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseEraProgressPanel.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseEraProgressPanel.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_RestoreWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_RestoreWorldTracker.Count() end
---*Action*
function LuaEvents.Tutorial_RestoreWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_RestoreWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_RestoreWorldTracker.Add(func) end
---@param func function
function LuaEvents.Tutorial_RestoreWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.MinimapPanel_AddContinentColorPair = {}
---*Query*
---@return number amount
function LuaEvents.MinimapPanel_AddContinentColorPair.Count() end
---*Action*
function LuaEvents.MinimapPanel_AddContinentColorPair.RemoveAll() end
---*Action*
function LuaEvents.MinimapPanel_AddContinentColorPair.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MinimapPanel_AddContinentColorPair.Add(func) end
---@param func function
function LuaEvents.MinimapPanel_AddContinentColorPair.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_Closed = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_Closed.Count() end
---*Action*
function LuaEvents.GovernorPanel_Closed.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_Closed.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_Closed.Remove(func) end

---@overload fun()
LuaEvents.GreatPeoplePopup_RefreshHeroes = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeoplePopup_RefreshHeroes.Count() end
---*Action*
function LuaEvents.GreatPeoplePopup_RefreshHeroes.RemoveAll() end
---*Action*
function LuaEvents.GreatPeoplePopup_RefreshHeroes.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeoplePopup_RefreshHeroes.Add(func) end
---@param func function
function LuaEvents.GreatPeoplePopup_RefreshHeroes.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressIntro_ShowWorldCongress = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressIntro_ShowWorldCongress.Count() end
---*Action*
function LuaEvents.WorldCongressIntro_ShowWorldCongress.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressIntro_ShowWorldCongress.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressIntro_ShowWorldCongress.Add(func) end
---@param func function
function LuaEvents.WorldCongressIntro_ShowWorldCongress.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_StartObserverMode = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_StartObserverMode.Count() end
---*Action*
function LuaEvents.EndGameMenu_StartObserverMode.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_StartObserverMode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_StartObserverMode.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_StartObserverMode.Remove(func) end

---@overload fun()
LuaEvents.StartCrossPlay = {}
---*Query*
---@return number amount
function LuaEvents.StartCrossPlay.Count() end
---*Action*
function LuaEvents.StartCrossPlay.RemoveAll() end
---*Action*
function LuaEvents.StartCrossPlay.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StartCrossPlay.Add(func) end
---@param func function
function LuaEvents.StartCrossPlay.Remove(func) end

---@overload fun()
LuaEvents.InGameTopOptionsMenu_Close = {}
---*Query*
---@return number amount
function LuaEvents.InGameTopOptionsMenu_Close.Count() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_Close.RemoveAll() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGameTopOptionsMenu_Close.Add(func) end
---@param func function
function LuaEvents.InGameTopOptionsMenu_Close.Remove(func) end

---@overload fun()
LuaEvents.Advisor_GovernmentOpenPolicies = {}
---*Query*
---@return number amount
function LuaEvents.Advisor_GovernmentOpenPolicies.Count() end
---*Action*
function LuaEvents.Advisor_GovernmentOpenPolicies.RemoveAll() end
---*Action*
function LuaEvents.Advisor_GovernmentOpenPolicies.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Advisor_GovernmentOpenPolicies.Add(func) end
---@param func function
function LuaEvents.Advisor_GovernmentOpenPolicies.Remove(func) end

---@overload fun()
LuaEvents.GreatPeople_OpenGreatPeople = {}
---*Query*
---@return number amount
function LuaEvents.GreatPeople_OpenGreatPeople.Count() end
---*Action*
function LuaEvents.GreatPeople_OpenGreatPeople.RemoveAll() end
---*Action*
function LuaEvents.GreatPeople_OpenGreatPeople.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GreatPeople_OpenGreatPeople.Add(func) end
---@param func function
function LuaEvents.GreatPeople_OpenGreatPeople.Remove(func) end

---@overload fun()
LuaEvents.ShowEndGame = {}
---*Query*
---@return number amount
function LuaEvents.ShowEndGame.Count() end
---*Action*
function LuaEvents.ShowEndGame.RemoveAll() end
---*Action*
function LuaEvents.ShowEndGame.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ShowEndGame.Add(func) end
---@param func function
function LuaEvents.ShowEndGame.Remove(func) end

---@overload fun()
LuaEvents.ChatPanel_OnChatReceived = {}
---*Query*
---@return number amount
function LuaEvents.ChatPanel_OnChatReceived.Count() end
---*Action*
function LuaEvents.ChatPanel_OnChatReceived.RemoveAll() end
---*Action*
function LuaEvents.ChatPanel_OnChatReceived.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ChatPanel_OnChatReceived.Add(func) end
---@param func function
function LuaEvents.ChatPanel_OnChatReceived.Remove(func) end

---@overload fun()
LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments = {}
---*Query*
---@return number amount
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments.Count() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments.RemoveAll() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments.Add(func) end
---@param func function
function LuaEvents.TechCivicCompletedPopup_GovernmentOpenGovernments.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_CancelAssignment = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_CancelAssignment.Count() end
---*Action*
function LuaEvents.GovernorPanel_CancelAssignment.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_CancelAssignment.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_CancelAssignment.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_CancelAssignment.Remove(func) end

---@overload fun()
LuaEvents.PlayerChange_OpenInGameOptionsMenu = {}
---*Query*
---@return number amount
function LuaEvents.PlayerChange_OpenInGameOptionsMenu.Count() end
---*Action*
function LuaEvents.PlayerChange_OpenInGameOptionsMenu.RemoveAll() end
---*Action*
function LuaEvents.PlayerChange_OpenInGameOptionsMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PlayerChange_OpenInGameOptionsMenu.Add(func) end
---@param func function
function LuaEvents.PlayerChange_OpenInGameOptionsMenu.Remove(func) end

---@overload fun()
LuaEvents.StateTransition_SignalRaised = {}
---*Query*
---@return number amount
function LuaEvents.StateTransition_SignalRaised.Count() end
---*Action*
function LuaEvents.StateTransition_SignalRaised.RemoveAll() end
---*Action*
function LuaEvents.StateTransition_SignalRaised.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StateTransition_SignalRaised.Add(func) end
---@param func function
function LuaEvents.StateTransition_SignalRaised.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ChooseProduction = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ChooseProduction.Count() end
---*Action*
function LuaEvents.NotificationPanel_ChooseProduction.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ChooseProduction.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ChooseProduction.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ChooseProduction.Remove(func) end

---@overload fun()
LuaEvents.NotificationPanel_ShowContinentLens = {}
---*Query*
---@return number amount
function LuaEvents.NotificationPanel_ShowContinentLens.Count() end
---*Action*
function LuaEvents.NotificationPanel_ShowContinentLens.RemoveAll() end
---*Action*
function LuaEvents.NotificationPanel_ShowContinentLens.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.NotificationPanel_ShowContinentLens.Add(func) end
---@param func function
function LuaEvents.NotificationPanel_ShowContinentLens.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_PlayerEdited = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_PlayerEdited.Count() end
---*Action*
function LuaEvents.WorldBuilder_PlayerEdited.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_PlayerEdited.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_PlayerEdited.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_PlayerEdited.Remove(func) end

---@overload fun()
LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro = {}
---*Query*
---@return number amount
function LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Count() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.RemoveAll() end
---*Action*
function LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Add(func) end
---@param func function
function LuaEvents.InGameTopOptionsMenu_ShowExpansionIntro.Remove(func) end

---@overload fun()
LuaEvents.TechCivicCompletedPopup_TechShown = {}
---*Query*
---@return number amount
function LuaEvents.TechCivicCompletedPopup_TechShown.Count() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_TechShown.RemoveAll() end
---*Action*
function LuaEvents.TechCivicCompletedPopup_TechShown.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TechCivicCompletedPopup_TechShown.Add(func) end
---@param func function
function LuaEvents.TechCivicCompletedPopup_TechShown.Remove(func) end

---@overload fun()
LuaEvents.PausePanel_OpenInGameOptionsMenu = {}
---*Query*
---@return number amount
function LuaEvents.PausePanel_OpenInGameOptionsMenu.Count() end
---*Action*
function LuaEvents.PausePanel_OpenInGameOptionsMenu.RemoveAll() end
---*Action*
function LuaEvents.PausePanel_OpenInGameOptionsMenu.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PausePanel_OpenInGameOptionsMenu.Add(func) end
---@param func function
function LuaEvents.PausePanel_OpenInGameOptionsMenu.Remove(func) end

---@overload fun()
LuaEvents.GameDebug_GetValues = {}
---*Query*
---@return number amount
function LuaEvents.GameDebug_GetValues.Count() end
---*Action*
function LuaEvents.GameDebug_GetValues.RemoveAll() end
---*Action*
function LuaEvents.GameDebug_GetValues.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GameDebug_GetValues.Add(func) end
---@param func function
function LuaEvents.GameDebug_GetValues.Remove(func) end

---@overload fun()
LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification = {}
---*Query*
---@return number amount
function LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification.Count() end
---*Action*
function LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification.RemoveAll() end
---*Action*
function LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification.Add(func) end
---@param func function
function LuaEvents.WorldCongressPopup_DismissSpecialSessionNotification.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseTradeOverview = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseTradeOverview.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseTradeOverview.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseTradeOverview.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseTradeOverview.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseTradeOverview.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_CloseWorldRankings = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_CloseWorldRankings.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseWorldRankings.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_CloseWorldRankings.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_CloseWorldRankings.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_CloseWorldRankings.Remove(func) end

---@overload fun()
LuaEvents.HistoricMoments_Close = {}
---*Query*
---@return number amount
function LuaEvents.HistoricMoments_Close.Count() end
---*Action*
function LuaEvents.HistoricMoments_Close.RemoveAll() end
---*Action*
function LuaEvents.HistoricMoments_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.HistoricMoments_Close.Add(func) end
---@param func function
function LuaEvents.HistoricMoments_Close.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ProductionOpen = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ProductionOpen.Count() end
---*Action*
function LuaEvents.CityPanel_ProductionOpen.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ProductionOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ProductionOpen.Add(func) end
---@param func function
function LuaEvents.CityPanel_ProductionOpen.Remove(func) end

---@overload fun()
LuaEvents.EraProgressPanel_Open = {}
---*Query*
---@return number amount
function LuaEvents.EraProgressPanel_Open.Count() end
---*Action*
function LuaEvents.EraProgressPanel_Open.RemoveAll() end
---*Action*
function LuaEvents.EraProgressPanel_Open.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EraProgressPanel_Open.Add(func) end
---@param func function
function LuaEvents.EraProgressPanel_Open.Remove(func) end

---@overload fun()
LuaEvents.DiplomacyActionView_ShowCongressResults = {}
---*Query*
---@return number amount
function LuaEvents.DiplomacyActionView_ShowCongressResults.Count() end
---*Action*
function LuaEvents.DiplomacyActionView_ShowCongressResults.RemoveAll() end
---*Action*
function LuaEvents.DiplomacyActionView_ShowCongressResults.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiplomacyActionView_ShowCongressResults.Add(func) end
---@param func function
function LuaEvents.DiplomacyActionView_ShowCongressResults.Remove(func) end

---@overload fun()
LuaEvents.WonderBuiltPopup_Closed = {}
---*Query*
---@return number amount
function LuaEvents.WonderBuiltPopup_Closed.Count() end
---*Action*
function LuaEvents.WonderBuiltPopup_Closed.RemoveAll() end
---*Action*
function LuaEvents.WonderBuiltPopup_Closed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WonderBuiltPopup_Closed.Add(func) end
---@param func function
function LuaEvents.WonderBuiltPopup_Closed.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_ToggleCivicPanel = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_ToggleCivicPanel.Count() end
---*Action*
function LuaEvents.WorldTracker_ToggleCivicPanel.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_ToggleCivicPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_ToggleCivicPanel.Add(func) end
---@param func function
function LuaEvents.WorldTracker_ToggleCivicPanel.Remove(func) end

---@overload fun()
LuaEvents.StrageticView_MapPlacement_ProductionOpen = {}
---*Query*
---@return number amount
function LuaEvents.StrageticView_MapPlacement_ProductionOpen.Count() end
---*Action*
function LuaEvents.StrageticView_MapPlacement_ProductionOpen.RemoveAll() end
---*Action*
function LuaEvents.StrageticView_MapPlacement_ProductionOpen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.StrageticView_MapPlacement_ProductionOpen.Add(func) end
---@param func function
function LuaEvents.StrageticView_MapPlacement_ProductionOpen.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_GovernmentOpenGovernments = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_GovernmentOpenGovernments.Count() end
---*Action*
function LuaEvents.LaunchBar_GovernmentOpenGovernments.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_GovernmentOpenGovernments.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_GovernmentOpenGovernments.Add(func) end
---@param func function
function LuaEvents.LaunchBar_GovernmentOpenGovernments.Remove(func) end

---@overload fun()
LuaEvents.PantheonChooser_OpenReligionPanel = {}
---*Query*
---@return number amount
function LuaEvents.PantheonChooser_OpenReligionPanel.Count() end
---*Action*
function LuaEvents.PantheonChooser_OpenReligionPanel.RemoveAll() end
---*Action*
function LuaEvents.PantheonChooser_OpenReligionPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PantheonChooser_OpenReligionPanel.Add(func) end
---@param func function
function LuaEvents.PantheonChooser_OpenReligionPanel.Remove(func) end

---@overload fun()
LuaEvents.UnitPanel_HideUnitPromotion = {}
---*Query*
---@return number amount
function LuaEvents.UnitPanel_HideUnitPromotion.Count() end
---*Action*
function LuaEvents.UnitPanel_HideUnitPromotion.RemoveAll() end
---*Action*
function LuaEvents.UnitPanel_HideUnitPromotion.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.UnitPanel_HideUnitPromotion.Add(func) end
---@param func function
function LuaEvents.UnitPanel_HideUnitPromotion.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_EndTutorialRestrictions = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_EndTutorialRestrictions.Count() end
---*Action*
function LuaEvents.Tutorial_EndTutorialRestrictions.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_EndTutorialRestrictions.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_EndTutorialRestrictions.Add(func) end
---@param func function
function LuaEvents.Tutorial_EndTutorialRestrictions.Remove(func) end

---@overload fun()
LuaEvents.CityPanelOverview_CloseButton = {}
---*Query*
---@return number amount
function LuaEvents.CityPanelOverview_CloseButton.Count() end
---*Action*
function LuaEvents.CityPanelOverview_CloseButton.RemoveAll() end
---*Action*
function LuaEvents.CityPanelOverview_CloseButton.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanelOverview_CloseButton.Add(func) end
---@param func function
function LuaEvents.CityPanelOverview_CloseButton.Remove(func) end

---@overload fun()
LuaEvents.GovernorPanel_Open = {}
---*Query*
---@return number amount
function LuaEvents.GovernorPanel_Open.Count() end
---*Action*
function LuaEvents.GovernorPanel_Open.RemoveAll() end
---*Action*
function LuaEvents.GovernorPanel_Open.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.GovernorPanel_Open.Add(func) end
---@param func function
function LuaEvents.GovernorPanel_Open.Remove(func) end

---@overload fun()
LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup = {}
---*Query*
---@return number amount
function LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup.Count() end
---*Action*
function LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup.RemoveAll() end
---*Action*
function LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup.Add(func) end
---@param func function
function LuaEvents.SwitchLayoutPopup_OpenSwitchLayoutPopup.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_TechTreeScrollToNode = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_TechTreeScrollToNode.Count() end
---*Action*
function LuaEvents.Tutorial_TechTreeScrollToNode.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_TechTreeScrollToNode.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_TechTreeScrollToNode.Add(func) end
---@param func function
function LuaEvents.Tutorial_TechTreeScrollToNode.Remove(func) end

---@overload fun()
LuaEvents.MapSelect_SetMapByValue = {}
---*Query*
---@return number amount
function LuaEvents.MapSelect_SetMapByValue.Count() end
---*Action*
function LuaEvents.MapSelect_SetMapByValue.RemoveAll() end
---*Action*
function LuaEvents.MapSelect_SetMapByValue.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MapSelect_SetMapByValue.Add(func) end
---@param func function
function LuaEvents.MapSelect_SetMapByValue.Remove(func) end

---@overload fun()
LuaEvents.MainMenu_PlayCiv6Started = {}
---*Query*
---@return number amount
function LuaEvents.MainMenu_PlayCiv6Started.Count() end
---*Action*
function LuaEvents.MainMenu_PlayCiv6Started.RemoveAll() end
---*Action*
function LuaEvents.MainMenu_PlayCiv6Started.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.MainMenu_PlayCiv6Started.Add(func) end
---@param func function
function LuaEvents.MainMenu_PlayCiv6Started.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_Expansion2_MyScreen = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_Expansion2_MyScreen.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_Expansion2_MyScreen.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_Expansion2_MyScreen.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_Expansion2_MyScreen.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_Expansion2_MyScreen.Remove(func) end

---@overload fun()
LuaEvents.EraReviewPopup_MakeDedication = {}
---*Query*
---@return number amount
function LuaEvents.EraReviewPopup_MakeDedication.Count() end
---*Action*
function LuaEvents.EraReviewPopup_MakeDedication.RemoveAll() end
---*Action*
function LuaEvents.EraReviewPopup_MakeDedication.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EraReviewPopup_MakeDedication.Add(func) end
---@param func function
function LuaEvents.EraReviewPopup_MakeDedication.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenReportsList = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenReportsList.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenReportsList.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenReportsList.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenReportsList.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenReportsList.Remove(func) end

---@overload fun()
LuaEvents.WorldTracker_OpenChooseResearch = {}
---*Query*
---@return number amount
function LuaEvents.WorldTracker_OpenChooseResearch.Count() end
---*Action*
function LuaEvents.WorldTracker_OpenChooseResearch.RemoveAll() end
---*Action*
function LuaEvents.WorldTracker_OpenChooseResearch.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldTracker_OpenChooseResearch.Add(func) end
---@param func function
function LuaEvents.WorldTracker_OpenChooseResearch.Remove(func) end

---@overload fun()
LuaEvents.CivicsTree_CloseCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.CivicsTree_CloseCivicsTree.Count() end
---*Action*
function LuaEvents.CivicsTree_CloseCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.CivicsTree_CloseCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CivicsTree_CloseCivicsTree.Add(func) end
---@param func function
function LuaEvents.CivicsTree_CloseCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.TradeRouteChooser_Close = {}
---*Query*
---@return number amount
function LuaEvents.TradeRouteChooser_Close.Count() end
---*Action*
function LuaEvents.TradeRouteChooser_Close.RemoveAll() end
---*Action*
function LuaEvents.TradeRouteChooser_Close.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.TradeRouteChooser_Close.Add(func) end
---@param func function
function LuaEvents.TradeRouteChooser_Close.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_SwitchToWorldView = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_SwitchToWorldView.Count() end
---*Action*
function LuaEvents.Tutorial_SwitchToWorldView.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_SwitchToWorldView.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_SwitchToWorldView.Add(func) end
---@param func function
function LuaEvents.Tutorial_SwitchToWorldView.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_SetDealAnimation = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_SetDealAnimation.Count() end
---*Action*
function LuaEvents.DiploScene_SetDealAnimation.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_SetDealAnimation.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_SetDealAnimation.Add(func) end
---@param func function
function LuaEvents.DiploScene_SetDealAnimation.Remove(func) end

---@overload fun()
LuaEvents.ResearchChooser_RestoreWorldTracker = {}
---*Query*
---@return number amount
function LuaEvents.ResearchChooser_RestoreWorldTracker.Count() end
---*Action*
function LuaEvents.ResearchChooser_RestoreWorldTracker.RemoveAll() end
---*Action*
function LuaEvents.ResearchChooser_RestoreWorldTracker.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.ResearchChooser_RestoreWorldTracker.Add(func) end
---@param func function
function LuaEvents.ResearchChooser_RestoreWorldTracker.Remove(func) end

---@overload fun()
LuaEvents.Lower_State_Transition = {}
---*Query*
---@return number amount
function LuaEvents.Lower_State_Transition.Count() end
---*Action*
function LuaEvents.Lower_State_Transition.RemoveAll() end
---*Action*
function LuaEvents.Lower_State_Transition.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Lower_State_Transition.Add(func) end
---@param func function
function LuaEvents.Lower_State_Transition.Remove(func) end

---@overload fun()
LuaEvents.Tutorial_ConstrainMovement = {}
---*Query*
---@return number amount
function LuaEvents.Tutorial_ConstrainMovement.Count() end
---*Action*
function LuaEvents.Tutorial_ConstrainMovement.RemoveAll() end
---*Action*
function LuaEvents.Tutorial_ConstrainMovement.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.Tutorial_ConstrainMovement.Add(func) end
---@param func function
function LuaEvents.Tutorial_ConstrainMovement.Remove(func) end

---@overload fun()
LuaEvents.PartialScreenHooks_OpenWorldRankings = {}
---*Query*
---@return number amount
function LuaEvents.PartialScreenHooks_OpenWorldRankings.Count() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenWorldRankings.RemoveAll() end
---*Action*
function LuaEvents.PartialScreenHooks_OpenWorldRankings.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.PartialScreenHooks_OpenWorldRankings.Add(func) end
---@param func function
function LuaEvents.PartialScreenHooks_OpenWorldRankings.Remove(func) end

---@overload fun()
LuaEvents.DiploScene_SceneClosed = {}
---*Query*
---@return number amount
function LuaEvents.DiploScene_SceneClosed.Count() end
---*Action*
function LuaEvents.DiploScene_SceneClosed.RemoveAll() end
---*Action*
function LuaEvents.DiploScene_SceneClosed.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.DiploScene_SceneClosed.Add(func) end
---@param func function
function LuaEvents.DiploScene_SceneClosed.Remove(func) end

---@overload fun()
LuaEvents.EndGameMenu_OneMoreTurn = {}
---*Query*
---@return number amount
function LuaEvents.EndGameMenu_OneMoreTurn.Count() end
---*Action*
function LuaEvents.EndGameMenu_OneMoreTurn.RemoveAll() end
---*Action*
function LuaEvents.EndGameMenu_OneMoreTurn.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.EndGameMenu_OneMoreTurn.Add(func) end
---@param func function
function LuaEvents.EndGameMenu_OneMoreTurn.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_OpenReligionPanel = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_OpenReligionPanel.Count() end
---*Action*
function LuaEvents.LaunchBar_OpenReligionPanel.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_OpenReligionPanel.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_OpenReligionPanel.Add(func) end
---@param func function
function LuaEvents.LaunchBar_OpenReligionPanel.Remove(func) end

---@overload fun()
LuaEvents.CongressButton_ShowCongressResults = {}
---*Query*
---@return number amount
function LuaEvents.CongressButton_ShowCongressResults.Count() end
---*Action*
function LuaEvents.CongressButton_ShowCongressResults.RemoveAll() end
---*Action*
function LuaEvents.CongressButton_ShowCongressResults.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CongressButton_ShowCongressResults.Add(func) end
---@param func function
function LuaEvents.CongressButton_ShowCongressResults.Remove(func) end

---@overload fun()
LuaEvents.LaunchBar_RaiseCivicsTree = {}
---*Query*
---@return number amount
function LuaEvents.LaunchBar_RaiseCivicsTree.Count() end
---*Action*
function LuaEvents.LaunchBar_RaiseCivicsTree.RemoveAll() end
---*Action*
function LuaEvents.LaunchBar_RaiseCivicsTree.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.LaunchBar_RaiseCivicsTree.Add(func) end
---@param func function
function LuaEvents.LaunchBar_RaiseCivicsTree.Remove(func) end

---@overload fun()
LuaEvents.WorldBuilder_SetPlacementStatus = {}
---*Query*
---@return number amount
function LuaEvents.WorldBuilder_SetPlacementStatus.Count() end
---*Action*
function LuaEvents.WorldBuilder_SetPlacementStatus.RemoveAll() end
---*Action*
function LuaEvents.WorldBuilder_SetPlacementStatus.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.WorldBuilder_SetPlacementStatus.Add(func) end
---@param func function
function LuaEvents.WorldBuilder_SetPlacementStatus.Remove(func) end

---@overload fun()
LuaEvents.CityPanel_ToggleOverviewBuildings = {}
---*Query*
---@return number amount
function LuaEvents.CityPanel_ToggleOverviewBuildings.Count() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewBuildings.RemoveAll() end
---*Action*
function LuaEvents.CityPanel_ToggleOverviewBuildings.Call() end
---*Action*
---@param func fun()
---@return fun()
function LuaEvents.CityPanel_ToggleOverviewBuildings.Add(func) end
---@param func function
function LuaEvents.CityPanel_ToggleOverviewBuildings.Remove(func) end
