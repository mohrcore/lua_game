local actor = {}

--local deep_copy_mod = require "deep_copy"
local queue_mod = require "queue"

--basically an ECS with messaging
function actor.Actor(scene)
    local this = {
        scene = scene,
        components = {},
        tag_listeners = {},
        component_message_queues = {},
    }
    local function addMethods(this)
        this.message = function(msg)
            local tag = msg.tag
            for component, _ in pairs(tag_listeners) do
                component_message_queues[compnent].push(msg)
            end
        end
        this.addComponent = function(component, instance)
            if this.components[component] ~= nil then return end
            --create component message queue
            if this.component_message_queues[component] == nil then
                this.component_message_queues[component] = queue_mod.Queue()
            end
            --create an instance of the component
            local new_component
            if instance == nil then
                new_component = component(this.scene)
            else
                new_component = instance
            end
            --assign messaging channels (send, query)
            new_component.assignMessageChannels(this.message, this.component_message_queues[component].pop)
            --subscribe to messages with interesting tags
            for _, broadcast_tag in ipairs(new_component.tagSubscriptions()) do
                if (this.tag_listeners[brodcat_tag] == nil) then
                    this.tag_listeners[broadcast_tag] = {}
                end
                this.tag_listeners[broadcast_tag][new_component] = true
            end
            --add component to the component set
            this.components[component] = new_component
        end
        this.removeComponent = function(component)
            if (this.components[component] == nil) then return end
            local rm_component  = this.components[component]
            for broadcast_tag in rm_component.tagSubscriptions() do
                this.tag_listeners[broadcast_tag][rm_component] = nil
            end
            component_message_queues[component] = nil
        end
        this.getComponent = function(component)
            return this.components[component]
        end
        this.clone = function()
            local clone = actor.Actor(this.scene)
            for component, instance in pairs(this.components) do
                clone.addComponent(component, instance.clone())
            end
            return clone
        end
    end
    addMethods(this)
    return this
end

return actor