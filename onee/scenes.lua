scene = {} -- functions
object = {}
instance = {}

scenes = {} -- actual containers

---------------------------------------------------------------- SCENE

Scene = class({
	name = "",
	path = "",
	id = 1, 
	active = true,
	visible = true,
	
	init = noop,
	deinit = noop,
	update = noop,
	update_pre = noop,
	update_post = noop,
	draw = noop,
	draw_pre = noop,
	draw_post = noop,
	
	__init = function(self)
		self.objects = {}
		self.instances = {}
		--self.layers = {}
		--self.cameras = {}
		
		self.assets = {}
		self.sprites = {}
		self.models = {}
		
		self.drawlist = {}
	end,
	
	remove = function(self)
		self:deinit()
		self = nil
	end,
})

--! SWITCH CURRENT SCENE
function scene.set(path, data, name)
	for k,scene in ipairs(scenes) do scene:remove() end
	collectgarbage()
	log("recreated scene stack")
	
	scene.add(path, 1, data, name)
end

--! INSERT SCENE TO STACK
function scene.add(path, i, data, name)
	i = i or #scenes+1
	name = name or string.tokenize(path, "/", -1)
	
	local t = files.exists("scenes/"..path..".lua") and dofile("scenes/"..path) or Scene()
	table.append(t, data) -- additional data
	t.name, t.path, t.id = name, path, i
	
	scenes[i] = t -- done
	
	log("added scene '"..path.."'")
	t:init()
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
			scene:update() -- scene
			
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
		
		if scene.visible then
			_prof.mark("scene")
			scene:draw() -- scene
			
			for id, instance in pairs(scene.instances) do
				_prof.push(id)
				if instance.visible then instance.draw(instance, scene) end -- instances
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
		path = path,
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
	
	local id = name.."_"..string.random(8)
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
		deinit = noop,
		update = noop,
		update_pre = noop,
		update_post = noop,
		draw = noop,
		draw_pre = noop,
		draw_post = noop,
	}
	
	if object.data then table.append(t, object.data) end
	
	if data then table.append(t, data) end -- additional data
	
	t.destroy = function() instance.delete(t.id, scene) end
	
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
	
	instance.deinit(instance)
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
