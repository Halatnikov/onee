local scene = {}

function scene.init()
	
	--asset.sprite("earless")
	--asset.sprite("example_tiled")
	--asset.sprite("greyguy")
	--asset.sprite("example_9slice")
	--asset.sprite("cinge")
	
	--asset.model("ayleen")
	--asset.model("pso_teleporter")
	--asset.model("test")
	--asset.model("scruffy")
	
	--object.new("test",{a=1,{3}})
	--instance.new("test",{b=4})
	--instance.new("test",{b=5})
	
	object.new("yorb")
	for i=1,6 do instance.new("yorb",{sprite={x=32*i,y=290}}) end
	
	object.new("player")
	instance.new("player")
	
	scene.a = 2
	--debug.table(object.instances("test"))
	
end

function scene.update()
	
	scene.a = scene.a - 10
	
end

function scene.draw()
	
	
	
end

return scene
