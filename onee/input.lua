input = {
	mode = "keyboard",
	ignore = false,
	touch_active = true,	

	time = {},
	pressed = {},
	released = {},
	
	mouse_wheel = 0,
	mouse_istouch = {},	
}

-- initialize the table
for k in pairs(config.input.keyboard) do 
	input[k] = false
	input.time[k] = 0
	input.pressed[k] = false
	input.released[k] = false
end

---------------------------------------------------------------- 

-- MAIN LOOP
function input.update()
	-- begin loop
	for key in pairs(input.time) do 
		input[key] = false -- reset key states
		input.pressed[key] = false
		input.released[key] = false
	end
	if input.ignore then return end
	
	-- keyboard and mouse mode
	for key, entry in pairs(config.input.keyboard) do
		-- keyboard keys
		if entry.k then
			if love.keyboard.isDown(entry.k) then 
				input.mode = "keyboard"
				input[key] = true
			end
		end
		-- mouse buttons
		if entry.m then
			if love.mouse.isDown(entry.m)
			and not input.mouse_istouch[1] then -- prevent touch input
				input.mode = "keyboard"
				input[key] = true
			end
		end
		-- mouse wheel
		if entry.mw then
			if math.abs(input.mouse_wheel) > 0
			and math.sign(input.mouse_wheel) == entry.mw then
				input.mode = "keyboard"
				input[key] = true 
			end
		end
	end
	
	-- gamepad mode
	if input.gamepads then
		for i, gamepad in pairs(input.gamepads) do -- loop through all connected gamepads
			for key, entry in pairs(config.input.gamepad) do
				-- gamepad buttons
				if entry.b then
					if gamepad:isGamepadDown(entry.b) then
						input.mode = "gamepad"
						input[key] = true
					end
				end
				-- gamepad hats (dpad)
				if entry.hat then
					for i in pairs(entry.hat) do
						if string.match(gamepad:getHat(1), entry.hat[i]) then
							input.mode = "gamepad"
							input[key] = true
						end
					end
				end
				-- gamepad axis
				if entry.axis then
					for i in pairs(entry.axis) do
						local axis, dir = entry.axis[i][1], entry.axis[i][2]
					
						if (math.abs(gamepad:getGamepadAxis(axis)) > config.input.gamepad_deadzone)
						and math.sign(gamepad:getGamepadAxis(axis)) == dir then 
							input.mode = "gamepad"
							input[key] = true 
						end
					end
				end
			end
		end
	end
	
	-- touch screen mode
	if mobile and input.touch_active then
		local touches = love.touch.getTouches()
		
		for key, entry in pairs(config.input.touch) do
			for i, shape in pairs(entry) do
				for j, id in pairs(touches) do
					local touchx, touchy = love.touch.getPosition(id)
					
					if shape.circle then
						local x, y = shape.circle[1], shape.circle[2]
						local radius = shape.circle[3]
						
						if shape.centerx then x = (windowwidth/2) + x elseif math.sign(x) == -1 then x = windowwidth + x end
						if shape.centery then y = (windowheight/2) + y elseif math.sign(y) == -1 then y = windowheight + y end
						
						if collision.point_circ(touchx,touchy, x,y,radius) then
							input.mode = "touch"
							input[key] = true
						end
					end
					
					if shape.rect then
						local x, y = shape.rect[1], shape.rect[2]
						local width = shape.rect[3]
						local height = shape.rect[4] or width
						
						if shape.centerx then x = (windowwidth/2) + x elseif math.sign(x) == -1 then x = windowwidth + x end
						if shape.centery then y = (windowheight/2) + y elseif math.sign(y) == -1 then y = windowheight + y end
						
						if collision.point_rect(touchx,touchy, x,y,width,height) then
							input.mode = "touch"
							input[key] = true
						end
					end
					
				end
			end
		end
	end
	
	-- end loop
	for key in pairs(input.time) do 
		if input[key] then
			if input.time[key] < 1 then input.pressed[key] = true end -- key pressed once
			input.time[key] = input.time[key] + 1 -- key is held, count time
		else
			if input.time[key] > 1 then input.released[key] = true end
			input.time[key] = 0 -- key was released
		end
	end
	input.mouse_wheel = 0 -- reset mouse wheel
end

-- DRAW LOOP
function input.draw()
	-- draw touch screen buttons
	if mobile and input.touch_active then
		for key, entry in pairs(config.input.touch) do
			for i, shape in pairs(entry) do
				love.graphics.setColor(1,1,1,0.5)
				local fill = input[key] and "fill" or "line"
				
				if shape.circle then
					local x, y = shape.circle[1], shape.circle[2]
					local radius = shape.circle[3]
					
					if shape.centerx then x = (windowwidth/2) + x elseif math.sign(x) == -1 then x = windowwidth + x end
					if shape.centery then y = (windowheight/2) + y elseif math.sign(y) == -1 then y = windowheight + y end
					
					love.graphics.circle(fill, x, y, radius)
					love.graphics.printf(shape.text or "", x-(radius/2), y-8, radius, "center")
				end
				
				if shape.rect then
					local x, y = shape.rect[1], shape.rect[2]
					local width = shape.rect[3]
					local height = shape.rect[4] or width
					
					if shape.centerx then x = (windowwidth/2) + x elseif math.sign(x) == -1 then x = windowwidth + x end
					if shape.centery then y = (windowheight/2) + y elseif math.sign(y) == -1 then y = windowheight + y end
					
					love.graphics.rectangle(fill, x, y, width, height)
					love.graphics.printf(shape.text or "", x, y+(height/2)-8, width, "center")
				end
				
				love.graphics.reset()
				
			end
		end
	end
end

---------------------------------------------------------------- 

-- update gamepad list
onee.love("joystickadded", function()
	input.gamepads = love.joystick.getJoysticks()
end)
onee.love("joystickremoved", function()
	input.gamepads = love.joystick.getJoysticks()
end)

-- mouse wheel input
onee.love("wheelmoved", function(x,y) 
	input.mouse_wheel = y
end)

-- differentiate between mouse and touch inputs (workaround)
onee.love("mousepressed", function(x,y,button,istouch)
	input.mouse_istouch[button] = istouch
end)
onee.love("mousereleased", function(x,y,button,istouch)
	input.mouse_istouch[button] = nil
end)

_prof.hook("input")