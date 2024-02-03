onee = {}
onee.version = "0.0.2-14"

---------------------------------------------------------------- INIT

-- temp font storage
fonts = {}
fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16, "mono", 2)
fonts.proggy_clean:setFilter("nearest")

-- init itself
do
	require("conf")
	require("onee/libs/errorhandler")

	-- libraries (user)
	require("onee/libs/json")
	require("onee/libs/gifload")
	require("onee/libs/gltf")

	-- onee modules
	require("onee/utils")
	require("onee/input")
	require("onee/collisions")
	require("onee/assets")
	require("onee/scenes")
	require("onee/debug")

	-- gui (user)
	require("onee/yui")
	
	tick = 1 / framerate
	onee.time_start = os.time()
	onee.allow_update = true
	
	debug.enable(debug_mode)
	
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	onee.bg = {8/255, 8/255, 8/255}
	
	-- :)
	print("LOVE2D "..love._version.." (".._VERSION..", "..string.left(jit.version, 13)..") | onee "..onee.version)
	local date = os.date("*t")
	print(date.year.."/"..string.zeropad(date.month,2).."/"..string.zeropad(date.day,2).." "..string.zeropad(date.hour,2)..":"..string.zeropad(date.min,2)..":"..string.zeropad(date.sec,2))
	scene.set("init")
end

---------------------------------------------------------------- MAIN LOOP

function onee.update(dt_)
	_prof.push("frame")
	_prof.push("onee.update")
	
	-- fps limiter start
	onee.before_update = (onee.before_update or 0) + tick
	
	-- various helper globals
	windowwidth = love.graphics.getWidth()
	windowheight = love.graphics.getHeight()
	mousex = love.mouse.getX()
	mousey = love.mouse.getY()
	
	if onee.allow_update then
		-- helper globals that require the game running
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
	
	scene.draw()
	input.draw()
	
	debug.draw()
	yui.draw()
	
	-- reset the graphics state constantly
	love.graphics.reset()
	love.graphics.setBackgroundColor(onee.bg[1], onee.bg[2], onee.bg[3])
	
	-- fps limiter end
	onee.after_draw = love.timer.getTime()
	if onee.before_update <= onee.after_draw then onee.before_update = onee.after_draw end
	love.timer.sleep(onee.before_update - onee.after_draw)
	
	_prof.pop()
	_prof.pop("frame")
end

function onee.quit()
	
end

---------------------------------------------------------------- MISC

_VERSION_major, _VERSION_minor = string.version(string.right(_VERSION, 3))
jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
jit.version_revision = string.left(jit.version_rolling, 2)

--TODO: make this support ... arguments and then just check if they're all strings or something
-- don't print to console if it has a category maybe

-- maybe i should just make a log() function, this doesn't seem like a good idea
--print_ = print
function log(arg)
	--debug.table(debug.getinfo(2)) --get name of the function that called this somehow
	--io.write(tostring(arg), newline)
	print(arg)
	-- use kinda sparingly, because this is laggy
	table.insert(qqueue, {text = {{1,1,1,1},tostring(arg)}, timestamp = ms})
end
-- /!\ [AssetLoading] asset.sprite() | asset "name" already loaded!
log("test")
