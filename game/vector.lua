local vector = {}

local VectorMetatable = {
    __index = {
        clone = function(self)
            return vector.Vector(self.values)
        end
    },
    __len = function(t)
        local s = 0
        for _, v in ipairs(t.values) do
            s = s + v * v
        end
        return math.sqrt(s)
    end,
    __add = function(a, b)
        local t = {};
        for i=1, #a.values do
            t[i] = a.values[i] + b.values[i]
        end
        return vec.Vector(t)
    end,
    __sub = function(a, b)
        local t = {};
        for i=1, #a.values do
            t[i] = a.values[i] - b.values[i]
        end
        return vec.Vector(t)
    end,
    __mul = function (a, b)
        local function dot(a, b)
            local p = 0
            for i=1, #a.values do
                p = p + a.values[i] * b.values[i]
            end
            return p
        end
        local function scale(v, s)
            local t = {};
            for i=1, #v.values do
                t[i] = v.values[i] * s
            end
            return vec.Vector(t)
        end
        if type(a) == "number" then
            return scale(b, a)
        end
        if type(b) == "number" then
            return scale(a, b)
        end
        return dot(a, b)
    end,
    __div = function(v, s)
        local t = {};
        for i=1, #v.values do
            t[i] = v.values[i] / s
        end
        return vec.Vector(t)
    end,
    __tostring = function(v)
        local t = { "(" }
        for i=1, #v.values-1 do
            table.insert(t, tostring(v.values[i]) .. ", ")
        end
        if #v.values > 0 then
            table.insert(t, tostring(v.values[#v.values]))
        end
        table.insert(t, ")");
        return table.concat(t, "")
    end,
}

function vector.Vector(t)
    local o = {
        values = t
    }
    setmetatable(o, VectorMetatable)
    return o
end

return vector