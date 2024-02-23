--- Implements a static label widget
--
-- @classmod yui.Label
-- @copyright 2022, The DoubleFourteen Code Forge
-- @author Lorenzo Cogotti, Andrea Pasquini

local BASE = (...):gsub('label$', '')

local Widget = require(BASE..'widget')
local core = require(BASE..'core')

-- Labels don't accept focus
local Label = setmetatable({
    nofocus = true,
    __call = function(cls, args) return cls:new(args) end
}, Widget)
Label.__index = Label

--- Attributes accepted by the @{Label} widget in addition to the standard @{yui.Widget.WidgetAttributes|attributes}.
--
-- @field text (string) text displayed inside the Label
-- @field[opt='center'] valign (string) vertical alignment 'top', 'bottom', 'center'
-- @field[opt='center'] align (string) horizontal alignment, 'left', 'center', 'right'
-- @table LabelAttributes

--- Label constructor
-- @param args (@{LabelAttributes}) widget attributes
function Label:new(args)
    self = setmetatable(args, self)

    self.text = self.text or ""
    self.align = self.align or 'center'
    self.valign = self.valign or 'center'
	self.focus = self.focus or false
	
    return self
end

function Label:onPointerInput(_,_, clicked)
    if self.focus then self:grabFocus() end
end

function Label:draw()
    local x,y,w,h = self.xx or self.x, self.yy or self.y, self.w, self.h
    local color, font, cornerRadius, spritefont = core.themeForWidget(self)


	if not spritefont then
		y = y + core.verticalOffsetForAlign(self.valign, font, h)
		
		love.graphics.setColor(color.normal.fg)
		love.graphics.setFont(font)
		love.graphics.printf(self.text, x+2, y, w-4, self.align)
	end
	
	if spritefont then
		love.graphics.setColor(color.normal.fg)
		text.printf(self.text, spritefont, x+2, y, w-4, self.align, self.valign)
	end
	
end

return Label
