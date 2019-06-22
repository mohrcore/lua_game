local playerrenderer = {}

local vector_mod = require "vector"

local PlayerRendererMetatable = {
    __index = {
        playercontroller = {},
        columns = 0,
        rows = 0,
        camera = {},
        position = {},
        scale = {},
        rotation = 0,
        center = {},
        player_img = nil,
        draw = function(self)
            local tw = self.player_img:getWidth()
            local th = self.player_img:getHeight()
            local x, y = self.camera:unpack()
            for cell_position, _ in pairs(self.playercontroller.instances) do
                local xpos, ypos = cell_position:unpack()
                love.graphics.draw(
                    self.player_img,
                    math.floor(self.position.values[1]), math.floor(self.position.values[2]),
                    self.rotation,
                    self.scale.values[1], self.scale.values[2],
                    self.center.values[1] * self.columns * tw - ((xpos - 1) * tw - x),
                    self.center.values[2] * self.rows * th - ((ypos - 1) * th - y)
            )
            end
        end
    }
}

function playerrenderer.PlayerRenderer(playercontroller, player_img, columns, rows)
    local this = {
        playercontroller = playercontroller,
        camera = vector_mod.Vector{0.0, 0.0},
        position = vector_mod.Vector{0.0, 0.0},
        scale = vector_mod.Vector{1.0, 1.0},
        center = vector_mod.Vector{0.5, 0.5},
        player_img = player_img,
        columns = columns,
        rows = rows
    }
    setmetatable(this, PlayerRendererMetatable)
    return this
end

return playerrenderer