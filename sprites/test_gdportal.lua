local sprite = {}

local framex = 196/2
local framey = 340/2

sprite.animations = {

	idle = {
		frames = {
			[1] = {filename = "portal_04_back_001", x = -9, y = -14},
			[2] = {filename = "portal_04_front_001", x = -62, y = -0},
			[3] = {filename = "portal_04_extra_001", x = -112, y = -103},
			[4] = {filename = "portal_04_extra_2_001", x = -119, y = -150},
		},
	},
	
}

return sprite