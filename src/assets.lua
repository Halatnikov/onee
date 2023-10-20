asset = {} -- functions
sprite = {}

assets = {} -- actual containers
sprites = {}

-- constants
TILE = {
	TILE = "repeat",
	MIRROR = "mirroredrepeat",
	ONCE = "clampzero",
	EDGES = "clamp",
	
	STRETCH = 0, -- only for nine-slices
}
DISPOSE = {
	ANY = 0, -- unspecified
	NONE = 1, -- superimpose on previous
	BACKGROUND = 2, -- clear to bg color
	PREVIOUS = 3, -- revert 1 frame back
}

local gif = require("src/assets/gif")
local nineslice = require("src/assets/nineslice")

---------------------------------------------------------------- ASSETS

function asset.sprite(path) -- LOAD NEW SPRITE ASSET --
	
	local name = string.tokenize(path,"/",#string.tokenize(path,"/"))
	if assets[name] then print("asset.sprite() | asset \""..name.."\" already loaded!") return end
	
	local sprite = require("sprites/"..path) -- init
	assets[name] = {}
	
	-- first pass, determine image types
	for anim in pairs(sprite.animations) do
		local animdef = sprite.animations[anim]
		
		if sprite.gif then animdef.gif = true end
	end
	
	-- second pass, load unique images
	for anim in pairs(sprite.animations) do
		local animdef = sprite.animations[anim]
		
		if not animdef.images then
			assets[name][anim] = {} -- new anim entry
			local filename = animdef.filename or anim

			-- gif
			if animdef.gif then
				gif.add("sprites/"..path.."/"..filename..".gif", animdef, assets[name][anim])
				
			-- one image file per frame (default)
			else
				for frame in pairs(animdef.frames) do
					local image = love.graphics.newImage("sprites/"..path.."/"..filename.."_"..(frame-1)..".png")
					
					assets[name][anim][frame] = image -- new frame entry
				end
				
			end
			
		end
	end
	
	-- third pass
	for anim in pairs(sprite.animations) do
		local animdef = sprite.animations[anim]
		
		asset.negative_frames(animdef)
		
		-- allow only one at a time
		if sprite.tiled then sprite.nineslice = nil end
		if sprite.nineslice then sprite.tiled = nil end
		
		for frame in pairs(animdef.frames) do
			local framedef = animdef.frames[frame]
			
			local image
			if not animdef.images then -- unique image
				image = assets[name][anim][frame]
			else
				if not framedef.image then -- reused animation
					image = assets[name][animdef.images][frame]
				else -- reused animation AND a different frame image
					image = assets[name][animdef.images][framedef.image]
				end
			end
			assert(image, "asset.sprite() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..name.."\"")
			
			-- frame width/height
			if not framedef.width then framedef.width = image:getWidth() end
			if not framedef.height then framedef.height = image:getHeight() end
			
			-- tiled sprites
			if sprite.tiled then image:setWrap(TILE.TILE, TILE.TILE) end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- nine-slices (9patches)
			if sprite.nineslice then nineslice.add(name, anim, frame, image, animdef, framedef) end
			
			-- add missing frame variables
			if not framedef.length then framedef.length = 1 end
			if not framedef.x then framedef.x = animdef.x or 0 end
			if not framedef.y then framedef.y = animdef.y or 0 end
			
		end
		
		-- add missing animation variables
		if not animdef.seq then
			if animdef.seq_start then
				animdef.seq = {animdef.seq_start[#animdef.seq_start]} -- disable looping
			else
				animdef.seq = {1} -- disable animating entirely
			end
		end
		if animdef.seq and not animdef.seq_start then
			animdef.seq_start = animdef.seq -- make identical seq_start and seq
		end
		if not animdef.speed then animdef.speed = 0 end
		
	end
	
	sprites[name] = sprite -- done
	
end

function asset.delete(name) -- UNLOAD ASSET
	assets[name] = nil
	if sprites[name] then sprites[name] = nil end
	collectgarbage()
end

---------------------------------------------------------------- HELPER FUNCTIONS

function asset.add_frames(count, x,y,length) -- shortcut for adding frames to sprite def
	local t = {}
	for i=1, count do
		t[i] = {}
		t[i].x = x or 0
		t[i].y = y or 0
		t[i].length = length or 1
	end
	return t
end

function asset.negative_frames(animdef) -- handle negative frame declarations
	for frame in pairs(animdef.frames) do
		if frame < 0 then -- if your frame is -1, that means the last frame and so on
			local i = (#animdef.frames+1) + frame
			animdef.frames[i] = table.append(animdef.frames[i], animdef.frames[frame])
		
			animdef.frames[frame] = nil
		end
	end
end

---------------------------------------------------------------- SPRITES

function sprite.init(sprite, name) -- INITIALIZE A NEW SPRITE --
	assert(sprites[name], "sprite.init() | \""..name.."\" is not a valid sprite!")
	
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
		
		t.tiled = {}
		t.tiled.quad = love.graphics.newQuad(0,0,0,0,0,0)
		
	elseif sprites[name].nineslice then
		
		t.nineslice = {}
		
		t.nineslice.qleft = love.graphics.newQuad(0,0,0,0,0,0)
		t.nineslice.qright = love.graphics.newQuad(0,0,0,0,0,0)
		t.nineslice.qtop = love.graphics.newQuad(0,0,0,0,0,0)
		t.nineslice.qbottom = love.graphics.newQuad(0,0,0,0,0,0)
		t.nineslice.qbody = love.graphics.newQuad(0,0,0,0,0,0)
		
		t.nineslice.canvas = love.graphics.newCanvas(1,1)
		
	end
	
	return table.append(sprite, t)
end

function sprite.update(sprite) -- UPDATE SPRITE --
	
	assert(sprite.name, "sprite.update() | not a valid sprite")
	local animdef = sprites[sprite.name].animations[sprite.animation]
	assert(animdef, "sprite.update() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	local framedef = animdef.frames[sprite.frame]
	assert(framedef, "sprite.update() | no such frame "..sprite.frame.." of animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	
	-- update nine-slice canvas
	if sprite.nineslice then
		local nwidth = sprite.nineslice.width or framedef.width
		local nheight = sprite.nineslice.height or framedef.height
		
		if sprite.nineslice.canvas:getWidth() ~= nwidth or sprite.nineslice.canvas:getHeight() ~= nheight then
			sprite.nineslice.canvas = love.graphics.newCanvas(nwidth, nheight)
		end
	end
	
	-- update animations
	sprite.timer = sprite.timer + dt
	
	-- animation was changed from outside
	if sprite.animation ~= sprite.current then
		sprite.speed = nil
		sprite.timer = 0
		sprite.seq = "seq_start"
		sprite.seq_index = 1
	
		sprite.current = sprite.animation
		sprite.frame = animdef[sprite.seq][sprite.seq_index]
	end
	
	-- frame was changed from outside
	if sprite.frame ~= animdef[sprite.seq][sprite.seq_index] then
		sprite.timer = 0
		
		sprite.seq_index = table.find(animdef[sprite.seq], sprite.frame)
	end
	
	local speed = sprite.speed or animdef.speed or 0 -- overwrite speed
	
	-- advance frame
	if sprite.timer > 1 / (speed / framedef.length) then
		sprite.timer = 0
		
		sprite.seq_index = sprite.seq_index + 1
		if sprite.seq_index > #animdef[sprite.seq] then -- animation reached end
			-- loop
			if not (animdef.loops == false) or (animdef.loops and sprite.loops < animdef.loops) then
				sprite.loops = sprite.loops + 1
				
				sprite.seq = "seq"
				sprite.seq_index = 1
			end
			-- stop
			if (animdef.loops == false) or (animdef.loops and sprite.loops > animdef.loops) then
				sprite.seq_index = #animdef[sprite.seq]
			end
		end
		
		sprite.frame = animdef[sprite.seq][sprite.seq_index]
		
	end
	
end

function sprite.draw(sprite) -- DRAW SPRITE --

	assert(sprite, "sprite.draw() | not a valid sprite")
	assert(sprite.name, "sprite.draw() | not a valid sprite")
	local spritedef = sprites[sprite.name]
	assert(spritedef, "sprite.draw() | no such sprite \""..sprite.name.."\"")
	
	-- basics
	local x = sprite.x or 0; x = math.round(x)
	local y = sprite.y or 0; y = math.round(y)
	local angle = sprite.angle or 0; angle = math.rad(angle)
	local scalex = sprite.scalex or 1
	local scaley = sprite.scaley or 1
	local skewx = sprite.skewx or 0
	local skewy = sprite.skewy or 0
	
	-- opacity and tinting
	local rgb = sprite.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = sprite.opacity or 100; opacity = opacity/100
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
	
	-- animation shenanigans
	local anim = sprite.animation
	local frame = sprite.frame
	
	local animdef = spritedef.animations[anim]
	assert(animdef, "sprite.draw() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	local framedef = animdef.frames[frame]
	assert(framedef, "sprite.draw() | no such frame "..sprite.frame.." of animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	
	-- origin points
	local framex = framedef.x or 0
	local framey = framedef.y or 0
	
	-- actual width/height numbers for convenience
	if sprite.width then
		scalex = sprite.width / framedef.width
	end
	if sprite.height then
		scaley = sprite.height / framedef.height
	end
	
	-- assigning an image
	local image
	if not animdef.images then -- unique image
		image = assets[sprite.name][anim][frame]
	else
		if not framedef.image then -- reused animation
			image = assets[sprite.name][animdef.images][frame]
		else -- reused animation AND a different frame image
			image = assets[sprite.name][animdef.images][framedef.image]
		end
	end
	assert(image, "sprite.draw() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..sprite.name.."\"")
	
	-- finally drawing itself
	if spritedef.tiled then -- TILED SPRITE
		
		assert(sprite.tiled, "sprite.draw() | no tiled definition in \""..sprite.name.."\"")
		local quad = sprite.tiled.quad
		
		local qref_width = framedef.width
		local qref_height = framedef.height
		
		local qx = sprite.tiled.x or 0
		local qy = sprite.tiled.y or 0
		local qwidth = sprite.tiled.width or qref_width; qwidth = math.floor(qwidth)
		local qheight = sprite.tiled.height or qref_height; qheight = math.floor(qheight)
		
		-- rebase origin points
		framex = qwidth * (framedef.x / framedef.width) or 0
		framey = qheight * (framedef.y / framedef.height) or 0
		
		quad:setViewport(qx, qy, qwidth, qheight, qref_width, qref_height)
		love.graphics.draw(image, quad, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	elseif spritedef.nineslice then -- NINE-SLICE SPRITE
	
		local nwidth = sprite.nineslice.width or framedef.width
		local nheight = sprite.nineslice.height or framedef.height
		
		-- rebase origin points
		framex = nwidth * (framedef.x / framedef.width) or 0
		framey = nheight * (framedef.y / framedef.height) or 0
		
		love.graphics.draw( nineslice.draw(sprite, anim, frame, animdef, framedef),
		x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	else -- REGULAR SPRITE
		
		love.graphics.draw(image, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	end
	
	-- reset graphics state
	love.graphics.setColor(1,1,1,1)
end
