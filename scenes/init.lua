local _ = Scene()

_.assets = {
	"font_controls",
	"font_12",
	"font_16",
	"font_titlecard",
}

function _:init()
	-- init fonts
	asset.spritefont("font_controls")
	
	asset.spritefont("font_12")
	font.append("font_12", "font_controls")
	
	asset.spritefont("font_16")
	font.append("font_16", "font_controls")
	
	asset.spritefont("font_titlecard")
	font.append("font_titlecard", "font_controls")
	
	scene.set("menu")
end

return _
