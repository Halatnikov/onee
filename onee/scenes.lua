scene = {} -- functions
object = {}
instance = {}

scenes = {} -- actual containers
instances = {}

---------------------------------------------------------------- SCENE

function scene.set(name, data) -- SWITCH CURRENT SCENE --
	
	-- clear the scene
	--for name in pairs(objects) do
		-- TODO: maybe a scene reset function?
		-- TODO: if same scene as before, then don't recreate persist instances
		--if not objects[name].persist then object.delete(name) end
	--end
	-- TODO: account persist objects somehow, a clear unused assets function?
	for name in pairs(assets) do asset.delete(name) end
	-- TODO: general graphics reset stuff here?
	--rgb = {8/255, 8/255, 8/255}
	collectgarbage()
	
	-- load new scene
	-- TODO: do it like objects, don't make the lua file mandatory, also do a path
	local t = require("scenes/"..name)
	
	t.scene = true
	t.name = name
	t.id = 1
	t.active = true
	t.visible = true
	
	t.objects = {}
	t.instances = {}
	
	t.drawlist = {}
	
	if data then table.append(t, data) end -- pass additional stuff to scene through this table
	
	t = table.protect(t, {"scene", "name", "id"})
	
	scenes[1] = t
	
	if t.init then t.init(t) end
	
	unrequire("scenes/"..name)
	
end

function scene.update() -- SCENES UPDATE LOOP --
	assert(table.length(scenes) > 0, "scene.update() | No scene initialized!")
	
	for id in kpairs(scenes) do
		local scene = scenes[id]
		if scene.active then
			if scene.update then scene.update(scene) end -- scene
			
			for id in pairs(scene.instances) do
				local instance = scene.instances[id]
				if instance.active and instance.update then
					instance.update(instance, scene) -- instances
				end
			end
		end
	end
end

function scene.draw() -- SCENES DRAW LOOP --
	for id in kpairs(scenes) do
		local scene = scenes[id]
		scene.drawlist = {} -- new frame
		if scene.visible then
			if scene.draw then scene.draw(scene) end -- scene
			
			for id in pairs(scene.instances) do
				local instance = scene.instances[id]
				if instance.visible and instance.draw then
					instance.draw(instance, scene) -- instances
				end
			end
			
			queue.execute(scene.drawlist)
		end
	end
end

---------------------------------------------------------------- OBJECTS

function object.new(path, scene, data, name) -- CREATE NEW OBJECT --
	
	if not name then name = string.tokenize(path, "/", -1) end
	if scene.objects[name] then return end
	
	local t = { -- init
		object = true,
		scene = scene.name,
		instances = 0,
	}
	
	if files.exists("objects/"..path..".lua") then 
		t.data = require("objects/"..path) -- add code to object, if it exists
	end
	
	if data then -- pass additional stuff to object through this table
		if not t.data then t.data = {} end
		table.append(t.data, data)
	end
	
	t = table.protect(t, {"object", "scene"})
	
	scene.objects[name] = t -- done
	unrequire("objects/"..path)
	
	return name
	
end

function object.delete(name, scene) -- DELETE OBJECT --
	if not scene.objects[name] then return end
	instance.clear(name)
	scene.objects[name] = nil
end

function object.instances(name, scene) -- GET ALL INSTANCE IDs OF AN OBJECT --
	if not scene.objects[name] then return nil end
	if scene.objects[name].instances == 0 then return nil end
	
	local t = {}
	for id in pairs(scene.instances) do
		if scene.instances[id].object == name then table.insert(t,id) end
	end
	
	return t
end

---------------------------------------------------------------- INSTANCES

function instance.new(name, scene, data) -- CREATE NEW INSTANCE --

	assert(scene.objects[name], "instance.new() | can't create instance, object \""..name.."\" doesn't exist!")
	
	local id = name.."_"..string.random(6)
	local object = scene.objects[name]
	
	local t = { -- init
		instance = true,
		scene = scene.name,
		object = name,
		id = id,
		id_i = table.length(scene.instances) + 1,
		
		active = true,
		visible = true,
	}
	
	if object.data then table.append(t, object.data) end
	if data then table.append(t, data) end -- pass additional stuff to instance through this table
	
	function t.delete()
		instance.delete(t.id, scene)
	end
	
	t = table.protect(t, {"instance", "object", "scene", "id", "id_i"})
	
	scene.instances[id] = t -- done
	
	object.instances = object.instances + 1
	
	if t.init then t.init(t, scene) end
	
	return id
	
end

function instance.delete(id, scene) -- DELETE INSTANCE --
	if not instances[id] then return end
	local name = instances[id].object
	scene.objects[name].instances = scene.objects[name].instances - 1

	instances[id] = nil
end

function instance.clear(name) -- CLEAR ALL INSTANCES OF OBJECT --
	for id in pairs(instances) do
		if instances[id].object == name then instance.delete(id) end
	end
end
