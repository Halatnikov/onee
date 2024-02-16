local spritesheet = {}

----------------------------------------------------------------

function spritesheet.add(sprite, path, frame, animdef, framedef, export)
	local sheetdef = framedef.sheet
	
	sprite.cached_images[path] = sprite.cached_images[path] or love.graphics.newImage(path)
	local image = sprite.cached_images[path]
	
	sheetdef.x = sheetdef.x or animdef.sheet.x or 0
	sheetdef.y = sheetdef.y or animdef.sheet.y or animdef.sheet.x or 0
	sheetdef.width = sheetdef.width or animdef.sheet.width or image:getWidth()
	sheetdef.height = sheetdef.height or animdef.sheet.height or animdef.sheet.width or image:getHeight()
	
	local canvas = love.graphics.newCanvas(sheetdef.width, sheetdef.height)
	canvas:renderTo(function()
		love.graphics.draw(image, -sheetdef.x, -sheetdef.y)
	end)
	
	export[frame] = love.graphics.newImage(canvas:newImageData())
	
	canvas = nil -- clear from memory
	collectgarbage()
end

function spritesheet.strip(sprite, path, animdef, export)
	local stripdef = animdef.strip
	assert(stripdef.frames, "spritesheet.strip() | no frame count specified in spritestrip for \""..path.."\"")
	
	sprite.cached_images[path] = sprite.cached_images[path] or love.graphics.newImage(path)
	local image = sprite.cached_images[path]
	
	stripdef.x = stripdef.x or 0
	stripdef.y = stripdef.y or 0
	-- TODO: only one horizontal row strips for now
	stripdef.width = stripdef.width or image:getWidth() / stripdef.frames
	stripdef.height = stripdef.height or image:getHeight()
	
	animdef.frames = animdef.frames or {}
	for i=1, stripdef.frames do
		if not animdef.frames[i] then animdef.frames[i] = {} end
		local framedef = animdef.frames[i]
		
		framedef.sheet = {
			x = stripdef.x + (stripdef.width * (i - 1)),
			y = stripdef.y,
			width = stripdef.width,
			height = stripdef.height,
		}
		
		spritesheet.add(sprite, path, i, animdef, framedef, export)
	end
	
end
----------------------------------------------------------------

return spritesheet