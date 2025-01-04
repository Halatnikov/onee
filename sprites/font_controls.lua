local sprite = {}

sprite.filename = "font_controls"

sprite.animations = {
	unknown = {
		seq = {1,2,3,4},
		speed = 3,
		strip = {frames = 4, padding = 1, y = 170, width = 16, height = 16},
	},
	invalid = {
		seq = {1,2,3,4},
		speed = 3,
		strip = {frames = 4, padding = 1, y = 187, width = 16, height = 16},
	},
}

local keyboard = {
	letters = string.split("abcdefghijklmnopqrstuvwxyz"),
	numbers = {"0","1","2","3","4","5","6","7","8","9","kp0","kp1","kp2","kp3","kp4","kp5","kp6","kp7","kp8","kp9"},
	functions = {"f1","f2","f3","f4","f5","f6","f7","f8","f9","f10","f11","f12","f13","f14","f15","f16","f17","f18"},
	general = {"up","down","left","right","escape","space","return","backspace","tab","lctrl","rctrl","lalt","ralt","lshift","rshift","pause","insert","home","delete","end","pageup","pagedown"},
	symbols = {"`","-","=","\\","[","]",";","'",",",".","/","kp/","kp*","kp-","kp+","kp.","kpenter"},
}

for k,v in pairs(keyboard) do
	for i=1, #v do
		local y = k == "letters" and 0
			or k == "numbers" and 34
			or k == "functions" and 68
			or k == "general" and 102
			or k == "symbols" and 136
		
		sprite.animations["key_"..v[i]] = {
			seq = {1,2},
			speed = 3,
			strip = {
				mode = "vertical", frames = 2, padding = 1, width = 16, height = 16,
				x = (16 * (i - 1)) + (i - 1), y = y,
			},
		}
	end
end

sprite.font = {
	
	spacing = 2,
	baseheight = 16,
	
}

return sprite