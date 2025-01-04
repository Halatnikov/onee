local _ = Scene()

-- todo: possibly load every single asset at init? using files.listdir("sprites")
_.assets = {
	"loading_bg",
	"loading_bar_bg",
	"loading_bar_fg",
}

function _:init()
	input.touch_active = false
	onee.width, onee.height = 590, 500
	window.update()
	
	asset.sprite("loading_bg", self)
	asset.sprite("loading_bar_bg", self)
	asset.sprite("loading_bar_fg", self)
	
	self.bg = sprite.init(self.bg, self, "loading_bg")
	self.bar_bg = sprite.init(self.bar_bg, self, "loading_bar_bg", {x = 24, y = 468, width = 542, height = 16})
	self.bar_fg = sprite.init(self.bar_fg, self, "loading_bar_fg", {x = 24, y = 468, width = 0, height = 16})
end

function _:deinit()
	input.touch_active = true
	onee.width, onee.height = 640, 480
	window.update()
end

function _:update()
	self.bar_fg.width = math.wrap(0, self.bar_fg.width + 4, 542)
end

function _:draw()
	sprite.draw(self.bg, self)
	sprite.draw(self.bar_bg, self)
	sprite.draw(self.bar_fg, self)
end

return _
