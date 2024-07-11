local object = {}

local framex = 196/2
local framey = 340/2

function object.init(self, scene)
	
	asset.sprite("test_gdportal", scene)
	
	self.sprites = {
		back = sprite.init(back, scene, "test_gdportal", {animation = "back"}),
		front = sprite.init(front, scene, "test_gdportal", {animation = "front"}),
		detail = sprite.init(detail, scene, "test_gdportal", {animation = "detail"}),
		icon = sprite.init(icon, scene, "test_gdportal", {animation = "icon"}),
	}
	
	local scalex = self.scalex or self.scale or 1; scalex = math.abs(scalex)
	local scaley = self.scaley or self.scale or 1; scaley = math.abs(scaley)
	
	self.ref = collision.init(self.collision, "ref",
		{x = self.x - (framex * scalex),
		y = self.y - (framey * scaley),
		rect = {width = 196 * scalex, height = 340 * scaley}}
	)
	
	self.canvas = {
		back = love.graphics.newCanvas(196, 340),
		front = love.graphics.newCanvas(196, 340),
	}
	
	--HotParticles
	self.particles = love.graphics.newParticleSystem(scene.assets["test_gdportal"]["particle"][1], 24)
	self.particles:setColors(0, 1, 1, 0.5)
	self.particles:setEmissionRate(30)
	self.particles:setOffset(16, 16)
	self.particles:setParticleLifetime(0.4, 0.8)
	self.particles:setRadialAcceleration(-195, -255)
	self.particles:setSizeVariation(0.33)
	self.particles:setSpeed(130, 170)
	self.particles:setSpread(0.87)
	
end

function object.update(self, scene)
	local scalex = self.scalex or self.scale or 1
	local scaley = self.scaley or self.scale or 1
	
	self.particles:setEmissionArea("uniform", 32*scalex, 128*scaley)
	self.particles:setSizes(0.75*scalex, 0.1*scalex)
	self.particles:update(dt)
	
	for k,v in pairs(self.sprites) do sprite.update(v, scene) end
end

function object.draw(self, scene)	
	
	self.canvas.back:renderTo(function()
		love.graphics.clear()
		sprite.draw(self.sprites.back, scene, {queued = false, ignorescale = true})
	end)
	self.canvas.front:renderTo(function()
		love.graphics.clear()
		sprite.draw(self.sprites.front, scene, {queued = false, ignorescale = true})
		sprite.draw(self.sprites.detail, scene, {queued = false, ignorescale = true})
		sprite.draw(self.sprites.icon, scene, {queued = false, ignorescale = true})
	end)
	
	local x = self.x or 0
	local y = self.y or 0
	local angle = self.angle or 0; angle = math.rad(angle)
	local scalex = self.scalex or self.scale or 1
	local scaley = self.scaley or self.scale or 1
	local rgb = self.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = self.opacity or 100; opacity = opacity/100
	
	local pwidth, pheight = 32*scalex, 128*scaley
	local px, py = point.rotate((x - 64 - pwidth - (pwidth/2)), y, math.deg(angle), x, y)
	
	queue.add(scene.drawlist, -1, function()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		love.graphics.draw(self.canvas.back, x, y, angle, scalex, scaley, framex, framey)
		
		love.graphics.setBlendMode("add")
		love.graphics.draw(self.particles, px, py, angle)
		love.graphics.reset()
	end)
	queue.add(scene.drawlist, 2, function()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		love.graphics.draw(self.canvas.front, x, y, angle, scalex, scaley, framex, framey)
		love.graphics.reset()
	end)
	
end

return object
