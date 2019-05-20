local scene = {}

MAX_SCENE_SPRITE_CLEARS = 2048
_global_scene_no = 0

function scene.Scene(name)
    if not name then
        name = "Scene" .. _global_scene_no
        _global_scene_no = _global_scene_no + 1
    end
    local this = {
        name = name,
        sprites = {}
    }
    local function addMethods(this)
        this.insertSprite = function(sprite)
            this.sprites[sprite] = true
            return sprite
        end
        this.removeSprite = function(sprite)
            this.sprites[sprite] = nil
        end
    end
    addMethods(this)
    return this
end

return scene