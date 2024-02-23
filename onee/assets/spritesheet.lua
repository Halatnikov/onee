local spritesheet = {}

----------------------------------------------------------------

function spritesheet.add(sprite, path, scene, name, anim, frame, animdef, framedef, export)
	local sheetdef = framedef.sheet
	
	sprite.cached_images[path] = sprite.cached_images[path] or love.image.newImageData(path)
	local imagedata = sprite.cached_images[path]
	
	sheetdef.x = sheetdef.x or animdef.sheet.x or 0
	sheetdef.y = sheetdef.y or animdef.sheet.y or animdef.sheet.x or 0
	sheetdef.width = sheetdef.width or animdef.sheet.width or imagedata:getWidth()
	sheetdef.height = sheetdef.height or animdef.sheet.height or animdef.sheet.width or imagedata:getHeight()
	
	local output = love.image.newImageData(sheetdef.width, sheetdef.height)
	output:paste(imagedata, 0, 0, sheetdef.x, sheetdef.y, sheetdef.width, sheetdef.height)
	
	local image = love.graphics.newImage(output)
	
	export[frame] = image
	atlas.add(scene, image, name, anim, frame)
	
	output = nil -- clear from memory
	collectgarbage()
end

function spritesheet.strip(sprite, path, scene, name, anim, animdef, export)
	local stripdef = animdef.strip
	assert(stripdef.frames, "spritesheet.strip() | no frame count specified in spritestrip for \""..path.."\"")
	
	sprite.cached_images[path] = sprite.cached_images[path] or love.image.newImageData(path)
	local imagedata = sprite.cached_images[path]
	
	stripdef.x = stripdef.x or 0
	stripdef.y = stripdef.y or 0
	stripdef.padding = stripdef.padding or 0
	
	-- TODO: sprites per row detection
	stripdef.mode = stripdef.mode or "horizontal"
	
	if stripdef.mode == "horizontal" then
		stripdef.width = stripdef.width or imagedata:getWidth() / stripdef.frames
		stripdef.height = stripdef.height or imagedata:getHeight()
	end
	if stripdef.mode == "vertical" then
		stripdef.width = stripdef.width or imagedata:getWidth()
		stripdef.height = stripdef.height or imagedata:getHeight() / stripdef.frames
	end
	
	animdef.frames = animdef.frames or {}
	for i=1, stripdef.frames do
		animdef.frames[i] = animdef.frames[i] or {}
		local framedef = animdef.frames[i]
		
		local x, y
		local width = stripdef.width
		local height = stripdef.height
		
		if stripdef.mode == "horizontal" then
			x = stripdef.x + (stripdef.width * (i - 1)) + (stripdef.padding * (i - 1))
			y = stripdef.y
		end
		if stripdef.mode == "vertical" then
			x = stripdef.x
			y = stripdef.y + (stripdef.height * (i - 1)) + (stripdef.padding * (i - 1))
		end
		
		framedef.sheet = {
			x = x, y = y,
			width = width, height = height,
		}
		
		spritesheet.add(sprite, path, scene, name, anim, i, animdef, framedef, export)
	end
	
end
----------------------------------------------------------------

return spritesheet