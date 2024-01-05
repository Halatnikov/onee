local object = {}

function object.init(self)
	self.x = self.x or 0
	self.y = self.y or 0
	self.width = self.width or 32
	self.height = self.height or 32
	
	self.collision = collision.init(self.collision, "collision",
		{rect = {}}
	)
end

function object.update(self)
	self.collision.x = self.x
	self.collision.y = self.y
	self.collision.rect.width = self.width
	self.collision.rect.height = self.height
	
	local player
	local check, col = collision.check(self.collision, "player", "collider_down")
	if check then player = instances[col.instance].player; player.ground = true end
end

function object.draw(self)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return object
