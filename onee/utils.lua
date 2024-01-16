
---------------------------------------------------------------- BOOLS
bool = {}

function bool.int(arg)
	return arg and 1 or 0
end

---------------------------------------------------------------- MATH
-- TODO: lerp (and pingpong), smoothstep, decay, map from one min-max range to another (0-255 to 0-1), closest to ^2, construct 2, vector 2?
-- angle from x1 y1 to x2 y2

math.random = love.math.random
math.int = math.floor
pi = math.pi
inf = math.huge

function math.choose(...)
	local arg = type(...) == "table" and ... or {...}
	return arg[math.random(#arg)]
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
	local mul = math.pow(10, decimals or 0)
    return math.floor(arg * mul + 0.5) / mul;
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

---------------------------------------------------------------- TABLES

function table.find(arg, result)
    for k,v in pairs(arg) do
        if v == result then return k end
    end
end

function table.append(a, b)
	a, b = a or {}, b or {}
	for k,v in pairs(b) do 
		if type(v) == "table" and type(a[k] or false) == "table" then
			table.append(a[k], b[k])
		else
			a[k] = v
		end
	end
	return a
end

function table.length(arg)
	local i = 0
	for k,v in pairs(arg) do i = i + 1 end
	return i
end

function table.mostcommon(arg)
	local count = {}
	for k, v in pairs(arg) do
		count[v] = (count[v] or 0) + 1
	end
	
	local common = next(count)
	local current = count[common]
	for k, v in pairs(count) do
		if count[k] > current then
			common, current = k, v
		end
	end
	
	return common
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
		return keys[i] and keys[i], arg[keys[i]] or nil
	end
end

function copy(a, seen)
	if type(a) ~= "table" then
		return a 
	end
	if seen and seen[a] then
		return seen[a] 
	end
	seen = seen or {}
	local b = setmetatable({}, getmetatable(a))
	seen[a] = b
	for k, v in pairs(a) do 
		b[copy(k, seen)] = copy(v, seen) 
	end
	return b
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
	
	arg.queue = nil
end

---------------------------------------------------------------- STRINGS

string.replace = string.gsub
string.mid = string.sub
string.lowercase = string.lower
string.uppercase = string.upper
newline = "\n"

function string.findcase(arg, find, i, plain) -- case insensitive
	return string.find(string.lower(arg), string.lower(find), i, plain)
end

function string.split(arg)
	local t = {}
	for i = 1, #arg do
		table.insert(t, string.mid(arg, i, i))
	end
	return t
end

function string.left(arg, len) -- alias
	return string.mid(arg, 1, len)
end

function string.right(arg, len) --alias
	if len < 0 then len = #arg - math.abs(len) end -- count from end
	return string.mid(arg, #arg - (len - 1), #arg)
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
	arg = tostring(arg)
	if #arg < decimals then decimals = decimals - #arg else decimals = 0 end
	return string.rep("0", decimals)..arg
end

function string.md5(arg) -- alias
	return love.data.hash("md5", tostring(arg))
end

-- % is the escape character for separator, because this uses patterns (not regex)
-- TODO: automatically replace ( with %( and |+ with %|%+ and etc 
function string.tokenize(arg, separator, index)
	-- get last index
	if index == -1 then index = #string.tokenize(arg, separator) end
	
	local t = {}
	for i in string.gmatch(arg..separator, "([^"..separator.."]*)"..separator) do
		table.insert (t, i)
		if index then
			if table.find(t, i) == index then return t[index] end
		end
	end
	return t
end

function string.version(arg)
	arg = arg or onee.version
	
	local ver = string.tokenize(arg, "-", 1)
	local pre = string.tokenize(arg, "-", 2)
	
	ver = string.tokenize(ver, ".")
	if type(pre) == "string" then table.insert(ver, pre) end
	
	return unpack(ver)
end

---------------------------------------------------------------- FILES
files = {}

files.exists = love.filesystem.getInfo

function unrequire(arg)
	package.loaded[arg] = nil
end

---------------------------------------------------------------- DEBUG

function debug.table(arg, mode, indent) -- alias
	print(serialize.pack(arg, indent or 1, mode or "lax"))
end

--TODO
--color random, color constants like red, white, black
--rgb(math.random(0,255), math.random(0,255), math.random(0,255))
--rgb(collision.debug.rgb, opacity)
