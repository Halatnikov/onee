local object = {}

function object.init(self, scene)
	self.collision = collision.init(self.collision, "collision",
		{x = self.x or 0, y = self.y or 0, rect = {width = self.width or 32, height = self.height or 32}}
	)
end

function object.update(self, scene)
	local check_down, col_down = collision.check(self.collision, "player", "collider_down")
	local check_left, col_left = collision.check(self.collision, "player", "collider_left")
	local check_right, col_right = collision.check(self.collision, "player", "collider_right")
	local player
	
	if check_left then 
		player = instances[col_left.instance].player
		player.x_speed = 0
		player.x = self.collision.x + self.collision.rect.width + 8
	end
	if check_right then 
		player = instances[col_right.instance].player
		player.x_speed = 0
		player.x = self.collision.x - 8
	end
	
	if check_down and not (check_left or check_right) then 
		player = instances[col_down.instance].player
		if player.y_speed > 0 and not player.ground then
			player.ground = true
			player.y = self.collision.y - 32
			--player.y_speed = 0
		end
	end
	if check_down ~= true and type(player) == "table" and player.ground == true then player.ground = false end
	
end

function object.draw(self, scene)
	love.graphics.rectangle("fill", self.collision.x, self.collision.y, self.collision.rect.width, self.collision.rect.height)
end

return object
