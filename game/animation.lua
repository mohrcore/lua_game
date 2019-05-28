local animation = {}

AnimationMetaTable =  {
    __index = {
        target_object,
        target_field,
        current_progress = 0.0,
        speed = 1.0,
        points = {},
        current_point_idx = 0,
        prev_point_idx = 0,
        current_ival = 0,
        running = true,
        setPoint = function(self, time, int)
            local point = {
                time = time,
                int = int
            }
            --binsearch
            local ub = #self.points
            local db = 1
            while true do
                if ub == db then break end
                local i = db + math.floor((ub - db) / 2)
                
                if time > self.points[i].time then
                    db = i + 1
                elseif time == self.points[i].time then
                    ub = i
                    db = i
                else
                    ub = i
                end
            end
            table.insert(self.points, db, point)
        end,
        step = function(self, dt)
            --calculate porogress
            local progress = dt * self.speed
            self.current_progress = self.current_progress + progress
            --update current and previous point indices
            local cidx
            if self.current_point_idx == 0 then
                cidx = 1
            elseif self.points[self.current_point_idx + 1] ~=nil and self.points[self.current_point_idx + 1].time <= self.current_progress then
                cidx = self.current_point_idx + 1
            else
                cidx = self.current_point_idx
            end
            self.prev_point_idx = self.current_point_idx
            self.current_point_idx = cidx
            --get points
            local cpoint = self.points[self.current_point_idx]
            local pipoint = self.points[self.prev_point_idx]
            local ppoint = self.points[self.current_point_idx - 1]
            if cpoint == nil then --no more animation to do
                --reset fields
                self:rest()
                --return
                return
            end
            --set starting value for interpolation
            if self.current_point_idx ~= self.prev_point_idx then
                if self.current_point_idx == 1 then 
                    self.current_ival = self.target[self.target_field] --set beggining value
                else
                    self.current_ival = ppoint.int(self.current_ival, 1.0) --update interpolation start value
                end
            end
            --calculate transformation interpolation progress [0:1]
            local beg_time
            local end_time = cpoint.time
            if ppoint == nil then beg_time = 0.0 else beg_time = ppoint.time end
            local transformation_porgress = (self.current_progress - beg_time) / (self.current_progress - end_time)
            --update field value
            self.target[self.target_field] = cpoint.int(self.current_ival, transformation_porgress)
        end,
        reset = function(self)
            self.current_progress = 0.0
            self.current_point_idx = 0
            self.prev_point_idx = 0
            self.running = false
        end,
        activate = function(self)
            self.running = true
        end
    }
}

function animation.Animation(target, field)
    local this = {}
    setmetatable(this, AnimationMetaTable)
    return this
end

return animation