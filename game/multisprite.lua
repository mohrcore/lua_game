local multisprite = {}

local vector_mod = require "vector"

local MultiSpriteMetatable = {
    __index = {
        array_image = nil, --love.graphics.Image
        sprite_idx = 1,
        scale = {}, --vector.Vector
        columns = 1,
        rows = 1,
        position = {}, --vector.Vector
        rotation = 0,
        draw = function(self)
            local px, py = self.position:unpack()
            local sx, sy = self.scale:unpack()
            local ssw = self.array_image:getWidth()
            local ssh = self.array_image:getHeight()
            local quad = love.graphics.newQuad(0, 0, ssw * self.columns, ssh * self.rows, ssw, ssh)
            love.graphics.drawLayer(
                self.array_image, self.sprite_idx,
                quad,
                math.floor(px), math.floor(py),
                self.rotation,
                sx, sy,
                ssw * sx / 2.0, ssh * sy / 2.0
            )
        end
    }
}

function multisprite.MultiSprite(array_image, idx, position)
    local this = {
        array_image = array_image,
        sprite_idx = idx,
        position = position:clone(),
        scale = vector_mod.Vector{1.0, 1.0}
    }
    setmetatable(this, MultiSpriteMetatable)
    return this
end

return multisprite