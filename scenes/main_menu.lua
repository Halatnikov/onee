local _ = Scene()

_.assets = {
	"titlescreen",
}

function _:init()
	asset.sprite("titlescreen", self)
	
	onee.loading = noop
	
	love.audio.stop()
	local audioFile = love.filesystem.newFileData("music/snd_title.ogg")
	local source = love.audio.newSource(audioFile, "stream")
	source:play()
	
	self.bg = sprite.init(self.bg, self, "titlescreen")
	
	onee.persist.font = love.graphics.newFont(12, "normal", window.internal)
	
	local gui = yui_
	local menu = dofile("common/menu")
	
	scene.add("popup", nil, {menu = {
		transparent = true,
		
		onDraw = function(self)
			love.graphics.setColor(0,0,0)
			love.graphics.printf("WHEN THE"..newline.."HAVE YOU EVER", onee.persist.font, 0, onee.height-16*2, onee.width, "center")
		end,
		
		gui.Spacer {w = 192, h = 24},
		
		menu.button("Test", function(self)
			self.text = string.random(8)
		end),
		
		gui.Choice {
			choices = {1, {"two",2}, "super mario"},
			choices_old = {1, {"two",2}, "super mario"},
			label = "Test Choice: ",
			--default = var,
			nowrap = false,
			
			onChange = function(self, choice) 
				
			end,
			
			draw = gui.Button.draw,
			onUpdate = function(self)
				self.text = self.choices[self.index][1]
				
				for k,v in ipairs(self.choices_old) do
					local label = type(v) == "table" and v[1] or v
					v = type(v) == "table" and v[2] or v
					self.choices[k] = {self.label..label, v}
				end
			end,
		},
		
		menu.button("Submenu", function(self)
			self.ui.active = false
			scene.add("popup", nil, {menu = {
				menu.button("Another one", function(self)
					self.text = string.random(8)
				end, {w = 256}),
				
				menu.button("Back", function(self)
					self.text = string.random(8)
				end),
			}})
		end),
		
		menu.button("Quit", function(self)
			love.event.quit()
		end),
		
		gui.Spacer {h = 24},
	}})
	
end

function _:deinit()
	love.audio.stop()
end

function _:update()
	
end

function _:draw()
	sprite.draw(self.bg, self)
end

return _
