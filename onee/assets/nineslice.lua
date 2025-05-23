local nineslice = {}

----------------------------------------------------------------

function nineslice.add(name, anim, frame, image, animdef, framedef, export)
	local ninedef = animdef.nineslice
	assert(ninedef, "nineslice.add() | no nine-slice definition for animation \""..anim.."\" in \""..name.."\"")
	assert(ninedef.x1, "nineslice.add() | no nine-slice size for animation \""..anim.."\" in \""..name.."\"")
	
	-- add missing nine-slice variables
	ninedef.x2 = ninedef.x2 or ninedef.x1
	ninedef.y1 = ninedef.y1 or ninedef.x1
	ninedef.y2 = ninedef.y2 or ninedef.y1
	
	ninedef.left = ninedef.left or TILE.TILE
	ninedef.right = ninedef.right or TILE.TILE
	ninedef.top = ninedef.top or TILE.TILE
	ninedef.bottom = ninedef.bottom or TILE.TILE
	ninedef.body = ninedef.body or TILE.TILE
	
	if ninedef.sides then
		ninedef.left = ninedef.sides
		ninedef.right = ninedef.sides
		ninedef.top = ninedef.sides
		ninedef.bottom = ninedef.sides
		
		ninedef.sides = nil
	end
	
	-- add new assets entries
	export._nineslices = export._nineslices or {}
	export._nineslices[anim] = export._nineslices[anim] or {}
	export._nineslices[anim][frame] = {}
	
	local images = export._nineslices[anim][frame]
	local slices = {}
	
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
		
		slices[i] = love.graphics.newCanvas(width, height)
		slices[i]:renderTo(function()
			love.graphics.draw(image, -x, -y)
		end)
		
		images[i] = love.graphics.newImage(slices[i]:newImageData())
	end
	
	slices = nil -- clear from memory
	collectgarbage()
	
	if ninedef.top ~= TILE.STRETCH then
		images[2]:setWrap(ninedef.top, ninedef.top)
	end
	if ninedef.left ~= TILE.STRETCH then
		images[4]:setWrap(ninedef.left, ninedef.left)
	end
	if ninedef.right ~= TILE.STRETCH then
		images[6]:setWrap(ninedef.right, ninedef.right)
	end
	if ninedef.bottom ~= TILE.STRETCH then
		images[8]:setWrap(ninedef.bottom, ninedef.bottom)
	end
	if ninedef.body ~= TILE.STRETCH then
		images[5]:setWrap(ninedef.body, ninedef.body)
	end
end

----------------------------------------------------------------

function nineslice.draw(sprite, scene, anim, frame, animdef, framedef)
	assert(sprite.nineslice, "nineslice.draw() | no nine-slice instance in \""..sprite.name.."\"")
	local ninedef = animdef.nineslice
	assert(ninedef, "nineslice.draw() | no nine-slice definition for animation \""..anim.."\" in \""..sprite.name.."\"")
	assert(ninedef.x1, "nineslice.draw() | no nine-slice size for animation \""..anim.."\" in \""..sprite.name.."\"")
	
	local slices = scene.assets[sprite.name]._nineslices[anim][frame]
	local canvas = sprite.nineslice.canvas
	
	local nwidth = sprite.nineslice.width or framedef.width
	local nheight = sprite.nineslice.height or framedef.height
	local nx, ny, qref_width, qref_height, qwidth, qheight
	
	window.pop()
	canvas:renderTo(function()
		love.graphics.clear()
		
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
	window.push()
	
	return(canvas)
end

----------------------------------------------------------------

return nineslice