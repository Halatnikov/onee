local scene_ = scene
local scene = {}

local menu = dofile("common/menu_simple")

local bool = true
local num = 5
local str = "you"
local textinput = "i'm freaks"

function scene.init(self)
	input.touch_active = false
	
	asset.sprite("spr_menu_arrow_16", self)
	asset.sprite("checkerboard", self)
	
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16", {x = 16})
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height}, scale = 8, z = -1})
	
	local main, yui_test
	
	main = menu.start({}, function(root, ui)
		local scene = self
		
		ui.onActive = function(self, active)
			self.visible = active
		end
		
		root.beforeDraw = function(self)
			gradient("horizontal", {
				{0, 1, 1, 0.5},
				{0, 1, 1, 0.125},
				{0, 0, 0, 0},
			}, 0, ui.focused.y - 2, 0, onee.width, ui.focused.h + 4)
		
			scene.arrow.y = ui.focused.y + 8
			sprite.draw(scene.arrow, scene, {queued = false})
		end
		
		menu.label("Scenes")
			
		local scenes = files.listdir("scenes")
		for i=1, #scenes do
			local name = string.remove(scenes[i], "scenes/", ".lua")
			
			menu.button(name, nil, function(self)
				scene_.set(name)
			end)
		end
		
		menu.label("Other")
		
		menu.button("yui elements test", "", function(self) yui.add(scene.menu, yui_test) end)
		
		menu.spacer()
		
		menu.hold("Quit", "When you die in the game,"..newline.."you die in real life", function(self)
			love.event.quit()
		end)
	end)
	
	yui_test = menu.start({}, function(root, ui)
		local scene = self
		
		root.beforeDraw = function(self)
			gradient("horizontal", {
				{0, 1, 1, 0.5},
				{0, 1, 1, 0.125},
				{0, 0, 0, 0},
			}, 0, ui.focused.y - 2, 0, onee.width, ui.focused.h + 4)
		
			scene.arrow.y = ui.focused.y + 8
			sprite.draw(scene.arrow, scene, {queued = false})
		end
		
		root.onActionInput = function(self, action)
			if action.cancel then yui.remove(scene.menu) end
		end
		
		menu.label("yui elements test")
		
		menu.button("Button", "that is a button", function(self) log("yes indeed") end)
		
		menu.checkbox("Checkbox", "description Checkbox wOw", bool)
		
		menu.slider("Slider", "", num, 0, 10, 1)
		
		menu.choice("Multi-choice", "", str, {{"Have", "have"}, {"You", "you"}, {"Ever", "ever"}}, false)
		
		menu.textinput("Text input", "aaaaaaaaaaaaaaaaaaaa", textinput)
		
		menu.button("Disabled", "", nil, false)
		
		menu.hold("Hold button", "a", function(self) log("THE") end)
		
		menu.dropdown("Dropdown menu", "opens a sub window", str, {
			{"Have", "have", "descriptions of separate items"},
			{"You", "you", "", function() log("i did") end},
			{"Ever", "ever", "hello"}
		})
		menu.dropdown("Inverted dropdown", "", str, table.fill("when the", 8), "when the", true)
		
		local gui = yui_
		table.insert(root, gui.Columns {
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
		
		menu.button("Back", "", function(self) yui.remove(scene.menu) end)
	end)
	
	self.menu = yui.new(main)
end

function scene.delete(self)
	input.touch_active = true
end

function scene.update(self)
	sprite.update(self.arrow, self)
	
	yui.update(self.menu)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	yui.draw(self.menu, self)
end

return scene
