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
---Props with a `Set<Name>` setter MUST go through the setter — primitives
---without a setter are a misuse (silent field writes bypass invariants like
---role/state coupling). Function values without a setter are allowed as a
---direct assignment escape hatch for screen-supplied callbacks.
---@param w UIWidget
---@param props table
function R.ApplyProps(w, props)
    if not props then return end
    for k, v in pairs(props) do
        local setter = w["Set" .. k]
        if type(setter) == "function" then
            setter(w, v)
        elseif type(v) == "function" then
            w[k] = v
        else
            print("CAI widget registry: prop '" .. tostring(k) .. "' on "
                .. tostring(w.Type or "?") .. " has no Set" .. tostring(k)
                .. " setter; primitive props must use the setter contract.")
        end
    end
end
