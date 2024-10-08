local object = {}

function object.init(self, scene)
	asset.sprite("yorb", scene)
	self.sprite = sprite.init(self.sprite, scene, "yorb")
	
	self.sprite.x = self.sprite.x or 0
	self.sprite.y = self.sprite.y or 0
	
	self.collision = collision.init(self.collision, "collision",
		{x = self.sprite.x-16, y = self.sprite.y-16, rect = {width = 32}}
	)
	
	self.sprite.frame = ((self.sprite.x + self.sprite.y) % 6) + 1
end

function object.update(self, scene)
	sprite.update(self.sprite, scene)
	
	if collision.check(self.collision, scene, "player", "hitbox") then
		self.collision = nil
		self.sprite.animation = "collect"
		
		self.sprite.anim_end = function(anim)
			self.destroy()
		end
	end
	
end

function object.draw(self, scene)
	sprite.draw(self.sprite, scene)
end

return object
