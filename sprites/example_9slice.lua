local sprite = {}

sprite.nineslice = true

sprite.animations = {

	idle = {
		nineslice = {
			x1 = 10,
			x2 = 10,
			y1 = 10,
			y2 = 10,
		},
		speed = 2,
		seq = {1,2},
		frames = asset.add_frames(2, 16,16),
	},
	
}

return sprite
