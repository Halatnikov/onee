local scene_ = scene
local scene = {}

local gui = yui_

function scene.init(self)
	asset.sprite("spr_menu_arrow_16", self)
	asset.sprite("checkerboard", self)
	
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16")
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height}, scale = 8, z = -1})
	
	yui.open.test = true
end

function scene.close(self)
	yui.open.test = nil
	yui.draw()
end

local theme_default = {
    cornerRadius = 0,
	font = nil,
    color = {
        normal = {bg = {0.25, 0.25, 0.25}, fg = {0.75, 0.75, 0.75}},
        hovered = {bg = {0.19, 0.6, 0.73}, fg = {1, 1, 1}},
        active = {bg = {1, 0.6, 0}, fg = {1, 1, 1}},
    }
}
local theme_textonly = {
	cornerRadius = 0,
	font = nil,
	color = {
		normal = {bg = {0,0,0,0}, fg = {1,1,1}},
		hovered = {bg = {0,0,0,0}, fg = {1,1,1}},
		active = {bg = {0,0,0,0}, fg = {1, 0.6, 0}},
	}
}
local theme_disabled = {
	cornerRadius = 0,
	font = nil,
	color = {
		normal = {bg = {0,0,0,0}, fg = {0,0,0}},
		hovered = {bg = {0,0,0,0}, fg = {0,0,0}},
		active = {bg = {0,0,0,0}, fg = {0,0,0}},
	}
}

local bool = true
local num = 5
local str = "you"
local textinput = "i'm freaks"

function yui.new.test()
	local x,y = 32, 16
	local width, height = onee.width-32, 16
	local padding = 4
	local theme = textonly
	
	local ui = {
		x = x, y = y, theme = theme_textonly,
		gui.Rows {
			padding = padding,
		},
	}
	
	local root = ui[1]
	
	table.insert(root, gui.Label {
		w = width, h = height, align = "left",
		xx = x-8,
		text = "Scenes",
	})
	
	local scenes = files.listdir("scenes")
	for i=1, #scenes do
		local name = string.remove(scenes[i], "scenes/", ".lua")
		table.insert(root, gui.Button {
			align = "left",
			text = name,
			onHit = function(self)
				scene_.set(name)
			end,
		})
	end
	
	table.insert(root, gui.Spacer {h = height})
	
	table.insert(root, gui.Label {
		align = "left",
		xx = x-8,
		text = "Thingies",
	})
	
	table.insert(root, gui.Button {
		align = "left",
		text = "Button",
		onHit = function(self)
			
		end,
	})
	
	table.insert(root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left",
			text = "Checkbox",
		},
		gui.Checkbox {
			theme = theme_default,
			checked = bool,
			onChange = function(self, checked)
				bool = not bool
			end,
		},
	})
	
	table.insert(root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left",
			text = "Slider",
		},
		gui.Columns {
			padding = 16,
			gui.Slider {
				w = width/2/2, h = height, theme = theme_default,
				min = 0, max = 10, step = 1,
				value = num,

				onChange = function(self, value)
					num = value
					self.parent[2].text = tostring(num)
				end
			},
			gui.Label {
				align = "left",
				text = tostring(num),
			},
		},
	})
	
	table.insert(root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left",
			text = "Multi-choice",
		},
		gui.Choice {
			w = width/2/2, theme = theme_default,
			choices = {
				{ text = "Have", value = "have" },
				{ text = "You", value = "you" },
				{ text = "Ever",  value = "ever" }
			},
			default = str,
			nowrap = true,

			onChange = function(self, choice) 
				str = choice.value
			end,
		},
	})
	
	table.insert(root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left",
			text = "Text input",
		},
		gui.Input {
			w = width/2/2, theme = theme_default,
			text = textinput,

			onChange = function(self, text)
				textinput = text
			end,
			onHit = function(self, text)
				self.cursor = 1
				self.text = ""
			end,
		},
	})
	
	table.insert(root, gui.Columns {
		gui.Label {
			w = width/2, h = height, align = "left",
			text = "Toggle",
		},
		gui.Button {
			align = "left",
			text = bool and "The" or "When",
			onHit = function(self)
				bool = not bool
				self.text = bool and "The" or "When"
			end,
		},
	})
	
	table.insert(root, gui.Button {
		align = "left", theme = theme_disabled,
		text = "Disabled",
		onHit = function(self)
			
		end,
	})
	
	table.insert(root, gui.Spacer {h = height})
	
	table.insert(root, gui.Button {
		align = "left",
		text = "the",
		onHit = function(self)
			
		end,
	})
	
	table.insert(root, gui.Button {
		align = "left",
		text = "Quit",
		onHit = function(self)
			love.event.quit()
		end,
	})
	
	return gui.Ui:new(ui)
end

function scene.update(self)
	sprite.update(self.arrow, self)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	if yui.test then
		local item = yui.test.focused
		
		queue.add(self.drawlist, 0, function()
			gradient("horizontal", {
				{0, 1, 1, 0.5},
				{0, 1, 1, 0.125},
				{0, 0, 0, 0},
			}, 0, item.y-2, 0, onee.width, item.h+4)
		end)
		
		self.arrow.x = 16
		self.arrow.y = item.y+8
		sprite.draw(self.arrow, self)
	end
end

return scene
