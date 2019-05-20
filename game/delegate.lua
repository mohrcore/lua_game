local delegate = {}

local DelegateMetaTable = {
    __call = function(d, ...)
        for k, _ in pairs(d.callbacks) do
            k(...)
        end
    end
}

function delegate.Delegate()
    local this = {
        callbacks = {}
    }
    local function addMethods(this)
        this.add = function(callback)
            this.callbacks[callback] = true
        end
        this.remove = function(callback)
            this.callbacks[callback] = false
        end
        setmetatable(this, DelegateMetaTable)
    end
    addMethods(this)
    return this
end

return delegate