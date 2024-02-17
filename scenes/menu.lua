local scene_ = scene
local scene = {}

local gui = yui_

local menu = dofile("common/menu_simple")

local bool = true
local num = 5
local str = "You"
local textinput = "i'm freaks"

function scene.init(self)
	asset.sprite("spr_menu_arrow_16", self)
	asset.sprite("checkerboard", self)
	
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16", {x = 16})
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height}, scale = 8, z = -1})
	
	menu.push("test")
	
	menu.label("Scenes")
		
	local scenes = files.listdir("scenes")
	for i=1, #scenes do
		local name = string.remove(scenes[i], "scenes/", ".lua")
		
		menu.button(name, nil, function(self)
			scene_.set(name)
		end)
	end
	
	menu.spacer()
	
	menu.label("{unknown}{key_pause}Thingies")
	
	menu.button("{input_a}Button{unknown}", "that is a button", function(self)
		print("yes indeed")
	end)
	
	menu.checkbox("Checkbox", "{unknown}description Checkbox wOw", bool)
	
	menu.slider("Slider", nil, num, 0, 10, 1)
	
	menu.choice("Multi-choice", nil, str, {{"Have", "have"}, {"Yo{null}u", "you"}, {"Ever", "ever"}}, false)
	
	menu.textinput("Text input", "aaaaaaaaaaaaaaaaaaaa", textinput)
	
	menu.disabled("Disabled")
	
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
	
	menu.spacer()
	
	menu.button("the", "an an")
	
	menu.button("Quit", "When you die in the game,"..newline.."you die in real life", function(self)
		love.event.quit()
	end)
	
	menu.pop()
end

function scene.delete(self)
	menu.close()
end

function scene.update(self)
	sprite.update(self.arrow, self)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	local focused = yui[menu.name].focused
	
	queue.add(self.drawlist, 0, function()
		gradient("horizontal", {
			{0, 1, 1, 0.5},
			{0, 1, 1, 0.125},
			{0, 0, 0, 0},
		}, 0, focused.y - 2, 0, onee.width, focused.h + 4)
	end)
	
	self.arrow.y = focused.y + 8
	sprite.draw(self.arrow, self)
	
	queue.add(self.drawlist, 2, function()
		text.print({"brb ", "{key_a}", {"shake", " accidentally"}, {{0,255,0}," inventing"}, " my own ", {{{"shake", strengthy = 3},{0,255,255}}, "scribble"}}, "font_12", 100, 82)
		text.print("test", "font_16", 100, 60)
	end)
end

return scene
