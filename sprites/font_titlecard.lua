local sprite = {}

sprite.filename = "font_titlecard"

sprite.font = {
	
	spacing = 2,
	baseheight = 32,
	rows = {
		{chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ", y = 0},
		{chars = "0123456789!?,: ", y = 33, width = 268},
	},
	fallback = "font_controls",
	
}

return sprite