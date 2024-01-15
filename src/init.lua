require("src/libs/errorhandler")
require("src/libs/df-serialize")
require("src/libs/json")
require("src/libs/gifload")
require("src/libs/gltf")

require("src/utils")
require("src/input")
require("src/collisions")
require("src/assets")
require("src/scene")

require("src/yui")
require("src/imgui")

---------------------------------------------------------------- 

_VERSION_major, _VERSION_minor = string.match(_VERSION, "Lua (%d+)%.(%d+)")

love.version = "LOVE2D "..love._version_major.."."..love._version_minor.."."..love._version_revision.." (Lua ".._VERSION_major..".".._VERSION_minor..")"

time_start = os.time()
allow_update = true
ms = 0 
frames = 0

love.graphics.setDefaultFilter("nearest","nearest",0)
love.graphics.setLineStyle("rough")
love.graphics.setBackgroundColor(8/255,8/255,8/255)

print(love.version.." | onee "..version)

---------------------------------------------------------------- 

misc = {}

function misc.update_start()
	before_update = (before_update or 0) + (1 / framerate)
end

function misc.draw_end()
	love.graphics.reset()
	
	after_draw = love.timer.getTime()
	if before_update <= after_draw then before_update = after_draw end
	love.timer.sleep(before_update - after_draw)
end

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
	debug_draw_sprites = false
	
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
love.keypressed = debug.keypressed

function debug.update()
	if not debug_mode then return end
end
			a = {{0,0}, {100,10}, {50,100}, {60,30}}
			local ox = 50
			local oy = 50

function debug.draw()
	if not debug_mode then return end
	debug.drawlist = {}
	
	if mobile then
		love.graphics.print(love.timer.getFPS(), windowwidth-18, 4)
		
		for i,id in ipairs(love.touch.getTouches()) do
			local touchx, touchy = love.touch.getPosition(id)
			love.graphics.line(touchx-12,touchy, touchx+12,touchy)
			love.graphics.line(touchx,touchy-12, touchx,touchy+12)
		end
	end
	
	for id in pairs(instances) do
		local function draw_recursively(arg)
			for k, v in pairs(arg) do
				if type(v) == "table" then
					if debug_draw_collisions and arg[k].collision == true then
						queue.add(debug.drawlist, 1, function()
							collision.debug_draw(arg[k])
						end)
					elseif debug_draw_sprites and arg[k].sprite == true then
						queue.add(debug.drawlist, 2, function()
							sprite.debug_draw(arg[k])
						end)
					-- skip 3d models, they cause a stack overflow
					elseif arg[k].model ~= true then
						draw_recursively(arg[k])
					end
				end
			end
		end
		
		draw_recursively(instances[id])
	end
	
	queue.execute(debug.drawlist)
	
	local angle = (angle or 0) + 0.15
	--b = collision.poly.move(a, angle, angle, ox, oy)
	--b = collision.poly.rotate(a, angle, ox, oy)
	
	--love.graphics.polygon("line", collision.poly.unpack(b))
	--love.graphics.line(mousex-16,mousey, mousex+24,mousey+32)
	
	--print(collision.poly_line(b, mousex-16,mousey, mousex+24,mousey+32))
	
end