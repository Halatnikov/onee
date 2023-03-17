local x = 24
local y = 32

return {
animations = {

	["idle"] = {
				seq_start = {1},
				seq = {1},
				speed = 0,
				frames = sprites.add_frames(1, x,y,1)
	},
	["walk"] = {
				seq_start = {1,2,3,4},
				seq = {1,2,3,4},
				speed = 10,
				frames = sprites.add_frames(4, x,y,1)
	},
	["skid"] = {
				seq_start = {1},
				seq = {1},
				speed = 0,
				frames = sprites.add_frames(1, x,y,1)
	},
	["jump"] = {
				seq_start = {1,2,3,4,5,6,7,8},
				seq = {1,2,3,4,5,6,7,8},
				speed = 15,
				frames = sprites.add_frames(8, x,y,1)
	},
	["fall"] = {
				seq_start = {1,2,3},
				seq = {3},
				speed = 10,
				frames = sprites.add_frames(3, x,y,1)
	},

}
}
