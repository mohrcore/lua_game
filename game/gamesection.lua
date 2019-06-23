local gamesection = {}

local GameSectionMetatable = {
    __index = {
        init = function(self) end,
        update = function(self, dt) end,
        draw = function(self) end,
        close = function(self) end,
    }
}

function gamesection.GameSection()
    local this = {}
    setmetatable(this, GameSectionMetatable)
    return this
end

return gamesection