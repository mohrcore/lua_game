local maptile  = {}

local vector_mod = require "vector"
local table_ext_mod = require "table_ext"
local multisprite_mod = require "multisprite"

local tile_layers = {
    "tile_hole",
    "tile_wall",
    "tile_arrow_left",
    "tile_arrow_right",
    "tile_arrow_up",
    "tile_star",
    "tile_finish"
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

local tile_layers = {
    hole = 1,
    wall = 2,
    arrow_left = 3,
    arrow_right = 4,
    arrow_up = 5,
    star = 6,
    finish = 7
}

local tile_type_props_to_layer_name = {
    arrow = function(props)
        local direction_to_layer_name_map = {
            left = "arrow_left",
            right = "arrow_right",
            up = "arrow_up"
        }
        return direction_to_layer_name_map[props.direction]
    end
}

function maptile.MapTile(tile_type, properties)
    local layer_name
    if properties and tile_type_props_to_layer_name[tile_type] then
        layer_name = tile_type_props_to_layer_name[tile_type](properties)
    else
        layer_name = tile_type
    end
    return {
        layer = tile_layers[layer_name],
        type = tile_type,
        props = properties
    }
end

function maptile.getTileset()
    return resources["tile_array_img"]
end

return maptile