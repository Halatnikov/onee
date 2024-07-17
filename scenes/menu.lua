local scene_ = scene
local scene = {}

local menu = dofile("common/menu_simple")

local bool = true
local num = 5
local str = "You"
local textinput = "i'm freaks"

function scene.init(self)
	input.touch_active = false
	
	asset.sprite("spr_menu_arrow_16", self)
	asset.sprite("checkerboard", self)
	
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16", {x = 16})
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height}, scale = 8, z = -1})
	
	menu.push("test")
	
	menu.root.beforeDraw = function()
		local focused = yui[menu.name].focused
		
		gradient("horizontal", {
			{0, 1, 1, 0.5},
			{0, 1, 1, 0.125},
			{0, 0, 0, 0},
		}, 0, focused.y - 2, 0, onee.width, focused.h + 4)
	
		self.arrow.y = focused.y + 8
		sprite.draw(self.arrow, self, {queued = false})
	end
	
	menu.label("Scenes")
		
	local scenes = files.listdir("scenes")
	for i=1, #scenes do
		local name = string.remove(scenes[i], "scenes/", ".lua")
		
		menu.button(name, nil, function(self)
			scene_.set(name)
		end)
	end
	
	menu.label("Thingies")
	
	menu.button("Button", "that is a button", function(self) log("yes indeed") end)
	
	menu.checkbox("Checkbox", "description Checkbox wOw", bool)
	
	menu.slider("Slider", "", num, 0, 10, 1)
	
	menu.choice("Multi-choice", "", str, {{"Have", "have"}, {"You", "you"}, {"Ever", "ever"}}, false)
	
	menu.textinput("Text input", "aaaaaaaaaaaaaaaaaaaa", textinput)
	
	menu.button("Disabled", "", nil, false)
	
	menu.hold("Hold button", "a", function(self) log("THE") end)
	
	menu.spacer()
	
	local gui = yui_
	table.insert(menu.root, gui.Columns {
		description = "a custom entry for demonstration",
		
		gui.Label {
			w = menu.w/2, h = menu.h, align = "left", focus = true,
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
	
	menu.hold("Quit", "When you die in the game,"..newline.."you die in real life", function(self)
		love.event.quit()
	end)
	
	menu.pop()
end

function scene.delete(self)
	menu.close()
	input.touch_active = true
end

function scene.update(self)
	sprite.update(self.arrow, self)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	queue.add(self.drawlist, 2, function()
		text.print({"TEST", "{input_right}"}, "font_titlecard", 100, 10)
		
		text.printf({
			"privet ", {{255,127,237},"ayleen, "}, {{127,255,255},"colored text"},
			newline, "new line... ", {"shake", "shaking text  "}, {{"shake", strengthx = 5}, "REALLY shaking"},
			newline, {{"shake", {0,255,0}}, "combining effects "},
			"{input_a}", "displaying ", "{unknown}", "icons ", "{key_return}", "{invalid}",
			newline, {"wave", "wavy text"},
			newline, {{"rainbow", size = 3}, "rainbow text"},
		}, "font_12", 100, 40, nil, "center")
	end)
end

return scene
