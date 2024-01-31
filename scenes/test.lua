local scene = {}

function scene.init()
	
	object.new("test",{a=1,{3}})
	--instance.new("test",{b=4})
	--instance.new("test",{b=5})
	
	object.new("yorb")
	for i=1,6 do instance.new("yorb",{sprite={x=32*i,y=290}}) end
	
	object.new("player")
	instance.new("player")
	
	object.new("solid")
	instance.new("solid", {y = 350, width = 800})
	instance.new("solid", {x = 400, y = 290, width = 64, height = 64})
	
	object.new("test_gdportal")
	instance.new("test_gdportal", {x = 200, y = 280, scale = 0.5, angle = 45})
	
	scene.a = 2
	--debug.table(object.instances("test"))
	
end

function scene.update()
	
	scene.a = scene.a - 10
	
end

function scene.draw()
	
	
	
end

return scene
