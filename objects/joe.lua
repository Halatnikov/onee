local object = {}

local player = {
	acc = 4/2,
	gravity = 0.5,
	jump = 10,
	y_max = 12/2,
	
	facing = 1,
	x_speed = 0,
	y_speed = 0,
	ground = false,
	jumping = false,
	
	state = "normal",
	animation = "idle",
}

----------------------------------------------------------------
local states = {}

states.normal = function()
	--temp
	if player.y > 200 then player.ground = true; player.y = 200 end
	if love.keyboard.isDown("lshift") then player.x, player.y = window.mouse(); player.ground = false end
	if input.pressed.b then player.state = "die" end
	
	-- begin loop
	player.x_speed = 0
	player.facing = input.right and 1 or input.left and -1 or player.facing

	-- acceleration
	if input.left or input.right then		
		player.x_speed = player.acc * player.facing
	end

	-- jumping
	if input.pressed.a and player.ground then
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
		player.y_speed = math.min(player.y_speed + player.gravity, player.y_max)
	end

	-- animation handling
	player.animation = "idle"
	if (input.left or input.right) and player.ground then player.animation = "walk" end
end

----------------------------------------------------------------

states.die = function()
	if not (player.animation == "die") then
		player.y_speed = -player.jump
	end

	player.x_speed = 0
	player.facing = 1
	player.animation = "die"
	player.ground = false

	player.y_speed = math.min(player.y_speed + player.gravity, player.y_max)
end

----------------------------------------------------------------

function object.init(self, scene)
	self.player = player
	self.states = states
	
	player.x = math.random(100,400)
	player.y = 200
	
	local skin = "scruffy"
	asset.sprite("characters/"..skin, scene)
	self.sprite = sprite.init(self.sprite, scene, skin)
	self.sprite.z = 1
	
	self.hitbox = collision.init(self.hitbox, "hitbox", {rect = {width = 25, height = 58}})
	
	self.collider = {
		up = collision.init(down, "collider_up", {line = {}}),
		left = collision.init(left, "collider_left", {line = {}}),
		right = collision.init(right, "collider_right", {line = {}}),
		down = collision.init(down, "collider_down", {line = {}}),
	}

end

function object.update(self, scene)
	states[player.state]()
	
	player.x = player.x + player.x_speed
	player.y = player.y + player.y_speed
	
	-- update sprite
	self.sprite.x = player.x
	self.sprite.y = player.y
	self.sprite.scalex = player.facing
	self.sprite.animation = player.animation
	sprite.update(self.sprite, scene)
	
	-- update colliders
	self.hitbox.x = (player.x - 16) + 4
	self.hitbox.y = (player.y - 32) + 6
	
	self.collider.up.x = self.hitbox.x + 1
	self.collider.up.y = self.hitbox.y
	self.collider.up.line.x = self.hitbox.x + 25 - 1
	self.collider.up.line.y = self.hitbox.y
	
	self.collider.left.x = self.hitbox.x
	self.collider.left.y = self.hitbox.y + 1
	self.collider.left.line.x = self.hitbox.x
	self.collider.left.line.y = self.hitbox.y + 58 - 1
	
	self.collider.right.x = self.hitbox.x + 25
	self.collider.right.y = self.hitbox.y + 1
	self.collider.right.line.x = self.hitbox.x + 25
	self.collider.right.line.y = self.hitbox.y + 58 - 1
	
	self.collider.down.x = self.hitbox.x + 1
	self.collider.down.y = self.hitbox.y + 58
	self.collider.down.line.x = self.hitbox.x + 25 - 1
	self.collider.down.line.y = self.hitbox.y + 58
	
	-- end loop
	--player.ground = false
	
end

function object.draw(self, scene)
	
	sprite.draw(self.sprite, scene)
	
end

return object
