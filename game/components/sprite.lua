local sprite = {}

local component_mod = require "component"

local SpriteSystemComponent = {
    position = {
        x = 0.0,
        y = 0.0,
    }
}

local SpriteSystemComponentMetatable = {
    __index = SpriteSystemComponent
}

local function SpriteSystemComponent()
    local system = SYSTEMS["gfx"]
    local this = {
        syscomp_helper = component_mod.SystemComponentHelper(system)
    }
    setmetatable(this, SpriteSystemComponent)
    system:registerComponent(this)
    return this
end

local SpriteUserObject = {
    setPostion = function(self, x, y)
        self.position = {
            x = x,
            y = y
        }
        self.syscomp_helper:userMessage({
            tag = "transform",
            body = {
                transform_mode = "absolute",
                x = x,
                y = y
            }
        })
    end
    updateUserObject = function(self)
        self.uo_helper:handleMessages(function (msg)
            --handle transforms
            if msg.tag == "tranform" then
                local body = msg.body
                if body.transform_mode == "absolute" then
                    self.position.x = body.x
                    self.position.y = body.y
                elseif body.transform_mode == "relative" then
                    self.position.x = self.position.x + body.x
                    self.position.y = self.position.y + body.y
                end
            end
        end)
    end
}

function sprite.Sprite()
    local syscomp = SpriteSystemComponent()
    local uo_helper = component_mod.UserObjectHelper(syscomp.syscomp_helper)
    local this = {
        syscomp = syscomp,
        uo_helper = uo_helper
    }
    setmetatable(this, SpriteUserObject)
    return this
end

return sprite