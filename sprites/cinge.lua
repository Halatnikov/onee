local sprite = {}

sprite.animations = {

	idle = {
		filename = "spr_boss_cinge_getup",
		seq = {1,2,3,4,5,6},
		speed = 10,
		x = 160/2,
		y = 160/2,
		sheet = {y = 0, width = 160},
		frames = {
			[1] = {sheet = {x = 160*0}},
			[2] = {sheet = {x = 160*1}},
			[3] = {sheet = {x = 160*2}},
			[4] = {sheet = {x = 160*3}},
			[5] = {sheet = {x = 160*4}},
			[6] = {sheet = {x = 160*5}},
		},
	},
	
	walk = {
		filename = "spr_boss_cinge_fireball",
		seq = {1,2,3,4,5,6,7,8},
		speed = 10,
		x = 160/2,
		y = 160/2,
		strip = {frames = 8},
	},
	
}

return sprite