onee = {
	version = "0.0.2-13",
}

---------------------------------------------------------------- INIT

-- temp font storage
fonts = {}
fonts.proggy_clean = love.graphics.newFont("ProggyClean.ttf", 16, "mono", 2)
fonts.proggy_clean:setFilter("nearest")

-- init itself
do
	require("conf")
	require("onee/libs/errorhandler")

	-- libraries
	require("onee/libs/lurker")
	require("onee/libs/df-serialize")
	require("onee/libs/json")
	require("onee/libs/gifload")
	require("onee/libs/gltf")

	-- onee modules
	require("onee/utils")
	require("onee/input")
	require("onee/collisions")
	require("onee/assets")
	require("onee/scene")
	require("onee/debug")

	-- gui libraries
	require("onee/yui")
	require("onee/imgui")
	
	tick = 1 / framerate
	onee.time_start = os.time()
	onee.allow_update = true
	
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	onee.bg = {8/255, 8/255, 8/255}
	
	-- :)
	print("LOVE2D "..love._version.." (".._VERSION..", "..string.left(jit.version, 13)..") | onee "..onee.version)
	print(os.date())
	scenes.set("init")
end

-- misc
_VERSION_major, _VERSION_minor = string.version(string.right(_VERSION, 3))
jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
jit.version_revision = string.left(jit.version_rolling, 2)

---------------------------------------------------------------- MAIN LOOP

function onee.update(dt_)
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
		
		scenes.update()
		input.update()
	end
	
	debug.update()
	imgui.update()
	
end

function onee.draw()
	
	scenes.draw()
	input.draw()
	
	debug.draw()
	imgui.draw()
	yui.draw()
	
	-- reset the graphics state constantly
	love.graphics.reset()
	love.graphics.setBackgroundColor(onee.bg[1], onee.bg[2], onee.bg[3])
	
	-- fps limiter end
	onee.after_draw = love.timer.getTime()
	if onee.before_update <= onee.after_draw then onee.before_update = onee.after_draw end
	love.timer.sleep(onee.before_update - onee.after_draw)
end

---------------------------------------------------------------- MISC

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
