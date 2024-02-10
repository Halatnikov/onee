local scene_ = scene
local scene = {}

function scene.init(self)
	window.update() -- init window
	
	fonts.proggy_clean = love.graphics.newFont("fonts/ProggyClean.ttf", 16, "mono", 2)
	fonts.proggy_clean:setFilter("nearest")
	
	onee.font = fonts.proggy_clean -- set default font
	
	scene_.set("menu")
end

return scene
