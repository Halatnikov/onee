input = {
	mode = "keyboard",
	time = {},
	
	mouse_wheel = 0
}

-- initialize the table
for key in pairs(config.input.keyboard) do 
	input[key] = false
	input.time[key] = 0
end

-- main loop
function input.update()
	
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
		-- mouse keytons
		if config.input.keyboard[key].m then
			if love.mouse.isDown(config.input.keyboard[key].m) then
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

-- update gamepad list
function love.joystickadded()
	input.gamepads = love.joystick.getJoysticks()
end
function love.joystickremoved()
	input.gamepads = love.joystick.getJoysticks()
end

-- press any key to switch modes
function input.keypressed() input.mode = "keyboard" end
function input.mousepressed() input.mode = "keyboard" end
function input.wheelmoved(x,y) 
	input.mouse_wheel = y -- mouse wheel input
	input.mode = "keyboard"
end
function love.joystickpressed() input.mode = "gamepad" end
function love.joystickaxis() input.mode = "gamepad" end