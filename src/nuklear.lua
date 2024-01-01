nuklear = {
	open = {},
	window = {},
}

-- init
if love._os == "Windows" then 
	ui = require("nuklear").newUI()
end

-- event redirection
function nuklear.keypressed(key, scancode, isrepeat)
	if not ui then return end
	if ui:keypressed(key, scancode, isrepeat) then return end 
end
function nuklear.keyreleased(key, scancode)
	if not ui then return end
	if ui:keyreleased(key, scancode) then return end
end
function nuklear.mousepressed(x, y, button, istouch, presses)
	if not ui then return end
	if ui:mousepressed(x, y, button, istouch, presses) then return end
end
function nuklear.mousereleased(x, y, button, istouch)
	if not ui then return end
	if ui:mousereleased(x, y, button, istouch) then return end
end
function nuklear.mousemoved(x, y, dx, dy, istouch)
	if not ui then return end
	if ui:mousemoved(x, y, dx, dy, istouch) then return end
end
function nuklear.textinput(text)
	if not ui then return end
	if ui:textinput(text) then return end
end
function nuklear.wheelmoved(x, y)
	if not ui then return end
	if ui:wheelmoved(x, y) then return end
end

-- main loop
function nuklear.update()
	if not ui then return end
	ui:frameBegin()
		if nuklear.open.debug then nuklear.window.debug() end
	ui:frameEnd()
end
function nuklear.draw()
	if not ui then return end
	ui:draw()
end


function nuklear.table(arg, caption, show_functions)
	ui:tree("tab", caption,
	function ()
		for k,v in pairs(arg) do
			if type(k) == "table" then nuklear.table(k, tostring(k), show_functions) end
			if type(k) ~= "table" then
				if not v then ui:label(tostring(k)) end
				if v then
					if type(v) == "table" then nuklear.table(v, tostring(k), show_functions) end
					if type(v) ~= "table" then
						if not show_functions then
							if type(v) ~= "function" then nuklear.table_label(k,v) end
						else
							nuklear.table_label(k,v)
						end
					end
				end
			end
		end
	end)
end

function nuklear.table_label(k,v)
	if type(v) ~= "userdata" then ui:label(tostring(k)..": "..tostring(v)) end
	if type(v) == "userdata" then
		if v.type and v:type() == "Image" then
			ui:layoutRow('dynamic', 32, 6)
			ui:image(v)
		end
	end
end

local draw_collisions = {value = true}

function nuklear.window.debug()
	ui:window("v"..version,
		500, 100, 300, 300,
		'border', 'title', 'movable', 'scalable', 'minimizable', 'scrollbar', 'scroll auto hide',
	function ()
		
		ui:layoutRow('dynamic', 12, 1)
		ui:label("FPS "..love.timer.getFPS().." "
				..math.round(fps,2).." "
				..math.round(1000*love.timer.getAverageDelta(),2).."ms")
		
		ui:label(windowwidth.."x"..windowheight)
		
		ui:layoutRow('dynamic', 18, 2)
		local reload = ui:button("Reload")
		if reload then love.event.quit("restart") end
		
		local reset_scene = ui:button("Reset scene")
		if reset_scene then scenes.set("init") end
		
		ui:checkbox("Draw collisions", draw_collisions)
		--debug_draw_collisions = draw_collisions.value
		
		nuklear.table(_G, "Global variables", true)
		
		ui:tree("tab","Performance", function ()
			local stats = love.graphics.getStats()
			local renderer = {}; renderer.name, renderer.version, renderer.vendor, renderer.device = love.graphics.getRendererInfo()
			
			ui:layoutRow('dynamic', 16, 1)
			ui:label("Timer "..math.round(ms,2).." "..frames.." "..math.round(love.timer.getTime(),2))
			ui:label("dt "..math.round(dt,4).." "..math.round(1000*dt,2).."ms")
			if ui:widgetIsHovered() then ui:tooltip('Textures and garbage collector') end
			ui:label("RAM "..math.round(stats.texturememory/1024/1024,2).."MB "..math.round(collectgarbage("count")/1024,2).."MB")
			
			nuklear.table(stats,"love.graphics.getStats()")
			nuklear.table(renderer,"love.graphics.getRendererInfo()")
			nuklear.table(love.graphics.getSystemLimits(),"love.graphics.getSystemLimits()")
		end)
		
		ui:tree("tab","Input: "..input.mode, function ()
			ui:layoutRow('dynamic', 16, 1)
			ui:label("Input mode: "..input.mode)
			ui:label("Mouse "..mousex.." "..mousey.." "..input.mouse_wheel)
			for key in pairs(config.input.keyboard) do 
				ui:label(key.."   "..bool.int(input[key]).." "..input.time[key])
			end
		end)
		
		nuklear.table(scene, "Scene: "..scene.name, true)
		nuklear.table(objects, "Objects: "..table.length(objects), true)
		nuklear.table(instances, "Instances: "..table.length(instances), true)
		
		nuklear.table(assets, "Assets: "..table.length(assets), true)
		nuklear.table(sprites, "Sprites: "..table.length(sprites), true)
		nuklear.table(models, "Models: "..table.length(models), true)
		
	end)
end
