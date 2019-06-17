local scene = {}

local sprite_mod = require "sprite"

local SceneMetatable = {
    __index = {
        actors = {},
        box2dworld = nil,
        update = function(self, dt)
            self.box2dworld:update(dt)
            for actor, _ in pairs(self.actors) do
                if actor.bodies and #actor.bodies >= 1 then
                    local px, py = actor.bodies[1]:getPosition()
                    local meter = love.physics.getMeter()
                    actor.sprite.position.values[1] = px * meter
                    actor.sprite.position.values[2] = py * meter
                end
            end
        end,
        drawActors = function(self)
            for actor, _ in pairs(self.actors) do
                actor.sprite:draw()
            end
        end
    }
}

function scene.Scene()
    local this = {
        box2dworld = love.physics.newWorld(0, 0)
    }
    setmetatable(this, SceneMetatable)
    local begin_contact = function(fixture1, fixture2, contact)
        local body1 = fixture1:getBody()
        local body2 = fixture2:getBody()
        local body1_udata = body1:getUserData()
        local body2_udata = body2:getUserData()
        if body1_udata and body1_udata.onCollision then
            body1_udata.onCollision(body2, 1)
        end
        if body2_udata and body2_udata.onCollision then
            body2_udata.onCollision(body1, 2)
        end
    end
    local end_contact = function(fixture1, fixture2, contact)
    end
    local pre_solve = function(fixture1, fixture2, contact)
        local body1 = fixture1:getBody()
        local body2 = fixture2:getBody()
        local body1_udata = body1:getUserData()
        local body2_udata = body2:getUserData()
        if body1_udata and not body1_udata.collides(body2) then
            contact:setEnabled(false)
            body1_udata.onCollision(body2, 1)
        end
        if body2_udata and not body2_udata.collides(body1) then
            contact:setEnabled(false)
            body2_udata.onCollision(body1, 2)
        end
--[[         if contact:getEnabled() then
            print "doopa"
        end ]]
    end
    local post_solve = function(fixture1, fixture2, contact)
    end
    this.box2dworld:setCallbacks(begin_contact, end_contact, pre_solve, post_solve)
    
    return this
end

return scene