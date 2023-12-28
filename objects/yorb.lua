local object = {}

function object.init(self)
	asset.sprite("yorb")
	self.sprite = sprite.init(self.sprite, "yorb")
	
	self.sprite.frame = ((self.sprite.x + self.sprite.y) % 6) + 1
end

function object.update(self)
	sprite.update(self.sprite)
end

function object.draw(self)
	sprite.draw(self.sprite)
end

return object
