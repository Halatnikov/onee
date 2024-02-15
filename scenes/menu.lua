local scene_ = scene
local scene = {}

local gui = yui_

local menu = {}
menu.name = "test"
menu.root = {}

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

local x,y = 32, 16
local width, height = onee.width-32-32, 16
local padding = 4
local theme = menu.themes.textonly

local bool = true
local num = 5
local str = "You"
local textinput = "i'm freaks"

function scene.init(self)
	asset.sprite("spr_menu_arrow_16", self)
	asset.sprite("checkerboard", self)
	
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16", {x = 16})
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height}, scale = 8, z = -1})
	
	yui.open[menu.name] = true
	
	local ui = {
		x = x, y = y, theme = theme,
		gui.Rows {
			padding = padding,
			onDraw = function(self)
				local focused = self.ui.focused
				
				local description = focused.description or ""
				local font = fonts.freaks16
				local width, wraps = font:getWrap(description, onee.width - 4)
				local height = font:getHeight()
				
				love.graphics.setColor(0, 0, 0, 0.75)
				love.graphics.rectangle("fill", 0, onee.height - (height * #wraps) - 4, onee.width, 64)
				love.graphics.reset()
				love.graphics.printf(text(description), fonts.freaks16, 4, onee.height - (height * #wraps) - 2, onee.width - 4)
			end,
		},
	}
	menu.root = ui[1]
	
	menu.label("Scenes")
		
	local scenes = files.listdir("scenes")
	for i=1, #scenes do
		local name = string.remove(scenes[i], "scenes/", ".lua")
		
		menu.button(name, nil, function(self)
			scene_.set(name)
		end)
	end
	
	menu.spacer()
	
	menu.label("{unknown}Thingies")
	
	menu.button("{input_a}Button {k_escape}", "that is a button", function(self)
		print("yes indeed")
	end)
	
	menu.checkbox("Checkbox", "description Checkbox wOw", bool)
	
	menu.slider("Slider", nil, num, 0, 10, 1)
	
	table.insert(menu.root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left", focus = true,
			text = "Multi-choice",
		},
		gui.Choice {
			w = width/2/2, theme = menu.themes.default,
			choices = {
				{ text = "Have", value = "have" },
				{ text = "Yo{null}u", value = "you" },
				{ text = "Ever",  value = "ever" }
			},
			default = str,
			nowrap = true,

			onChange = function(self, choice) 
				str = choice.value
			end,
		},
	})
	
	menu.textinput("Text input", "aaaaaaaaaaaaaaaaaaaa", textinput)
	
	menu.disabled("Disabled")
	
	table.insert(menu.root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left", focus = true,
			text = "Toggle",
			description = "a custom entry for demonstration",
		},
		gui.Button {
			align = "left",
			text = bool and "The" or "When",
			description = "a custom entry for demonstration",
			onHit = function(self)
				bool = not bool
				self.text = bool and "The" or "When"
			end,
		},
	})
	
	menu.spacer()
	
	menu.button("the", "an an")
	
	menu.button("Quit", "When you die in the game,"..newline.."you die in real life", function(self)
		love.event.quit()
	end)
	
	yui[menu.name] = gui.Ui:new(ui)
end

function scene.delete(self)
	yui.open[menu.name] = nil
	yui.draw()
end

function menu.label(label, t)
	local item = gui.Label {
		w = width, h = height, align = "left",
		xx = x-8,
		text = label or "",
	}
	table.append(item, t or {})
	table.insert(menu.root, item)
end

function menu.spacer(size, t)
	local item = gui.Spacer {h = size or height}
	table.append(item, t or {})
	table.insert(menu.root, item)
end

function menu.button(label, description, func, t)
	local item = gui.Button {
		align = "left",
		text = label or "",
		description = description or "",
		onHit = func or noop,
	}
	table.append(item, t or {})
	table.insert(menu.root, item)
end

function menu.disabled(label, description, t)
	return menu.button(label, description, nil, table.append({theme = menu.themes.disabled}, t or {}))
end

function menu.checkbox(label, description, var, t)
	local item = gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left", focus = true,
			text = label or "",
			description = description or "",
		},
		gui.Checkbox {
			theme = menu.themes.default,
			description = description or "",
			
			checked = var,
			onChange = function(self, checked)
				var = not var
			end,
		},
	}
	table.append(item, t or {})
	table.insert(menu.root, item)
end

function menu.slider(label, description, var, min, max, step, t)
	local item = gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left", focus = true,
			text = label or "",
			description = description or "",
		},
		gui.Columns {
			padding = 16,
			gui.Slider {
				w = width/2/2, h = height, theme = menu.themes.default,
				description = description or "",
				
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

function menu.textinput(label, description, var, t)
	local item = gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left", focus = true,
			text = label or "",
			description = description or "",
		},
		gui.Input {
			w = width/2/2, theme = menu.themes.default,
			description = description or "",
			
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

function scene.update(self)
	sprite.update(self.arrow, self)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	local item = yui[menu.name].focused
	
	queue.add(self.drawlist, 0, function()
		gradient("horizontal", {
			{0, 1, 1, 0.5},
			{0, 1, 1, 0.125},
			{0, 0, 0, 0},
		}, 0, item.y - 2, 0, onee.width, item.h + 4)
	end)
	
	self.arrow.y = item.y + 8
	sprite.draw(self.arrow, self)
end

return scene
