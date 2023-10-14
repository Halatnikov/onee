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
	
	-- first pass, determine image types
	for anim in pairs(sprite.animations) do
		local animdata = sprite.animations[anim]
		
		if sprite.gif then animdata.gif = true end
	end
	
	-- second pass, load unique images
	for anim in pairs(sprite.animations) do
		local animdata = sprite.animations[anim]
		if not animdata.images then
			assets[name][anim] = {} -- new anim entry

			-- gif
			if animdata.gif then
				local filename = animdata.filename or anim
				local file = love.filesystem.newFile("sprites/"..path.."/"..filename..".gif", "r")
				local gifload = gifload()
				
				gifload:update(file:read()) -- read the gif file
				file:close()
				local gif = gifload:done()
				assets.gif = gifload:done()
				
				animdata.frames = {} -- grab frames and seq from gif
				animdata.seq = {}
				
				if not gif.loop == 0 then -- loop: 0 = infinite, false = don't loop, >1 = loop x times
					if gif.loop == false or gif.loop == 1 then
						animdata.loops = false
					else
						animdata.loops = gif.loop
					end
				end
				
				local delays = {}
				local delays_count = {}
				
				-- first pass
				for i=1, gif.nimages do
					local frame, x, y, delay, dispose = gif:frame(i)
					delays[i] = delay
				end
				
				
				function count(arg)
					local counts = {}
					for k, v in pairs(arg) do
						v = tostring(v)
						counts[v] = (counts[v] or 0) + 1
					end
					
					local key = next(counts)
					local max = counts[key]

					for k, v in pairs(counts) do
						if counts[k] > max then
							key, max = k, v
						end
					end

					print(key, max)
					return counts
				end
				
				
				debug.table(count(delays))
				
				-- second pass
				for i=1, gif.nimages do
					local frame, x, y, delay, dispose = gif:frame(i)
					
					assets[name][anim][i] = love.graphics.newImage(frame) -- new frame entry
					
					animdata.frames[i] = {}
					animdata.seq[i] =  i
				end
				
			-- one image file per frame (default)
			else
				for frame in pairs(animdata.frames) do
					local filename = animdata.filename or anim
					local image = love.graphics.newImage("sprites/"..path.."/"..filename.."_"..(frame-1)..".png")
					
					assets[name][anim][frame] = image -- new frame entry
				end
			end
			
		end
	end
	
	-- third pass
	for anim in pairs(sprite.animations) do
		local animdata = sprite.animations[anim]
		for frame in pairs(animdata.frames) do
			
			local image
			if not animdata.images then -- unique image
				image = assets[name][anim][frame]
			else
				if not animdata.frames[frame].image then -- reused animation
					image = assets[name][animdata.images][frame]
				else -- reused animation AND a different frame image
					image = assets[name][animdata.images][animdata.frames[frame].image]
				end
			end
			
			-- frame width/height
			animdata.frames[frame].width = image:getWidth()
			animdata.frames[frame].height = image:getHeight()
			
			-- tiled sprites
			if sprite.tiled then image:setWrap("repeat", "repeat") end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- add missing frame variables
			if not animdata.frames[frame].speed then
				animdata.frames[frame].speed = 1
			end
			if not animdata.frames[frame].x then
				animdata.frames[frame].x = animdata.x or 0
			end
			if not animdata.frames[frame].y then
				animdata.frames[frame].y = animdata.y or 0
			end
			
		end
		
		-- add missing animation variables
		if not animdata.seq then
			if animdata.seq_start then
				animdata.seq = {animdata.seq_start[#animdata.seq_start]} -- disable looping
			else
				animdata.seq = {1} -- disable animating entirely
			end
		end
		if animdata.seq and not animdata.seq_start then
			animdata.seq_start = animdata.seq -- make identical seq_start and seq
		end
		if not animdata.speed then
			animdata.speed = 0
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
		loops = 0,
	}
	if sprites[name].tiled then
		t.quad = love.graphics.newQuad(0,0,0,0,0,0)
	end
	return table.append(sprite, t)
end

function sprite.update(sprite) -- UPDATE SPRITE --
	
	local animdata = sprites[sprite.name].animations[sprite.animation]
	
	sprite.timer = sprite.timer + dt
	
	-- animation was changed from outside
	if sprite.animation ~= sprite.current then
		sprite.speed = nil
		
		sprite.current = sprite.animation
	
		sprite.timer = 0
		sprite.seq = "seq_start"
		sprite.seq_index = 1
		sprite.frame = animdata[sprite.seq][sprite.seq_index]
	end
	
	-- frame was changed from outside
	if sprite.frame ~= animdata[sprite.seq][sprite.seq_index] then
		sprite.seq_index = table.find(animdata[sprite.seq], sprite.frame)
		
		sprite.timer = 0
	end
	
	local speed = sprite.speed or animdata.speed or 0 -- overwrite speed
	
	-- advance frame
	if sprite.timer > 1 / (speed / animdata.frames[sprite.frame].speed) then -- (speed / frame "length" multiplier)
		sprite.timer = 0
		
		sprite.seq_index = sprite.seq_index + 1
		if sprite.seq_index > #animdata[sprite.seq] then -- animation reached end
			-- loop
			if not (animdata.loops == false) or (animdata.loops and sprite.loops < animdata.loops) then
				sprite.loops = sprite.loops + 1
				
				sprite.seq = "seq"
				sprite.seq_index = 1
			end
			-- stop
			if (animdata.loops == false) or (animdata.loops and sprite.loops > animdata.loops) then
				sprite.seq_index = #animdata[sprite.seq]
			end
		end
		
		sprite.frame = animdata[sprite.seq][sprite.seq_index]
		
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
	
	local animdata = data.animations[anim]
	
	local framex = animdata.frames[frame].x or 0
	local framey = animdata.frames[frame].y or 0
	
	-- actual width/height numbers for convenience
	if sprite.width then
		scalex = sprite.width / animdata.frames[frame].width
	end
	if sprite.height then
		scaley = sprite.height / animdata.frames[frame].height
	end
	
	-- assigning an image
	local image
	if not animdata.images then -- unique image
		image = assets[sprite.name][anim][frame]
	else
		if not animdata.frames[frame].image then -- reused animation
			image = assets[sprite.name][animdata.images][frame]
		else -- reused animation AND a different frame image
			image = assets[sprite.name][animdata.images][animdata.frames[frame].image]
		end
	end
	
	-- finally drawing itself
	if data.tiled then -- TILED SPRITE
		
		local quad = sprite.quad
			
		local qref_width = animdata.frames[frame].width
		local qref_height = animdata.frames[frame].height
			
		local qx = sprite.qx or 0
		local qy = sprite.qy or 0
		local qwidth = sprite.qwidth or qref_width; qwidth = math.floor(qwidth)
		local qheight = sprite.qheight or qref_height; qheight = math.floor(qheight)
			
		quad:setViewport(qx, qy, qwidth, qheight, qref_width, qref_height)
		love.graphics.draw(image, quad, x, y, angle, scalex, scaley, framex, framey)
		
	else -- REGULAR SPRITE
		
		love.graphics.draw(image, x, y, angle, scalex, scaley, framex, framey)
		
	end
	
	
end
