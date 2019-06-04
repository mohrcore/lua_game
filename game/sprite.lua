local sprite = {}

--local delegate_mod require "delegate"
local vector_mod = require "vector"

SpriteMetatable = {
    __index = {
        position = {},
        channel = {},
        setPosition = function(self, x, y)
            local last = self.position:clone()
            self.position.values[1] = x
            self.position.values[2] = y
            self.channel:push({
                tag = "transform",
                body = {
                    transform_tyoe = "position",
                    last = last,
                    vec = vector.Vector{x, y}
                }
            })
        end
        move = function(self, x, y)
            last = self.position:clone()
            self.position.values[1] = position.values[1] + x
            self.position.values[2] = position.values[2] + y
            self.channel:push({
                tag = "transform",
                sender = self,
                body = {
                    transform_type = "translate",
                    last = last
                    vec = self.position:clone()
                }
            })

        end
    }
}

function sprite.Sprite(channel)
    local s_channel = channel
    if s_channel == nil then s_channel = love.thread.newChannel()
    local this = {
        position = vector_mod.Vector{0.0, 0.0}
        channel = s_channel
    }
    setmetatable(this, SpriteMetatable)
    return this
end

return sprite