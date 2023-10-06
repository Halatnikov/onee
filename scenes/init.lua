local scene = {}

function scene.init()
	
	asset.sprite("earless")
	asset.sprite("example_tiled")
	asset.sprite("yorb")
	
	object.new("test",{a=1,{3}})
	instance.new("test",{b=4})
	instance.new("test",{b=5})
	
	object.new("yorb")
	for i=1,6 do instance.new("yorb",{sprite={x=32*i,y=32}}) end
	
	scene.a = 2
	--debug.table(object.instances("test"))
	
	scene.path = "D:\Users\DoorOpener\Desktop\C2andWADs\super_freaks\123\Super Freaks 1 2006 - The Search for Tikiman"
	
end

function scene.update()
	
	scene.a = scene.a - 10
	
end

function scene.draw()
	
	
	
end

return scene
