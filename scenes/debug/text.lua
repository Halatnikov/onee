local scene = {}

function scene.draw(self)
	text.print({"TEST", "{input_right}"}, "font_titlecard", 100, 10)
	
	text.printf({
		"privet ", {{255,127,237},"ayleen, "}, {{127,255,255},"colored text"},
		newline, "new line... ", {"shake", "shaking text  "}, {{"shake", strengthx = 5}, "REALLY shaking"},
		newline, {{"shake", {0,255,0}}, "combining effects "},
		"{input_a}", "displaying ", "{unknown}", "icons ", "{key_return}", "{invalid}",
		newline, {"wave", "wavy text"},
		newline, {{"rainbow", size = 3}, "rainbow text"},
	}, "font_12", 100, 40, nil, "center")
end

return scene