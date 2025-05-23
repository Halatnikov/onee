onee = {
	version = "0.0.2-27",
	colors = {	
		bg = {8, 8, 8},
		bg_deep = {16, 16, 16},
	},
}

---------------------------------------------------------------- INIT

do
	require("conf")
	require("onee/errorhandler")
	
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
	
	love.filesystem.createDirectory("/")
	
	-- for loading external dlls
	onee.libtype = jit.arch == "x64" and (love._os == "Windows" and "dll" or love._os == "Linux" and "so")
	if onee.libtype then
		love.filesystem.createDirectory("libs")
		package.cpath = package.cpath..";"..love.filesystem.getSaveDirectory().."/libs/?."..onee.libtype
	end
	
	-- set default font
	onee.font = love.graphics.newFont("onee/ProggyClean.ttf", 16)
	onee.font:setFilter("nearest")
	
	-- various сonstants
	framerate = 60
	tick = 1 / framerate
	onee.time_start = os.time()
	onee.allow_update = true
	onee.width, onee.height = love.config.width, love.config.height

	-- libraries (user)
	require("onee/libs/oo")
	require("onee/libs/semver")
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
	require("onee/debug")
	require("onee/files")
	require("onee/window")
	require("onee/input")
	
	require("onee/scenes")
	require("onee/assets")
	require("onee/collisions")
	require("onee/yui")
	
	-- :)
	log(string.format("onee %s | love2d %s (%s, %s)", onee.version, love._version, _VERSION, string.left(jit.version, 13)))
	local date = os.date("*t")
	log(string.format("%d-%02d-%02d %02d:%02d:%02d", date.year, date.month, date.day, date.hour, date.min, date.sec))
	
	-- :o
	debug.enable(debug_mode)
	
	-- resolve some initital things
	onee.compatibility(onee.version, love.config.onee)
	window.update() -- init game canvas
	onee.persist = Scene()
	
	-- off we go
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
	end)
	
	input.draw()
	debug.draw_post()
	
	-- reset the graphics state constantly
	love.graphics.reset(true)
	
	_prof.mark("sleeping...")
	-- frame limiter end
	onee.after_draw = love.timer.getTime()
	onee.before_update = (onee.before_update <= onee.after_draw) and onee.after_draw or onee.before_update
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