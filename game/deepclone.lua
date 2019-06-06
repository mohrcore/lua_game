deepclone = {}

-- Save copied tables in `copies`, indexed by original table.
function deepClone(orig, copies)
    copies = copies or {}
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        if copies[orig] then
            copy = copies[orig]
        else
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                if orig_value.clone then
                    copy[orig_key] = orig_value:clone()
                else
                    copy[orig_key] = deepClone(orig_value, copies)
                end
            end
            setmetatable(copy, getmetatable(orig))
            copies[orig] = copy
        end
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function deepclone.implementGenericClone(object)
    object.clone = deepClone
end

return deepclone