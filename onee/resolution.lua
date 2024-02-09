resolution = {}

-- init
do
	resolution.x, resolution.y = 0, 0
	resolution.scale = 1
	resolution.internal = 2
	resolution.mode = ""
	
	resolution.canvas = nil
	resolution.quad = love.graphics.newQuad(0, 0, 0, 0, 0, 0)
end
transform = love.math.newTransform()

--!
function resolution.update(width, height)
	if not (width and height) then width, height = love.graphics.getDimensions() end
	
	local refwidth = onee.width * resolution.internal
	local refheight = onee.height * resolution.internal
	resolution.refwidth, resolution.refheight = refwidth, refheight
	
	resolution.scale = math.min(width / onee.width, height / onee.height)
	-- if resolution.mode == "integer" then 
		-- resolution.scale = math.floor(resolution.scale)
	-- end
	
	resolution.x = math.floor((width - (resolution.scale * onee.width)) / (2 * resolution.internal))
	resolution.y = math.floor((height - (resolution.scale * onee.height)) / (2 * resolution.internal))
	
	resolution.canvas = love.graphics.newCanvas(refwidth, refheight, {dpiscale = 1, msaa = 0})
	resolution.canvas:setWrap(TILE.ONCE)
	resolution.canvas:setFilter("nearest", "nearest", 0)
	
	resolution.quad:setViewport(0, 0, onee.width, onee.height, refwidth, refheight)
	
end


--!
function resolution.draw(func)
		love.graphics.setCanvas()
		love.graphics.setDefaultFilter("nearest", "nearest", 0)
	resolution.canvas:renderTo(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		resolution.push()
		func()
		resolution.pop()
	end)
	
	love.graphics.clear(onee.colors.bg_deep[1], 0.25, onee.colors.bg_deep[3])
	love.graphics.draw(resolution.canvas, resolution.x, resolution.y, 0, 1)
	
	--love.graphics.origin()
end

function resolution.push()
	--love.graphics.origin()
	love.graphics.push()
	--transform:reset()
	--transform:scale(resolution.internal)
	--love.graphics.applyTransform(transform)
	--love.graphics.translate(-50,-50)
	--love.graphics.setDefaultFilter("nearest", "nearest", 0)
	--love.graphics.reset()
	love.graphics.scale(resolution.internal)
	--local saveCanvas = love.graphics.getCanvas()
end

function resolution.pop()
	--love.graphics.setCanvas()
	--love.graphics.setCanvas(saveCanvas)
	--love.graphics.origin()
	love.graphics.pop()
end