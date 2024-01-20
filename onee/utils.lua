
---------------------------------------------------------------- BOOLS
bool = {}

function bool.int(arg)
	return arg and 1 or 0
end

---------------------------------------------------------------- MATH
-- TODO: lerp (and pingpong), smoothstep, decay, closest to ^2, construct 2, vector 2?
-- angle from x1 y1 to x2 y2
-- every x seconds

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

function math.round(arg, decimals)
	decimals = 10 ^ math.abs(decimals or 0)
    return math.floor(arg * decimals + 0.5) / decimals
end

function math.choose(...)
	local arg = type(...) == "table" and ... or {...}
	return arg[math.random(#arg)]
end

function math.randomfake(min, max, precision)
	if not (min and max) then min, max = 0, 1 end
	max = max or min
	precision = precision or 4
	local time = love.timer.getTime()
	time = math.floor((time - math.floor(time)) * 10^precision)
	return time % 2 == 0 and max or min
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
	if b < a then a, b = b, a
		t = t + (0.707 * (b - a)) -- offset starting point by sqrt(2)/2 if going from b to a
	end
	t = love.timer.getTime() / (t / b)
	local len = b - a
	t = math.clamp(a, t - math.floor(t / (len*2)) * (len*2), b*2)
	return len - math.abs(t - len)
end

---------------------------------------------------------------- STRINGS
--TODO: string.join

string.replace = string.gsub
string.mid = string.sub
string.lowercase = string.lower
string.uppercase = string.upper
newline = "\n"

function string.split(arg)
	local t = {}
	for i = 1, #arg do
		table.insert(t, string.mid(arg, i, i))
	end
	return t
end

function string.trim(arg)
   return string.gsub(arg, "^%s*(.-)%s*$", "%1")
end

function string.left(arg, len) -- alias
	return string.mid(arg, 1, len)
end

function string.right(arg, len) --alias
	if len < 0 then len = #arg - math.abs(len) end -- count from end
	return string.mid(arg, #arg - (len - 1), #arg)
end

function string.findcase(arg, find, i, plain) -- case insensitive alias
	return string.find(string.lower(arg), string.lower(find), i, plain)
end

function string.random(length)
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
	local t = {}
	for i=1, length do
		local r = math.random(1, #charset)
		table.insert(t, string.mid(charset, r, r))
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

function string.remove(arg, find) -- alias
	return string.replace(arg, find, "")
end

function string.md5(arg) -- alias
	return love.data.hash("md5", tostring(arg))
end

function string.tokenize(arg, separator, index)
	if index == -1 then index = #string.tokenize(arg, separator) end -- get last index
	
	local escaped = string.replace(separator, "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%1")
	
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
--TODO: reverse a table, maxn

function copy(a, seen)
	if type(a) ~= "table" then
		return a 
	end
	if seen and seen[a] then
		return seen[a] 
	end
	local seen = seen or {}
	local mt_a = getmetatable(a) or {}
	local b = setmetatable({}, mt_a)
	seen[a] = b
	for k, v in pairs(a) do 
		if mt_a.protected and table.find(mt_a.blacklist, k) then k = "__"..k end
		b[copy(k, seen)] = copy(v, seen) 
	end
	return b
end

function table.compare(a, b)
	if a == b then return true end
	for k, v in pairs(a) do
		if a[k] ~= b[k] then return false end
	end
	for k, v in pairs(b) do
		if b[k] ~= a[k] then return false end
	end
	return true
end

function table.append(a, b)
	a, b = a or {}, b or {}
	local mt_a, mt_b = getmetatable(a) or {}, getmetatable(b) or {}
	if mt_b ~= {} then setmetatable(a, mt_b) end
	
	for k,v in pairs(b) do 
		if type(v) == "table" and type(a[k] or false) == "table" then
			table.append(a[k], b[k])
		else
			if mt_b.protected and table.find(mt_b.blacklist, k) then k = "__"..k end
			a[k] = v
		end
	end
	return a
end

function table.find(arg, result)
    for k,v in pairs(arg) do
        if v == result then return k end
    end
end

function table.length(arg)
	local i = 0
	for k,v in pairs(arg) do i = i + 1 end
	return i
end

function table.reverse(arg)
	local t = copy(arg)
	table.sort(t, function(a,b) return a > b end)
	return t
end

function table.sortby(arg, k)
	local t = copy(arg)
	table.sort(t, function(a,b) return a[k] < b[k] end)
	return t
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

local _pairs = pairs
function pairs(arg)
	local mt = getmetatable(arg)
	if mt and mt.protected then arg = mt.__index end
	
	return _pairs(arg)
end

function kpairs(arg)
	local keys = {}
	for k in pairs(arg) do table.insert(keys, k) end
	table.sort(keys, function(a, b)
		if type(a) ~= type(b) then return tostring(a) < tostring(b) end
		return a < b
	end)
	local i = 0
	return function()
		i = i + 1
		-- nil is important
		return keys[i] == nil and nil or keys[i], arg[keys[i]]
	end
end

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
--rgb(collision.debug.rgb, opacity)
color = {}

function color.hsl(h, s, l, a)
	a = a or 1
	if s <= 0 then return l, l, l, a end
	h = h * 6
	local c = (1 - math.abs( 2 * l - 1)) * s
	local x = (1 - math.abs( h % 2 - 1)) * c
	local m = (1 - 0.5 * c)
	local r, g, b
	if h < 1 then r, g, b = c, x, 0
	elseif h < 2 then r, g, b = x, c, 0
	elseif h < 3 then r, g, b = 0, c, x
	elseif h < 4 then r, g, b = 0, x, c
	elseif h < 5 then r, g, b = x, 0, c
	else r, g, b = c, 0, x
	end 
	return r + m, g + m, b + m, a
end

---------------------------------------------------------------- FILES
files = {}

files.exists = love.filesystem.getInfo

dofile_ = dofile
function dofile(path, env)
	local run = assert(love.filesystem.load(path), path.." not found")
	if env then setfenv(run, env) end
	run()
end

function unrequire(arg)
	package.loaded[arg] = nil
end

