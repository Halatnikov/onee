local scene_ = scene
local scene = {}

local gui = yui_

function scene.init(self)
	asset.sprite("spr_menu_arrow_16", self)
	self.arrow = sprite.init(self.arrow, self, "spr_menu_arrow_16")
	
	yui.open.test = true
end

function scene.close(self)
	yui.open.test = nil
end

function yui.new.test()
	local width, height = onee.width, 20
	local padding = 4
	
	local theme = {
		cornerRadius = 0,
		font = nil,
		color = {
			normal = {bg = {0,0,0,0}, fg = {1,1,1}},
			hovered = {bg = {0,0,0,0}, fg = {1,1,1}},
			active = {bg = {0,0,0,0}, fg = {1,1,1}}
		}
	}
	
	local ui = {
		x = 32, y = 32, theme = theme,
		gui.Rows {
			padding = padding,
		},
	}
	
	local scenes = files.listdir("scenes")
	
	for i=1, #scenes do
		local name = string.remove(scenes[i], "scenes/", ".lua")
		local option = gui.Button {
			w = width, h = height, align = "left",
			text = name,
			onHit = function()
				scene_.set(name)
			end,
		}
		table.insert(ui[1], option)
	end
	
	return gui.Ui:new(ui)
end

function scene.update(self)
	sprite.update(self.arrow, self)
end

function scene.draw(self)
	if yui.test then
		for i=1, #yui.test[1] do
			local item = yui.test[1][i]
			if item.hovered then
				gradient("horizontal", {
					{0, 1, 1, 0.25},
					{0, 0, 0, 0},
				}, 0, item.y, 0, onee.width, item.h)
				self.arrow.x = 4+8+4
				self.arrow.y = item.y+8+(4/2)
				sprite.draw(self.arrow, self)
			end
		end
	end
end

return scene
