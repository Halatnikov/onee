require("src/utils")
require("src/nuklear")

require("src/input")
require("src/assets")
require("src/scene")

require("src/libs/tserial")


local major, minor, revision = love.getVersion()
love.version = "LOVE2D "..major.."."..minor.."."..revision.." (".._VERSION..")"

before_update = 0
ms = 0 
frames = 0


misc = {}

function misc.update()
	dt = love.timer.getDelta()
	fps = 1/dt
	ms = ms + dt
	frames = frames + 1
	
	if debug_mode then debug.update() end
end


if debug_mode then
	nuklear.open.debug = true
	
	function debug.keypressed(k)
		if k == "f2" then love.event.quit("restart") end
		if k == "`" or k == "f1" then nuklear.open.debug = not nuklear.open.debug end
		
		if k == "q" or k == "f3" then scenes.set("init") end
	end

end

function debug.update()
	
end
