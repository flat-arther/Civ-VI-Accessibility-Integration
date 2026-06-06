-- CAIWidgetRegistry.lua
-- Type-name -> constructor map. Each widget file registers itself at load.
-- A constructor takes (manager, id, props) and returns an instance.

CAIWidgetRegistry = {}
local R = CAIWidgetRegistry
R._ctors = {}

---@param typeName string
---@param ctor fun(mgr:UIScreenManager, id:string, props?:table):UIWidget
function R.Register(typeName, ctor)
    if R._ctors[typeName] then
        print("CAI widget registry: overwriting type " .. tostring(typeName))
    end
    R._ctors[typeName] = ctor
end

---@param typeName string
---@return fun(mgr:UIScreenManager, id:string, props?:table):UIWidget|nil
function R.GetCtor(typeName) return R._ctors[typeName] end

---Apply per-instance prop overrides on top of the constructed widget.
---Props with a `Set<Name>` setter route through the setter so coupled
---invariants (e.g. role/state) are enforced. Any other prop — function or
---primitive — is assigned directly to the instance field.
---@param w UIWidget
---@param props table
function R.ApplyProps(w, props)
    if not props then return end
    for k, v in pairs(props) do
        local setter = w["Set" .. k]
        if type(setter) == "function" then
            setter(w, v)
        else
            w[k] = v
        end
    end
end
