
level = {
	tiled = {map = {}, tilesets = {}, templates = {},}
}

skin = "scruffy"

function level.load(name)
	
	level.tiled.map = json.decode(love.filesystem.read("levels/"..name..".tmj")) -- read the map
	
	local map = level.tiled.map
	
	for k in pairs(map.tilesets) do -- read the map's tilesets
		if map.tilesets[k].source then
			local name1 = map.tilesets[k].source
			local name = string.replace(string.tokenize(name1,"/",#string.tokenize(name1,"/")),".tsj","")
			level.tiled.tilesets[name] = json.decode(love.filesystem.read("tiles/"..name..".tsj"))
		end
	end
	
	for k in pairs(map.layers) do -- read the map's templates
		if map.layers[k].type == "objectgroup" then
			for obj in pairs(map.layers[k].objects) do
				if map.layers[k].objects[obj].template then
					local name1 = map.layers[k].objects[obj].template
					local name = string.replace(string.tokenize(name1,"/",#string.tokenize(name1,"/")),".tj","")
					if not level.tiled.templates[name] then
						level.tiled.templates[name] = json.decode(love.filesystem.read("objects/"..name..".tj"))
					end
				end
			end
		end
	end
	
	local templates = level.tiled.templates
	
	for k in pairs(templates) do -- read the templates' tilesets (i don't even know if that's needed)
		if templates[k].tileset then
			local name1 = templates[k].tileset.source
			local name = string.replace(string.tokenize(name1,"/",#string.tokenize(name1,"/")),".tsj","")
			if not level.tiled.tilesets[name] then
				level.tiled.tilesets[name] = json.decode(love.filesystem.read("tiles/"..name..".tsj"))
			end
		end
	end
	
	local tilesets = level.tiled.tilesets
	
end
