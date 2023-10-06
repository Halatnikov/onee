-- thank you love2d forums, thank you 1492

function math.boolint(arg)
	return arg and 1 or 0
end

function math.sign(arg)
	return (arg > 0) and 1 or (arg < 0) and -1 or 0
end

function math.flipsign(arg)
	return (arg > 0) and -arg or math.abs(arg)
end

function math.clamp(arg, min, max)
    if min > max then min, max = max, min end -- swap if wrong way around
    return math.max(min, math.min(max, arg))
end

function math.round(arg, decimals)
	local mul = math.pow(10, decimals or 0)
    return math.floor(arg * mul + 0.5) / mul;
end

function table.find(table, arg)
    for k,v in pairs(table) do
        if v == arg then return k end
    end
end

function string.random(length)
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
	local t = {}; local r
	for i=1, length do
		r = love.math.random(1, #charset)
		table.insert(t, string.sub(charset, r, r))
	end
	return table.concat(t)
end

-- % is the escape character, because this thing uses patterns (not regex funnily enough)
function string.tokenize(string, sep, index) -- what the hell is this
	local string = string; local t = {}
	for i in string.gmatch(string, "[^"..sep..sep.."]+") do -- replace ",," with ", ," so it doesn't skip it
		string = string.replace(string, sep..sep, sep.." "..sep)
	end
	for i in string.gmatch(string, "[^"..sep.."]+") do
		table.insert (t, i)
		if index then
			if table.find(t, i) == index then return t[index] end
		end
	end
	return t
end

function string.replace(string,find,replace)  -- ye
	return string.gsub(string,find,replace)
end

function debug.table(t,drop,indent)
	local drop = drop or true
	local indent = indent or true
	if t then print(tserial.pack(t,drop,indent)) end
end

function version_int(arg)
	local arg = arg or version
	local pre

	if string.find(arg,"-") then 
		ver = string.tokenize(arg,"%-",1)
		pre = string.tokenize(arg,"%-",2)
	end
	
	ver = tonumber(table.concat(string.tokenize(ver,"%.")))
	
	if pre then return ver, pre end
	if not pre then return ver end
end
