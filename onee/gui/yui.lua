yui = {
	open = {},
	new = {},
}

-- init
local gui
do
	yui_ = require("onee/libs/yui")
	gui = yui_

	if mobile and debug_mode then yui.open.debug_button = true end
end

function yui.draw()
	-- individual UIs updates
	if yui.debug then
		love.graphics.setColor(0.1, 0.1, 0.1, 0.9)
		love.graphics.rectangle("fill", yui.debug.x, yui.debug.y, yui.debug.w, yui.debug.h, 4)
		love.graphics.reset()
		
		yui.debug[1][2].text = string.format("%02d %02.2f FPS %02.2fms", love.timer.getFPS(), fps, 1000*love.timer.getAverageDelta())
	end
	
	-- main loop
	for k,v in pairs(yui.open) do
		if not yui[k] then yui[k] = yui.new[k]() end
	end
	
	for k,v in pairs(yui) do
		if type(yui[k]) == "table" and yui[k].yui == true then
			if yui.open[k] == true then
				yui[k]:update(tick)
				yui[k]:draw()
			else
				yui[k] = nil
			end
		end
	end
end

-- UIs
function yui.new.debug_button()
	local ui = {
		x = onee.width-20-4, y = 4,
		gui.Rows {
			-- open debug menu
			gui.Button {
				w = 20, h = 20, nofocus = true,
				text = "+",
				onHit = function()
					yui.open.debug = true
					yui.open.debug_button = nil
				end,
			},
		},
	}
	
	return gui.Ui:new(ui)
end

function yui.new.debug()
	local width, height = 192, 20
	local padding = 4
	local ui = {
		x = onee.width-width-padding, y = padding,
		gui.Rows {
			-- close debug menu
			gui.Button {
				w = width, h = height, align = "right",
				text = onee.version.." -",
				onHit = function()
					yui.open.debug_button = true
					yui.open.debug = nil
				end,
			},
			-- fps, raw fps and dt
			gui.Label {
				align = "right",
				text = "",
			},
			gui.Columns {
				padding = padding,
				-- reload
				gui.Button {
					w = width/2 - padding/2, h = height,
					text = "Reload",
					onHit = function()
						love.event.quit("restart")
					end,
				},
				-- reset scene
				gui.Button {
					text = "Reset scene",
					onHit = function()
						scene.set(scenes[1].name)
					end,
				},
			},
			-- draw collisions
			gui.Checkbox {
				checked = debug_draw_collisions,
				text = "Draw collisions",
				onChange = function()
					debug_draw_collisions = not debug_draw_collisions
				end,
			},
			-- draw sprite bboxes
			gui.Checkbox {
				checked = debug_draw_sprites,
				text = "Draw sprite BBoxes",
				onChange = function()
					debug_draw_sprites = not debug_draw_sprites
				end,
			},
		},
	}
	
	return gui.Ui:new(ui)
end

_prof.hook("yui")