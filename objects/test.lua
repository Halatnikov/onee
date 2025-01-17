local object = {}

function object.init(self, scene)
	
	asset.sprite("characters/earless", scene)
	asset.sprite("example_tiled", scene)
	asset.sprite("greyguy", scene)
	asset.sprite("example_9slice", scene)
	asset.sprite("cinge", scene)
	
	asset.model("ayleen", scene)
	asset.model("pso_teleporter", scene)
	asset.model("test", scene)
	asset.model("scruffy", scene)
	
	self.sprite = sprite.init(self.sprite, scene, "earless")
	self.sprite.x = math.random(100,400)
	self.sprite.y = 100
	self.sprite.animation = "walk"
	self.sprite.angle = -77
	
	self.sprite2 = sprite.init(self.sprite2, scene, "example_tiled")
	self.sprite2.x = math.random(0,300)
	self.sprite2.y = 300
	self.sprite2.tiled.width = 238
	self.sprite2.tiled.height = 78
	self.sprite2.angle = 20
	self.sprite2.frame = math.random(1,4)
	
	self.sprite3 = sprite.init(self.sprite3, scene, "greyguy")
	
	self.sprite4 = sprite.init(self.sprite4, scene, "example_9slice")
	self.sprite4.x = 100
	self.sprite4.y = 100
	self.sprite4.nineslice.width = 128
	self.sprite4.nineslice.height = 64
	self.sprite4.frame = math.random(1,2)
	
	self.model = model.init(self.model, scene, "pso_teleporter", {scale = 10})
	self.model.scale = 16
	self.model.yoffset = 11
	--self.model.canvas.width = 256
	--self.model.canvas.height = 256
	--self.model.angle = {y = 180}
	
end

function object.update(self, scene)
	
	self.aaa = (self.aaa or math.random(0,10)) + 1
	self.sprite4.angle = (self.sprite4.angle or math.random(0,360)) + 2
	
	sprite.update(self.sprite, scene)
	sprite.update(self.sprite2, scene)
	sprite.update(self.sprite3, scene)
	sprite.update(self.sprite4, scene)
	
	model.update(self.model, scene)
	
end


function object.draw(self, scene)
	
	sprite.draw(self.sprite, scene)
	sprite.draw(self.sprite2, scene)
	sprite.draw(self.sprite3, scene)
	sprite.draw(self.sprite4, scene)
	
	model.draw(self.model, scene)
	
end

return object
