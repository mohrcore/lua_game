local gamemap = {}

local maptile_mod = require "maptile"
local vector_mod = require "vector"

local GameMapMetatable = {
    __index = {
        columns = 0,
        layer1 = {},
        player_start = {}, --player starting position
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
            self.columns = w
            self.rows = h
        end,
    }
}

local char_to_tile = {
    ['.'] = {"empty"},
    ['o'] = {"hole"},
    ['#'] = {"wall"},
    ['<'] = {"arrow", {direction = "left"}},
    ['>'] = {"arrow", {direction = "right"}},
    ['A'] = {"arrow", {direction = "up"}},
    ['P'] = {"player_start"},
    ['*'] = {"star"}
}

local function loadGameMapFromFile(path)
    local file = love.filesystem.newFile(path)
    local ok, err = file:open('r')
    if not ok then
        file:close()
        return false, err
    end
    local map = {}
    local columns, rows
    local line_no = 1
    local player_start
    for line in file:lines() do
        if line_no == 1 then
            columns = string.len(line)
        end
        map[line_no] = {}
        local x = 1
        for c in line:gmatch'.' do
            if x > columns then break end
            local tile_name, tile_props = unpack(char_to_tile[c])
            if tile_name ~= "empty" and tile_name ~= "player_start" then
                map[line_no][x] = maptile_mod.MapTile(tile_name, tile_props)
            end
            if tile_name == "player_start" then
                player_start = vector_mod.Vector{x, line_no}
            end
            x = x + 1
        end
        line_no = line_no + 1
    end
    file:close()
    return true, map, columns, player_start
end

function gamemap.GameMap(filepath)
    local ok, gm, columns, player_start = loadGameMapFromFile(filepath)
    if not ok then
        error("An error has occured, when loadin a gamemap from path: \'" .. path .. "\'\n Details:\n" .. gm)
    end
    local this = {
        layer1 = gm,
        columns = columns,
        player_start = player_start
    }
    setmetatable(this, GameMapMetatable)
    return this
end

GameMapRendererMetatable = {
    __index = {
        columns = 0,   -- maximum number of colums to draw, draws all columns, when set to 0 or below (integer)
        rows = 0,      -- maximum number of rows to draw, draws all rows when set to 0 or belo (integer)
        camera = {},   -- camera position (in gamemap pixels)
        position = {}, -- position (in pixels)
        scale = {},    -- scaling for gamemap (nubmer)
        rotation = 0,  -- rotation (in radians)
        center = {},  -- center of gamemap's transforms (relative to size)
        gamemap = {},  -- gamemap to draw
        tileset = nil, -- a tileset used to reder the map (love.graphics.ArrayImage)
        draw = function(self)
            if self.gamemap.layer1[1] == nil then return end --empty gamemap
            local columns = self.columns
            local rows = self.rows
            if columns <= 0 then
                columns = self.gamemap.columns
            end
            if rows <= 0 then
                rows = #self.gamemap.layer1
            end
            local tw = self.tileset:getWidth()
            local th = self.tileset:getHeight()
            local x, y = (self.camera + vector_mod.Vector{((self.gamemap.columns - columns) * tw) / 2.0, ((#self.gamemap.layer1 - rows) * th) / 2.0}):unpack()
            for i = 1, rows do
                for j = 1, columns do
                    local row = self.gamemap.layer1[math.floor(i + y / tw)]
                    if row then
                        local tile = row[math.floor(j + x / th)]
                        if tile then
                            love.graphics.drawLayer(
                                self.tileset, tile.layer,
                                math.floor(self.position.values[1]), math.floor(self.position.values[2]),
                                self.rotation,
                                self.scale.values[1], self.scale.values[2],
                                math.floor(self.center.values[1] * columns * tw - ((j - 1) * tw - (x % tw))),
                                math.floor(self.center.values[2] * rows * th - ((i - 1) * th - (y % th)))
                            )
                        end
                    end
                end
            end
        end,
        getPixelWidth = function(self)
            if self.gamemap.layer1[1] == nil then return 0 end --empty gamemap
            local columns = self.columns
            if columns <= 0 or columns > self.gamemap.columns then
                columns = self.gamemap.columns
            end
            return columns * self.tileset:getWidth()
        end,
        getPixelHeight = function(self)
            if self.gamemap.layer1[1] == nil then return 0 end --empty gamemap
            local rows = self.rows
            if rows <= 0 or rows > #self.gamemap.layer1 then
                rows = #self.gamemap.layer1
            end
            return rows * self.tileset:getHeight()
        end,
    }
}

function gamemap.GameMapRenderer(gamemap, tileset)
    local this = {
        tileset = tileset,
        camera = vector_mod.Vector{0.0, 0.0},
        position = vector_mod.Vector{0.0, 0.0},
        scale = vector_mod.Vector{1.0, 1.0},
        center = vector_mod.Vector{0.5, 0.5},
        gamemap = gamemap,
    }
    setmetatable(this, GameMapRendererMetatable)
    return this
end

return gamemap