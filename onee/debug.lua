function debug.enable(enabled)
	debug_mode = enabled
	if enabled then
		
		-- libraries (debug)
		require("onee/libs/lurker")
		require("onee/libs/profi")
		require("onee/libs/df-serialize")
		
		-- gui (debug)
		require("onee/imgui")
		
		love.setDeprecationOutput(true)
		love.window.setTitle(love.config.window.title.." (debug)")
		
		debug_draw_collisions = true
		debug_draw_sprites = false
		debug_hotswap = true
		debug.profiler_enable(false)
		debug.profiler_deep_enable(false)
		
		lurker.interval = 1
		
		_prof.hook("debug")
		_prof.hook("lurker") 
		_prof.hook("queue")
		--_prof.hook("love.graphics.draw()")
		
		-- TODO: functions on disabling/reenabling debug mode, maybe unrequire lurker completely
		-- TODO: init imgui here
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
		
	else
		
		love.window.setTitle(love.config.window.title)
		
		_prof.hook = noop
		
		debug_draw_collisions = false
		debug_draw_sprites = false
		debug_hotswap = false
		debug.profiler_enable(false)
		debug.profiler_deep_enable(false)
		
		yui.open.debug = nil
		yui.open.debug_button = nil
		
	end
end

function debug.profiler_enable(enabled)
	debug_profiler = enabled
	if enabled then
		_prof.enable(true)
	else
		_prof.enable(false)
		debug.profiler_deep_enable(false)
	end
end

function debug.profiler_deep_enable(enabled)
	debug_profiler_deep = enabled
	if enabled then
		profi:reset()
		profi:setGetTimeMethod(love.timer.getTime)
		jit.off()
		jit.flush()
		profi:start()
	elseif profi and profi.has_started then
		jit.on()
		profi:stop()
		collectgarbage()
	end
end

----------------------------------------------------------------

function debug.update()
	if not debug_mode then return end
	
	if debug_hotswap then lurker.update() end
	
	imgui.update()
end

a = {{0,0}, {100,10}, {50,100}, {60,30}}
local ox = 50
local oy = 50

qqueue = {}
function debug.draw()
	if not debug_mode then return end
	
	if mobile then
		local touches = love.touch.getTouches()
		for i=1, #touches do
			local touchx, touchy = love.touch.getPosition(touches[i])
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	debug.drawlist = {}
	for id, scene in kpairs(scenes) do
		for id, instance in pairs(scene.instances) do
			local function draw_recursively(arg)
				for k, v in pairs(arg) do
					if type(v) == "table" then
						if debug_draw_collisions and v.collision == true then
							queue.add(debug.drawlist, 1, function()
								collision.debug_draw(v)
							end)
						elseif debug_draw_sprites and v.sprite == true then
							queue.add(debug.drawlist, 2, function()
								sprite.debug_draw(v, scene)
							end)
						-- skip 3d models, they cause a stack overflow
						elseif v.model ~= true then
							draw_recursively(v)
						end
					end
				end
			end
			
			draw_recursively(instance)
		end
	end
	queue.execute(debug.drawlist)
	
	imgui.draw()
	
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
		v.timestamp = v.timestamp or 0
		
		love.graphics.print(v.text, fonts.proggy_clean, 4, windowheight - 4 - ((13  * i)))
		if ms - v.timestamp > 3 then table.remove(qqueue, k) end
	end
	if #qqueue > 24 then table.remove(qqueue, 1) end
	
	--local angle = (angle or 0) + 0.15
	--b = poly.move(a, angle, angle, ox, oy)
	--b = poly.rotate(a, angle, ox, oy)
	
	--love.graphics.polygon("line", poly.unpack(b))
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(b, mousex-16,mousey, mousex+24,mousey+32))
	
end

----------------------------------------------------------------

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

----------------------------------------------------------------

function debug.test(arg)
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
	dofile("onee/_tests/"..arg, env)
	
	-- test finished
	local success, summary, passes, errors = lust.success, lust.summary, lust.passes, lust.errors
	local took = math.round(love.timer.getTime() - time_start, 5)
	
	if success then log("TEST PASSED")
	else log("TEST FAILED")
	end
	log("PASSES: "..passes..", ERRORS: "..errors..", TOOK: "..took)
	
	unrequire("onee/libs/lust")
	
	return success, summary, passes, errors, took
end

----------------------------------------------------------------

_prof = {
	enabled = false,
	data = {},
	hooks = {},
	level = 1,
	start = 0,
	stop = 0,
	ram = 0,
}

local function push(name, data)
	_prof.level = _prof.level + 1
	
	local parent
	for k,v in ripairs(_prof.data) do
		if v.level == _prof.level - 1 then
			parent = v.id
			break
		end
	end
	
	local ram = collectgarbage("count")
	local event = {
		type = "event",
		id = #_prof.data + 1,
		parent = parent,
		level = _prof.level,
		name = name,
		data = data,
		start = love.timer.getTime(),
		ramstart = ram - _prof.ram,
	}
	
	table.insert(_prof.data, event)
	_prof.ram = _prof.ram + (collectgarbage("count") - ram)
end

local function mark(name, data)
	_prof.level = _prof.level + 1
	
	local parent
	for k,v in ripairs(_prof.data) do
		if v.level == _prof.level - 1 then
			parent = v.id
			break
		end
	end
	
	local mark = {
		type = "mark",
		id = #_prof.data + 1,
		parent = parent,
		level = _prof.level,
		name = name,
		data = data,
		start = love.timer.getTime(),
	}
	
	table.insert(_prof.data, mark)
	
	_prof.level = _prof.level - 1 
end

local function pop(name)
	local previous
	for k,v in ripairs(_prof.data) do
		if v.level == _prof.level then
			if not name then
				previous = v
				break
			elseif name and v.name == name then
				previous = v
				break
			end
		end
	end
	
	local ram = collectgarbage("count")
	if previous then 
		previous.stop = love.timer.getTime()
		previous.ramstop = ram - _prof.ram
	end
	
	_prof.ram = _prof.ram + (collectgarbage("count") - ram)
	_prof.level = _prof.level - 1
end

local function wrap(t, key, name)
	local func = t[key]
	
	local function pop(...)
		_prof.pop()
		return ...
	end
		
	t[key] = function(...)
		if not _prof.enabled then return func(...) end
		_prof.push(name)
		return pop(func(...))
	end
end

function _prof.hook(path, name)
	if debug_hotswap and lurker.swappedonce then return end
	name = name or tostring(path)
	
	local root
	--if #path == 1 then root = _G
	--elseif name == "_G" then root = _G; name = "" 
	if type(path) == "table" then root = path
	else
		path = string.tokenize(path, ".")
		root = _G[path[1]] and _G[path[1]]
		root = root[path[2]] and root[path[2]] or root
	end
	
	
	if type(path) == "string" and string.right(path[#path],2) == "()" then
		wrap(root, string.remove(path[#path],"()"), string.remove(name,"()"))
	else
		local path = {name}
		local function recursive(arg)
			for k,v in pairs(arg) do
				if type(v) == "table" and v ~= package.loaded then
					table.insert(path, k)
					if #path > 4 then break end
					name = table.concat(path, ".")
					recursive(v)
					table.remove(path, 2)
				elseif type(v) == "function" then
					name = table.concat(path, ".")
					wrap(arg, k, name.."."..k)
				end
			end
		end
		recursive(root)
	end
end

function _prof.enable(enabled)
	_prof.enabled = enabled
	if enabled then
		_prof.data = {}
		_prof.data_pretty = {}
		
		_prof.start = love.timer.getTime()
		_prof.stop = 0
		_prof.level = 1
		_prof.ram = 0
		
		_prof.push = push
		_prof.pop = pop
		_prof.mark = mark
	else
		_prof.push = noop
		_prof.pop = noop
		_prof.mark = noop
		
		_prof.stop = love.timer.getTime()
		
		_prof.data_pretty = table.unflatten(_prof.data)
	end
	collectgarbage()
end

text = love.filesystem.read("onee/debug.lua")
text = string.tokenize(text, newline)
for i=1, #text do text[i] = string.trim(text[i]) end

docs = {}

local function tag(arg)
	local t = {}
	if string.left(arg, 1) == "@" then
		local split = string.tokenize(arg, " ")
		t.tag = string.right(split[1], -1)
		table.remove(split, 1)
		
		if t.tag == "function" then
			local has_local = split[#split] == "(local)"
			if has_local then 
				t.localfunc = true
				table.remove(split, #split)
			end
			
			t.name = split[1]
			table.remove(split, 1)
		end
		
		if t.tag == "param" then
			local has_type = (string.left(split[1],1) == "(" and string.right(split[1],1) == ")")
			if has_type then 
				split[1] = string.mid(split[1], 2, #split[1]-1)
				local type = string.tokenize(split[1], "=")
				
				t.type = type[1]
				if type[2] then
					t.optional = true
					t.default = #type[2] ~= 0 and type[2] or nil
				end
				
				table.remove(split, 1)
			end
			
			t.name = split[1]
			table.remove(split, 1)
			
			if split[1] == "-" then table.remove(split, 1) end
		end
		
		if t.tag == "returns" then
			local has_type = (string.left(split[1],1) == "(" and string.right(split[1],1) == ")")
			if has_type then 
				t.type = string.mid(split[1], 2, #split[1]-1)
				table.remove(split, 1)
			end
		end
		
		t.text = table.concat(split, " ")
	end
	return t
end

for i=1, #text do
	if string.left(text[i],3) == "---" and string.mid(text[i],4,4) ~= "-" then 
		local parent = {}
		parent.text = string.trim(string.remove(text[i], "---"))
		table.append(parent, tag(parent.text))
		
		for i = i+1, #text do
			if string.left(text[i],2) ~= "--" then break end
			parent.children = parent.children or {}
			
			local child = {}
			child.text = string.trim(string.remove(text[i], "--"))
			table.append(child, tag(child.text))
			
			if child.tag and #child.text == 0 then child.text = nil end
			if (child.text or child.tag) then table.insert(parent.children, child) end
		end
		
		if #parent.text == 0 then parent.text = nil end
		if (parent.tag or parent.children) then table.insert(docs, parent) end
	end
end

--- @function _prof.hook
-- @param path
-- @param name

--- @function push (local)
-- do the mario
--
-- @param (string) name
-- @param (table={}) data - optional table
-- @returns (an) donkey kong country
