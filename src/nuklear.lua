nuklear_open = {}

function nuklear_gui()
	gui:frameBegin()
	
	if nuklear_open.debug then nuklear_ui_debug() end

	gui:frameEnd()
end

function nuklear_ui_debug()
	
	gui:window("v"..version, 500, 100, 300, 300,
			'border', 'title', 'movable', 'scalable', 'minimizable', 'scrollbar', 'scroll auto hide', function ()
		gui:layoutRow('dynamic', 16, 1)
		
		gui:label("FPS "..love.timer.getFPS().." "..math.round(1/dt,2).." "..math.round(1000*love.timer.getAverageDelta(),2).."ms")
		
		gui:tree("tab","Player", function ()
			gui:layoutRow('dynamic', 16, 1)
			gui:label("XY "..math.round(instances[player_inst].x,2).." "..math.round(instances[player_inst].y,2))
			gui:label("Speed "..math.round(player.x_speed,2).." "..math.round(player.y_speed,2))
			gui:label("Direction "..player.facing.." Ground "..tostring(player.ground))
			gui:label("Animation "..player.animation)
		end)
		
		gui:tree("tab","Input", function ()
			gui:layoutRow('dynamic', 16, 1)
			gui:label("Mouse XY "..love.mouse.getX().." "..love.mouse.getY().." "..input.mouse_wheel)
			gui:label("Input UDLR "..math.boolint(input.up).." "..math.boolint(input.down).." "..math.boolint(input.left).." "..math.boolint(input.right))
			gui:label("Input ABS "..math.boolint(input.a).." "..math.boolint(input.b).." "..math.boolint(input.start))
			gui:label("Input times UDLR "..input.time.up.." "..input.time.down.." "..input.time.left.." "..input.time.right)
			gui:label("Input times ABS "..input.time.a.." "..input.time.b.." "..input.time.start)
			gui:label("Input Mode "..input.mode)
		end)
		
		gui:tree("tab","Performance", function ()
			local stats = love.graphics.getStats()
			local renderer = {}; renderer.name, renderer.version, renderer.vendor, renderer.device = love.graphics.getRendererInfo()
			
			gui:layoutRow('dynamic', 16, 1)
			gui:label("Timer "..math.round(ms,2).." "..frames.." "..math.round(love.timer.getTime(),2))
			gui:label("dt "..math.round(dt,4).." "..math.round(1000*dt,2).."ms")
			if gui:widgetIsHovered() then gui:tooltip('Textures and garbage collector') end
			gui:label("RAM "..math.round(stats.texturememory/1024/1024,2).."MB "..math.round(collectgarbage("count")/1024,2).."MB")
			
			nuklear_add_table(love.graphics.getStats(),"love.graphics.getStats()")
			nuklear_add_table(renderer,"love.graphics.getRendererInfo()")
			nuklear_add_table(love.graphics.getSystemLimits(),"love.graphics.getSystemLimits()")
			
		end)
		
		nuklear_add_table(_G,"Global variables")
		
		nuklear_add_table(level,"level")
		nuklear_add_table(assets,"assets")
		nuklear_add_table(sprites,"sprites")
		nuklear_add_table(objects,"objects")
		nuklear_add_table(instances,"instances")
		
	end)
	
end

function nuklear_add_table(t, name)
	gui:tree("tab", name, function ()
		for k,v in pairs(t) do
			if type(k) ~= "table" then
				if not v then gui:label(tostring(k)) end
				if v then 
					if type(v) ~= "table" and type(v) ~= "function" then gui:label(tostring(k)..": "..tostring(v)) end
					if type(v) == "table" then nuklear_add_table(v, tostring(k)) end
				end
			end
			if type (k) == "table" then nuklear_add_table(k, tostring(k)) end
		end
	end)
end
