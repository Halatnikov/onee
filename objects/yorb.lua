local object = {}

function object.init(self)
	asset.sprite("yorb")
	self.sprite = sprite.init(self.sprite, "yorb")
	
	self.sprite.x = self.sprite.x or 0
	self.sprite.y = self.sprite.y or 0
	
	self.collision = collision.init(self.collision, "collision",
		{x = self.sprite.x-16, y = self.sprite.y-16, rect = {width = 32}}
	)
	
	self.sprite.frame = ((self.sprite.x + self.sprite.y) % 6) + 1
end

function object.update(self)
	sprite.update(self.sprite)
	
	if collision.check(self.collision, "player", "hitbox") then
		self.collision = nil
		self.sprite.animation = "collect"
		
		function self.sprite.anim_end()
			self.delete()
		end
	end
	
end

function object.draw(self)
	sprite.draw(self.sprite)
end

return object
