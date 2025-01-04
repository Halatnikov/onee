--TODO: maybe do a t.onee (set them as globals later)
function love.conf(t)
	t.title = "Scruffy 1: Freaky Edition"
	t.identity = "scruffy1freaky" -- savedata folder
	t.version = "11.3" -- minimum love2d version
	
	t.onee = "0.0.2" -- preferred onee version
	
	t.width = 640
    t.height = 480
	
	t.gammacorrect = true
	t.window = nil
	
	love.config = t -- expose config
	debug_mode = true
end

config = {
	graphics = {
		scale = 1,
		scale_internal = 1,
		scale_mode = "none",
	},
	input = {
		keyboard = {
			up = {k = {"up","w"}, mw = 1},
			down = {k = {"down","s"}, mw = -1},
			left = {k = {"left","a"}},
			right = {k = {"right","d"}},
			a = {k = {"z","space"}, m = {1}},
			b = {k = {"x"}, m = {2}},
			start = {k = {"return","escape"}},
		},
		gamepad = {
			up = {b = {"dpup"}, axis = {{"lefty",-1}}, hat = {"u"}},
			down = {b = {"dpdown"}, axis = {{"lefty",1}}, hat = {"d"}},
			left = {b = {"dpleft"}, axis = {{"leftx",-1}}, hat = {"l"}},
			right = {b = {"dpright"}, axis = {{"leftx",1}}, hat = {"r"}},
			a = {b = {"a"}},
			b = {b = {"b"}},
			start = {b = {"start"}},
		},
		gamepad_deadzone = 0.3,
		touch = {
			up = {{rect = {64,-140, 32,64}}},
			down = {{rect = {64,-76, 32,64}}},
			left = {{rect = {16,-92, 64,32}}},
			right = {{rect = {80,-92, 64,32}}},
			a = {{circle = {-64,-80, 48}, text = "A"}},
			b = {{circle = {-150,-48, 32}, text = "B"}},
			start = {{rect = {-44,-48, 88,32}, centerx = true, text = "Pause"}},
		},
	},
}

