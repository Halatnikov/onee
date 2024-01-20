group("collision between two shapes", function()
	
	test("point in rectangle", function()
		assert(collision.point_rect(50, 50, 0, 0, 100, 100)).pass()
		assert(collision.point_rect(150, 50, 0, 0, 100, 100)).deny()
	end)
	
	test("aliases", function()
		local rect_point = collision.rect_point(0, 0, 100, 100, 50, 150)
		local _point_rect = collision.point_rect(150, 50, 0, 0, 100, 100)
		assert(rect_point == _point_rect).pass()
	end)
	
end)