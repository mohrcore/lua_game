local collisiongrid = {}

delegate_mod = require "delegate"

function collisiongrid.CollisionGrid(rows, cols, factor_x, factor_y, margin_top, margin_left, margin_right, margin_bottom)
    if not factor_x then factor_x = 1 end
    if not factor_y then factor_y = 1 end
    if not margin_top then margin_top = 0 end
    if not margin_left then margin_left = 0 end
    if not margin_right then margin_right = 0 end
    if not margin_bottom then margin_bottom = 0 end
    local this = {
        xs = factor_x,
        ys = factor_y,
        rows = rows,
        cols = cols,
        margin_bounds = {
            top = margin_top,
            left = margin_left,
            right = margin_right,
            bottom = margin_bottom
        }
    }
    local grid = {}
    for i = 1, cols do
        grid[i] = {}
        for j = 1, rows do
            grid[i][j] = {}
        end
    end
    this.grid = grid
    local function addMethods(this)
        local performIfCellAvailable = function(x, y, f)
            if not this[x] then
                if x >= 1 - this.margin_bounds.left and x <= this.cols + this.margin_bounds.right then
                    this[x] = {}
                else return false end
            end
            if not this[x][y] then 
                if y >= 1 - this.margin_bounds.top and y <= this.rows + this.margin_bounds.bottom then
                    this[x][y] = {}
                else return false end
            end
            f(this[x][y])
            return true
        end
        this.addBody = function(body)
            local x, y = body.getPosition()
            local cx = math.floor(x / this.xs * this.cols) + 1
            local cy = math.floor(y / this.ys * this.rows) + 1
            return performIfCellAvailable(cx, cy, function(cell)
                cell[body] = {
                    --Move to another cell if necessary
                    pos_change_callback = function(prev_x, prev_y)
                        local x, y = body.getPosition()
                        local cx = math.floor(prev_x / this.xs * this.cols) + 1
                        local cy = math.floor(prev_y / this.ys * this.rows) + 1
                        local ncx = math.floor(x / this.xs * this.cols) + 1
                        local ncy = math.floor(y / this.ys * this.rows) + 1
                        if cx ~= ncx or cy ~= ncy then
                            local tab = nil
                            if performIfCellAvailable(cx, cy, function(cell)
                                tab = cell[body]
                                cell[body] = nil
                            end) then
                                performIfCellAvailable(ncx, ncy, function(cell)
                                    cell[body] = tab
                                end)
                            else
                                this.addBody(body)
                            end
                        end
                    end
                }
                --Move to another cell if necessary
                body.on_position_change.add(cell[body].pos_change_callback)
            end)
        end
        this.removeBody = function(body)
            local x, y = body.getPosition()
            local cx = math.floor(x / this.xs * this.cols) + 1
            local cy = math.floor(y / this.ys * this.rows) + 1
            return performIfCellAvailable(cx, cy, function(cell)
                local cb = cell[body].pos_change_callback
                body.on_position_change.remove(cb)
                cell[body] = nil
            end)
        end
        local distance = function(x1, y1, x2, y2)
            local xdiff = x1 - x2
            local ydiff = y1 - y2
            return math.sqrt(xdiff * xdiff + ydiff * ydiff)
        end
        this.withinDistance = function(x, y, dist)
            local cxmin = math.floor((x - dist) / this.xs * this.cols) + 1
            local cxmax = math.floor((x + dist) / this.xs * this.cols) + 1
            local cymin = math.floor((y - dist) / this.ys * this.rows) + 1
            local cymax = math.floor((y + dist) / this.ys * this.rows) + 1
            local cx = cxmin
            local cy = cymin
            --print("cxmin: " .. cxmin .. " cymin: " .. cymin .. " cxmax: " .. cxmax .. " cymax: " .. cymax)
            local ni = nil
            local v = nil
            return function()
                local cell = nil
                local n = nil
                repeat
                    while n == nil do
                        if performIfCellAvailable(cx, cy, function(c) cell = c end) then
                            local vv, nn = next(cell, v)
                            v = vv
                            n = nn
                        end
                        if n == nil then
                            if cx < cxmax then
                                cx = cx + 1
                            else
                                cx = cxmin
                                cy = cy + 1
                            end
                            --print "dupa"
                            if cy > cymax then
                                return nil
                            end
                            v = nil
                        end
                    end
                    n = nil
                    local vx, vy = v.getPosition()
                    --print("vpos: " .. vx .. " " .. vy)
                    --print("ccx: " .. cx .. " cy: " .. cy)
                until (distance(x, y, v.getPosition()) <= dist)
                return v
            end
        end
    end
    addMethods(this)
    return this
end

return collisiongrid