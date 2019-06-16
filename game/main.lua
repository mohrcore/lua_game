DEBUG = true
RESPATHS = {}

local playerset_mod = require "playerset"
local vector_mod = require "vector"

function configureResPaths()
    RESPATHS["player"] = "data/img/ball1.png"
end

function love.conf(t)
    t.console = DEBUG
end

function love.load()
    local ww = love.graphics.getWidth()
    local wh = love.graphics.getHeight()
    configureResPaths()
    playerset = playerset_mod.PlayerSet(ww, wh, vector_mod.Vector{ww / 2.0 ,wh / 2.0}, love.graphics.newImage(RESPATHS["player"]))
end

function love.update(dt)
    updatePlayer(dt)
end

function love.draw()
    for sprite, _ in pairs(playerset.player_sprites) do
        sprite:draw()
    end
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
    pressedKey("z", function()
        playerset:splitSprites(vector_mod.Vector{playerset.split_delta, 0.0})
    end)
--[[     pressedKey("right", function()
        playerset:moveSprites(vector_mod.Vector{playerset.move_delta, 0,0})
    end)
    pressedKey("left", function()
        playerset:moveSprites(vector_mod.Vector{-playerset.move_delta, 0,0})
    end) ]]
    downKey("right", function()
        playerset:moveSprites(vector_mod.Vector{playerset.move_delta, 0,0} * dt * 10)
    end)
    downKey("left", function()
        playerset:moveSprites(vector_mod.Vector{-playerset.move_delta, 0,0} * dt * 10)
    end)
    pressedKey("c", function()
        for sprite, _ in pairs(playerset.player_sprites) do
            playerset:moveSprite(sprite, vector_mod.Vector{0.0, -1.0 * playerset.move_delta})
            break
        end
    end)
end

function table.concatSeq(t1, t2)
    local t1sz = #t1
    for i = 1, #t2 do
        t1[t1sz + i] = t2[i]
    end
end
