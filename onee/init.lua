onee = {}
onee.version = "0.0.2-15"

---------------------------------------------------------------- INIT

-- temp font storage
fonts = {}
fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16, "mono", 2)
fonts.proggy_clean:setFilter("nearest")

do
	require("conf")
	require("onee/libs/errorhandler")
	
	-- love2d shenanigans
	love.filesystem.setIdentity(love.filesystem.getIdentity(), true)
	mobile = (love._os == "Android" or love._os == "iOS")
	
	if not (debug_hotswap and lurker.swappedonce) then
		love.window.setMode(love.config.window.width, love.config.window.height, {
			vsync = 0, resizable = true, fullscreen = mobile,
			minwidth = love.config.window.width, minheight = love.config.window.height,
		})
	end
	
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	onee.bg = {8/255, 8/255, 8/255}
	love.graphics.present() -- black screen

	-- libraries (user)
	require("onee/libs/urfs")
	require("onee/libs/json")
	require("onee/libs/gifload")
	require("onee/libs/gltf")

	-- onee modules
	require("onee/utils")
	require("onee/resolution")
	require("onee/files")
	require("onee/debug")
	
	require("onee/input")
	require("onee/collisions")
	require("onee/assets")
	require("onee/scenes")

	-- gui (user)
	require("onee/gui/yui")
	
	-- various сonstants
	framerate = 60
	tick = 1 / framerate
	onee.time_start = os.time()
	onee.allow_update = true
	onee.width, onee.height = love.config.window.width, love.config.window.height
	
	-- :o
	debug.enable(debug_mode)
	
	-- :)
	print("LOVE2D "..love._version.." (".._VERSION..", "..string.left(jit.version, 13)..") | onee "..onee.version)
	local date = os.date("*t")
	print(string.format("%d/%02d/%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
	
	-- off we go
	scene.set("init")
end

---------------------------------------------------------------- MAIN LOOP

function onee.update(dt_)
	_prof.push("frame")
	_prof.push("onee.update")
	
	-- frame limiter start
	onee.before_update = (onee.before_update or 0) + tick
	
	-- various сonstants
	windowwidth = love.graphics.getWidth()
	windowheight = love.graphics.getHeight()
	mousex = love.mouse.getX()
	mousey = love.mouse.getY()
	
	if onee.allow_update then
		-- various сonstants that require the game running
		dt = love.timer.getDelta()
		fps = 1 / dt
		ms = (ms or 0) + dt
		frames = (frames or 0) + 1
		
	-- main loop
		scene.update()
		input.update()
	end
	
	debug.update()
	--
	
	_prof.pop()
end

function onee.draw()
	_prof.push("onee.draw")
	
	-- main loop
	scene.draw()
	input.draw()
	yui.draw()
	
	debug.draw()
	--
	
	-- reset the graphics state constantly
	love.graphics.reset()
	love.graphics.setLineStyle("rough")
	love.graphics.setBackgroundColor(onee.bg[1], onee.bg[2], onee.bg[3])
	
	-- frame limiter end
	_prof.mark("sleeping...")
	onee.after_draw = love.timer.getTime()
	if onee.before_update <= onee.after_draw then onee.before_update = onee.after_draw end
	love.timer.sleep(onee.before_update - onee.after_draw)
	
	_prof.pop()
	_prof.pop("frame")
end

function onee.resize(width, height)
	
end
love.resize = onee.resize

function onee.quit()
	
end
love.quit = onee.quit

---------------------------------------------------------------- MISC

_VERSION_major, _VERSION_minor = string.version(string.right(_VERSION, 3))
jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
jit.version_revision = string.left(jit.version_rolling, 2)
