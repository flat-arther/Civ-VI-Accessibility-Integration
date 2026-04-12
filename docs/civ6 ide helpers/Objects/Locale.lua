---@meta


---**Contexts:** Gameplay, UI
Locale = {}
---**Contexts:** Gameplay, UI
---
---*Query*
---@return table langInfo 
function Locale.GetCurrentLanguage() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.IsUTF8() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.Compare() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.IsASCII() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.IsNilOrWhitespace() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.StripTags() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.IsNilOrEmpty() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.LookupLanguage() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.Compose() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToOrdinal() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.GetLanguageDisplayName() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToUpper() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.GetAudioLanguages() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToSpellout() end
---**Contexts:** Gameplay, UI
---
---*Action*
---@return string romanNumerals 
function Locale.ToRomanNumeral() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.SplitString() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.SubString() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.IsValidKey() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToLower() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.GetLanguageCoverage() end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToNumber() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.EndsWith() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.GetLanguages() end
---**Contexts:** Gameplay, UI
---
---*Query*
---
---Replaces occurances of LOC_ tags with localized text from the Localization DB.
---@param text string 
---@return string localizedText 
function Locale.Lookup(text) end
---**Contexts:** Gameplay, UI
---
---*Action*
function Locale.ToPercent() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.Length() end
---**Contexts:** Gameplay, UI
---
---*Query*
function Locale.Bundle() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.HasTextKey() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@return boolean  
function Locale.StartsWith() end
---**Contexts:** Gameplay, UI
---
---*Query*
---@param name string 
---@return string text 
function Locale.LookupBundle(name) end