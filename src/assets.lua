asset = {} -- functions
sprite = {}

assets = {} -- actual containers
sprites = {}

---------------------------------------------------------------- ASSETS

function asset.sprite(path) -- LOAD NEW SPRITE ASSET --
	
	local name = string.tokenize(path,"/",#string.tokenize(path,"/"))
	if assets[name] then print("asset.sprite() | asset \""..name.."\" already loaded!") return end
	
	local sprite = require("sprites/"..path) -- init
	assets[name] = {}
	
	-- first pass, load unique images
	for anim in pairs(sprite.animations) do
		if not sprite.animations[anim].images then
			assets[name][anim] = {} -- new anim entry

			for frame in pairs(sprite.animations[anim].frames) do
				local image = love.graphics.newImage("sprites/"..path.."/"..anim.."_"..(frame-1)..".png")
				
				assets[name][anim][frame] = image -- new frame entry
			end
		end
	end
	
	-- second pass
	for anim in pairs(sprite.animations) do
		for frame in pairs(sprite.animations[anim].frames) do
			
			local image
			if not sprite.animations[anim].images then -- unique image
				image = assets[name][anim][frame]
			else
				if not sprite.animations[anim].frames[frame].image then -- reused animation
					image = assets[name][sprite.animations[anim].images][frame]
				else -- reused animation AND a different frame image
					image = assets[name][sprite.animations[anim].images][sprite.animations[anim].frames[frame].image]
				end
			end
			
			-- frame width/height
			sprite.animations[anim].frames[frame].width = image:getWidth()
			sprite.animations[anim].frames[frame].height = image:getHeight()
			
			-- tiled sprites
			if sprite.tiled then image:setWrap("repeat", "repeat") end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- add missing variables
			if not sprite.animations[anim].seq then
				sprite.animations[anim].seq = {1}
			end
			if not sprite.animations[anim].seq_start then
				sprite.animations[anim].seq_start = sprite.animations[anim].seq
			end
			if not sprite.animations[anim].speed then
				sprite.animations[anim].speed = 0
			end
			
		end

	end
	
	sprites[name] = sprite -- done
	
end

function asset.delete(name) -- UNLOAD ASSET
	assets[name] = nil
	if sprites[name] then sprites[name] = nil end
	collectgarbage()
end

----------------------------------------------------------------

function asset.add_frames(count, x,y,speed) -- shortcut for adding frames to sprite data
	local t = {}
	for i=1, count do
		t[i] = {}
		t[i].x = x or 0
		t[i].y = y or 0
		t[i].speed = speed or 1
	end
	return t
end

---------------------------------------------------------------- SPRITES

function sprite.init(sprite, name) -- INITIALIZE A NEW SPRITE --
	if not sprites[name] then print("sprite.init() | "..name.." is not a valid sprite!") return end
	local t = {
		sprite = true,
		name = name,
		animation = "idle",
		current = "idle",
		frame = 1,
		timer = 0,
		seq = "seq_start",
		seq_index = 1,
	}
	if sprites[name].tiled then
		t.quad = love.graphics.newQuad(0,0,0,0,0,0)
	end
	return table.append(sprite, t)
end

function sprite.update(sprite) -- UPDATE SPRITE --
	
	local anim = sprites[sprite.name].animations[sprite.animation]
	
	sprite.timer = sprite.timer + dt
	
	-- animation was changed from outside
	if sprite.animation ~= sprite.current then
		sprite.speed = nil
		
		sprite.current = sprite.animation
	
		sprite.timer = 0
		sprite.seq = "seq_start"
		sprite.seq_index = 1
		sprite.frame = anim[sprite.seq][sprite.seq_index]
	end
	
	-- frame was changed from outside
	if sprite.frame ~= anim[sprite.seq][sprite.seq_index] then
		sprite.seq_index = table.find(anim[sprite.seq], sprite.frame)
		
		sprite.timer = 0
	end
	
	local speed = sprite.speed or anim.speed or 0 -- overwrite speed
	
	-- advance frame
	if sprite.timer > 1 / (speed / anim.frames[sprite.frame].speed) then -- (speed / frame speed multiplier)
		sprite.timer = 0
		
		sprite.seq_index = sprite.seq_index + 1
		if sprite.seq_index > #anim[sprite.seq] then -- loop
			sprite.seq = "seq"
			sprite.seq_index = 1
		end
		sprite.frame = anim[sprite.seq][sprite.seq_index]
		
	end
	
	return sprite
	
end

function sprite.draw(sprite) -- DRAW SPRITE --

	local data = sprites[sprite.name]
	
	-- basics
	local x = sprite.x or 0; x = math.round(x)
	local y = sprite.y or 0; y = math.round(y)
	local angle = sprite.angle or 0; angle = math.rad(angle)
	local scalex = sprite.scalex or 1
	local scaley = sprite.scaley or 1
	
	-- opacity and tinting
	local rgb = sprite.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = sprite.opacity or 100; opacity = opacity/100
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
	
	-- animation shenanigans
	local anim = sprite.animation
	local frame = sprite.frame
	
	local frame_x = data.animations[anim].frames[frame].x or 0
	local frame_y = data.animations[anim].frames[frame].y or 0
	
	-- actual width/height numbers for convenience
	if sprite.width then
		scalex = sprite.width / data.animations[anim].frames[frame].width
	end
	if sprite.height then
		scaley = sprite.height / data.animations[anim].frames[frame].height
	end
	
	-- assigning an image
	local image
	if not data.animations[anim].images then -- unique image
		image = assets[sprite.name][anim][frame]
	else
		if not data.animations[anim].frames[frame].image then -- reused animation
			image = assets[sprite.name][data.animations[anim].images][frame]
		else -- reused animation AND a different frame image
			image = assets[sprite.name][data.animations[anim].images][data.animations[anim].frames[frame].image]
		end
	end
	
	-- finally drawing itself
	if not data.tiled then -- REGULAR SPRITE
		love.graphics.draw(image, x, y, angle, scalex, scaley, frame_x, frame_y)
	end
	
	if data.tiled then -- TILED SPRITE
		local quad = sprite.quad
			
		local qref_width = data.animations[anim].frames[frame].width
		local qref_height = data.animations[anim].frames[frame].height
			
		local qx = sprite.qx or 0
		local qy = sprite.qy or 0
		local qwidth = sprite.qwidth or qref_width; qwidth = math.floor(qwidth)
		local qheight = sprite.qheight or qref_height; qheight = math.floor(qheight)
			
		quad:setViewport(qx, qy, qwidth, qheight, qref_width, qref_height)
		love.graphics.draw(image, quad, x, y, angle, scalex, scaley, frame_x, frame_y)
	end
	
end
