local sprite = {}

sprite.animations = {
	
	idle = {
		filename = "spr_player_stand_scruffy",
		x = 24,
		y = 32,
		strip = {frames = 1},
	},
	
	walk = {
		filename = "spr_player_walk_scruffy",
		seq = {1,2,3,4},
		speed = 10,
		x = 24,
		y = 32,
		strip = {frames = 4},
	},
	
	skid = {
		filename = "spr_player_skid_scruffy",
		x = 24,
		y = 32,
		strip = {frames = 1},
	},
	
	jump = {
		filename = "spr_player_jump_scruffy",
		seq = {1,2,3,4,5,6,7,8},
		speed = 15,
		x = 24,
		y = 32,
		strip = {frames = 8},
	},
	
	fall = {
		filename = "spr_player_air_scruffy",
		seq_start = {1,2},
		seq = {3},
		speed = 10,
		x = 24,
		y = 32,
		strip = {frames = 3},
	},
	
}

return sprite