local sprite = {}

sprite.tiled = true
sprite.animations = {

	["idle"] = {
				seq = {1,2,3,4},
				speed = 5,
				frames = asset.add_frames(4, 0,0,1),
	},
	
}

return sprite
