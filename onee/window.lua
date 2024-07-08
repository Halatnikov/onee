window = {}

-- init
do
	window.x, window.y = 0, 0
	window.scale = 0

	window.internal = 1
	window.mode = ""
	
	window.gamescale = 1
	window.canvas = nil
end

--!
function window.update(width, height)
	if not (width and height) then width, height = love.graphics.getDimensions() end
	
	local refwidth = onee.width * window.internal
	local refheight = onee.height * window.internal
	
	window.scale = math.min(width / onee.width, height / onee.height)
	if window.mode == "integer" then 
		window.scale = math.floor((window.scale * window.internal) / window.internal)
	end
	
	window.gamescale = 1 / window.scale / window.internal
	
	window.x = math.floor((width - (window.scale * onee.width)) / 2)
	window.y = math.floor((height - (window.scale * onee.height)) / 2)
	
	window.canvas = love.graphics.newCanvas(refwidth, refheight, {dpiscale = 1, msaa = 0})
	window.canvas:setWrap(TILE.ONCE)
	window.canvas:setFilter("nearest", "nearest", 0)
end

--!
function window.draw(func)
	if not window.canvas then return end
	
	window.canvas:renderTo(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		window.push()
		func()
		window.pop()
	end)
	
	love.graphics.clear(onee.colors.bg_deep[1], onee.colors.bg_deep[2], onee.colors.bg_deep[3])
	love.graphics.draw(window.canvas, window.x, window.y, 0, window.scale / window.internal)
end

--! upscaling
function window.push()
	love.graphics.push()
	love.graphics.scale(window.internal)
end

--!
function window.pop()
	love.graphics.pop()
end

--! get mouse position relative to the game
function window.mouse()
	local x = math.floor((love.mouse.getX() - window.x) * window.gamescale)
	local y = math.floor((love.mouse.getY() - window.y) * window.gamescale)
	return x, y
end
