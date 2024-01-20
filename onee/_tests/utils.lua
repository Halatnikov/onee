lust = require("onee/libs/lust")
local describe, it, expect = lust.describe, lust.it, lust.expect
local before, after = lust.before, lust.after
local spy = lust.spy
local paths = lust.paths

local group, test, assert = describe, it, expect

-- assert().pass()
paths.pass = {test = paths.truthy.test}
table.insert(paths[""], "pass")
table.insert(paths.to, "pass")
table.insert(paths.to_not, "pass")

-- assert().deny()
paths.deny = {test = function(v, msg)
	return v == false or v == nil,
	'expected ' .. tostring(v) .. ' to be falsy',
	'expected ' .. tostring(v) .. ' to not be falsy',
	msg
end}
table.insert(paths[""], "deny")
table.insert(paths.to, "deny")
table.insert(paths.to_not, "deny")

-- assert().error()
paths.error = {test = paths.fail.test}
table.insert(paths[""], "error")
table.insert(paths.to, "error")
table.insert(paths.to_not, "error")

-- assert().success()
paths.success = {test = function(f, msg)
	return pcall(f),
	'expected ' .. tostring(f) .. ' to succeed',
	'expected ' .. tostring(f) .. ' to not succeed',
	msg
end}
table.insert(paths[""], "success")

-- assert().type()
paths.type = {test = function(v, x, msg)
	return type(v) == x,
	"expected "..tostring(v).." to be a "..x,
	"expected "..tostring(v).." to not be a "..x,
	msg
end}
table.insert(paths[""], "type")
table.insert(paths.be, "type")

--assert().exist()
paths.exist = {test = paths.exist.test}
table.insert(paths[""], "exist")

print("STARTING TEST")

group("utils test", function()
	
	test("conventions", function()
		assert(bool.int(nil) == 0).pass("don't check for types")
		assert(bool.int() == 0).pass()
		assert(bool.int("string") == 1).pass()
		
		assert(function() math.sign("string") end).error("can error when passing a wrong type")
	end)
	
	group("bool library", function()
		test("bool.int(arg)", function()
			assert(bool.int(true) == 1).pass("true is 1")
			assert(bool.int(false) == 0).pass("false is 0")
		end)
	end)
	
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
	end)
	
	group("table library extension", function()
		
		test("copy(arg) - deep-copying a table", function()
			local a, b
			a, b = {}, {}
			a = b
			local function modifies_origin(arg)
				local t = arg; t.test = 1
			end
			modifies_origin(b)
			assert(a.test).exist("let's say tables are weird sometimes")
			
			a, b = {}, {}
			a = b
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
			
			assert(table.find(t,"A") == "c").pass()
			assert(table.find(t,"d") == nil).pass()
			assert(table.find(string_vals,"c")).type("number")
			assert(table.find(number_vals,2) == 3).pass()
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
		
		test("table.protect(arg, blacklist)", function()
			local t = { a = 1, b = 2, c = 3 }
			t = table.protect(t, {"a", "c"})
			local mt = getmetatable(t)
			assert(mt.protected).pass("identifies as protected")
			assert(t.c == 3).pass("can still index it")
			assert(function() t.d = 4; t.b = nil end).success("can still modify it")
			
			assert(function() t.a = 5 end).error("can't modify a protected key")
			assert(t.a == 1).pass("key is still unchanged")
			
			assert(function() t.__a = 5 end).success("can bypass protection by modifying __key")
			assert(t.a == 1).deny("now the key is changed")
			
			table.remove(mt.blacklist, table.find(mt.blacklist, "c"))
			assert(function() t.c = 5 end).success("able to modify the blacklist")
			
			local t2 = {}; for k,v in pairs(t) do t2[k] = v end
			assert(t2.a == 5 and t2.d == 4).pass("still works with pairs() iterator")
		end)
		
		test("kpairs() iterator", function()
			local t = {a = true, d = true, b = true, c = true}
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
		local function substract(arg)
			val = val - arg
		end
		before(function()
			t = {}
			val = 0
		end)
		
		test("make a queue and execute", function()
			for i = -1, 4 do queue.add(t, i, function() substract(1) end) end
			assert(t.queue).exist("queue initialized")
			assert(t.first == -1 and t.last == 4).pass()
			assert(t.queue[1][1]).type("function")
			
			queue.execute(t)
			assert(val == -6).pass("executed queue")
			assert(t.queue and t.first and t.last).deny("queue is emptied when executed")
		end)
		
		test("adding to the same index", function()
			queue.add(t, 2, function() substract(1) end)
			queue.add(t, 2, function() substract(1) end)
			queue.add(t, 2, function() substract(1) end)
			assert(t.queue[2][3]).type("function")
			
			queue.execute(t)
			assert(val == -3).pass("executed queue")
		end)
	end)
	
end)

if lust.errors == 0 then print("O TEST FULLY PASSED")
else
	if lust.passes == 0 then print("X TEST FULLY FAILED")
	else print("X TEST FAILED")
	end
end
print("PASSES: "..lust.passes..", ERRORS: "..lust.errors)
unrequire("onee/libs/lust")