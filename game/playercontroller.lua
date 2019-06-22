local playercontroller = {}

local vector_mod = require "vector"
local sprite_mod = require "sprite"
local table_ext_mod = require "table_ext"

local function moveLogic(tile_ahead, tile_destination, tile_ahead_destination)
    local move_info = {
        move_ahead = true,
        move_side = true
    }
    if tile_ahead and tile_ahead.type == "wall" then
        move_info.move_ahead = false
    end
    if (tile_destination and tile_destination.type == "wall")
    or (tile_ahead_destination and tile_ahead_destination.type == "wall") then
        move_info.move_side = false
    end
    return move_info
end

--[[ local function splitLogic(tile_destination1, tile_destination2, tile_ahead_destination1, tile_ahead_destination2)
    local split_info = {
        
    }
end ]]

local function hashCellPosition(position)
    return math.floor(position.values[2]) % 128 + math.floor(position.values[1] * 128) --player nstances should get further away from themselves than 128 tiles,
end

local function updateLogic(tile, tile_ahead, another_instance_present)
    local ctrl = {
        destroy = false,
        move = nil,
        remove_tile = false,
        add_score = 0,
    }
    if another_instance_present then
        ctrl.destroy = true
        return ctrl
    end
    if tile and tile.type == "hole" then
        ctrl.destroy = true
    end
    if tile and tile.type == "wall" then
        ctrl.destroy = true
    end
    if tile_ahead and tile_ahead.type == "wall" then
        ctrl.destroy = true
    end
    if tile and tile.type == "arrow" then
        local move_vec
        if tile.props.direction == "left" then
            move_vec = vector_mod.Vector{-1, 0}
        elseif tile.props.direction == "right" then
            move_vec = vector_mod.Vector{1, 0}
        elseif tile.props.direction == "up" then
            move_vec = vector_mod.Vector{0, -1}
        end
        ctrl.move = move_vec
    end
    if ctrl.move then
        ctrl.destroy = false
    end
    if tile and tile.type == "star" then
        ctrl.add_score = 1
        ctrl.remove_tile = true
    end
    return ctrl
end

local function getTile(pc, x, y)
    if not pc.gamemap.layer1[y] then return nil end
    return pc.gamemap.layer1[y][x]
end

local function getTileAhead(pc, x, y)
    if y == math.ceil(y) then
        return getTile(pc, math.ceil(x), y)
    end
    return getTile(pc, math.ceil(x), math.floor(y))
end

local PlayerControllerMetatable = {
    __index = {
        gamemap = {},
        instances = {},
        instance_count_hm = {},
        score = 0,
        init = function(self, position)
            self.instances[position] = true
        end,
        move = function(self, vec, instance)
            local dx, dy = vec:unpack()
            local mov_fn = function(position)
                local to = position + vector_mod.Vector{dx, dy}
                self.instance_count_hm[hashCellPosition(position)] = self.instance_count_hm[hashCellPosition(position)] - 1
                self.instance_count_hm[hashCellPosition(to)] = self.instance_count_hm[hashCellPosition(to)] + 1
                local tile_destination = getTile(self, math.ceil(position.values[1] + dx), math.ceil(position.values[2] + dy))
                local tile_ahead = getTileAhead(self, position.values[1], position.values[2])
                local tile_ahead_destination = getTileAhead(self, position.values[1] + dx, position.values[2] + dy)
                local move_info = moveLogic(tile_ahead, tile_destination, tile_ahead_destination)
                if move_info.move_side then
                    position.values[1] = position.values[1] + dx
                end
                if move_info.move_ahead then
                    position.values[2] = position.values[2] + dy
                end
            end
            if instance == nil then
                for position, _ in pairs(self.instances) do
                    mov_fn(position)
                end
            else
                mov_fn(instance)
            end
        end,
        split = function(self, vec)
            --local dx, dy = vec:unpack()
            local newpositions = {}
            for position, _ in pairs(self.instances) do
                local clone = position:clone()
                local new_position = position + vec
                local new_clone_position = position - vec
                self.instance_count_hm[hashCellPosition(position)] = self.instance_count_hm[hashCellPosition(position)] - 1
                self.instance_count_hm[hashCellPosition(new_position)] = self.instance_count_hm[hashCellPosition(new_position)] + 1
                self.instance_count_hm[hashCellPosition(new_clone_position)] = self.instance_count_hm[hashCellPosition(new_clone_position)] + 1
                position.values[1] = position.values[1] + vec.values[1]
                position.values[2] = position.values[2] + vec.values[2]
                clone = new_clone_position
                newpositions[clone] = true
            end
            table_ext_mod.mergeSets(self.instances, newpositions)
        end,
        update = function(self)
            for position, _ in pairs(self.instances) do
                local tile = getTile(self, math.ceil(position.values[1]), math.ceil(position.values[2]))
                local tile_ahead = getTileAhead(self, position.values[1], position.values[2])
                local another_instance_present = false
                if self.instance_count_hm[hashCellPosition(position)] > 1 then
                    another_instance_present = true
                end
                local ul_result = updateLogic(tile, tile_ahead, another_instance_present)
                if ul_result.destroy == true then
                    self.instances[position] = nil
                    self.instance_count_hm[hashCellPosition(position)] = self.instance_count_hm[hashCellPosition(position)] - 1
                else
                    if ul_result.move then
                        self:move(ul_result.move, position)
                        --self:update() --?
                    end
                end
                if ul_result.remove_tile then
                    self.gamemap.layer1[math.ceil(position.values[2])][math.ceil(position.values[1])] = nil
                end
                self.score = self.score + ul_result.add_score
            end
        end
    }
}

function playercontroller.PlayerController(gamemap)
    local this = {
        gamemap = gamemap,
        instances = {}
    }
    setmetatable(this, PlayerControllerMetatable)
    setmetatable(this.instance_count_hm, {
        __index = function(self, k)
            return 0;
        end,
    })
    return this
end

return playercontroller