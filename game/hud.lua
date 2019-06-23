local hud = {}

local HudMetatable = {
    __index = {
        player_controller = {},
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
        margin = 8,
        scale = 1.0,
        pts_font = nil,
        instance_font = nil,
        draw = function(self)
            local score = self.player_controller.score
            local pts_text = tostring(score)
            if self.pts_font then love.graphics.setFont(self.pts_font) end
            love.graphics.printf({{0.5, 1, 1}, pts_text}, 0, self.top + self.margin, self.right - self.left, "center", 0, self.scale, self.scale)
            local instances = tostring(self.player_controller.instance_count)
            local instances_text1 = "Instance count: "
            local instances_text2 = instances
            if self.instances_font then love.graphics.setFont(self.instances_font) end
            local colors = {1, 1, 1}
            if self.player_controller.instance_count < 1 then
                colors = {1, 0, 0}
            end
            love.graphics.printf({{1, 109/255, 199/255}, instances_text1, colors, instances_text2}, 0 + self.margin, self.bottom - self.margin - self.instances_font:getHeight(), self.right - self.left, "left", 0, self.scale, self.scale)
        end
    }
}

function hud.Hud(player_controller, left, top, right, bottom)
    local this = {
        left = left,
        right = right,
        top = top,
        bottom = bottom,
        player_controller = player_controller
    }
    setmetatable(this, HudMetatable)
    return this
end

return hud