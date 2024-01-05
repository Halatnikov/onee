version = "0.0.2-10"

function love.load()
	require("conf")
	require("src")
	
	print(love.version.." | onee "..version)
	scenes.set("init")
end

function love.quit()
	
end

-- main loop
function love.update(dt)
	before_update = before_update + (1/framerate)
	
	if allow_update then
		misc.update()
		scenes.update()
		input.update()
	end
	
	--gui.update()
	imgui.update(dt)
	
	debug.update()
end

function love.draw()
	scenes.draw()
	input.draw()
	
	--gui.draw()
	imgui.draw()
	
	debug.draw()
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end
