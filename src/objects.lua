
objects = {}
instances = {}

assets = {}
sprites = {}

function instances_update() -- MAIN UPDATE LOOP --
	for k,v in pairs(instances) do
		if type(v) ~= "function" then
		
			-- update all instances
			if instances[k].update and instances[k].active then instances[k].update(k) end
			
			-- animate the instances
			if instances[k].animation then instances.animate(k) end
			
		end
	end
end

function instances_draw() -- MAIN DRAW LOOP --
	for k,v in pairs(instances) do
		if type(v) ~= "function" then
			
			if instances[k].draw then instances[k].draw(k) end
			
			instances.draw(k)
			
		end
	end
end

--------------------------------------------------------------- INSTANCES

function instances.draw(id) -- DRAW INSTANCE --
	
	local object = instances[id].object
	
	if not objects[object].sprite then return end
	
	local x = math.round(instances[id].x) or 0
	local y = math.round(instances[id].y) or 0
	local angle = instances[id].angle or 0; angle = math.rad(angle)
	local scalex = instances[id].scalex or 1
	local scaley = instances[id].scaley or 1
	
	local rgb = instances[id].rgb or {255,255,255}; rgb = {rgb[1]/255, rgb[2]/255, rgb[3]/255}
	local opacity = instances[id].opacity or 100; opacity = opacity/100
	
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], opacity)
	
	if objects[object].sprite then -- SPRITE
		local sprite = objects[object].sprite
		local anim = instances[id].animation.name
		local frame = instances[id].animation.frame
		
		local frame_x = sprites[sprite].animations[anim].frames[frame].x or 0
		local frame_y = sprites[sprite].animations[anim].frames[frame].y or 0
		
		if instances[id].width then
			scalex = instances[id].width / sprites[sprite].animations[anim].frames[frame].width
		end
		if instances[id].height then
			scaley = instances[id].height / sprites[sprite].animations[anim].frames[frame].height
		end
	
		local image
		if not sprites[sprite].animations[anim].anim then
			image = assets[sprite][anim][frame]
		else
			image = assets[sprite][sprites[sprite].animations[anim].anim][frame]
		end
		
		if not sprites[sprite].tiled then -- REGULAR SPRITE
			love.graphics.draw(image, x, y, angle, scalex, scaley, frame_x, frame_y)
		end
		
		if sprites[sprite].tiled then -- TILED SPRITE
			local quad = instances[id].quad
			
			local qref_width = sprites[sprite].animations[anim].frames[frame].width
			local qref_height = sprites[sprite].animations[anim].frames[frame].height
			
			local qx = instances[id].qx or 0
			local qy = instances[id].qy or 0
			local qwidth = instances[id].qwidth or qref_width; qwidth = math.floor(qwidth)
			local qheight = instances[id].qheight or qref_height; qheight = math.floor(qheight)
			
			quad:setViewport(qx, qy, qwidth, qheight, qref_width, qref_height)
			love.graphics.draw(image, quad, x, y, angle, scalex, scaley, frame_x, frame_y)
		end
	end
	
end

function instances.animate(id) -- ANIMATE INSTANCE --
	
	local object = instances[id].object
	
	if not objects[object].sprite then return end
	
	local anim = instances[id].animation -- this is the INSTANCE, what's being WRITTEN
	local data							 -- this is the SPRITE, what's being READ
	
	if objects[object].sprite then -- instance is of a sprite
		data = sprites[objects[object].sprite].animations[anim.name]
	end
	
	anim.timer = anim.timer + dt
	
	-- animation was changed from outside
	if anim.current ~= anim.name then
		anim.speed = nil
		
		anim.current = anim.name
	
		anim.timer = 0
		anim.seq = "seq_start"
		anim.seq_index = 1
		anim.frame = data[anim.seq][anim.seq_index]
	end
	
	-- frame was changed from outside
	if data[anim.seq][anim.seq_index] ~= anim.frame then
		anim.seq_index = table.find(data[anim.seq], anim.frame)
		
		anim.timer = 0
	end
	
	local speed = anim.speed or data.speed or 0
	
	-- advance frame
	if anim.timer > 1 / (speed / data.frames[anim.frame].speed) then
		anim.timer = 0
		
		anim.seq_index = anim.seq_index + 1
		if anim.seq_index > #data[anim.seq] then -- loop
			anim.seq = "seq"
			anim.seq_index = 1
		end
		anim.frame = data[anim.seq][anim.seq_index]
		
	end
	
	instances[id].animation = anim -- done
	
end

function instances.new(object, params) -- CREATE NEW INSTANCE --

	if not objects[object] then print("instances.new() | can't create instance, object \""..object.."\" doesn't exist!") return end

	objects[object].instances = objects[object].instances + 1

	local id = object.."_"..string.random(6)
	
	local instance = {}
	
	instance.object = object
	instance.active = true
	
	if objects[object].sprite then -- instance is of a sprite
		instance.animation = {
			name = "idle",
			current = "idle",
			frame = 1,
			timer = 0,
			seq = "seq_start",
			seq_index = 1,
		}
		if sprites[objects[object].sprite].tiled then -- tiled sprite
			instance.quad = love.graphics.newQuad(0,0,0,0,0,0)
		end
	end
	
	if params then
		for k,v in pairs(params) do
			instance[k] = v
		end
	end
	
	for k,v in pairs(objects[object]) do
		if type(v) == "function" then
			instance[k] = v
		end
	end
	
	instances[id] = instance -- done
	
	if instance.init then instances[id].init(id) end
	
	return id
	
end

function instances.delete(id) -- DELETE INSTANCE --
	local object = instances[id].object
	objects[object].instances = objects[object].instances - 1

	instances[id] = nil
end

function instances.clear(object) -- DELETE ALL INSTANCES OF AN OBJECT --
	for k,v in pairs(instances) do
		if type(v) ~= "function" then
			if instances[k].object == object then instances.delete(k) end
		end
	end
end

function instances.get(object, string) -- GET ALL INSTANCE IDs OF AN OBJECT --
	if not objects[object] then return nil end
	if objects[object].instances == 0 then return nil end
	
	local t = {}
	for k,v in pairs(instances) do
		if type(v) ~= "function" then
			if instances[k].object == object then table.insert(t,k) end
		end
	end
	
	if string then return table.concat(t,",") end
	return t
end

--------------------------------------------------------------- OBJECTS

function objects.new(name, image) -- CREATE NEW OBJECT --

	if objects[name] then print("objects.new() | object \""..name.."\" already exists!") return end

	local image = image or nil 
	
	local object = {}
	
	if love.filesystem.getInfo("objects/"..name..".lua") then 
		object = require("objects/"..name) -- add script to object if object.lua exists
	end
	
	object.instances = 0
	
	if image then
		if sprites[image] then -- object is a sprite
			object.sprite = image 
		end
	end

	objects[name] = object -- done
	
end

function objects.delete(name) -- DELETE OBJECT --
	instances.clear(name)
	objects[name] = nil
end

function objects.clear() -- DELETE ALL OBJECTS --
	for k,v in pairs(objects) do
		if type(v) ~= "function" then
			objects.delete(k)
		end
	end
end

--------------------------------------------------------------- SPRITES

function sprites.add_frames(count, x,y,speed) -- shortcut for adding frames to sprite data ~~
	local t = {}
	for i=1, count do
		t[i] = {}
		t[i].x = x or 0
		t[i].y = y or 0
		t[i].speed = speed or 1
	end
	return t
end

--------------------------------------------------------------- ASSETS

function assets.sprite(path, name) -- LOAD NEW SPRITE --
	
	if assets[name] then print("assets.sprite() | asset \""..name.."\" already loaded!") return end
	
	local file = love.filesystem.load(path..".sprite.lua")
	
	local sprite = file()
	assets[name] = {}
	
	for anim in pairs(sprite.animations) do -- first loop through all the unique animations
		if not sprite.animations[anim].anim then
			assets[name][anim] = {}
			for frame in pairs(sprite.animations[anim].frames) do
				local image = love.graphics.newImage(path.."/"..anim.."_"..(frame-1)..".png")
				
				if type(sprite.tiled) == "boolean" and sprite.tiled then image:setWrap("repeat", "repeat") end
				if type(sprite.tiled) == "string" then image:setWrap(sprite.tiled, sprite.tiled) end
				if type(sprite.tiled) == "table" then image:setWrap(sprite.tiled[1], sprite.tiled[2]) end
				
				assets[name][anim][frame] = image
			
				sprite.animations[anim].frames[frame].width = image:getWidth()
				sprite.animations[anim].frames[frame].height = image:getHeight()
			end
		end
	end
	for anim in pairs(sprite.animations) do -- only then loop through animations that are reused, to ensure it's fine
		if sprite.animations[anim].anim then
			for frame in pairs(sprite.animations[anim].frames) do
				local image = assets[name][sprite.animations[anim].anim][frame]
			
				sprite.animations[anim].frames[frame].width = image:getWidth()
				sprite.animations[anim].frames[frame].height = image:getHeight()
			end
		end
	end
	
	sprites[name] = sprite
	
end

function assets.unload(name) -- UNLOAD ASSET --
	assets[name] = nil
	if sprites[name] then sprites[name] = nil end
	collectgarbage()
end

function assets.clear() -- UNLOAD ALL ASSETS --
	for k,v in pairs(assets) do
		if type(v) ~= "function" and type(v) ~= "number" then
			assets.unload(k)
		end
	end
	collectgarbage()
end
