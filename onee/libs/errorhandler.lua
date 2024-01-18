errorhandler = {}
local utf8 = require("utf8")

local function error_printer(msg, layer)
	print((debug.traceback("Error: " .. tostring(msg), 1+(layer or 1)):gsub("\n[^\n]+$", "")))
end

function love.errorhandler(msg)
	msg = tostring(msg)

	error_printer(msg, 2)

	if not love.window or not love.graphics or not love.event then
		return
	end

	if not love.graphics.isCreated() or not love.window.isOpen() then
		local success, status = pcall(love.window.setMode, 800, 600)
		if not success or not status then
			return
		end
	end

	-- Reset state.
	if love.mouse then
		love.mouse.setVisible(true)
		love.mouse.setGrabbed(false)
		love.mouse.setRelativeMode(false)
		if love.mouse.isCursorSupported() then
			love.mouse.setCursor()
		end
	end
	if love.joystick then
		-- Stop all joystick vibrations.
		for i,v in ipairs(love.joystick.getJoysticks()) do
			v:setVibration()
		end
	end
	if love.audio then love.audio.stop() end
	
	local draw, copyToClipboard = errorhandler.draw(msg, "love")
	
	return function()
		love.event.pump()

		for e, a, b, c in love.event.poll() do
			if e == "quit" then
				return 1
			elseif e == "keypressed" and a == "escape" then
				return 1
			elseif e == "keypressed" and a == "space" then
				return "restart"
			elseif e == "keypressed" and a == "c" and love.keyboard.isDown("lctrl", "rctrl") then
				copyToClipboard()
			elseif e == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then name = "Game" end
				local buttons = {"OK", "Cancel"}
				if love.system then
					buttons[3] = "Copy to clipboard"
				end
				local pressed = love.window.showMessageBox("Quit "..name.."?", "", buttons)
				if pressed == 1 then
					return 1
				elseif pressed == 3 then
					copyToClipboard()
				end
			end
		end
		
		love.graphics.present()
		draw()
		
		if love.timer then
			love.timer.sleep(0.1)
		end
	end
end

errorhandler.print = error_printer
-- todo: an option for more detailed tracebacks

function errorhandler.draw(msg, mode, notraceback)
	
	love.graphics.reset()
	local font = love.graphics.setNewFont(14)
	love.graphics.setColor(1, 1, 1)
	love.graphics.origin()
	
	msg = tostring(msg)
	local trace = notraceback and "" or debug.traceback()

	local sanitizedmsg = {}
	for char in msg:gmatch(utf8.charpattern) do
		table.insert(sanitizedmsg, char)
	end
	sanitizedmsg = table.concat(sanitizedmsg)

	local titles = {
		"Error",
		"It's going to be okay",
		"the",
		"Guys, I just saw a dog!",
		"That'll be four bucks baby you want fries with that?",
		"Funfetti code injection exploit",
		"Death",
		"The New Technology",
		"Arbitrary freak execution",
		"H",
		"Well, I heard you CAN lose a lot of weight on it",
		"But you can't keep it off, gotta eat less and exercise more",
		"So, what brings you here?",
		"things are happening",
		"Catastrophic failure",
	}

	local err = {}
	table.insert(err, titles[love.math.random(#titles)].."\n")
	
	if mode == "lurker" then
		table.insert(err, "[lurker] - If you fix the problem and update the file, the program will try to resume\n")
	end
	
	table.insert(err, sanitizedmsg)
	if #sanitizedmsg ~= #msg then
		table.insert(err, "Invalid UTF-8 string in error message.")
	end
	
	table.insert(err, "\n")
	for l in trace:gmatch("(.-)\n") do
		if not l:match("boot.lua") then
			l = l:gsub("stack traceback:", "Traceback\n")
			table.insert(err, l)
		end
	end

	err = table.concat(err, "\n")

	err = err:gsub("\t", "")
	err = err:gsub("%[string \"(.-)\"%]", "%1")
	
	err = err.."\n"
	err = err.."\nPress Ctrl+C to copy to clipboard"
	err = err.."\nPress Esc to quit or Space to restart"
	err = err.."\n"

	local fullErrorText = err
	local function copyToClipboard()
		if not love.system then return end
		love.system.setClipboardText(fullErrorText)
		err = err.."\nCopied to clipboard!"
	end
	
	local function draw()
		if not love.graphics.isActive() then return end
		local pos = 70
		love.graphics.clear(89/255, 157/255, 220/255)
		love.graphics.printf(err, font, pos, pos, love.graphics.getWidth() - pos)
		love.graphics.reset()
	end
	
	return draw, copyToClipboard
	
end