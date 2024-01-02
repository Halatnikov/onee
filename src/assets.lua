asset = {} -- functions
sprite = {}
model = {
	anim = {}
}

assets = {} -- actual containers
sprites = {}
models = {}

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
local spritesheet = require("src/assets/spritesheet")
local nineslice = require("src/assets/nineslice")

---------------------------------------------------------------- ASSETS

function asset.sprite(path) -- LOAD NEW SPRITE ASSET --
	
	local name = string.tokenize(path, "/", -1)
	if assets[name] then return end -- already loaded
	
	local time_start = love.timer.getTime()
	local sprite = require("sprites/"..path) -- init
	assets[name] = {}
	
	-- first pass
	for anim in pairs(sprite.animations) do
		local animdef = sprite.animations[anim]
		
		-- determine image types
		if sprite.gif then animdef.gif = true end
		
		-- load only unique images
		if not animdef.images then
			assets[name][anim] = {} -- new anim entry
			local filename = sprite.filename or animdef.filename or anim

			-- look in animdef
			-- gif
			if animdef.gif then
				gif.add("sprites/"..path.."/"..filename..".gif", animdef, assets[name][anim])
			
			-- spritestrip (extension of spritesheet)
			elseif animdef.strip then
				spritesheet.strip("sprites/"..path.."/"..filename..".png", animdef, assets[name][anim])
				
			else
				-- look in framedef
				for frame in pairs(animdef.frames) do
					local framedef = animdef.frames[frame]
					
					-- spritesheet
					if framedef.sheet then
						spritesheet.add("sprites/"..path.."/"..filename..".png", frame, animdef, framedef, assets[name][anim])
						
					-- one image file per frame (default)
					else
						local imagepath = path.."/"..filename.."_"..(frame-1)
						if framedef.filename then imagepath = path.."/"..framedef.filename end
						
						local image = love.graphics.newImage("sprites/"..imagepath..".png")
						
						assets[name][anim][frame] = image -- new frame entry
					end
					
				end
			end
			
		end
	end
	
	-- second pass
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
			if sprite.nineslice then
				nineslice.add(name, anim, frame, image, animdef, framedef)
			end
			
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
	
	local time_finish = love.timer.getTime()
	print("took "..math.round(time_finish - time_start, 4))
	
end

function asset.model(path) -- LOAD NEW 3D MODEL ASSET --
	
	local name = string.tokenize(path, "/", -1)
	if assets[name] then return end -- already loaded
	
	local model = json.decode(love.filesystem.read("models/"..path.."/"..name..".gltf")) -- init
	local modeldef = {}
	if files.exists("models/"..path..".lua") then modeldef = require("models/"..path) end
	
	-- overwrite texture images
	if model.images then
		for i=1, #model.images do
			local texture = model.textures[i].name or model.images[i].name..".png"
			
			if files.exists("models/"..path.."/"..texture) then
				local image = love.filesystem.read("models/"..path.."/"..texture)
				
				model.images[i].uri = "data:image/png;base64,"..love.data.encode("string", "base64", image)
			end
		end
	end
	
	-- animation definitions
	if model.animations then
		modeldef.animationsref = {}
		
		if not modeldef.animations then modeldef.animations = {} end
		
		for i=1, #model.animations do
			if not modeldef.animations[model.animations[i].name] then
				modeldef.animations[model.animations[i].name] = {
					loop = true,
				}
			end
			modeldef.animationsref[i] = model.animations[i].name
		end
	end
	
	-- overwrite materials
	if modeldef.materials then
		for mat in pairs(modeldef.materials) do
			model.materials[mat].alphaMode = modeldef.materials[mat].alphaMode or nil
			model.materials[mat].doubleSided = modeldef.materials[mat].doubleSided or nil
		end
	end
	
	assets[name] = gltf.newAsset(model)
	assets[name]:continueLoading(5)
	
	models[name] = modeldef -- done
	
end

function asset.delete(name) -- UNLOAD ASSET
	assets[name] = nil
	
	sprites[name] = nil
	models[name] = nil
	
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
		if frame < 0 then -- if your frame is -1, that means the last frame, -2 second to last and so on
			local i = (#animdef.frames+1) + frame
			animdef.frames[i] = table.append(animdef.frames[i], animdef.frames[frame])
		
			animdef.frames[frame] = nil
		end
	end
end

---------------------------------------------------------------- SPRITES

function sprite.init(sprite, name, data) -- INIT A NEW SPRITE INSTANCE --
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
		t.tiled = {
			quad = love.graphics.newQuad(0,0,0,0,0,0),
		}
	
	elseif sprites[name].nineslice then
		t.nineslice = {
			qleft = love.graphics.newQuad(0,0,0,0,0,0),
			qright = love.graphics.newQuad(0,0,0,0,0,0),
			qtop = love.graphics.newQuad(0,0,0,0,0,0),
			qbottom = love.graphics.newQuad(0,0,0,0,0,0),
			qbody = love.graphics.newQuad(0,0,0,0,0,0),
			
			canvas = love.graphics.newCanvas(1,1),
		}
	end
	
	table.append(t, data) -- additional data
	
	return table.append(sprite, t)
end

function sprite.update(sprite) -- UPDATE SPRITE --
	
	assert(sprite, "sprite.update() | not a valid sprite")
	assert(sprite.sprite, "sprite.update() | not a valid sprite")
	assert(sprites[sprite.name], "sprite.update() | not a valid sprite")
	local animdef = sprites[sprite.name].animations[sprite.animation]
	assert(animdef, "sprite.update() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	
	-- update animations
	sprite.timer = sprite.timer + tick
	
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
	
	local framedef = animdef.frames[sprite.frame]
	assert(framedef, "sprite.update() | no such frame "..sprite.frame.." of animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	
	-- advance frame
	if sprite.timer > 1 / (speed / framedef.length) then
		sprite.timer = 0
		
		sprite.seq_index = sprite.seq_index + 1
		if sprite.seq_index > #animdef[sprite.seq] then -- animation reached end
			-- callback
			if sprite.anim_end then sprite.anim_end() end
			
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
	
	-- update nine-slice canvas size
	if sprite.nineslice then
		local nwidth = sprite.nineslice.width or framedef.width
		local nheight = sprite.nineslice.height or framedef.height
		
		if sprite.nineslice.canvas:getWidth() ~= nwidth or sprite.nineslice.canvas:getHeight() ~= nheight then
			sprite.nineslice.canvas = love.graphics.newCanvas(nwidth, nheight)
		end
	end
	
end

function sprite.draw(sprite) -- DRAW SPRITE --

	assert(sprite, "sprite.draw() | not a valid sprite")
	assert(sprite.sprite, "sprite.draw() | not a valid sprite")
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
	
	-- z order
	local z = sprite.z or 0
	
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
		
		assert(sprite.tiled, "sprite.draw() | no tiled instance in \""..sprite.name.."\"")
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
		queue.add(scenes.drawlist, z, function()
			love.graphics.draw(image, quad, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end)
		
	elseif spritedef.nineslice then -- NINE-SLICE SPRITE
	
		assert(sprite.nineslice, "sprite.draw() | no nine-slice instance in \""..sprite.name.."\"")
		local nwidth = sprite.nineslice.width or framedef.width
		local nheight = sprite.nineslice.height or framedef.height
		
		-- rebase origin points
		framex = nwidth * (framedef.x / framedef.width) or 0
		framey = nheight * (framedef.y / framedef.height) or 0
		
		queue.add(scenes.drawlist, z, function()
			love.graphics.draw( nineslice.draw(sprite, anim, frame, animdef, framedef),
			x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end)
		
	else -- REGULAR SPRITE
		
		queue.add(scenes.drawlist, z, function()
			love.graphics.draw(image, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end)
		
	end
	
	love.graphics.reset()
end

---------------------------------------------------------------- 3D MODELS

local vec3 = require "src/libs/gltf/cpml.modules.vec3"
local mat4 = require "src/libs/gltf/cpml.modules.mat4"

function model.init(model, name, data) -- INIT A NEW 3D MODEL INSTANCE --
	assert(models[name], "model.init() | \""..name.."\" is not a valid 3d model!")
	
	local t = {
		model = true,
		name = name,
		
		instance = assets[name]:newInstance(1),
		projection = gltf.newRenderer(),
		canvas = {
			main = love.graphics.newCanvas(windowwidth, windowheight),
			depth = love.graphics.newCanvas(windowwidth, windowheight, {format = "depth32f"}),
		},
		viewport = {
			pos = vec3.new(0, 0, -1),
			transform = mat4.new(),
		},
	}
	
	table.append(t, data) -- additional data
	
	t.projection:setCanvases(t.canvas.main, t.canvas.depth)
	
	t.instance:playAnimation(1) --temp
	
	return table.append(model, t)
end

function model.update(model) -- UPDATE 3D MODEL --
	assert(model, "model.update() | not a valid 3d model")
	assert(model.model, "model.update() | not a valid 3d model")
	
	local modeldef = models[model.name]
	
	local width = model.canvas.width or windowwidth
	local height = model.canvas.height or windowheight
	local fov = model.fov or 45
	local scale = model.scale or 1
	local anglex = model.angle and model.angle.x or 0; anglex = math.rad(anglex)
	local angley = model.angle and model.angle.y or 0; angley = math.rad(angley)
	local anglez = model.angle and model.angle.z or 0; anglez = math.rad(anglez)
	
	-- update the canvas size
	if model.canvas.main:getWidth() ~= width or model.canvas.main:getHeight() ~= height then
		model.canvas.main = love.graphics.newCanvas(width, height)
		model.canvas.depth = love.graphics.newCanvas(width, height, {format = "depth32f"})
		
		model.projection:setCanvases(model.canvas.main, model.canvas.depth)
	end
	
	-- update animations
	-- TODO: loop count, seek to time (progress 0 to 1?, pause
	-- TODO: add animation, remove animation, stop all, set animation (string or a table)
	-- model.anim.state(model, {idle = {seek = 0.5, pause = true}})
	local playing = model.instance.activePlayHeads
	for i in pairs(playing) do
		if not modeldef.animations then break end -- no animations
		local animdef = modeldef.animations[modeldef.animationsref[i]]
		
		local speed = 1
		
		-- loop
		if animdef.loop then
			if playing[i].time >= (playing[i].maxTime - tick) then
				playing[i].time = 0
			end
		end
		
		model.instance:updateAnimation(i, tick * speed)
	end
	
	-- viewport/"camera" position
	-- Z is basically model's "scale", front of a model is north, so Z = -1
	-- models are centered by 0,0 so you need to use offsets to actually center it
	-- TODO: maybe actual scaling?
	model.viewport.pos.x = model.xoffset or 0
	model.viewport.pos.y = model.yoffset or 0
	model.viewport.pos.z = model.z or -(fov * (math.average(width, height) / fov)) / scale
	
	-- set projection matrix (fov, aspect ratio, clip distance min, max)
	model.projection:setProjectionMatrix(mat4.from_perspective(fov, (width / height), 0.1, 1000))
	
	-- set view matrix
	local transform = model.viewport.transform
	local center_y = vec3.new(0, 1, 0)		-- direction that represents up
	local center_z = vec3.new(0, 0, 1)		-- "eye" position of the viewport
	transform:look_at(transform, model.viewport.pos, model.viewport.pos + center_z, center_y)
	transform:translate(transform, -model.viewport.pos)
	
	-- model angles
	transform:rotate(transform, anglex, vec3.new(1, 0, 0)) -- x
	transform:rotate(transform, angley, vec3.new(0, 1, 0)) -- y
	transform:rotate(transform, anglez, vec3.new(0, 0, 1)) -- z
	
	model.projection:setViewMatrix(transform)
	
end

function model.draw(model) -- DRAW 3D MODEL --
	assert(model, "model.draw() | not a valid 3d model")
	assert(model.model, "model.draw() | not a valid 3d model")
	
	-- the model itself
	model.projection:addToDrawList(model.instance)
	model.projection:draw()
	
	-- handle the canvas
	local x = model.x or model.canvas.x or 0; x = math.round(x)
	local y = model.y or model.canvas.y or 0; y = math.round(y)
	local angle = model.canvas.angle or 0; angle = math.rad(angle)
	local scalex = model.canvas.scalex or 1
	local scaley = model.canvas.scaley or 1
	local xoffset = model.canvas.xoffset or 0
	local yoffset = model.canvas.yoffset or 0
	local skewx = model.skewx or model.canvas.skewx or 0
	local skewy = model.skewy or model.canvas.skewy or 0
	local z = model.canvas.z or 0
	
	-- opacity and tinting
	local rgb = model.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = model.opacity or 100; opacity = opacity/100
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
	
	queue.add(scenes.drawlist, z, function()
		love.graphics.draw(model.canvas.main, x, y, angle, scalex, scaley, xoffset, yoffset, skewx, skewy)
	end)
	
	love.graphics.reset()
end