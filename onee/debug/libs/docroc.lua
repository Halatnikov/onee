-- docroc v0.1.0 - Lua documentation generator
-- https://github.com/bjornbytes/docroc
-- License - MIT, see LICENSE for details.

docroc = {}
docs = {}

function docroc.all()
	local list = files.listdir("")
	local t = {}
	for i=1, #list do
		if string.right(list[i],4) == ".lua" and not string.find(list[i], "onee/libs") then table.insert(t, list[i]) end
	end
	for i=1, #t do
		docs[t[i]] = docroc.process(t[i])
	end
end

function docroc.process(filename)
	local source = love.filesystem.read(filename)
	
	local comments = {}
	source:gsub("%s*%-%-!(.-)\n([%s%w\n][^\n]*)", function(chunk, context)
		chunk = chunk:gsub("^%s*%-*%s*", ""):gsub("\n%s*%-*%s*", " ")
		chunk = chunk:gsub("^[^@]", "@raw %1")
		context = context:match("[^\n]+")

		local tags = {}
		chunk:gsub("@(%w+)%s?([^@]*)", function(name, body)
			body = body:gsub("(%s+)$", "")
			local processor = docroc.processors[name]
			if not processor then log("docroc.process() | unknown tag - "..name..newline..context) end
			local tag = processor and processor(body) or {}
			body = body:gsub("%-%-%s*(.*)$", "")
			tag.tag = name
			tag._raw = body
			tags[name] = tags[name] or {}
			table.insert(tags[name], tag)
		end)
		
		-- auto document a function 
		context:gsub("function ([%w%p][^(]*)(%b())", function(name, params)
			local tparams = {}
			params:sub(2,-2):gsub("([%w%p][^%,]*)%,?", function(param)
				table.insert(tparams, param)
			end)
			
			-- auto fill types and defaults if there's a comment
			local ttypes = {}
			context:gsub("%s*%-%-%s*(.*)", function(types)
				types:gsub("([%w%p][^%,]*)%,?", function(comment)
					local type, optional, default
					type = comment:gsub("(%=)(.*)", function(_, value)
						optional = true
						value = string.trim(value)
						default = #value ~= 0 and value or nil
						return ""
					end)
					type = #type ~= 0 and type or nil
					
					local param = {
						type = type,
						optional = optional,
						default = default,
					}
					table.insert(ttypes, param)
				end)
			end)
			
			-- name and description
			if not tags["function"] then
				if context:find("local ") then tags["local"] = {[1] = {tag = "local"}} end
				
				tags["function"] = {}
				local tag = {tag = "function", name = name,}
				if tags["raw"] then
					tag.description =  tags["raw"][1]._raw
					tags["raw"] = nil
				end
				table.insert(tags["function"], tag)
			end
			
			-- params
			tags["param"] = tags["param"] or {}
			for i=1, #tparams do
				local exists = table.find(tags["param"], "name", tparams[i])
				local param
				if not exists then
					local tag = {tag = "param", name = tparams[i], _order = i}
					table.insert(tags["param"], tag)
					param = tag
				else
					param = tags["param"][exists]
					param._order = i
				end
				if ttypes[i] then
					param.type = param.type or ttypes[i].type
					param.optional = param.optional or ttypes[i].optional
					param.default = param.default or ttypes[i].default
				end
			end
			tags["param"] = table.sortby(tags["param"], "_order")
		end)
		
		-- comment "block" done
		table.insert(comments, {
			tags = tags,
			context = context,
		})
	end)
	
	comments = #comments ~= 0 and comments or nil
	return comments
end

docroc.processors = {}
local processor = docroc.processors

processor["raw"] = function(body)
	return {}
end

processor["local"] = processor.raw

processor["function"] = function(body)
	local name = body:match("^%s*([%w%p]+)")
	local description = body:match("%-%-%s*(.*)$")
	
	return {
		name = name,
		description = description,
	}
end

processor["param"] = function(body)
	local name = body:match("^%s*(%w+)") or body:match("^%s*%b()%s*(%w+)")
	local description = body:match("%-%-%s*(.*)$")
	local type, optional, default
	body:gsub("^%s*(%b())", function(match)
		type = match:sub(2, -2):gsub("(%=)(.*)", function(_, value)
			optional = true
			value = string.trim(value)
			default = #value ~= 0 and value or nil
			return ""
		end)
		type = #type ~= 0 and type or nil
		return ""
	end)
	
	return {
		name = name,
		description = description,
		type = type,
		optional = optional,
		default = default,
	}
end

processor["returns"] = function(body)
	local name = body:match("^%s*(%w+)") or body:match("^%s*%b()%s*(%w+)")
	local description = body:match("%-%-%s*(.*)$")
	local type
	body:gsub("^%s*(%b())", function(match)
		type = match:sub(2, -2)
		return ""
	end)
	
	return {
		name = name,
		description = description,
		type = type,
	}
end

return docroc
