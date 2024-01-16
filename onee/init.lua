onee = {
	version = "0.0.2-11",
}

---------------------------------------------------------------- INIT

do
	require("conf")
	require("onee/libs/errorhandler")

	-- libraries
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
	print(
		"LOVE2D "..love._version.." (".._VERSION..", "..string.left(jit.version, 13)..") | onee "..onee.version
		..newline..os.date()
	)
	scenes.set("init")
end

-- misc
_VERSION_major, _VERSION_minor = string.match(_VERSION, "Lua (%d+)%.(%d+)")
jit.version_major, jit.version_minor, jit.version_rolling = string.version(string.right(jit.version, -7))
jit.version_revision = string.left(jit.version_rolling, 2)

---------------------------------------------------------------- MAIN LOOP

function onee.update(dt_)
	-- fps limiter start
	before_update = (before_update or 0) + tick
	
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
		
		if scenes then scenes.update() end
		if input then input.update() end
	end
	
	debug.update()
	if imgui then imgui.update() end
	
end

function onee.draw()
	
	if scenes then scenes.draw() end
	if input then input.draw() end
	
	debug.draw()
	if imgui then imgui.draw() end
	if yui then yui.draw() end
	
	-- reset the graphics state constantly
	love.graphics.reset()
	love.graphics.setBackgroundColor(onee.bg[1], onee.bg[2], onee.bg[3])
	
	-- fps limiter end
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end

---------------------------------------------------------------- DEBUG

if debug_mode then
	love.setDeprecationOutput(true)
	
	debug_draw_collisions = true
	debug_draw_sprites = false
	
	-- TODO: set window title to "title (debug)"
	
	-- TODO: init imgui here
	-- TODO: on debug_mode disable, close all the ui
	-- TODO: shortcut ` or f1 to open/close the debug window
	
end

function debug.keypressed(k)
	if not debug_mode then return end
	
	if k == "f2" then love.event.quit("restart") end
	
	if k == "q" or k == "f3" then scenes.set("init") end
end
love.keypressed = debug.keypressed

function debug.update()
	if not debug_mode then return end
end
			a = {{0,0}, {100,10}, {50,100}, {60,30}}
			local ox = 50
			local oy = 50

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
	
	--local angle = (angle or 0) + 0.15
	--b = poly.move(a, angle, angle, ox, oy)
	--b = poly.rotate(a, angle, ox, oy)
	
	--love.graphics.polygon("line", poly.unpack(b))
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(b, mousex-16,mousey, mousex+24,mousey+32))
	
end
