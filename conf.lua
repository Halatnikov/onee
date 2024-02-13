--TODO: maybe do a t.onee (set them as globals later)
function love.conf(t)
	t.title = "onee"
	t.identity = "onee" -- savedata folder
	t.version = "11.3" -- minimum love2d version
	
	t.window.width = 640
    t.window.height = 360
	t.gammacorrect = true
	
	t.externalstorage = true -- android
	
	love.config = t -- expose config
	debug_mode = true
end

config = {
	graphics = {
		scale = 1,
		scale_internal = 1,
		scale_mode = "",
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
			up = {},
			down = {},
			left = {},
			right = {},
			a = {{circle = {-64,-80, 48}, text = "A"}},
			b = {{circle = {-150,-48, 32}, text = "B"}},
			start = {{rect = {-44,-48, 88,32}, centerx = true, text = "Start"}},
		},
	},
}

