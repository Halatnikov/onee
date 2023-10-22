input = {
	mode = "keyboard",
	time = {},
	
	mouse_wheel = 0,
	mouse_istouch = {},
}

-- initialize the table
for key in pairs(config.input.keyboard) do 
	input[key] = false
	input.time[key] = 0
end

---------------------------------------------------------------- 

function input.update() -- MAIN LOOP --
	-- begin loop
	for key in pairs(input.time) do 
		input[key] = false -- reset key states
	end
	
	-- keyboard mode
	for key in pairs(config.input.keyboard) do
		-- keyboard keys
		if config.input.keyboard[key].k then
			if love.keyboard.isDown(config.input.keyboard[key].k) then 
				input.mode = "keyboard"
				input[key] = true
			end
		end
		-- mouse buttons
		if config.input.keyboard[key].m then
			if love.mouse.isDown(config.input.keyboard[key].m)
			and not input.mouse_istouch[1] then -- prevent touch input
				input.mode = "keyboard"
				input[key] = true
			end
		end
		-- mouse wheel
		if config.input.keyboard[key].mw then
			if math.abs(input.mouse_wheel) > 0
			and math.sign(input.mouse_wheel) == config.input.keyboard[key].mw then
				input.mode = "keyboard"
				input[key] = true 
			end
		end
	end
	
	-- gamepad mode
	if input.gamepads then
		for p=1,#input.gamepads do -- loop through all connected gamepads
			for key in pairs(config.input.gamepad) do
				-- gamepad buttons
				if config.input.gamepad[key].b then
					if input.gamepads[p]:isGamepadDown(config.input.gamepad[key].b) then
						input.mode = "gamepad"
						input[key] = true
					end
				end
				-- gamepad hats (dpad)
				if config.input.gamepad[key].hat then
					for i in pairs(config.input.gamepad[key].hat) do
						if string.match(input.gamepads[p]:getHat(1),config.input.gamepad[key].hat[i]) then
							input.mode = "gamepad"
							input[key] = true
						end
					end
				end
				-- gamepad axis
				if config.input.gamepad[key].axis then
					for i in pairs(config.input.gamepad[key].axis) do
					
						local axis = config.input.gamepad[key].axis[i][1]
						local dir = config.input.gamepad[key].axis[i][2]	
					
						if math.abs(input.gamepads[p]:getGamepadAxis(axis)) > config.input.gamepad_deadzone
						and math.sign(input.gamepads[p]:getGamepadAxis(axis)) == dir then 
							input.mode = "gamepad"
							input[key] = true 
						end
					end
				end
			end
		end
	end
	
	-- touch screen mode
	if mobile then
		local touches = love.touch.getTouches()
		
		for key in pairs(config.input.touch) do
			for i in pairs(config.input.touch[key]) do
				for j,id in ipairs(touches) do
					local touchx, touchy = love.touch.getPosition(id)
					local shape = config.input.touch[key][i]
					
					if shape.circle then
						local x = shape.circle[1]
						local y = shape.circle[2]
						local radius = shape.circle[3]
						
						if math.sign(x) == -1 then x = windowwidth + x end
						if math.sign(y) == -1 then y = windowheight + y end
						
						if collision.point_circle(touchx,touchy, x,y,radius) then
							input.mode = "touch"
							input[key] = true
						end
					end
					
					if shape.rect then
						local x = shape.rect[1]
						local y = shape.rect[2]
						local width = shape.rect[3]
						local height = shape.rect[4] or width
						
						if math.sign(x) == -1 then x = windowwidth + x end
						if math.sign(y) == -1 then y = windowheight + y end
						
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
		if input[key] == true then 
			input.time[key] = input.time[key] + 1	-- key is held, count time
		else
			input.time[key] = 0						-- key was released
		end
	end
	input.mouse_wheel = 0 -- reset mouse wheel
	
end

---------------------------------------------------------------- 

function input.draw() -- DRAW LOOP --
	-- draw touch screen buttons
	if mobile then
		for key in pairs(config.input.touch) do
			for i in pairs(config.input.touch[key]) do
				local shape = config.input.touch[key][i]
				
				if shape.circle then
					local x = shape.circle[1]
					local y = shape.circle[2]
					local radius = shape.circle[3]
					local segments = shape.circle[4] or nil -- how detailed is the circle
					
					if math.sign(x) == -1 then x = windowwidth + x end
					if math.sign(y) == -1 then y = windowheight + y end
					
					if not input[key] == true then
						love.graphics.setColor(1,1,1,0.5)
						love.graphics.circle("line",x,y,radius, segments)
						love.graphics.printf(shape.text or "", x-(radius/2), y-8, radius, "center")
					else
						love.graphics.setColor(1,1,1,0.5)
						love.graphics.circle("fill",x,y,radius, segments)
						love.graphics.printf(shape.text or "", x-(radius/1.33), y-12, radius, "center", 0, 1.5, 1.5)
					end
				end
				
				if shape.rect then
					local x = shape.rect[1]
					local y = shape.rect[2]
					local width = shape.rect[3]
					local height = shape.rect[4] or width
					local rx = shape.rect[5] or nil -- round corners
					local ry = shape.rect[6] or ry
					local segments = shape.rect[7] or nil
					
					if math.sign(x) == -1 then x = windowwidth + x end
					if math.sign(y) == -1 then y = windowheight + y end
					
					if not input[key] == true then
						love.graphics.setColor(1,1,1,0.5)
						love.graphics.rectangle("line",x,y,width,height, rx,ry,segments)
						love.graphics.printf(shape.text or "", x, y+(height/2)-8, width, "center")
					else
						love.graphics.setColor(1,1,1,0.5)
						love.graphics.rectangle("fill",x,y,width,height, rx,ry,segments)
						love.graphics.printf(shape.text or "", x-(width/4), y+(height/2)-12, width, "center", 0, 1.5, 1.5)
					end
				end
				
				-- reset graphics state
				love.graphics.setColor(1,1,1,1)
				
			end
		end
	end
end

---------------------------------------------------------------- 

-- update gamepad list
function love.joystickadded()
	input.gamepads = love.joystick.getJoysticks()
end
function love.joystickremoved()
	input.gamepads = love.joystick.getJoysticks()
end

-- mouse wheel input
function input.wheelmoved(x,y) 
	input.mouse_wheel = y
end

-- differentiate between mouse and touch inputs (workaround)
function input.mousepressed(x,y,button,istouch)
  input.mouse_istouch[button] = istouch
end
function input.mousereleased(x,y,button,istouch)
  input.mouse_istouch[button] = nil
end
