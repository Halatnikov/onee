local menu = {}

local gui = yui_

menu.themes = {
	default = {
		cornerRadius = 0,
		font = fonts.freaks12,
		color = {
			normal = {bg = {0.25, 0.25, 0.25}, fg = {0.75, 0.75, 0.75}},
			hovered = {bg = {0.19, 0.6, 0.73}, fg = {1, 1, 1}},
			active = {bg = {1, 0.6, 0}, fg = {1, 1, 1}},
		}
	},
	
	textonly = {
		cornerRadius = 0,
		font = fonts.freaks12,
		color = {
			normal = {bg = {0,0,0,0}, fg = {1,1,1}},
			hovered = {bg = {0,0,0,0}, fg = {1,1,1}},
			active = {bg = {0,0,0,0}, fg = {1, 0.6, 0}},
		}
	},
	
	disabled = {
		cornerRadius = 0,
		font = fonts.freaks12,
		color = {
			normal = {bg = {0,0,0,0}, fg = {0,0,0}},
			hovered = {bg = {0,0,0,0}, fg = {0,0,0}},
			active = {bg = {0,0,0,0}, fg = {0,0,0}},
		}
	},
}

menu.name = nil
menu.root, menu.ui = nil, nil
menu.x, menu.y = 32, 16
menu.w, menu.h = onee.width-64, 16
menu.padding = 4
menu.theme = menu.themes.textonly

--!
function menu.push(name, params)
	params = params or {}
	
	menu.name = name
	menu.x = params.x or menu.x
	menu.y = params.y or menu.y
	menu.w = params.w or menu.w
	menu.h = params.h or menu.h
	menu.theme = params.theme or menu.theme
	
	yui.open[menu.name] = true
	
	menu.ui = {
		x = menu.x, y = menu.y, theme = menu.theme,
		gui.Rows {
			padding = menu.padding,
			onDraw = function(self)
				local focused = self.ui.focused
				local description = focused.description
				
				if description then
					local font = fonts.freaks16
					local width, wraps = font:getWrap(description, onee.width - 4)
					local height = font:getHeight()
					
					love.graphics.setColor(0, 0, 0, 0.75)
					love.graphics.rectangle("fill", 0, onee.height - (height * #wraps) - 4, onee.width, 64)
					love.graphics.reset()
					love.graphics.printf(text(description), fonts.freaks16, 4, onee.height - (height * #wraps) - 2, onee.width - 4)
				end
			end,
		},
	}
	
	menu.root = menu.ui[1]
end

--!
function menu.pop()
	yui[menu.name] = gui.Ui:new(menu.ui)
	menu.ui = nil
end

--!
function menu.close()
	yui.open[menu.name] = nil
	yui.draw()
end

--!
function menu.label(label, t)
	local item = gui.Label {
		w = menu.w, h = menu.h, align = "left",
		xx = menu.x-8,
		text = label or "",
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
function menu.button(label, description, func, t)
	local item = gui.Button {
		align = "left",
		text = label or "",
		description = description,
		onHit = func or noop,
	}
	
	table.append(item, t or {})
	table.insert(menu.root, item)
end

--!
function menu.disabled(label, description, t)
	return menu.button(label, description, nil, table.append({theme = menu.themes.disabled}, t or {}))
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
				w = menu.w/2/2, h = menu.h, theme = menu.themes.default,
				
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

return menu