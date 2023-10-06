version = "0.0.2-2"

function love.load()
	require("conf")
	require("src")
	
	print(love.version.." | onee "..version)
	scenes.set("init")
end

-- main loop
function love.update(dt)
	before_update = before_update + (1/60)
	
	misc.update()
	scenes.update()
	input.update()
	gui.update()
	if debug_mode then debug.update() end
end

function love.draw()
	scenes.draw()
	input.draw()
	gui.draw()
	if debug_mode then debug.draw() end
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end

-- central callbacks
function love.keypressed(key, scancode, isrepeat)
	debug.keypressed(key, scancode, isrepeat)
	gui.keypressed(key, scancode, isrepeat)
end
function love.mousepressed(x, y, button, istouch, presses)
	input.mousepressed(x, y, button, istouch, presses)
	gui.mousepressed(x, y, button, istouch, presses)
end
function love.mousereleased(x, y, button, istouch)
	input.mousereleased(x, y, button, istouch)
	gui.mousereleased(x, y, button, istouch)
end
function love.wheelmoved(x, y)
	input.wheelmoved(x, y)
	gui.wheelmoved(x, y)
end

