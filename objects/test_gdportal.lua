local object = {}

local framex = 196/2
local framey = 340/2

function object.init(self)
	
	asset.sprite("test_gdportal")
	
	self.sprites = {}
	self.sprites.back = sprite.init(self.sprites.back, "test_gdportal", {frame = 1})
	self.sprites.front = sprite.init(self.sprites.front, "test_gdportal", {frame = 2})
	self.sprites.detail = sprite.init(self.sprites.detail, "test_gdportal", {frame = 3})
	self.sprites.icon = sprite.init(self.sprites.icon, "test_gdportal", {frame = 4})
	
	local scalex = self.scalex or self.scale or 1; scalex = math.abs(scalex)
	local scaley = self.scaley or self.scale or 1; scaley = math.abs(scaley)
	
	self.ref = collision.init(self.collision, "ref",
		{x = self.x - (framex * scalex),
		y = self.y - (framey * scaley),
		rect = {width = 196 * scalex, height = 340 * scaley}}
	)
	
	self.canvas = {}
	self.canvas.back = love.graphics.newCanvas(196, 340)
	self.canvas.front = love.graphics.newCanvas(196, 340)
	
end

function object.update(self)
	sprite.update(self.sprites.back)
	sprite.update(self.sprites.front)
	sprite.update(self.sprites.detail)
	sprite.update(self.sprites.icon)
end

function object.draw(self)	
	
	self.canvas.back:renderTo(function()
		love.graphics.clear()
		sprite.draw(self.sprites.back, false)
	end)
	self.canvas.front:renderTo(function()
		love.graphics.clear()
		sprite.draw(self.sprites.front, false)
		sprite.draw(self.sprites.detail, false)
		sprite.draw(self.sprites.icon, false)
	end)
	
	local x = self.x or 0
	local y = self.y or 0
	local angle = self.angle or 0; angle = math.rad(angle)
	local scalex = self.scalex or self.scale or 1
	local scaley = self.scaley or self.scale or 1
	local rgb = self.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = self.opacity or 100; opacity = opacity/100
	
	queue.add(scenes.drawlist, -1, function()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		love.graphics.draw(self.canvas.back, x, y, angle, scalex, scaley, framex, framey)
		love.graphics.reset()
	end)
	queue.add(scenes.drawlist, 2, function()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		love.graphics.draw(self.canvas.front, x, y, angle, scalex, scaley, framex, framey)
		love.graphics.reset()
	end)
	
end

return object
