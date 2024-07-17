local scene_ = scene
local scene = {}

function scene.init(self)
	input.touch_active = false
	
	asset.sprite("checkerboard", self)
	self.bg = sprite.init(self.bg, self, "checkerboard", {tiled = {width = onee.width, height = onee.height, x = -8}, scale = 8, z = -1})
	
	local gui = yui_
	
	local width, height = 192, 20
	local padding = 4
	local menu = {
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
					-- self.ui.instance.stack[1].visible = true
					yui.remove(self.ui.instance)
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
						--love.event.quit("restart")
					end,
				},
				-- reset scene
				gui.Button {
					text = "Reset scene",
					onHit = function(self)
						scene_.set(scenes[1].name)
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
			-- draw yui debug
			gui.Checkbox {
				checked = debug_yui,
				text = "yui debug",
				onChange = function(self)
					debug_yui = not debug_yui
				end,
			},
		},
	}
	
	self.test = yui.new {
		x = onee.width-20-4, y = 4,
		gui.Rows {
			-- open debug menu
			gui.Button {
				w = 20, h = 20, nofocus = true,
				text = "+",
				onHit = function(self)
					-- self.ui.instance.stack[1].visible = false
					yui.add(self.ui.instance, menu)
				end,
			},
		},
	}
end

function scene.delete(self)
	
end

function scene.update(self)
	yui.update(self.test)
end

function scene.draw(self)
	sprite.draw(self.bg, self)
	
	yui.draw(self.test, self)
end

return scene
