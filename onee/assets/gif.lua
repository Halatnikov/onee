local gif = {}

----------------------------------------------------------------

function gif.add(path, animdef, export)
	local file = love.filesystem.read(path)
	assert(file, "gif.add() | incorrect gif path \""..path.."\"")
	
	local gifload = gifload()
	gifload:update(file) -- read the gif file
	local gif = gifload:done()
	assert(gif.nimages > 0, "gif.add() | invalid gif \""..path.."\"")
	
	local no_seq -- init frames and seq from gif
	if not animdef.frames then animdef.frames = {} end
	if not animdef.seq then animdef.seq = {}; no_seq = true end
	
	if not animdef.loops then -- loop: 0 = infinite, false = don't loop, >1 = loop x times 
		if not gif.loop == 0 then
			if gif.loop == false or gif.loop == 1 then
				animdef.loops = false
			else
				animdef.loops = gif.loop
			end
		end
	end
	
	local delays = {}
	
	-- first pass
	for i=1, gif.nimages do
		local frame, x, y, delay, dispose = gif:frame(i)
		
		if delay < 0.01 then delay = 0.01 end -- minimum delay
		delays[i] = delay -- count all delays
		
		if not animdef.frames[i] then animdef.frames[i] = {} end -- add to frames and seq
		if no_seq then animdef.seq[i] =  i end
	end
	
	asset.negative_frames(animdef)
	
	local base_delay = table.mostcommon(delays) -- get the most common delay
	if not animdef.speed then
		animdef.speed = math.round(gif.nimages / (base_delay * gif.nimages), 2) -- speed
	end
	
	-- canvas to paste incomplete gif frames onto
	local canvas = love.graphics.newCanvas(gif.width, gif.height)
	local previous
	
	-- second pass
	for i=1, gif.nimages do
		local framedef = animdef.frames[i]
		local frame, x, y, delay, dispose = gif:frame(i)
		local image = love.graphics.newImage(frame)
		
		if not framedef.length then -- frame length
			if delay ~= base_delay then
				framedef.length = math.round(delay / base_delay, 2)
			end
		end
		
		if framedef.gif_dispose then dispose = framedef.gif_dispose end -- overwrite dispose
		
		canvas:renderTo(function() -- do a frame
			if dispose == DISPOSE.ANY or dispose == DISPOSE.NONE then
				previous = nil
				love.graphics.draw(image, x, y)
			elseif dispose == DISPOSE.BACKGROUND then
				previous = nil
				love.graphics.clear()
				if animdef.gif_transparent == false then -- fill with background color
					local bg = gif.background
					love.graphics.clear(bg[1]/255, bg[2]/255, bg[3]/255)
				end
				love.graphics.draw(image, x, y)
			elseif dispose == DISPOSE.PREVIOUS then
				if not previous then previous = i-1 end
				love.graphics.clear()
				love.graphics.draw(export[previous], x, y)
				love.graphics.draw(image, x, y)
			end
		end)
		
		export[i] = love.graphics.newImage(canvas:newImageData()) -- new frame entry
	end
	
	canvas = nil -- clear from memory
	collectgarbage()
end

----------------------------------------------------------------

return gif