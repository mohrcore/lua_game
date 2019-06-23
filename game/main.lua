DEBUG = true
RESPATHS = {}

local scene_mod = require "scene"
local vector_mod = require "vector"
local resources_mod = require "resources"

local maptile_mod = require "maptile"
local gameplaysection_mod = require "gameplaysection"
local endscreen_section_mod = require "endscreensection"

function love.conf(t)
    t.console = DEBUG
end

CURRENT_SECTION = {
    instance = nil
}

SECTION_SWITCHES = {}

local function switchToGamePlay(map)
    if CURRENT_SECTION.instance then CURRENT_SECTION.instance:close() end
    CURRENT_SECTION.instance = gameplaysection_mod.GameplaySection()
    CURRENT_SECTION.instance:init("coolmap1", function()
        local score = CURRENT_SECTION.instance.player_controller.score
        SECTION_SWITCHES.switchToEndScreen(score, true)
    end, function()
        local score = CURRENT_SECTION.instance.player_controller.score
        SECTION_SWITCHES.switchToEndScreen(score, false)
    end)
end

local function switchToEndScreen(score, wl)
    if CURRENT_SECTION.instance then CURRENT_SECTION.instance:close() end
    CURRENT_SECTION.instance = endscreen_section_mod.EndScreenSection(score, wl)
    CURRENT_SECTION.instance:init(function()
        SECTION_SWITCHES.switchToGamePlay("coolmap1")
    end)
end

SECTION_SWITCHES.switchToGamePlay = switchToGamePlay
SECTION_SWITCHES.switchToEndScreen = switchToEndScreen

function love.load()
    love.window.setMode(1024, 720)
    love.window.setTitle("SPLIT!")
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    resources_mod.configureResPaths()
    maptile_mod.loadResources()

    switchToGamePlay("coolmap1")
end

function love.update(dt)
    CURRENT_SECTION.instance:update(dt)
end

function love.draw()
    CURRENT_SECTION.instance:draw()
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
