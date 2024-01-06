local object = {}

function object.init(self)
	self.x = self.x or 0
	self.y = self.y or 0
	self.width = self.width or 32
	self.height = self.height or 32
	
	self.collision = collision.init(self.collision, "collision",
		{rect = {}}
	)
end

function object.update(self)
	self.collision.x = self.x
	self.collision.y = self.y
	self.collision.rect.width = self.width
	self.collision.rect.height = self.height
	
	local check_down, col_down = collision.check(self.collision, "player", "collider_down")
	local check_left, col_left = collision.check(self.collision, "player", "collider_left")
	local check_right, col_right = collision.check(self.collision, "player", "collider_right")
	
	if check_left then 
		local player = instances[col_left.instance].player
		player.x = self.x + self.width + 8
		player.x_speed = 0
	end
	if check_right then 
		local player = instances[col_right.instance].player
		player.x = self.x - 8
		player.x_speed = 0
	end
	
	if check_down and not (check_left or check_right) then 
		local player = instances[col_down.instance].player
		if not player.ground and player.y_speed > 0 then
			player.ground = true
			player.y = self.y - 32
			--player.y_speed = 0
		end
	end
	
	
end

function object.draw(self)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
end

return object
