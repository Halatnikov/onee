yui = {
	open = {},
	create = {},
}

-- init
local gui
do
	yui_ = require("onee/libs/yui")
	gui = yui_

	if (mobile or not onee.libtype) and debug_mode then yui.open.debug_button = true end
end

-- event redirection
onee.love("keypressed", function(key, scan, isrepeat)
	for k,v in pairs(yui) do
		if type(v) == "table" and v.yui == true then
			v:keypressed(key, scan, isrepeat)
		end
	end
end)
onee.love("keyreleased", function(key, scan)
	for k,v in pairs(yui) do
		if type(v) == "table" and v.yui == true then
			v:keyreleased(key, scan)
		end
	end
end)
onee.love("textinput", function(text)
	for k,v in pairs(yui) do
		if type(v) == "table" and v.yui == true then
			v:textinput(text)
		end
	end
end)
onee.love("textedited", function(text, start, len)
	for k,v in pairs(yui) do
		if type(v) == "table" and v.yui == true then
			v:textedited(text, start, len)
		end
	end
end)

-- main loop
function yui.draw_()
	for k,v in pairs(yui.open) do
		if not yui[k] then yui[k] = yui.create[k]() end
	end
	
	for k,v in pairs(yui) do
		if type(v) == "table" and v.yui == true then
			if yui.open[k] == true then
				v:update(dt)
				v:draw()
				if debug_yui then yui.debug_draw(v) end
			else
				yui[k] = nil
			end
		end
	end
end

function yui.debug_draw(ui)
	function draw_recursive(arg)
		for k,v in ipairs(arg) do
			love.graphics.setColor(1,1,1,0.1)
			local mode = ui.focused == v and "fill" or "line"
			love.graphics.rectangle(mode, math.round(v.x), math.round(v.y), v.w, v.h)
			love.graphics.reset()
			draw_recursive(v)
		end
	end
	draw_recursive(ui)
end

-----------------------------------------------
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
	
	if root then
		root.instance = t
		table.insert(t.stack, gui.Ui:new(root))
	end
	
	return t
end

function yui.add(yui, child)
	assert((yui and yui.yui_instance), "yui.add() | not a valid yui instance!")
	
	child.instance = yui
	table.insert(yui.stack, gui.Ui:new(child))
	
	for i, child in ipairs(yui.stack) do
		child.active = i == #yui.stack and true or false
		child.focused.active = child.focused.active and false or nil
	end
end

function yui.remove(yui)
	assert((yui and yui.yui_instance), "yui.remove() | not a valid yui instance!")
	
	table.remove(yui.stack)
	
	for i, child in ipairs(yui.stack) do
		child.active = i == #yui.stack and true or false
		child.focused.active = child.focused.active and false or nil
	end
end

function yui.update(yui)
	assert((yui and yui.yui_instance), "yui.update() | not a valid yui instance!")
	
	for i, child in ipairs(yui.stack) do
		child:update(dt)
	end
end

local yui_ = yui
function yui.draw(yui, scene)
	assert((yui and yui.yui_instance), "yui.draw() | not a valid yui instance!")
	
	if not scene then
		for i, child in ipairs(yui.stack) do
			child:draw()
			if debug_yui then yui_.debug_draw(child) end
		end
	else
		queue.add(scene.drawlist, yui.z or 1, function()
			for i, child in ipairs(yui.stack) do
				child:draw()
				if debug_yui then yui_.debug_draw(child) end
			end
		end)
	end
end

-----------------------------------------------------------------

-- UIs
function yui.create.debug_button()
	local ui = {
		x = onee.width-20-4, y = 4,
		gui.Rows {
			-- open debug menu
			gui.Button {
				w = 20, h = 20, nofocus = true,
				text = "+",
				onHit = function()
					yui.open.debug = true
					yui.open.debug_button = nil
				end,
			},
		},
	}
	
	return gui.Ui:new(ui)
end

function yui.create.debug()
	local width, height = 192, 20
	local padding = 4
	local ui = {
		x = onee.width-width-padding, y = padding,
		gui.Rows {
			beforeDraw = function(self)
				love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h, 4)
				love.graphics.reset()
			end,
			
			-- close debug menu
			gui.Button {
				w = width, h = height, align = "right",
				text = onee.version.." - ",
				onHit = function(self)
					yui.open.debug_button = true
					yui.open.debug = nil
				end,
			},
			-- fps, raw fps and dt
			gui.Label {
				align = "right",
				text = "",
				onUpdate = function(self)
					self.text = string.format("%d %02.2f FPS %02.2fms", love.timer.getFPS(), fps, 1000*love.timer.getAverageDelta())
				end,
			},
			gui.Columns {
				padding = padding,
				-- reload
				gui.Button {
					w = width/2 - padding/2, h = height,
					text = "Reload",
					onHit = function(self)
						love.event.quit("restart")
					end,
				},
				-- reset scene
				gui.Button {
					text = "Reset scene",
					onHit = function(self)
						scene.set(scenes[1].name)
					end,
				},
			},
			-- draw collisions
			gui.Checkbox {
				checked = debug_draw_collisions,
				text = "Draw collisions",
				onChange = function(self)
					debug_draw_collisions = not debug_draw_collisions
				end,
			},
			-- draw sprite bboxes
			gui.Checkbox {
				checked = debug_draw_sprites,
				text = "Draw sprite BBoxes",
				onChange = function(self)
					debug_draw_sprites = not debug_draw_sprites
				end,
			},
			-- draw yui debui
			gui.Checkbox {
				checked = debug_yui,
				text = "yui debug",
				onChange = function(self)
					debug_yui = not debug_yui
				end,
			},
		},
	}
	
	return gui.Ui:new(ui)
end

_prof.hook("yui")