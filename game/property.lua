local property = {}

function property.PropertyTable(t, setter)
    this = {}
    setmetatable(t, {
        __index = t,
        __newindex = function(_, k, v)
            setter(t, k, v)
            t[k] = v
        end
    })
    return this
end

return property