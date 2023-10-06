version = "0.0.2-1"

love.graphics.setDefaultFilter("nearest","nearest",0)

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
	nuklear.update()
	input.update()
	
end

function love.draw()
	
	scenes.draw()
	nuklear.draw()
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw) -- limit fps to 60
	
end

-- central callbacks
function love.keypressed(key, scancode, isrepeat)
	input.keypressed(key, scancode, isrepeat)
	debug.keypressed(key, scancode, isrepeat)
	nuklear.keypressed(key, scancode, isrepeat)
end
function love.mousepressed(x, y, button, istouch, presses)
	input.mousepressed(x, y, button, istouch, presses)
	nuklear.mousepressed(x, y, button, istouch, presses)
end
function love.wheelmoved(x, y)
	input.wheelmoved(x, y)
	nuklear.wheelmoved(x, y)
end