local scene_ = scene
local scene = {}

function scene.init(self)
	window.update() -- init window
	
	-- init fonts
	fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16, "mono", 2)
	fonts.proggy_clean:setFilter("nearest")
	onee.font = fonts.proggy_clean -- set default font
	
	asset.spritefont("font_controls")
	
	asset.spritefont("font_12")
	font.append("font_12", "font_controls")
	
	asset.spritefont("font_16")
	font.append("font_16", "font_controls")
	
	asset.spritefont("font_titlecard")
	
	scene_.set("menu")
end

return scene
