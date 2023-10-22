collision = {} -- functions

---------------------------------------------------------------- 

---- points
-- POINT WITH LINE COLLISION --
function collision.point_line(Ax, Ay, Bx1, By1, Bx2, By2)
	local length = math.distance(Bx1,By1,Bx2,By2)
	local distance1 = math.distance(Ax,Ay,Bx1,By1)
	local distance2 = math.distance(Ax,Ay,Bx2,By2)
	
	return distance1 + distance2 >= length - 0.1 
	   and distance1 + distance2 <= length + 0.1
end
-- POINT WITH RECTANGLE COLLISION --
function collision.point_rect(Ax, Ay, Bx1, By1, Bx2, By2)
	return
	    Ax >= Bx1 and Ax <= Bx1 + Bx2
	and Ay >= By1 and Ay <= By1 + By2
end
-- POINT WITH CIRCLE COLLISION --
function collision.point_circ(Ax, Ay, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Bradius
end

---- lines
-- LINE WITH LINE COLLISION --
function collision.line_line(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	local colA = ((Bx2 - Bx1) * (Ay1 - By1) - (By2 - By1) * (Ax1 - Bx1)) 
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	local colB = ((Ax2 - Ax1) * (Ay1 - By1) - (Ay2 - Ay1) * (Ax1 - Bx1))
			   / ((By2 - By1) * (Ax2 - Ax1) - (Bx2 - Bx1) * (Ay2 - Ay1))
	
	return colA >= 0 and colA <= 1
	   and colB >= 0 and colB <= 1
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
	local colA1 = collision.point_circ(Ax1, Ay1, Bx, By, Bradius)
	local colA2 = collision.point_circ(Ax2, Ay2, Bx, By, Bradius)
	local collision = false
	
	local length = math.distance(Ax1, Ay1, Ax2, Ay2)
	local centerx = Bx - Ax1
	local centery = By - Ay1
	local angle = (centerx * (Ax2 - Ax1)) + (centery * (Ay2 - Ay1))
	
	if angle > 0 then
		angle = angle/length
		
		if angle < length then
			collision =  math.sqrt((centerx^2) + (centery^2) - (angle^2)) <= Bradius
		end
	end
	
	return colA1 or colA2 
		or collision
end

---- rectangles
-- RECTANGLE WITH RECTANGLE COLLISION --
function collision.rect_rect(Ax1, Ay1, Ax2, Ay2, Bx1, By1, Bx2, By2)
	return
		Ax1 <= Bx1 + Bx2 and Ay1 <= By1 + By2
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
-- CIRCLE WITH CIRCLE COLLISION --
function collision.circ_circ(Ax, Ay, Aradius, Bx, By, Bradius)
	return math.distance(Ax, Ay, Bx, By) <= Aradius + Bradius
end

-- add intersections?

function math.distance(x1, y1, x2, y2)
	if not y2 then x2, y2 = y1, y1; y1 = x1 end -- allow one axis
	return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end
