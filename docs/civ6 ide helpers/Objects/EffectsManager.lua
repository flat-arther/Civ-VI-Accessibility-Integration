---@meta


---**Contexts:** UI
EffectsManager = {}
---**Contexts:** UI
---
---*Action*
function EffectsManager:PauseAllEffects() end
---**Contexts:** UI
---
---*Action*
---@param Control Control 
---@param effect string 
---@param options? table 
function EffectsManager:PlayEffectOneTime(Control, effect, options) end
---**Contexts:** UI
---
---*Action*
function EffectsManager:ResumeAllEffects() end
---**Contexts:** UI
---
---*Action*
---@param Control Control 
---@param effect string 
---@param options? table 
function EffectsManager:PlayEffect(Control, effect, options) end
---**Contexts:** UI
---
---*Action*
---@param Control Control 
function EffectsManager:StopEffect(Control) end
---**Contexts:** UI
---
---*Action*
function EffectsManager:StopAllEffects() end