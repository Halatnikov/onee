local menu = {}
local gui = yui_

function menu.button(name, func, data)
	func = func or noop
	local t = gui.Button {
		h = 16, align = "center",
		text = name,
		onEnter = function(self)
			local test = love.audio.newSource("sounds/snd_menu.wav", "static"):play()
		end,
		onHit = function(self)
			local test = love.audio.newSource("sounds/snd_pause.wav", "static"):play()
			func(self)
		end,
	}
	table.append(t, data)
	return t
end
	
return menu