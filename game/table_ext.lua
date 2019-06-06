local table_ext = {}

function table_ext.mergeSets(t1, t2, ...)
    if t2 == nil then
        return t1
    else
        for k, v in pairs(t2) do
            if t1[k] == nil then
                t1[k] = v
            end
        end
        table_ext.mergeSets(t1, ...)
    end
end

return table_ext