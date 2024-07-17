--- Local drawing helpers
--
-- @module yui.core
-- @copyright 2022, The DoubleFourteen Code Forge
-- @author Lorenzo Cogotti, Andrea Pasquini

local core = {}

-- Helpers for drawing
function core.verticalOffsetForAlign(valign, font, h)
    if valign == 'top' then
        return 0
    elseif valign == 'bottom' then
        return h - font:getHeight()
    end
    -- else: 'middle'
    return (h - font:getHeight()) / 2
end

function core.themeForWidget(widget)
    local uiTheme = widget.ui.theme
    local theme = widget.theme or uiTheme

    local color = theme.color or uiTheme.color
    local font = theme.font or uiTheme.font or love.graphics.getFont()
    local cornerRadius = theme.cornerRadius or uiTheme.cornerRadius
	local spritefont = theme.spritefont or uiTheme.spritefont

    return color, font, cornerRadius, spritefont
end

function core.colorForWidgetState(widget, color)
    color = color or widget.theme.color or widget.ui.theme.color

    if widget.active then
        return color.active
    elseif widget:isFocused() then
        return color.hovered
    else
        return color.normal
    end
end

function core.drawBox(x,y,w,h, color, cornerRadius)
    w = math.max(cornerRadius/2, w)
    if h < cornerRadius/2 then
        y,h = y - (cornerRadius - h), cornerRadius/2
    end

    love.graphics.setColor(color.bg)
    love.graphics.rectangle('fill', x,y, w,h, cornerRadius)
end

-- Calculate and return the union of two rectangles.
function core.rectunion(x1,y1,w1,h1, x2,y2,w2,h2)
    local xw1,yh1, xw2,yh2

    if w1 < 0 or h1 < 0 then
        local huge = math.huge

        x1,y1,xw1,yh1 = huge,huge,-huge,-huge
    else
        xw1,yh1 = x1 + w1,y1 + h1
    end
    if w2 < 0 or h2 < 0 then
        local huge = math.huge

        x2,y2,xw2,yh2 = huge,huge,-huge,-huge
    else
        xw2,yh2 = x2 + w2,y2 + h2
    end

    x1  = math.min(x1, x2)
    y1  = math.min(y1, y2)
    xw1 = math.max(xw1, xw2)
    yh1 = math.max(yh1, yh2)

    return x1, y1, xw1 - x1, yh1 - y1
end

-- Test whether point (x,y) lies inside a rectangle.
function core.pointinrect(x,y, rx,ry,rw,rh)
    return x >= rx and y >= ry and x-rx <= rw and y-ry <= rh
end

-- Test whether 'obj' is an instance of the given class 'cls'.
function core.isinstance(obj, cls)
    if rawequal(cls, nil) then return rawequal(obj, nil) end

    repeat
        local m = getmetatable(obj)
        if rawequal(m, cls) then return true end

        obj = m
    until rawequal(obj, nil)

    return false
end

return core
