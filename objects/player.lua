local object = {}

local player = {
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
	ground = true,
	jumping = false,
	
	state = "",
	
	animation = "idle",
}

function object.init(id)
	
	local startpos = instances[instances.get("startpos",true)]
	
	if startpos ~= nil then
		instances[id].x = startpos.x
		instances[id].y = startpos.y
	else
		instances[id].x = 0
		instances[id].y = 0
	end
	
end

function object.update(id)
	
	player_main(id)
	
	instances[id].animation.name = player.animation
	
	instances[id].player = player
	
	
end

function player_main(id)

	if input.left ~= input.right then
		player.facing = math.boolint(input.right)-math.boolint(input.left)
		if player.ground then
			player.x_speed = player.x_speed + (player.acc * player.facing)
		else
			player.x_speed = player.x_speed + (player.acc_air * player.facing)
		end
	end
	
	if math.abs(player.x_speed) > 0 and input.left == input.right then
		if player.ground then
			player.x_speed = player.x_speed + (player.dec * -math.sign(player.x_speed))
		else
			player.x_speed = player.x_speed + (player.dec_air * -math.sign(player.x_speed))
		end
	end
	
	if player.ground then
		if input.left == false and input.right == false then
			player_apply_friction()
		end
	end
			
	if input.a and player.ground then
		player.y_speed = -player.jump
		player.ground = false; player.jumping = true
	end
	
	if not player.ground then
		if input.a then
			player.y_speed = player.y_speed + player.gravity
		else
			player.y_speed = player.y_speed + (player.gravity*2)
		end
	end
	
	if player.ground then
		player.y_speed = 0; player.jumping = false
	end
	
	player.x_speed = math.clamp(player.x_speed,-player.x_max,player.x_max)
	player.y_speed = math.clamp(player.y_speed,-player.y_max,player.y_max)
	
	instances[id].x = instances[id].x + player.x_speed
	instances[id].y = instances[id].y + player.y_speed
	
	if instances[id].y > 120 then player.ground = true else player.ground = false end
	
	player.allow_facing = true
	if player.allow_facing then 
		instances[id].scalex = player.facing 
		if player.animation == "skid" then player.allow_facing = false end
	end
	
	if player.ground and player.x_speed == 0 then player.animation = "idle" end
	if player.ground and player.x_speed ~= 0 then
		player.animation = "walk"
		if input.left and player.x_speed > 0 then player.animation = "skid"; instances[id].scalex = 1 end
		if input.right and player.x_speed < 0 then player.animation = "skid"; instances[id].scalex = -1 end
	end
	if player.jumping then player.animation = "jump" end
	if not player.jumping and not player.ground then player.animation = "fall" end
	
	if player.animation == "skid" then
		if input.left == input.right and math.abs(player.x_speed) < 0.2 then player.animation = "idle" end
	end
	
end

function player_apply_friction()
	if player.ground then
		player.x_speed = player.x_speed - math.min( math.abs(player.x_speed), player.friction * math.sign(player.x_speed) )
	else
		player.x_speed = player.x_speed * player.friction_air
	end
end

return object