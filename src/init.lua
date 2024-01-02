require("src/libs/errorhandler")
require("src/libs/tserial")
require("src/libs/json")
--loveframes = require("src/libs/loveframes")
gifload = require("src/libs/gifload")
gltf = require("src/libs/gltf")

require("src/utils")
require("src/input")
require("src/collisions")
require("src/assets")
require("src/scene")

--require("src/gui")
--require("src/nuklear")
require("src/imgui")

---------------------------------------------------------------- 

local major, minor, revision = love.getVersion()
love.version = "LOVE2D "..major.."."..minor.."."..revision.." (".._VERSION..")"

if love._os == "Android" or love._os == "iOS" then
	mobile = true
end

love.graphics.setDefaultFilter("nearest","nearest",0)
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(8/255,8/255,8/255)

before_update = 0
allow_update = true
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
	
	debug_draw_collisions = true
	
	-- todo: init imgui here
	-- todo: on debug_mode disable, close all the ui
	-- todo: shortcut ` or f1 to open/close the debug window
	-- todo: something quick and dirty on loveframes for android
	--gui.open.debug()
	
end

function debug.keypressed(k)
	if not debug_mode then return end
	
	if k == "f2" then love.event.quit("restart") end
	
	if k == "q" or k == "f3" then scenes.set("init") end
end

function debug.update()
	if not debug_mode then return end
end
			local a = {{0,0}, {100,10}, {50,100}, {60,30}}
function debug.draw()
	if not debug_mode then return end
	
	if mobile then
		love.graphics.print(love.timer.getFPS(), windowwidth-18, 4)
		
		for i,id in ipairs(love.touch.getTouches()) do
			local touchx, touchy = love.touch.getPosition(id)
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	for i=1, #a do
		a[i][1] = a[i][1] + 0.3
		a[i][2] = a[i][2] + 0.3
	end
	
	local b = {}
	for i=1, #a do
		table.insert(b, a[i][1])
		table.insert(b, a[i][2])
	end
	
	--love.graphics.polygon("line", b)
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(a, mousex-16,mousey, mousex+24,mousey+32))
	
end
