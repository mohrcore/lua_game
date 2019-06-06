playerset = {}

local sprite_mod = require "sprite"
local table_ext_mod = require "table_ext"

local function getOverlapGridCellForPosition(ogrid, position)
    local x = math.floor(position.values[1] * #ogrid.grid / ogrid.real_width) + 1
    local y = math.floor(position.values[2] * #ogrid.grid[1] / ogrid.real_width) + 1
    --print("X: " .. x .. " Y: " .. y)
    if ogrid.grid[x] == nil then
        --print("x: " .. x .. " y: " .. y)
        return nil, x, y
    end
    return ogrid.grid[x][y], x, y
end

local function scheduleOverlapGridBodyRemoval(ogrid, body, position)
    ogrid.bodies_to_remove[#ogrid.bodies_to_remove + 1] = {
        body = body,
        position = position
    }
end

local function removeScheduledOverlapGridBodies(ogrid)
    for i, v in ipairs(ogrid.bodies_to_remove) do
        local cell = getOverlapGridCellForPosition(ogrid, v.position)
        cell[v.body] = nil
        ogrid.bodies_to_remove[i] = nil
    end
    ogrid.bodies_to_remove = {}
end

local function checkGridOverlap(ogrid, cx, cy, body, position, radius)
    local hr = math.floor(radius / 2)
    for i = cx - hr, cx + hr do
        for j = cy - hr, cy + hr do
            local cell
            if ogrid.grid[i] then
                cell = ogrid.grid[i][j]
            else
                cell = nil
            end
            if cell ~= nil then
                for b_body, b_position in pairs(cell) do
                    if b_body ~= body and ogrid.bodies_checked[b_body] == nil and (b_position - position):length() <= radius then
                        ogrid.overlapCallback(body, b_body, {
                            removeBody = function(b)
                                if b == body then
                                    scheduleOverlapGridBodyRemoval(ogrid, b, position)
                                elseif b == b_body then
                                    scheduleOverlapGridBodyRemoval(ogrid, b, b_position)
                                end
                            end
                            })
                    end
                end
            end
        end
    end
end

OverlapGridMetatable = {
    __index = {
        real_width = 0.0,
        real_height = 0.0,
        grid = {},
        overlapCallback = nil,
        outOfBoundsCallback = nil,
        bodies_to_remove = {},
        bodies_to_check = {},
        bodies_checked = {},
        overlap_radius = 0.0,
        addBody = function(self, body, position)
            local cell, cx, cy = getOverlapGridCellForPosition(self, position)
            if cell == nil then
                self.outOfBoundsCallback(body)
                return false
            end
            if cell[body] then return false end
            cell[body] = position
            self.bodies_to_check[body] = position
            --checkGridOverlap(self, cx, cy, body, position, self.overlap_radius) --remove! this should be done in step!
            return true
        end,
        removeBody = function(self, body, position)
            local cell = getOverlapGridCellForPosition(self, position)
            if cell == nil then return false end
            if cell[body] == nil then return false end
            cell[body] = nil
            return true
        end,
        updateBody = function(self, body, source, destination)
            local src_cell = getOverlapGridCellForPosition(self, source)
            local dst_cell, cx, cy = getOverlapGridCellForPosition(self, destination)
            if src_cell == nil then return false end
            if src_cell[body] == nil then
                print "this shouldn't have happend!"
                return false
            end
            if dst_cell == nil then --handle out-of-grid situations
                self.outOfBoundsCallback(body)
                src_cell[body] = nil
                return false
            end
            if src_cell ~= dst_cell then
                src_cell[body] = nil
            end
            dst_cell[body] = destination
            self.bodies_to_check[body] = destination
            --checkGridOverlap(self, cx, cy, body, destination, self.overlap_radius) --remove! this should be done in step!
            return true
        end,
        step = function(self)
            for body, position in pairs(self.bodies_to_check) do
                local _, cx, cy = getOverlapGridCellForPosition(self, position)
                checkGridOverlap(self, cx, cy, body, position, self.overlap_radius)
                self.bodies_to_check[body] = nil --safe????
                self.bodies_checked[body] = true
            end
            removeScheduledOverlapGridBodies(self)
            self.bodies_checked = {}
        end
    }
}

function playerset.OverlapGrid(real_width, real_height, columns, rows)
    grid = {}
    for i = 1, columns do
        grid[i] = {}
        for j = 1, rows do
            grid[i][j] = {}
        end
    end
    local this = {
        grid = grid,
        real_width = real_width,
        real_height = real_height,
    }
    setmetatable(this, OverlapGridMetatable)
    return this
end

PlayerSetMetatable = {
    __index = {
        player_sprites = {},
        overlap_grid = {},
        move_delta = 48,
        split_delta = 96,
        moveSprites = function(self, vec)
            for sprite, _ in pairs(self.player_sprites) do
                local new_position = sprite.position + vec
                self.overlap_grid:updateBody(sprite, sprite.position, new_position)
                sprite.position = new_position
            end
            self.overlap_grid:step() --check for overlaps and execute overlap logic if necessary
        end,
        splitSprites = function(self, vec)
            local clones = {}
            for sprite, _ in pairs(self.player_sprites) do
                local clone = sprite:clone()
                local p_sprite_position = sprite.position:clone()
                sprite.position = sprite.position + vec
                clone.position = clone.position - vec
                self.overlap_grid:updateBody(sprite, p_sprite_position, sprite.position)
                local clones_val = true
                --switch out-of-bounds-callback to remove sprites from clones set, instead of player_sprites set.
                local outOfBoundsCallback = self.overlap_grid.outOfBoundsCallback
                self.overlap_grid.outOfBoundsCallback = function(body)
                    clones_val = nil
                end
                self.overlap_grid:addBody(clone, clone.position) --clone is not deleted if it steps outside of the grid!
                self.overlap_grid.outOfBoundsCallback = outOfBoundsCallback
                clones[clone] = clones_val
            end
            table_ext_mod.mergeSets(self.player_sprites, clones)
            self.overlap_grid:step() --check for overlaps and execute overlap logic if necessary
--[[             --debig
            local sprite_count = 0
            for _, _ in pairs(self.player_sprites) do
                sprite_count = sprite_count + 1
            end
            print("sprite cnt: " .. sprite_count) ]]
        end
    }
}

function playerset.PlayerSet(area_width, area_height, initial_pos, image)
    print "dupa"
    local initial_sprite = sprite_mod.Sprite(image)
    initial_sprite.position = initial_pos
    local this = {
        overlap_grid = playerset.OverlapGrid(area_width, area_height, 16, 16),
        player_sprites = {}
    }
    this.player_sprites[initial_sprite] = true
    setmetatable(this, PlayerSetMetatable)
    this.overlap_grid.overlap_radius = 2.0 --px
    --behaviour on overlap
    this.overlap_grid.overlapCallback = function(sprite1, sprite2, gridctrl)
        --print "aaaaaaa"
        this.player_sprites[sprite2] = nil
        gridctrl.removeBody(sprite2)
    end
    this.overlap_grid.outOfBoundsCallback = function(sprite)
        --print("out of bounds! " .. tostring(sprite.position))
        this.player_sprites[sprite] = nil
    end
    this.overlap_grid:addBody(initial_sprite, initial_pos)
    return this
end

return playerset