local gameplaysection = {}

local gamesection_mod = require "gamesection"

local table_ext_mod = require "table_ext"

local scene_mod = require "scene"
local vector_mod = require "vector"
local resources_mod = require "resources"

local maptile_mod = require "maptile"
local gamemap_mod = require "gamemap"
local playercontroller_mod = require "playercontroller"
local playerrenderer_mod = require "playerrenderer"
local cameracontroller_mod = require "cameracontroller"
local hud_mod = require "hud"

function gameplaysection.GameplaySection()
    local this = gamesection_mod.GameSection()
    this.init = function(self, map, onwin, onlose)
        self.ww = love.graphics.getWidth()
        self.wh = love.graphics.getHeight()
        resources_mod.configureResPaths()
        maptile_mod.loadResources()
        self.scene = scene_mod.Scene()
        local gamemap = gamemap_mod.GameMap(RESPATHS[map])
        self.gamemap_renderer = gamemap_mod.GameMapRenderer(gamemap, maptile_mod.getTileset())
        self.scene:setCamera(vector_mod.Vector{0.0, #gamemap.layer1 * self.gamemap_renderer.tileset:getHeight() / 2.0})
        --self.gamemap_renderer.rotation = 0.3
        self.gamemap_renderer.position = vector_mod.Vector{self.ww / 2.0, self.wh / 2.0}
        self.gamemap_renderer.scale = vector_mod.Vector{1, 1}
        self.gamemap_renderer.columns = self.ww / self.gamemap_renderer.tileset:getWidth() + 2
        self.gamemap_renderer.rows = self.wh / self.gamemap_renderer.tileset:getHeight() + 2
        self.gamemap_renderer.camera = self.scene.camera
        local gm_actor = {
            drawable = self.gamemap_renderer
        }
        self.scene:addActor(gm_actor)
        self.player_controller = playercontroller_mod.PlayerController(gamemap)
        self.player_controller.onWin = onwin
        self.player_controller.onLose = onlose
        local starting_pos = gamemap.player_start
        if not starting_pos.values then
            starting_pos = vector_mod.Vector{1, 1}
        end
        self.player_controller:init(starting_pos)
        local player_img = love.graphics.newImage(RESPATHS["player"])
        self.player_renderer = playerrenderer_mod.PlayerRenderer(self.player_controller, player_img, gamemap.columns, #gamemap.layer1)
        --self.player_renderer.rotation = 0.3
        self.player_renderer.position = vector_mod.Vector{self.ww / 2.0, self.wh / 2.0}
        self.player_renderer.scale = vector_mod.Vector{1, 1}
        self.player_renderer.camera = self.scene.camera
        local pr_actor = {
            drawable = self.player_renderer
        }
        self.scene:addActor(pr_actor)
        self.camera_controller = cameracontroller_mod.CameraController(self.scene.camera, self.player_controller, self.gamemap_renderer)
        self.camera_controller.stiffness = 2.0
        self.hud = hud_mod.Hud(self.player_controller, 0, 0, self.ww, self.wh)
        self.hud.pts_font = love.graphics.newFont(RESPATHS["font_gumball"], 96)
        self.hud.instances_font = love.graphics.newFont(RESPATHS["font_gumball"], 32)
    end
    this.update = function(self, dt)
        local speed = 100.0
        local speed_vec = vector_mod.Vector{0, -150}
        self.player_controller:move(vector_mod.Vector{0.0, -speed * dt / self.gamemap_renderer.tileset:getHeight()})
        self:updatePlayer(dt)
        self.camera_controller:update(dt, speed_vec)
    end
    this.updatePlayer = function(self, dt)
        pressedKey("right", function()
            self.player_controller:move(vector_mod.Vector{1.0, 0})
        end)
        pressedKey("left", function()
            self.player_controller:move(vector_mod.Vector{-1, 0})
        end)
        pressedKey("z", function()
            self.player_controller:split(vector_mod.Vector{2, 0})
        end)
        self.player_controller:update()
    end
    this.draw = function(self)
        self.scene:drawActors()
        self.hud:draw()
    end
    return this
end

return gameplaysection