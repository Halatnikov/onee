spritesheet = {}

----------------------------------------------------------------
function spritesheet.add(path, frame, animdef, framedef, export)
	local sheetdef = framedef.sheet
	
	local image = love.graphics.newImage(path)
	
	if not sheetdef.x then sheetdef.x = animdef.sheet.x or 0 end
	if not sheetdef.y then sheetdef.y = animdef.sheet.y or animdef.sheet.x or 0 end
	if not sheetdef.width then sheetdef.width = animdef.sheet.width or image:getWidth() end
	if not sheetdef.height then sheetdef.height = animdef.sheet.height or animdef.sheet.width or image:getHeight() end
	
	local canvas = love.graphics.newCanvas(sheetdef.width, sheetdef.height)
	canvas:renderTo(function()
		love.graphics.draw(image, -sheetdef.x, -sheetdef.y)
	end)
	
	export[frame] = love.graphics.newImage(canvas:newImageData())
end

function spritesheet.strip(path, animdef, export)
	local stripdef = animdef.strip
	assert(stripdef.frames, "asset.sprite() | no frame count specified in spritestrip of animation \""..anim.."\" in \""..name.."\"")
	
	local image = love.graphics.newImage(path)
	
	if not stripdef.x then stripdef.x = 0 end
	if not stripdef.y then stripdef.y = 0 end
	-- TODO: only one horizontal row strips for now
	if not stripdef.width then stripdef.width = image:getWidth() / stripdef.frames end
	if not stripdef.height then stripdef.height = image:getHeight() end
	
	if not animdef.frames then animdef.frames = {} end
	for i=1, stripdef.frames do
		if not animdef.frames[i] then animdef.frames[i] = {} end
		local framedef = animdef.frames[i]
		
		framedef.sheet = {
			x = stripdef.x + (stripdef.width * (i - 1)),
			y = stripdef.y,
			width = stripdef.width,
			height = stripdef.height,
		}
		
		spritesheet.add(path, i, animdef, framedef, export])
	end
	
end
----------------------------------------------------------------

return spritesheet