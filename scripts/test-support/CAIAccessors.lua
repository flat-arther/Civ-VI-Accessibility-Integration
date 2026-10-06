-- Install the real caiUtils service accessors without bootstrapping game APIs.
return function(api)
    local file = assert(io.open('src/UI/shared/caiUtils.lua', 'rb'))
    local source = file:read('a'); file:close()
    local last = assert(source:find('include("textProcessing")', 1, true))
    local env = { ExposedMembers = { CAI = api } }
    assert(load(source:sub(1, last - 1), '@caiUtils accessors', 't', env))()
    return env.CAI
end
