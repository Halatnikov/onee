
---------------------------------------------------------------- BOOLS
bool = {}

function bool.int(arg)
	return arg == true and 1 or 0
end

---------------------------------------------------------------- MATH
-- TODO: lerp (and pingpong), smoothstep, decay, closest to ^2, construct 2, vector 2?
-- angle from x1 y1 to x2 y2

math.random = love.math.random
math.int = math.floor
pi = math.pi
inf = math.huge

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

function string.findcase(arg, find, index, plain) -- case insensitive alias
	return string.find(string.lower(arg), string.lower(find), index, plain)
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

function string.zeropad(arg, decimals)
	if math.is_int(decimals) then -- do 20 -> 0020
		return string.format("%0"..decimals.."d", arg)
	elseif math.between(0, decimals, 1) then -- do 0.2 -> 0.200
		decimals = #tostring(decimals) == 3 and decimals * 10 or decimals * 100
		return string.format("%."..decimals.."f", arg)
	end
end

function string.md5(arg) -- alias
	return love.data.hash("md5", tostring(arg))
end

function string.tokenize(arg, separator, index)
	if index == -1 then index = #string.tokenize(arg, separator) end -- get last index
	
	local escaped = string.escape(separator)
	
	local t = {}
	for k in string.gmatch(arg..separator, "([^"..escaped.."]*)"..separator) do
		table.insert (t, k)
		
		if index then
			if table.find(t, k) == index then return t[index] end
		end
	end
	if not index then return t end
end

function string.version(arg)
	arg = arg or onee.version
	
	local ver = string.tokenize(arg, "-", 1)
	local pre = string.tokenize(arg, "-", 2)
	
	ver = string.tokenize(ver, ".")
	if pre then table.insert(ver, pre) end
	
	return unpack(ver)
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

function table.reverse(arg)
	return table.sort(arg, function(a,b) return a > b end)
end

function table.fill(v, min, max)
	if not max then min, max = 1, min end
	local t = {}
	for i = min, max do table.insert(t, v) end
	return t
end

function table.append(a, b)
	a, b = a or {}, b or {}
	local mt = getmetatable(b)
	if mt then setmetatable(a, mt) end
	
	for k,v in pairs(b) do 
		if type(v) == "table" and type(a[k] or false) == "table" then
			table.append(a[k], b[k])
		else
			if mt and mt.protected and table.find(mt.blacklist, k) then k = "__"..k end
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

function table.maxn(arg, v)
	local maxn
	for k,v in pairs(arg) do
		if not v then -- keys
			maxn = maxn or k
			maxn = k > maxn and k or maxn
		else -- values
			maxn = maxn or v
			maxn = v > maxn and v or maxn
		end
	end
	return maxn
end
function table.maxv(arg) return table.maxn(arg, true) end -- alias
table.maxk = table.maxn -- alias

function table.minn(arg, v)
	local minn
	for k,v in pairs(arg) do
		if not v then -- keys
			minn = minn or k
			minn = k < minn and k or minn
		else -- values
			minn = minn or v
			minn = v < minn and v or minn
		end
	end
	return minn
end
function table.minv(arg) return table.minn(arg, true) end -- alias
table.mink = table.minn -- alias

function table.sortby(arg, k, descending)
	return table.sort(arg, function(a,b)
		if not (a[k] and b[k]) then return end
		if not descending then
			if type(a) ~= type(b) then return tostring(a[k]) < tostring(b[k]) end
			return a[k] < b[k]
		else
			if type(a) ~= type(b) then return tostring(a[k]) > tostring(b[k]) end
			return a[k] > b[k]
		end
	end)
end

function table.sortv(arg, descending)
	return table.sort(arg, function(a,b)
		if not (arg[a] and arg[b]) then return end
		if not descending then
			if type(arg[a]) ~= type(arg[b]) then return tostring(arg[a]) < tostring(arg[b]) end
			return arg[a] < arg[b]
		else
			if type(arg[a]) ~= type(arg[b]) then return tostring(arg[a]) > tostring(arg[b]) end
			return arg[a] > arg[b]
		end
	end)
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
			arg[parent].children = arg[parent].children or {}
			table.insert(arg[parent].children, node)
		else
			table.insert(tree, node)
		end
	end
  
	return tree
end

function table.protect(arg, blacklist)
	local proxy = {}
	local mt = {
		protected = true,
		blacklist = blacklist,
		__index = arg,
		__newindex = function(t, k, v)
			assert(not table.find(blacklist, "__"), "attempt to modify protected table")
			assert(not table.find(blacklist, k), "attempt to overwrite protected key \""..k.."\"")
			k = string.remove(k, "__") -- bypass by setting __key
			arg[k] = v
		end,
	}
	setmetatable(proxy, mt)
	return proxy
end

---------------------------------------------------------------- ITERATORS

pairs_ = pairs
function pairs(arg)
	local mt = getmetatable(arg)
	if mt and mt.protected then arg = mt.__index end
	
	return pairs_(arg)
end

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
		if i ~= 0 then
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
--TODO
--color random, color constants like red, white, black
--rgb(math.random(0,255), math.random(0,255), math.random(0,255))
color = {}

function color.random()
	return math.random(0,255), math.random(0,255), math.random(0,255)
end

function hsl(h, s, l, a)
	if s <= 0 then return l, l, l, a end
	h = h * 6
	local c = (1 - math.abs( 2 * l - 1)) * s
	local x = (1 - math.abs( h % 2 - 1)) * c
	local m = (1 - 0.5 * c)
	local r, g, b
	if h < 1 then     r, g, b = c, x, 0
	elseif h < 2 then r, g, b = x, c, 0
	elseif h < 3 then r, g, b = 0, c, x
	elseif h < 4 then r, g, b = 0, x, c
	elseif h < 5 then r, g, b = x, 0, c
	else              r, g, b = c, 0, x
	end 
	return r + m, g + m, b + m, a
end

function rgb(r, g, b, a)
	if type(r) == "table" then
		r, g, b, a = r[1], r[2], r[3], g or r[4] -- allow "{rgb},a"
	end
	
	r = math.between(0, r, 1) and r or r/255
	g = math.between(0, g, 1) and g or g/255
	b = math.between(0, b, 1) and b or b/255
	a = a and (math.between(0, a, 1) and a or a/100)
	return r, g, b, a
end

function torgb(r, g, b, a)
	return math.round(r*255), math.round(g*255), math.round(b*255), a and math.round(a*255)
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
	
	local vertices = {}
	if type == "horizontal" then
		for i, color in ipairs(colors) do
			local x = (i - 1) / (#colors - 1)
			table.insert(vertices, {x, 1, x, 1, color[1], color[2], color[3], color[4] or 1})
			table.insert(vertices, {x, 0, x, 0, color[1], color[2], color[3], color[4] or 1})
		end
	elseif type == "vertical" then
		for i, color in ipairs(colors) do
			local y = (i - 1) / (#colors - 1)
			table.insert(vertices, {1, y, 1, y, color[1], color[2], color[3], color[4] or 1})
			table.insert(vertices, {0, y, 0, y, color[1], color[2], color[3], color[4] or 1})
		end
	end
	
	love.graphics.draw(love.graphics.newMesh(vertices, "strip", "static"), x, y, r, w, h, ox, oy, kx, ky)
end

---------------------------------------------------------------- MISC

function noop(...) end

function unrequire(arg)
	package.loaded[arg] = nil
end

dofile_ = dofile
function dofile(path, env)
	if string.right(path, 4) ~= ".lua" then path = path..".lua" end 
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
		t.wdayname = string.tokenize("Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday",",",t.wday)
		t.wdayshort = string.left(t.wdayname,3)
		t.monthname = string.tokenize("January,February,March,April,May,June,July,August,September,October,November,December",",",t.month)
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
