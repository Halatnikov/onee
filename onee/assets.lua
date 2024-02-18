asset = {} -- functions
sprite = {}
model = {
	anim = {},
}
font = {}
text = {}

-- containers
fonts = {}

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

-- sub-types
local gif = require("onee/assets/gif")
local spritesheet = require("onee/assets/spritesheet")
local nineslice = require("onee/assets/nineslice")

---------------------------------------------------------------- AUXILLARY

--! UNLOAD ASSET
function asset.delete(name, scene)
	scene.assets[name] = nil
	
	scene.sprites[name] = nil
	scene.models[name] = nil
	
	collectgarbage()
end

--! helper for adding frames to sprite def
function asset.add_frames(count, x,y,length)
	local t = {}
	for i=1, count do
		t[i] = {
			x = x or 0,
			y = y or 0,
			length = length or 1,
		}
	end
	return t
end

--! helper for handling negative frame declarations
function asset.negative_frames(animdef)
	for frame in pairs(animdef.frames) do
		if frame < 0 then -- if your frame is -1, that means the last frame, -2 second to last and so on
			local i = (#animdef.frames+1) + frame
			animdef.frames[i] = table.append(animdef.frames[i], animdef.frames[frame])
		
			animdef.frames[frame] = nil
		end
	end
end

---------------------------------------------------------------- SPRITES

do--#region SPRITES
--! LOAD NEW SPRITE ASSET
function asset.sprite(path, scene, sprite) -- string, table, table=
	local name = string.tokenize(path, "/", -1)
	if scene.assets[name] then return end -- already loaded
	
	local time_start = love.timer.getTime()
	love.graphics.reset(true)
	window.draw(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		love.graphics.printf("loading sprite "..path, onee.width/2-150, onee.height-16, 150*2, "center")
	end)
	love.graphics.present()
	
	sprite = sprite or dofile("sprites/"..path) -- init
	scene.assets[name] = {}
	sprite.cached_images = {}
	
	-- first pass
	for anim, animdef in pairs(sprite.animations) do
		--print(anim)
		
		-- determine image types
		if sprite.gif then animdef.gif = true end
		
		-- load only unique images
		if not animdef.images then
			scene.assets[name][anim] = {} -- new anim entry
			local filename = sprite.filename or animdef.filename or anim

			-- look in animdef
			-- gif
			if animdef.gif then
				local imagepath = path.."/"..filename
				if files.exists("sprites/"..string.remove(imagepath, path.."/")..".gif") then 
					imagepath = string.remove(imagepath, path.."/")
				end
				
				gif.add("sprites/"..imagepath..".gif", animdef, scene.assets[name][anim])
			
			-- spritestrip (extension of spritesheet)
			elseif animdef.strip then
				local imagepath = path.."/"..filename
				if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
					imagepath = string.remove(imagepath, path.."/")
				end
				
				spritesheet.strip(sprite, "sprites/"..imagepath..".png", animdef, scene.assets[name][anim])
				
			-- look in framedef
			elseif animdef.frames then
				
				for frame, framedef in pairs(animdef.frames) do
					local filename = framedef.filename or filename
					
					-- spritesheet
					if framedef.sheet then
						local imagepath = path.."/"..filename
						if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
							imagepath = string.remove(imagepath, path.."/")
						end
						
						spritesheet.add(sprite, "sprites/"..imagepath..".png", frame, animdef, framedef, scene.assets[name][anim])
						
					-- one image file per frame (default)
					else
						local imagepath = path.."/"..filename.."_"..(frame-1)
						if framedef.filename then imagepath = path.."/"..filename end
						if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
							imagepath = string.remove(imagepath, path.."/")
						end
						
						local image = love.graphics.newImage("sprites/"..imagepath..".png")
						
						scene.assets[name][anim][frame] = image -- new frame entry
					end
					
				end
			
			-- no frames defined
			else
				-- get single frame from spritesheet
				if animdef.sheet then
					animdef.frames = {[1] = {sheet = {}}}
					local framedef = animdef.frames[1]
					
					local imagepath = path.."/"..filename
					if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
						imagepath = string.remove(imagepath, path.."/")
					end
					
					spritesheet.add(sprite, "sprites/"..imagepath..".png", 1, animdef, framedef, scene.assets[name][anim])
					
				-- get single frame from filename
				else
					animdef.frames = {[1] = {}}
					
					local imagepath = path.."/"..filename
					if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
						imagepath = string.remove(imagepath, path.."/")
					end
					
					local image = love.graphics.newImage("sprites/"..imagepath..".png")
					
					scene.assets[name][anim][1] = image -- new frame entry
				end
			end
			
		end
	end
	
	-- second pass
	for anim, animdef in pairs(sprite.animations) do
		asset.negative_frames(animdef)
		
		-- allow only one at a time
		if sprite.tiled then sprite.nineslice = nil end
		if sprite.nineslice then sprite.tiled = nil end
		
		for frame in pairs(animdef.frames) do
			local framedef = animdef.frames[frame]
			
			local image
			if not animdef.images then -- unique image
				image = scene.assets[name][anim][frame]
			else
				if not framedef.image then -- reused animation
					image = scene.assets[name][animdef.images][frame]
				else -- reused animation AND a different frame image
					image = scene.assets[name][animdef.images][framedef.image]
				end
			end
			assert(image, "asset.sprite() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..name.."\"")
			
			-- frame width/height
			framedef.width = framedef.width or image:getWidth()
			framedef.height = framedef.height or image:getHeight()
			
			-- tiled sprites
			if sprite.tiled then image:setWrap(TILE.TILE, TILE.TILE) end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- nine-slices
			if sprite.nineslice then
				nineslice.add(name, anim, frame, image, animdef, framedef, scene.assets[name])
			end
			
			-- add missing frame variables
			framedef.length = framedef.length or 1
			framedef.x = framedef.x or animdef.x or 0
			framedef.y = framedef.y or animdef.y or 0
			
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
		animdef.speed = animdef.speed or 0
		
	end
	
	sprite.cached_images = nil
	scene.sprites[name] = sprite -- done
	
	local time_finish = love.timer.getTime()
	print("sprite "..path.." took "..math.round(time_finish - time_start, 4))
end

--! INIT A NEW SPRITE INSTANCE
function sprite.init(sprite, scene, name, data)
	local spritedef = scene.sprites[name]
	assert(spritedef, "sprite.init() | \""..name.."\" is not a valid sprite!")
	
	local t = {
		sprite = true,
		name = name,
		active = true,
		visible = true,
		
		animation = "idle",
		animation_old = "idle",
		frame = 1,
		timer = 0,
		seq = "seq_start",
		seq_index = 1,
		loops = 0,
		
		anim_end = noop,
	}
	
	if scene.sprites[name].tiled then
		t.tiled = {
			quad = love.graphics.newQuad(0,0,0,0,0,0),
		}
	
	elseif scene.sprites[name].nineslice then
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
	
	t = table.protect(t, {"sprite", "name"})
	
	return table.append(sprite, t)
end

--! UPDATE SPRITE
function sprite.update(sprite, scene)
	assert((sprite and sprite.sprite), "sprite.update() | not a valid sprite")
	
	if not sprite.active then return end
	
	local spritedef = scene.sprites[sprite.name]
	assert(spritedef, "sprite.update() | no such sprite \""..sprite.name.."\"")
	
	local animdef = spritedef.animations[sprite.animation]
	assert(animdef, "sprite.update() | no such animation \""..sprite.animation.."\" in \""..sprite.name.."\"")
	
	-- update animations
	sprite.timer = sprite.timer + tick
	
	-- animation was changed from outside
	if sprite.animation ~= sprite.animation_old then
		sprite.speed = nil
		sprite.timer = 0
		sprite.seq = "seq_start"
		sprite.seq_index = 1
		sprite.loops = 0
	
		sprite.animation_old = sprite.animation
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
			sprite.anim_end(sprite.animation)
			
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

--! DRAW SPRITE
function sprite.draw(sprite, scene, args)
	assert((sprite and sprite.sprite), "sprite.draw() | not a valid sprite")
	
	if not sprite.visible then return end
	
	local spritedef = scene.sprites[sprite.name]
	assert(spritedef, "sprite.draw() | no such sprite \""..sprite.name.."\"")
	
	args = args or {}
	if args.queued == nil then args.queued = true end
	if args.queued == false then sprite.queued = false end
	
	-- basics
	local x = sprite.x or 0; x = math.round(x)
	local y = sprite.y or 0; y = math.round(y)
	local angle = sprite.angle or 0; angle = math.rad(math.round(angle))
	local scalex = sprite.scalex or sprite.scale or 1
	local scaley = sprite.scaley or sprite.scale or 1
	local skewx = sprite.skewx or 0
	local skewy = sprite.skewy or 0
	
	-- z order
	local z = sprite.z or 0
	
	-- opacity and tinting
	local rgb = sprite.rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = sprite.opacity or 100; opacity = opacity/100
	
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
		image = scene.assets[sprite.name][anim][frame]
	else
		if not framedef.image then -- reused animation
			image = scene.assets[sprite.name][animdef.images][frame]
		else -- reused animation AND a different frame image
			image = scene.assets[sprite.name][animdef.images][framedef.image]
		end
	end
	assert(image, "sprite.draw() | no image loaded for frame "..frame.." of animation \""..anim.."\" in \""..sprite.name.."\"")
	
	-- finally drawing itself
	local function draw() end
	
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
		draw = function()
			love.graphics.draw(image, quad, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end
		
	elseif spritedef.nineslice then -- NINE-SLICE SPRITE
	
		assert(sprite.nineslice, "sprite.draw() | no nine-slice instance in \""..sprite.name.."\"")
		local nwidth = sprite.nineslice.width or framedef.width
		local nheight = sprite.nineslice.height or framedef.height
		
		-- rebase origin points
		framex = nwidth * (framedef.x / framedef.width) or 0
		framey = nheight * (framedef.y / framedef.height) or 0
		
		draw = function()
			love.graphics.draw( nineslice.draw(sprite, scene, anim, frame, animdef, framedef),
			x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end
		
	else -- REGULAR SPRITE
		
		draw = function()
			love.graphics.draw(image, x, y, angle, scalex, scaley, framex, framey, skewx, skewy)
		end
		
	end
	
	if args.queued then
		queue.add(scene.drawlist, z, function()
			love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
			draw()
			love.graphics.reset()
		end)
	elseif args.ignorescale then
		window.pop()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		draw()
		window.push()
	else
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		draw()
		love.graphics.reset()
	end
end

--! DEBUG DRAW SPRITE
function sprite.debug_draw(sprite, scene)
	if not sprite.active then return end 
	if sprite.queued == false then return end
	
	local spritedef = scene.sprites[sprite.name]
	local animdef = spritedef.animations[sprite.animation]
	local framedef = animdef.frames[sprite.frame]
	
	if not sprite.debug then
		sprite.debug = {
			rgb = {math.random(0,255), math.random(0,255), math.random(0,255)},
			highlighted = false,
		}
	end
	
	local mode = sprite.debug.highlighted and "fill" or "line"
	
	love.graphics.setColor(sprite.debug.rgb[1]/255, sprite.debug.rgb[2]/255, sprite.debug.rgb[3]/255, 0.5)
	love.graphics.setLineWidth(3)
	
	local x = sprite.x or 0 
	local y = sprite.y or 0 
	local scalex = sprite.scalex or sprite.scale or 1; scalex = math.abs(scalex)
	local scaley = sprite.scaley or sprite.scale or 1; scaley = math.abs(scaley)
	local angle = sprite.angle or 0
	
	local bbox_x = x - (framedef.x * scalex)
	local bbox_y = y - (framedef.y * scaley)
	local width = scalex * framedef.width
	local height = scaley * framedef.height
	
	-- bbox
	if sprite.tiled then
		if angle ~= 0 then
			local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
			local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
			
			love.graphics.polygon(mode, poly.unpack(bbox))
		else
			love.graphics.rectangle(mode, bbox_x, bbox_y, width, height)
		end
	elseif sprite.nineslice then
		if angle ~= 0 then
			local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
			local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
			
			love.graphics.polygon(mode, poly.unpack(bbox))
		else
			love.graphics.rectangle(mode, bbox_x, bbox_y, width, height)
		end
	else
		if angle ~= 0 then
			local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
			local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
			
			love.graphics.polygon(mode, poly.unpack(bbox))
		else
			love.graphics.rectangle(mode, bbox_x, bbox_y, width, height)
		end
	end
	
	-- origin
	love.graphics.line(x-4, y, x+4, y)
	love.graphics.line(x, y-4, x, y+4)
	
	love.graphics.reset()
end
end--#endregion

---------------------------------------------------------------- 3D MODELS

do--#region 3D MODELS
--! LOAD NEW 3D MODEL ASSET
function asset.model(path, scene)
	local name = string.tokenize(path, "/", -1)
	if scene.assets[name] then return end -- already loaded
	
	local time_start = love.timer.getTime()
	love.graphics.reset(true)
	window.draw(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		love.graphics.printf("loading model "..path, onee.width/2-150, onee.height-16, 150*2, "center")
	end)
	love.graphics.present()
	
	local model = json.decode(love.filesystem.read("models/"..path.."/"..name..".gltf")) -- init
	local modeldef = {}
	if files.exists("models/"..path..".lua") then modeldef = dofile("models/"..path) end
	
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
		for mat, matdef in pairs(modeldef.materials) do
			model.materials[mat].alphaMode = matdef.alphaMode or nil
			model.materials[mat].doubleSided = matdef.doubleSided or nil
		end
	end
	
	scene.assets[name] = gltf.newAsset(model)
	scene.assets[name]:continueLoading(5)
	
	scene.models[name] = modeldef -- done
	
	local time_finish = love.timer.getTime()
	print("model "..path.." took "..math.round(time_finish - time_start, 4))
end

local vec3 = require "onee/libs/gltf/cpml.modules.vec3"
local mat4 = require "onee/libs/gltf/cpml.modules.mat4"

--! INIT A NEW 3D MODEL INSTANCE
function model.init(model, scene, name, data)
	assert(scene.models[name], "model.init() | \""..name.."\" is not a valid 3d model!")
	
	local t = {
		model = true,
		name = name,
		active = true,
		visible = true,
		
		instance = scene.assets[name]:newInstance(1),
		projection = gltf.newRenderer(),
		canvas = {
			main = love.graphics.newCanvas(onee.width, onee.height),
			depth = love.graphics.newCanvas(onee.width, onee.height, {format = "depth32f"}),
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

--! UPDATE 3D MODEL
function model.update(model, scene)
	assert((model and model.model), "model.update() | not a valid 3d model")
	
	if not model.active then return end
	
	local modeldef = scene.models[model.name]
	assert(modeldef, "model.update() | no such model \""..model.name.."\"")
	
	local width = model.canvas.width or onee.width
	local height = model.canvas.height or onee.height
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
	for i=1, #playing do
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

--! DRAW 3D MODEL
function model.draw(model, scene)
	assert((model and model.model), "model.draw() | not a valid 3d model")
	
	if not model.visible then return end
	
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
	
	queue.add(scene.drawlist, z, function()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		love.graphics.draw(model.canvas.main, x, y, angle, scalex, scaley, xoffset, yoffset, skewx, skewy)
		love.graphics.reset()
	end)
end
end--#endregion

---------------------------------------------------------------- SPRITEFONTS

do--#region SPRITEFONTS

--! LOAD NEW SPRITEFONT ASSET
-- an extension of sprite
function asset.spritefont(path)
	local name = string.tokenize(path, "/", -1)
	if fonts[name] then return end -- already loaded
	
	local time_start = love.timer.getTime()
	love.graphics.reset(true)
	window.draw(function()
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		love.graphics.printf("preprocessing font "..path, onee.width/2-150, onee.height-16, 150*2, "center")
	end)
	love.graphics.present()
	
	local sprite = dofile("sprites/"..path) -- init
	fonts[name] = {}
	sprite.cached_images = {}
	
	sprite.tiled = nil -- nope
	sprite.nineslice = nil
	
	local font = fonts[name]
	
	-- mini scene for storing assets
	font.scene = {
		scene = true,
		fontscene = true,
		name = name,
		
		assets = {},
		sprites = {},
		
		instances = {},
	}
	font.scene = table.protect(font.scene, {"scene", "font"})
	
	local fontdef = sprite.font
	font.font = fontdef
	fontdef.spacing = fontdef.spacing or 0
	fontdef.linespacing = fontdef.linespacing or 0
	assert(fontdef.baseheight, "asset.spritefont() | no baseheight specified")
	
	-- static character rows helper
	if fontdef.rows then
		for i, row in ipairs(fontdef.rows) do
			local filename = row.filename or sprite.filename
			
			local imagepath = path.."/"..filename
			if files.exists("sprites/"..string.remove(imagepath, path.."/")..".png") then 
				imagepath = string.remove(imagepath, path.."/")
			end
			imagepath = "sprites/"..imagepath..".png"
			
			sprite.cached_images[imagepath] = sprite.cached_images[imagepath] or love.image.newImageData(imagepath)
			local imagedata = sprite.cached_images[imagepath]
			
			local chars = string.split(row.chars)
			row.x = row.x or 0
			row.y = row.y or 0
			row.width = row.width or fontdef.basewidth or imagedata:getWidth()
			row.height = row.height or fontdef.baseheight or imagedata:getHeight()
			
			local xoffset = row.x
			
			for i=1, #chars do
				local x, width
				
				for j = xoffset, row.width do
					local done = false
					local r, g, b
					
					if j >= row.width then done = true end
					
					if not done then r, g, b = imagedata:getPixel(j, row.y) end
					if (r == 1 and g == 0 and b == 1) then done = true end -- pink line separator
					
					if done then
						x = xoffset
						width = j - xoffset
						
						xoffset = j + 1
						break
					end
				end
				
				local t  = {
					filename = filename,
					sheet = {x = x, y = row.y, width = width, height = row.height},
				}
				
				sprite.animations[chars[i]] = sprite.animations[chars[i]] or {}
				table.append(sprite.animations[chars[i]], t)
			end
			
		end
	end
	
	local time_finish = love.timer.getTime()
	print("font "..path.." took "..math.round(time_finish - time_start, 4))
	
	sprite.cached_images = nil
	asset.sprite(path, font.scene, sprite) -- done, move on
end

--!
function font.append(font, arg)
	if type(font) == "string" then font = fonts[font] end
	if type(arg) ~= "table" then arg = {arg} end
	local fontscene = font.scene
	
	for k,v in ipairs(arg) do
		if type(v) == "string" then v = fonts[v] end
		local name = v.scene.name
		
		fontscene.assets[name] = v.scene.assets[name]
		fontscene.sprites[name] = v.scene.sprites[name]
	end
end

--!
function text.new(id, scene)
	local t = {
		instance = true,
		fontinstance = true,
		scene = scene.name,
		id = id,
		
		sprites = {},
	}
	t = table.protect(t, {"instance", "id", "scene", "text"})
	
	scene.instances[id] = t
	
	return t
end

--! alias
function text.printf(arg, font, x, y, limit, alignh, alignv, r, sx, sy, ox, oy, kx, ky)
	return text.print(arg, font, x, y, r, sx, sy, ox, oy, kx, ky, limit, alignh, alignv)
end

--!
function text.print(arg, font, x, y, r, sx, sy, ox, oy, kx, ky, limit, alignh, alignv)
	if type(arg) == "string" then arg = {arg} end
	if type(font) == "string" then font = fonts[font] end
	
	x = x or 0; x = math.round(x)
	y = y or 0; y = math.round(y)
	r = r or 0; r = math.round(r)
	sx = sx or 1
	sy = sy or sx or 1
	ox = ox or 0
	oy = oy or 0
	kx = kx or 0
	ky = ky or 0
	
	limit = limit or nil
	alignh = alignh or "left"
	alignv = alignv or "top"
	
	local fontscene = font.scene
	local fontdef = font.font
	
	-- update or create instance
	local id = string.md5(tostring(font)..x..y..r..sx..sy..ox..oy..kx..ky)
	fontscene.instances[id] = fontscene.instances[id] or text.new(id, fontscene)
	local instance = fontscene.instances[id]
	
	instance.timer = (instance.timer or 0) + dt
	instance.dt = dt
	
	local curx, cury = 0, 0
	local width, height = 0, fontdef.baseheight
	
	local charcount = 0
	local totalchars = 0
	
	local lines = {[1] = {}}
	local curline = 1
	
	-- print character function
	local function printchar(char)
		local curfont
		
		if char == newline then 
			curline = curline + 1
			charcount = 0
			curx = 0
			cury = cury + fontdef.baseheight + fontdef.linespacing
			height = height + cury
			
			lines[curline] = {}
		end
		
		-- find character in available fonts
		if fontscene.assets[fontscene.name][char] then -- main font takes priority
			curfont = fontscene.name
		else
			for k, font in pairs(fontscene.assets) do -- look in appended fonts
				if k ~= fontscene.name and font[char] then 
					curfont = k
					break
				end
			end
		end
		
		if curfont then
			charcount = charcount + 1
			totalchars = totalchars + 1
			
			-- sprite per character
			instance.sprites[curline] = instance.sprites[curline] or {}
			instance.sprites[curline][charcount] = instance.sprites[curline][charcount]
				or sprite.init(instance.sprites[curline][charcount], fontscene, curfont, {animation = char})
			
			local charsprite = instance.sprites[curline][charcount]
			
			local spritedef = fontscene.sprites[curfont]
			local animdef = spritedef.animations[char]
			local framedef = animdef.frames[charsprite.frame]
			
			local curfontdef = spritedef.font
			
			charsprite.x = curx
			charsprite.y = cury
			
			charsprite.realx = curx
			charsprite.realy = cury
			charsprite.num = charcount
			charsprite.numtotal = totalchars
			charsprite.char = char
			
			curx = curx + framedef.width + curfontdef.spacing
			lines[curline].width = curx
			lines[curline].charcount = charcount
			
			return charsprite
		end
	end
	
	-- main function
	local function handlechunk(chunk, func)
		local text = tostring(chunk[#chunk])
		func = func or noop
			
		-- loop through characters
		for i, char in ipairs(string.split(text)) do
			local charsprite = printchar(char)
			
			if charsprite then
				func(charsprite, i)
			end
		end
	end
	
	-- iterator function
	local function loopchunks(arg)
		for i, chunk in ipairs(arg) do
			if type(chunk) ~= "table" then chunk = {chunk} end
			
			-- "text" chunk
			if #chunk == 1 then
				if string.left(chunk[1], 1) == "{" and string.right(chunk[1], 1) == "}" then
					-- inline icon
					local icon = string.sub(chunk[1], 2, -2)
					local char
					
					-- input icons
					if string.find(icon, "input_") then
						local button = string.tokenize(icon, "_", 2)
						
						if input.mode == "keyboard" then 
							local prefix = "key_"
							local config = config.input.keyboard[button]
							
							if config then
								if config.k then
									icon = prefix..config.k[1]
								elseif config.m then
									
								elseif config.mw then
									
								else
									icon = "null"
								end
							else
								icon = "null"
							end
						end
						
						char = printchar(icon)
						if not char then char = printchar("unknown") end
						
					else
						-- regular icons
						char = printchar(icon)
					end
					
					local spritedef = fontscene.sprites[char.name]
					local animdef = spritedef.animations[icon]
					local framedef = animdef.frames[char.frame]
					
					-- center icon vertically
					char.y = char.realy + (fontdef.baseheight - framedef.height) / 2
				else
					-- regular text
					handlechunk(chunk)
				end
			
			-- {{effects}, "text"} chunk 
			elseif #chunk == 2 then
				local effects = chunk[1]
				if type(effects) == "string" then effects = {effects} end
				if #effects == 1 then effects = {effects} end
				
				if (#effects == 3 or #effects == 4) then effects = {effects} end -- color alias
				
				handlechunk(chunk, function(char, i)
					for i, effect in ipairs(effects) do
						local effect = copy(effect)
						if type(effect) == "string" then effect = {effect} end
						
						-- apply color
						if (#effect == 3 or #effect == 4) and type(effect[1] == "number") then
							table.insert(effect, 1, "color") -- alias
						end
						if effect[1] == "color" then
							local r, g, b = effect[2], effect[3], effect[4]
							local a = effect[5] or 100
							
							char.rgb = {r, g, b}
							char.opacity = a
						end
						
						-- shaking text
						if effect[1] == "shake" then
							local strengthx = effect.strengthx or effect.strength or 1
							local strengthy = effect.strengthy or effect.strength or 1
							local range = effect.range or {-1, 1}
							
							char.x = char.realx + (char.num * math.random(range[1], range[2]) * ((strengthx / 2) / charcount))
							char.y = char.realy + (char.num * math.random(range[1], range[2]) * ((strengthy / 2) / charcount))
						end
						
					end
				end)
				
			end
			
		end
	end
	
	-- loop through all chunks
	loopchunks(arg)
	
	instance.height = height
	instance.lines = lines
	instance.totalchars = totalchars
	
	-- final draw	
	love.graphics.push()
	
	love.graphics.translate(x, y)
	love.graphics.rotate(math.rad(r))
	love.graphics.scale(sx, sy)
	love.graphics.shear(kx, ky)
	love.graphics.translate(-ox, -oy)
	
	for i, line in pairs(instance.sprites) do
		for i, charsprite in pairs(line) do
			sprite.update(charsprite, fontscene)
			sprite.draw(charsprite, fontscene, {queued = false})
		end
	end
	
	love.graphics.pop()
	
	-- clean inactive instances
	-- for k,v in pairs(fontscene.instances) do
		-- if v.dt ~= dt then fontscene.instances[k] = nil end
	-- end
	
	return instance -- that way you can do `local the = text.print("returns an instance", 0, 0)`
end
end--#endregion

_prof.hook("asset")
_prof.hook("sprite")
_prof.hook(gif, "gif")
_prof.hook(nineslice, "nineslice")
_prof.hook(spritesheet, "spritesheet")
_prof.hook("model")
_prof.hook("text")