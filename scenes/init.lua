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
	asset.spritefont("font_16")
	asset.spritefont("font_titlecard")
	
	scene.set("menu")
end

return _
