include("caiUtils")
include("EraCompletePopup")

local function GetAgeText()
	local localPlayerID = Game.GetLocalPlayer()
	if localPlayerID == nil or localPlayerID == PlayerTypes.NONE then return nil end

	local eraTable = Game.GetEras()
	if eraTable == nil then return nil end

	if eraTable.HasHeroicGoldenAge and eraTable:HasHeroicGoldenAge(localPlayerID) then
		return Locale.Lookup("LOC_CAI_ERA_HEROIC_AGE")
	elseif eraTable.HasGoldenAge and eraTable:HasGoldenAge(localPlayerID) then
		return Locale.Lookup("LOC_CAI_ERA_GOLDEN_AGE")
	elseif eraTable.HasDarkAge and eraTable:HasDarkAge(localPlayerID) then
		return Locale.Lookup("LOC_CAI_ERA_DARK_AGE")
	elseif eraTable.HasGoldenAge then
		return Locale.Lookup("LOC_CAI_ERA_NORMAL_AGE")
	end

	return nil
end

OnShow = WrapFunc(OnShow, function(orig)
	orig()
	Speak("Calling era complete")
	local eraName = Controls.EraCompletedHeader:GetText()
	if not eraName or eraName == "" then return end

	local text = Locale.Lookup("LOC_CAI_ERA_ENTERING", eraName)
	local ageText = GetAgeText()
	if ageText then
		text = text .. ". " .. ageText
	end

	Speak(text)
end)
ContextPtr:SetShowHandler(OnShow)
