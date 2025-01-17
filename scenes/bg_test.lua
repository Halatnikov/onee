local _ = Scene()

_.assets = {
	"bg_purple",
}

_.color = {1, 0.5, 1}

function _:init()
	asset.sprite("bg_purple", self)
	self.bg = sprite.init(self.bg, self, "bg_purple", {tiled = {width = onee.width, height = onee.height, y = 0}})
	
	--temp
	object.new("joe", self)
	instance.new("joe", self)
end

function _:update()
	if frames % 2 == 0 then self.bg.tiled.y = math.wrap(0, self.bg.tiled.y + 1, 32) end
end

function _:draw()
	love.graphics.clear(self.color)
	sprite.draw(self.bg, self)
end

return _
