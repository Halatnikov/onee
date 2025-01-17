local _ = Scene()
local gui = yui_

_.assets = {
	"menu_cursor",
}

_.transpatent = false
_.menu = {
	gui.Label {
		w = 192, h = 16, align = "center",
		text = "Invalid menu!",
	},
}

function _:init()
	asset.sprite("menu_cursor", self)
	
	self.cursor1 = sprite.init(self.cursor1, self, "menu_cursor", {scalex = -1})
	self.cursor2 = sprite.init(self.cursor2, self, "menu_cursor")
	
	local window = {
		x = 0, y = 0, 
		theme = {
			cornerRadius = 0,
			font = onee.persist.font,
			color = {
				normal = {bg = {0,0,0,0}, fg = {0,0,0}},
				hovered = {bg = {0,0,0,0}, fg = {0,0,0}},
				active = {bg = {0,0,0,0}, fg = {0,0,0}},
			}
		},
		
		init = function(self)
			local root = self[1]
			root.x, root.y = (onee.width/2) - root.w/2, (onee.height/2) - root.h/2
			root:layoutWidgets()
		end,
		
		gui.Rows {
			beforeDraw = function(self)
				love.graphics.setColor(1,1,1, self.transparent and 0.5 or 1)
				love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
				love.graphics.reset()
				
				_.cursor1.animation = self.ui.focused.choices and "arrow" or "idle"
				_.cursor2.animation = self.ui.focused.choices and "arrow" or "idle"
				_.cursor1.x, _.cursor1.y = self.x + 16, self.ui.focused.y
				_.cursor2.x, _.cursor2.y = self.x + self.w - 16, self.ui.focused.y
				sprite.draw(_.cursor1, _, {queued = false})
				sprite.draw(_.cursor2, _, {queued = false})
			end,
		},
	}
	
	table.append(window[1], self.menu)
	self.yui = yui.new(window)
end

function _:deinit()
	
end

function _:update()
	yui.update(self.yui)
end

function _:draw()
	yui.draw(self.yui, self)
end

return _
