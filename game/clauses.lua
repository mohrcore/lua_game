str = io.read "*all"

res = {}

for pos, neg in string.gfind(str, "res%-clauses %(([^%(%)]*)%) %(([^%(%)]*)%)") do
    if not pos then pos = "" end
    if not neg then neg = "" end
    table.insert(res, { p = pos, n = neg })
end

for _, v in ipairs(res) do
    print("Clause: pos: " .. v.p .. ", neg: " .. v.n)
end