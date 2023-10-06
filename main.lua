
version = "0.0.1-4" -- pre-alpha
before_update = 0

--nest = require("src/libs/3ds-nest"):init({mode = "ctr", scale = 1, emulateJoystick = false})

function love.load()
	
	local major, minor, revision = love.getVersion()
    love_ver = "LOVE2D "..major.."."..minor.."."..revision.." (".._VERSION..")"
	print(love_ver.." | Onee "..version)
	
	require("src/objects")
	require("src/level")
	require("src/input")
	require("src/misc")
	require("src/nuklear")
	
	require("src/libs")
	
	love.graphics.setBackgroundColor(8/255,8/255,8/255)
	
end

function love.update()
	
	if love._console_name == "3DS" then n3ds = true end
	before_update = before_update + (1/60)

	if nuklear then nuklear_gui() end -- nuklear gui update
	
	if debug_mode then debug_main() end
	
	input_main()
	
	misc_main()
	
	instances_update()
	
	if photon then photon_update() end
	
end

function love.draw(screen)
	
	if not n3ds then
		instances_draw()
	
		if nuklear then gui:draw() end -- nuklear gui draw
	end
	
	if n3ds then
		if screen ~= "bottom" then
			instances_draw()
		end
		if screen == "bottom" then
			love.graphics.print("poopoo peepee 3d 2")
			love.graphics.rectangle("fill",50,150,40,40)
		end
	end
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then
		before_update = after_draw
	end
	love.timer.sleep(before_update - after_draw)
	
end

-- central callbacks

function love.keypressed(key, scancode, isrepeat)
	love.keypressed_input(key, scancode, isrepeat)
	if nuklear then love.keypressed_nuklear(key, scancode, isrepeat) end
	love.keypressed_debug(key, scancode, isrepeat)
end

function love.mousepressed(x, y, button, istouch, presses)
	love.mousepressed_input(x, y, button, istouch, presses)
	if nuklear then love.mousepressed_nuklear(x, y, button, istouch, presses) end
end

function love.wheelmoved(x, y)
	love.wheelmoved_input(x, y)
	if nuklear then love.wheelmoved_nuklear(x, y) end
end
