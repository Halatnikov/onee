-- docroc v0.1.0 - Lua documentation generator
-- https://github.com/bjornbytes/docroc
-- License - MIT, see LICENSE for details.

docroc = {}

function docroc.process(filename)
	local source = love.filesystem.read(filename)
	
	local comments = {}
	source:gsub('%s*%-%-!(.-)\n([%s%w\n][^\n%-]*)', function(chunk, context)
		chunk = chunk:gsub('^%s*%-*%s*', ''):gsub('\n%s*%-*%s*', ' ')
		chunk = chunk:gsub('^[^@]', '@raw %1')
		context = context:match('[^\n]+')

		local tags = {}
		chunk:gsub('@(%w+)%s?([^@]*)', function(name, body)
			body = body:gsub('(%s+)$', '')
			local processor = docroc.processors[name]
			local tag = processor and processor(body) or {}
			body = body:gsub('%-%-%s*(.*)$', '')
			tag.tag = name
			tag._raw = body
			tags[name] = tags[name] or {}
			table.insert(tags[name], tag)
		end)
		
		-- auto document a function 
		context:gsub("function ([%w%p][^(]*)(%b())", function(name, params)
			local t = {}
			params:sub(2,-2):gsub("([%w%p][^%,]*)%,?", function(param)
				table.insert(t, param)
			end)
			
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
			
			tags["param"] = tags["param"] or {}
			for i=1, #t do
				local exists = table.find(tags["param"], "name", t[i])
				if not exists then
					local tag = {tag = "param", name = t[i], _order = i}
					table.insert(tags["param"], tag)
				else
					tags["param"][exists]._order = i
				end
			end
			table.sortby(tags["param"], "_order")
		end)
		
		-- comment "block" done
		table.insert(comments, {
			tags = tags,
			context = context,
		})
	end)

	return comments
end

docroc.processors = {}
local processor = docroc.processors

processor["function"] = function(body)
	local name = body:match("^%s*([%w%p]+)")
	local description = body:match('%-%-%s*(.*)$')
	
	return {
		name = name,
		description = description,
	}
end

processor["param"] = function(body)
	local name = body:match('^%s*(%w+)') or body:match('^%s*%b()%s*(%w+)')
	local description = body:match('%-%-%s*(.*)$')
	local type, optional, default
	body:gsub('^%s*(%b())', function(match)
		type = match:sub(2, -2):gsub('(%=)(.*)', function(_, value)
			optional = true
			default = #value ~= 0 and value or nil
			return ''
		end)
		return ''
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
	local name = body:match('^%s*(%w+)') or body:match('^%s*%b()%s*(%w+)')
	local description = body:match('%-%-%s*(.*)$')
	local type
	body:gsub('^%s*(%b())', function(match)
		type = match:sub(2, -2)
		return ''
	end)
	
	return {
		name = name,
		description = description,
		type = type,
	}
end

return docroc
