local object = {}

function object.init(self, scene)
	
	self.player = {
		x_speed = 0,
		y_speed = 0,
		
		acc = 0.3,
		acc_air = 0.3,
		dec = 0.25,
		dec_air = 0.25,
		gravity = 0.25,
		friction = 0.3,
		friction_air = 0.96875,
		
		jump = 7.15,
		x_max = 3,
		y_max = 6,
		
		facing = 1,
		allow_facing = true,
		ground = false,
		jumping = false,
		
		state = "",
		
		animation = "idle",
	}
	
	local player = self.player
	
	player.x = math.random(100,400)
	player.y = 200
	
	local skin = "1u_scruffy"
	asset.sprite(skin, scene)
	self.sprite = sprite.init(self.sprite, scene, skin)
	self.sprite.z = 1
	
	self.hitbox = collision.init(self.hitbox, "hitbox", {rect = {width = 16, height = 32}})
	
	self.collider = {
		down = collision.init(down, "collider_down", {line = {}}),
		left = collision.init(left, "collider_left", {line = {}}),
		right = collision.init(right, "collider_right", {line = {}}),
	}

end

function object.update(self, scene)
	local player = self.player
	
	-- acceleration
	if input.left ~= input.right then
		player.facing = math.bool(input.right) - math.bool(input.left)
		
		if player.ground then
			player.x_speed = player.x_speed + (player.acc * player.facing)
		else
			player.x_speed = player.x_speed + (player.acc_air * player.facing)
		end
	end
	
	-- deceleration
	if math.abs(player.x_speed) > 0 and input.left == input.right then
		if player.ground then
			player.x_speed = player.x_speed + (player.dec * -math.sign(player.x_speed))
		else
			player.x_speed = player.x_speed + (player.dec_air * -math.sign(player.x_speed))
		end
	end
	
	-- friction
	if input.left == false and input.right == false then
		if player.ground then
			player.x_speed = player.x_speed - math.min(math.abs(player.x_speed), player.friction * math.sign(player.x_speed))
		else
			player.x_speed = player.x_speed * player.friction_air
		end
	end

	-- jumping
	if input.a and input.time.a < 8 and player.ground then
		player.y_speed = -player.jump
		player.jumping = true
		
		player.ground = false
	end
	
	-- landing
	if player.ground then
		player.y_speed = 0
		player.jumping = false
	end
	
	-- falling
	if not player.ground then
		local gravity = (input.a and player.y_speed < -1) and player.gravity or player.gravity * 2
		player.y_speed = player.y_speed + gravity
	end
	
	-- limit speed
	player.x_speed = math.clamp(-player.x_max, player.x_speed, player.x_max)
	player.y_speed = math.clamp(-player.y_max, player.y_speed, player.y_max)
	
	-- update position
	player.x = player.x + player.x_speed
	player.y = player.y + player.y_speed
	
	-- animation handling
	if player.ground and player.x_speed == 0 then player.animation = "idle" end
	if player.ground and player.x_speed ~= 0 then
		player.animation = "walk"
		if input.left and player.x_speed > 0 then player.animation = "skid"; player.facing = 1 end
		if input.right and player.x_speed < 0 then player.animation = "skid"; player.facing = -1 end
	end
	if player.jumping then player.animation = "jump" end
	if not player.jumping and not player.ground then player.animation = "fall" end
	
	player.allow_facing = true
	if player.allow_facing then 
		self.sprite.scalex = player.facing
		if player.animation == "skid" then player.allow_facing = false end
	end
	
	if player.animation == "skid" then
		if input.left == input.right and math.abs(player.x_speed) < 0.2 then player.animation = "idle" end
	end
	
	--temp
	if love.keyboard.isDown("lshift") then player.x, player.y = window.mouse() ; player.ground = false end
	
	-- update sprite
	self.sprite.x = player.x
	self.sprite.y = player.y
	self.sprite.animation = player.animation
	sprite.update(self.sprite, scene)
	
	-- update collision
	self.hitbox.x = player.x - 8
	self.hitbox.y = player.y - 12
	
	self.collider.left.x = player.x - 8
	self.collider.left.y = player.y - 16
	self.collider.left.line.x = player.x - 8
	self.collider.left.line.y = player.y + 16
	
	self.collider.right.x = player.x + 8
	self.collider.right.y = player.y - 16
	self.collider.right.line.x = player.x + 8
	self.collider.right.line.y = player.y + 16
	
	self.collider.down.x = player.x - 8
	self.collider.down.y = player.y + 32
	self.collider.down.line.x = player.x + 8
	self.collider.down.line.y = player.y + 32
	
	-- end loop
	--player.ground = false
	
end

function object.draw(self, scene)
	
	sprite.draw(self.sprite, scene)
	
end

return object
