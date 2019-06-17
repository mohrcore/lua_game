local playercontroller = {}

local vector_mod = require "vector"
local sprite_mod = require "sprite"
local table_ext_mod = require "table_ext"

local player_shell_shape = love.physics.newCircleShape(0.5)
local player_heart_shape = love.physics.newCircleShape(0.1)


local function makePlayerBodies(scene, position, shelldata, heartdata)
    local shell = love.physics.newBody(scene.box2dworld, position.values[1], position.values[2], "dynamic")
    shell:setUserData(shelldata)
    local shell_fixture = love.physics.newFixture(shell, player_shell_shape)
    local heart = love.physics.newBody(scene.box2dworld, position.values[1], position.values[2], "dynamic")
    heart:setUserData(heartdata)
    local heart_fixture = love.physics.newFixture(heart, player_heart_shape)
    local pjoint = love.physics.newWeldJoint(shell, heart, position.values[1], position.values[2], false)
    return shell, heart, {shell_fixture, heart_fixture, pjoint}
end

local function collides(ctable, other_body)
    local ob_data = other_body:getUserData()
    if not ob_data then return false end
    if ctable[ob_data.collision_tag] then
        return true
    end
    return false
end

local function createPlayerShellData(actor, pc)
    local collides_with = {
        solid = true,
        player_barrier = true
    }
    return {
        tag = "player_instance",
        collision_tag = "player",
        collides_with = collides_with,
        onCollision = function(other_body, id) --id is used to disinguish two colliding bodies
        end,
        collides = function(other_body)
            collides(collides_with, other_body)
        end
    }
end

local function createPlayerHeartData(actor, pc)
    local collides_with = {}
    return {
        tag = "player_instance_heart",
        collisiton_tag = "player_heart",
        collides_with = collides_with,
        onCollision = function(other_body, id) --id is used to disinguish two colliding bodies
            local ob_data = other_body:getUserData()
            if not (ob_data and ob_data.tag) then return end
            if ob_data.tag == "player_instance_heart" and id == 2 then
                print "rmvd!"
                pc.scene.actors[actor] = nil --remove instance with id == 2
                pc.actors[actor] = nil
                for _, body in ipairs(actor.bodies) do
                    body:destroy()
                end
            end
        end,
        collides = function(other_body)
            collides(collides_with, other_body)
        end
    }
end

local function clonePlayerActor(actor, pc, position)
    local meter = love.physics.getMeter()
    local clone = {}
    clone.sprite = actor.sprite:clone()
    clone.sprite.position = position * meter
    local shell_data = createPlayerShellData(clone, pc)
    local heart_data = createPlayerHeartData(clone, pc)
    local clone_shell, clone_heart, refs = makePlayerBodies(scene, position, shell_data, heart_data)
    clone.bodies = {clone_shell, clone_heart}
    clone.refs = refs
    return clone
end

local PlayerControllerMetatable = {
    __index = {
        scene = {},
        actors = {},
        init = function(self, position)
            self.actors = {}
            local meter = love.physics.getMeter()
            local player_img = love.graphics.newImage(RESPATHS["player"])
            local sprite = sprite_mod.Sprite(player_img)
            sprite.position = position
            local actor = {
                sprite = sprite
            }
            local shell_data = createPlayerShellData(actor, self)
            local heart_data = createPlayerHeartData(actor, self)
            local player_shell, player_heart, refs = makePlayerBodies(self.scene, position / meter, shell_data, heart_data)
            actor.bodies = {player_shell, player_heart}
            actor.refs = refs
            self.actors[actor] = true
            self.scene.actors[actor] = true
        end,
        move = function(self, vec)
            local meter = love.physics.getMeter()
            for actor, _ in pairs(self.actors) do
                local shell = actor.bodies[1]
                local heart = actor.bodies[2]
                local cpx, cpy = shell:getPosition()
                local npx = cpx + vec.values[1] / meter
                local npy = cpy + vec.values[2] / meter
                heart:setPosition(npx, npy)
                shell:setPosition(npx, npy)
            end
        end,
        split = function(self, vec)
            print "split!"
            local meter = love.physics.getMeter()
            local clones = {}
            for actor, _ in pairs(self.actors) do
                local dpx = vec.values[1] / meter
                local dpy = vec.values[2] / meter
                local shell = actor.bodies[1]
                local clone = clonePlayerActor(actor, self, vector_mod.Vector{shell:getPosition()} - vector_mod.Vector{dpx, dpy})
                clones[clone] = true
                self.scene.actors[clone] = true
                local heart = actor.bodies[2]
                local clone_shell = clone.bodies[1]
                local clone_heart = clone.bodies[2]
                local cpx, cpy = shell:getPosition()
                heart:setPosition(cpx + dpx, cpy + dpy)
                shell:setPosition(cpx + dpx, cpy + dpy)
                --clone_heart:setPosition(cpx - dpx, cpy - dpy)
                --clone_shell:setPosition(cpx - dpx, cpy - dpy)
            end
            table_ext_mod.mergeSets(self.actors, clones)
        end
    }
}

function playercontroller.PlayerController(scene)
    local this = {
        scene = scene
    }
    setmetatable(this, PlayerControllerMetatable)
    return this
end

return playercontroller