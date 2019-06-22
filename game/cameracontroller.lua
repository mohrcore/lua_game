local camreacontroller = {}

local vector_mod = require "vector"

local function lerp(a, b, v)
    v = math.min(math.max(v, 0.0), 1.0)
    return (1 - v) * a + v * b
end

local CameraControllerMetatable = {
    __index = {
        camera = {},
        player_controller = {},
        gamemap_renderer = {},
        stiffness = 1.0,
        update = function(self, dt, speed_vec)
            local center_pos = vector_mod.Vector{0, 0}
            local minx = 999999
            local maxx = -999999
            local miny = 999999
            local maxy = -999999
            for position, _ in pairs(self.player_controller.instances) do
                if position.values[1] < minx then minx = position.values[1] end
                if position.values[1] > maxx then maxx = position.values[1] end
                if position.values[2] < miny then miny = position.values[2] end
                if position.values[2] > maxy then maxy = position.values[2] end
            end
            local nposx = self.camera.values[1] + speed_vec.values[1] * dt
            local nposy = self.camera.values[2] + speed_vec.values[2] * dt
            self.camera.values[1] = nposx
            self.camera.values[2] = nposy
            self.camera.values[1] = lerp(
                self.camera.values[1],
                (minx + (maxx - minx) / 2.0 - 1 - self.gamemap_renderer.gamemap.columns / 2.0) * gamemap_renderer.tileset:getWidth(),
                dt * self.stiffness
            )
            self.camera.values[2] = lerp(
                self.camera.values[2],
                ((miny + (maxy - miny) / 2.0) - 1 - #self.gamemap_renderer.gamemap.layer1 / 2.0) * gamemap_renderer.tileset:getHeight(),
                dt * self.stiffness
            )
        end
    }
}

function camreacontroller.CameraController(camera, player_controller, gamemap_renderer)
    local this = {
        camera = camera,
        player_controller = player_controller,
        gamemap_renderer = gamemap_renderer
    }
    setmetatable(this, CameraControllerMetatable)
    return this
end

return camreacontroller