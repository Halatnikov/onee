local scene_ = scene
local scene = {}

function scene.init(self)
	window.update() -- init window
	
	-- init fonts
	fonts.proggy_clean = love.graphics.newFont("fonts/proggy_clean.fnt")
	
	fonts.controls = love.graphics.newFont("fonts/controls.fnt")
	text.icons("controls")
	
	fonts.freaks12 = love.graphics.newFont("fonts/freaks12.fnt")
	fonts.freaks12:setFallbacks(fonts.controls)
	
	fonts.freaks16 = love.graphics.newFont("fonts/freaks16.fnt")
	fonts.freaks16:setFallbacks(fonts.controls)
	
	fonts.titlecard = love.graphics.newFont("fonts/titlecard.fnt")
	
	onee.font = fonts.proggy_clean -- set default font
	
	scene_.set("menu")
end

return scene
