onee = {}
onee.version = "0.0.2-21"
onee.colors = {	
	bg = {8/255, 8/255, 8/255},
	bg_deep = {16/255, 16/255, 16/255},
}

---------------------------------------------------------------- INIT

do
	require("conf")
	require("onee/libs/errorhandler")
	
	-- love2d shenanigans
	mobile = (love._os == "Android" or love._os == "iOS")
	
	love.window.setMode(love.config.width, love.config.height, {
		vsync = 0, resizable = true, fullscreen = mobile,
		minwidth = love.config.width, minheight = love.config.height,
	})
	
	love.window.setTitle(love.config.title)
	
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	love.graphics.clear()
	love.graphics.present() -- black screen
	
	-- for loading external dlls
	onee.libtype = jit.arch == "x64" and (love._os == "Windows" and "dll" or love._os == "Linux" and "so")
	if onee.libtype then
		package.cpath = package.cpath..";"..love.filesystem.getSaveDirectory().."/libs/?."..onee.libtype
		love.filesystem.createDirectory("libs")
	end

	-- libraries (user)
	require("onee/libs/urfs")
	require("onee/libs/timer")
	require("onee/libs/json")
	require("onee/libs/runtime-textureatlas")
	require("onee/libs/gifload")
	require("onee/libs/gltf")
	love.joystick.loadGamepadMappings("onee/libs/gamecontrollerdb.txt")

	-- onee modules
	require("onee/utils")
	require("onee/misc")
	require("onee/window")
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
	onee.width, onee.height = love.config.width, love.config.height
	
	_VERSION_major, _VERSION_minor = string.version(string.right(_VERSION, 3))
	jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
	jit.version_revision = string.left(jit.version_rolling, 2)
	
	-- :o
	debug.enable(debug_mode)
	
	-- :)
	print("love2d "..love._version.." (".._VERSION..", "..string.left(jit.version, 13)..") | onee "..onee.version)
	local date = os.date("*t")
	print(string.format("%d/%02d/%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
	
	-- off we go
	window.update() -- init game canvas
	scene.set("init")
end

---------------------------------------------------------------- MAIN LOOP

function onee.update()
	_prof.push("frame")
	_prof.push("onee.update")
	
	-- frame limiter start
	onee.before_update = (onee.before_update or 0) + tick
	
	-- update сonstants
	windowwidth, windowheight = love.graphics.getWidth(), love.graphics.getHeight()
	mousex, mousey = love.mouse.getX(), love.mouse.getY()
	
	if onee.allow_update then
		-- update сonstants that require the game running
		dt = love.timer.getDelta()
		fps = 1 / dt
		ms = (ms or 0) + dt
		frames = (frames or 0) + 1
		
		scene.update()
		input.update()
	end
	
	debug.update()
	
	_prof.pop()
end

function onee.draw()
	_prof.push("onee.draw")
	
	window.draw(function()
		scene.draw()
		debug.draw()
		yui.draw()
	end)
	
	input.draw()
	debug.draw_post()
	
	-- reset the graphics state constantly
	love.graphics.reset(true)
	
	_prof.mark("sleeping...")
	-- frame limiter end
	onee.after_draw = love.timer.getTime()
	if onee.before_update <= onee.after_draw then onee.before_update = onee.after_draw end
	love.timer.sleep(onee.before_update - onee.after_draw)
	
	_prof.pop()
	_prof.pop("frame")
end

function onee.resize(width, height)
	window.update(width, height)
end
love.resize = onee.resize

function onee.quit()
	
end
love.quit = onee.quit

-- love.focus, love.mousefocus, love.visible, love.filedropped, love.directorydropped