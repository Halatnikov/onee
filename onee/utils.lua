---------------------------------------------------------------- MATH
-- TODO: lerp (and pingpong), smoothstep, decay, closest to ^2, construct 2, vector 2?
-- angle from x1 y1 to x2 y2

pi = math.pi
inf = math.huge
math.random = love.math.random
math.int = math.floor

function math.bool(arg)
	return arg == true and 1 or 0
end

function math.is_int(arg)
	return math.floor(arg) == arg and true or false
end

function math.is_float(arg)
	return not math.is_int(arg)
end

function math.sign(arg)
	return (arg > 0) and 1 or (arg < 0) and -1 or 0
end

function math.flipsign(arg)
	return (arg > 0) and -arg or math.abs(arg)
end

function math.between(min, arg, max)
	return arg >= min and arg <= max
end

function math.clamp(min, arg, max)
    return math.max(min, math.min(max, arg))
end

function math.wrap(min, arg, max)
    return arg > max and min or arg < min and max or arg
end

function math.gridsnap(arg, step)
	return math.floor(arg / step) * step
end

function math.round(arg, decimals)
	decimals = 10 ^ (decimals or 0)
    return math.floor(arg * decimals + 0.5) / decimals
end

function math.choose(...)
	local arg = type(...) == "table" and ... or {...}
	return arg[math.random(#arg)]
end

function math.average(...)
	local arg = type(...) == "table" and ... or {...}
	local sum = 0
	for i=1, #arg do
		sum = sum + arg[i]
	end
	return sum / #arg
end

function math.distance(x1, y1, x2, y2)
	if not y2 then x2, y2 = y1, y1; y1 = x1 end -- allow one axis
	return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end

function math.map(arg, a_min, a_max, b_min, b_max)
	return (arg - a_min) * (b_max - b_min) / (a_max - a_min) + b_min
end

function math.loop(a, b, t)
	-- t in seconds from a to b
	if b < a then a, b, t = b, a, -t end
	t = love.timer.getTime() / (t / b)
	local len = b - a
	return math.map((t - math.floor(t / len) * len), 0, len, a, b)
end

function math.loop_pingpong(a, b, t)
	-- t in seconds from a to b to a
	local len = b - a
	if b < a then a, b = b, a
		len = b - a
		t = t + (0.707 * len) -- offset starting point by sqrt(2)/2 if going from b to a
	end
	t = love.timer.getTime() / (t / b)
	t = math.clamp(a, t - math.floor(t / (len*2)) * (len*2), b*2)
	return len - math.abs(t - len)
end

---------------------------------------------------------------- STRINGS

string.replace = string.gsub
string.mid = string.sub
string.lowercase = string.lower
string.uppercase = string.upper
newline = "\n"

function string.trim(arg)
   return string.replace(arg, "^%s*(.-)%s*$", "%1")
end

function string.escape(arg)
	return string.replace(arg, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
end

function string.left(arg, len) -- alias
	if len < 0 then len = #arg - math.abs(len) end -- count from end
	return string.mid(arg, 1, len)
end

function string.right(arg, len) --alias
	if len < 0 then len = #arg - math.abs(len) end -- count from end
	return string.mid(arg, #arg - (len - 1), #arg)
end

string.find_ = string.find
function string.find(arg, find, index, plain) -- alias
	if plain == nil then plain = true end
	return string.find_(arg, find, index, plain)
end

function string.remove(arg, ...)
	local find = type(...) == "table" and ... or {...}
	for i=1, #find do
		arg = string.replace(arg, string.escape(find[i]), "")
	end
	return arg
end

function string.split(arg)
	local t = {}
	for i=1, #arg do
		table.insert(t, string.mid(arg, i, i))
	end
	return t
end

function string.random(length)
	local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
	local t = {}
	for i=1, length do
		local r = math.random(1, #chars)
		table.insert(t, string.mid(chars, r, r))
	end
	return table.concat(t)
end

-- TODO: use sha-384 for other stuff preferably
function string.md5(arg) -- alias
	return love.data.hash("md5", tostring(arg))
end

function string.tokenize(arg, separator, index)
	if index == -1 then index = #string.tokenize(arg, separator) end -- get last index
	
	local escaped = string.escape(separator)
	
	local t = {}
	for k in string.gmatch(arg..separator, "([^"..escaped.."]*)"..separator) do
		table.insert(t, k)
		
		if index and table.find(t, k) == index then
			return t[index]
		end
	end
	if not index then return t end
end

---------------------------------------------------------------- TABLES

function copy(arg)
    local ref = {}
    local function recursive(arg)
        if type(arg) ~= "table" then
            return arg
        elseif ref[arg] then
            return ref[arg]
        end
		
        local new = {}
        ref[arg] = new
        for k,v in pairs(arg) do
            new[recursive(k)] = recursive(v)
        end
		
        return setmetatable(new, recursive(getmetatable(arg)))
    end
    return recursive(arg)
end

function table.compare(a, b)
	a, b = a or {}, b or {}
    if a == b then return true end
	local function recursive(a, b)
		if a == b then return true end
		if type(a) ~= type(b) then return false end
		if type(a) ~= "table" then return false end
		local keys = {}

		for k1, v1 in pairs(a) do
			local v2 = b[k1]
			if v2 == nil or recursive(v1, v2) == false then
				return false
			end
			keys[k1] = true
		end

		for k2 in pairs(b) do
			if not keys[k2] then return false end
		end
		
		return true
	end
	return recursive(a, b)
end

function table.length(arg)
	local i = 0
	for k,v in pairs(arg) do i = i + 1 end
	return i
end

function table.append(a, b)
	a, b = a or {}, b or {}
	if getmetatable(b) then setmetatable(a, getmetatable(b)) end
	
	for k,v in pairs(b) do 
		if type(v) == "table" and type(a[k] or false) == "table" then
			table.append(a[k], b[k])
		else
			a[k] = v
		end
	end
	return a
end

function table.find(arg, result, result2)
	if not result2 then
		-- table has a key equaling "result"
		for k,v in pairs(arg) do
			if v == result then return k end
		end
	else
		-- nested table which has a key "result" that equals "result2"
		for k,v in pairs(arg) do
			if type(v) == "table" and v[result] and v[result] == result2 then return k end
		end
	end
end

function table.fill(v, min, max)
	if not max then min, max = 1, min end
	local t = {}
	for i = min, max do table.insert(t, type(v) == "function" and v() or v) end
	return t
end

function table.clear(arg)
	local k = next(arg)
	while k ~= nil do
		arg[k] = nil
		k = next(arg)
	end
end

function table.reverse(arg)
	arg = copy(arg)
    for i=1, math.floor(#arg/2) do
        arg[i], arg[#arg - i+1] = arg[#arg - i+1], arg[i]
    end
    return arg
end

function table.sortby(arg, k, descending)
	arg = copy(arg)
	table.sort(arg, function(a,b)
		if not (a[k] and b[k]) then return end
		if type(a) ~= type(b) then return tostring(a[k]) < tostring(b[k]) end
		return a[k] < b[k]
	end)
	return descending and table.reverse(arg) or arg
end

function table.sortv(arg, descending)
	arg = copy(arg)
	table.sort(arg, function(a,b)
		if type(a) ~= type(b) then return tostring(a) < tostring(b) end
		return a < b
	end)
	return descending and table.reverse(arg) or arg
end

function table.mostcommon(arg)
	local count = {}
	for k, v in pairs(arg) do
		count[v] = (count[v] or 0) + 1
	end
	
	local current = next(count)
	local best = count[current]
	for k, v in pairs(count) do
		if count[k] > best then
			current, best = k, v
		end
	end
	
	return current, count
end

function table.unflatten(arg)
	arg = copy(arg)
	local keys, node, tree = {}, {}, {}
	
	for i=1, #arg do keys[arg[i].id] = i end
	for i=1, #arg do
		node = arg[i]
		if node.parent and keys[node.parent] then
			local parent = keys[node.parent]
			table.insert(arg[parent], node)
		else
			table.insert(tree, node)
		end
	end
  
	return tree
end

---------------------------------------------------------------- ITERATORS

function kpairs(arg, v)
	local keys = {}
	for k in pairs(arg) do table.insert(keys, k) end
	if not v then -- sort keys
		table.sort(keys, function(a, b)
			if type(a) ~= type(b) then return tostring(a) < tostring(b) end
			return a < b
		end)
	else -- sort values
		table.sort(keys, function(a,b)
			if not (arg[a] and arg[b]) then return end
			if type(arg[a]) ~= type(arg[b]) then return tostring(arg[a]) < tostring(arg[b]) end
			return arg[a] < arg[b]
		end)
	end
	local i = 0
	return function()
		i = i + 1
		-- nil is important
		return keys[i] == nil and nil or keys[i], arg[keys[i]]
	end
end
function vpairs(arg) return kpairs(arg, true) end -- alias

function ripairs(arg)
	return function(arg, i)
		i = i - 1
		if not (i == 0) then
			return i, arg[i]
		end
	end, arg, #arg + 1
end

---------------------------------------------------------------- QUEUEING

queue = {}

function queue.add(arg, i, add)
	if not arg.queue then
		table.append(arg, {queue = {}, first = 1, last = 1})
	end
	i = i or arg.last + 1
	if i < arg.first then arg.first = i end
	if i > arg.last then arg.last = i end
	
	if not arg.queue[i] then arg.queue[i] = {} end
	arg.queue[i][#arg.queue[i] + 1] = add
end

function queue.execute(arg)
	if not arg.queue then return end
	for i = arg.first, arg.last do
		if arg.queue[i] then
			for j = 1, #arg.queue[i] do arg.queue[i][j]() end
		end
	end
	arg.queue, arg.first, arg.last = nil, nil, nil
end

---------------------------------------------------------------- COLORS
--TODO: color constants like red, white, black

color = {}

function color.rgb(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], g or r[4] -- allow "{rgb},a"
	end
	
	if not (math.between(0, r, 1) and math.between(0, g, 1) and math.between(0, b, 1)) then
		r = r/255
		g = g/255
		b = b/255
	end
	a = a and (math.between(0, a, 1) and a or a/100)
	return r, g, b, a
end

function color.hsl(h, s, l, a)
	if not (s > 0) then return l, l, l, a end
	
	local function convert(p, q, t)
		if t < 0 then t = t + 1 end
		if t > 1 then t = t - 1 end
		if t < 1/6 then return p + (q - p) * 6 * t end
		if t < 1/2 then return q end
		if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
		return p
	end
	
	local q = (l < 0.5) and l * (1 + s) or l + s - l * s
	local p = l * 2 - q

	local r = convert(p, q, h + 1/3)
	local g = convert(p, q, h)
	local b = convert(p, q, h - 1/3)

    return r, g, b, a
end

function color.hex(hex)
	hex = string.right(hex, 6)
	local r = tonumber(string.mid(hex, 1,2), 16)/255
	local g = tonumber(string.mid(hex, 3,4), 16)/255
	local b = tonumber(string.mid(hex, 5,6), 16)/255
	return r, g, b
end

rgb = color.rgb
hsl = color.hsl
hex = color.hex

function color.torgb(r, g, b, a)
	return math.round(r*255), math.round(g*255), math.round(b*255), a and math.round(a*100)
end

function color.random()
	return math.random(0,255), math.random(0,255), math.random(0,255)
end

---------------------------------------------------------------- DRAWING

function love.graphics.stack(func, stack)
	stack = stack or "transform"
	love.graphics.push(stack)
	func()
	love.graphics.pop()
end

function gradient(type, colors, x, y, r, w, h, ox, oy, kx, ky)
	type = type or "horizontal"
	r = math.rad(r or 0)
	local types = {}
	
	types["horizontal"] = function()
		local vertices = {}
		for i, color in ipairs(colors) do
			local x = (i - 1) / (#colors - 1)
			table.insert(vertices, {x, 1, x, 1, color[1], color[2], color[3], color[4] or 1})
			table.insert(vertices, {x, 0, x, 0, color[1], color[2], color[3], color[4] or 1})
		end
		return vertices
	end
	
	types["vertical"] = function()
		local vertices = {}
		for i, color in ipairs(colors) do
			local y = (i - 1) / (#colors - 1)
			table.insert(vertices, {1, y, 1, y, color[1], color[2], color[3], color[4] or 1})
			table.insert(vertices, {0, y, 0, y, color[1], color[2], color[3], color[4] or 1})
		end
		return vertices
	end
	
	love.graphics.draw(love.graphics.newMesh(types[type](), "strip", "static"), x, y, r, w, h, ox, oy, kx, ky)
end

---------------------------------------------------------------- MISC

function noop(...) end

function unrequire(arg)
	package.loaded[arg] = nil
end

dofile_ = dofile
function dofile(path, env)
	path = string.right(path, 4) == ".lua" and path or path..".lua"
	local run = assert(love.filesystem.load(path), path.." not found")
	if env then setfenv(run, env) end
	return run()
end

os.date_ = os.date
function os.date(format, time)
	time = time or os.time()
	if format == "*t" then
		local t = os.date_("*t",time)
		-- default fields: year, month, day, hour, min, sec, wday, yday, isdst
		t.wdayname = string.tokenize("monday,tuesday,wednesday,thursday,friday,saturday,sunday",",",t.wday)
		t.wdayshort = string.left(t.wdayname,3)
		t.monthname = string.tokenize("january,february,march,april,may,june,july,august,september,october,november,december",",",t.month)
		t.monthshort = string.left(t.monthname,3)
		t.hour12 = tonumber(os.date_("%I",time))
		t.period = os.date_("%p",time) -- am, pm
		t.week = tonumber(os.date_("%W",time))
		t.yearshort = tonumber(os.date_("%y",time))
		t.beats = (time + 3600) % 86400 / 86.4 -- swatch internet time
		return t
	end
	return os.date_(format, time)
end

-- allows using __gc metamethod on table
-- TODO: what about __len, __pairs and __ipairs
function setproxy(arg)
	local proxy = newproxy(true)
	getmetatable(proxy).__gc = function()
		return arg.__gc and arg:__gc()
	end
	arg.__newproxy = proxy
end
