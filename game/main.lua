DEBUG = true
RESPATHS = {}

local playercontroller_mod = require "playercontroller"
local scene_mod = require "scene"
local vector_mod = require "vector"

local maptile_mod = require "maptile"

function configureResPaths()
    RESPATHS["player"] = "data/img/ball1.png"
    RESPATHS["tile_hole"] = "data/img/tiles/hole.png"
    RESPATHS["tile_wall"] = "data/img/tiles/wall.png"
end

function love.conf(t)
    t.console = DEBUG
end

function love.load()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    configureResPaths()
    maptile_mod.loadResources()
    love.physics.setMeter(48)
    scene = scene_mod.Scene()
    test_hole = maptile_mod.Hole(scene, vector_mod.Vector{48, 288}, 1, 1)
    scene.actors[test_hole] = true
    player_controller = playercontroller_mod.PlayerController(scene)
    player_controller:init(vector_mod.Vector{ww / 2.0, wh / 2.0})
end

function love.update(dt)
    updatePlayer(dt)
    scene:update(dt)
end

function love.draw()
    scene:drawActors()
end

KEY_DOWN = {}
function pressedKey(key, f)
    if love.keyboard.isDown(key) then
        if not KEY_DOWN[key] then
            f()
        end
        KEY_DOWN[key] = true
    else
        KEY_DOWN[key] = false
    end
end
function downKey(key, f)
    if love.keyboard.isDown(key) then
        f()
    end
end

function updatePlayer(dt)
    pressedKey("right", function()
        player_controller:move(vector_mod.Vector{48.0, 0,0})
    end)
    pressedKey("left", function()
        player_controller:move(vector_mod.Vector{-48.0, 0,0})
    end)
    pressedKey("z", function()
        player_controller:split(vector_mod.Vector{96, 0.0})
    end)
end
