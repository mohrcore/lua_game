local maptile  = {}

local vector_mod = require "vector"

MapTileMetatable = {
    __index = {
        functionality = {},
        image = {}
    }
}

function maptile.MapTile(functionality, image)
    local this = {}
    setmetatable(this, MapTileMetatable)
    return this
end

HoleMetatable = {
    __index = {
        solid = false,
        onPlayerCollision = function(self, playerset, instance)
            instance:remove()
        end
    }
}
ArrowMetatable = {
    __index = {
        solid = false,
        distance = 1,
        direction = "up",
        onPlayerCollision = function(self, playerset, instance)
            local dvec
            if self.direction == "up" then
                dvec = vector_mod.Vector{0.0, -1.0}
            elseif self.direction == "down" then
                dvec = vector_mod.Vector{0.0, 1.0}
            elseif self.direction == "left" then
                dvec = vector_mod.Vector{-1.0, 0.0}
            elseif self.direction == "right" then
                dvec = vector_mod.Vector{1.0, 0.0}
            end
            instance:move(dvec * (playerset.move_delta * distance))
        end
    }
}
WallMetatable = {
    __index = {
        solid = true
    }
}
FloorMetatable = {
    __index = {
        solid = false
    }
}


return maptile