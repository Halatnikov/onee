local object = {}

function object.init(self)
	self.x = self.x or 0
	self.y = self.y or 0
	self.width = self.width or 32
	self.height = self.height or 32
	
	self.collision = collision.init(self.collision, "collision",
		{x = self.x, y = self.y, rect = {width = self.width, height = self.height}}
	)
end

function object.update(self)
	self.collision.x = self.x
	self.collision.y = self.y
	self.collision.rect.width = self.width
	self.collision.rect.height = self.height
end

function object.draw(self)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return object
