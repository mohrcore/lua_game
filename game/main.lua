DEBUG = true
RESPATHS = {}

local scene_mod = require "scene"
local vector_mod = require "vector"

local maptile_mod = require "maptile"
local gamemap_mod = require "gamemap"
local playercontroller_mod = require "playercontroller"
local playerrenderer_mod = require "playerrenderer"

function configureResPaths()
    RESPATHS["player"] = "data/img/ball1.png"
    RESPATHS["tile_hole"] = "data/img/tiles/hole.png"
    RESPATHS["tile_wall"] = "data/img/tiles/wall.png"
    RESPATHS["tile_arrow_left"] = "data/img/tiles/arrow_left.png"
    RESPATHS["tile_arrow_right"] = "data/img/tiles/arrow_right.png"
    RESPATHS["tile_arrow_up"] = "data/img/tiles/arrow_up.png"
    RESPATHS["tile_star"] = "data/img/tiles/star.png"
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
    local gamemap = gamemap_mod.GameMap("data/maps/testmap1.map")
    gamemap_renderer = gamemap_mod.GameMapRenderer(gamemap, maptile_mod.getTileset())
    scene:setCamera(vector_mod.Vector{0.0, gamemap_renderer:getPixelHeight() / 2.0})
    --gamemap_renderer.rotation = 0.3
    gamemap_renderer.position = vector_mod.Vector{ww / 2.0, wh / 2.0}
    gamemap_renderer.scale = vector_mod.Vector{1, 1}
    --gamemap_renderer.columns = 6
    --gamemap_renderer.rows = 6
    gamemap_renderer.camera = camera
    local gm_actor = {
        drawable = gamemap_renderer
    }
    scene:addActor(gm_actor)
    player_controller = playercontroller_mod.PlayerController(gamemap)
    local starting_pos = gamemap.player_start
    if not starting_pos.values then
        starting_pos = vector_mod.Vector{1, 1}
    end
    player_controller:init(starting_pos)
    local player_img = love.graphics.newImage(RESPATHS["player"])
    player_renderer = playerrenderer_mod.PlayerRenderer(player_controller, player_img, gamemap.columns, #gamemap.layer1)
    --player_renderer.rotation = 0.3
    player_renderer.position = vector_mod.Vector{ww / 2.0, wh / 2.0}
    player_renderer.scale = vector_mod.Vector{1, 1}
    player_renderer.camera = camera
    local pr_actor = {
        drawable = player_renderer
    }
    scene:addActor(pr_actor)
    --player_controller = playercontroller_mod.PlayerController(scene)
    --player_controller:init(vector_mod.Vector{ww / 2.0, wh / 2.0})
end

function love.update(dt)
    local speed = 150.0
    scene.camera.values[2] = scene.camera.values[2] - speed * dt
    player_controller:move(vector_mod.Vector{0.0, -speed * dt / gamemap_renderer.tileset:getHeight()})
    updatePlayer(dt)
    --scene:update(dt)
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
        player_controller:move(vector_mod.Vector{1.0, 0})
    end)
    pressedKey("left", function()
        player_controller:move(vector_mod.Vector{-1, 0})
    end)
    pressedKey("z", function()
        player_controller:split(vector_mod.Vector{2, 0})
    end)
    player_controller:update()
end
