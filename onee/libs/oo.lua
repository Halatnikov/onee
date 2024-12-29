-- Pure Lua classes with multiple inheritance.
-- MIT/X license (c) 2016 Daniel Lima

-- Create an instance of self
local function new(self, param, ...)
	local obj
	if not ... and type(param) == 'table' then
		obj = setmetatable(param, self)
		obj:__init()
	else
		obj = setmetatable({}, self)
		obj:__init(param, ...)
	end
	return obj
end

local root = {
	__init = function(...) end,
}
local types = {
	[root] = {},
}

-- Create a new subclass of the 'base' class,
-- passing several tables as mixins for multiple inheritance.
-- In case of conflicting attributes, the last mixin will resolve.
local function extend(base,...)
	-- T is the new subclass of self
	local T = {
		__init = base.__init, --default initializer
	}
	
	-- superclasses of T
	types[T] = { [T]=true }
	for t in pairs(types[base]) do
		types[T][t] = true
	end
	
	-- copy mixins to T
	for _,m in ipairs{...} do
		types[T][m] = true
		for t in pairs(types[m] or {}) do
			types[T][t] = true
		end
		for k,v in pairs(m) do
			T[k] = v
		end
	end
	
	-- link methods
	T.super   = base
	T.extend  = extend
	T.__index = T
	-- test if object is an instance of class (or any subclass)
	function T:is(class)
		return types[T][class]
	end
	
	return setmetatable(T, {__call = new, __index = base})
end

-- alias to class creation
local function alias(self, ...)
	return extend(root,...)
end

class = setmetatable({types = types}, {__call = alias})

