version = "0.0.2-8"

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
	tick = 0.016
	before_update = before_update + (1/60)
	
	if allow_update then
		misc.update()
		scenes.update()
		input.update()
	end
	
	--gui.update()
	--nuklear.update()
	imgui.update(dt)
	
	debug.update()
end

function love.draw()
	scenes.draw()
	input.draw()
	
	--gui.draw()
	--nuklear.draw()
	imgui.draw()
	
	debug.draw()
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end

-- central callbacks
function love.keypressed(key, scancode, isrepeat)
	debug.keypressed(key, scancode, isrepeat)
	
	--gui.keypressed(key, scancode, isrepeat)
	--nuklear.keypressed(key, scancode, isrepeat)
	imgui.keypressed(key, scancode, isrepeat)
end
function love.keyreleased(key, scancode)
	--gui.keyreleased(key, scancode)
	--nuklear.keyreleased(key, scancode)
	imgui.keyreleased(key, scancode)
end
function love.mousepressed(x, y, button, istouch, presses)
	input.mousepressed(x, y, button, istouch, presses)
	
	--gui.mousepressed(x, y, button, istouch, presses)
	--nuklear.mousepressed(x, y, button, istouch, presses)
	imgui.mousepressed(x, y, button, istouch, presses)
end
function love.mousereleased(x, y, button, istouch)
	input.mousereleased(x, y, button, istouch)
	
	--gui.mousereleased(x, y, button, istouch)
	--nuklear.mousereleased(x, y, button, istouch)
	imgui.mousereleased(x, y, button, istouch)
end
function love.mousemoved(x, y, dx, dy, istouch)
	--nuklear.mousemoved(x, y, dx, dy, istouch)
	imgui.mousemoved(x, y, dx, dy, istouch)
end
function love.wheelmoved(x, y)
	input.wheelmoved(x, y)
	
	--gui.wheelmoved(x, y)
	--nuklear.wheelmoved(x, y)
	imgui.wheelmoved(x, y)
end
function love.textinput(text)
	--gui.textinput(text)
	--nuklear.textinput(text)
	imgui.textinput(text)
end
