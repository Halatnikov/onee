local scene = {}

function scene.init(self)
	
	object.new("test", self, {a=1,{3}})
	--instance.new("test", self ,{b=4})
	--instance.new("test", self ,{b=5})
	
	object.new("yorb", self)
	for i=1,6 do instance.new("yorb", self ,{sprite={x=32*i,y=290}}) end
	
	object.new("player", self)
	instance.new("player", self)
	
	object.new("solid", self)
	instance.new("solid", self , {y = 350, width = 800})
	instance.new("solid", self , {x = 400, y = 290, width = 64, height = 64})
	
	object.new("test_gdportal", self)
	instance.new("test_gdportal", self , {x = 200, y = 280, scale = 0.5, angle = 45})
	
	scene.a = 2
	--debug.table(object.instances("test", self))
	
end

function scene.update(self)
	
	scene.a = scene.a - 10
	
end

function scene.draw(self)
	
	
	
end

return scene
