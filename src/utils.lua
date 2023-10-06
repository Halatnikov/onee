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

function string.random(length)
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
	local t = {}
	for i=1, length do
		local r = love.math.random(1, #charset)
		table.insert(t, string.sub(charset, r, r))
	end
	return table.concat(t)
end

-- % is the escape character for separator, because this uses patterns (not regex)
function string.tokenize(arg, separator, index)
	-- todo: automatically replace ( with %( and |+ with %|%+ and etc 
	local t = {}
	for i in string.gmatch(arg..separator, "([^"..separator.."]*)"..separator) do
		table.insert (t, i)
		if index then
			if table.find(t, i) == index then return t[index] end
		end
	end
	return t
end

function string.replace(arg,find,replace) -- that's right
	return string.gsub(arg,find,replace)
end

function debug.table(arg,drop,indent)
	print(tserial.pack(arg,drop or true,indent or true))
end