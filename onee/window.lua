window = {}

window.SCALING = {
	NONE = "none",
	INTEGER = "integer",
}

-- init
do
	window.x, window.y = 0, 0
	window.scale = 0

	window.internal = 1
	window.mode = window.SCALING.NONE
	
	window.canvas = nil
end

--!
function window.update(width, height)
	if not (width and height) then width, height = love.graphics.getDimensions() end
	
	local refwidth = onee.width * window.internal
	local refheight = onee.height * window.internal
	
	window.scale = math.min(width / onee.width, height / onee.height)
	if window.mode == window.SCALING.INTEGER then window.scale = math.floor(window.scale) end
	
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
		love.graphics.clear(rgb(onee.colors.bg))
		window.push()
		func()
		window.pop()
	end)
	
	love.graphics.clear(rgb(onee.colors.bg_deep))
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

--!
function window.tocanvas(x, y)
	local x = math.floor((x - window.x) / window.scale)
	local y = math.floor((y - window.y) / window.scale)
	return x, y
end

--!
function window.towindow(x, y)
	local x = math.floor((x * window.scale) + window.x)
	local y = math.floor((y * window.scale) + window.y)
	return x, y
end

--! get mouse position relative to the game
function window.mouse()
	return window.tocanvas(love.mouse.getPosition())
end
