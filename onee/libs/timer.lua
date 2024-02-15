--- Timer utilities.
--
-- This is a reworked implementation of the original timer module
-- from the hump library (https://github.com/vrld/hump).
-- See README.ACKNOWLEDGEMENT for detailed information.
--
-- It offers functionality to schedule tasks for delayed or periodic
-- execution, as well as tweening.
--
-- @module gear.timer
-- @copyright 2010-2013 Matthias Richter
-- @copyright 2022 The DoubleFourteen Code Forge
-- @author Matthias Richter, Lorenzo Cogotti

local Timer = {}
Timer.__index = Timer

local function updateTimerHandle(handle)
	if dt == handle.prevdt then return end
	
    handle.time = handle.time + dt
    handle.during(dt, math.max(handle.limit - handle.time, 0))

    while handle.time >= handle.limit and handle.count > 0 do
        if handle.after(handle.after) == false then
            handle.count = 0
            break
        end
        handle.time = handle.time - handle.limit
        handle.count = handle.count - 1
    end
	
	handle.prevdt = dt
end

function Timer:update()
    -- timers may create new timers, which leads to undefined behavior
    -- in pairs() - so we need to put them in a different table first
    local to_update = {}
    for handle in pairs(self.functions) do
        to_update[handle] = handle
    end

    for handle in pairs(to_update) do
        if self.functions[handle] then
            updateTimerHandle(handle)
            if handle.count == 0 then
                self.functions[handle] = nil
            end
        end
    end
end

function Timer:during(delay, during, after)
    local handle = {
        time = 0,
        during = during,
        after = after or noop,
        limit = delay,
        count = 1,
		prevdt = 0,
    }

    self.functions[handle] = true
    return handle
end

function Timer:after(delay, func)
    return self:during(delay, noop, func)
end

function Timer:every(delay, after, count)
    local handle = {
        time = 0,
        during = noop,
        after = after,
        limit = delay,
        count = count or inf,
		prevdt = 0,
    }

    self.functions[handle] = true
    return handle
end

function Timer:cancel(handle)
	self.functions[handle] = nil
end

function Timer:clear()
    self.functions = {}
end

function Timer:script(f)
    local co = coroutine.wrap(f)
    co(function(t)
        self:after(t, co)
        coroutine.yield()
    end)
end

-- Timer instancing
timer = {}

function timer.new()
   return setmetatable({functions = {}}, Timer)
end

return timer
