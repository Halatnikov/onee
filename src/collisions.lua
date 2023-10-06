collision = {} -- functions

---------------------------------------------------------------- 

-- POINT WITH RECTANGLE COLLISION --
function collision.point_rect(px, py, x1, y1, x2, y2)
	if  px >= x1 and px <= x2
	and py >= y1 and py <= y2 then
		return true
	else
		return false
	end
end
-- POINT WITH ELLIPSE COLLISION --
function collision.point_ellipse(px, py, x, y, radiusx, radiusy)
	if math.pow(px - x, 2) / radiusx ^ 2
     + math.pow(py - y, 2) / radiusy ^ 2 <= 1 then
		return true
	else
		return false
	end
end
