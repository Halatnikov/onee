local scene_ = scene
local scene = {}

function scene.init(self)
	window.update() -- init window
	
	-- init fonts
	fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16, "mono", 2)
	fonts.proggy_clean:setFilter("nearest")
	
	fonts.freaks12 = love.graphics.newFont("fonts/freaks12.fnt")
	fonts.freaks16 = love.graphics.newFont("fonts/freaks16.fnt")
	
	onee.font = fonts.proggy_clean -- set default font
	
	scene_.set("menu")
end

return scene
