
---------------------------------------------------------------- BOOLS
bool = {}

function bool.int(arg)
	return arg and 1 or 0
end

---------------------------------------------------------------- MATH
-- TODO: lerp, smoothstep, decay, map from one min-max range to another, ^2, construct 2, vector 2?

function math.random(...) -- alias
	return love.math.random(...)
end

function math.choose(...)
	local arg = {...}
	return arg[math.random(#arg)]
end

function math.sign(arg)
	return (arg > 0) and 1 or (arg < 0) and -1 or 1
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
	local arg = {...}
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
	if not a then a = {} end
	if not b then b = {} end
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
	table.sort(keys, 
		function(a, b)
			if type(a) ~= type(b) then return tostring(a) < tostring(b) end
			return a < b
		end)
	local i = 0
	local function iterate()
		i = i + 1
		if keys[i] == nil then
			return nil
		else 
			return keys[i], arg[keys[i]]
		end
	end
	return iterate
end

---------------------------------------------------------------- QUEUEING
queue = {}

function queue.add(arg, i, add)
	if not arg.queue then
		table.append(arg, {queue = {}, first = 1, last = 1})
	end

	if i < arg.first then arg.first = i end
	if i > arg.last then arg.last = i end
	
	if not arg.queue[i] then arg.queue[i] = {} end
	table.insert(arg.queue[i], add)
end

function queue.execute(arg)
	if not arg.queue then return end
	for i = arg.first, arg.last do
		if arg.queue[i] then
			for k,v in pairs(arg.queue[i]) do v() end
		end
	end
	
	arg.queue = nil
end

---------------------------------------------------------------- STRINGS
-- TODO: construct 2 (left right (trim?), etc)

function string.replace(arg,find,replace) -- alias
	return string.gsub(arg,find,replace)
end

function string.split(arg)
	local t = {}
	for i = 1, #arg do
		table.insert(t, string.sub(arg, i, i))
	end
	return t
end

function string.random(length)
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
	local t = {}
	for i=1, length do
		local r = math.random(1, #charset)
		table.insert(t, string.sub(charset, r, r))
	end
	return table.concat(t)
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
	local ver = arg or version
	local pre
	
	if string.find(ver,"-") then
		ver = string.tokenize(arg,"%-",1)
		pre = tonumber(string.tokenize(arg,"%-",2))
	end
	
	ver = tonumber(table.concat(string.tokenize(ver,"%.")))
	
	return ver, pre
end

---------------------------------------------------------------- FILES
files = {}

function files.exists(path) -- alias
	return love.filesystem.getInfo(path)
end

---------------------------------------------------------------- DEBUG

function debug.table(arg,drop,indent) -- alias
	print(tserial.pack(arg,drop or true,indent or true))
end