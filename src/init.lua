require("src/libs/errorhandler")
require("src/libs/tserial")
require("src/libs/json")
loveframes = require("src/libs/loveframes")
gifload = require("src/libs/gifload")
gltf = require("src/libs/gltf")

require("src/utils")
require("src/gui")
require("src/nuklear")

require("src/input")
require("src/collisions")
require("src/assets")
require("src/scene")

---------------------------------------------------------------- 

local major, minor, revision = love.getVersion()
love.version = "LOVE2D "..major.."."..minor.."."..revision.." (".._VERSION..")"

if love._os == "Android" or love._os == "iOS" then
	mobile = true
end

love.graphics.setDefaultFilter("nearest","nearest",0)
love.graphics.setBackgroundColor(8/255,8/255,8/255)

before_update = 0
ms = 0 
frames = 0

---------------------------------------------------------------- 

misc = {}

function misc.update()
	dt = love.timer.getDelta()
	fps = 1/dt
	ms = ms + dt
	frames = frames + 1
	
	windowwidth = love.graphics.getWidth()
	windowheight = love.graphics.getHeight()
	mousex = love.mouse.getX()
	mousey = love.mouse.getY()
end

---------------------------------------------------------------- 

if debug_mode then
	love.setDeprecationOutput(true)
	
	gui.open.debug()
	if ui then nuklear.open.debug = true end
	
	function debug.keypressed(k)
		if k == "f2" then love.event.quit("restart") end
		--if k == "`" or k == "f1" then nuklear.open.debug = not nuklear.open.debug end
		
		if k == "q" or k == "f3" then scenes.set("init") end
	end
end

function debug.update()
	
end

function debug.draw()
	if mobile then
		love.graphics.print(love.timer.getFPS(), windowwidth-18, 4)
		
		for i,id in ipairs(love.touch.getTouches()) do
			local touchx, touchy = love.touch.getPosition(id)
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	
	--print(collision.line_circ(mousex, mousey, mousex+48, mousey+128, windowwidth/2, windowheight/2, 48))
	love.graphics.circle("line", windowwidth/2, windowheight/2, 48)
	love.graphics.line(mousex, mousey, mousex+48, mousey+128)
	
end
