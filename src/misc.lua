
player = {}

timer_ms = 0 
timer_frames = 0

function misc_main()
	
	if not n3ds then love.graphics.setDefaultFilter("nearest","nearest",0) end
	
	dt = love.timer.getDelta()
	fps = 1/dt
	timer_ms = timer_ms + dt
	timer_frames = timer_frames + 1
	
	player_inst = instances.get("player",true)
	if player_inst then player = instances[player_inst].player end
	
end

function debug_main()

	if not n3ds then love.setDeprecationOutput(true) end
	nuklear_open.debug = true
	function love.keypressed_debug(k)
		if k == "lctrl" then  end -- do whatever
		if k == "rctrl" then assets.clear() objects.clear() end -- do whatever 2
		if k == "ralt" then instances.clear("yorb") end -- do whatever 3???
		
		if k == "lshift" then instances[player_inst].x, instances[player_inst].y = love.mouse.getPosition() end
		if k == "f2" then love.event.quit("restart") end
	end
	if timer_frames == 5 then
							
							level.load("test")
							
							objects.new("startpos")
							instances.new("startpos",{x=300,y=200})
							
							assets.sprite("skins/"..skin, "skin")
							objects.new("player","skin")
							instances.new("player") 
							--instances.new("player",{x=32,y=32})
							
							assets.sprite("objects/yorb", "yorb")
							objects.new("yorb","yorb")
							for i=1,6 do instances.new("yorb",{x=32*i,y=32}) end
							
							assets.sprite("objects/example_sprite_tiled", "example_sprite_tiled")
							objects.new("example_sprite_tiled","example_sprite_tiled")
							instances.new("example_sprite_tiled",{x=64,y=64,qwidth=112,qheight=76})
							
							objects.new("example_object")
							--for i=1,8 do instances.new("example_object",{x=32*i,y=32}) end
							
	end
end
