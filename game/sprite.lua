local sprite = {}

--local delegate_mod require "delegate"
local vector_mod = require "vector"
local deepclone_mod = require "deepclone"

SpriteMetatable = {
    __index = {
        position = {},
        rotation = 0.0,
        scale = {},
        img = {},
        draw = function(self)
            love.graphics.draw(
                self.img,
                math.floor(self.position.values[1]), math.floor(self.position.values[2]),
                self.rotation,
                self.scale.values[1], self.scale.values[2],
                self.img:getWidth() * self.scale.values[1] / 2.0, self.img:getHeight() * self.scale.values[2] / 2.0)
        end
    }
}
deepclone_mod.implementGenericClone(SpriteMetatable.__index)

function sprite.Sprite(image)
    local this = {
        position = vector_mod.Vector{0.0, 0.0},
        scale = vector_mod.Vector{1.0, 1.0},
        img = image
    }
    setmetatable(this, SpriteMetatable)
    return this
end

return sprite