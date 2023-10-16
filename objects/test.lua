local object = {}

function object.init(self)
	
	self.aaa = love.math.random(0,10)
	
	self.sprite = sprite.init(self.sprite, "earless")
	self.sprite.x = love.math.random(100,400)
	self.sprite.y = 100
	self.sprite.animation = "walk"
	self.sprite.angle = -77
	
	self.sprite2 = sprite.init(self.sprite2, "example_tiled")
	self.sprite2.x = love.math.random(0,300)
	self.sprite2.y = 300
	self.sprite2.qwidth = 238
	self.sprite2.qheight = 78
	self.sprite2.angle = 20
	self.sprite2.frame = love.math.random(1,4)
	
	self.sprite3 = sprite.init(self.sprite3, "greyguy")
	
end

function object.update(self)
	
	self.aaa = self.aaa + 1
	
	sprite.update(self.sprite)
	sprite.update(self.sprite2)
	sprite.update(self.sprite3)
	
end

function object.draw(self)
	
	sprite.draw(self.sprite)
	sprite.draw(self.sprite2)
	sprite.draw(self.sprite3)
	
end

return object
