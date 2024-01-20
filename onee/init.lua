onee = {
	version = "0.0.2-12",
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

---------------------------------------------------------------- DEBUG

if debug_mode then
	love.setDeprecationOutput(true)
	love.window.setTitle(love.config.window.title.." (debug)")
	
	debug_draw_collisions = true
	debug_draw_sprites = false
	
	lurker.interval = 1
	
	-- TODO: functions on disabling/reenabling debug mode, maybe unrequire lurker completely
	-- TODO: init imgui here
	-- TODO: on debug_mode disable, close all the ui
	-- TODO: shortcut ` or f1 to open/close the debug window
	
	-- monitor global variable :eyes:
	debug.globals = {}
	setmetatable(_G, {
		__newindex = function (t, k, v)
			table.insert(debug.globals, k)
			rawset(t, k, v)
		end
	})
	
end

function debug.disable()
	love.window.setTitle(love.config.window.title)
end

function debug.keypressed(k)
	if not debug_mode then return end
	
	if k == "f2" then love.event.quit("restart") end
	
	if k == "q" or k == "f3" then scenes.set("init") end
	
	if k == "f" then log((#qqueue+1).." HOLY SHIT "..string.random(10).." Testing testing Test Test 2 3 4 omg my god "..ms) end
	if k == "g" then log(string.random(150)) end
end
love.keypressed = debug.keypressed

function debug.update()
	if not debug_mode then debug.disable() return end
	
	if debug_hotswap then lurker.update() end
end

a = {{0,0}, {100,10}, {50,100}, {60,30}}
local ox = 50
local oy = 50

qqueue = {}
function debug.draw()
	if not debug_mode then return end
	debug.drawlist = {}
	
	if mobile then
		for i,id in ipairs(love.touch.getTouches()) do
			local touchx, touchy = love.touch.getPosition(id)
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	for id in pairs(instances) do
		local function draw_recursively(arg)
			for k, v in pairs(arg) do
				if type(v) == "table" then
					if debug_draw_collisions and arg[k].collision == true then
						queue.add(debug.drawlist, 1, function()
							collision.debug_draw(arg[k])
						end)
					elseif debug_draw_sprites and arg[k].sprite == true then
						queue.add(debug.drawlist, 2, function()
							sprite.debug_draw(arg[k])
						end)
					-- skip 3d models, they cause a stack overflow
					elseif arg[k].model ~= true then
						draw_recursively(arg[k])
					end
				end
			end
		end
		
		draw_recursively(instances[id])
	end
	
	queue.execute(debug.drawlist)
	
	-- TODO: show same thing for profiling
	if debug_hotswap then
		local h = math.loop(0, 1, 4)
		love.graphics.setColor(color.hsl(h, 1, 0.5))
		love.graphics.printf("HOTSWAP", fonts.proggy_clean, windowwidth-128-4, windowheight-16, 128, "right")
		love.graphics.reset()
	end
	
	
	local i = 0
	for k, v in ripairs(qqueue) do
		i = i + 1
		local text = qqueue[k].text
		local width, wraps = fonts.proggy_clean:getWrap(text, windowwidth - 4)
		
		love.graphics.printf(text, fonts.proggy_clean, 4, windowheight - 4 - ((13  * i)*#wraps), windowwidth - 4)
		if ms - qqueue[k].timestamp > 3 then table.remove(qqueue, k) end
	end
	if #qqueue > 24 then table.remove(qqueue, 1) end
	
	--local angle = (angle or 0) + 0.15
	--b = poly.move(a, angle, angle, ox, oy)
	--b = poly.rotate(a, angle, ox, oy)
	
	--love.graphics.polygon("line", poly.unpack(b))
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(b, mousex-16,mousey, mousex+24,mousey+32))
	
end

--TODO: make this support ... arguments and then just check if they're all strings or something
-- don't print to console if it has a category maybe

-- maybe i should just make a log() function, this doesn't seem like a good idea
--print_ = print
function log(arg)
	debug.table(debug.getinfo(2)) --get name of the function that called this somehow
	--io.write(tostring(arg), newline)
	print(arg)
	-- use kinda sparingly, because this is laggy
	table.insert(qqueue, {text = {{1,1,1,1},tostring(arg)}, timestamp = ms})
end
-- /!\ [AssetLoading] asset.sprite() | asset "name" already loaded!

require("onee/_tests/utils")