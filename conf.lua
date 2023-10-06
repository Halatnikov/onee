function love.conf(t)
	t.window.title = "onee"
	
	t.window.vsync = 0
	--t.window.resizable = true
	
	t.version = "11.3"
end

debug_mode = true

config = {
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
	},
}

