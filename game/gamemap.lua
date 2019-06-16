local gamemap = {}

GameMapMetatable = {
    __index = {
        layer1 = {},
        layer2 = {},
        setDimensions = function(self, w, h)
            for i = 1, h do
                self.layer1[i] = {}
                for j = 1, w do
                    self.map[i][j] = false
                end
            end
            for i = 1, h do
                self.layer2[i] = {}
            end
        end
    }
}

function gamemap.GameMap()
    local this = {}
    setmetatable(this, GameMapMetatable)
    return this
end

GameMapRendererMetatable = {
    __index = {
        screen_width = 0,
        screen_height = 0,
        tile_w = 0,
        tile_h = 0,
        camera_x = 0.5,
        camera_y = 0.5,
        gamemap = {},
        spawnSpriteCallback = nil,
        drawGameMap = function(self, position)
            local left = (position.values[1] - (1.0 - self.camera_x) * self.screen_width) / self.tile_w
            local right = (position.values[1] + self.camera_x * self.screen_width) / self.tile_w
            local top  = (position.values[2] - (1.0 - self.camera_y) * self.screen_height) / self.tile_h
            local bottom = (position.values[2] + self.camera_y * self.screen_height) / self.tile_h
            for i = top, bottom do
                for j = left, right do
                    if self.gamemap.layer1[i][j] then
                        local l1tile = self.gamemap.layer1[i][j]
                        local l2tile = self.gamemap.layer2[i][j]
                        love.draw(l1tile.img, j * self.tile_w + offset_x, i * self.tile_h + offset_y) --todo: calculate offsets!
                    end
                end
            end
        end
    }
}

return gamemap