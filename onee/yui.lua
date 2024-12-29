yui = {}
yui_ = require("onee/libs/yui")
local gui = yui_

--!
function yui.new(root, data)
	local t = {
		yui_instance = true,
		stack = {},
	}
	
	t.keypressed = function(key, scan, isrepeat)
		for i, child in ipairs(t.stack) do
			child:keypressed(key, scan, isrepeat)
		end
	end
	t.keyreleased = function(key, scan)
		for i, child in ipairs(t.stack) do
			child:keyreleased(key, scan)
		end
	end
	t.textinput = function(text)
		for i, child in ipairs(t.stack) do
			child:textinput(text)
		end
	end
	t.textedited = function(text, start, len)
		for i, child in ipairs(t.stack) do
			child:textedited(text, start, len)
		end
	end
	
	onee.love("keypressed", t.keypressed)
	onee.love("keyreleased", t.keyreleased)
	onee.love("textinput", t.textinput)
	onee.love("textedited", t.textedited)
	
	table.append(t, data) -- additional data
	if root then yui.add(t, root) end
	
	return t
end

local function refresh_stack(stack)
	for i, child in ipairs(stack) do
		child.active = false
		child:onActive(false)
		child.focused.active = child.focused.active and false or nil
	end
	
	stack[#stack]:onActive(true)
	stack[#stack].timer:after(0.1, function() stack[#stack].active = true end)
end

--!
function yui.add(yui, child)
	assert((yui and yui.yui_instance), "yui.add() | not a valid yui instance!")
	
	child.instance = yui
	child.previous = yui.stack[#yui.stack]
	child.onActive = child.onActive or noop
	table.insert(yui.stack, child.yui and child or gui.Ui:new(child))
	refresh_stack(yui.stack)
end

--!
function yui.remove(yui)
	assert((yui and yui.yui_instance), "yui.remove() | not a valid yui instance!")
	
	table.remove(yui.stack)
	refresh_stack(yui.stack)
end

local yui_ = yui
--!
function yui.readd(yui)
	assert((yui and yui.yui_instance), "yui.readd() | not a valid yui instance!")
	
	local topmost = yui.stack[#yui.stack] -- store it here
	yui_.remove(yui)
	yui_.add(yui, topmost)
end

--!
function yui.update(yui)
	assert((yui and yui.yui_instance), "yui.update() | not a valid yui instance!")
	
	for i, child in ipairs(yui.stack) do
		child:update(dt)
	end
end

--!
function yui.draw(yui, scene)
	assert((yui and yui.yui_instance), "yui.draw() | not a valid yui instance!")
	
	if scene then
		queue.add(scene.drawlist, yui.z or 1, function()
			for i, child in ipairs(yui.stack) do
				child:draw()
				if debug_yui then yui_.debug_draw(child) end
			end
		end)
	else
		for i, child in ipairs(yui.stack) do
			child:draw()
			if debug_yui then yui_.debug_draw(child) end
		end
	end
end

--!
function yui.debug_draw(ui)
	local function draw_recursive(arg)
		for k,v in ipairs(arg) do
			love.graphics.setColor(1,1,1,0.1)
			local mode = ui.focused == v and "fill" or "line"
			love.graphics.rectangle(mode, math.floor(v.x), math.floor(v.y), v.w, v.h)
			love.graphics.reset()
			draw_recursive(v)
		end
	end
	draw_recursive(ui)
end

-- additional UIs
if debug_mode then
	require("onee/debug/yui/debug_menu") -- mobile debug button
end

_prof.hook("yui")
