local component = {}

local function nop0()
end
local function nop1(arg1)
end

local SystemComponentHelper = {
    userMessage = function(self, msg)
        self.user_message_channel:push(msg)
    end
}
local SystemComponentHelperMetatable = {
    __index = SystemComponentHelper
}

function component.SystemComponentHelper(system)
    local this = {
        system_messgae_channel = love.thread.newChannel()
        user_message_channel = love.thread.newChannel()
    }
    setmetatable(this, SystemComponentHelperMetatable)
    return this
end

local UserObjectHelper = {
    handleMessages = function(self, handler)
        local msg
        while true do
           msg = self.syscomp.user_message_channel:pop()
           if msg == nil then break end
           handler(msg)
        end
    end
}

local UserObjectHelperMetatable = {
    __index = UserObjectHelper
}

--[[ --this is only to unpack messages from stack and send them to the syscomp
local function passUserObjectMessages(uo, m, ...)
    if m == nil then return end
    uo.syscomp:message(m)
    passUserObjectMessages(uo, ...)
end

setmetatable(UserObject, {
    --suppouseddly nested __index calls are tails calls
    --so the original table (actual object, not UserObject prototype) should be on stack
    --this means that accesing 'self.usermethods_table' should return
    --the table held by the instance, not the empty one from the prototype.
    __index = function(self, k) 
        passUserObjectMessages(self, self.usermethods_table[k](self))
    end
}) ]]

--[[ local UserObjectMetatable = {
    __index = UserObject
} ]]

function component.UserObjectHelper(syscomp_helper)
    local this = {
        syscomp_helper = syscomp_helper
    }
    setmetatable(this, UserObjectHelperMetatable)
    return this
end

function component.initComponent(o, tag_subscriptions)
    local pollMessage = nop0
    o.sendMessage = nop0
    o.handleMessage = nop1
    o.update = function()
        while true do
            local msg = pollMessage()
            if (msg == nil) then break end
            o.handleMessage(msg)
        end
    end
    local tags
    if (tag_subscriptions == nil) then
        tags = {}
    else
        tags = tag_subscriptions
    end
    o.tagSubscriptions = function()
        return tags
    end
    o.assignMessageChannles = function(send, poll)
        o.sendMessage = send
        pollMessage = poll
    end
end
return component