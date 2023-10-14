local sprite = {}

sprite.test = true
sprite.animations = {

	idle = {
		seq_start = {1},
		seq = {2,2,3,4,3},
		speed = 10,
		frames = asset.add_frames(4, 24,34),
	},
	walk = {
		seq = {1,2,3,4},
		speed = 25,
		frames = {
			[1] = { x = 20, y = 24 },
			[2] = { x = 20, y = 23 },
			[3] = { x = 20, y = 20 },
			[4] = { x = 20, y = 20 },
		},
		test = true,
	},
	skid = {
		images = "walk",
		frames = {
			[1] = { x = 20, y = 20, image = 3, test = true },
		},
	},
	jump = {
		seq = {1,2,3,4},
		speed = 25,
		frames = asset.add_frames(4, 17,-1),
	},
	fall = {
		images = "jump",
		seq = {1,2,3,4},
		speed = 25,
		frames = asset.add_frames(4, 17,-1),
	},

}

return sprite
