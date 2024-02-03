-- https://github.com/pfirsich/jprof

local msgpack = require("onee/libs/jprof/MessagePack")

-- We need to make sure the number format is "double", so our timestamps have enough accuracy.
-- NOTE: It might be possible to subtract the first timestamp from all others
-- and gain a bunch of significant digits, but we probably want about 0.01ms accuracy
-- which corresponds to 1e-5 s. With ~7 significant digits in single precision floats,
-- our accuracy might suffer already at about 100 seconds, so we go with double
msgpack.set_number("double")

local profiler = {}

-- the zonestack is just for catching errors made using push/pop
-- we preallocate 16 elements here (tested in interactive luajit interpreter v2.0.5)
-- we do this, so table.insert/table.remove does have no (non-constant) impact on
-- the memory consumption we determine using collectgarbage("count"))
-- since no allocations/deallocations are triggered by them anymore
local zoneStack = {}
for i=1, 16 do table.insert(zoneStack, 0) end

local profData = {}
-- profMem keeps track of the amount of memory allocated by prof.push/prof.pop
-- which is then subtracted from collectgarbage("count"),
-- to measure the jprof-less (i.e. "real") memory consumption
local profMem = 0

local function getByte(n, byte)
    return bit.rshift(bit.band(n, bit.lshift(0xff, 8*byte)), 8*byte)
end

-- I need this function (and not just msgpack.pack), so I can pack and write
-- the file in chunks. If we attempt to pack a big table, the amount of memory
-- used during packing can exceed the luajit memory limit pretty quickly, which will
-- terminate the program before the file is written.
local function msgpackListIntoFile(list, file)
    local n = #list
    -- https://github.com/msgpack/msgpack/blob/master/spec.md#array-format-family
    if n < 16 then
        file:write(string.char(144 + n))
    elseif n < 0xFFFF then
        file:write(string.char(0xDC, getByte(n, 1), getByte(n, 0)))
    elseif n < 0xFFffFFff then
        file:write(string.char(0xDD, getByte(n, 3), getByte(n, 2), getByte(n, 1), getByte(n, 0)))
    else
        error("List too big")
    end
    for _, elem in ipairs(list) do
        file:write(msgpack.pack(elem))
    end
end

local function addEvent(name, memCount, annot)
    local event = {name, love.timer.getTime(), memCount, annot}
    if profData then
        table.insert(profData, event)
    end
end

local function push(name, annotation)
	if #zoneStack == 0 then
		assert(name == "frame", "(jprof) You may only push the 'frame' zone onto an empty stack")
	end

	local memCount = collectgarbage("count")
	table.insert(zoneStack, name)
	addEvent(name, memCount - profMem, annotation)

	-- Usually keeping count of the memory used by jprof is easy, but when realtime profiling is used
	-- netFlush also frees memory for garbage collection, which might happen at unknown points in time
	-- therefore the memory measured is slightly less accurate when realtime profiling is used
	-- if the full profiling data is not saved to profData, then only netBuffer will increase the
	-- memory used by jprof and all of it will be freed for garbage collection at some point, so that
	-- we should probably not try to keep track of it at all
	if profData then
		profMem = profMem + (collectgarbage("count") - memCount)
	end
end

local function pop(name)
	if name then
		-- assert(zoneStack[#zoneStack] == name,
			-- ("(jprof) Top of zone stack, does not match the zone passed to prof.pop ('%s', on top: '%s')!"):format(name, zoneStack[#zoneStack]))
	end
	if name and zoneStack[#zoneStack] ~= name then return end
	if zoneStack[#zoneStack] == nil then return end

	local memCount = collectgarbage("count")
	table.remove(zoneStack)
	addEvent("pop", memCount - profMem)
	if profData then
		profMem = profMem + (collectgarbage("count") - memCount)
	end
end

local function popAll()
	for i = #zoneStack, 1, -1 do
		pop(zoneStack[i])
	end
end

function profiler.write(filename)
	assert(#zoneStack == 0, "(jprof) Zone stack is not empty")

	if profData then
		local file, msg = love.filesystem.newFile(filename, "w")
		assert(file, msg)
		msgpackListIntoFile(profData, file)
		file:close()
		print(("(jprof) Saved profiling data to '%s'"):format(filename))
	end
end

local noop = function() end

function profiler.enabled(enabled)
	if enabled then
		profiler.push = push
		profiler.pop = pop
		profiler.popAll = popAll
	else
		profiler.push = noop
		profiler.pop = noop
		profiler.popAll = noop
	end
end

profiler.enabled(false)
popAll()

profiler.zonestack = zoneStack
profiler.profdata = profData

_prof = profiler

return prof
