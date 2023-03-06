input = {
	mode = "keyboard",
	time = {},
	
	mouse_wheel = 0
}

for key in pairs(config.input.keyboard) do 
	input.time[key] = 0
end

function input_main()

-- begin loop
	if not n3ds then
	for key in pairs(input.time) do 
		input[key] = false
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
			if love.mouse.isDown(config.input.keyboard[key].m) then
				input.mode = "keyboard"
				input[key] = true
			end
		end
		-- mouse wheel
		if config.input.keyboard[key].mw then
			if math.sign(input.mouse_wheel) == config.input.keyboard[key].mw then
				if math.abs(input.mouse_wheel) > 0 then 
					input.mode = "keyboard"
					input[key] = true 
				end
			end
		end
	end
	
-- gamepad mode
	if input.gamepads then -- loop through all connected gamepads
		for p=1,#input.gamepads do
			for but in pairs(config.input.gamepad) do
				-- gamepad buttons
				if config.input.gamepad[but].b then
					if input.gamepads[p]:isGamepadDown(config.input.gamepad[but].b) then
						input.mode = "gamepad"
						input[but] = true
					end
				end
				-- gamepad hats (dpad)
				if config.input.gamepad[but].hat then
					for i in pairs(config.input.gamepad[but].hat) do
						if string.match(input.gamepads[p]:getHat(1),config.input.gamepad[but].hat[i]) then
							input.mode = "gamepad"
							input[but] = true
						end
					end
				end
				-- gamepad axis
				if config.input.gamepad[but].axis then
					for i in pairs(config.input.gamepad[but].axis) do
					
						local axis = config.input.gamepad[but].axis[i][1]
						local dir = config.input.gamepad[but].axis[i][2]	
					
						if math.sign(input.gamepads[p]:getGamepadAxis(axis)) == dir then
							if math.abs(input.gamepads[p]:getGamepadAxis(axis)) > config.input.gamepad_deadzone then 
								input.mode = "gamepad"
								input[but] = true 
							end
						end
					end
				end
			end
		end
	end
	end
	
	if n3ds then
		function love.gamepadpressed(joystick,button)
			if button == "dpleft" then input.left = true end
			if button == "dpright" then input.right = true end
			if button == "a" then input.a = true end
			
		end
		
		function love.gamepadreleased(joystick,button)
			if button == "dpleft" then input.left = false end
			if button == "dpright" then input.right = false end
			if button == "a" then input.a = false end
			
		end
		
		function love.gamepadaxis(joystick,axis,value)
			if axis == 1 then
				if value == 0 then input.left = false; input.right = false end
				if value > 0 then input.right = true end
				if value < 0 then input.left = true end
			end
			
		end
	end
	
-- end loop
	for key in pairs(input.time) do 
		if input[key] == true then input.time[key] = input.time[key] + 1 else input.time[key] = 0 end
	end
	input.mouse_wheel = 0
	
end


function love.joystickadded()
	input.gamepads = love.joystick.getJoysticks() end
function love.joystickremoved()
	input.gamepads = love.joystick.getJoysticks() end

-- press any key to switch modes
function love.keypressed_input() input.mode = "keyboard" end
function love.mousepressed_input() input.mode = "keyboard" end
function love.wheelmoved_input(x,y) 
	input.mouse_wheel = y; input.mode = "keyboard" end
function love.joystickpressed(joystick) input.mode = "gamepad" end
function love.joystickaxis(joystick) input.mode = "gamepad" end
