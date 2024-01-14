local object = {}

function object.init(self)
	self.collision = collision.init(self.collision, "collision",
		{x = self.x or 0, y = self.y or 0, rect = {width = self.width or 32, height = self.height or 32}}
	)
end

function object.update(self)
	local check_down, col_down = collision.check(self.collision, "player", "collider_down")
	local check_left, col_left = collision.check(self.collision, "player", "collider_left")
	local check_right, col_right = collision.check(self.collision, "player", "collider_right")
	
	if check_left then 
		local player = instances[col_left.instance].player
		player.x = self.collision.x + self.collision.rect.width + 8
		player.x_speed = 0
	end
	if check_right then 
		local player = instances[col_right.instance].player
		player.x = self.collision.x - 8
		player.x_speed = 0
	end
	
	if check_down and not (check_left or check_right) then 
		local player = instances[col_down.instance].player
		if player.y_speed > 0 and not player.ground then
			player.ground = true
			player.y = self.collision.y - 32
			--player.y_speed = 0
		end
	end
	
end

function object.draw(self)
	love.graphics.rectangle("fill", self.collision.x, self.collision.y, self.collision.rect.width, self.collision.rect.height)
end

return object
