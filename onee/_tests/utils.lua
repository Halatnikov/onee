group("math library extension", function()
	test("globals", function()
		assert(math.random == love.math.random).pass()
		assert(math.int == math.floor).pass()
		assert(pi == math.pi).pass()
		assert(inf == math.huge).pass()
	end)
	test("math.is_int(arg)", function()
		assert(math.is_int(1)).pass("1 is an int")
		assert(math.is_int(2.5)).deny("2.5 isn't an int")
	end)
	test("math.is_float(arg)", function()
		assert(math.is_float(1)).deny("just a negated math.is_int()")
	end)
	test("math.sign(arg)", function()
		assert(math.sign(2) == 1).pass("2 is positive")
		assert(math.sign(-2) == -1).pass("-2 is negative")
		assert(math.sign(0) == 0).pass("0 is well, 0")
	end)
	test("math.flipsign(arg)", function()
		assert(math.flipsign(2) == -2).pass("2 is -2")
		assert(math.flipsign(-2) == 2).pass("-2 is 2")
		assert(math.flipsign(0) == 0).pass("0 is still 0")
	end)
	test("math.between(min, arg, max)", function()
		assert(math.between(0, 1, 2)).pass("1 is between 0 and 2")
		assert(math.between(0, 0, 2) and math.between(0, 2, 2)).pass("0 and 2 are between 0 and 2")
		assert(math.between(0, -1, 2) and math.between(0, 3, 2)).deny("-1 and 3 aren't between 0 and 2")
		assert(math.between(2, 3, 0)).deny("wrong min max order")
	end)
	test("math.clamp(min, arg, max)", function()
		assert(math.clamp(0, 1, 2) == 1).pass("1 is within 0 and 2")
		assert(math.clamp(0, 3, 2) == 2 and math.clamp(0, -1, 2) == 0).pass("clamp -1 and 3 to be within 0 than 2")
		assert(math.clamp(2, 1, 0) == 2).pass("wrong min max order")
	end)
	test("math.wrap(min, arg, max)", function()
		assert(math.wrap(0, 1, 2) == 1).pass("1 is within 0 and 2")
		assert(math.wrap(0, 3, 2) == 0 and math.wrap(0, -1, 2) == 2).pass("wrap -1 and 3 to be within 0 than 2")
		assert(math.wrap(2, -1, 0) == 0 and math.wrap(2, 3, 0) == 2).pass("wrong min max order")
	end)
	test("math.round(arg, decimals)", function()
		assert(math.round(1.3) == 1).pass("below 0.5 rounds to 0")
		assert(math.round(1.7) == 2).pass("above and 0.5 rounds to 1")
		assert(math.round(1.499, 2) == 1.5).pass("cut down decimals and slightly round")
		assert(math.round(1.500, 3) == 1.5).pass("expects maximum amount of decimals, rounds 1.500 to 1.5")
		assert(math.round(1) == 1).pass("try an int")
		assert(math.round(1.7, 1) == 1.7).pass("that did nothing")
	end)
	test("math.choose(...)", function()
		local choose = math.choose("a", "b", "c")
		assert(choose == "a" or choose == "b" or choose == "c").pass("returns random key from args")
		local t = {"a", "b", "c"}
		local choose = math.choose(t)
		assert(choose == "a" or choose == "b" or choose == "c").pass("recognizes a table")
	end)
	test("math.average(...)", function()
		assert(math.average(1, 2) == 1.5).pass("average from args")
		assert(math.average(1, 3, 2) == 2).pass("any count")
		local t = {1}
		assert(math.average(t) == 1).pass("recognizes a table")
	end)
	test("math.distance(x1, x2, y1, y2)", function()
		assert(math.distance(0,1,1,2) == math.distance(0,1,1,0)).pass("ima be honest, i've no idea")
		assert(math.distance(0,1) == math.distance(0,0,1,1)).pass("accept just the first 2 args")
	end)
	test("math.map(arg, a_min, a_max, b_min, b_max)", function()
		assert(math.round(math.map(128, 0, 255, 0, 1), 1) == 0.5).pass("map value from 0-255 range to 0-1")
		assert(math.round(math.map(0.25, 0, 1, 0, 255)) == 64).pass("vice versa")
	end)
	test("math.loop(a, b, t)", function()
		local before, after = math.loop(0, 1, 1), math.loop(0, 1, 1)
		assert(after > before).pass("loops a through b over t in seconds with unspecified starting point")
		local before, after = math.loop(1, 0, 1), math.loop(1, 0, 1)
		assert(after < before).pass("if a > b then loop from b to a")
		local before, after = math.loop(-32, 48, 64), math.loop(-32, 48, 64)
		assert(after > before).pass("non 0-1 range")
		local before, after = math.loop(48, -32, 64), math.loop(48, -32, 64)
		assert(after < before).pass("non 0-1 range in reverse")
		local before, after = math.loop(-1, -2, 1), math.loop(-1, -2, 1)
		assert(after < before).deny("reverse a and b")
		local before, after = math.loop(0, 1, -1), math.loop(0, 1, -1)
		assert(after > before).deny("reverse t")
	end)
end)

group("string library extension", function()
	test("globals", function()
		assert(string.replace == string.gsub).pass()
		assert(string.mid == string.sub).pass()
		assert(string.lowercase == string.lower).pass()
		assert(string.uppercase == string.upper).pass()
		assert(newline == "\n").pass()
	end)
	test("string.trim(arg)", function()
		assert(string.trim(" a b ") == "a b").pass("remove spaces before and after the string")
	end)
	test("string.escape(arg)", function()
		assert(string.escape("(a+b)?") == "%(a%+b%)%?").pass("escape all special characters used in lua patterns")
	end)
	test("string.split(arg)", function()
		assert(table.compare(string.split("a,b!c1"), {"a",",","b","!","c","1"})).pass("split string into table")
	end)
end)

group("table library extension", function()
	
	local a, b = {"a","c","b"}, {"a","c","b"}
	print(a==b)
	print(table.compare(a,b))
	test("copy(arg) - deep-copying a table", function()
		local a, b
		a, b = {}, {}; a = b
		local function modifies_origin(arg)
			local t = arg; t.test = 1
		end
		modifies_origin(b)
		assert(a.test).exist("let's say tables are weird sometimes")
		
		a, b = {}, {}; a = b
		local function doesnt_modify(arg)
			local t = copy(arg); t.test = 1
		end
		doesnt_modify(b)
		assert(a.test).to_not.exist("doesn't modify the original")
	end)
	test("table.find(arg, result)", function()
		local t = { a = "a", b = 2, c = "A", }
		local string_vals = { "a", "b", "c", }
		local number_vals = { 1, 3, 2, }
		
		assert(table.find(t,"A") == "c").pass("search value, get key")
		assert(table.find(t,"d")).deny("no such value")
		assert(table.find(string_vals,"c")).type("number", "string values")
		assert(table.find(number_vals,2) == 3).pass("number values")
	end)
	test("table.length(arg)", function()
		local t_num = {1, 2, 3}
		local t_str = {a = 1, b = 2, c = 3}
		local mixed_keys = { 1, a = 1, b = {}, 3, {}, }
		local not_from_0 = {}; for i = -2, 4 do not_from_0[i] = true end
		
		assert(#t_num == table.length(t_num)).pass()
		assert(#t_str == 0 and table.length(t_str) == 3).pass("works more accurately than #table")
		assert(#mixed_keys == 3 and table.length(mixed_keys) == 5).pass("doesn't ignore non numeric keys")
		assert(#not_from_0 == 4 and table.length(not_from_0) == 7).pass("doesn't ignore anything lower then 0")
	end)
	test("table.mostcommon(arg)", function()
		local t = { 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 4 }
		local common, counts = table.mostcommon(t)
		assert(common == 4).pass("most common numeric value in a table")
		assert(counts[1] == 2).pass("table with count of occurances of values")
	end)
	test("kpairs() and vpairs() iterator", function()
		local t = {a = true, d = true, b = true, c = true}
		local not_from_0 = {}; for i = -2, 4 do not_from_0[i] = true end
		local t_sorted = {}; for k,v in kpairs(not_from_0) do print(k,v) end
		local t_sorted = {}; for k,v in kpairs(t) do table.insert(t_sorted, k) end
		
		assert(t_sorted[2] == "b" and t_sorted[4] == "d").pass("keys alphabetically sorted")
	end)
	test("ripairs() iterator", function()
		local t = {2, 3, 4}
		local t_sorted = {}; for k,v in ripairs(t) do table.insert(t_sorted, v) end
		
		assert(t_sorted[1] == 4).pass("numeric table in reverse")
	end)
end)

group("queue library", function()
	local t, val
	local function subtract(arg)
		val = val - arg
	end
	before(function()
		t = {}; val = 0
	end)
	
	test("make a queue and execute", function()
		for i = -1, 4 do queue.add(t, i, function() subtract(1) end) end
		assert(t.queue).exist("queue initialized")
		assert(t.first == -1 and t.last == 4).pass()
		assert(t.queue[1][1]).type("function")
		
		queue.execute(t)
		assert(val == -6).pass("executed queue")
		assert(t.queue and t.first and t.last).deny("queue is emptied when executed")
	end)
	test("adding to the same index", function()
		queue.add(t, 2, function() subtract(1) end)
		queue.add(t, 2, function() subtract(1) end)
		queue.add(t, 2, function() subtract(1) end)
		assert(t.queue[2][3]).type("function")
		
		queue.execute(t)
		assert(val == -3).pass("executed queue")
	end)
end)
