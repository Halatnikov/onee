local object = {}

function object.init(id)
	instances[id].x = love.math.random(0,640)
	instances[id].y = love.math.random(0,480)
	instances[id].inc = love.math.random(1,16)
	instances[id].start = love.math.random(-100,100)
	
	instances[id].timer = instances[id].start
end

function object.update(id)
	instances[id].timer = instances[id].timer + instances[id].inc
end

function object.draw(id)
	love.graphics.print(instances[id].timer, instances[id].x, instances[id].y)
end

return object
