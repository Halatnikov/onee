function love.conf(t)
	t.window.title = "Onee"
	
	t.window.vsync = 0
	--t.window.resizable = true
	
	t.identity = "savedata"
	t.appendidentity = true
	t.version = "11.3"
	
	t.window.fullscreen = (love._os == "Android")
	
end

debug_mode = true

config = {
	input = {
		keyboard = {
		 -- key = {k = {"z","x"}, m = {1,2}, mw = -1}
			up = {k = {"up","w"}},
			down = {k = {"down","s"}},
			left = {k = {"left","a"}},
			right = {k = {"right","d"}},
			a = {k = {"z"}},
			b = {k = {"x"}},
			start = {k = {"return"}},
		},
		gamepad = {
		 -- but = {b = {"a","b"}, axis = {{"axis",-1},{"axis",1}}, hat = {"l","r"}},
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