local endscreensection = {}

local gamesection_mod = require "gamesection"

function endscreensection.EndScreenSection(score, wl)
    local this = gamesection_mod.GameSection()
    this.init = function(self, oncontinue)
        self.ww = love.graphics.getWidth()
        self.wh = love.graphics.getHeight()
        self.wl_font = love.graphics.newFont(RESPATHS["font_gumball"], 128)
        self.score_font = love.graphics.newFont(RESPATHS["font_gumball"], 96)
        if wl then
            self.wl_text = {{0.3, 1.0, 0.6}, "You win!"}
        else
            self.wl_text =  {{1.0, 0.1, 0.1}, "You lose!"}
        end
        self.score_text = {{1, 1, 1}, "Your score is: " .. score}
        self.onContinue = oncontinue
    end
    this.draw = function(self)
        love.graphics.setFont(self.wl_font)
        love.graphics.printf(self.wl_text, 0, self.wh / 2.0 - self.wl_font:getHeight(), self.ww, "center")
        love.graphics.setFont(self.score_font)
        love.graphics.printf(self.score_text, 0, self.wh / 2.0 + 10, self.ww, "center")
    end
    this.update = function(self)
        pressedKey("z", self.onContinue)
        pressedKey("space", self.onContinue)
        pressedKey("left", self.onContinue)
        pressedKey("right", self.onContinue)
        pressedKey("return", self.onContinue)
    end
    this.close = function(self)
    end
    return this
end

return endscreensection