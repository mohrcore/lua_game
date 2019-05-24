local queue = {}

local deep_copy_mod = require "deep_copy"

function queue.Queue()
    local this = {
        first = 0,
        last = -1
    }
    local function addMethods(this)
        this.push = function(e)
            this.last = this.last + 1
            this[this.last] = e
        end
        this.pop = function()
            local e = this[this.first]
            if e ~= nil then
                this[this.first] = nil
                this.first = this.first + 1;
            end
            return e
        end
        this.clear = function()
            local e
            repeat
                e = this.pop()
            until e == nil
        end
        this.clone = function()
            local clone = deep_copy_mod.deepClone(this)
        end
    end
    addMethods(this)
    return this
end

return queue