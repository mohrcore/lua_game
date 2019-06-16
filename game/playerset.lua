playerset = {}

local sprite_mod = require "sprite"
local table_ext_mod = require "table_ext"
local proximitygrid_mod = require "proximitygrid"


PlayerSetMetatable = {
    __index = {
        player_sprites = {},
        proximity_grid = {},
        move_delta = 48,
        split_delta = 96,
        moveSprites = function(self, vec)
            for sprite, _ in pairs(self.player_sprites) do
                local new_position = sprite.position + vec
                self.proximity_grid:teleportBody(sprite, sprite.position, new_position)
                sprite.position = new_position
            end
            self.proximity_grid:step() --check for overlaps and execute overlap logic if necessary
        end,
        splitSprites = function(self, vec)
            local clones = {}
            for sprite, _ in pairs(self.player_sprites) do
                local clone = sprite:clone()
                local p_sprite_position = sprite.position:clone()
                sprite.position = sprite.position + vec
                clone.position = clone.position - vec
                self.proximity_grid:teleportBody(sprite, p_sprite_position, sprite.position)
                local clones_val = true
                --switch out-of-bounds-callback to remove sprites from clones set, instead of player_sprites set.
                local outOfBoundsCallback = self.proximity_grid.outOfBoundsCallback
                self.proximity_grid.outOfBoundsCallback = function(body)
                    clones_val = nil
                end
                self.proximity_grid:addBody(clone, clone.position)
                self.proximity_grid.outOfBoundsCallback = outOfBoundsCallback
                clones[clone] = clones_val
            end
            table_ext_mod.mergeSets(self.player_sprites, clones)
            self.proximity_grid:step() --check for overlaps and execute overlap logic if necessary
--[[             --debig
            local sprite_count = 0
            for _, _ in pairs(self.player_sprites) do
                sprite_count = sprite_count + 1
            end
            print("sprite cnt: " .. sprite_count) ]]
        end,
        moveSprite = function(self, sprite, vec)
            local new_position = sprite.position + vec
            self.proximity_grid:teleportBody(sprite, sprite.position, new_position)
            sprite.position = new_position
            self.proximity_grid:step()
        end
    }
}

function playerset.PlayerSet(area_width, area_height, initial_pos, image)
    local initial_sprite = sprite_mod.Sprite(image)
    initial_sprite.position = initial_pos
    local this = {
        proximity_grid = proximitygrid_mod.ProximityGrid(area_width, area_height, 16, 16),
        player_sprites = {}
    }
    this.player_sprites[initial_sprite] = true
    setmetatable(this, PlayerSetMetatable)
    this.proximity_grid.overlap_radius = 2.0 --px
    --behaviour on overlap
    this.proximity_grid.proximityCallback = function(sprite1, sprite2, gridctrl)
        this.player_sprites[sprite2] = nil
        gridctrl.removeBody(sprite2)
    end
    this.proximity_grid.outOfBoundsCallback = function(sprite)
        this.player_sprites[sprite] = nil
    end
    this.proximity_grid:addBody(initial_sprite, initial_pos)
    return this
end

return playerset