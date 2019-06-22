local scene = {}

local sprite_mod = require "sprite"
local vector_mod = require "vector"

local SceneMetatable = {
    __index = {
        actors = {},
        camera = {},
        drawActors = function(self)
            for actor, _ in pairs(self.actors) do
                actor.drawable:draw()
            end
        end,
        setCamera = function(self, vec)
            self.camera.values[1] = vec.values[1]
            self.camera.values[2] = vec.values[2]
        end,
        addActor = function(self, actor)
            if actor.drawable.camera then
                actor.drawable.camera = self.camera
            end
            self.actors[actor] = true
        end,
        removeActor = function(self, actor)
            self.actors[actor] = nil
        end
    }
}

function scene.Scene()
    local this = {
        camera = vector_mod.Vector{0.0, 0.0}
    }
    setmetatable(this, SceneMetatable)    
    return this
end

return scene