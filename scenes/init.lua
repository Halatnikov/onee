local scene_ = scene
local scene = {}

function scene.init(self)
	-- init fonts
	fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16)
	fonts.proggy_clean:setFilter("nearest")
	onee.font = fonts.proggy_clean -- set default font
	
	asset.spritefont("font_controls")
	
	asset.spritefont("font_12")
	font.append("font_12", "font_controls")
	
	asset.spritefont("font_16")
	font.append("font_16", "font_controls")
	
	asset.spritefont("font_titlecard")
	font.append("font_titlecard", "font_controls")
	
	scene_.set("menu")
end

return scene
