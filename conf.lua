function love.conf(t)
	t.window.title = "onee"
	t.version = "11.3"
	
	t.window.vsync = 0
	t.window.resizable = true
	t.window.fullscreen = (love._os == "Android" or love._os == "iOS")
	t.gammacorrect = true
	
	t.identity = "savedata"
	t.appendidentity = true
	t.externalstorage = true
end

mobile = (love._os == "Android" or love._os == "iOS")

tick = 0.016
framerate = 60

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
		touch = {
			up = {},
			down = {},
			left = {},
			right = {},
			a = {{circle = {-64,-80, 48}, text = "A"}},
			b = {{circle = {-150,-48, 32}, text = "B"}},
			start = {{rect = {312,-48, 88,32}, text = "Start"}},
		},
	},
}

