local gui = yui_
local button, menu

---------------------------------------------------------------- open button
local width, height = 20, 20
local padding = 4
button = {
	x = onee.width-width-padding, y = padding,
	
	onActive = function(self, active)
		self.visible = active
	end,
	
	gui.Rows {
		-- open debug menu
		gui.Button {
			w = width, h = height, nofocus = true,
			text = "+",
			onHit = function(self)
				yui.add(self.ui.instance, menu)
			end,
		},
	},
}

---------------------------------------------------------------- menu itself
local width, height = 192, 20
local padding = 4
menu = {
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
					love.event.quit("restart")
				end,
			},
			-- reset scene
			gui.Button {
				text = "Reset scene",
				onHit = function(self)
					scene.set(scenes[1].path)
				end,
			},
		},
		
		gui.Spacer {h = 4},
		
		gui.Columns {
			padding = padding,
			-- to init scene
			gui.Button {
				w = width/2 - padding/2, h = height,
				text = "Re-init",
				onHit = function(self)
					scene.set("init")
				end,
			},
			-- crahs
			gui.Button {
				text = "Crash!",
				onHit = function(self)
					error("you did this to yourself")
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

debug.yui.debug_menu = yui.new(button)