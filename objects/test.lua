local object = {}

function object.init(self)
	
	asset.sprite("earless")
	asset.sprite("example_tiled")
	asset.sprite("greyguy")
	asset.sprite("example_9slice")
	asset.sprite("cinge")
	
	asset.model("ayleen")
	asset.model("pso_teleporter")
	asset.model("test")
	asset.model("scruffy")
	
	self.sprite = sprite.init(self.sprite, "earless")
	self.sprite.x = math.random(100,400)
	self.sprite.y = 100
	self.sprite.animation = "walk"
	self.sprite.angle = -77
	
	self.sprite2 = sprite.init(self.sprite2, "example_tiled")
	self.sprite2.x = math.random(0,300)
	self.sprite2.y = 300
	self.sprite2.tiled.width = 238
	self.sprite2.tiled.height = 78
	self.sprite2.angle = 20
	self.sprite2.frame = math.random(1,4)
	
	self.sprite3 = sprite.init(self.sprite3, "greyguy")
	
	self.sprite4 = sprite.init(self.sprite4, "example_9slice")
	self.sprite4.x = 100
	self.sprite4.y = 100
	self.sprite4.nineslice.width = 128
	self.sprite4.nineslice.height = 64
	self.sprite4.frame = math.random(1,2)
	
	self.model = model.init(self.model, "pso_teleporter", {scale = 10})
	self.model.scale = 16
	self.model.yoffset = 11
	--self.model.canvas.width = 256
	--self.model.canvas.height = 256
	--self.model.angle = {y = 180}
	
end

function object.update(self)
	
	self.aaa = (self.aaa or math.random(0,10)) + 1
	self.sprite4.angle = (self.sprite4.angle or math.random(0,360)) + 2
	
	sprite.update(self.sprite)
	sprite.update(self.sprite2)
	sprite.update(self.sprite3)
	sprite.update(self.sprite4)
	
	model.update(self.model)
	
end

function object.draw(self)
	
	sprite.draw(self.sprite)
	sprite.draw(self.sprite2)
	sprite.draw(self.sprite3)
	sprite.draw(self.sprite4)
	
	model.draw(self.model)
	
end

return object
