local object = {}

function object.init(id)

	local x = instances[id].x; local y = instances[id].y
	
	instances[id].animation.frame = ((x + y) % 6) + 1
	
end

function object.update(id)
	
	
	
end

return object