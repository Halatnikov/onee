version = "0.0.2-11"

function love.load()
	require("conf")
	require("src")
	
	scenes.set("init")
end

function love.quit()
	
end

local image1 = love.graphics.newImage("sprites/test_gdportal/square.png")

local ps = love.graphics.newParticleSystem(image1, 24)
ps:setColors(0, 1, 1, 0.5)
ps:setEmissionArea("uniform", 32, 64)
ps:setEmissionRate(30)
ps:setOffset(16, 16)
ps:setParticleLifetime(0.4, 0.8)
ps:setRadialAcceleration(-260, -340)
ps:setSizes(0.35, 0.05)
ps:setSizeVariation(0.33)
ps:setSpeed(130, 170)
ps:setSpread(0.87)



-- main loop
function love.update(dt)
	before_update = before_update + (1/framerate)
	
	if allow_update then
		misc.update()
		scenes.update()
		input.update()
	end
	
	debug.update()
	--gui.update()
	imgui.update(dt)
	
	ps:update(dt)
end

function love.draw()
	scenes.draw()
	input.draw()
	
	debug.draw()
	--gui.draw()
	imgui.draw()
	
	love.graphics.setBlendMode("add")
	--love.graphics.rectangle("line",140-20,270-80,20*2,80*2)
	love.graphics.draw(ps, 187-48, 300-16)
	love.graphics.reset()
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end
