scene = {} -- functions
object = {}
instance = {}

scenes = {} -- actual containers

---------------------------------------------------------------- SCENE

--! SWITCH CURRENT SCENE
function scene.set(path, data, name)
	
	name = name or string.tokenize(path, "/", -1)
	
	if scenes[1] then scenes[1].delete(scenes[1]) end
	scenes[1] = {}
	collectgarbage()
	
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
		
		atlases = {},
		batches = {},
		drawlist = {},
		
		init = noop,
		delete = noop,
		update = noop,
		draw = noop,
	}
	
	if files.exists("scenes/"..path..".lua") then table.append(t, dofile("scenes/"..path)) end
	
	if data then table.append(t, data) end -- additional data
	
	t = table.protect(t, {"scene", "id"})
	
	scenes[1] = t --done
	
	t.init(t)
	
end

-- SCENES UPDATE LOOP
function scene.update(source)
	source = source or scenes
	assert(table.length(source) > 0, "scene.update() | No scene initialized!")
	_prof.push("scene.update")
	
	for id, scene in ipairs(source) do
		_prof.push(scene.name)
		if scene.active then
			_prof.mark("scene")
			scene.update(scene) -- scene
			
			for id, instance in pairs(scene.instances) do
				_prof.push(id)
				if instance.active then instance.update(instance, scene) end -- instances
				_prof.pop()
			end
		end
		_prof.pop()
	end
	_prof.pop()
end

-- SCENES DRAW LOOP
function scene.draw(source)
	source = source or scenes
	_prof.push("scene.draw")
	for id, scene in ipairs(source) do
		_prof.push(scene.name)
		scene.drawlist = {} -- new frame
		for i, batch in ipairs(scene.batches) do
			batch:clear()
		end
		
		if scene.visible then
			_prof.mark("scene")
			scene.draw(scene) -- scene
			
			for id, instance in pairs(scene.instances) do
				_prof.push(id)
				if instance.visible then instance.draw(instance, scene) end -- instances
				_prof.pop()
			end
			
			_prof.mark("final scene draw")
			queue.execute(scene.drawlist)
			for i, batch in ipairs(scene.batches) do
				love.graphics.draw(batch)
			end
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
	
	if data then -- additional data
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
	if not scene.objects[name] then return end
	if scene.objects[name].instances == 0 then return end
	
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
		
		init = noop,
		delete = noop,
		update = noop,
		draw = noop,
	}
	
	if object.data then table.append(t, object.data) end
	
	if data then table.append(t, data) end -- additional data
	
	function t.destroy()
		instance.delete(t.id, scene)
	end
	
	t = table.protect(t, {"instance", "object", "scene", "id", "id_i"})
	
	scene.instances[id] = t -- done
	
	object.instances = object.instances + 1
	
	t.init(t, scene)
	
	return t
	
end

--! DELETE INSTANCE
function instance.delete(id, scene)
	local instance = scene.instances[id]
	if not instance then return end
	
	local name = instance.object
	scene.objects[name].instances = scene.objects[name].instances - 1
	
	instance.delete(instance)
	scene.instances[id] = nil
end

--! CLEAR ALL INSTANCES OF OBJECT
function instance.clear(name, scene)
	local instance_ = instance
	for id, instance in pairs(scene.instances) do
		if instance.object == name then instance_.delete(id, scene) end
	end
end

_prof.hook("object")
_prof.hook("instance")
