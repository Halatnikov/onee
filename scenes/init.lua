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
	
	asset.spritefont("font_12", {fallbacks = {"font_controls"}})
	
	asset.spritefont("font_16", {fallbacks = {"font_controls"}})
	
	asset.spritefont("font_titlecard", {fallbacks = {"font_controls"}})
	
	scene.set("menu")
end

return _
