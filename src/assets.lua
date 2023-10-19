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
				if not file then error("asset.sprite() | incorrect gif path \"sprites/"..path.."/"..filename..".gif\"") end
				
				local gifload = gifload()
				gifload:update(file:read()) -- read the gif file
				file:close()
				local gif = gifload:done()
				if gif.nimages == 0 then error("asset.sprite() | invalid gif \"sprites/"..path.."/"..filename..".gif\"") end
				
				local no_seq -- init frames and seq from gif
				if not animdata.frames then animdata.frames = {} end
				if not animdata.seq then animdata.seq = {}; no_seq = true end
				
				if not animdata.loops then -- loop: 0 = infinite, false = don't loop, >1 = loop x times 
					if not gif.loop == 0 then
						if gif.loop == false or gif.loop == 1 then
							animdata.loops = false
						else
							animdata.loops = gif.loop
						end
					end
				end
				
				local delays = {}
				
				-- first pass
				for i=1, gif.nimages do
					local frame, x, y, delay, dispose = gif:frame(i)
					
					if delay < 0.01 then delay = 0.01 end -- minimum delay
					delays[i] = delay -- count all delays
					
					if not animdata.frames[i] then animdata.frames[i] = {} end -- add to frames and seq
					if no_seq then animdata.seq[i] =  i end
				end
				
				asset.negative_frames(animdata)
				
				local base_delay = table.mostcommon(delays) -- get the most common delay
				if not animdata.speed then
					animdata.speed = math.round(gif.nimages / (base_delay * gif.nimages), 2) -- speed
				end
				
				-- canvas to paste incomplete gif frames onto
				local canvas = love.graphics.newCanvas(gif.width, gif.height)
				local previous
				
				-- second pass
				for i=1, gif.nimages do
					local framedata = animdata.frames[i]
					local frame, x, y, delay, dispose = gif:frame(i)
					local image = love.graphics.newImage(frame)
					
					if not framedata.length then -- frame length
						if delay ~= base_delay then
							framedata.length = math.round(delay / base_delay, 2)
						end
					end
					
					if framedata.gif_dispose then dispose = framedata.gif_dispose end -- overwrite dispose
					
					canvas:renderTo(function() -- do a frame
						if dispose == DISPOSE.ANY or dispose == DISPOSE.NONE then
							previous = nil
							love.graphics.draw(image, x, y)
						end
						if dispose == DISPOSE.BACKGROUND then
							previous = nil
							love.graphics.clear()
							if animdata.gif_transparent == false then -- fill with background color
								local bg = gif.background
								love.graphics.setColor(bg[1]/255, bg[2]/255, bg[3]/255)
								love.graphics.rectangle("fill", 0, 0, gif.width, gif.height)
								love.graphics.setColor(1, 1, 1)
							end
							love.graphics.draw(image, x, y)
						end
						if dispose == DISPOSE.PREVIOUS then
							if not previous then previous = i-1 end
							love.graphics.clear()
							love.graphics.draw(assets[name][anim][previous], x, y)
							love.graphics.draw(image, x, y)
						end
					end)
					image = canvas:newImageData()
					
					assets[name][anim][i] = love.graphics.newImage(image) -- new frame entry
				end
				
				canvas = nil -- clear from memory
				
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
		
		asset.negative_frames(animdata)
		
		-- allow only one at a time
		if sprite.tiled then sprite.nineslice = nil end
		if sprite.nineslice then sprite.tiled = nil end
		
		for frame in pairs(animdata.frames) do
			local framedata = animdata.frames[frame]
			
			local image
			if not animdata.images then -- unique image
				image = assets[name][anim][frame]
			else
				if not framedata.image then -- reused animation
					image = assets[name][animdata.images][frame]
				else -- reused animation AND a different frame image
					image = assets[name][animdata.images][framedata.image]
				end
			end
			if not image then error("asset.sprite() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..name.."\"") end
			
			-- frame width/height
			if not framedata.width then framedata.width = image:getWidth() end
			if not framedata.height then framedata.height = image:getHeight() end
			
			-- tiled sprites
			if sprite.tiled then image:setWrap(TILE.TILE, TILE.TILE) end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- nine-slices (9patches)
			if sprite.nineslice then
				local ninedata = animdata.nineslice
				if not ninedata or not ninedata.x1 then error("asset.sprite() | no nine-slice size for animation \""..anim.."\" in \""..name.."\"") end
				
				-- add missing nine-slice variables
				if not ninedata.x2 then ninedata.x2 = ninedata.x1 end
				if not ninedata.y1 then
					ninedata.y1 = ninedata.x1
					ninedata.y2 = ninedata.x2
				end
				if not ninedata.y2 then ninedata.y2 = ninedata.y1 end
				
				if not ninedata.left then ninedata.left = TILE.TILE end
				if not ninedata.right then ninedata.right = TILE.TILE end
				if not ninedata.top then ninedata.top = TILE.TILE end
				if not ninedata.bottom then ninedata.bottom = TILE.TILE end
				
				if not ninedata.body then ninedata.body = TILE.TILE end
				
				if ninedata.sides then
					ninedata.left = ninedata.sides
					ninedata.right = ninedata.sides
					ninedata.top = ninedata.sides
					ninedata.bottom = ninedata.sides
					
					ninedata.sides = nil
				end
				
				-- add new assets entries
				if not assets[name]._nineslices then assets[name]._nineslices = {} end
				if not assets[name]._nineslices[anim] then assets[name]._nineslices[anim] = {} end
				assets[name]._nineslices[anim][frame] = {}
				
				local images = assets[name]._nineslices[anim][frame]
				local canvas = {}
				
				-- split into 9 images
				for i = 1, 9 do
					local x, y, widht, height
					
					-- top left | top | top right
					if i == 1 then
						x = 0
						y = 0
						width = ninedata.x1
						height = ninedata.y1
					elseif i == 2 then
						x = ninedata.x1
						y = 0
						width = framedata.width - (ninedata.x1 + ninedata.x2)
						height = ninedata.y1
					elseif i == 3 then
						x = framedata.width - ninedata.x2
						y = 0
						width = ninedata.x2
						height = ninedata.y1
					
					-- middle left | middle | middle right
					elseif i == 4 then
						x = 0
						y = ninedata.y1
						width = ninedata.x1
						height = framedata.height - (ninedata.y1 + ninedata.y2)
					elseif i == 5 then
						x = ninedata.x1
						y = ninedata.y1
						width = framedata.width - (ninedata.x1 + ninedata.x2)
						height = framedata.height - (ninedata.y1 + ninedata.y2)
					elseif i == 6 then
						x = framedata.width - ninedata.x2
						y = ninedata.y1
						width = ninedata.x2
						height = framedata.height - (ninedata.y1 + ninedata.y2)
					
					-- bottom left | bottom | bottom right
					elseif i == 7 then
						x = 0
						y = framedata.height - ninedata.y2
						width = ninedata.x1
						height = ninedata.y2
					elseif i == 8 then
						x = ninedata.x1
						y = framedata.height - ninedata.y2
						width = framedata.width - (ninedata.x1 + ninedata.x2)
						height = ninedata.y2
					elseif i == 9 then
						x = framedata.width - ninedata.x2
						y = framedata.height - ninedata.y2
						width = ninedata.x2
						height = ninedata.y2
					end
					
					canvas[i] = love.graphics.newCanvas(width, height)
					canvas[i]:renderTo(function()
						love.graphics.draw(image, -x, -y)
					end)
					
					images[i] = love.graphics.newImage(canvas[i]:newImageData())
				end
				
				canvas = nil -- clear from memory
				
				if ninedata.left ~= TILE.STRETCH then
					images[4]:setWrap(ninedata.left, ninedata.left)
				end
				if ninedata.right ~= TILE.STRETCH then
					images[6]:setWrap(ninedata.right, ninedata.right)
				end
				if ninedata.top ~= TILE.STRETCH then
					images[2]:setWrap(ninedata.top, ninedata.top)
				end
				if ninedata.bottom ~= TILE.STRETCH then
					images[8]:setWrap(ninedata.bottom, ninedata.bottom)
				end
				if ninedata.body ~= TILE.STRETCH then
					images[5]:setWrap(ninedata.body, ninedata.body)
				end
				
			end
			
			-- add missing frame variables
			if not framedata.length then framedata.length = 1 end
			if not framedata.x then framedata.x = animdata.x or 0 end
			if not framedata.y then framedata.y = animdata.y or 0 end
			
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
		if not animdata.speed then animdata.speed = 0 end
		
	end
	
	sprites[name] = sprite -- done
	
end

function asset.delete(name) -- UNLOAD ASSET
	assets[name] = nil
	if sprites[name] then sprites[name] = nil end
	collectgarbage()
end

---------------------------------------------------------------- HELPER FUNCTIONS

function asset.add_frames(count, x,y,length) -- shortcut for adding frames to sprite data
	local t = {}
	for i=1, count do
		t[i] = {}
		t[i].x = x or 0
		t[i].y = y or 0
		t[i].length = length or 1
	end
	return t
end

function asset.negative_frames(animdata) -- handle negative frame declarations
	for frame in pairs(animdata.frames) do
		if frame < 0 then -- if your frame is -1, that means the last frame and so on
			local i = (#animdata.frames+1) + frame
			animdata.frames[i] = table.append(animdata.frames[i], animdata.frames[frame])
		
			animdata.frames[frame] = nil
		end
	end
end

---------------------------------------------------------------- SPRITES

function sprite.init(sprite, name) -- INITIALIZE A NEW SPRITE --
	if not sprites[name] then error("sprite.init() | \""..name.."\" is not a valid sprite!") end
	
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
	
	if not sprite or not sprite.name then error("sprite.update() | not a valid sprite") end
	local animdata = sprites[sprite.name].animations[sprite.animation]
	if not animdata then error("sprite.update() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"") end
	local framedata = animdata.frames[sprite.frame]
	if not framedata then error("sprite.update() | no such frame "..sprite.frame.." of animation \""..sprite.animation.."\" in \""..sprite.name.."\"") end
	
	-- update nine-slice canvas
	if sprite.nineslice then
		local nwidth = sprite.nineslice.width or framedata.width
		local nheight = sprite.nineslice.height or framedata.height
		
		if sprite.nineslice.canvas:getWidth() ~= nwidth or sprite.nineslice.canvas:getHeight() ~= nheight then
			sprite.nineslice.canvas = love.graphics.newCanvas(nwidth, nheight)
		end
	end
	
	-- update animations
	sprite.timer = sprite.timer + dt
	
	-- animation was changed from outside
	if sprite.animation ~= sprite.current then
		sprite.current = sprite.animation
	
		sprite.speed = nil
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
	if sprite.timer > 1 / (speed / framedata.length) then
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
	
end

function sprite.draw(sprite) -- DRAW SPRITE --

	if not sprite or not sprite.name then error("sprite.draw() | not a valid sprite") end
	local data = sprites[sprite.name]
	if not data then error("sprite.draw() | no such sprite \""..sprite.name.."\"") end
	
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
	
	local animdata = data.animations[anim]
	if not animdata then error("sprite.draw() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"") end
	local framedata = animdata.frames[frame]
	if not framedata then error("sprite.draw() | no such frame "..sprite.frame.." of animation \""..sprite.animation.."\" in \""..sprite.name.."\"") end
	
	-- actual width/height numbers for convenience
	if sprite.width then
		scalex = sprite.width / framedata.width
	end
	if sprite.height then
		scaley = sprite.height / framedata.height
	end
	
	-- origin points
	local framex = framedata.x or 0
	local framey = framedata.y or 0
	
	-- assigning an image
	local image
	if not animdata.images then -- unique image
		image = assets[sprite.name][anim][frame]
	else
		if not framedata.image then -- reused animation
			image = assets[sprite.name][animdata.images][frame]
		else -- reused animation AND a different frame image
			image = assets[sprite.name][animdata.images][framedata.image]
		end
	end
	if not image then error("sprite.draw() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..sprite.name.."\"") end
	
	-- finally drawing itself
	if data.tiled then -- TILED SPRITE
		
		if not sprite.tiled then error("sprite.draw() | no tiled data in \""..sprite.name.."\"") end
		local quad = sprite.tiled.quad
		
		local qref_width = framedata.width
		local qref_height = framedata.height
		
		local qx = sprite.tiled.x or 0
		local qy = sprite.tiled.y or 0
		local qwidth = sprite.tiled.width or qref_width; qwidth = math.floor(qwidth)
		local qheight = sprite.tiled.height or qref_height; qheight = math.floor(qheight)
		
		-- rebase origin points
		framex = qwidth * (framedata.x / framedata.width) or 0
		framey = qheight * (framedata.y / framedata.height) or 0
		
		quad:setViewport(qx, qy, qwidth, qheight, qref_width, qref_height)
		love.graphics.draw(image, quad, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	elseif data.nineslice then -- NINE-SLICE SPRITE
		
		if not sprite.nineslice then error("sprite.draw() | no nine-slice data in \""..sprite.name.."\"") end
		local ninedata = animdata.nineslice
		if not ninedata or not ninedata.x1 then error("sprite.draw() | no nine-slice size for animation \""..anim.."\" in \""..name.."\"") end
		
		local slices = assets[sprite.name]._nineslices[anim][frame]
		local canvas = sprite.nineslice.canvas
		
		local nwidth = sprite.nineslice.width or framedata.width
		local nheight = sprite.nineslice.height or framedata.height
		
		canvas:renderTo(function()
			-- top left
			local nx = 0
			local ny = 0
			love.graphics.draw(slices[1], nx, ny)
			
			-- top
			local nx = ninedata.x1
			local ny = 0
			local qref_width = framedata.width - (ninedata.x1 + ninedata.x2)
			local qref_height = ninedata.y1
			local qwidth = nwidth - (ninedata.x1 + ninedata.x2)
			local qheight = qref_height
			if ninedata.top ~= TILE.STRETCH then
				sprite.nineslice.qtop:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
				love.graphics.draw(slices[2], sprite.nineslice.qtop, nx, ny)
			else
				love.graphics.draw(slices[2], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
			end
			
			-- top right
			local nx = nwidth - ninedata.x2
			local ny = 0
			love.graphics.draw(slices[3], nx, ny)
			
			-- left
			local nx = 0
			local ny = ninedata.y1
			local qref_width = ninedata.x1
			local qref_height = framedata.height - (ninedata.y1 + ninedata.y2)
			local qwidth = qref_width
			local qheight = nheight - (ninedata.y1 + ninedata.y2)
			if ninedata.left ~= TILE.STRETCH then
				sprite.nineslice.qleft:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
				love.graphics.draw(slices[4], sprite.nineslice.qleft, nx, ny)
			else
				love.graphics.draw(slices[4], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
			end
			
			-- body
			local nx = ninedata.x1
			local ny = ninedata.y1
			local qref_width = framedata.width - (ninedata.x1 + ninedata.x2)
			local qref_height = framedata.height - (ninedata.y1 + ninedata.y2)
			local qwidth = nwidth - (ninedata.x1 + ninedata.x2)
			local qheight = nheight - (ninedata.y1 + ninedata.y2)
			if ninedata.body ~= TILE.STRETCH then
				sprite.nineslice.qbody:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
				love.graphics.draw(slices[5], sprite.nineslice.qbody, nx, ny)
			else
				love.graphics.draw(slices[5], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
			end
			
			-- right
			local nx = nwidth - ninedata.x2
			local ny = ninedata.y1
			local qref_width = ninedata.x2
			local qref_height = framedata.height - (ninedata.y1 + ninedata.y2)
			local qwidth = qref_width
			local qheight = nheight - (ninedata.y1 + ninedata.y2)
			if ninedata.right ~= TILE.STRETCH then
				sprite.nineslice.qright:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
				love.graphics.draw(slices[6], sprite.nineslice.qright, nx, ny)
			else
				love.graphics.draw(slices[6], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
			end
			
			-- bottom left
			local nx = 0
			local ny = nheight - ninedata.y2
			love.graphics.draw(slices[7], nx, ny)
			
			-- bottom
			local nx = ninedata.x1
			local ny = nheight - ninedata.y2
			local qref_width = framedata.width - (ninedata.x1 + ninedata.x2)
			local qref_height = ninedata.y2
			local qwidth = nwidth - (ninedata.x1 + ninedata.x2)
			local qheight = qref_height
			if ninedata.bottom ~= TILE.STRETCH then
				sprite.nineslice.qbottom:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
				love.graphics.draw(slices[8], sprite.nineslice.qbottom, nx, ny)
			else
				love.graphics.draw(slices[8], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
			end
			
			-- bottom right
			local nx = nwidth - ninedata.x2
			local ny = nheight - ninedata.y2
			love.graphics.draw(slices[9], nx, ny)
		end)
		
		-- rebase origin points
		framex = nwidth * (framedata.x / framedata.width) or 0
		framey = nheight * (framedata.y / framedata.height) or 0
		
		love.graphics.draw(canvas, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	else -- REGULAR SPRITE
		
		love.graphics.draw(image, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		
	end
	
	-- reset graphics state
	love.graphics.setColor(1,1,1,1)
end
