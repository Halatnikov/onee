collision = {} -- functions

---------------------------------------------------------------- 

-- points
-- POINT WITH RECTANGLE COLLISION --
function collision.point_rect(px, py, x1, y1, x2, y2)
	return
	    px >= x1 and px <= x2
	and py >= y1 and py <= y2
end
-- POINT WITH CIRCLE COLLISION --
function collision.point_circle(px, py, cx, cy, cradius)
	return math.distance(px, py, cx, cy) <= cradius
end

-- rectangles
-- RECTANGLE WITH RECTANGLE COLLISION --
function collision.rect_rect(ax1, ay1, ax2, ay2, bx1, by1, bx2, by2)
	return
		ax1 <= bx1 + bx2 and bx1 <= ax1 + ax2
	and ay1 <= by1 + by2 and by1 <= ay1 + ay2
end
-- RECTANGLE WITH CIRCLE COLLISION --
function collision.rect_circle(x1, y1, x2, y2, cx, cy, cradius)
	local colx, coly = cx, cy
	if (cx <= x1) 	   then colx = x1      end
	if (cx >= x1 + x2) then colx = x1 + x2 end
	if (cy <= y1)      then coly = y1      end
	if (cy >= y1 + y2) then coly = y1 + y2 end
	
	return math.distance(colx, coly, cx, cy) <= cradius 
end

-- circles
-- CIRCLE WITH CIRCLE COLLISION --
function collision.rect_rect(ax, ay, aradius, bx, by, bradius)
	return math.distance(ax, ay, bx, by) <= aradius + bradius
end


function math.distance(x1, y1, x2, y2)
	if not y2 then x2, y2 = y1, y1; y1 = x1 end -- allow one axis
	return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
