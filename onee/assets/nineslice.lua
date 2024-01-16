local nineslice = {}

----------------------------------------------------------------

function nineslice.add(name, anim, frame, image, animdef, framedef)
	local ninedef = animdef.nineslice
	assert(ninedef, "nineslice.add() | no nine-slice definition for animation \""..anim.."\" in \""..name.."\"")
	assert(ninedef.x1, "nineslice.add() | no nine-slice size for animation \""..anim.."\" in \""..name.."\"")
	
	-- add missing nine-slice variables
	if not ninedef.x2 then ninedef.x2 = ninedef.x1 end
	if not ninedef.y1 then ninedef.y1 = ninedef.x1 end
	if not ninedef.y2 then ninedef.y2 = ninedef.y2 end
	
	if not ninedef.left then ninedef.left = TILE.TILE end
	if not ninedef.right then ninedef.right = TILE.TILE end
	if not ninedef.top then ninedef.top = TILE.TILE end
	if not ninedef.bottom then ninedef.bottom = TILE.TILE end
	if not ninedef.body then ninedef.body = TILE.TILE end
	
	if ninedef.sides then
		ninedef.left = ninedef.sides
		ninedef.right = ninedef.sides
		ninedef.top = ninedef.sides
		ninedef.bottom = ninedef.sides
		
		ninedef.sides = nil
	end
	
	-- add new assets entries
	if not assets[name]._nineslices then assets[name]._nineslices = {} end
	if not assets[name]._nineslices[anim] then assets[name]._nineslices[anim] = {} end
	assets[name]._nineslices[anim][frame] = {}
	
	local images = assets[name]._nineslices[anim][frame]
	local canvas = {}
	
	-- split into 9 images
	for i = 1, 9 do
		local x, y, width, height
		
		-- top left | top | top right
		if i == 1 then
			x = 0
			y = 0
			width = ninedef.x1
			height = ninedef.y1
		elseif i == 2 then
			x = ninedef.x1
			y = 0
			width = framedef.width - (ninedef.x1 + ninedef.x2)
			height = ninedef.y1
		elseif i == 3 then
			x = framedef.width - ninedef.x2
			y = 0
			width = ninedef.x2
			height = ninedef.y1
		
		-- left | body | right
		elseif i == 4 then
			x = 0
			y = ninedef.y1
			width = ninedef.x1
			height = framedef.height - (ninedef.y1 + ninedef.y2)
		elseif i == 5 then
			x = ninedef.x1
			y = ninedef.y1
			width = framedef.width - (ninedef.x1 + ninedef.x2)
			height = framedef.height - (ninedef.y1 + ninedef.y2)
		elseif i == 6 then
			x = framedef.width - ninedef.x2
			y = ninedef.y1
			width = ninedef.x2
			height = framedef.height - (ninedef.y1 + ninedef.y2)
		
		-- bottom left | bottom | bottom right
		elseif i == 7 then
			x = 0
			y = framedef.height - ninedef.y2
			width = ninedef.x1
			height = ninedef.y2
		elseif i == 8 then
			x = ninedef.x1
			y = framedef.height - ninedef.y2
			width = framedef.width - (ninedef.x1 + ninedef.x2)
			height = ninedef.y2
		elseif i == 9 then
			x = framedef.width - ninedef.x2
			y = framedef.height - ninedef.y2
			width = ninedef.x2
			height = ninedef.y2
		end
		
		canvas[i] = love.graphics.newCanvas(width, height)
		canvas[i]:renderTo(function()
			love.graphics.draw(image, -x, -y)
		end)
		
		images[i] = love.graphics.newImage(canvas[i]:newImageData())
	end
	
	canvas = nil -- clear from memory
	
	if ninedef.left ~= TILE.STRETCH then
		images[4]:setWrap(ninedef.left, ninedef.left)
	end
	if ninedef.right ~= TILE.STRETCH then
		images[6]:setWrap(ninedef.right, ninedef.right)
	end
	if ninedef.top ~= TILE.STRETCH then
		images[2]:setWrap(ninedef.top, ninedef.top)
	end
	if ninedef.bottom ~= TILE.STRETCH then
		images[8]:setWrap(ninedef.bottom, ninedef.bottom)
	end
	if ninedef.body ~= TILE.STRETCH then
		images[5]:setWrap(ninedef.body, ninedef.body)
	end
end

----------------------------------------------------------------

function nineslice.draw(sprite, anim, frame, animdef, framedef)
	assert(sprite.nineslice, "nineslice.draw() | no nine-slice instance in \""..sprite.name.."\"")
	local ninedef = animdef.nineslice
	assert(ninedef, "nineslice.draw() | no nine-slice definition for animation \""..anim.."\" in \""..sprite.name.."\"")
	assert(ninedef.x1, "nineslice.draw() | no nine-slice size for animation \""..anim.."\" in \""..sprite.name.."\"")
	
	local slices = assets[sprite.name]._nineslices[anim][frame]
	local canvas = sprite.nineslice.canvas
	
	local nwidth = sprite.nineslice.width or framedef.width
	local nheight = sprite.nineslice.height or framedef.height
	local nx, ny, qref_width, qref_height, qwidth, qheight
	
	canvas:renderTo(function()
		-- top left
		nx = 0
		ny = 0
		love.graphics.draw(slices[1], nx, ny)
		
		-- top
		nx = ninedef.x1
		ny = 0
		qref_width = framedef.width - (ninedef.x1 + ninedef.x2)
		qref_height = ninedef.y1
		qwidth = nwidth - (ninedef.x1 + ninedef.x2)
		qheight = qref_height
		if ninedef.top ~= TILE.STRETCH then
			sprite.nineslice.qtop:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(slices[2], sprite.nineslice.qtop, nx, ny)
		else
			love.graphics.draw(slices[2], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
		end
		
		-- top right
		nx = nwidth - ninedef.x2
		ny = 0
		love.graphics.draw(slices[3], nx, ny)
		
		-- left
		nx = 0
		ny = ninedef.y1
		qref_width = ninedef.x1
		qref_height = framedef.height - (ninedef.y1 + ninedef.y2)
		qwidth = qref_width
		qheight = nheight - (ninedef.y1 + ninedef.y2)
		if ninedef.left ~= TILE.STRETCH then
			sprite.nineslice.qleft:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(slices[4], sprite.nineslice.qleft, nx, ny)
		else
			love.graphics.draw(slices[4], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
		end
		
		-- body
		nx = ninedef.x1
		ny = ninedef.y1
		qref_width = framedef.width - (ninedef.x1 + ninedef.x2)
		qref_height = framedef.height - (ninedef.y1 + ninedef.y2)
		qwidth = nwidth - (ninedef.x1 + ninedef.x2)
		qheight = nheight - (ninedef.y1 + ninedef.y2)
		if ninedef.body ~= TILE.STRETCH then
			sprite.nineslice.qbody:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(slices[5], sprite.nineslice.qbody, nx, ny)
		else
			love.graphics.draw(slices[5], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
		end
		
		-- right
		nx = nwidth - ninedef.x2
		ny = ninedef.y1
		qref_width = ninedef.x2
		qref_height = framedef.height - (ninedef.y1 + ninedef.y2)
		qwidth = qref_width
		qheight = nheight - (ninedef.y1 + ninedef.y2)
		if ninedef.right ~= TILE.STRETCH then
			sprite.nineslice.qright:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(slices[6], sprite.nineslice.qright, nx, ny)
		else
			love.graphics.draw(slices[6], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
		end
		
		-- bottom left
		nx = 0
		ny = nheight - ninedef.y2
		love.graphics.draw(slices[7], nx, ny)
		
		-- bottom
		nx = ninedef.x1
		ny = nheight - ninedef.y2
		qref_width = framedef.width - (ninedef.x1 + ninedef.x2)
		qref_height = ninedef.y2
		qwidth = nwidth - (ninedef.x1 + ninedef.x2)
		qheight = qref_height
		if ninedef.bottom ~= TILE.STRETCH then
			sprite.nineslice.qbottom:setViewport(0, 0, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(slices[8], sprite.nineslice.qbottom, nx, ny)
		else
			love.graphics.draw(slices[8], nx, ny, 0, qwidth/qref_width, qheight/qref_height)
		end
		
		-- bottom right
		nx = nwidth - ninedef.x2
		ny = nheight - ninedef.y2
		love.graphics.draw(slices[9], nx, ny)
	end)
	
	return(canvas)
end

----------------------------------------------------------------

return nineslice