local sprite = {}

sprite.animations = {

	["idle"] = {
				seq = {1,2,3,4,5,6},
				speed = 7,
				frames = asset.add_frames(6, 16,16,1),
	},
}

return sprite
