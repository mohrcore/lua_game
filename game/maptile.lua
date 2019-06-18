local maptile  = {}

local vector_mod = require "vector"
local table_ext_mod = require "table_ext"
local multisprite_mod = require "multisprite"

local tile_layers = {
    "tile_hole",
    "tile_wall"
}

local resources = {}

function maptile.loadResources()
    local paths = table_ext_mod.mapSeq(tile_layers, function(name)
        return RESPATHS[name]
    end)
    local tile_array_img = love.graphics.newArrayImage(paths)
    tile_array_img:setWrap("repeat", "repeat")
    resources["tile_array_img"] = tile_array_img
end

local square_tileshape = love.physics.newRectangleShape(1, 1)

local function makeTileBody(world, position, w, h)
    local px, py = (position / love.physics.getMeter()):unpack()
    print("tile body: [x: " .. px .. " y: " .. py .. "]")
    local body = love.physics.newBody(world, px, py, "dynamic")
    local tileshape
    if w == 1 and h == 1 then
        tileshape = square_tileshape
    else
        tileshape = love.physics.newRectangleShape(w / 2.0 - 0.5, h / 2.0 - 0.5, w, h)
    end
    local fixture = love.physics.newFixture(body, tileshape)
    return body, {fixture}
end

local function collides(ctable, other_body)
    local ob_data = other_body:getUserData()
    if not ob_data then return false end
    if ctable[ob_data.collision_tag] then
        return true
    end
    return false
end

function maptile.Hole(scene, position, w, h)
    local body, refs = makeTileBody(scene.box2dworld, position, w, h)
    local sprite = multisprite_mod.MultiSprite(resources["tile_array_img"], 1, position)
    sprite.rows = h
    sprite.columns = w
    body:setUserData({
        tag = "hole",
        collision_tag = "pass-through",
        collides_with = {},
        onCollision = function(other_body, id)
            local ob_udata = other_body:getUserData()
            if not ob_udata then return end
            if ob_udata.tag == "player_instance_heart" then
                print "doopa"
                ob_udata:destroyMe()
            end
        end,
        collides = function(other_body)
            return collides({}, other_body)
        end
    })
    local actor = {
        sprite = sprite,
        body = body,
        refs  = refs
    }
    return actor
end


return maptile