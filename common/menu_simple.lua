local menu = {}

local gui = yui_

--!
function menu.start(params, func)	
	menu.themes = {
		default = {
			cornerRadius = 0,
			font = nil,
			spritefont = "font_12",
			color = {
				normal = {bg = {0.25, 0.25, 0.25}, fg = {0.75, 0.75, 0.75}},
				hovered = {bg = {0.19, 0.6, 0.73}, fg = {1, 1, 1}},
				active = {bg = {1, 0.6, 0}, fg = {1, 1, 1}},
			}
		},
		
		textonly = {
			cornerRadius = 0,
			font = nil,
			spritefont = "font_12",
			color = {
				normal = {bg = {0,0,0,0}, fg = {1,1,1}},
				hovered = {bg = {0,0,0,0}, fg = {1,1,1}},
				active = {bg = {0,0,0,0}, fg = {1, 0.6, 0}},
			}
		},
		
		disabled = {
			cornerRadius = 0,
			font = nil,
			spritefont = "font_12",
			color = {
				normal = {bg = {0,0,0,0}, fg = {0,0,0}},
				hovered = {bg = {0,0,0,0}, fg = {0,0,0}},
				active = {bg = {0,0,0,0}, fg = {0,0,0}},
			}
		},
	}
	
	menu.x, menu.y = 32, 16
	menu.w, menu.h = onee.width-64, 16
	menu.padding = 4
	menu.theme = menu.themes.textonly
	
	table.append(menu, params)
	
	menu.ui = {
		x = menu.x, y = menu.y, theme = menu.theme,
		gui.Rows {
			padding = menu.padding,
			
			onDraw = function(self)
				local description = self.ui.focused.description
				
				if description and not (#description == 0) then
					local height = self.spritefont and self.spritefont.height or 0
					
					love.graphics.setColor(0, 0, 0, 0.75)
					love.graphics.rectangle("fill", 0, onee.height - height - 4, onee.width, 64)
					love.graphics.reset()
					self.spritefont = text.printf(description, "font_16", 4, onee.height - 20 - 2, nil, nil, "bottom")
				end
			end,
		},
	}
	
	menu.root = menu.ui[1]
	
	func(menu.root, menu.ui)
	
	return menu.ui
end

--!
function menu.label(label, t)
	local item = gui.Label {
		w = menu.w, h = menu.h, align = "left",
		xx = menu.x-8,
		text = label or "",
		onDraw = function(self)
			love.graphics.setColor(menu.themes.default.color["normal"].fg)
			love.graphics.line(self.x + self.spritefont.width, self.y + (self.h/2), self.x + self.w, self.y + (self.h/2))
			love.graphics.reset()
		end,
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.spacer(size, t)
	local item = gui.Spacer {h = size or menu.h}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.button(label, description, func, enabled, t)
	local item = gui.Button {
		w = menu.w/2, h = menu.h, align = "left",
		text = label or "",
		description = description,
		onHit = func or noop,
	}
	
	if enabled == nil then enabled = true end
	if enabled == false then
		item.theme = menu.themes.disabled
	end
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.checkbox(label, description, var, t)
	local item = gui.Columns {
		description = description,
		
		gui.Label {
			w = menu.w/2, h = menu.h, align = "left", focus = true,
			text = label or "",
		},
		gui.Checkbox {
			theme = menu.themes.default,
			
			checked = var,
			onChange = function(self, checked)
				var = not var
			end,
		},
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.slider(label, description, var, min, max, step, t)
	local item = gui.Columns {
		description = description,
		
		gui.Label {
			w = menu.w/2, h = menu.h, align = "left", focus = true,
			text = label or "",
		},
		gui.Columns {
			padding = 16,
			gui.Slider {
				w = (menu.w/2/2)-8, h = menu.h, theme = menu.themes.default,
				
				min = min, max = max, step = step or 1,
				value = var,

				onChange = function(self, value)
					var = value
					self.parent[2].text = tostring(var)
				end
			},
			gui.Label {
				align = "left",
				text = tostring(var),
			},
		},
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.choice(label, description, var, choices, wrap, t)
	local item = gui.Columns {
		description = description,
		
		gui.Label {
			w = menu.w/2, h = menu.h, align = "left", focus = true,
			text = label or "",
		},
		gui.Choice {
			w = menu.w/3, theme = menu.themes.default,
			choices = choices,
			default = var,
			nowrap = not wrap,

			onChange = function(self, choice) 
				var = choice[2]
			end,
		},
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.textinput(label, description, var, t)
	local item = gui.Columns {
		description = description,
		
		gui.Label {
			w = menu.w/2, h = menu.h, align = "left", focus = true,
			text = label or "",
		},
		gui.Input {
			w = menu.w/3, theme = menu.themes.default,
			
			text = var,

			onChange = function(self, text)
				var = text
			end,
			onHit = function(self, text)
				self.cursor = 1
				self.text = ""
				self:onChange(self.text)
			end,
		},
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.disabled(label, description, t)
	return menu.button(label, description, nil, false, t)
end

--!
function menu.hold(label, description, func, speed, t)
	local item = gui.Button {
		w = menu.w/2, h = menu.h, align = "left",
		text = label or "",
		description = description,
		onHit = func or noop,
		
		hold = 0,
		hold_speed = tick * (speed or 1.25),
		
		-- internal
		hold_blocked = false,
		hold_time = 0,
		
		onPointerInput = function(self) self:grabFocus() end,
		onActionInput = noop,
		
		onUpdate = function(self)
			if self:isFocused() and self.ui.device.confirm or (self.ui.device.clicking and collision.point_rect(self.ui.device.px, self.ui.device.py, self.x, self.y, self.w, self.h)) then
				if not self.hold_blocked then
					self.hold = self.hold + self.hold_speed
				end
			else
				self.hold = 0
				self.hold_blocked = true
			end
			
			if self.hold >= 1 then
				self.hold = 0
				self.hold_blocked = true
				
				if not self.active then
					self.active = true
					self:onHit()

					self.ui.timer:after(0.15, function() self.active = false end)
				end
			end
			
			-- prevent excess inputs
			if self.ui.device.confirm or self.ui.device.clicking then
				if self.hold_time < 1 then self.hold_blocked = false end
				self.hold_time = self.hold_time + 1
			else
				self.hold_time = 0
			end
		end,

		beforeDraw = function(self)
			love.graphics.setColor(rgb(self.ui.theme.color["active"].fg, 0.75))
			love.graphics.rectangle("fill", self.x, self.y, self.hold / 1 * self.w, self.h)
			love.graphics.reset()
		end,
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

return menu