asset = {} -- functions
sprite = {}
model = {
	anim = {},
}

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
function asset.sprite(path, scene)
	local name = string.tokenize(path, "/", -1)
	if scene.assets[name] then return end -- already loaded
	
	print("loading sprite "..path)
	local time_start = love.timer.getTime()
	
	local sprite = dofile("sprites/"..path) -- init
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
				gif.add("sprites/"..path.."/"..filename..".gif", animdef, scene.assets[name][anim])
			
			-- spritestrip (extension of spritesheet)
			elseif animdef.strip then
				spritesheet.strip(sprite, "sprites/"..path.."/"..filename..".png", animdef, scene.assets[name][anim])
				
			-- look in framedef
			elseif animdef.frames then
				
				for frame, framedef in pairs(animdef.frames) do
					-- spritesheet
					if framedef.sheet then
						spritesheet.add(sprite, "sprites/"..path.."/"..filename..".png", frame, animdef, framedef, scene.assets[name][anim])
						
					-- one image file per frame (default)
					else
						local imagepath = filename.."_"..(frame-1)
						if framedef.filename then imagepath = framedef.filename end
						local image = love.graphics.newImage("sprites/"..path.."/"..imagepath..".png")
						
						scene.assets[name][anim][frame] = image -- new frame entry
					end
					
				end
			
			-- get single frame from filename if no frames defined
			else
				animdef.frames = {[1] = {}}
				local image = love.graphics.newImage("sprites/"..path.."/"..filename..".png")
				
				scene.assets[name][anim][1] = image -- new frame entry
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
			if not framedef.width then framedef.width = image:getWidth() end
			if not framedef.height then framedef.height = image:getHeight() end
			
			-- tiled sprites
			if sprite.tiled then image:setWrap(TILE.TILE, TILE.TILE) end
			if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
			if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
			
			-- nine-slices (9patches)
			if sprite.nineslice then
				nineslice.add(name, anim, frame, image, animdef, framedef, scene.assets[name])
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
	
	sprite.cached_images = nil
	scene.sprites[name] = sprite -- done
	
	local time_finish = love.timer.getTime()
	print("took "..math.round(time_finish - time_start, 4))
end

--! INIT A NEW SPRITE INSTANCE
function sprite.init(sprite, scene, name, data)
	assert(scene.sprites[name], "sprite.init() | \""..name.."\" is not a valid sprite!")
	
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
			if sprite.anim_end then sprite.anim_end(sprite.animation) end
			
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
function sprite.draw(sprite, scene, queued)
	assert((sprite and sprite.sprite), "sprite.draw() | not a valid sprite")
	
	if not sprite.visible then return end
	
	local spritedef = scene.sprites[sprite.name]
	assert(spritedef, "sprite.draw() | no such sprite \""..sprite.name.."\"")
	
	if queued == nil then queued = true end
	if queued == false then sprite.queued = false end
	
	-- basics
	local x = sprite.x or 0; x = math.round(x)
	local y = sprite.y or 0; y = math.round(y)
	local angle = sprite.angle or 0; angle = math.round(angle); angle = math.rad(angle)
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
	
	if queued then
		queue.add(scene.drawlist, z, function()
			love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
			draw()
			love.graphics.reset()
		end)
	else
		resolution.pop()
		love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
		draw()
		resolution.push()
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
		local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
		local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
		
		love.graphics.polygon(mode, poly.unpack(bbox))
	elseif sprite.nineslice then
		local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
		local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
		
		love.graphics.polygon(mode, poly.unpack(bbox))
	else
		local bbox_old = poly.rect(bbox_x, bbox_y, width, height)
		local bbox = poly.rotate(bbox_old, angle, framedef.x * scalex, framedef.y * scaley)
		
		love.graphics.polygon(mode, poly.unpack(bbox))
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
	
	print("loading model "..path)
	local time_start = love.timer.getTime()
	
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
	print("took "..math.round(time_finish - time_start, 4))
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

--! UPDATE 3D MODEL
function model.update(model, scene)
	assert((model and model.model), "model.update() | not a valid 3d model")
	
	if not model.active then return end
	
	local modeldef = scene.models[model.name]
	assert(modeldef, "model.update() | no such model \""..model.name.."\"")
	
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

_prof.hook("asset")
_prof.hook("sprite")
_prof.hook(gif, "gif")
_prof.hook(nineslice, "nineslice")
_prof.hook(spritesheet, "spritesheet")
_prof.hook("model")