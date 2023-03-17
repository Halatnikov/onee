return {
animations = {

	["idle"] = {
				seq_start = {1},
				seq = {2,3,4,3,2},
				speed = 10,
				frames = sprites.add_frames(4, 24,34,1)
	},
	["walk"] = {
				seq_start = {1,2,3,4},
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
				anim = "walk",
				seq_start = {3},
				seq = {3},
				speed = 0,
				frames = sprites.add_frames(3, 20,20,1)
	},
	["jump"] = {
				seq_start = {1,2,3,4},
				seq = {1,2,3,4},
				speed = 25,
				frames = sprites.add_frames(4, 17,-1,1)
	},
	["fall"] = {
				anim = "jump",
				seq_start = {1,2,3,4},
				seq = {1,2,3,4},
				speed = 25,
				frames = sprites.add_frames(4, 17,-1,1)
	},

}
}
