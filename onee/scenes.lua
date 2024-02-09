scene = {} -- functions
object = {}
instance = {}

scenes = {} -- actual containers

---------------------------------------------------------------- SCENE

--! SWITCH CURRENT SCENE
function scene.set(path, data, name)
	
	name = name or string.tokenize(path, "/", -1)
	
	local t = { -- init
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
	
	if files.exists("scenes/"..path..".lua") then table.append(t, dofile("scenes/"..path)) end
	if data then table.append(t, data) end
	
	t = table.protect(t, {"scene", "name", "id"})
	
	scenes[1] = t --done
	
	if t.init then t.init(t) end
	
end

--! SCENES UPDATE LOOP
function scene.update()
	assert(table.length(scenes) > 0, "scene.update() | No scene initialized!")
	_prof.push("scene.update")
	
	for id, scene in kpairs(scenes) do
		_prof.push(scene.name)
		if scene.active then
			_prof.mark("scene")
			if scene.update then scene.update(scene) end -- scene
			
			for id, instance in pairs(scene.instances) do
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

--! SCENES DRAW LOOP
function scene.draw()
	_prof.push("scene.draw")
	for id, scene in kpairs(scenes) do
		_prof.push(scene.name)
		scene.drawlist = {} -- new frame
		if scene.visible then
			_prof.mark("scene")
			if scene.draw then scene.draw(scene) end -- scene
			
			for id, instance in pairs(scene.instances) do
				_prof.push(id)
				if instance.visible and instance.draw then
					instance.draw(instance, scene) -- instances
				end
				_prof.pop()
			end
			
			_prof.mark("final scene draw")
			queue.execute(scene.drawlist)
		end
		_prof.pop()
	end
	_prof.pop()
end

---------------------------------------------------------------- OBJECTS

--! CREATE NEW OBJECT
function object.new(path, scene, data, name)
	
	name = name or string.tokenize(path, "/", -1)
	if scene.objects[name] then return end
	
	local t = { -- init
		object = true,
		name = name,
		scene = scene.name,
		instances = 0,
	}
	
	if files.exists("objects/"..path..".lua") then 
		t.data = dofile("objects/"..path) -- add code to object, if it exists
	end
	
	if data then -- pass additional stuff to object through this table
		t.data = t.data or {}
		table.append(t.data, data)
	end
	
	t = table.protect(t, {"object", "name", "scene"})
	
	scene.objects[name] = t -- done
	
	return t
	
end

--! DELETE OBJECT
function object.delete(name, scene)
	if not scene.objects[name] then return end
	instance.clear(name, scene)
	scene.objects[name] = nil
end

--! GET ALL INSTANCE IDs OF AN OBJECT
function object.instances(name, scene)
	if not scene.objects[name] then return nil end
	if scene.objects[name].instances == 0 then return nil end
	
	local t = {}
	for id, instance in pairs(scene.instances) do
		if instance.object == name then table.insert(t, id) end
	end
	
	return t
end

---------------------------------------------------------------- INSTANCES

--! CREATE NEW INSTANCE
function instance.new(name, scene, data) -- string, table, table=

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
	
	return t
	
end

--! DELETE INSTANCE
function instance.delete(id, scene)
	if not scene.instances[id] then return end
	local name = scene.instances[id].object
	scene.objects[name].instances = scene.objects[name].instances - 1

	scene.instances[id] = nil
end

--! CLEAR ALL INSTANCES OF OBJECT
function instance.clear(name, scene)
	for id, instance in pairs(scene.instances) do
		if instance.object == name then instance.delete() end
	end
end

_prof.hook("object")
_prof.hook("instance")
