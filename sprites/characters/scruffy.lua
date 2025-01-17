local sprite = {}

sprite.animations = {

	idle = {
		filename = "spr_joestandr_0",
		x = 16, y = 32,
	},
	
	walk = {
		filename = "spr_joewalkr",
		seq = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
		speed = 15,
		x = 16, y = 32,
		frames = asset.add_frames(16, 16,32),
	},
	
	die = {
		filename = "spr_joedie_0",
		x = 16, y = 32,
	},

}

return sprite
