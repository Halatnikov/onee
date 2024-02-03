if debug_mode then
	love.setDeprecationOutput(true)
	love.window.setTitle(love.config.window.title.." (debug)")
	
	debug_draw_collisions = true
	debug_draw_sprites = false
	debug_hotswap = true
	debug_profiler = false
	debug_profiler_deep = false
	
	lurker.interval = 1
	
	-- TODO: functions on disabling/reenabling debug mode, maybe unrequire lurker completely
	-- TODO: init imgui here
	-- TODO: on debug_mode disable, close all the ui
	-- TODO: shortcut ` or f1 to open/close the debug window
	
	-- monitor global variables :eyes:
	debug.globals = {}
	setmetatable(_G, {
		__newindex = function (t, k, v)
			table.insert(debug.globals, k)
			if v == nil then table.remove(debug.globals, table.find(k)) end
			rawset(t, k, v)
		end
	})
	
end

function debug.update()
	if not debug_mode then debug.enable(false) return end
	
	if debug_hotswap then lurker.update() end
	if debug_profiler_deep then profi:checkMemory(0.1) end
end

function debug.enable(enabled)
	debug_mode = enabled
	if enabled then
	
	else
		love.window.setTitle(love.config.window.title)
	end
end

function debug.profiler_enable(enabled)
	debug_profiler = enabled
	if enabled then
		table.clear(_prof.profdata)
		_prof.enabled(true)
	else
		_prof.popAll()
		_prof.write("jprof.mpack")
		_prof.enabled(false)
		
		debug.profiler_deep_enable(false)
		collectgarbage()
	end
end

function debug.profiler_deep_enable(enabled)
	debug_profiler_deep = enabled
	if enabled then
		profi:reset()
		profi:setGetTimeMethod(love.timer.getTime)
		profi:start()
	else
		profi:stop()
		profi:writeReport("ProFi.txt")
		collectgarbage()
	end
end

a = {{0,0}, {100,10}, {50,100}, {60,30}}
local ox = 50
local oy = 50

qqueue = {}
function debug.draw()
	if not debug_mode then return end
	
	if mobile then
		for i,id in ipairs(love.touch.getTouches()) do
			local touchx, touchy = love.touch.getPosition(id)
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	debug.drawlist = {}
	for id in kpairs(scenes) do
		local scene = scenes[id]
		for id in pairs(scene.instances) do
			local function draw_recursively(arg)
				for k, v in pairs(arg) do
					if type(v) == "table" then
						if debug_draw_collisions and arg[k].collision == true then
							queue.add(debug.drawlist, 1, function()
								collision.debug_draw(arg[k])
							end)
						elseif debug_draw_sprites and arg[k].sprite == true then
							queue.add(debug.drawlist, 2, function()
								sprite.debug_draw(arg[k], scene)
							end)
						-- skip 3d models, they cause a stack overflow
						elseif arg[k].model ~= true then
							draw_recursively(arg[k])
						end
					end
				end
			end
			
			draw_recursively(scene.instances[id])
		end
	end
	queue.execute(debug.drawlist)
	
	local h = math.loop(0, 1, 4)
	love.graphics.setColor(color.hsl(h, 1, 0.5))
	if debug_hotswap then
		love.graphics.printf("HOTSWAP", fonts.proggy_clean, windowwidth-128-4, windowheight-(16 + 13*0), 128, "right")
		--love.graphics.printf(math.loop(3, 2, -2), fonts.proggy_clean, windowwidth-128-4, windowheight-(16 + 13*1), 128, "right")
	end
	if debug_profiler or debug_profiler_deep then
		local text = debug_profiler_deep and "DEEP PROFILING" or "PROFILING"
		love.graphics.printf(text, fonts.proggy_clean, windowwidth-128-4, windowheight-(16 + 13*1), 128, "right")
	end
	love.graphics.reset()
	
	
	local i = 0
	for k, v in ripairs(qqueue) do
		i = i + 1
		local timestamp = qqueue[k].timestamp or 0
		local text = qqueue[k].text
		local width, wraps = fonts.proggy_clean:getWrap(text, windowwidth - 4)
		
		love.graphics.printf(text, fonts.proggy_clean, 4, windowheight - 4 - ((13  * i)*#wraps), windowwidth - 4)
		if ms - timestamp > 3 then table.remove(qqueue, k) end
	end
	if #qqueue > 24 then table.remove(qqueue, 1) end
	
	--local angle = (angle or 0) + 0.15
	--b = poly.move(a, angle, angle, ox, oy)
	--b = poly.rotate(a, angle, ox, oy)
	
	--love.graphics.polygon("line", poly.unpack(b))
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(b, mousex-16,mousey, mousex+24,mousey+32))
	
end

function debug.keypressed(k, scancode, isrepeat)
	if not debug_mode then return end
	--press l to learn
	
	if k == "f2" then love.event.quit("restart") end
	
	if k == "q" or k == "f3" then scene.set("init") end
	 
	if k == "f" then log((#qqueue+1).." HOLY SHIT "..string.random(10).." Testing testing Test Test 2 3 4 omg my god "..ms) end
	if k == "g" then log(string.random(150)) end
end
love.keypressed = debug.keypressed

function debug.table(arg, mode, indent)
	print(serialize.pack(arg, indent or 1, mode or "lax"))
end

function debug.test(arg)
	debug_testing = true
	local path = "onee/_tests/"..arg..".lua"
	
	-- set up the test environment
	local env = {}
	env = copy(_G) -- add globals, techically isolated for that test only?
	
	local lust = require("onee/libs/lust")
	
	env.describe, env.it, env.expect = lust.describe, lust.it, lust.expect
	env.before, env.after = lust.before, lust.after
	env.spy = lust.spy

	env.group, env.test, env.assert = env.describe, env.it, env.expect
	
	-- set up custom functions
	
	-- force fail test
	function lust.fail(msg)
		msg = msg or ""
		error("Forcefully failed"..newline..lust.indent(lust.level+1).."AT: "..msg, 2)
	end
	env.fail = lust.fail
	
	-- mock random
	env.math.random = math.randomfake
	
	-- set up custom assertions
	local paths = lust.paths
	
	-- assert().pass()
	paths.pass = {test = paths.truthy.test}
	table.insert(paths[""], "pass")
	table.insert(paths.to, "pass")
	table.insert(paths.to_not, "pass")

	-- assert().deny()
	paths.deny = {test = function(v, msg)
		return v == false or v == nil,
		'expected ' .. tostring(v) .. ' to be falsy',
		'expected ' .. tostring(v) .. ' to not be falsy',
		msg
	end}
	table.insert(paths[""], "deny")
	table.insert(paths.to, "deny")
	table.insert(paths.to_not, "deny")

	-- assert().error()
	paths.error = {test = paths.fail.test}
	table.insert(paths[""], "error")
	table.insert(paths.to, "error")
	table.insert(paths.to_not, "error")

	-- assert().success()
	paths.success = {test = function(f, msg)
		return pcall(f),
		"expected "..tostring(f).." to succeed",
		"expected "..tostring(f).." to not succeed",
		msg
	end}
	table.insert(paths[""], "success")

	-- assert().type()
	paths.type = {test = function(v, x, msg)
		return type(v) == x,
		"expected "..tostring(v).." to be a "..x,
		"expected "..tostring(v).." to not be a "..x,
		msg
	end}
	table.insert(paths[""], "type")
	table.insert(paths.be, "type")

	--assert().exist()
	paths.exist = {test = paths.exist.test}
	table.insert(paths[""], "exist")
	
	env.paths = paths
	
	-- run test
	local time_start = love.timer.getTime()
	log("RUNNING TEST \""..arg.."\"")
	dofile(path, env)
	
	-- test finished
	local success, summary, passes, errors = lust.success, lust.summary, lust.passes, lust.errors
	local took = math.round(love.timer.getTime() - time_start, 5)
	
	if success then log("TEST PASSED")
	else log("TEST FAILED")
	end
	log("PASSES: "..passes..", ERRORS: "..errors..", TOOK: "..took)
	
	unrequire("onee/libs/lust")
	debug_testing = nil
	
	return success, summary, passes, errors, took
end
