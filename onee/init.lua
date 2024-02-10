onee = {}
onee.version = "0.0.2-15"
onee.colors = {
	bg = {8/255, 8/255, 8/255},
	bg_deep = {16/255, 16/255, 16/255},
}

---------------------------------------------------------------- INIT

function onee.init()
	require("conf")
	require("onee/libs/errorhandler")
	
	-- love2d shenanigans
	love.filesystem.setIdentity(love.filesystem.getIdentity(), true)
	mobile = (love._os == "Android" or love._os == "iOS")
	
	love.window.setMode(love.config.window.width, love.config.window.height, {
		vsync = 0, resizable = true, fullscreen = mobile,
		minwidth = love.config.window.width, minheight = love.config.window.height,
	})
	
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	love.graphics.clear()
	love.graphics.present() -- black screen

	-- libraries (user)
	require("onee/libs/urfs")
	require("onee/libs/json")
	require("onee/libs/gifload")
	require("onee/libs/gltf")

	-- onee modules
	require("onee/utils")
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
	onee.width, onee.height = love.config.window.width, love.config.window.height
	windowwidth, windowheight = onee.width, onee.height
	
	_VERSION_major, _VERSION_minor = string.version(string.right(_VERSION, 3))
	jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
	jit.version_revision = string.left(jit.version_rolling, 2)
	
	-- love callbacks
	onee.love("resize", onee.resize)
	onee.love("quit", onee.quit)
	
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
	
	-- update сonstants
	windowwidth = love.graphics.getWidth()
	windowheight = love.graphics.getHeight()
	mousex = love.mouse.getX()
	mousey = love.mouse.getY()
	
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
	
	-- frame limiter end
	_prof.mark("sleeping...")
	onee.after_draw = love.timer.getTime()
	if onee.before_update <= onee.after_draw then onee.before_update = onee.after_draw end
	love.timer.sleep(onee.before_update - onee.after_draw)
	
	_prof.pop()
	_prof.pop("frame")
end

function onee.resize(width, height)
	window.update(width, height)
end

function onee.quit()
	
end

---------------------------------------------------------------- MISC

onee.love_callbacks = {}

--! hook love callbacks, so it can call multiple functions at once
-- @param name -- if love.x, then put it as "x"
function onee.love(name, func)
	onee.love_callbacks[name] = onee.love_callbacks[name] or {}
	
	local new = onee.love_callbacks[name] == {} and true
	if new then table.insert(onee.love_callbacks[name], love[name]) end
	
	table.insert(onee.love_callbacks[name], func)
	
	love[name] = function(...)
		for i=1, #onee.love_callbacks[name] do
			onee.love_callbacks[name][i](...)
		end
	end
end

love.graphics.reset_ = love.graphics.reset

--! modified love.graphics.reset for my needs
function love.graphics.reset(ignore) -- bool=
	if ignore then love.graphics.reset_() end
	
	-- might as well use these here
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	love.graphics.setBackgroundColor(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
	love.graphics.setFont(onee.font or love.graphics.getFont())
	
	if not ignore then
		-- don't deactivate canvases, transformations, shaders, current font and scissors!
		love.graphics.setColor(1,1,1,1)
		love.graphics.setBlendMode("alpha")
		
		love.graphics.setLineWidth(1)
		love.graphics.setLineJoin("miter")
		love.graphics.setPointSize(1)
		love.graphics.setStencilTest()
		love.graphics.setDepthMode()
		love.graphics.setColorMask()
		love.graphics.setWireframe(false)
		love.graphics.setMeshCullMode("none")
		love.graphics.setFrontFaceWinding("ccw")
	end
end

return onee.init()