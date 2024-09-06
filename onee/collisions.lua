-- functions
collision = {}

point = {}
line = {}
rect = {}
circ = {}
poly = {}

---------------------------------------------------------------- INSTANCES

--! INIT A NEW COLLISION INSTANCE
function collision.init(collision, name, data)
	assert(data, "collision.init() | no collision data passed!")
	
	local t = {
		collision = true,
		name = name,
		
		active = true,
	}
	table.append(t, data)
	
	-- POINT (and everything else)
	t.x = t.x or 0
	t.y = t.y or t.x or 0
	-- LINE
	if t.line then 
		t.rect = nil; t.circ = nil
		
		t.line.x = t.line.x or 0
		t.line.y = t.line.y or t.line.x or 0
	-- RECTANGLE
	elseif t.rect then
		t.line = nil; t.circ = nil
		
		t.rect.width = t.rect.width or 0
		t.rect.height = t.rect.height or t.rect.width or 0
	-- CIRCLE
	elseif t.circ then 
		t.line = nil; t.rect = nil
		
		t.circ.radius = t.circ.radius or 0
	end
	
	t = table.protect(t, {"collision", "name"})
	
	return table.append(collision, t)
end

--! DEBUG DRAW COLLISION
function collision.debug_draw(collision)
	if not collision.active then return end 
	
	if not collision.debug then
		collision.debug = {
			rgb = {color.random()},
			highlighted = false,
		}
	end
	
	local mode = collision.debug.highlighted and "fill" or "line"
	
	love.graphics.setColor(rgb(collision.debug.rgb, 0.5))
	-- LINE
	if collision.line then
		love.graphics.line(collision.x, collision.y, collision.line.x, collision.line.y)
		if collision.debug.highlighted and frames % 5 == 0 then
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.setLineWidth(3)
			love.graphics.line(collision.x, collision.y, collision.line.x, collision.line.y)
		end
	-- RECT
	elseif collision.rect then
		love.graphics.rectangle(mode, collision.x, collision.y, collision.rect.width, collision.rect.height)
	-- CIRCLE
	elseif collision.circ then
		love.graphics.circle(mode, collision.x, collision.y, collision.circ.radius)
	-- POINT
	else
		love.graphics.line(collision.x-4, collision.y, collision.x+4, collision.y)
		love.graphics.line(collision.x, collision.y-4, collision.x, collision.y+4)
		love.graphics.circle(mode, collision.x, collision.y, 6)
	end
	love.graphics.reset()
	
end

--! FIND COLLISION BETWEEN INSTANCES
function collision.check(self, scene, objectname, collisionname)
	if not self then return end
	if not self.active then return end
	
	local candidates = {}
	
	local function check_recursively(arg, id)
		for k, v in pairs(arg) do
			if type(v) == "table" then
				if v.collision == true and v.name == collisionname and
				self ~= v and v.active then
					--TODO: add IDs in a separate table
					v.instance = id
					table.insert(candidates, v)
				else
					check_recursively(v, id)
				end
			end
		end
	end
	
	for id, instance in pairs(scene.instances) do
		if instance.object == objectname then
			check_recursively(instance, id)
		end
	end
	
	-- nothing found
	if #candidates == 0 then return end
	
	for i=1, #candidates do
		local other = candidates[i]
		
		-- return only when a collision is found, otherwise continue
		if collision.resolve(self, other) then
			return true, other
		end
	end
	
end

--! CHECK TWO INDIVIDUAL COLLISION TYPES
function collision.resolve(self, other)
	-- LINE
	if self.line then
		if other.line then -- LINE WITH LINE
			return collision.line_line(
				self.x, self.y, self.line.x, self.line.y,
				other.x, other.y, other.line.x, other.line.y
			)
		elseif other.rect then -- LINE WITH RECT
			return collision.line_rect(
				self.x, self.y, self.line.x, self.line.y,
				other.x, other.y, other.rect.width, other.rect.height
			)
		elseif other.circ then -- LINE WITH CIRCLE
			return collision.line_circ(
				self.x, self.y, self.line.x, self.line.y,
				other.x, other.y, other.circ.radius
			)
		else -- LINE WITH POINT
			return collision.line_point(
				self.x, self.y, self.line.x, self.line.y,
				other.x, other.y
			)
		end
	-- RECT
	elseif self.rect then
		if other.line then -- RECT WITH LINE
			return collision.rect_line(
				self.x, self.y, self.rect.width, self.rect.height,
				other.x, other.y, other.line.x, other.line.y
			)
		elseif other.rect then -- RECT WITH RECT
			return collision.rect_rect(
				self.x, self.y, self.rect.width, self.rect.height,
				other.x, other.y, other.rect.width, other.rect.height
			)
		elseif other.circ then -- RECT WITH CIRCLE
			return collision.rect_circ(
				self.x, self.y, self.rect.width, self.rect.height,
				other.x, other.y, other.circ.radius
			)
		else -- RECT WITH POINT
			return collision.rect_point(
				self.x, self.y, self.rect.width, self.rect.height,
				other.x, other.y
			)
		end
	-- CIRCLE
	elseif self.circ then
		if other.line then -- CIRCLE WITH LINE
			return collision.circ_line(
				self.x, self.y, self.circ.radius,
				other.x, other.y, other.line.x, other.line.y
			)
		elseif other.rect then -- CIRCLE WITH RECT
			return collision.circ_rect(
				self.x, self.y, self.circ.radius,
				other.x, other.y, other.rect.width, other.rect.height
			)
		elseif other.circ then -- CIRCLE WITH CIRCLE
			return collision.circ_circ(
				self.x, self.y, self.circ.radius,
				other.x, other.y, other.circ.radius
			)
		else -- CIRCLE WITH POINT
			return collision.circ_point(
				self.x, self.y, self.circ.radius,
				other.x, other.y
			)
		end
	-- POINT
	else
		if other.line then -- POINT WITH LINE
			return collision.point_line(
				self.x, self.y,
				other.x, other.y, other.line.x, other.line.y
			)
		elseif other.rect then -- POINT WITH RECT
			return collision.point_rect(
				self.x, self.y,
				other.x, other.y, other.rect.width, other.rect.height
			)
		elseif other.circ then -- POINT WITH CIRCLE
			return collision.point_circ(
				self.x, self.y,
				other.x, other.y, other.circ.radius
			)
		else -- POINT WITH POINT
			return collision.point_point(
				self.x, self.y,
				other.x, other.y
			)
		end	
	end
end

---------------------------------------------------------------- CALCULATIONS
-- add intersections? (maybe for raycasts?)

do--#region CALCULATIONS

---- points
--! POINT WITH POINT COLLISION
function collision.point_point(Ax, Ay, Bx, By)
	return math.round(Ax) == math.round(Bx)
	   and math.round(Ay) == math.round(By)
end
--! POINT WITH LINE COLLISION
function collision.point_line(Ax, Ay, Bx1, By1, Bx2, By2)
	local length = math.distance(Bx1, By1, Bx2, By2)
	local distance1 = math.distance(Ax, Ay, Bx1, By1)
	local distance2 = math.distance(Ax, Ay, Bx2, By2)
	
	return math.between(length - 0.1, (distance1 + distance2), length + 0.1)
end
--! POINT WITH RECTANGLE COLLISION
function collision.point_rect(Ax, Ay, Bx1, By1, Bx2, By2)
	return math.between(Bx1, (Ax), Bx1 + Bx2)
	   and math.between(By1, (Ay), By1 + By2)
end
--! POINT WITH CIRCLE COLLISION
function collision.point_circ(Ax, Ay, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Bradius
end
-- (alias)
function collision.point_poly(Ax, Ay, B)
	return collision.poly_point(B, Ax, Ay)
end

---- lines
-- (alias)
function collision.line_point(Ax1, Ay1, Ax2, Ay2, Bx, By)
	return collision.point_line(Bx, By, Ax1, Ay1, Ax2, Ay2)
end
--! LINE WITH LINE COLLISION
function collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	local colA = ((Bx2 - Bx1) * (Ay1 - By1) - (By2 - By1) * (Ax1 - Bx1)) 
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	local colB = ((Ax2 - Ax1) * (Ay1 - By1) - (Ay2 - Ay1) * (Ax1 - Bx1))
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	
	return math.between(0, colA, 1)
	   and math.between(0, colB, 1)
end
--! LINE WITH RECTANGLE COLLISION
function collision.line_rect(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	local colA = collision.point_rect(Ax1, Ay1, Bx1, By1, Bx2, By2)
	
	local left = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx1, (By1 + By2))
	local right = collision.line_line(Ax1, Ay1, Ax2, Ay2, (Bx1 + Bx2), By1, (Bx1 + Bx2), (By1 + By2))
	local top = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, (Bx1 + Bx2), By1)
	local bottom = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, (By1 + By2), (Bx1 + Bx2), (By1 + By2))
	
	return colA
		or left or right or top or bottom
end
--! LINE WITH CIRCLE COLLISION
function collision.line_circ(Ax1, Ay1, Ax2, Ay2, Bx, By, Bradius)
	local result = false
	
	local colA = collision.point_circ(Ax1, Ay1, Bx, By, Bradius)
	
	local length = math.distance(Ax1, Ay1, Ax2, Ay2)
	local centerx = Bx - Ax1
	local centery = By - Ay1
	local angle = (centerx * (Ax2 - Ax1)) + (centery * (Ay2 - Ay1))
	
	if angle > 0 then
		angle = angle/length
		
		if angle < length then
			result =  math.sqrt((centerx^2) + (centery^2) - (angle^2)) <= Bradius
		end
	end
	
	return colA or result
end
-- (alias)
function collision.line_poly(Ax1, Ay1, Ax2, Ay2, B)
	return collision.poly_line(B, Ax1, Ay1, Ax2, Ay2)
end

---- rectangles
-- (alias)
function collision.rect_point(Ax1, Ay1, Ax2, Ay2, Bx, By)
	return collision.point_rect(Bx, By, Ax1, Ay1, Ax2, Ay2)
end
-- (alias)
function collision.rect_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	return collision.line_rect(Bx1, By1, Bx2, By2, Ax1, Ay1, Ax2, Ay2)
end
--! RECTANGLE WITH RECTANGLE COLLISION
function collision.rect_rect(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	return Ax1 <= Bx1 + Bx2 and Ay1 <= By1 + By2
	   and Bx1 <= Ax1 + Ax2 and By1 <= Ay1 + Ay2
end
--! RECTANGLE WITH CIRCLE COLLISION
function collision.rect_circ(Ax1, Ay1, Ax2, Ay2, Bx, By, Bradius)
	local colx, coly = Bx, By
	if Bx <= Ax1 	   then colx = Ax1       end
	if Bx >= Ax1 + Ax2 then colx = Ax1 + Ax2 end
	if By <= Ay1       then coly = Ay1       end
	if By >= Ay1 + Ay2 then coly = Ay1 + Ay2 end
	
	return math.distance(colx, coly, Bx, By) <= Bradius
end

---- circles
-- (alias)
function collision.circ_point(Ax, Ay, Aradius, Bx, By)
	return point_circ(Bx, By, Ax, Ay, Aradius)
end
-- (alias)
function collision.circ_line(Ax, Ay, Aradius, Bx1, By1, Bx2, By2)
	return collision.line_circ(Bx1, By1, Bx2, By2, Ax, Ay, Aradius)
end
-- (alias)
function collision.circ_rect(Ax, Ay, Aradius, Bx1, By1, Bx2, By2)
	return collision.rect_circ(Bx1, By1, Bx2, By2, Ax, Ay, Aradius)
end
--! CIRCLE WITH CIRCLE COLLISION
function collision.circ_circ(Ax, Ay, Aradius, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Aradius + Bradius
end

---- polygons
--! POLY WITH POINT COLLISION
function collision.poly_point(A, Bx, By)
	local wn = 0 -- winding number algorithm
	
	local current
	local next = A[#A]
	for i=1, #A do
		current = next
		next = A[i]
		
		if current[2] > By then
			if (next[2] <= By) and (current[1] - Bx) * (next[2] - By) < (next[1] - Bx) * (current[2] - By) then
				wn = wn + 1
			end
		else
			if (next[2] > By) and (current[1] - Bx) * (next[2] - By) > (next[1] - Bx) * (current[2] - By) then
				wn = wn - 1
			end
		end
		
	end
	
	return wn % 2 ~= 0 -- collision if odd
end
--! POLY WITH LINE COLLISION
function collision.poly_line(A, Bx1, By1, Bx2, By2)
	local result = false
	
	local colB = collision.point_poly(Bx1, By1, A)
	
	local current
	local next = A[#A]
	for i=1, #A do
		current = next
		next = A[i]
		
		if collision.line_line(Bx1, By1, Bx2, By2, current[1], current[2], next[1], next[2]) then
			result = true
		end
	end
	
	return colB or result
end
end--#endregion

---------------------------------------------------------------- INDIVIDUAL SHAPES
-- todo: width, height, bbox, move, rotate, scale

-- POINTS
--!
function point.rotate(x, y, angle, ox, oy)
	if angle == 0 then return x, y end
	
	angle = math.rad(angle)
	ox = ox or x
	oy = oy or y
	
	return ox + (math.cos(angle) * (x - ox) - math.sin(angle) * (y - oy)),
		oy + (math.sin(angle) * (x - ox) + math.cos(angle) * (y - oy))
end

-- POLYGONS
--!
function poly.unpack(arg)
	local t = {}
	for i=1, #arg do
		table.insert(t, arg[i][1])
		table.insert(t, arg[i][2])
	end
	return t
end

--!
function poly.pack(arg)
	local t = {}
	for i=1, #arg, 2 do
		table.insert(t, {arg[i], arg[i+1]})
	end
	return t
end

--!
function poly.rect(x, y, width, height)
	return {
		{x, y},
		{x + width, y},
		{x + width, y + height},
		{x, y + height},
	}
end

--!
function poly.move(arg, x, y, ox, oy)
	local t = copy(arg)
	
	ox = t[1][1] + (ox or 0)
	oy = t[1][2] + (oy or ox or 0)
	
	for i=1, #t do
		t[i][1] = t[i][1] + x
		t[i][2] = t[i][2] + y
	end
	
	return t
end

--!
function poly.rotate(arg, angle, ox, oy)
	if angle == 0 then return arg, angle end
	
	local t = copy(arg)
	angle = math.rad(angle)
	
	ox = t[1][1] + (ox or 0)
	oy = t[1][2] + (oy or ox or 0)
	
	local sin, cos = math.sin(angle), math.cos(angle)
	for i=1, #t do
		local x = t[i][1] - ox
		local y = t[i][2] - oy
		
		t[i][1] = ox + (cos * x - sin * y)
		t[i][2] = oy + (sin * x + cos * y)
	end
	
	angle = math.deg(angle)
	return t, angle
end

_prof.hook("collision")
_prof.hook("point")
_prof.hook("line")
_prof.hook("rect")
_prof.hook("circ")
_prof.hook("poly")