local _ = Scene()

_.assets = {
	"titlescreen",
	"menu_cursor",
}

function _:init()
	asset.sprite("titlescreen", self)
	asset.sprite("menu_cursor", self)
	
	love.audio.stop()
	local audioFile = love.filesystem.newFileData("music/snd_title.ogg")
	local source = love.audio.newSource(audioFile, "stream")
	source:play()
	
	self.bg = sprite.init(self.bg, self, "titlescreen")
	self.cursor1 = sprite.init(self.cursor1, self, "menu_cursor", {scalex = -1})
	self.cursor2 = sprite.init(self.cursor2, self, "menu_cursor")
	
	local gui = yui_
	local scene = self
	
	local theme = {
		cornerRadius = 0,
		font = love.graphics.newFont(12, "normal", window.internal),
		color = {
			normal = {bg = {0,0,0,0}, fg = {0,0,0}},
			hovered = {bg = {0,0,0,0}, fg = {0,0,0}},
			active = {bg = {0,0,0,0}, fg = {0,0,0}},
		}
	}
	
	local function button(name, func)
		func = func or noop
		return gui.Button {
			h = 16, align = "center",
			text = name,
			onEnter = function(self)
				local test = love.audio.newSource("sounds/snd_menu.wav", "static"):play()
			end,
			onHit = function(self)
				local test = love.audio.newSource("sounds/snd_pause.wav", "static"):play()
				func(self)
			end,
		}
	end
	
	self.menu = yui.new({
		x = 0, y = 0, theme = theme,
		init = function(self)
			local root = self[1]
			root.x, root.y = (onee.width/2) - root.w/2, (onee.height/2) - root.h/2
			root:layoutWidgets()
		end,
		
		gui.Rows {
			beforeDraw = function(self)
				love.graphics.setColor(1,1,1, 0.5)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.reset()
				
				scene.cursor1.x, scene.cursor1.y = self.x + 16, self.ui.focused.y
				scene.cursor2.x, scene.cursor2.y = self.x + self.w - 16, self.ui.focused.y
				sprite.draw(scene.cursor1, scene, {queued = false})
				sprite.draw(scene.cursor2, scene, {queued = false})
			end,
			
			onDraw = function(self)
				love.graphics.setColor(0,0,0)
				love.graphics.printf("WHEN THE"..newline.."HAVE YOU EVER", theme.font, 0, onee.height-16*2, onee.width, "center")
			end,
			
			gui.Spacer {w = 192, h = 24},
			
			button("Test"),
			button("Test", function(self)
				self.text = string.random(8)
			end),
			button("Quit", function(self)
				love.event.quit()
			end),
			
			gui.Spacer {h = 24},
		},
		
	})
end

function _:deinit()
	
end

function _:update()
	yui.update(self.menu)
end

function _:draw()
	sprite.draw(self.bg, self)
	
	yui.draw(self.menu, self)
end

return _
