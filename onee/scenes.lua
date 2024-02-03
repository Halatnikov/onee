scene = {} -- functions
object = {}
instance = {}

scenes = {} -- actual containers

---------------------------------------------------------------- SCENE

function scene.set(path, data, name) -- SWITCH CURRENT SCENE --
	
	if not name then name = string.tokenize(path, "/", -1) end
	
	local t = {
		scene = true,
		name = name,
		id = 1,
		active = true,
		visible = true,
		
		objects = {},
		instances = {},
		
		assets = {},
		sprites = {},
		models = {},
		
		drawlist = {},
	}
	
	if files.exists("scenes/"..path..".lua") then table.append(t, require("scenes/"..path)) end
	if data then table.append(t, data) end
	
	t = table.protect(t, {"scene", "name", "id"})
	
	scenes[1] = t --done
	
	if t.init then t.init(t) end
	
	unrequire("scenes/"..path)
	
end

function scene.update() -- SCENES UPDATE LOOP --
	assert(table.length(scenes) > 0, "scene.update() | No scene initialized!")
	_prof.push("scene.update")
	
	for id in kpairs(scenes) do
		local scene = scenes[id]
		_prof.push(scene.name)
		if scene.active then
			_prof.push("scene")
			if scene.update then scene.update(scene) end -- scene
			_prof.pop()
			
			for id in pairs(scene.instances) do
				local instance = scene.instances[id]
				_prof.push(id)
				if instance.active and instance.update then
					instance.update(instance, scene) -- instances
				end
				_prof.pop()
			end
		end
		_prof.pop()
	end
	_prof.pop()
end

function scene.draw() -- SCENES DRAW LOOP --
	_prof.push("scene.draw")
	for id in kpairs(scenes) do
		local scene = scenes[id]
		_prof.push(scene.name)
		scene.drawlist = {} -- new frame
		if scene.visible then
			_prof.push("scene")
			if scene.draw then scene.draw(scene) end -- scene
			_prof.pop()
			
			for id in pairs(scene.instances) do
				local instance = scene.instances[id]
				_prof.push(id)
				if instance.visible and instance.draw then
					instance.draw(instance, scene) -- instances
				end
				_prof.pop()
			end
			
			_prof.push("final scene draw")
			queue.execute(scene.drawlist)
			_prof.pop()
		end
		_prof.pop()
	end
	_prof.pop()
end

---------------------------------------------------------------- OBJECTS

function object.new(path, scene, data, name) -- CREATE NEW OBJECT --
	
	if not name then name = string.tokenize(path, "/", -1) end
	if scene.objects[name] then return end
	
	local t = { -- init
		object = true,
		name = name,
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
	
	t = table.protect(t, {"object", "name", "scene"})
	
	scene.objects[name] = t -- done
	unrequire("objects/"..path)
	
	return name
	
end

function object.delete(name, scene) -- DELETE OBJECT --
	if not scene.objects[name] then return end
	instance.clear(name, scene)
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
	if not scene.instances[id] then return end
	local name = scene.instances[id].object
	scene.objects[name].instances = scene.objects[name].instances - 1

	scene.instances[id] = nil
end

function instance.clear(name, scene) -- CLEAR ALL INSTANCES OF OBJECT --
	for id in pairs(scene.instances) do
		if scene.instances[id].object == name then instance.delete(id, scene) end
	end
end
