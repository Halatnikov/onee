scenes = {} -- functions
object = {}
instance = {}

scene = {} -- actual containers
objects = {}
instances = {}

---------------------------------------------------------------- SCENE

function scenes.set(name, data) -- SWITCH CURRENT SCENE --
	
	-- clear the scene
	for name in pairs(objects) do
		-- TODO: maybe a scene reset function?
		-- TODO: if same scene as before, then don't recreate persist instances
		if not objects[name].persist then object.delete(name) end
	end
	-- TODO: account persist objects somehow, a clear unused assets function?
	for name in pairs(assets) do asset.delete(name) end
	love.graphics.setBackgroundColor(8/255,8/255,8/255)
	collectgarbage()
	
	-- load new scene
	scene = require("scenes/"..name)
	
	scene.name = name
	
	if data then table.append(scene, data) end -- pass additional stuff to scene through this table
	
	if scene.init then scene.init() end
	
end

function scenes.update() -- SCENE UPDATE LOOP --

	assert(scene.name, "scenes.update() | No scene initialized!")
	
	if scene.update then scene.update() end -- scene

	for id in pairs(instances) do -- instances
		if instances[id].update and instances[id].active then instances[id].update(instances[id]) end
	end
	
end

function scenes.draw() -- SCENE DRAW LOOP --
	scenes.drawlist = {}
	
	if scene.draw then scene.draw() end -- scene
	
	for id in pairs(instances) do -- instances
		if instances[id].draw then instances[id].draw(instances[id]) end
	end
	
	queue.execute(scenes.drawlist)
end

---------------------------------------------------------------- OBJECTS

function object.new(path, data) -- CREATE NEW OBJECT --
	
	local name = string.tokenize(path, "/", -1)
	if objects[name] then print("object.new() | object \""..name.."\" already exists!") return end
	
	local object = {} -- init
	object.instances = 0
	
	if files.exists("objects/"..path..".lua") then 
		object.data = require("objects/"..path) -- add code to object, if it exists
	end
	
	if data then -- pass additional stuff to object through this table
		if not object.data then object.data = {} end
		table.append(object.data, data)
	end
	
	objects[name] = object -- done
	
	return name
	
end

function object.delete(name) -- DELETE OBJECT --
	instance.clear(name)
	objects[name] = nil
end

function object.instances(name) -- GET ALL INSTANCE IDs OF AN OBJECT --
	if not objects[name] then return nil end
	if objects[name].instances == 0 then return nil end
	
	local t = {}
	for id in pairs(instances) do
		if instances[id].object == name then table.insert(t,id) end
	end
	
	return t
end

---------------------------------------------------------------- INSTANCES

function instance.new(name, data) -- CREATE NEW INSTANCE --

	if not objects[name] then print("instance.new() | can't create instance, object \""..name.."\" doesn't exist!") return end
	
	local id = name.."_"..string.random(6)
	local object = objects[name]
	
	local instance = {} -- init
	instance.object = name
	instance.active = true
	
	if object.data then table.append(instance, object.data) end
	if data then table.append(instance, data) end -- pass additional stuff to instance through this table
	
	instances[id] = instance -- done
	
	object.instances = object.instances + 1
	
	if instance.init then instances[id].init(instances[id]) end
	
	return id
	
end

function instance.delete(id) -- DELETE INSTANCE --
	local name = instances[id].object
	objects[name].instances = objects[name].instances - 1

	instances[id] = nil
end

function instance.clear(name) -- CLEAR ALL INSTANCES OF OBJECT --
	for id in pairs(instances) do
		if instances[id].object == name then instance.delete(id) end
	end
end
