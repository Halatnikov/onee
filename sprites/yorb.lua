local sprite = {}

sprite.animations = {

	idle = {
		seq = {1,2,3,4,5,6},
		speed = 7,
		frames = asset.add_frames(6, 16,16),
	},
	
	collect = {
		filename = "spr_yorb_collect",
		seq_start = {1,2,3,4,5,6},
		speed = 10,
		x = 8,
		y = 8,
		strip = {frames = 6},
	},
}

return sprite
