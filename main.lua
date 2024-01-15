version = "0.0.2-11"

function love.load()
	require("conf")
	require("src")
	
	scenes.set("init")
end

function love.quit()
	
end

-- main loop
function love.update(dt)
	misc.update_start()
	
	if allow_update then
		misc.update()
		scenes.update()
		input.update()
	end
	
	debug.update()
	imgui.update(dt)
	yui.update()
end

function love.draw()
	scenes.draw()
	input.draw()
	
	debug.draw()
	imgui.draw()
	yui.draw()
	
	misc.draw_end()
end
