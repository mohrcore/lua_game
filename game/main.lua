DEBUG = true
RESPATHS = {}

PLAYER_MOV_X_SPEED = 500
PLAYER_DUPE_DIST = 96

mod_player = require "player"
mod_scene = require "scene"
mod_collisiongrid = require "collisiongrid"

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
    active_scene = mod_scene.Scene "Kool Scene"
    active_scene.player_collision_grid = mod_collisiongrid.CollisionGrid(
        16, --rows
        16, --columns
        ww, --window width
        wh, --window height
        16, --16 cells top margin
        16, --16 cells left margin
        16, --16 cells right margin
        16  --16 cells bottom margin
    )
    local player = active_scene.insertSprite(mod_player.Player(10, 200))
    active_scene.player_collision_grid.addBody(player)
    player_sprites = { sset = {} }
    player_sprites.sset[player] = true
    player_sprites.foreach = function(f)
        for k, _ in pairs(player_sprites.sset) do
            f(k)
        end
    end
end

function love.update(dt)
    updatePlayer(dt)
end

function love.draw()
    for k, _ in pairs(active_scene.sprites) do
        local x, y = k.getPosition()
        love.graphics.draw(k.sprite_img, math.floor(x), math.floor(y))
    end
end

zdown = false
function updatePlayer(dt)
    if love.keyboard.isDown "right" then
        player_sprites.foreach(function(player)
            player.speed.x = PLAYER_MOV_X_SPEED
        end)
    elseif love.keyboard.isDown "left" then
        player_sprites.foreach(function(player)
            player.speed.x = -PLAYER_MOV_X_SPEED
        end)
    else
        player_sprites.foreach(function(player)
            player.speed.x = 0
        end)
    end
    player_sprites.foreach(function(player)
        local posx, posy = player.getPosition()
        player.setPosition(posx + player.speed.x * dt, posy)
    end)
    if love.keyboard.isDown "z" then
        if not zdown then
            zdown = true
            local clones = {}
            player_sprites.foreach(function(player)
                local posx, posy = player.getPosition()
                local ww = love.graphics.getWidth()
                if posx >= -ww + PLAYER_DUPE_DIST and posx <= 2 * ww - PLAYER_DUPE_DIST then
                    local clone = active_scene.insertSprite(player.clone())
                    player.setPosition(posx - PLAYER_DUPE_DIST, posy)
                    clone.setPosition(posx + PLAYER_DUPE_DIST, posy)
                    active_scene.player_collision_grid.addBody(clone)
                    clones[clone] = true
                else
                    active_scene.removeSprite(player)
                    player_sprites.sset[player] = nil
                    active_scene.player_collision_grid.removeBody(player)
                end
            end)
            --table.concatSeq(player_sprites, clones)
            table.mergeSets(player_sprites.sset, clones)
        end
    else
        zdown = false
    end
    --remove overlapping player sprites
    player_sprites.foreach(function(sprite)
        local x, y = sprite.getPosition()
        for body in active_scene.player_collision_grid.withinDistance(x, y, 3) do
            --print "bodi"
            if body ~= sprite then
                print "remvd"
                active_scene.removeSprite(body)
                player_sprites.sset[body] = nil
                active_scene.player_collision_grid.removeBody(body)
            end
        end
    end)
end

function table.concatSeq(t1, t2)
    local t1sz = #t1
    for i = 1, #t2 do
        t1[t1sz + i] = t2[i]
    end
end

function table.mergeSets(t1, t2, ...)
    if t2 == nil then
        return t1
    else
        for k, v in pairs(t2) do
            if t1[k] == nil then
                t1[k] = v
            end
        end
        table.mergeSets(t1, ...)
    end
end
