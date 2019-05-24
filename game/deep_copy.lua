local deep_copy = {}

function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function deepClone(orig) --uses o.clone() insted of assignement/deepCopy when possible
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        local copy
        if (type(orig.clone) == 'function') then
            copy = orig.clone()
        else
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[deepCopy(orig_key)] = deepCopy(orig_value)
            end
            setmetatable(copy, deepCopy(getmetatable(orig)))
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

return deep_copy