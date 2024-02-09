resolution = {}

-- init
do
	resolution.x, resolution.y = 0, 0
	resolution.scale = 0
	resolution.internal = 1
	resolution.mode = ""
	
	resolution.canvas = nil
end

--!
function resolution.update(width, height)
	if not (width and height) then width, height = love.graphics.getDimensions() end
	
	local refwidth = onee.width * resolution.internal
	local refheight = onee.height * resolution.internal
	resolution.refwidth, resolution.refheight = refwidth, refheight
	
	resolution.scale = math.min(width / onee.width, height / onee.height)
	if resolution.mode == "integer" then 
		resolution.scale = math.floor((resolution.scale * resolution.internal) / resolution.internal)
		--resolution.scale = math.floor(math.max(resolution.scale, 1/resolution.internal))
	end
	
	resolution.x = math.floor((width - (resolution.scale * onee.width)) / 2)
	resolution.y = math.floor((height - (resolution.scale * onee.height)) / 2)
	
	resolution.canvas = love.graphics.newCanvas(refwidth, refheight, {dpiscale = 1, msaa = 0})
	resolution.canvas:setWrap(TILE.ONCE)
	resolution.canvas:setFilter("nearest", "nearest", 0)
end

--!
function resolution.draw(func)
	resolution.canvas:renderTo(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		resolution.push()
		func()
		resolution.pop()
	end)
	
	love.graphics.clear(onee.colors.bg_deep[1], onee.colors.bg_deep[2], onee.colors.bg_deep[3])
	love.graphics.draw(resolution.canvas, resolution.x, resolution.y, 0, resolution.scale/resolution.internal)
end

--!
function resolution.push()
	love.graphics.push()
	love.graphics.scale(resolution.internal)
end

--!
function resolution.pop()
	love.graphics.pop()
end