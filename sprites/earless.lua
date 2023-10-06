local sprite = {}

sprite.animations = {

	["idle"] = {
				seq_start = {1},
				seq = {2,3,4,3},
				speed = 10,
				frames = asset.add_frames(4, 24,34,1)
	},
	["walk"] = {
				seq = {1,2,3,4},
				speed = 25,
				frames = {
					[1] = { x = 20, y = 24, speed = 1 },
					[2] = { x = 20, y = 23, speed = 1 },
					[3] = { x = 20, y = 20, speed = 1 },
					[4] = { x = 20, y = 20, speed = 1 },
				}
	},
	["skid"] = {
				images = "walk",
				frames = {
					[1] = { x = 20, y = 20, speed = 1, image = 3 },
				}
	},
	["jump"] = {
				seq = {1,2,3,4},
				speed = 25,
				frames = asset.add_frames(4, 17,-1,1)
	},
	["fall"] = {
				images = "jump",
				seq = {1,2,3,4},
				speed = 25,
				frames = asset.add_frames(4, 17,-1,1)
	},

}

return sprite
