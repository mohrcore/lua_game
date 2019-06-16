local proximitygrid = {}

local vector_mod = require "vector"

local function getProximityGridCellForPosition(pgrid, position)
    local x = math.floor(position.values[1] * #pgrid.grid / pgrid.real_width) + 1
    local y = math.floor(position.values[2] * #pgrid.grid[1] / pgrid.real_width) + 1
    --print("X: " .. x .. " Y: " .. y)
    if pgrid.grid[x] == nil then
        --print("x: " .. x .. " y: " .. y)
        return nil, x, y
    end
    return pgrid.grid[x][y], x, y
end

local function scheduleProximityGridBodyRemoval(pgrid, body, position)
    pgrid.bodies_to_remove[#pgrid.bodies_to_remove + 1] = {
        body = body,
        position = position
    }
end

local function removeScheduledProximityGridBodies(pgrid)
    for i, v in ipairs(pgrid.bodies_to_remove) do
        local cell = getProximityGridCellForPosition(pgrid, v.position)
        cell[v.body] = nil
        pgrid.bodies_to_remove[i] = nil
    end
    pgrid.bodies_to_remove = {}
end

local function checkGridProximityOld(pgrid, cx, cy, body, position, radius)
    local hr = math.floor(radius / 2)
    for i = cx - hr, cx + hr do
        for j = cy - hr, cy + hr do
            local cell
            if pgrid.grid[i] then
                cell = pgrid.grid[i][j]
            else
                cell = nil
            end
            if cell ~= nil then
                for b_body, b_position in pairs(cell) do
                    if b_body ~= body and pgrid.bodies_checked[b_body] == nil and (b_position - position):length() <= radius then
                        pgrid.proximityCallback(body, b_body, {
                            removeBody = function(b)
                                if b == body then
                                    scheduleProximityGridBodyRemoval(pgrid, b, position)
                                elseif b == b_body then
                                    scheduleProximityGridBodyRemoval(pgrid, b, b_position)
                                end
                            end
                        })
                    end
                end
            end
        end
    end
end

local function calculateMinimalDistanceForMovingBodies(a1, a2, b1, b2)
    -- First, we will define bodies movement as functions
    -- that interpolate between starting, and ending points:
    -- body1(x) = a1 + (a2 - a1) * x
    -- body2(x) = b1 + (b2 - b1) * x
    -- then we will define a function that returns a square of a distance between
    -- those bodies, depending on the interpolation value:
    -- f(x) = (body2(x)[1] - body1(x)[1])^2 + (body2(x)[2] - body1(x)[2])^2
    -- this is the same as
    -- f(x) = ((a2[1]-a1[1]-b2[1]+b1[1])^2 + (a2[2]-a1[2]-b2[2]+b1[2])^2) * x^2
    --      + 2((a1[1]-b1[1])(a2[1]-a1[1]-b2[1]-b1[1]) + (a1[2]-b1[2])(a2[2]-a1[2]-b2[2]-b1[2])) * x
    --      + (a1[1]-b1[1])^2 + (a1[2]-b1[2])^2
    --      = alpha * x^2 + beta ^ x + gamma
    -- We need a derivative of this function, so we could calculate it's minimum
    -- f'(x) = 2 * alpha * x + beta
    -- Ok, now let's define some coefficients, to save up on processing:
    local t1 = a2.values[1]-a1.values[1]-b2.values[1]+b1.values[1]
    local t2 = a2.values[2]-a1.values[2]-b2.values[2]+b1.values[2]
    local t3 = a1.values[1]-b1.values[1]
    local t4 = a1.values[2]-b1.values[2]
    local alpha = t1 * t1 + t2 * t2
    local beta = t1 * t3 + t2 * t4
    local gamma = t3 * t3 + t4 + t4
    if alpha == 0 then
        --This is a special case (movements are parallel)
    else
        -- Let's use alpha and beta coefficients to find a root of f'(x)
        -- by solving the following equation: 2 * alpha * x + beta = 0
        local xmin = -(beta / (2 * alpha))
        -- Handle situations when xmin is not on segments (segments don't cross)
        if xmin < 0 then
            xmin = 0
        elseif xmin > 1 then
            xmin = 1
        end
        -- Now, we just plug xmin to f(x), to get the minimal distance: mindist = f(xmin)
        return alpha * xmin * xmin + beta * xmin + gamma
        -- Done!
end

local function onSegment(a, b, c) -- checks wether c lies on ab segment, if a,b,c are colinear
    if c.values[1] <= math.max(a.values[1], b.values[1]) and
       c.values[1] >= math.min(a.values[1], b.values[1]) and
       c.values[2] <= math.max(a.values[2], b.values[2]) and
       c.values[2] >= math.min(a.values[2], b.values[2]) then
        return true
    end
    return false
end

local function checkSegmentsCross(p1, q1, p2, q2)
    -- This is just the algorithm from here:
    -- https://www.geeksforgeeks.org/check-if-two-given-line-segments-intersect/
    -- It's a trivial problem with ridiculously lenghty solution, so I just
    -- translated avaible solution to Lua to save some time and my mental health

    local function orientation(p, q, r) 
        -- See https://www.geeksforgeeks.org/orientation-3-ordered-points/ 
        -- for details of below formula. 
        local val = (q.values[2]-p.values[2]) * (r.values[1]-q.values[1]) - (q.values[1]-p.values[1]) * (r.values[2]-q.values[2]); 
        if val == 0 then return 0 end --colinear 
        if val > 0 then
            return 1 --cw
        end
        return 2 --ccw
    end
    -- Find the four orientations needed for general and 
    -- special cases 
    local o1 = orientation(p1, q1, p2)
    local o2 = orientation(p1, q1, q2)
    local o3 = orientation(p2, q2, p1)
    local o4 = orientation(p2, q2, q1)
    -- General case 
    if (o1 ~= o2 and o3 ~= o4) then
        return true
    end
    -- Special Cases 
    -- p1, q1 and p2 are colinear and p2 lies on segment p1q1 
    if o1 == 0 and onSegment(p1, q1, p2) then return true end
    -- p1, q1 and q2 are colinear and q2 lies on segment p1q1 
    if o2 == 0 and onSegment(p1, q1, q2) then return true end
    -- p2, q2 and p1 are colinear and p1 lies on segment p2q2 
    if o3 == 0 and onSegment(p2, q2, p1) then return true end
    -- p2, q2 and q1 are colinear and q1 lies on segment p2q2 
    if o4 == 0 and onSegment(p2, q2, q1) then return true end
    return false -- Doesn't fall in any of the above cases 
end

-- I'm not even going to go into details on what's going on here
-- Basically, it's a line segment rasterizer, that executes 'fun'
-- On each cell which the segment passes through
-- and calls 'oob' when it goes out-of-bounds
-- It can handle special cases, with some precision and it was the worst part of writing it
local function forCellsOfSegment(pgrid, v1, v2, fun, oob)
    local ccell, cx, cy = getProximityGridCellForPosition(pgrid, v1)
    local prev_cell = nil
    while true do
        --print("cx: " .. cx .. " cy: " .. cy)
        ccell = pgrid.grid[cx][cy]
        if ccell == nil then
            oob()
            break
        end
        fun(ccell, prev_cell, cx, cy)
        local grid_cell_w = pgrid.real_width / #pgrid.grid
        local grid_cell_h = pgrid.real_height / #pgrid.grid[1]
        local tl_corner =  vector_mod.Vector{grid_cell_w * (cx - 1), grid_cell_h * (cy - 1)} --top-left 
        local tr_corner =  vector_mod.Vector{grid_cell_w * cx, grid_cell_h * (cy - 1)}       --top-right
        local bl_corner =  vector_mod.Vector{grid_cell_w * (cx - 1), grid_cell_h * cy}       --bottom-left
        local br_corner =  vector_mod.Vector{grid_cell_w * cx, grid_cell_h * cy}             --bottom-right
        -- Find the next cell the segment is in, by checking segment's intersectoins with cell boundaries
        local vdiff_norm = (v2 - v1):norm()
        local l_cross = checkSegmentsCross(v1, v2, tl_corner, bl_corner)
        local r_cross = checkSegmentsCross(v1, v2, tr_corner, br_corner)
        local t_cross = checkSegmentsCross(v1, v2, tl_corner, tr_corner)
        local b_cross = checkSegmentsCross(v1, v2, bl_corner, br_corner)
        local tl_cross = onSegment(v1, v2, tl_corner) and math.abs((tl_corner - v1):norm() * vdiff_norm) > 0.99999999
        local tr_cross = onSegment(v1, v2, tr_corner) and math.abs((tr_corner - v1):norm() * vdiff_norm) > 0.99999999
        local bl_cross = onSegment(v1, v2, bl_corner) and math.abs((bl_corner - v1):norm() * vdiff_norm) > 0.99999999
        local br_cross = onSegment(v1, v2, br_corner) and math.abs((br_corner - v1):norm() * vdiff_norm) > 0.99999999
        --print("tr: " .. (br_corner - v1):norm() * vdiff_norm)
        if     prev_cell ~= 'l' and l_cross and (not tl_cross or tr_cross) and not bl_cross then
            cx = cx - 1
            prev_cell = 'r'
        elseif prev_cell ~= 'r' and r_cross and (not tr_cross or tl_cross) and not br_cross then
            cx = cx + 1
            prev_cell = 'l'
        elseif prev_cell ~= 't' and t_cross and (not tl_cross or bl_cross) and not tr_cross then
            cy = cy - 1
            prev_cell = 'b'
        elseif prev_cell ~= 'b' and b_cross and (not bl_cross or tl_cross) and not br_cross then
            cy = cy + 1
            prev_cell = 't'
        elseif prev_cell ~= 'tl' and tl_cross then
            cx = cx - 1
            cy = cy - 1
            prev_cell = 'br'
        elseif prev_cell ~= 'tr' and tr_cross then
            cx = cx + 1
            cy = cy - 1
            prev_cell = 'bl'
        elseif prev_cell ~= 'bl' and bl_cross then
            cx = cx - 1
            cy = cy + 1
            prev_cell = 'tr'
        elseif prev_cell ~= 'br' and br_cross then
            cx = cx + 1
            cy = cy + 1
            prev_cell = 'tl'
        else
            break
        end        
    end
end

local function checkGridProximity(pgrid, cx, cy, body, posmov)
    -- Calculate box check boundaries
    local cxmin, cxmax, cymin, cymax, bw, bh
    local rvec = vector_mod.Vector{pgrid.proximity_radius, pgrid.proximity_radius}
    if posmov.move then
       _, cxmin, cymin = getProximityGridCellForPosition(pgrid, posmov.source - rvec)
       _, cxmax, cymax = getProximityGridCellForPosition(pgrid, posmov.source + rvec)
    else
        _, cxmin, cymin = getProximityGridCellForPosition(pgrid, posmov - rvec)
        _, cxmax, cymax = getProximityGridCellForPosition(pgrid, posmov + rvec)
    end
    bw = cxmax - cxmin + 1
    bh = cymax - cymin + 1
    cxmin = math.max(cxmin, 1)
    cxmax = math.min(cxmax, #pgrid.grid)
    cymin = math.max(cymin, 1)
    cymax = math.min(cymax, #pgrid.grid[1])
    -- Define full rectangle check
    -- This will be used when checking teleportations and first celss of a movement
    local function checkRect(position, checkfun)
        for i = cxmin, cxmax do
            for j = cymin, cymax do
                local cell = pgrid.grid[i][j]
                for b_body, b_position in pairs(cell) do
                    if b_body ~= body and pgrid.bodies_checked[b_body] == nil and (b_position - position):length() <= pgrid.proximity_radius then
                        pgrid.proximityCallback(body, b_body, {
                            removeBody = function(b)
                                if b == body then
                                    scheduleProximityGridBodyRemoval(pgrid, b, position)
                                elseif b == b_body then
                                    scheduleProximityGridBodyRemoval(pgrid, b, b_position)
                                end
                            end
                        })
                    end
                end
            end
        end
    end
    local function checkBodiesInCell(body, body_posmov, cell)
        for b_body, b_posmov in pairs(cell) do
            if b_body ~= body and pgrid.bodies_checked[b_body] == nil then
                if body_posmov.move then
                    if b_posmov.move then
                        if calculateMinimalDistanceForMovingBodies(body.body_posmov.source, body_posmov.destination, b_posmov.source, b_posmov.destination) <= pgrid.proximity_radius then
                            pgrid.proximityCallback(body, b_body, {
                                removeBody = function(b)
                                    if b == body then
                                        scheduleProximityGridBodyRemoval(pgrid, b, body_posmov)
                                    elseif b == b_body then
                                        scheduleProximityGridBodyRemoval(pgrid, b, b_posmov)
                                    end
                                end
                            })
                        end
                    else
                    end
                end
            end
            if b_body ~= body and pgrid.bodies_checked[b_body] == nil and (b_position - position):length() <= pgrid.proximity_radius then
                pgrid.proximityCallback(body, b_body, {
                    removeBody = function(b)
                        if b == body then
                            scheduleProximityGridBodyRemoval(pgrid, b, position)
                        elseif b == b_body then
                            scheduleProximityGridBodyRemoval(pgrid, b, b_position)
                        end
                    end
                })
            end
        end
    end
    if posmov.move then
        local firstcell = true
        forCellsOfSegment(pgrid, posmov.source, posmov.destination, function(cell, prev, cx, cy)
            if firstcell then
                firstcell = false
                return
            end
        end, cb)
    else
        checkRect(posmov)
    end
end

ProximityGridMetatable = {
    __index = {
        real_width = 0.0,
        real_height = 0.0,
        grid = {},
        proximityCallback = nil,
        outOfBoundsCallback = nil,
        bodies_to_remove = {},
        bodies_to_check = {},
        bodies_checked = {},
        proximity_radius = 0.0,
        addBody = function(self, body, position)
            local cell, cx, cy = getProximityGridCellForPosition(self, position)
            if cell == nil then
                self.outOfBoundsCallback(body)
                return false
            end
            if cell[body] then return false end
            cell[body] = position
            self.bodies_to_check[body] = position
            return true
        end,
        removeBody = function(self, body, position)
            local cell = getProximityGridCellForPosition(self, position)
            if cell == nil then return false end
            if cell[body] == nil then return false end
            cell[body] = nil
            return true
        end,
        teleportBody = function(self, body, source, destination)
            local src_cell = getProximityGridCellForPosition(self, source)
            local dst_cell, cx, cy = getProximityGridCellForPosition(self, destination)
            if src_cell == nil then return false end
            if src_cell[body] == nil then
                print "this shouldn't have happend!"
                return false
            end
            if dst_cell == nil then --handle out-of-grid situations
                self.outOfBoundsCallback(body)
                src_cell[body] = nil
                return false
            end
            if src_cell ~= dst_cell then
                src_cell[body] = nil
            end
            dst_cell[body] = destination
            self.bodies_to_check[body] = destination
            return true
        end,
        moveBody = function(self, body, source, destination)
            local src_cell, scx, scy = getProximityGridCellForPosition(self, source)
            if src_cell == nil then return false end
            if src_cell[body] == nil then
                print "this shouldn't have happend!"
                return false
            end
            local dst_cell, dcx, dcy = getProximityGridCellForPosition(self, destination)
            local ccx = scx
            local ccy = scy
            local firstcell = true
            local out_of_bounds_cb = function()
                self.outOfBoundsCallback(body)
            end
            local oncell = function(cell, from_dir)
                local move = {
                    move = true,
                    source = source,
                    destination = destination
                }
                cell[body] = move
                if firstcell then
                    self.bodies_to_check[body] = move
                end
                firstcell = false
            end
            forCellsOfSegment(source, destination, oncell, out_of_bounds_cb)
            return true
        end,
        step = function(self)
            for body, v in pairs(self.bodies_to_check) do
                if v.move then
                    local firstcell = true
                    forCellsOfSegment(self, v.source, v.destination, function(cell, prev, cx, cy) --TODO: modife 'checkGridProximity'
                        if firstcell then
                        end
                        firstcell = false
                    end, function() self.outOfBoundsCallback(body) end)
                else
                    local _, cx, cy = getProximityGridCellForPosition(self, v)
                    checkGridProximity(self, cx, cy, body, v, self.proximity_radius)
                    self.bodies_to_check[body] = nil
                    self.bodies_checked[body] = true
                end
            end
            removeScheduledProximityGridBodies(self)
            self.bodies_checked = {}
        end
    }
}

function proximitygrid.ProximityGrid(real_width, real_height, columns, rows)
    local grid = {}
    for i = 1, columns do
        grid[i] = {}
        for j = 1, rows do
            grid[i][j] = {}
        end
    end
    local this = {
        grid = grid,
        real_width = real_width,
        real_height = real_height,
    }
    setmetatable(this, ProximityGridMetatable)
    return this
end

-- 'forCellsOfSegment' line-rasterizer testing
function testSomeStuff(p1, p2)
    local pgrid = proximitygrid.ProximityGrid(16, 16, 16, 16)
    local cb = function()
    end
    local pts = {}
    for i = 1, 16 do
        pts[i] = {}
        for j = 1, 16 do
            pts[i][j] = '.'
        end
    end
    forCellsOfSegment(pgrid, p1, p2, function(_, _, cx, cy)
        pts[cy][cx] = '#'
    end, cb)
    for _, v in ipairs(pts) do
        local str = ""
        for _, c in ipairs(v) do
            str = str .. c
        end
        print(str)
    end
end

testSomeStuff(vector_mod.Vector{1.5, 1.5}, vector_mod.Vector{9.5, 15.5})

return proximitygrid