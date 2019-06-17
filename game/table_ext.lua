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

function table_ext.concatSeq(t1, t2)
    local t1sz = #t1
    for i = 1, #t2 do
        t1[t1sz + i] = t2[i]
    end
end

return table_ext