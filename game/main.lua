DEBUG = true
RESPATHS = {}

local scene_mod = require "scene"
local vector_mod = require "vector"
local resources_mod = require "resources"

local maptile_mod = require "maptile"
local gamemap_mod = require "gamemap"
local playercontroller_mod = require "playercontroller"
local playerrenderer_mod = require "playerrenderer"
local cameracontroller_mod = require "cameracontroller"

function love.conf(t)
    t.console = DEBUG
end

function love.load()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    resources_mod.configureResPaths()
    maptile_mod.loadResources()
    love.physics.setMeter(48)
    scene = scene_mod.Scene()
    local gamemap = gamemap_mod.GameMap("data/maps/testmap3.map")
    gamemap_renderer = gamemap_mod.GameMapRenderer(gamemap, maptile_mod.getTileset())
    scene:setCamera(vector_mod.Vector{0.0, #gamemap.layer1 * gamemap_renderer.tileset:getHeight() / 2.0})
    --gamemap_renderer.rotation = 0.3
    gamemap_renderer.position = vector_mod.Vector{ww / 2.0, wh / 2.0}
    gamemap_renderer.scale = vector_mod.Vector{1, 1}
    gamemap_renderer.columns = 19
    gamemap_renderer.rows = 15
    gamemap_renderer.camera = scene.camera
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
    player_renderer.camera = scene.camera
    local pr_actor = {
        drawable = player_renderer
    }
    scene:addActor(pr_actor)
    camera_controller = cameracontroller_mod.CameraController(scene.camera, player_controller, gamemap_renderer)
end

function love.update(dt)
    local speed = 150.0
    local speed_vec = vector_mod.Vector{0, -150}
    player_controller:move(vector_mod.Vector{0.0, -speed * dt / gamemap_renderer.tileset:getHeight()})
    updatePlayer(dt)
    camera_controller:update(dt, speed_vec)
    
    
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
