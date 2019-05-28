local player = {}

delegate_mod = require "delegate"
animation_mod = require "animation"
--property_mod = require "property"

function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

PlayerMetatable = {
    __index = {
        position = {
            x = 0,
            y = 0
        },
        speed = {
            x = 0,
            y = 0
        }
    }
}

function player.Player(pos_x, pos_y)
    if not pos_x then pos_x = 0 end
    if not pos_y then pos_y = 0 end
    local this = {
        speed = { x = 0, y = 0 },
        animations = {},
        on_position_change = delegate_mod.Delegate(),
    }
    local img = love.graphics.newImage(RESPATHS["player"])
    if not img then return end
    this.sprite_img = img
    local function addMethods(this, pos_x, pos_y)
        local position = {
            x = pos_x,
            y = pos_y,
        }
        this.getPosition = function()
            return position.x, position.y
        end
        this.setPosition = function(x, y)
            local ox, oy = this.getPosition()
            position.x = x
            position.y = y
            this.on_position_change(ox, oy)
        end
        this.clone = function()
            --print("Dupa: speedx: " .. t.speed.x .. " posx: " .. t.position.x)
            local c = {
                speed = deepCopy(this.speed),
                animation = deepCopy(this.animations),
                sprite_img= this.sprite_img,
                on_position_change = delegate_mod.Delegate()
            }
            addMethods(c, this.getPosition())
            return c
        end
    end
    addMethods(this, pos_x, pos_y)
    return this
end

return player