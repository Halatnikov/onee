local sprite = {}

sprite.filename = "font_16"

sprite.animations = {
	
}

sprite.font = {
	
	spacing = 2,
	baseheight = 20,
	
	rows = {
		{chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ", y = 0},
		{chars = "abcdefghijklmnopqrstuvwxyz", y = 21, width = 276},
		{chars = "0123456789", y = 42, width = 111},
		{chars = " !\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~", y = 63, width = 319},
	},
	
}

return sprite