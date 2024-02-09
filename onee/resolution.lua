resolution = {}

-- init
do
	resolution.x, resolution.y = 0, 0
	resolution.scale = 1
	resolution.internal = 1
	
	resolution.canvas = nil
	resolution.quad = love.graphics.newQuad(0,0,0,0,0,0)
end

function resolution.update(width, height)
	if not (width and height) then width, height = love.graphics.getDimensions() end
	
	resolution.scale = math.min(width / onee.width, height / onee.height)
	
	local refwidth = onee.width * resolution.internal
	local refheight = onee.height * resolution.internal
	
	resolution.canvas = love.graphics.newCanvas(refwidth, refheight, {dpiscale = 1, format = "srgba8"})
	resolution.quad:setViewport(0, 0, onee.width, onee.height, refwidth, refheight)
	
	resolution.x = math.floor((width - (resolution.scale * onee.width)) / (2 * resolution.internal))
	resolution.y = math.floor((height - (resolution.scale * onee.height)) / (2 * resolution.internal))
	
end

love.graphics.reset_ = love.graphics.reset
function love.graphics.reset(truereset)
	if truereset then love.graphics.reset_() return end
	
	love.graphics.setColor(1,1,1,1)
	love.graphics.setBlendMode("alpha")
	love.graphics.setLineWidth(1)
end

function resolution.push()
	love.graphics.setCanvas(resolution.canvas)
	love.graphics.origin()
	love.graphics.clear(onee.bg[1], onee.bg[2], onee.bg[3])
end

function resolution.pop()
	love.graphics.setCanvas()
	love.graphics.clear(onee.bg[1], onee.bg[2], onee.bg[3])
	love.graphics.scale(resolution.internal)
	love.graphics.draw(resolution.canvas, resolution.quad, resolution.x, resolution.y, 0, resolution.scale/resolution.internal)
	love.graphics.origin()
end
