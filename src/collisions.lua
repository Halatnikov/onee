collision = {} -- functions

---------------------------------------------------------------- INSTANCES

function collision.init(collision, name, data) -- INIT A NEW COLLISION INSTANCE --
	assert(data, "collision.init() | no collision data passed!")
	
	local t = {
		collision = true,
		name = name,
		active = true,
		x = 0,
	}
	table.append(t, data)
	
	-- POINT (and everything else) --
	if not t.y then t.y = t.x end
	-- LINE --
	if t.line then 
		t.rect = nil; t.circ = nil
		
		if not t.line.y then t.line.y = t.line.x end
	-- RECTANGLE --
	elseif t.rect then
		t.line = nil; t.circ = nil
		
		if not t.rect.height then t.rect.height = t.rect.width end
	-- CIRCLE --
	elseif t.circ then 
		t.line = nil; t.rect = nil
	end
	
	return table.append(collision, t)
end

function collision.draw(collision) -- DEBUG DRAW COLLISION --
	if not collision.active then return end 
	
	if not collision.rgb then
		collision.rgb = {math.random(0,255), math.random(0,255), math.random(0,255)}
	end
	
	love.graphics.setColor(collision.rgb[1]/255, collision.rgb[2]/255, collision.rgb[3]/255, 0.5)
	-- LINE --
	if collision.line then
		love.graphics.line(collision.x, collision.y, collision.line.x, collision.line.y)
	-- RECT --
	elseif collision.rect then
		love.graphics.rectangle("line", collision.x, collision.y, collision.rect.width, collision.rect.height)
	-- CIRCLE --
	elseif collision.circ then
		love.graphics.circle("line", collision.x, collision.y, collision.circ.radius)
	-- POINT --
	else
		love.graphics.line(collision.x-4, collision.y, collision.x+4, collision.y)
		love.graphics.line(collision.x, collision.y-4, collision.x, collision.y+4)
		love.graphics.circle("line", collision.x, collision.y, 6)
	end
	love.graphics.reset()
	
end

function collision.check(self, objectname, collisionname) -- FIND COLLISION BETWEEN INSTANCES --
	if not self then return end
	if not self.active then return end
	
	local candidates = {}
	
	for id in pairs(instances) do
		if instances[id].object == objectname then
			for fields in pairs(instances[id]) do
				local field = instances[id][fields]
				
				if type(field) == "table" and 
				field.collision and field.name == collisionname then
					table.insert(candidates, field)
				end
			end
		end
	end
	
	-- nothing found
	if not candidates[1] then return end
	
	for i=1, #candidates do
		local other = candidates[i]
		local result
		
		if not other.active then break end
		
		-- LINE --
		if self.line then
			if other.line then -- LINE WITH LINE --
				result = collision.line_line(
					self.x, self.y, self.line.x, self.line.y,
					other.x, other.y, other.line.x, other.line.y
				)
			elseif other.rect then -- LINE WITH RECT --
				result = collision.line_rect(
					self.x, self.y, self.line.x, self.line.y,
					other.x, other.y, other.rect.width, other.rect.height
				)
			elseif other.circ then -- LINE WITH CIRCLE --
				result = collision.line_circ(
					self.x, self.y, self.line.x, self.line.y,
					other.x, other.y, other.circ.radius
				)
			else -- LINE WITH POINT --
				result = collision.line_point(
					self.x, self.y, self.line.x, self.line.y,
					other.x, other.y
				)
			end
		-- RECT --
		elseif self.rect then
			if other.line then -- RECT WITH LINE --
				result = collision.rect_line(
					self.x, self.y, self.rect.width, self.rect.height,
					other.x, other.y, other.line.x, other.line.y
				)
			elseif other.rect then -- RECT WITH RECT --
				result = collision.rect_rect(
					self.x, self.y, self.rect.width, self.rect.height,
					other.x, other.y, other.rect.width, other.rect.height
				)
			elseif other.circ then -- RECT WITH CIRCLE --
				result = collision.rect_circ(
					self.x, self.y, self.rect.width, self.rect.height,
					other.x, other.y, other.circ.radius
				)
			else -- RECT WITH POINT --
				result = collision.rect_point(
					self.x, self.y, self.rect.width, self.rect.height,
					other.x, other.y
				)
			end
		-- CIRCLE --
		elseif self.circ then
			if other.line then -- CIRCLE WITH LINE --
				result = collision.circ_line(
					self.x, self.y, self.circ.radius,
					other.x, other.y, other.line.x, other.line.y
				)
			elseif other.rect then -- CIRCLE WITH RECT --
				result = collision.circ_rect(
					self.x, self.y, self.circ.radius,
					other.x, other.y, other.rect.width, other.rect.height
				)
			elseif other.circ then -- CIRCLE WITH CIRCLE --
				result = collision.circ_circ(
					self.x, self.y, self.circ.radius,
					other.x, other.y, other.circ.radius
				)
			else -- CIRCLE WITH POINT --
				result = collision.circ_point(
					self.x, self.y, self.circ.radius,
					other.x, other.y
				)
			end
		-- POINT --
		else
			if other.line then -- POINT WITH LINE --
				result = collision.point_line(
					self.x, self.y,
					other.x, other.y, other.line.x, other.line.y
				)
			elseif other.rect then -- POINT WITH RECT --
				result = collision.point_rect(
					self.x, self.y,
					other.x, other.y, other.rect.width, other.rect.height
				)
			elseif other.circ then -- POINT WITH CIRCLE --
				result = collision.point_circ(
					self.x, self.y,
					other.x, other.y, other.circ.radius
				)
			else -- POINT WITH POINT --
				result = collision.point_point(
					self.x, self.y,
					other.x, other.y
				)
			end	
		end
		
		-- return only when a collision is found, otherwise continue
		if result then
			return true
		end
		
	end
	
end

---------------------------------------------------------------- CALCULATIONS
-- add intersections? (maybe for raycasts?)

---- points
-- POINT WITH POINT COLLISION --
function collision.point_point(Ax, Ay, Bx, By)
	return math.round(Ax) == math.round(Bx)
	   and math.round(Ay) == math.round(By)
end
-- POINT WITH LINE COLLISION --
function collision.point_line(Ax, Ay, Bx1, By1, Bx2, By2)
	local length = math.distance(Bx1,By1,Bx2,By2)
	local distance1 = math.distance(Ax,Ay,Bx1,By1)
	local distance2 = math.distance(Ax,Ay,Bx2,By2)
	
	return math.between(length - 0.1, (distance1 + distance2), length + 0.1)
end
-- POINT WITH RECTANGLE COLLISION --
function collision.point_rect(Ax, Ay, Bx1, By1, Bx2, By2)
	return math.between(Bx1, (Ax), Bx1 + Bx2)
	   and math.between(By1, (Ay), By1 + By2)
end
-- POINT WITH CIRCLE COLLISION --
function collision.point_circ(Ax, Ay, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Bradius
end
-- POINT WITH POLY COLLISION (alias) --
function collision.point_poly(Ax, Ay, B)
	return collision.poly_point(B, Ax, Ay)
end

---- lines
-- LINE WITH POINT COLLISION (alias) --
function collision.line_point(Ax1, Ay1, Ax2, Ay2, Bx, By)
	return collision.point_line(Bx, By, Ax1, Ay1, Ax2, Ay2)
end
-- LINE WITH LINE COLLISION --
function collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	local colA = ((Bx2 - Bx1) * (Ay1 - By1) - (By2 - By1) * (Ax1 - Bx1)) 
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	local colB = ((Ax2 - Ax1) * (Ay1 - By1) - (Ay2 - Ay1) * (Ax1 - Bx1))
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	
	return math.between(0, colA, 1)
	   and math.between(0, colB, 1)
end
-- LINE WITH RECTANGLE COLLISION --
function collision.line_rect(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	local colA1 = collision.point_rect(Ax1, Ay1, Bx1, By1, Bx2, By2)
	local colA2 = collision.point_rect(Ax2, Ay2, Bx1, By1, Bx2, By2)
	
	local left = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx1, (By1 + By2))
	local right = collision.line_line(Ax1, Ay1, Ax2, Ay2, (Bx1 + Bx2), By1, (Bx1 + Bx2), (By1 + By2))
	local top = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, (Bx1 + Bx2), By1)
	local bottom = collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, (By1 + By2), (Bx1 + Bx2), (By1 + By2))
	
	return colA1 or colA2
		or left or right or top or bottom
end
-- LINE WITH CIRCLE COLLISION --
function collision.line_circ(Ax1, Ay1, Ax2, Ay2, Bx, By, Bradius)
	local result = false
	
	local colA1 = collision.point_circ(Ax1, Ay1, Bx, By, Bradius)
	local colA2 = collision.point_circ(Ax2, Ay2, Bx, By, Bradius)
	
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
	
	return colA1 or colA2 
		or result
end
-- LINE WITH POLY COLLISION (alias) --
function collision.line_poly(Ax1, Ay1, Ax2, Ay2, B)
	return collision.poly_line(B, Ax1, Ay1, Ax2, Ay2)
end

---- rectangles
-- RECTANGLE WITH POINT COLLISION (alias) --
function collision.rect_point(Ax1, Ay1, Ax2, Ay2, Bx, By)
	return collision.point_rect(Bx, By, Ax1, Ay1, Ax2, Ay2)
end
-- RECTANGLE WITH LINE COLLISION (alias) --
function collision.rect_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	return collision.line_rect(Bx1, By1, Bx2, By2, Ax1, Ay1, Ax2, Ay2)
end
-- RECTANGLE WITH RECTANGLE COLLISION --
function collision.rect_rect(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	return Ax1 <= Bx1 + Bx2 and Ay1 <= By1 + By2
	   and Bx1 <= Ax1 + Ax2 and By1 <= Ay1 + Ay2
end
-- RECTANGLE WITH CIRCLE COLLISION --
function collision.rect_circ(Ax1, Ay1, Ax2, Ay2, Bx, By, Bradius)
	local colx, coly = Bx, By
	if Bx <= Ax1 	   then colx = Ax1       end
	if Bx >= Ax1 + Ax2 then colx = Ax1 + Ax2 end
	if By <= Ay1       then coly = Ay1       end
	if By >= Ay1 + Ay2 then coly = Ay1 + Ay2 end
	
	return math.distance(colx, coly, Bx, By) <= Bradius
end

---- circles
-- CIRCLE WITH POINT COLLISION (alias) --
function collision.circ_point(Ax, Ay, Aradius, Bx, By)
	return point_circ(Bx, By, Ax, Ay, Aradius)
end
-- CIRCLE WITH LINE COLLISION (alias) --
function collision.circ_line(Ax, Ay, Aradius, Bx1, By1, Bx2, By2)
	return collision.line_circ(Bx1, By1, Bx2, By2, Ax, Ay, Aradius)
end
-- CIRCLE WITH RECTANGLE COLLISION (alias) --
function collision.circ_rect(Ax, Ay, Aradius, Bx1, By1, Bx2, By2)
	return collision.rect_circ(Bx1, By1, Bx2, By2, Ax, Ay, Aradius)
end
-- CIRCLE WITH CIRCLE COLLISION --
function collision.circ_circ(Ax, Ay, Aradius, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Aradius + Bradius
end

---- polygons
-- POLY WITH POINT COLLISION --
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
-- POLY WITH LINE COLLISION --
function collision.poly_line(A, Bx1, By1, Bx2, By2)
	local result = false
	
	local colB1 = collision.point_poly(Bx1, By1, A)
	local colB2 = collision.point_poly(Bx2, By2, A)
	
	local current
	local next = A[#A]
	for i=1, #A do
		current = next
		next = A[i]
		
		if collision.line_line(Bx1, By1, Bx2, By2, current[1], current[2], next[1], next[2]) then
			result = true
		end
	end
	
	return colB1 or colB2
		or result
end
