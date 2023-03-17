package.preload["photon.common.class"] = function(...)
  local NO_SUPERCLASS = {}
  local U = {}
  local function initInternal(class, inst, ...)
    if class.superclass ~= NO_SUPERCLASS then
      initInternal(class.superclass, inst, ...)
    end
    setmetatable(inst, class.meta)
    class.init(inst, ...)
  end
  local function initInternal2(class, inst, ...)
    if class.superclass ~= NO_SUPERCLASS then
      initInternal2(class.superclass, inst, ...)
    end
    class.init2(inst, ...)
  end
  function U.declare(className)
    return U.declareInternal(className)
  end
  function U.declareInternal(className)
    className = className or "UnnamedClass"
    local meta = {
      __index = {}
    }
    local class = {
      meta = meta,
      proto = meta.__index,
      superclass = NO_SUPERCLASS,
      init = function()
      end,
      init2 = function()
      end
    }
    meta.class = class
    local classmeta = {
      class = {},
      __tostring = function()
        return className
      end
    }
    setmetatable(class, classmeta)
    function class.new(...)
      local inst = {}
      initInternal(class, inst, ...)
      initInternal2(class, inst, ...)
      return inst
    end
    function class.apply(inst)
      setmetatable(inst, meta)
    end
    function class.issameorextended(c)
      return class == c or c.superclass and c.superclass ~= NO_SUPERCLASS and class.issameorextended(c.superclass)
    end
    function class.isinstance(inst)
      local mt = getmetatable(inst)
      if mt and mt.class then
        return class.issameorextended(mt.class)
      end
      return false
    end
    return class
  end
  function U.extend(base, className)
    local class = U.declareInternal(className)
    class.superclass = base
    for k, v in pairs(base.meta) do
      if not class.meta[k] then
        class.meta[k] = v
      end
    end
    local classProto = class.proto
    local superIndex = base.meta.__index
    if type(superIndex) == "table" then
      function class.meta:__index(x)
        return classProto[x] or superIndex[x]
      end
    else
      function class.meta:__index(x)
        return classProto[x] or superIndex(self, x)
      end
    end
    return class
  end
  function U.classof(inst)
    local mt = getmetatable(inst)
    if mt then
      return mt.class
    else
      return nil
    end
  end
  return U
end
package.preload["photon.common.Logger"] = function(...)
  local class = require("photon.common.class")
  local Logger = class.declare("Logger")
  local instance = Logger.proto
  Logger.Level = {
    FATAL = 0,
    ERROR = 1,
    WARN = 2,
    INFO = 3,
    DEBUG = 4,
    TRACE = 5
  }
  local levelStr = {
    "FATAL",
    "ERROR",
    "WARN",
    "INFO",
    "DEBUG",
    "TRACE"
  }
  function Logger:init(prefix, level)
    self:setPrefix(prefix)
    self.logFunc = print
    local l = level or Logger.Level.INFO
    self:setLevel(l)
  end
  function instance:format(...)
    local arg = {
      ...
    }
    local str = {}
    for i = 1, #arg do
      table.insert(str, tostring(arg[i]))
    end
    return table.concat(str, " ")
  end
  function instance:log(level, ...)
    local arg = {
      ...
    }
    if level <= self.level and self.logFunc then
      local str = {}
      table.insert(str, os.date())
      table.insert(str, levelStr[level + 1])
      table.insert(str, tostring(self.prefix))
      for i = 1, #arg do
        table.insert(str, tostring(arg[i]))
      end
      self.logFunc(table.concat(str, " "))
    end
  end
  function instance:fatal(...)
    self:log(Logger.Level.FATAL, ...)
  end
  function instance:error(...)
    self:log(Logger.Level.ERROR, ...)
  end
  function instance:warn(...)
    self:log(Logger.Level.WARN, ...)
  end
  function instance:info(...)
    self:log(Logger.Level.INFO, ...)
  end
  function instance:debug(...)
    self:log(Logger.Level.DEBUG, ...)
  end
  function instance:trace(...)
    self:log(Logger.Level.TRACE, ...)
  end
  function instance:setLevel(level)
    assert(type(level) == "number" and level >= Logger.Level.FATAL and level <= Logger.Level.TRACE)
    self.level = level
  end
  function instance:isLevelEnabled(level)
    return level <= self.level
  end
  function instance:getLevel()
    return self.level
  end
  function instance:setPrefix(prefix)
    self.prefix = tostring(prefix or "") .. ":"
  end
  function instance:setLogFunction(func)
    assert(not func or type(func) == "function")
    self.logFunc = func
  end
  return Logger
end
package.preload["photon.common.type.Array"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Array")
  function C:init(...)
    local arg = {
      ...
    }
    for _, v in ipairs(arg) do
      table.insert(self, v)
    end
  end
  local toStrDone = {}
  local toStrDepth = 0
  function C.meta:__tostring()
    local done = toStrDone[self]
    if done then
      return " /" .. toStrDepth - done .. "\\ "
    else
      toStrDone[self] = toStrDepth
      toStrDepth = toStrDepth + 1
      local t = {}
      for _, v in ipairs(self) do
        table.insert(t, tostring(v))
      end
      toStrDone[self] = nil
      toStrDepth = toStrDepth - 1
      local et = self:getElementType()
      local elTypeStr = ""
      if et then
        elTypeStr = "(" .. tostring(et) .. ")"
      end
      return elTypeStr .. "[" .. table.concat(t, ",") .. "]"
    end
  end
  function C.proto:push(value)
    table.insert(self, value)
  end
  function C.proto:indexOf(value)
    for i, v in ipairs(self) do
      if v == value then
        return i
      end
    end
    return -1
  end
  local function typify(t)
    local className = "Array(" .. tostring(t) .. ")"
    C[t] = class.extend(C, className)
    C[t].meta.elementtype = t
    getmetatable(C[t]).__tostring = function()
      return className
    end
    return C[t]
  end
  function C.proto:getElementType()
    return getmetatable(self).elementtype
  end
  getmetatable(C).__index = function(self, x)
    return typify(x)
  end
  return C
end
package.preload["photon.common.type.Byte"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Byte")
  function C:init(value)
    if value < 0 or value > 255 then
      assert(false, "Byte value out of range:" .. value)
    end
    self.value = value
  end
  function C.meta:__tostring()
    return "Byte(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Double"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Double")
  function C:init(value)
    self.value = value
  end
  function C.meta:__tostring()
    return "Double(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Float"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Float")
  function C:init(value)
    self.value = value
  end
  function C.meta:__tostring()
    return "Float(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Integer"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Integer")
  function C:init(value)
    self.value = math.floor(value)
  end
  function C.meta:__tostring()
    return "Int(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Long"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Long")
  function C:init(value)
    self.value = math.floor(value)
  end
  function C.meta:__tostring()
    return "Long(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Short"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("Short")
  function C:init(value)
    self.value = math.floor(value)
  end
  function C.meta:__tostring()
    return "Short(" .. self.value .. ")"
  end
  return C
end
package.preload["photon.common.type.Null"] = function(...)
  local C = {}
  setmetatable(C, {
    __tostring = function()
      return "Null"
    end
  })
  return C
end
package.preload["photon.common.util.bit.numberlua"] = function(...)
  local M = {
    _TYPE = "module",
    _NAME = "bit.numberlua",
    _VERSION = "0.3.1.20120131"
  }
  local floor = math.floor
  local MOD = 4294967296
  local MODM = MOD - 1
  local memoize = function(f)
    local mt = {}
    local t = setmetatable({}, mt)
    function mt:__index(k)
      local v = f(k)
      t[k] = v
      return v
    end
    return t
  end
  local make_bitop_uncached = function(t, m)
    local function bitop(a, b)
      local res, p = 0, 1
      while a ~= 0 and b ~= 0 do
        local am, bm = a % m, b % m
        res = res + t[am][bm] * p
        a = (a - am) / m
        b = (b - bm) / m
        p = p * m
      end
      res = res + (a + b) * p
      return res
    end
    return bitop
  end
  local function make_bitop(t)
    local op1 = make_bitop_uncached(t, 2)
    local op2 = memoize(function(a)
      return memoize(function(b)
        return op1(a, b)
      end)
    end)
    return make_bitop_uncached(op2, 2 ^ (t.n or 1))
  end
  function M.tobit(x)
    return x % 4294967296
  end
  M.bxor = make_bitop({
    [0] = {
      [0] = 0,
      [1] = 1
    },
    [1] = {
      [0] = 1,
      [1] = 0
    },
    ["n"] = 4
  })
  local bxor = M.bxor
  function M.bnot(a)
    return MODM - a
  end
  local bnot = M.bnot
  function M.band(a, b)
    return (a + b - bxor(a, b)) / 2
  end
  local band = M.band
  function M.bor(a, b)
    return MODM - band(MODM - a, MODM - b)
  end
  local bor = M.bor
  local lshift, rshift
  function M.rshift(a, disp)
    if disp < 0 then
      return lshift(a, -disp)
    end
    return floor(a % 4294967296 / 2 ^ disp)
  end
  rshift = M.rshift
  function M.lshift(a, disp)
    if disp < 0 then
      return rshift(a, -disp)
    end
    return a * 2 ^ disp % 4294967296
  end
  lshift = M.lshift
  function M.tohex(x, n)
    n = n or 8
    local up
    if n <= 0 then
      if n == 0 then
        return ""
      end
      up = true
      n = -n
    end
    x = band(x, 16 ^ n - 1)
    return "%0" .. n .. (up and "X" or "x"):format(x)
  end
  local tohex = M.tohex
  function M.extract(n, field, width)
    width = width or 1
    return band(rshift(n, field), 2 ^ width - 1)
  end
  local extract = M.extract
  function M.replace(n, v, field, width)
    width = width or 1
    local mask1 = 2 ^ width - 1
    v = band(v, mask1)
    local mask = bnot(lshift(mask1, field))
    return band(n, mask) + lshift(v, field)
  end
  local replace = M.replace
  function M.bswap(x)
    local a = band(x, 255)
    x = rshift(x, 8)
    local b = band(x, 255)
    x = rshift(x, 8)
    local c = band(x, 255)
    x = rshift(x, 8)
    local d = band(x, 255)
    return lshift(lshift(lshift(a, 8) + b, 8) + c, 8) + d
  end
  local bswap = M.bswap
  function M.rrotate(x, disp)
    disp = disp % 32
    local low = band(x, 2 ^ disp - 1)
    return rshift(x, disp) + lshift(low, 32 - disp)
  end
  local rrotate = M.rrotate
  function M.lrotate(x, disp)
    return rrotate(x, -disp)
  end
  local lrotate = M.lrotate
  M.rol = M.lrotate
  M.ror = M.rrotate
  function M.arshift(x, disp)
    local z = rshift(x, disp)
    if x >= 2147483648 then
      z = z + lshift(2 ^ disp - 1, 32 - disp)
    end
    return z
  end
  local arshift = M.arshift
  function M.btest(x, y)
    return band(x, y) ~= 0
  end
  M.bit32 = {}
  local function bit32_bnot(x)
    return (-1 - x) % MOD
  end
  M.bit32.bnot = bit32_bnot
  local function bit32_bxor(a, b, c, ...)
    local z
    if b then
      a = a % MOD
      b = b % MOD
      z = bxor(a, b)
      if c then
        z = bit32_bxor(z, c, ...)
      end
      return z
    elseif a then
      return a % MOD
    else
      return 0
    end
  end
  M.bit32.bxor = bit32_bxor
  local function bit32_band(a, b, c, ...)
    local z
    if b then
      a = a % MOD
      b = b % MOD
      z = (a + b - bxor(a, b)) / 2
      if c then
        z = bit32_band(z, c, ...)
      end
      return z
    elseif a then
      return a % MOD
    else
      return MODM
    end
  end
  M.bit32.band = bit32_band
  local function bit32_bor(a, b, c, ...)
    local z
    if b then
      a = a % MOD
      b = b % MOD
      z = MODM - band(MODM - a, MODM - b)
      if c then
        z = bit32_bor(z, c, ...)
      end
      return z
    elseif a then
      return a % MOD
    else
      return 0
    end
  end
  M.bit32.bor = bit32_bor
  function M.bit32.btest(...)
    return bit32_band(...) ~= 0
  end
  function M.bit32.lrotate(x, disp)
    return lrotate(x % MOD, disp)
  end
  function M.bit32.rrotate(x, disp)
    return rrotate(x % MOD, disp)
  end
  function M.bit32.lshift(x, disp)
    if disp > 31 or disp < -31 then
      return 0
    end
    return lshift(x % MOD, disp)
  end
  function M.bit32.rshift(x, disp)
    if disp > 31 or disp < -31 then
      return 0
    end
    return rshift(x % MOD, disp)
  end
  function M.bit32.arshift(x, disp)
    x = x % MOD
    if disp >= 0 then
      if disp > 31 then
        return x >= 2147483648 and MODM or 0
      else
        local z = rshift(x, disp)
        if x >= 2147483648 then
          z = z + lshift(2 ^ disp - 1, 32 - disp)
        end
        return z
      end
    else
      return lshift(x, -disp)
    end
  end
  function M.bit32.extract(x, field, ...)
    local width = (...) or 1
    if field < 0 or field > 31 or width < 0 or field + width > 32 then
      error("out of range")
    end
    x = x % MOD
    return extract(x, field, ...)
  end
  function M.bit32.replace(x, v, field, ...)
    local width = (...) or 1
    if field < 0 or field > 31 or width < 0 or field + width > 32 then
      error("out of range")
    end
    x = x % MOD
    v = v % MOD
    return replace(x, v, field, ...)
  end
  M.bit = {}
  function M.bit.tobit(x)
    x = x % MOD
    if x >= 2147483648 then
      x = x - MOD
    end
    return x
  end
  local bit_tobit = M.bit.tobit
  function M.bit.tohex(x, ...)
    return tohex(x % MOD, ...)
  end
  function M.bit.bnot(x)
    return bit_tobit(bnot(x % MOD))
  end
  local function bit_bor(a, b, c, ...)
    if c then
      return bit_bor(bit_bor(a, b), c, ...)
    elseif b then
      return bit_tobit(bor(a % MOD, b % MOD))
    else
      return bit_tobit(a)
    end
  end
  M.bit.bor = bit_bor
  local function bit_band(a, b, c, ...)
    if c then
      return bit_band(bit_band(a, b), c, ...)
    elseif b then
      return bit_tobit(band(a % MOD, b % MOD))
    else
      return bit_tobit(a)
    end
  end
  M.bit.band = bit_band
  local function bit_bxor(a, b, c, ...)
    if c then
      return bit_bxor(bit_bxor(a, b), c, ...)
    elseif b then
      return bit_tobit(bxor(a % MOD, b % MOD))
    else
      return bit_tobit(a)
    end
  end
  M.bit.bxor = bit_bxor
  function M.bit.lshift(x, n)
    return bit_tobit(lshift(x % MOD, n % 32))
  end
  function M.bit.rshift(x, n)
    return bit_tobit(rshift(x % MOD, n % 32))
  end
  function M.bit.arshift(x, n)
    return bit_tobit(arshift(x % MOD, n % 32))
  end
  function M.bit.rol(x, n)
    return bit_tobit(lrotate(x % MOD, n % 32))
  end
  function M.bit.ror(x, n)
    return bit_tobit(rrotate(x % MOD, n % 32))
  end
  function M.bit.bswap(x)
    return bit_tobit(bswap(x % MOD))
  end
  return M
end
package.preload["photon.common.util.byteutil"] = function(...)
  local M = {}
  function M.get_byte(num, i)
    return math.floor(num / 256 ^ i) % 256
  end
  function M.int_to_byte_array_be(num, arr, startIndex)
    if startIndex == nil then
      startIndex = 1
    end
    for i = 0, 3 do
      arr[startIndex + i] = M.get_byte(num, 3 - i)
    end
  end
  function M.array_to_int_be(arr, startIndex)
    if startIndex == nil then
      startIndex = 1
    end
    local res = 0
    for i = startIndex, startIndex + 3 do
      res = res * 256 + arr[i]
    end
    return res
  end
  function M.array_to_short_be(arr, startIndex)
    if startIndex == nil then
      startIndex = 1
    end
    return 256 * arr[startIndex] + arr[startIndex + 1]
  end
  return M
end
package.preload["photon.common.util.tableutil"] = function(...)
  local class = require("photon.common.class")
  local M = {}
  local function typeExt(x)
    return tostring(class.classof(x) or type(x))
  end
  function M.toString(tbl, wTypes)
    if type(wTypes) ~= "number" then
      wTypes = wTypes and 2 or 0
    end
    local wKeyTypes = wTypes > 1
    local s = ""
    if type(tbl) == "table" then
      if wTypes > 0 then
        s = s .. "(" .. typeExt(tbl) .. "): "
      end
      for k, v in pairs(tbl) do
        if wTypes > 0 then
          s = s .. (wKeyTypes and "(" .. typeExt(k) .. ")" or "") .. tostring(k) .. " = " .. "(" .. typeExt(v) .. ")" .. tostring(v) .. " "
        else
          s = s .. tostring(k) .. "=" .. tostring(v) .. " "
        end
      end
    elseif wTypes > 0 then
      return "" .. (wKeyTypes and "(" .. typeExt(tbl) .. ")" or "") .. tostring(tbl) .. "\n"
    else
      return "" .. tostring(tbl) .. "\n"
    end
    return s
  end
  local toStrDone = {}
  local toStrDepth = 0
  function M.toStringReq(tbl, wTypes)
    if type(wTypes) ~= "number" then
      wTypes = wTypes and 2 or 0
    end
    local wKeyTypes = wTypes > 1
    if type(tbl) == "table" then
      local done = toStrDone[tbl]
      if done then
        return " /" .. toStrDepth - done .. "\\ \n"
      else
        toStrDone[tbl] = toStrDepth
        toStrDepth = toStrDepth + 1
        local s = ""
        if wTypes > 0 then
          s = s .. "(" .. typeExt(tbl) .. ")"
        end
        s = s .. "\n"
        for k, v in pairs(tbl) do
          if wTypes > 0 then
            s = s .. string.rep("  ", toStrDepth) .. (wKeyTypes and "(" .. typeExt(k) .. ")" or "") .. tostring(k) .. "=" .. M.toStringReq(v, wTypes)
          else
            s = s .. string.rep("  ", toStrDepth) .. tostring(k) .. "=" .. M.toStringReq(v, wTypes)
          end
        end
        toStrDone[tbl] = nil
        toStrDepth = toStrDepth - 1
        return s
      end
    elseif wTypes > 0 then
      return "" .. "(" .. typeExt(tbl) .. ")" .. tostring(tbl) .. "\n"
    else
      return "" .. tostring(tbl) .. "\n"
    end
  end
  function M.bytesToString(bytes)
    local s = {}
    for i = 1, #bytes do
      table.insert(s, string.char(bytes[i]))
    end
    return table.concat(s)
  end
  function M.stringToBytes(buf)
    local s = {}
    for i = 1, #buf do
      table.insert(s, buf:byte(i))
    end
    return s
  end
  function M.addTable(t1, t2, start, length)
    local startFrom = 1
    local count = #t2
    if start and start > 0 then
      startFrom = start
    end
    if length and length > 0 then
      count = start + length - 1
    end
    for i = startFrom, count do
      table.insert(t1, t2[i])
    end
  end
  function M.removeFromHead(tbl, count)
    for i = 1, count do
      table.remove(tbl, 1)
    end
  end
  function M.dumpTable(tbl)
    local t = {}
    for i = 1, #tbl do
      table.insert(t, string.format("%.2X", tbl[i]))
    end
    return table.concat(t, " ")
  end
  function M.getn(tbl)
    local count = 0
    for k, v in pairs(tbl) do
      count = count + 1
    end
    return count
  end
  function M.nonEmpty(tbl)
    local count = 0
    for k, v in pairs(tbl) do
      return true
    end
    return false
  end
  function M.getKeyByValue(enum, value)
    for k, v in pairs(enum) do
      if v == value then
        return k
      end
    end
    return nil
  end
  local Byte = require("photon.common.type.Byte")
  local Short = require("photon.common.type.Short")
  local Integer = require("photon.common.type.Integer")
  local Long = require("photon.common.type.Long")
  local Float = require("photon.common.type.Float")
  local Double = require("photon.common.type.Double")
  function M.deepCopy(x)
    if type(x) == "table" then
      local t = {}
      for k, v in pairs(x) do
        t[k] = M.deepCopy(v)
      end
      local c = class.classof(x)
      if c then
        c.apply(t)
      end
      return t
    else
      return x
    end
  end
  function M.deepCopyUntyped(x)
    local c = class.classof(x)
    if c == Byte or c == Short or c == Integer or c == Long or c == Float or c == Double then
      return x.value
    elseif type(x) == "table" then
      local t = {}
      for k, v in pairs(x) do
        t[k] = M.deepCopyUntyped(v)
      end
      return t
    else
      return x
    end
  end
  return M
end
package.preload["photon.common.util.time"] = function(...)
  local socket = require("socket")
  local initTime = socket.gettime()
  local function timeFromStart()
    return socket.gettime() - initTime
  end
  local function timeFromStartMs()
    return math.floor((socket.gettime() - initTime) * 1000)
  end
  return {
    now = socket.gettime,
    timeFromStart = timeFromStart,
    timeFromStartMs = timeFromStartMs
  }
end
package.preload["photon.core.EventData"] = function(...)
  local class = require("photon.common.class")
  local EventData = class.declare("EventData")
  function EventData:init(code, params)
    assert(type(code) == "number" and type(params) == "table", "Unsupported param types")
    local instance = self
    instance.code = code
    instance.parameters = params
  end
  function EventData.proto:getParameterForCode(parameterCode)
    return self.parameters[parameterCode]
  end
  return EventData
end
package.preload["photon.core.GpOperationReader"] = function(...)
  local CoreConstants = require("photon.core.constants")
  local logger = require("photon.common.Logger").new("GpOperationReader")
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local Null = require("photon.common.type.Null")
  local deserializeTable, deserializeTypeTable
  local class = require("photon.common.class")
  local C = class.declare("GpOperationReader")
  function C:init(data)
    assert(type(data) == "table")
    self.mpData = data
    self.mDataOffset = 0
  end
  function C.proto:deserialize()
    return self:deserializeType(self:deserializeByte())
  end
  function C.proto:deserializeType(dataType)
    local desMeth = deserializeTable[dataType]
    if desMeth then
      return desMeth(self)
    else
      logger:error("deserialize() failed due to unsupported data type.", dataType)
      return nil
    end
  end
  function C.proto:deserializeInteger()
    local res = 0
    for i = 0, 3 do
      res = res * 256 + self:deserializeByte()
    end
    return res
  end
  function C.proto:deserializeLong()
    local res = 0
    for i = 0, 7 do
      res = res * 256 + self:deserializeByte()
    end
    return res
  end
  function C.proto:deserializeFloat()
    local x = {}
    for i = 1, 4 do
      x[5 - i] = self:deserializeByte()
    end
    local sign = 1
    local mantissa = x[3] % 128
    for i = 2, 1, -1 do
      mantissa = mantissa * 256 + x[i]
    end
    if x[4] > 127 then
      sign = -1
    end
    local exponent = x[4] % 128 * 2 + math.floor(x[3] / 128)
    local res = 0
    if exponent ~= 0 then
      mantissa = (math.ldexp(mantissa, -23) + 1) * sign
      res = math.ldexp(mantissa, exponent - 127)
    end
    return res
  end
  function C.proto:deserializeDouble()
    local x = {}
    for i = 1, 8 do
      x[9 - i] = self:deserializeByte()
    end
    local sign = 1
    local mantissa = x[7] % 16
    for i = 6, 1, -1 do
      mantissa = mantissa * 256 + x[i]
    end
    if x[8] > 127 then
      sign = -1
    end
    local exponent = x[8] % 128 * 16 + math.floor(x[7] / 16)
    local res = 0
    if exponent ~= 0 then
      mantissa = (math.ldexp(mantissa, -52) + 1) * sign
      res = math.ldexp(mantissa, exponent - 1023)
    end
    return res
  end
  function C.proto:deserializeString()
    local size = self:deserializeShort()
    local temp = {}
    for i = 1, size do
      table.insert(temp, string.char(self:deserializeByte()))
    end
    return table.concat(temp)
  end
  function C.proto:deserializeBoolean()
    local b = self:deserializeByte()
    if b == 0 then
      return false
    else
      return true
    end
  end
  function C.proto:deserializeShort()
    return 256 * self:deserializeByte() + self:deserializeByte()
  end
  function C.proto:deserializeByte()
    self.mDataOffset = self.mDataOffset + 1
    return self.mpData[self.mDataOffset]
  end
  function C.proto:deserializeObjectArray()
    local array = Array.new()
    local size = self:deserializeShort()
    for i = 1, size do
      local dataType = self:deserializeByte()
      local desMeth = deserializeTable[dataType]
      if desMeth then
        array[i] = desMeth(self)
      else
        logger:error("deserializeObjectArray() failed due to unsupported data type.", dataType)
      end
    end
    return array
  end
  function C.proto:deserializeArray()
    local array
    local size = self:deserializeShort()
    local dataType = self:deserializeByte()
    local arrayType = deserializeTypeTable[dataType]
    if arrayType then
      array = Array[arrayType].new()
    else
      array = Array.new()
    end
    local desMeth = deserializeTable[dataType]
    if desMeth then
      for i = 1, size do
        array[i] = desMeth(self)
      end
    else
      logger:error("deserializeArray() failed due to unsupported data type.", array)
    end
    return array
  end
  function C.proto:deserializeByteArray()
    local array = Array[Byte].new()
    local size = self:deserializeInteger()
    for i = 1, size do
      array[i] = self:deserializeByte()
    end
    return array
  end
  function C.proto:deserializeHashTable()
    local hashtable = {}
    local size = self:deserializeShort()
    for i = 1, size do
      local k = self:deserialize()
      local v = self:deserialize()
      if k then
        hashtable[k] = v
      end
    end
    return hashtable
  end
  function C.proto:deserializeDictionary()
    local dict = {}
    local keyType = self:deserializeByte()
    local valType = self:deserializeByte()
    local size = self:deserializeShort()
    local readKeyType = keyType == 0 or keyType == string.byte("*")
    local readValType = valType == 0 or valType == string.byte("*")
    for i = 1, size do
      local k, v
      if readKeyType then
        k = self:deserialize()
      else
        k = self:deserializeType(keyType)
      end
      if readValType then
        v = self:deserialize()
      else
        v = self:deserializeType(valType)
      end
      dict[k] = v
    end
    return dict
  end
  function C.proto:getDataOffset()
    return self.mDataOffset
  end
  deserializeTable = {
    [CoreConstants.TypeCode.BYTE] = C.proto.deserializeByte,
    [CoreConstants.TypeCode.SHORT] = C.proto.deserializeShort,
    [CoreConstants.TypeCode.INTEGER] = C.proto.deserializeInteger,
    [CoreConstants.TypeCode.LONG] = C.proto.deserializeLong,
    [CoreConstants.TypeCode.FLOAT] = C.proto.deserializeFloat,
    [CoreConstants.TypeCode.DOUBLE] = C.proto.deserializeDouble,
    [CoreConstants.TypeCode.BOOLEAN] = C.proto.deserializeBoolean,
    [CoreConstants.TypeCode.STRING] = C.proto.deserializeString,
    [CoreConstants.TypeCode.HASHTABLE] = C.proto.deserializeHashTable,
    [CoreConstants.TypeCode.DICTIONARY] = C.proto.deserializeDictionary,
    [CoreConstants.TypeCode.OBJECT] = C.proto.deserializeObjectArray,
    [CoreConstants.TypeCode.ARRAY] = C.proto.deserializeArray,
    [CoreConstants.TypeCode.INTERNAL_BYTEARRAY] = C.proto.deserializeByteArray,
    [CoreConstants.TypeCode.EG_NULL] = function()
      return Null
    end
  }
  deserializeTypeTable = {
    [CoreConstants.TypeCode.BYTE] = require("photon.common.type.Byte"),
    [CoreConstants.TypeCode.SHORT] = require("photon.common.type.Short"),
    [CoreConstants.TypeCode.INTEGER] = require("photon.common.type.Integer"),
    [CoreConstants.TypeCode.LONG] = require("photon.common.type.Long"),
    [CoreConstants.TypeCode.FLOAT] = require("photon.common.type.Float"),
    [CoreConstants.TypeCode.DOUBLE] = require("photon.common.type.Double"),
    [CoreConstants.TypeCode.BOOLEAN] = "boolean",
    [CoreConstants.TypeCode.STRING] = "string"
  }
  return C
end
package.preload["photon.core.GpOperationWriter"] = function(...)
  local byteutil = require("photon.common.util.byteutil")
  local tableutil = require("photon.common.util.tableutil")
  local CoreConstants = require("photon.core.constants")
  local logger = require("photon.common.Logger").new("GpOperationWriter")
  local class = require("photon.common.class")
  local C = class.declare("GpOperationWriter")
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local Short = require("photon.common.type.Short")
  local Integer = require("photon.common.type.Integer")
  local Long = require("photon.common.type.Long")
  local Float = require("photon.common.type.Float")
  local Double = require("photon.common.type.Double")
  local Null = require("photon.common.type.Null")
  local serializeTable, serializeTypeTable
  local function _P(x)
    print(tableutil.toString(x))
  end
  function C:init()
    self.mpData = {}
  end
  function C.proto:writeByte(byte)
    assert(type(byte) == "number", "Value must be number")
    table.insert(self.mpData, byte)
  end
  function C.proto:writeShort(num)
    self:writeByte(byteutil.get_byte(num, 1))
    self:writeByte(byteutil.get_byte(num, 0))
  end
  function C.proto:serializeByte(num, setType)
    if type(num) ~= "number" then
      assert(Byte.isinstance(num), "Value must be number or Byte")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.BYTE)
    end
    self:writeByte(num)
  end
  function C.proto:serializeShort(num, setType)
    if type(num) ~= "number" then
      assert(Short.isinstance(num), "Value must be number or Short")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.SHORT)
    end
    self:writeShort(num)
  end
  function C.proto:serializeInteger(num, setType)
    if type(num) ~= "number" then
      assert(Integer.isinstance(num), "Value must be number or Integer")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.INTEGER)
    end
    for i = 3, 0, -1 do
      self:writeByte(byteutil.get_byte(num, i))
    end
  end
  function C.proto:serializeLong(num, setType)
    if type(num) ~= "number" then
      assert(Long.isinstance(num), "Value must be number or Long")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.LONG)
    end
    for i = 7, 0, -1 do
      self:writeByte(byteutil.get_byte(num, i))
    end
  end
  function C.proto:writeFloat(x)
    local grab_byte = function(v)
      return math.floor(v / 256), math.floor(v) % 256
    end
    local sign = 0
    if x < 0 then
      sign = 1
      x = -x
    end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then
      mantissa = 0
      exponent = 0
    else
      mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 24)
      exponent = exponent + 126
    end
    local v = {}
    local byte
    x, byte = grab_byte(mantissa)
    table.insert(v, byte)
    x, byte = grab_byte(x)
    table.insert(v, byte)
    x, byte = grab_byte(exponent * 128 + x)
    table.insert(v, byte)
    x, byte = grab_byte(sign * 128 + x)
    table.insert(v, byte)
    for i = 4, 1, -1 do
      self:writeByte(v[i])
    end
  end
  function C.proto:writeDouble(x)
    local grab_byte = function(v)
      return math.floor(v / 256), math.floor(v) % 256
    end
    local sign = 0
    if x < 0 then
      sign = 1
      x = -x
    end
    local mantissa, exponent = math.frexp(x)
    if x == 0 then
      mantissa, exponent = 0, 0
    else
      mantissa = (mantissa * 2 - 1) * math.ldexp(0.5, 53)
      exponent = exponent + 1022
    end
    local v = {}
    local byte
    x = mantissa
    for i = 1, 6 do
      x, byte = grab_byte(x)
      table.insert(v, byte)
    end
    x, byte = grab_byte(exponent * 16 + x)
    table.insert(v, byte)
    x, byte = grab_byte(sign * 128 + x)
    table.insert(v, byte)
    for i = 8, 1, -1 do
      self:writeByte(v[i])
    end
  end
  function C.proto:serializeFloat(num, setType)
    if type(num) ~= "number" then
      assert(Float.isinstance(num), "Value must be number or Float")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.FLOAT)
    end
    self:writeFloat(num)
  end
  function C.proto:serializeDouble(num, setType)
    if type(num) ~= "number" then
      assert(Double.isinstance(num), "Value must be number or Double")
      num = num.value
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.DOUBLE)
    end
    self:writeDouble(num)
  end
  function C.proto:serializeNumber(num, setType)
    assert(type(num) == "number", "Value must be number")
    if setType then
      self:writeByte(CoreConstants.TypeCode.DOUBLE)
    end
    self:writeDouble(num)
  end
  function C.proto:serializeBoolean(val, setType)
    assert(type(val) == "boolean", "Value must be boolean")
    if setType then
      self:writeByte(CoreConstants.TypeCode.BOOLEAN)
    end
    if val then
      self:writeByte(1)
    else
      self:writeByte(0)
    end
  end
  function C.proto:serializeString(str, setType)
    assert(type(str) == "string", "Value must be string")
    if setType then
      self:writeByte(CoreConstants.TypeCode.STRING)
    end
    self:writeShort(#str)
    for i = 1, #str do
      self:writeByte(str:byte(i))
    end
  end
  function C.proto:serializeHashTable(hash, setType)
    assert(type(hash) == "table", "Value must be table")
    if setType then
      self:writeByte(CoreConstants.TypeCode.HASHTABLE)
    end
    local size = tableutil.getn(hash)
    self:writeShort(size)
    for k, v in pairs(hash) do
      if not self:serialize(k, true, false) then
        return false
      end
      if not self:serialize(v, true, false) then
        return false
      end
    end
    return true
  end
  function C.proto:serializeObjectArray(array, setType)
    if class.classof(array) ~= Array then
      assert(false, "Untyped array required: " .. tostring(array))
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.OBJECT)
    end
    local size = #array
    self:writeShort(size)
    for i = 1, size do
      local v = array[i]
      local tp = class.classof(v) or type(v)
      local serMeth
      if tp == Array then
        serMeth = C.proto.serializeObjectArray
      elseif Array.isinstance(v) then
        serMeth = C.proto.serializeArray
      else
        serMeth = serializeTable[tp]
      end
      if serMeth then
        if serMeth(self, v, true) == false then
          return false
        end
      else
        assert(false, "Serialize array object type not supported: " .. tostring(tp))
      end
    end
  end
  function C.proto:serializeArray(array, setType)
    if not Array.isinstance(array) or class.classof(array) == Array then
      assert(false, "Typed array required: " .. tostring(array))
    end
    if setType then
      self:writeByte(CoreConstants.TypeCode.ARRAY)
    end
    local size = #array
    self:writeShort(size)
    local tp = array:getElementType()
    local serMeth = serializeTable[tp]
    local arrType = serializeTypeTable[tp]
    if not serMeth or not arrType then
      assert(false, "Serialize array type not supported " .. tostring(tp) .. " (" .. tostring(array) .. ")")
    end
    self:writeByte(arrType)
    for i = 1, #array do
      if serMeth(self, array[i]) == false then
        return false
      end
    end
    return true
  end
  function C.proto:serialize(serObject, setType)
    if serObject == nil or serObject == Null then
      self:writeByte(CoreConstants.TypeCode.EG_NULL)
      return true
    end
    local serMeth
    local tp = class.classof(serObject) or type(serObject)
    if class.classof(serObject) == Array then
      serMeth = C.proto.serializeObjectArray
    elseif Array.isinstance(serObject) then
      serMeth = C.proto.serializeArray
    else
      serMeth = serializeTable[tp]
    end
    if serMeth then
      if serMeth(self, serObject, setType) == false then
        return false
      end
      return true
    else
      logger:error("serialize() failed due to unsupported data type:", tp)
      return false
    end
  end
  function C.proto:getDataOffset()
    return #self.mpData
  end
  function C.proto:getData()
    return self.mpData
  end
  serializeTable = {
    ["number"] = C.proto.serializeNumber,
    ["boolean"] = C.proto.serializeBoolean,
    ["string"] = C.proto.serializeString,
    ["table"] = C.proto.serializeHashTable,
    [Byte] = C.proto.serializeByte,
    [Short] = C.proto.serializeShort,
    [Integer] = C.proto.serializeInteger,
    [Long] = C.proto.serializeLong,
    [Float] = C.proto.serializeFloat,
    [Double] = C.proto.serializeDouble
  }
  serializeTypeTable = {
    ["number"] = CoreConstants.TypeCode.DOUBLE,
    ["boolean"] = CoreConstants.TypeCode.BOOLEAN,
    ["string"] = CoreConstants.TypeCode.STRING,
    ["table"] = CoreConstants.TypeCode.HASHTABLE,
    [Array] = CoreConstants.TypeCode.ARRAY,
    [Byte] = CoreConstants.TypeCode.BYTE,
    [Short] = CoreConstants.TypeCode.SHORT,
    [Integer] = CoreConstants.TypeCode.INTEGER,
    [Long] = CoreConstants.TypeCode.LONG,
    [Float] = CoreConstants.TypeCode.FLOAT,
    [Double] = CoreConstants.TypeCode.DOUBLE,
    [Null] = CoreConstants.TypeCode.EG_NULL
  }
  return C
end
package.preload["photon.core.OperationRequest"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("OperationRequest")
  function C:init(operationCode, parameters)
    if parameters == nil then
      parameters = {}
    end
    assert(type(operationCode) == "number" and type(parameters) == "table", "Unsupported param types")
    self.operationCode = operationCode
    self.parameters = parameters
  end
  function C.proto:setParameters(parameters)
    assert(type(parameters) == "table", "Unsupported param types")
    self.parameters = parameters
  end
  return C
end
package.preload["photon.core.OperationResponse"] = function(...)
  local tableutil = require("photon.common.util.tableutil")
  local class = require("photon.common.class")
  local OperationResponse = class.declare("OperationResponse")
  function OperationResponse:init(operationCode, errCode)
    assert(type(operationCode) == "number" and type(errCode) == "number", "Unsupported param types")
    local instance = self
    instance.operationCode = operationCode
    instance.parameters = nil
    instance.parameters = {}
    instance.errCode = errCode
    instance.errMsg = ""
  end
  function OperationResponse.proto:toString(withParameterTypes)
    local dbgMsg = "(" .. self.errMsg .. ")"
    return "OperationResponse - operationCode: " .. self.operationCode .. ", returnCode: " .. self.errCode .. " " .. dbgMsg .. tableutil.toString(self.parameters, withParameterTypes)
  end
  function OperationResponse.proto:getParameterForCode(parameterCode)
    return self.parameters[parameterCode]
  end
  function OperationResponse.proto:setDebugMessage(msg)
    assert(type(msg) == "string")
    self.errMsg = msg
  end
  function OperationResponse.proto:addParameter(parameterCode, parameter)
    self.parameters[parameterCode] = parameter
  end
  return OperationResponse
end
package.preload["photon.core.PhotonPeer"] = function(...)
  local Array = require("photon.common.type.Array")
  local EnetPeer = require("photon.core.internal.EnetPeer")
  local CoreConstants = require("photon.core.constants")
  local Logger = require("photon.common.Logger")
  local class = require("photon.common.class")
  local PhotonPeer = class.extend(EnetPeer, "PhotonPeer")
  local instance = PhotonPeer.proto
  PhotonPeer.StatusCodes = {
    Connecting = 1,
    Connect = 2,
    Disconnect = 3,
    EncryptionEstablished = 4,
    Error = 1001,
    ConnectFailed = 1002,
    ConnectClosed = 1003,
    Timeout = 1004,
    EncryptionEstablishError = 1005
  }
  local CoreStatusCodeConvert = {
    [CoreConstants.StatusCode.EXCEPTION_ON_CONNECT] = PhotonPeer.StatusCodes.ConnectFailed,
    [CoreConstants.StatusCode.CONNECT] = PhotonPeer.StatusCodes.Connect,
    [CoreConstants.StatusCode.DISCONNECT] = PhotonPeer.StatusCodes.Disconnect,
    [CoreConstants.StatusCode.EXCEPTION] = PhotonPeer.StatusCodes.Error,
    [CoreConstants.StatusCode.SEND_ERROR] = PhotonPeer.StatusCodes.Error,
    [CoreConstants.StatusCode.INTERNAL_RECEIVE_EXCEPTION] = PhotonPeer.StatusCodes.Error,
    [CoreConstants.StatusCode.TIMEOUT_DISCONNECT] = PhotonPeer.StatusCodes.Timeout,
    [CoreConstants.StatusCode.DISCONNECT_BY_SERVER] = PhotonPeer.StatusCodes.ConnectClosed,
    [CoreConstants.StatusCode.DISCONNECT_BY_SERVER_USER_LIMIT] = PhotonPeer.StatusCodes.ConnectClosed,
    [CoreConstants.StatusCode.DISCONNECT_BY_SERVER_LOGIC] = PhotonPeer.StatusCodes.ConnectClosed,
    [CoreConstants.StatusCode.ENCRYPTION_ESTABLISHED] = PhotonPeer.StatusCodes.EncryptionEstablished,
    [CoreConstants.StatusCode.ENCRYPTION_FAILED_TO_ESTABLISH] = PhotonPeer.StatusCodes.EncryptionEstablishError
  }
  function PhotonPeer:init()
    self.logger:setPrefix("PhotonPeer")
    self._peerStatusListeners = {}
    self._eventListeners = {}
    self._responseListeners = {}
    self.mListener = {
      onOperationResponse = function(listener, ...)
        instance._onOperationResponse(self, ...)
      end,
      onStatusChanged = function(listener, ...)
        instance._onStatusChanged(self, ...)
      end,
      onEvent = function(listener, ...)
        instance._onEvent(self, ...)
      end
    }
    self.logger:trace("create")
    self.trafficStatsIncoming = nil
    self.trafficStatsOutgoing = nil
    self.trafficStatsGameLevel = nil
  end
  function instance:getResentReliableCommands()
    return self.packetsLost
  end
  function instance:_addListener(listeners, code, callback)
    if listeners[code] == nil then
      listeners[code] = Array.new()
    end
    if type(callback) == "function" then
      self.logger:debug("PhotonPeer[_addListener] - Adding listener for event", code)
      listeners[code]:push(callback)
    else
      self.logger:error("PhotonPeer[_addListener] - Listener", code, "is not a function but of type", type(callback), ". No listener added!")
    end
    return self
  end
  function instance:_dispatch(listeners, code, args)
    if listeners[code] then
      local events = listeners[code]
      for _, listener in ipairs(events) do
        listener(args or Array.new())
      end
      return true
    else
      return false
    end
  end
  function instance:_onStatusChanged(coreStatusCode)
    local statusCode = CoreStatusCodeConvert[coreStatusCode]
    if statusCode and not self:_dispatch(self._peerStatusListeners, statusCode, statusCode, "peerStatus") then
      self.logger:warn("PhotonPeer[_dispatchPeerStatus] - No handler for ", statusCode, "registered.")
    end
  end
  function instance:_onOperationResponse(operationResponse)
    if not self:_dispatch(self._responseListeners, operationResponse.operationCode, operationResponse, "response") then
      self:onUnhandledResponse(operationResponse)
    end
  end
  function instance:_onEvent(eventData)
    if not self:_dispatch(self._eventListeners, eventData.code, eventData, "event") then
      self:onUnhandledEvent(eventData)
    end
  end
  function instance:addPeerStatusListener(statusCode, callback)
    self:_addListener(self._peerStatusListeners, statusCode, callback)
  end
  function instance:addPhotonEventListener(eventCode, callback)
    self:_addListener(self._eventListeners, eventCode, callback)
  end
  function instance:addResponseListener(operationCode, callback)
    self:_addListener(self._responseListeners, operationCode, callback)
  end
  function instance:_dummy_sendOperation_()
  end
  function instance:setLogLevel(level)
    self.logger:setLevel(level)
  end
  function instance:onUnhandledEvent(eventData)
    self.logger:warn("PhotonPeer: No handler for event", eventData.code, "registered.")
  end
  function instance:onUnhandledResponse(operationResponse)
    self.logger:warn("PhotonPeer: No handler for response", operationResponse.operationCode, "registered.")
  end
  function instance:_dummy_service_()
  end
  function instance:_dummy_serviceBasic_()
  end
  function instance:_dummy_dispatchIncomingCommands_()
  end
  function instance:_dummy4_sendOutgoingCommands_()
  end
  function instance:_dummy_getRoundTripTime_()
  end
  function instance:_dummy_getRoundTripTimeVariance_()
  end
  function instance:_dummy_setTrafficStatsEnabled(enabled)
  end
  function instance:_dummy_getTrafficStatsEnabled()
  end
  function instance:_dummy_getTrafficStatsEnabledTime()
  end
  function instance:_dummy_resetTrafficStats()
  end
  function instance:_dummy_resetTrafficStatsMaximumCounters()
  end
  return PhotonPeer
end
package.preload["photon.core.constants"] = function(...)
  local M = {}
  M.MessageType = {
    MSGT_INIT = 0,
    MSGT_INIT_RES = 1,
    MSGT_OP = 2,
    MSGT_OP_RES = 3,
    MSGT_EV = 4,
    MSGT_INT_OP = 6,
    MSGT_INT_OP_RES = 7
  }
  M.StatusCode = {
    EXCEPTION_ON_CONNECT = 1023,
    CONNECT = 1024,
    DISCONNECT = 1025,
    EXCEPTION = 1026,
    QUEUE_OUTGOING_RELIABLE_WARNING = 1027,
    QUEUE_OUTGOING_UNRELIABLE_WARNING = 1029,
    SEND_ERROR = 1030,
    QUEUE_OUTGOING_ACKS_WARNING = 1031,
    QUEUE_INCOMING_RELIABLE_WARNING = 1033,
    QUEUE_INCOMING_UNRELIABLE_WARNING = 1035,
    QUEUE_SENT_WARNING = 1037,
    INTERNAL_RECEIVE_EXCEPTION = 1039,
    TIMEOUT_DISCONNECT = 1040,
    DISCONNECT_BY_SERVER = 1041,
    DISCONNECT_BY_SERVER_USER_LIMIT = 1042,
    DISCONNECT_BY_SERVER_LOGIC = 1043,
    ENCRYPTION_ESTABLISHED = 1048,
    ENCRYPTION_FAILED_TO_ESTABLISH = 1049
  }
  M.TypeCode = {
    BYTE = string.byte("b"),
    SHORT = string.byte("k"),
    INTEGER = string.byte("i"),
    LONG = string.byte("l"),
    FLOAT = string.byte("f"),
    DOUBLE = string.byte("d"),
    BOOLEAN = string.byte("o"),
    STRING = string.byte("s"),
    HASHTABLE = string.byte("h"),
    DICTIONARY = string.byte("D"),
    OBJECT = string.byte("z"),
    ARRAY = string.byte("y"),
    INTERNAL_BYTEARRAY = string.byte("x"),
    GPOPERATION = string.byte("g"),
    PHOTON_COMMAND = string.byte("p"),
    EG_NULL = string.byte("*"),
    CUSTOM = string.byte("c"),
    UNKNOWN = 0
  }
  M.ErrorCode = {
    SUCCESS = 0,
    EFAILED = 1,
    ENOMEMORY = 2,
    EBADCLASS = 10,
    EBADPARM = 14,
    EITEMBUSY = 32,
    NET_SUCCESS = 0,
    NET_ERROR = -1,
    NET_ENETNONET = 534,
    NET_MSGSIZE = 539,
    NET_ENOTCONN = 540
  }
  return M
end
package.preload["photon.core.TrafficStats"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("TrafficStats")
  local instance = C.proto
  function C:init(packageHeaderSize)
    local instance = self
    self.packageHeaderSize = packageHeaderSize
  end
  function instance:inc(name, x)
    local s = self[name]
    if s == nil then
      self[name] = x or 1
    else
      self[name] = s + (x or 1)
    end
  end
  function instance:count(name, bytes)
    self:inc(name .. "Count")
    self:inc(name .. "Bytes", bytes)
  end
  return C
end
package.preload["photon.core.TrafficStatsGameLevel"] = function(...)
  local PhotonTime = require("photon.common.util.time")
  local class = require("photon.common.class")
  local TrafficStats = require("photon.core.TrafficStats")
  local C = class.extend(TrafficStats, "TrafficStatsGameLevel")
  local instance = C.proto
  function C:init()
    local instance = self
    self.dispatchIncomingCommandsCalls = 0
    self.sendOutgoingCommandsCalls = 0
    self:resetMaximumCounters()
  end
  function instance:timeForResponseCallback(code, t)
    if t > self.longestOpResponseCallback then
      self.longestOpResponseCallback = t
      self.longestOpResponseCallbackOpCode = code
    end
  end
  function instance:timeForEventCallback(code, t)
    if t > self.longestEventCallback then
      self.longestEventCallback = t
      self.longestEventCallbackCode = code
    end
  end
  function instance:dispatchIncomingCommandsCalled()
    if self.timeOfLastDispatchCall then
      local delta = PhotonTime.now() - self.timeOfLastDispatchCall
      if delta > self.longestDeltaBetweenDispatching then
        self.longestDeltaBetweenDispatching = delta
      end
    end
    self.dispatchIncomingCommandsCalls = self.dispatchIncomingCommandsCalls + 1
    self.timeOfLastDispatchCall = PhotonTime.now()
  end
  function instance:sendOutgoingCommandsCalled()
    if self.timeOfLastSendCall then
      local delta = PhotonTime.now() - self.timeOfLastSendCall
      if delta > self.longestDeltaBetweenSending then
        self.longestDeltaBetweenSending = delta
      end
    end
    self.sendOutgoingCommandsCalls = self.sendOutgoingCommandsCalls + 1
    self.timeOfLastSendCall = PhotonTime.now()
  end
  function instance:resetMaximumCounters()
    self.longestDeltaBetweenDispatching = 0
    self.longestDeltaBetweenSending = 0
    self.longestEventCallback = 0
    self.longestEventCallbackCode = 0
    self.longestOpResponseCallback = 0
    self.longestOpResponseCallbackOpCode = 0
    self.timeOfLastDispatchCall = nil
    self.timeOfLastSendCall = nil
  end
  return C
end
package.preload["photon.core.internal.EnetChannel"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("EnetChannel")
  function C:init(channelNumber)
    assert(type(channelNumber) == "number", "channelNumber is not number")
    self.channelNumber = channelNumber
    self.incomingReliableSequenceNumber = 0
    self.incomingUnreliableSequenceNumber = 0
    self.outgoingReliableSequenceNumber = 0
    self.outgoingUnreliableSequenceNumber = 0
    self.incomingReliableCommands = {}
    self.incomingUnreliableCommands = {}
    self.outgoingReliableCommands = {}
    self.outgoingUnreliableCommands = {}
  end
  function C.proto:getReliableCommandFromQueue(reliableSequenceNumber)
    for i = 1, #self.incomingReliableCommands do
      local pCommand = self.incomingReliableCommands[i]
      if pCommand.mReliableSequenceNumber == reliableSequenceNumber then
        return pCommand
      end
    end
    return nil
  end
  function C.proto:getUnreliableCommandFromQueue(unreliableSequenceNumber)
    for i = 1, #self.incomingUnreliableCommands do
      local pCommand = self.incomingUnreliableCommands[i]
      if pCommand.mUnreliableSequenceNumber == unreliableSequenceNumber then
        return pCommand
      end
    end
    return nil
  end
  function C.proto:removeReliableCommandFromQueue(reliableSequenceNumber)
    for i = 1, #self.incomingReliableCommands do
      local pCommand = self.incomingReliableCommands[i]
      if pCommand.mReliableSequenceNumber == reliableSequenceNumber then
        table.remove(self.incomingReliableCommands, i)
        return true
      end
    end
    return false
  end
  function C.proto:removeUnreliableCommandFromQueue(unreliableSequenceNumber)
    for i = 1, #self.incomingUnreliableCommands do
      local pCommand = self.incomingUnreliableCommands[i]
      if pCommand.mUnreliableSequenceNumber == unreliableSequenceNumber then
        table.remove(self.incomingUnreliableCommands, i)
        return true
      end
    end
    return false
  end
  return C
end
package.preload["photon.core.internal.EnetCommand"] = function(...)
  local InternalConstants = require("photon.core.internal.constants")
  local tableutil = require("photon.common.util.tableutil")
  local byteutil = require("photon.common.util.byteutil")
  local logger = require("photon.common.Logger").new("EnetCommand")
  local class = require("photon.common.class")
  local C = class.declare("EnetCommand")
  function C:init(...)
    local arg = {
      ...
    }
    if type(arg[2]) == "table" then
      self:initWithBuffer(...)
    elseif type(arg[2]) == "number" then
      self:initWithType(...)
    elseif type(arg[2]) == "nil" then
      self:initWithCommand(...)
    else
      error("unknown constructor")
    end
  end
  function C.proto:init(listener)
    self.mListener = listener
    self.mCommandFlags = 0
    self.mCommandType = 0
    self.mCommandChannelID = 0
    self.mStartSequenceNumber = 0
    self.mFragmentCount = 0
    self.mFragmentNumber = 0
    self.mTotalLength = 0
    self.mFragmentOffset = 0
    self.mFragmentsRemaining = 0
    self.mReliableSequenceNumber = 0
    self.mUnreliableSequenceNumber = 0
    self.mUnsequencedGroupNumber = 0
    self.mReservedByte = 4
    self.mCommandPayload = {}
    self.mCommandSentTime = 0
    self.mCommandOriginalSentTime = 0
    self.mCommandSentCount = 0
    self.mAckReceivedReliableSequenceNumber = 0
    self.mAckReceivedSentTime = 0
    self.mRoundTripTimeout = 0
  end
  function C.proto:initWithType(listener, cType, payload)
    assert(type(cType) == "number")
    assert(payload == nil or type(payload) == "table")
    if payload then
      logger:trace("create EnetCommand type:", cType, "payload length:", #payload)
    end
    self:init(listener)
    self.mCommandType = cType
    self.mCommandFlags = InternalConstants.CommandProperties.FV_RELIABLE
    self.mCommandChannelID = 255
    if payload and #payload > 0 and cType ~= InternalConstants.CommandProperties.CT_CONNECT then
      self.mCommandPayload = {}
      tableutil.addTable(self.mCommandPayload, payload)
    end
    local sw = {
      [InternalConstants.CommandProperties.CT_CONNECT] = function()
        logger:trace("CT_CONNECT")
        self.mCommandPayload = {}
        self.mCommandPayload[1] = 0
        self.mCommandPayload[2] = 0
        self.mCommandPayload[3] = byteutil.get_byte(InternalConstants.InternalProperties.EG_OPT_MTU_SIZE, 1)
        self.mCommandPayload[4] = byteutil.get_byte(InternalConstants.InternalProperties.EG_OPT_MTU_SIZE, 0)
        self.mCommandPayload[5] = 0
        self.mCommandPayload[6] = 0
        self.mCommandPayload[7] = 128
        self.mCommandPayload[8] = 0
        self.mCommandPayload[9] = 0
        self.mCommandPayload[10] = 0
        self.mCommandPayload[11] = 0
        self.mCommandPayload[12] = 0
        if listener then
          self.mCommandPayload[12] = listener:getChannelCountUserChannels()
        end
        self.mCommandPayload[13] = 0
        self.mCommandPayload[14] = 0
        self.mCommandPayload[15] = 0
        self.mCommandPayload[16] = 0
        self.mCommandPayload[17] = 0
        self.mCommandPayload[18] = 0
        self.mCommandPayload[19] = 0
        self.mCommandPayload[20] = 0
        self.mCommandPayload[21] = 0
        self.mCommandPayload[22] = 0
        self.mCommandPayload[23] = 2
        self.mCommandPayload[24] = 2
        self.mCommandPayload[25] = 0
        self.mCommandPayload[26] = 0
        self.mCommandPayload[27] = 0
        self.mCommandPayload[28] = 136
        self.mCommandPayload[29] = 0
        self.mCommandPayload[30] = 0
        self.mCommandPayload[31] = 0
        self.mCommandPayload[32] = 19
      end,
      [InternalConstants.CommandProperties.CT_DISCONNECT] = function()
        logger:trace("CT_DISCONNECT")
        if listener and listener:getConnectionState() ~= InternalConstants.ConnectionState.CONNECTED then
          self.mCommandFlags = InternalConstants.CommandProperties.FLAG_UNSEQUENCED
          if listener:getConnectionState() == InternalConstants.ConnectionState.ZOMBIE then
            self.mReservedByte = 2
          end
        end
      end,
      [InternalConstants.CommandProperties.CT_SENDRELIABLE] = function()
        logger:trace("CT_SENDRELIABLE")
        self.mCommandChannelID = 0
      end,
      [InternalConstants.CommandProperties.CT_SENDUNRELIABLE] = function()
        logger:trace("CT_SENDUNRELIABLE")
        self.mCommandFlags = InternalConstants.CommandProperties.FV_UNRELIABLE
        self.mCommandChannelID = 0
      end,
      [InternalConstants.CommandProperties.CT_SENDFRAGMENT] = function()
        logger:trace("CT_SENDFRAGMENT")
        self.mCommandChannelID = 0
      end,
      [InternalConstants.CommandProperties.CT_ACK] = function()
        logger:trace("CT_ACK")
        self.mCommandFlags = InternalConstants.CommandProperties.FV_UNRELIABLE
      end
    }
    local foo = sw[cType]
    if foo then
      foo()
    end
  end
  function C.proto:createAck()
    local payLoad = {}
    local sentTime = self.mCommandSentTime
    byteutil.int_to_byte_array_be(self.mReliableSequenceNumber, payLoad, 1)
    byteutil.int_to_byte_array_be(sentTime, payLoad, 5)
    local retVal = C.new(self.mListener, InternalConstants.CommandProperties.CT_ACK, payLoad)
    retVal.mCommandChannelID = self.mCommandChannelID
    return retVal
  end
  function C.proto:commandLength()
    local plen = #self.mCommandPayload
    local hlen = InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_LENGTH
    if self.mCommandType == InternalConstants.CommandProperties.CT_SENDUNRELIABLE then
      hlen = hlen + 4
    end
    if self.mCommandType == InternalConstants.CommandProperties.CT_SENDFRAGMENT then
      hlen = InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_FRAGMENT_LENGTH
    end
    return hlen + plen
  end
  function C.proto:serialize(buffer)
    if not buffer then
      return
    end
    assert(type(buffer) == "table")
    assert(#buffer == 0)
    logger:trace("serialize command with type:", self.mCommandType, "payload length:", #self.mCommandPayload)
    local bufferlen = self:commandLength()
    buffer[1] = self.mCommandType
    buffer[2] = self.mCommandChannelID
    buffer[3] = self.mCommandFlags
    buffer[4] = self.mReservedByte
    byteutil.int_to_byte_array_be(bufferlen, buffer, 5)
    byteutil.int_to_byte_array_be(self.mReliableSequenceNumber, buffer, 9)
    if self.mCommandType == InternalConstants.CommandProperties.CT_SENDUNRELIABLE then
      byteutil.int_to_byte_array_be(self.mUnreliableSequenceNumber, buffer, 13)
    elseif self.mCommandType == InternalConstants.CommandProperties.CT_SENDFRAGMENT then
      byteutil.int_to_byte_array_be(self.mStartSequenceNumber, buffer, 13)
      byteutil.int_to_byte_array_be(self.mFragmentCount, buffer, 17)
      byteutil.int_to_byte_array_be(self.mFragmentNumber, buffer, 21)
      byteutil.int_to_byte_array_be(self.mTotalLength, buffer, 25)
      byteutil.int_to_byte_array_be(self.mFragmentOffset, buffer, 29)
    end
    for i = 1, #self.mCommandPayload do
      table.insert(buffer, self.mCommandPayload[i])
    end
  end
  function C.proto:initWithBuffer(listener, pBuffer, nRead, sentTime)
    assert(type(pBuffer) == "table")
    assert(type(nRead) == "table")
    assert(type(sentTime) == "number")
    self:init(listener)
    if not pBuffer then
      nRead[0] = 0
      return
    end
    local pCur = pBuffer
    local commandLength = 0
    local commandPayloadLen = 0
    local readedBytes = 0
    self.mCommandType = pCur[1]
    self.mCommandChannelID = pCur[2]
    self.mCommandFlags = pCur[3]
    self.mReservedByte = pCur[4]
    commandLength = byteutil.array_to_int_be(pCur, 5)
    self.mReliableSequenceNumber = byteutil.array_to_int_be(pCur, 9)
    readedBytes = 12
    self.mCommandSentTime = sentTime
    self.mCommandPayload = {}
    local sw = {
      [InternalConstants.CommandProperties.CT_ACK] = function()
        logger:trace("CT_ACK")
        self.mAckReceivedReliableSequenceNumber = byteutil.array_to_int_be(pCur, 13)
        self.mAckReceivedSentTime = byteutil.array_to_int_be(pCur, 17)
        readedBytes = 20
      end,
      [InternalConstants.CommandProperties.CT_PING] = function()
        logger:trace("CT_PING")
      end,
      [InternalConstants.CommandProperties.CT_SENDRELIABLE] = function()
        logger:trace("CT_SENDRELIABLE")
        commandPayloadLen = commandLength - InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_LENGTH
      end,
      [InternalConstants.CommandProperties.CT_SENDUNRELIABLE] = function()
        logger:trace("CT_SENDUNRELIABLE")
        self.mUnreliableSequenceNumber = byteutil.array_to_int_be(pCur, 13)
        readedBytes = 16
        commandPayloadLen = commandLength - InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_LENGTH - 4
      end,
      [InternalConstants.CommandProperties.CT_VERIFYCONNECT] = function()
        logger:trace("CT_VERIFYCONNECT")
        local outgoingPeerID = 0
        outgoingPeerID = byteutil.array_to_short_be(pCur, 13)
        readedBytes = 44
        if self.mListener:getPeerID() == -1 then
          self.mListener:setPeerID(outgoingPeerID)
        end
      end,
      [InternalConstants.CommandProperties.CT_SENDFRAGMENT] = function()
        logger:trace("CT_SENDFRAGMENT")
        self.mStartSequenceNumber = byteutil.array_to_int_be(pCur, 13)
        self.mFragmentCount = byteutil.array_to_int_be(pCur, 17)
        self.mFragmentNumber = byteutil.array_to_int_be(pCur, 21)
        self.mTotalLength = byteutil.array_to_int_be(pCur, 25)
        self.mFragmentOffset = byteutil.array_to_int_be(pCur, 29)
        commandPayloadLen = commandLength - InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_FRAGMENT_LENGTH
        self.mFragmentsRemaining = self.mFragmentCount
        readedBytes = 32
      end
    }
    local foo = sw[self.mCommandType]
    if foo then
      foo()
    end
    if commandPayloadLen > 0 then
      for i = readedBytes + 1, readedBytes + commandPayloadLen do
        table.insert(self.mCommandPayload, pCur[i])
      end
      readedBytes = readedBytes + commandPayloadLen
    end
    nRead[1] = readedBytes
  end
  function C.proto:initWithCommand(toCopy)
    assert(C.isinstance(toCopy))
    self:init()
    self.mAckReceivedReliableSequenceNumber = toCopy.mAckReceivedReliableSequenceNumber
    self.mAckReceivedSentTime = toCopy.mAckReceivedSentTime
    self.mCommandChannelID = toCopy.mCommandChannelID
    self.mCommandFlags = toCopy.mCommandFlags
    self.mCommandType = toCopy.mCommandType
    self.mFragmentCount = toCopy.mFragmentCount
    self.mFragmentNumber = toCopy.mFragmentNumber
    self.mFragmentOffset = toCopy.mFragmentOffset
    self.mStartSequenceNumber = toCopy.mStartSequenceNumber
    self.mFragmentsRemaining = toCopy.mFragmentsRemaining
    self.mReliableSequenceNumber = toCopy.mReliableSequenceNumber
    self.mUnreliableSequenceNumber = toCopy.mUnreliableSequenceNumber
    self.mUnsequencedGroupNumber = toCopy.mUnsequencedGroupNumber
    self.mReservedByte = toCopy.mReservedByte
    self.mCommandSentTime = toCopy.mCommandSentTime
    self.mCommandOriginalSentTime = toCopy.mCommandOriginalSentTime
    self.mCommandSentCount = toCopy.mCommandSentCount
    self.mRoundTripTimeout = toCopy.mRoundTripTimeout
    self.mTotalLength = toCopy.mTotalLength
    if #toCopy.mCommandPayload > 0 then
      for i = 1, #toCopy.mCommandPayload do
        self.mCommandPayload[i] = toCopy.mCommandPayload[i]
      end
    end
  end
  return C
end
package.preload["photon.core.internal.EnetCommandListener"] = function(...)
  local class = require("photon.common.class")
  local C = class.declare("EnetCommandListener")
  function C.proto:getChannelCountUserChannels()
    error("not implemented")
  end
  function C.proto:getConnectionState()
    error("not implemented")
  end
  function C.proto:getPeerID()
    error("not implemented")
  end
  function C.proto:setPeerID(newPeerId)
    error("not implemented")
  end
  return C
end
package.preload["photon.core.internal.EnetConnect"] = function(...)
  local socket = require("socket")
  local class = require("photon.common.class")
  local C = class.extend(require("photon.core.internal.PhotonConnect"), "EnetConnect")
  function C.proto:checkConnection()
    return true
  end
  function C.proto:socket()
    return socket.udp()
  end
  function C.proto:defaultPort()
    return 5055
  end
  return C
end
package.preload["photon.core.internal.EnetPeer"] = function(...)
  local bit = require("photon.common.util.bit.numberlua").bit
  local bit32 = require("photon.common.util.bit.numberlua").bit32
  local PeerBase = require("photon.core.internal.PeerBase")
  local EnetConnect = require("photon.core.internal.EnetConnect")
  local PhotonHeader = require("photon.core.internal.PhotonHeader")
  local EnetCommand = require("photon.core.internal.EnetCommand")
  local EnetChannel = require("photon.core.internal.EnetChannel")
  local CoreConstants = require("photon.core.constants")
  local InternalConstants = require("photon.core.internal.constants")
  local tableutil = require("photon.common.util.tableutil")
  local byteutil = require("photon.common.util.byteutil")
  local PhotonTime = require("photon.common.util.time")
  local Logger = require("photon.common.Logger")
  local class = require("photon.common.class")
  local C = class.extend(PeerBase, "EnetPeer")
  function C:init(listener)
    self.logger:setPrefix("EnetPeer")
    self.windowSize = InternalConstants.PeerProperties.WINDOW_SIZE
    self.unsequencedWindow = {}
    self.channels = {}
    self.outgoingUnsequencedGroupNumber = 0
    self.incomingUnsequencedGroupNumber = 0
    self.commandCount = 0
    self.buffer = {}
    self.bufferLen = 0
    self.commandSize = 0
    self.rt = EnetConnect.new(self)
    self.sentReliableCommands = {}
    self.outgoingAcknowledgements = {}
  end
  function C.proto:getPackageHeaderSize()
    return InternalConstants.PeerProperties.UDP_PACKAGE_HEADER_LENGTH
  end
  function C.proto:cleanupNonHierarchical()
    self.buffer = {}
    self.channels = {}
    self.sentReliableCommands = {}
    self.outgoingAcknowledgements = {}
  end
  function C.proto:cleanup()
    self:cleanupNonHierarchical()
    PeerBase.proto.cleanup(self)
  end
  function C.proto:reset()
    PeerBase.proto.reset(self)
    self.channels = {}
    for i = 1, self.channelCountUserChannels + 1 do
      table.insert(self.channels, EnetChannel.new(i))
    end
    self.buffer = {}
  end
  function C.proto:connect(ipAddr, appID)
    self.logger:debug("connect", ipAddr, appID)
    return PeerBase.proto.connect(self, ipAddr, appID)
  end
  function C.proto:startConnection(ipAddr)
    self.logger:debug("startConnection to", ipAddr)
    return self.rt:startConnection(ipAddr)
  end
  function C.proto:disconnect()
    if self.connectionState ~= InternalConstants.ConnectionState.DISCONNECTED then
      self:clearAllQueues()
      local cmd = EnetCommand.new(self, InternalConstants.CommandProperties.CT_DISCONNECT)
      if self.trafficStatsEnabled then
        self.trafficStatsOutgoing:count("controlCommand", cmd:commandLength())
      end
      if self.connectionState == InternalConstants.ConnectionState.CONNECTED then
        self:queueOutgoingReliableCommand(cmd)
      else
        self:queueOutgoingUnreliableCommand(cmd)
      end
      self:sendOutgoingCommands()
    end
    if self.connectionState == InternalConstants.ConnectionState.CONNECTED then
      self.connectionState = InternalConstants.ConnectionState.DISCONNECTING
    else
      self:stopConnection()
      self.shouldScheduleDisconnectCB = true
    end
  end
  function C.proto:stopConnection()
    PeerBase.proto.stopConnection(self)
  end
  function C.proto:sendOutgoingCommands()
    if self.trafficStatsEnabled then
      self.trafficStatsGameLevel:sendOutgoingCommandsCalled()
    end
    if self.connectionState == InternalConstants.ConnectionState.DISCONNECTED then
      return
    end
    if self.isSendingCommand then
      return
    end
    self.buffer = {}
    self.bufferLen = InternalConstants.PeerProperties.UDP_PACKAGE_HEADER_LENGTH
    if self.crcEnabled then
      self.bufferLen = self.bufferLen + InternalConstants.PeerProperties.CRC_LENGTH
    end
    for i = 1, self.bufferLen do
      self.buffer[i] = 0
    end
    self.commandCount = 0
    self.timeInt = PhotonTime:timeFromStartMs()
    if 0 < #self.outgoingAcknowledgements then
      self:serializeToBuffer(self.outgoingAcknowledgements)
    end
    for i = 1, #self.sentReliableCommands do
      local pCommand = self.sentReliableCommands[i]
      if self.timeInt - pCommand.mCommandOriginalSentTime > self.sentTimeAllowance then
        self.logger:error("> disconnect due to retry timeout (max retry time) time:", self.timeInt, ", originalSentTime:", pCommand.mCommandOriginalSentTime)
        self.connectionState = InternalConstants.ConnectionState.ZOMBIE
        self.mListener:onStatusChanged(CoreConstants.StatusCode.TIMEOUT_DISCONNECT)
        self:disconnect()
        return
      end
    end
    if self.timeInt > self.timeoutInt and 0 < #self.sentReliableCommands then
      for i = 1, #self.sentReliableCommands do
        local pCommand = self.sentReliableCommands[i]
        if self.timeInt - pCommand.mCommandSentTime > pCommand.mRoundTripTimeout then
          if pCommand.mCommandSentCount > self.sentCountAllowance then
            self.logger:error(">reliable: disconnect due to retry timeout:", pCommand.mCommandSentCount, "/", self.sentCountAllowance, "pCommand:", pCommand.mReliableSequenceNumber)
            self.connectionState = InternalConstants.ConnectionState.ZOMBIE
            self.mListener:onStatusChanged(CoreConstants.StatusCode.TIMEOUT_DISCONNECT)
            self:disconnect()
            return
          end
          self.packetsLost = self.packetsLost + 1
          self.logger:debug(">reliable: resending pCommand:", pCommand.mReliableSequenceNumber, ", time:", self.timeInt, ". sent time:", pCommand.mCommandSentTime, "timeout:", self.timeoutInt, ", sentCount:", pCommand.mCommandSentCount, ", original sent time:", pCommand.mCommandOriginalSentTime, "round trip:", pCommand.mRoundTripTimeout)
          local cmd = {}
          self:removeSentReliableCommand(pCommand.mReliableSequenceNumber, pCommand.mCommandChannelID, cmd)
          if #cmd > 0 then
            pCommand = cmd[1]
          end
          if pCommand then
            self:queueOutgoingReliableCommand(pCommand)
          end
          break
        end
      end
    end
    local tmpChannelId = self.channelCountUserChannels + 1
    local channel
    repeat
      channel = self.channels[tmpChannelId]
      if 0 < #channel.outgoingReliableCommands then
        self:serializeToBuffer(channel.outgoingReliableCommands)
        self.logger:trace(">reliable: written/used bytes:", self.bufferLen)
      end
      if 0 < #channel.outgoingUnreliableCommands then
        self:serializeToBuffer(channel.outgoingUnreliableCommands)
        self.logger:trace(">unreliable: written/used bytes:", self.bufferLen)
      end
      if tmpChannelId == self.channelCountUserChannels + 1 then
        tmpChannelId = 1
      else
        tmpChannelId = tmpChannelId + 1
      end
    until tmpChannelId >= self.channelCountUserChannels + 1
    if self.connectionState == InternalConstants.ConnectionState.CONNECTED and #self.sentReliableCommands == 0 and 0 < self.timePingInterval and self.timeInt - self.timeLastReceive > self.timePingInterval and self.bufferLen + self.commandSize < InternalConstants.InternalProperties.EG_OPT_MTU_SIZE then
      self.logger:trace("adding PING")
      local cmd = EnetCommand.new(self, InternalConstants.CommandProperties.CT_PING)
      self:queueOutgoingReliableCommand(cmd)
      if self.trafficStatsEnabled then
        self.trafficStatsOutgoing:count("controlCommand", cmd:commandLength())
      end
    end
    if self.trafficStatsEnabled then
      self.trafficStatsOutgoing:inc("totalPacketCount")
      self.trafficStatsOutgoing:inc("totalCommandsInPackets", self.commandCount)
    end
    self:sendDataInternal()
  end
  function C.proto:sendDataInternal()
    if self.commandCount > 0 then
      self.logger:trace(">HEADER: peerID", self.peerID, "cmdCount", self.commandCount, "sentTime", self.timeInt, "challenge", self.challenge)
      local pPH = PhotonHeader.new()
      pPH.peerID = self.peerID
      pPH.flags = self.crcEnabled and 204 or 0
      pPH.commandCount = self.commandCount
      pPH.sentTime = self.timeInt
      pPH.challenge = self.challenge
      pPH:setInTable(self.buffer)
      if self.crcEnabled then
        pPH.crc = self:calculateCrc(self.buffer)
        pPH:setCrcInTable(self.buffer)
      end
      if self.debugUseShortcut then
        self:onReceiveDataCallback(self.buffer, 0)
        return
      end
      self.logger:trace(">BUFFER:", table.concat(self.buffer, ","))
      self.logger:trace(">LENGTH:", #self.buffer)
      self.isSendingCommand = true
      self.rt:sendPackage(tableutil.bytesToString(self.buffer))
    end
  end
  function C.proto:dispatchIncomingCommands()
    local pCommand
    local ret = false
    self.logger:trace("<dispatchIncomingCommands")
    if self.trafficStatsEnabled then
      self.trafficStatsGameLevel:dispatchIncomingCommandsCalled()
    end
    if #self.channels > 0 then
      for channelIndex = 1, self.channelCountUserChannels + 1 do
        local pChannel = self.channels[channelIndex]
        if pChannel and 0 < #pChannel.incomingUnreliableCommands then
          pCommand = pChannel.incomingUnreliableCommands[1]
          if pCommand and 0 < pCommand.mUnreliableSequenceNumber then
            if pCommand.mReliableSequenceNumber > pChannel.incomingReliableSequenceNumber then
              self.logger:debug("<unreliable: not yet needed (reliable sequence must catch up)", pCommand.mReliableSequenceNumber, pChannel.incomingReliableSequenceNumber)
              pCommand = nil
            else
              pChannel.incomingUnreliableSequenceNumber = pCommand.mUnreliableSequenceNumber
              self.byteCountCurrentDispatch = pCommand:commandLength()
              if pCommand.mCommandPayload then
                ret = self:deserializeOperation(pCommand.mCommandPayload)
              end
              if 0 < #pChannel.incomingUnreliableCommands then
                table.remove(pChannel.incomingUnreliableCommands, 1)
              end
              self.logger:trace("<unreliable: dispatchIncomingCommands returns", ret)
              return ret
            end
          end
        end
        if not pCommand and pChannel and 0 < #pChannel.incomingReliableCommands then
          repeat
            pCommand = pChannel.incomingReliableCommands[1]
            if pCommand.mReliableSequenceNumber > pChannel.incomingReliableSequenceNumber + 1 then
              self.logger:debug("<reliable: postpone not next", pCommand.mReliableSequenceNumber, pChannel.incomingReliableSequenceNumber + 1)
              return false
            end
            if pCommand.mReliableSequenceNumber <= pChannel.incomingReliableSequenceNumber then
              table.remove(pChannel.incomingReliableCommands, 1)
              self.logger:debug("<reliable: skipping duplicate", pCommand.mReliableSequenceNumber, pChannel.incomingReliableSequenceNumber)
              pCommand = nil
            end
          until pCommand or #pChannel.incomingReliableCommands == 0
          if not pCommand then
            self.logger:trace("<reliable: dispatchIncomingCommands returns", false)
            return false
          end
          if pCommand.mCommandType ~= InternalConstants.CommandProperties.CT_SENDFRAGMENT then
            pChannel.incomingReliableSequenceNumber = pCommand.mReliableSequenceNumber
            self.byteCountCurrentDispatch = pCommand:commandLength()
            if 0 < #pCommand.mCommandPayload then
              ret = self:deserializeOperation(pCommand.mCommandPayload)
            end
            if 0 < #pChannel.incomingReliableCommands then
              table.remove(pChannel.incomingReliableCommands, 1)
            end
            return ret
          elseif 0 < pCommand.mFragmentsRemaining then
            pCommand = nil
          else
            local completePayload = {}
            local fragmentSequenceNumber = pCommand.mStartSequenceNumber
            local finalFragmentNumber = pCommand.mStartSequenceNumber + pCommand.mFragmentCount - 1
            self.logger:debug("<fragmented: starting to assemble", fragmentSequenceNumber, finalFragmentNumber)
            while fragmentSequenceNumber <= finalFragmentNumber do
              local fragment = pChannel:getReliableCommandFromQueue(fragmentSequenceNumber)
              if fragment then
                tableutil.addTable(completePayload, fragment.mCommandPayload)
                if fragmentSequenceNumber ~= pCommand.mStartSequenceNumber then
                  pChannel:removeReliableCommandFromQueue(fragmentSequenceNumber)
                end
              else
                self.logger:error("<fragmented: not all fragments are found", fragmentSequenceNumber)
                return false
              end
              fragmentSequenceNumber = fragmentSequenceNumber + 1
            end
            self.logger:debug("<fragmented: assembled", pCommand.mStartSequenceNumber, finalFragmentNumber)
            pCommand.mCommandPayload = completePayload
            pCommand.mCommandPayloadLen = pCommand.mTotalLength
            pChannel.incomingReliableSequenceNumber = finalFragmentNumber
            self.byteCountCurrentDispatch = pCommand:commandLength()
            local ret = self:deserializeOperation(pCommand.mCommandPayload)
            if 0 < #pChannel.incomingReliableCommands then
              table.remove(pChannel.incomingReliableCommands, 1)
            end
            return ret
          end
        end
      end
    end
    return false
  end
  function C.proto:fetchServerTimestamp()
    if self.connectionState == InternalConstants.ConnectionState.DISCONNECTED or self.connectionState == InternalConstants.ConnectionState.DISCONNECTING then
      self.logger:warn("called in a disconnected state. Photon can't fetch the servertime while disconnected and will ignore this call. Please repeat it, when you are connected.")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.SEND_ERROR)
    else
      self:send(InternalConstants.CommandProperties.CT_EG_SERVERTIME, {}, self.channelCountUserChannels)
    end
  end
  function C.proto:onConnectCallback(nError)
    self.logger:trace("onConnectCallback error =", nError)
    if nError ~= 0 then
      self.mListener:onStatusChanged(CoreConstants.StatusCode.EXCEPTION_ON_CONNECT)
    else
      local cmd = EnetCommand.new(self, InternalConstants.CommandProperties.CT_CONNECT)
      self:queueOutgoingReliableCommand(cmd)
      if self.trafficStatsEnabled then
        self.trafficStatsOutgoing:count("controlCommand", cmd:commandLength())
      end
      self.connectionState = InternalConstants.ConnectionState.CONNECTING
    end
  end
  function C.proto:onReceiveDataCallback(pBuf, nError)
    local i = 0
    local iOffset = {0}
    local peerID = 0
    local flags = 0
    local commandCount = 0
    local sentTime = 0
    local inChallenge = 0
    local incomingCommands = {}
    local pCur = {}
    local countInBuf = 0
    if pBuf then
      pCur = tableutil.stringToBytes(pBuf)
      countInBuf = #pBuf
    end
    self.logger:trace("length =", countInBuf, ", error =", nError)
    if nError ~= 0 then
      self.mListener:onStatusChanged(CoreConstants.StatusCode.INTERNAL_RECEIVE_EXCEPTION)
    end
    self.timestampOfLastReceive = PhotonTime.now()
    if countInBuf == 0 or not pBuf then
      return
    end
    peerID = byteutil.array_to_short_be(pCur, 1)
    flags = pCur[3]
    commandCount = pCur[4]
    sentTime = byteutil.array_to_int_be(pCur, 5)
    inChallenge = byteutil.array_to_int_be(pCur, 9)
    if flags == 204 then
      local crc = byteutil.array_to_int_be(pCur, 13)
      byteutil.int_to_byte_array_be(0, pCur, 13)
      local crcCalc = self:calculateCrc(pCur, countInBuf)
      if crc ~= crcCalc then
        self.packetLossByCrc = self.packetLossByCrc + 1
        self.logger:error("Ignored package due to wrong CRC. Incoming: " .. crc .. " Local: " .. crcCalc)
        return
      end
      tableutil.removeFromHead(pCur, 16)
    else
      tableutil.removeFromHead(pCur, 12)
    end
    self.logger:trace("peerID =", peerID, " flags =", flags, " commandCount =", commandCount, " sentTime =", sentTime, " challenge =", inChallenge)
    if self.trafficStatsEnabled then
      self.trafficStatsIncoming:inc("totalPacketCount")
      self.trafficStatsIncoming:inc("totalCommandsInPackets", self.commandCount)
    end
    self.timeInt = PhotonTime:timeFromStartMs()
    self.serverSentTime = sentTime
    if inChallenge ~= self.challenge then
      self.logger:error("rejected incoming. challenge does not fit:", self.challenge)
      return
    end
    if commandCount > 1 then
      self.logger:trace("+++ commandCount:", commandCount)
    end
    for i = 1, commandCount do
      tableutil.removeFromHead(pCur, iOffset[1])
      table.insert(incomingCommands, EnetCommand.new(self, pCur, iOffset, sentTime))
    end
    local pCommand
    for _, pCommand in pairs(incomingCommands) do
      if pCommand then
        self:execute(pCommand)
        if 0 < bit.band(pCommand.mCommandFlags, InternalConstants.CommandProperties.FLAG_RELIABLE) then
          local ackForCommand = pCommand:createAck()
          self:queueOutgoingAcknowledgement(ackForCommand)
          if self.trafficStatsEnabled then
            self.trafficStatsIncoming.timestampOfLastReliableCommand = PhotonTime.now()
            self.trafficStatsOutgoing:count("controlCommand", ackForCommand:commandLength())
          end
        end
      end
    end
  end
  function C.proto:getIncomingReliableCommandsCount()
    local returnValue = 0
    if #self.channels == 0 then
      return -1
    end
    for i = 1, self.channelCountUserChannels do
      if self.channels[i] then
        returnValue = returnValue + #self.channels[i].incomingReliableCommands
      end
    end
    return returnValue
  end
  function C.proto:getQueuedIncomingCommands()
    local temp = 0
    if #self.channels == 0 then
      return -1
    end
    for i = 1, self.channelCountUserChannels do
      if self.channels[i] then
        temp = temp + #self.channels[i].incomingReliableCommands + #self.channels[i].incomingUnreliableCommands
      end
    end
    return temp
  end
  function C.proto:getQueuedOutgoingCommands()
    local temp = 0
    if #self.channels == 0 then
      return -1
    end
    for i = 1, self.channelCountUserChannels do
      if self.channels[i] then
        temp = temp + #self.channels[i].outgoingReliableCommands + #self.channels[i].outgoingUnreliableCommands
      end
    end
    return temp
  end
  function C.proto:send(cType, payload, channelId)
    self.byteCountLastOperation = 0
    if payload then
      self.logger:trace("> send cType:", cType, " payloadSize:", #payload)
    else
      self.logger:trace("> send cType:", cType, " payloadSize: nil")
    end
    if self:sendInFragments(payload, channelId) then
      return
    end
    local pCommand = EnetCommand.new(self, cType, payload)
    pCommand.mCommandChannelID = channelId
    self.byteCountLastOperation = pCommand:commandLength()
    if pCommand.mCommandFlags == InternalConstants.CommandProperties.FV_RELIABLE then
      self:queueOutgoingReliableCommand(pCommand)
      if self.trafficStatsEnabled then
        local cl = pCommand:commandLength()
        self.trafficStatsOutgoing:count("reliableOpCommand", cl)
        self.trafficStatsGameLevel:count("operation", cl)
      end
    else
      self:queueOutgoingUnreliableCommand(pCommand)
      if self.trafficStatsEnabled then
        local cl = pCommand:commandLength()
        self.trafficStatsOutgoing:count("unreliableOpCommand", cl)
        self.trafficStatsGameLevel:count("operation", cl)
      end
    end
  end
  function C.proto:sendInFragments(payload, channelId)
    local fragmentLength = InternalConstants.InternalProperties.EG_OPT_MTU_SIZE - InternalConstants.PeerProperties.UDP_PACKAGE_HEADER_LENGTH - InternalConstants.CommandProperties.PHOTON_COMMAND_HEADER_FRAGMENT_LENGTH - 1
    if payload and fragmentLength < #payload then
      local fragmentCount = math.floor((#payload + fragmentLength - 1) / fragmentLength)
      local startSequenceNumber
      local tmpPayload = {}
      local channel
      channel = self.channels[channelId + 1]
      startSequenceNumber = channel.outgoingReliableSequenceNumber + 1
      self.logger:debug(">fragmented: payload will be sent in", fragmentCount, "fragments", startSequenceNumber)
      local fragmentOffset = 0
      local fragmentNumber = 0
      local payloadSize = #payload
      while fragmentOffset < payloadSize do
        if fragmentLength > payloadSize - fragmentOffset then
          fragmentLength = payloadSize - fragmentOffset
        end
        tmpPayload = {}
        tableutil.addTable(tmpPayload, payload, fragmentOffset + 1, fragmentLength)
        local pCommand = EnetCommand.new(self, InternalConstants.CommandProperties.CT_SENDFRAGMENT, tmpPayload)
        pCommand.mFragmentNumber = fragmentNumber
        pCommand.mStartSequenceNumber = startSequenceNumber
        pCommand.mFragmentCount = fragmentCount
        pCommand.mTotalLength = payloadSize
        pCommand.mFragmentOffset = fragmentOffset
        pCommand.mCommandChannelID = channelId
        self.byteCountLastOperation = self.byteCountLastOperation + pCommand:commandLength()
        self:queueOutgoingReliableCommand(pCommand)
        fragmentNumber = fragmentNumber + 1
        fragmentOffset = fragmentOffset + fragmentLength
        if self.trafficStatsEnabled then
          local l = pCommand:commandLength()
          self.trafficStatsOutgoing:count("FragmentOpCommand", l)
          self.trafficStatsGameLevel:countOperation(l)
        end
        self.logger:debug(">fragmented: fragment sent", pCommand.mStartSequenceNumber, pCommand.mReliableSequenceNumber, pCommand.mFragmentNumber)
      end
      return true
    end
    return false
  end
  function C.proto:queueOutgoingUnreliableCommand(pCommand)
    local pChannel
    local channelIndex = 1
    if #self.channels == 0 then
      self.logger:error(">unreliable: channels are NULL")
      return
    end
    if pCommand.mCommandChannelID == 255 then
      channelIndex = self.channelCountUserChannels + 1
    end
    pChannel = self.channels[channelIndex]
    pCommand.mReliableSequenceNumber = pChannel.outgoingReliableSequenceNumber
    pChannel.outgoingUnreliableSequenceNumber = pChannel.outgoingUnreliableSequenceNumber + 1
    pCommand.mUnreliableSequenceNumber = pChannel.outgoingUnreliableSequenceNumber
    table.insert(pChannel.outgoingUnreliableCommands, pCommand)
    if #pChannel.outgoingUnreliableCommands == self.warningTresholdQueueOutgoingUnreliable then
      self.logger:warn(">unreliable: WARNING! There are", #pChannel.outgoingUnreliableCommands, "outgoing messages waiting in the local sendQueue")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_OUTGOING_UNRELIABLE_WARNING)
    end
    self.logger:debug(">unreliable: sent", pCommand.mReliableSequenceNumber, pCommand.mUnreliableSequenceNumber)
  end
  function C.proto:queueOutgoingReliableCommand(pCommand)
    if #self.channels == 0 then
      self.logger:error(">reliable: channels are NULL")
      return
    end
    self.logger:trace(">reliable: command channel ID:", pCommand.mCommandChannelID)
    self.logger:trace(">reliable: channels:", #self.channels)
    local pChannel
    if pCommand.mCommandChannelID == 255 then
      self.logger:trace(">reliable: pCommand.mCommandChannelID == -1")
      pChannel = self.channels[self.channelCountUserChannels + 1]
    else
      self.logger:trace(">reliable: pCommand.mCommandChannelID != -1")
      pChannel = self.channels[pCommand.mCommandChannelID + 1]
    end
    if pCommand.mReliableSequenceNumber == 0 then
      pChannel.outgoingReliableSequenceNumber = pChannel.outgoingReliableSequenceNumber + 1
      pCommand.mReliableSequenceNumber = pChannel.outgoingReliableSequenceNumber
    end
    table.insert(pChannel.outgoingReliableCommands, pCommand)
    if #pChannel.outgoingReliableCommands == self.warningTresholdQueueOutgoingReliable then
      self.logger:warn(">reliable: WARNING! There are", #pChannel.outgoingReliableCommands, "outgoing messages waiting in the local sendQueue")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_OUTGOING_RELIABLE_WARNING)
    end
    self.logger:debug(">reliable: sent", pCommand.mReliableSequenceNumber, pCommand.mUnreliableSequenceNumber, pCommand.mCommandOriginalSentTime, pCommand.mCommandSentTime)
  end
  function C.proto:queueOutgoingAcknowledgement(command)
    self.logger:trace(">ack: queueOutgoingAcknowledgement")
    table.insert(self.outgoingAcknowledgements, command)
    if #self.outgoingAcknowledgements == self.warningTresholdQueueOutgoingAcks then
      self.logger:warn(">ack: WARNING! There are", #self.outgoingAcknowledgements, "outgoing acknowledgements waiting in the queue")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_OUTGOING_ACKS_WARNING)
    end
  end
  function C.proto:queueSentReliableCommand(command)
    self.logger:trace(">reliable: queueSentReliableCommand")
    table.insert(self.sentReliableCommands, command)
    if #self.sentReliableCommands == self.warningTresholdQueueSent then
      self.logger:warn(">reliable: WARNING! There are", #self.sentReliableCommands, "sent reliable messages waiting for their acknowledgement")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_SENT_WARNING)
    end
  end
  function C.proto:queueIncomingCommand(pCommand)
    local pCommandCopy, channel
    self.logger:trace("<queueIncomingCommand")
    if #self.channels == 0 then
      self.logger:error("<channels are NULL")
      return false
    end
    if pCommand.mCommandChannelID > self.channelCountUserChannels + 1 then
      self.logger:error("<received command for non-existing channel!")
      return false
    end
    if pCommand.mCommandChannelID ~= 255 then
      channel = self.channels[pCommand.mCommandChannelID + 1]
    else
      channel = self.channels[self.channelCountUserChannels + 1]
    end
    if pCommand.mCommandFlags == InternalConstants.CommandProperties.FV_RELIABLE then
      if pCommand.mReliableSequenceNumber < channel.incomingReliableSequenceNumber then
        self.logger:debug("<reliable: skipping old pCommand", pCommand.mReliableSequenceNumber)
        return false
      end
      if channel:getReliableCommandFromQueue(pCommand.mReliableSequenceNumber) then
        self.logger:debug("<reliable: skipping duplicate", pCommand.mReliableSequenceNumber)
        return false
      end
      if #channel.incomingReliableCommands == self.warningTresholdQueueIncomingReliable then
        self.logger:warn("<reliable: WARNING! There are", #channel.incomingReliableCommands, "incoming messages waiting in the local incoming reliable message queue of channel", channel.channelNumber, "!")
        self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_INCOMING_RELIABLE_WARNING)
      end
      pCommandCopy = EnetCommand.new(pCommand)
      table.insert(channel.incomingReliableCommands, pCommandCopy)
      self:sortLastElementInQueue(channel.incomingReliableCommands, true)
      return true
    end
    if pCommand.mCommandFlags == InternalConstants.CommandProperties.FV_UNRELIABLE then
      if pCommand.mReliableSequenceNumber < channel.incomingReliableSequenceNumber then
        self.logger:debug("<unreliable: skipping old by reliable s/n", pCommand.mReliableSequenceNumber, channel.incomingReliableSequenceNumber)
        return true
      end
      if pCommand.mUnreliableSequenceNumber <= channel.incomingUnreliableSequenceNumber then
        self.logger:debug("<unreliable: skipping old by unreliable s/n", pCommand.mUnreliableSequenceNumber, channel.incomingUnreliableSequenceNumber)
        return true
      end
      if channel:getUnreliableCommandFromQueue(pCommand.mUnreliableSequenceNumber) then
        self.logger:debug("<unreliable: skipping duplicate", pCommand.mUnreliableSequenceNumber)
        return false
      end
      if #channel.incomingUnreliableCommands == self.warningTresholdQueueIncomingUnreliable then
        self.logger:warn("<unreliable: WARNING! There are", #channel.incomingUnreliableCommands, "incoming messages waiting in the local incoming unreliable message queue of channel", channel.channelNumber, "!")
        self.mListener:onStatusChanged(CoreConstants.StatusCode.QUEUE_INCOMING_UNRELIABLE_WARNING)
      end
      pCommandCopy = EnetCommand.new(pCommand)
      table.insert(channel.incomingUnreliableCommands, pCommandCopy)
      self:sortLastElementInQueue(channel.incomingUnreliableCommands, false)
      return true
    end
    if pCommand.mCommandFlags == InternalConstants.CommandProperties.FV_UNRELIABLE_UNSEQUENCED then
      return false
    end
    return false
  end
  function C.proto:serializeToBuffer(ev)
    local tmpCopied = 0
    self.logger:trace("serializeToBuffer")
    for i = 1, #ev do
      local command = ev[i]
      local tmp = {}
      command:serialize(tmp)
      local tmpsize = #tmp
      self.logger:trace("serialized command:", command.mCommandType, "length:", tmpsize)
      if self.bufferLen + tmpsize >= InternalConstants.InternalProperties.EG_OPT_MTU_SIZE then
        self.logger:debug(">udp package is full. Commands in Package:", self.commandCount, " . Commands left in queue:", #ev)
        break
      else
        tableutil.addTable(self.buffer, tmp)
        self.commandCount = self.commandCount + 1
        self.bufferLen = self.bufferLen + tmpsize
        tmpCopied = tmpCopied + 1
        if 0 < bit.band(command.mCommandFlags, InternalConstants.CommandProperties.FLAG_RELIABLE) then
          command.mCommandSentTime = self.timeInt
          command.mCommandSentCount = command.mCommandSentCount + 1
          if command.mRoundTripTimeout == 0 then
            command.mCommandOriginalSentTime = self.timeInt
            command.mRoundTripTimeout = self.roundTripTime + 4 * self.roundTripTimeVariance
          else
            command.mRoundTripTimeout = command.mRoundTripTimeout * 2
          end
          if #self.sentReliableCommands == 0 then
            self.timeoutInt = command.mCommandSentTime + command.mRoundTripTimeout
          end
          self.packetsSent = self.packetsSent + 1
          self:queueSentReliableCommand(EnetCommand.new(command))
          self.packetsSent = self.packetsSent + 1
        end
      end
    end
    for i = 1, tmpCopied do
      table.remove(ev, 1)
    end
    return #ev
  end
  function C.proto:execute(pCommand)
    self.logger:trace("execute command:", pCommand.mCommandType)
    local sw = {
      [InternalConstants.CommandProperties.CT_CONNECT] = function()
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("controlCommand", pCommand:commandLength())
        end
      end,
      [InternalConstants.CommandProperties.CT_PING] = function()
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("controlCommand", pCommand:commandLength())
        end
      end,
      [InternalConstants.CommandProperties.CT_DISCONNECT] = function()
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("controlCommand", pCommand:commandLength())
        end
        local reason = CoreConstants.StatusCode.DISCONNECT_BY_SERVER
        if pCommand.mReservedByte == 1 then
          reason = CoreConstants.StatusCode.DISCONNECT_BY_SERVER_LOGIC
        elseif pCommand.mReservedByte == 3 then
          reason = CoreConstants.StatusCode.DISCONNECT_BY_SERVER_USER_LIMIT
        else
          self.logger:error("Info: Server sent disconnect because of a timeout. PeerId:", self.peerID, "  RTT/Variance:", self.roundTripTime, "/", self.roundTripTimeVariance)
          self:stopConnection()
          self.mListener:onStatusChanged(reason)
        end
      end,
      [InternalConstants.CommandProperties.CT_ACK] = function()
        self.logger:trace("CT_ACK")
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("controlCommand", pCommand:commandLength())
        end
        self.trafficStatsIncoming.timestampOfLastAck = PhotonTime.now()
        self.timeLastReceive = self.timeInt
        self.timeInt = PhotonTime:timeFromStartMs()
        local roundtripTime = self.timeInt - pCommand.mAckReceivedSentTime
        local pRemovedCommand
        local cmd = {}
        self:removeSentReliableCommand(pCommand.mAckReceivedReliableSequenceNumber, pCommand.mCommandChannelID, cmd)
        if #cmd > 0 then
          pRemovedCommand = cmd[1]
        end
        self.logger:trace("removed command is", pRemovedCommand)
        if pRemovedCommand then
          self.logger:debug("<ack:", pCommand.mAckReceivedReliableSequenceNumber, pCommand.mCommandChannelID)
          if pRemovedCommand.mCommandType == InternalConstants.CommandProperties.CT_EG_SERVERTIME then
            if roundtripTime <= self.roundTripTime then
              self.serverTimeOffset = self.serverSentTime + bit.rshift(roundtripTime, 1) - PhotonTime:timeFromStartMs()
              self.serverTimeOffsetIsAvailable = true
            else
              self:fetchServerTimestamp()
            end
          else
            self:updateRoundTripTimeAndVariance(roundtripTime)
            if self.connectionState == InternalConstants.ConnectionState.DISCONNECTING and pRemovedCommand.mCommandType == InternalConstants.CommandProperties.CT_DISCONNECT then
              self.logger:trace("DISCONNECT COMPLETE")
              self:stopConnection()
              self.mListener:onStatusChanged(CoreConstants.StatusCode.DISCONNECT)
            elseif pRemovedCommand.mCommandType == InternalConstants.CommandProperties.CT_CONNECT then
              self.logger:trace("removed command = CT_CONNECT")
              self.roundTripTime = roundtripTime
            end
          end
        elseif self.connectionState == InternalConstants.ConnectionState.CONNECTED then
          self.logger:debug("<ack: w/o command", pCommand.mAckReceivedReliableSequenceNumber, pCommand.mCommandChannelID)
        end
      end,
      [InternalConstants.CommandProperties.CT_SENDRELIABLE] = function()
        self.logger:trace("CT_SENDRELIABLE")
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("reliableOpCommand", pCommand:commandLength())
        end
        self:queueIncomingCommand(pCommand)
      end,
      [InternalConstants.CommandProperties.CT_SENDUNRELIABLE] = function()
        self.logger:trace("CT_SENDUNRELIABLE")
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("unreliableOpCommand", pCommand:commandLength())
        end
        self:queueIncomingCommand(pCommand)
      end,
      [InternalConstants.CommandProperties.CT_SENDFRAGMENT] = function()
        self.logger:trace("CT_SENDFRAGMENT")
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("fragmentOpCommand", pCommand:commandLength())
        end
        local success
        if self.connectionState == InternalConstants.ConnectionState.CONNECTED then
          if pCommand.mFragmentNumber > pCommand.mFragmentCount or pCommand.mFragmentOffset >= pCommand.mTotalLength or pCommand.mFragmentOffset + #pCommand.mCommandPayload > pCommand.mTotalLength then
            self.logger:error("Received fragment has bad size")
          end
          success = self:queueIncomingCommand(pCommand)
          if success then
            local pChannel = self.channels[pCommand.mCommandChannelID + 1]
            if pCommand.mReliableSequenceNumber == pCommand.mStartSequenceNumber then
              local storedFollowingFragment
              local storedFirstFragment = pChannel:getReliableCommandFromQueue(pCommand.mReliableSequenceNumber)
              local fragmentSequenceNumber = pCommand.mStartSequenceNumber + 1
              storedFirstFragment.mFragmentsRemaining = storedFirstFragment.mFragmentsRemaining - 1
              repeat
                while storedFirstFragment.mFragmentsRemaining > 0 and fragmentSequenceNumber < pCommand.mStartSequenceNumber + storedFirstFragment.mFragmentCount do
                  storedFollowingFragment = pChannel:getReliableCommandFromQueue(fragmentSequenceNumber)
                  fragmentSequenceNumber = fragmentSequenceNumber + 1
                  storedFirstFragment.mFragmentsRemaining = storedFirstFragment.mFragmentsRemaining - 1
                end
              until storedFollowingFragment
            else
              local pStartCmd = pChannel:getReliableCommandFromQueue(pCommand.mStartSequenceNumber)
              if pStartCmd then
                pStartCmd.mFragmentsRemaining = pStartCmd.mFragmentsRemaining - 1
              end
            end
          end
        end
      end,
      [InternalConstants.CommandProperties.CT_VERIFYCONNECT] = function()
        self.logger:trace("CT_VERIFYCONNECT")
        if self.trafficStatsEnabled then
          self.trafficStatsIncoming:count("controlCommand", pCommand:commandLength())
        end
        if self.connectionState == InternalConstants.ConnectionState.CONNECTING then
          self.logger:trace("init bytes length", #self.initBytes)
          local cmd = EnetCommand.new(self, InternalConstants.CommandProperties.CT_SENDRELIABLE, self.initBytes)
          self:queueOutgoingReliableCommand(cmd)
          if self.trafficStatsEnabled then
            self.trafficStatsOutgoing:count("controlCommand", cmd:commandLength())
          end
          self.connectionState = InternalConstants.ConnectionState.CONNECTED
        end
      end
    }
    local foo = sw[pCommand.mCommandType]
    if foo then
      foo()
    end
  end
  function C.proto:removeSentReliableCommand(ackReceivedReliableSequenceNumber, ackReceivedChannel, command)
    local foundCommand, result
    local foundIndex = -1
    for i = 1, #self.sentReliableCommands do
      result = self.sentReliableCommands[i]
      if result and result.mReliableSequenceNumber == ackReceivedReliableSequenceNumber and result.mCommandChannelID == ackReceivedChannel then
        foundCommand = result
        foundIndex = i
        break
      end
    end
    if foundCommand then
      table.insert(command, EnetCommand.new(foundCommand))
      table.remove(self.sentReliableCommands, foundIndex)
      if #self.sentReliableCommands > 0 then
        result = self.sentReliableCommands[1]
        self.timeoutInt = result.mCommandSentTime + result.mRoundTripTimeout
      end
    end
  end
  function C.proto:sortLastElementInQueue(argQueue, sortByReliableSequenceNumber)
    if #argQueue <= 1 then
      return
    end
    local tmpIndex = 0
    local pCommandTmp
    local indexOfLastCommand = #argQueue
    local pCommandNew = argQueue[#argQueue]
    tmpIndex = #argQueue - 1
    while tmpIndex > 0 do
      pCommandTmp = argQueue[tmpIndex]
      if sortByReliableSequenceNumber then
        if pCommandNew.mReliableSequenceNumber > pCommandTmp.mReliableSequenceNumber then
          break
        end
      elseif pCommandNew.mUnreliableSequenceNumber > pCommandTmp.mUnreliableSequenceNumber then
        break
      end
      tmpIndex = tmpIndex - 1
    end
    tmpIndex = tmpIndex + 1
    while indexOfLastCommand >= tmpIndex do
      pCommandTmp = argQueue[tmpIndex]
      argQueue[tmpIndex] = pCommandNew
      tmpIndex = tmpIndex + 1
      if indexOfLastCommand >= tmpIndex then
        pCommandNew = pCommandTmp
      end
    end
  end
  function C.proto:clearAllQueues()
    self.outgoingAcknowledgements = {}
    self.sentReliableCommands = {}
    for i = 1, self.channelCountUserChannels + 1 do
      self.channels[i].incomingReliableCommands = {}
      self.channels[i].incomingUnreliableCommands = {}
      self.channels[i].outgoingReliableCommands = {}
      self.channels[i].outgoingUnreliableCommands = {}
    end
  end
  function C.proto:calculateCrc(buffer)
    local crc = 4294967295
    local current = 0
    for _, v in pairs(buffer) do
      crc = bit32.bxor(crc, v)
      for i = 0, 7 do
        local crcBit1 = bit32.band(crc, 1) ~= 0
        crc = bit32.rshift(crc, 1)
        if crcBit1 then
          crc = bit32.bxor(crc, 3988292384)
        end
      end
    end
    return crc
  end
  return C
end
package.preload["photon.core.internal.NetSim"] = function(...)
  local Logger = require("photon.common.Logger")
  local PhotonTime = require("photon.common.util.time")
  local tableutil = require("photon.common.util.tableutil")
  local function _P(x)
    print(tableutil.toStringReq(x))
  end
  local _B = function(x)
    for i, v in ipairs(x) do
      print(i, v[1], "{...}", v[3])
    end
  end
  local class = require("photon.common.class")
  local C = class.declare("NetSim")
  function C:init(name, delay, jitter, lossPerc, dupPerc)
    self.buffer = {}
    self.delay = delay or 0
    self.jitter = jitter or 0
    self.lossPerc = lossPerc or 0
    self.dupPerc = dupPerc or 0
    self.nPush = 0
    self.nOut = 0
    self.nLost = 0
    self.nDuplicated = 0
    self.logger = Logger.new(name, Logger.Level.DEBUG)
    self.logger:debug("init")
  end
  function C.proto:_pushWithDelay(obj)
    local time0 = PhotonTime.timeFromStartMs()
    local time = time0 + (self.delay + math.random(-self.jitter, self.jitter))
    local i = 1
    while self.buffer[i] and time >= self.buffer[i][1] do
      i = i + 1
    end
    table.insert(self.buffer, i, {
      time,
      obj,
      time0
    })
    self.nPush = self.nPush + 1
    self.logger:debug("push", self.nPush, #self.buffer, i)
  end
  function C.proto:push(obj)
    if math.random() * 100 < self.lossPerc then
      self.nLost = self.nLost + 1
      self.logger:debug("lost", self.nLost)
    else
      self:_pushWithDelay(obj)
    end
  end
  function C.proto:pop(time)
    local time = time or PhotonTime.timeFromStartMs()
    if self.buffer[1] and time > self.buffer[1][1] then
      local obj = table.remove(self.buffer, 1)[2]
      if math.random() * 100 < self.dupPerc then
        self:_pushWithDelay(obj)
        self.nDuplicated = self.nDuplicated + 1
        self.logger:debug("duplicated", self.nDuplicated)
      end
      return obj
    else
      return nil
    end
  end
  function C.proto:servicePush(oper)
    local r = oper()
    while r do
      self:push(r)
      r = oper()
    end
  end
  function C.proto:servicePop(oper)
    local r = self:pop()
    while r do
      oper(r)
      r = self:pop()
    end
  end
  return C
end
package.preload["photon.core.internal.PeerBase"] = function(...)
  local bit = require("photon.common.util.bit.numberlua").bit
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local LiteConstants = require("photon.lite.constants")
  local OperationRequest = require("photon.core.OperationRequest")
  local OperationResponse = require("photon.core.OperationResponse")
  local EventData = require("photon.core.EventData")
  local GpOperationWriter = require("photon.core.GpOperationWriter")
  local GpOperationReader = require("photon.core.GpOperationReader")
  local tableutil = require("photon.common.util.tableutil")
  local InternalConstants = require("photon.core.internal.constants")
  local CoreConstants = require("photon.core.constants")
  local PhotonTime = require("photon.common.util.time")
  local Logger = require("photon.common.Logger")
  local encryption = require("photon.core.internal.crypto.encryption")
  local TrafficStats = require("photon.core.TrafficStats")
  local TrafficStatsGameLevel = require("photon.core.TrafficStatsGameLevel")
  local class = require("photon.common.class")
  local C = class.declare("PeerBase")
  function C:init(listener)
    self.logger = Logger.new("PeerBase")
    self.logger:setLevel(5)
    self.mListener = listener
    self.shouldScheduleDisconnectCB = false
    self.rt = nil
    self.sentCountAllowance = InternalConstants.PeerProperties.SENTCOUNTALLOWANCE
    self.sentTimeAllowance = InternalConstants.PeerProperties.SENTTIMEALLOWANCE
    self.timePingInterval = InternalConstants.PeerProperties.TIMEPINGINTERVAL
    self.secretKey = nil
    self.sharedKeyHash = nil
    self.isEncryptionAvailable = false
    self.warningTresholdQueueOutgoingReliable = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_OUTGOING_RELIABLE_DEFAULT
    self.warningTresholdQueueOutgoingUnreliable = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_OUTGOING_UNRELIABLE_DEFAULT
    self.warningTresholdQueueOutgoingAcks = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_OUTGOING_ACKS_DEFAULT
    self.warningTresholdQueueIncomingReliable = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_INCOMING_RELIABLE_DEFAULT
    self.warningTresholdQueueIncomingUnreliable = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_INCOMING_UNRELIABLE_DEFAULT
    self.warningTresholdQueueSent = InternalConstants.InternalProperties.WARNING_THRESHOLD_QUEUE_SENT_DEFAULT
    self.debugUseShortcut = false
    self.peerID = -1
    self.challenge = 0
    self.connectionState = InternalConstants.ConnectionState.DISCONNECTED
    self.channelCountUserChannels = InternalConstants.PeerProperties.CHANNEL_COUNT_DEFAULT
    self.timeInt = 0
    self.timeoutInt = 0
    self.timeLastReceive = 0
    self.packetsLost = 0
    self.packetLoss = 0
    self.packetsSent = 0
    self.packetLossEpoch = 0
    self.packetLossVariance = 0
    self.packetThrottleEpoch = 0
    self.serverTimeOffset = 0
    self.serverTimeOffsetIsAvailable = false
    self.serverSentTime = 0
    self.roundTripTime = 0
    self.roundTripTimeVariance = 0
    self.lastRoundTripTime = 0
    self.lowestRoundTripTime = 0
    self.lastRoundTripTimeVariance = 0
    self.highestRoundTripTimeVariance = 0
    self.packetThrottleInterval = 0
    self.timestampOfLastReceive = 0
    self.byteCountLastOperation = 0
    self.byteCountCurrentDispatch = 0
    self.isSendingCommand = false
    self.applicationIsInitialized = false
    self.crcEnabled = false
    self.packetLossByCrc = 0
    self.rt = nil
    self.initBytes = {}
    for i = 1, InternalConstants.InternalProperties.INIT_BYTES_LENGTH do
      self.initBytes[i] = 0
    end
    self.initBytes[1] = 243
    self.initBytes[2] = 0
    self.initBytes[3] = 1
    self.initBytes[4] = 6
    self.initBytes[5] = 1
    self.initBytes[6] = 65
    self.initBytes[7] = 0
    self.initBytes[8] = 0
    self.initBytes[9] = 7
  end
  function C:init2(listener)
    self:resetTrafficStats()
  end
  function C.proto:isConnected()
    return self.connectionState == InternalConstants.ConnectionState.CONNECTED
  end
  function C.proto:cleanupNonHierarchical()
    self.connectionState = InternalConstants.ConnectionState.DISCONNECTED
    self.secretKey = nil
    self.sharedKeyHash = nil
  end
  function C.proto:cleanup()
    self:cleanupNonHierarchical()
  end
  function C.proto:reset()
    self.logger:trace("reset()")
    self:cleanup()
    self.peerID = -1
    self.challenge = PhotonTime.timeFromStartMs()
    self.packetsSent = 0
    self.packetsLost = 0
    self.packetLoss = 0
    self.roundTripTime = InternalConstants.PeerProperties.ENET_PEER_DEFAULT_ROUND_TRIP_TIME
    self.packetThrottleInterval = InternalConstants.PeerProperties.ENET_PEER_PACKET_THROTTLE_INTERVAL
    self.isSendingCommand = false
    self.serverTimeOffsetIsAvailable = false
    self.serverTimeOffset = 0
  end
  function C.proto:connect(ipAddr, appID)
    self.logger:trace(" address: ", ipAddr)
    if self.connectionState ~= InternalConstants.ConnectionState.DISCONNECTED then
      self.logger:error("failed: Peer is already connected!")
      return false
    end
    self:reset()
    self.peerIpAddr = ipAddr
    appID = appID or "Lite"
    for i = 1, #appID do
      self.initBytes[InternalConstants.InternalProperties.INIT_BYTES_HEADER_LENGTH + i] = string.byte(appID, i)
    end
    self.logger:trace("init bytes:", table.concat(self.initBytes, ","))
    if self:startConnection(self.peerIpAddr) then
      return true
    else
      self.logger:error("failed: PhotonConnect_createConnection() failed.")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.EXCEPTION_ON_CONNECT)
      return false
    end
  end
  function C.proto:stopConnection()
    self.rt:stopConnection()
    self:cleanup()
    self.connectionState = InternalConstants.ConnectionState.DISCONNECTED
    self.challenge = PhotonTime.timeFromStartMs()
  end
  function C.proto:service(dispatchIncomingCommands)
    local dispatch = dispatchIncomingCommands == nil or dispatchIncomingCommands
    self:serviceBasic()
    if dispatch then
      repeat
      until not self:dispatchIncomingCommands()
    end
    self.logger:trace("self:sendOutgoingCommands")
    self:sendOutgoingCommands()
    if self.shouldScheduleDisconnectCB then
      self.shouldScheduleDisconnectCB = false
      self.mListener:onStatusChanged(CoreConstants.StatusCode.DISCONNECT)
    end
  end
  function C.proto:serviceBasic()
    self.rt:service()
  end
  function C.proto:sendOperation(operationCode, data, sendReliable, channelId, encrypt)
    if sendReliable == nil then
      sendReliable = true
    end
    channelId = channelId or 0
    encrypt = encrypt or false
    if not self:opCustom(OperationRequest.new(operationCode, data), sendReliable, channelId, encrypt) then
      local operationResponse = OperationResponse.new(operationCode, -1)
      operationResponse:setDebugMessage("Send operation error")
      self.mListener:onOperationResponse(operationResponse)
    end
  end
  function C.proto:opRaiseEvent(code, data, sendReliable, channelId, encrypt, msgType)
    local p = {}
    p[LiteConstants.ParameterCode.CODE] = Byte.new(code)
    p[LiteConstants.ParameterCode.DATA] = data
    self:opCustom(OperationRequest.new(LiteConstants.OperationCode.RAISE_EV, p), sendReliable, channelId, encrypt, msgType)
  end
  function C.proto:opCustom(operationRequest, sendReliable, channelId, encrypt, msgType)
    if channelId == nil then
      channelId = 0
    end
    if msgType == nil then
      msgType = CoreConstants.MessageType.MSGT_OP
    end
    if encrypt and not self.isEncryptionAvailable then
      self.logger:error("exchange keys first to enable encryption!")
      return false
    end
    if self.connectionState ~= InternalConstants.ConnectionState.CONNECTED then
      self.logger:error("wrong connection state", self.connectionState, tableutil.getKeyByValue(InternalConstants.ConnectionState, self.connectionState))
      return false
    end
    if channelId >= self.channelCountUserChannels then
      self.logger:error("channelId", channelId, "is out of channel-count bounds", 0, "-", self.channelCountUserChannels - 1)
      return false
    end
    local serializedOp = {}
    if not self:serializeOperation(operationRequest, serializedOp, encrypt, msgType) then
      return false
    end
    if #serializedOp > 0 then
      if sendReliable then
        self:send(InternalConstants.CommandProperties.CT_SENDRELIABLE, serializedOp, channelId)
      else
        self:send(InternalConstants.CommandProperties.CT_SENDUNRELIABLE, serializedOp, channelId)
      end
      return true
    end
    return false
  end
  function C.proto:establishEncryption()
    return self:opExchangeKeysForEncryption()
  end
  function C.proto:getServerTimeOffset()
    if self.serverTimeOffsetIsAvailable then
      return self.serverTimeOffset
    else
      return 0
    end
  end
  function C.proto:getServerTime()
    if self.serverTimeOffsetIsAvailable then
      return self.serverTimeOffset + PhotonTime:timeFromStartMs()
    else
      return 0
    end
  end
  function C.proto:getBytesOut()
    return self.rt:getBytesOut()
  end
  function C.proto:getBytesIn()
    return self.rt:getBytesIn()
  end
  function C.proto:getSentCountAllowance()
    return self.sentCountAllowance
  end
  function C.proto:setSentCountAllowance(setSentCountAllowance)
    self.sentCountAllowance = setSentCountAllowance
  end
  function C.proto:getTimePingInterval()
    return self.timePingInterval
  end
  function C.proto:setTimePingInterval(setTimePingInterval)
    self.timePingInterval = setTimePingInterval
  end
  function C.proto:getRoundTripTime()
    return self.roundTripTime
  end
  function C.proto:getRoundTripTimeVariance()
    return self.roundTripTimeVariance
  end
  function C.proto:getPeerID()
    return self.peerID
  end
  function C.proto:getSentTimeAllowance()
    return self.sentTimeAllowance
  end
  function C.proto:setSentTimeAllowance(sentTimeAllow)
    self.sentTimeAllowance = sentTimeAllow
  end
  function C.proto:getServerAdress()
    return self.peerIpAddr
  end
  function C.proto:getIsEncryptionAvailable()
    return self.isEncryptionAvailable
  end
  function C.proto:onSendCommands(nError)
    self.isSendingCommand = false
    if nError ~= 0 then
      if self.connectionState == InternalConstants.ConnectionState.CONNECTING then
        self.mListener:onStatusChanged(CoreConstants.StatusCode.EXCEPTION_ON_CONNECT)
      else
        self.mListener:onStatusChanged(CoreConstants.StatusCode.SEND_ERROR)
      end
    end
  end
  function C.proto:onDisconnected()
    self.logger:trace("onDisconnected")
    self:stopConnection()
  end
  function C.proto:getCrcEnabled(void)
    return self.crcEnabled
  end
  function C.proto:setCrcEnabled(val)
    if self.connectionState == InternalConstants.ConnectionState.DISCONNECTED then
      self.crcEnabled = val
    else
      self.logger:error("CrcEnabled can only be set while disconnected.")
    end
  end
  function C.proto:getPacketLossByCrc()
    return self.packetLossByCrc
  end
  function C.proto:serializeOperation(operationRequest, buffer, encrypt, msgType)
    local enc_bytes
    local operationWriter = GpOperationWriter.new()
    local code = operationRequest.operationCode
    local count = tableutil.getn(operationRequest.parameters)
    self.logger:trace("serializeOperation. code:", code, "count:", count)
    operationWriter:writeByte(code)
    operationWriter:writeShort(count)
    local params = operationRequest.parameters
    for k, v in pairs(params) do
      self.logger:trace("serialize key:", k, "value:", v)
      operationWriter:writeByte(k)
      if not operationWriter:serialize(v, true) then
        self.logger:error("failed due to a data type, not supported by protocol")
        return false
      end
    end
    if encrypt and self.isEncryptionAvailable then
      enc_bytes = encryption.encrypt(self.sharedKeyHash, operationWriter:getData())
    end
    buffer[1] = 243
    buffer[2] = msgType
    if encrypt and self.isEncryptionAvailable then
      for i = 1, #enc_bytes do
        buffer[InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH + i] = enc_bytes[i]
      end
      buffer[2] = bit.bor(buffer[2], 128)
    else
      local data = operationWriter:getData()
      for i = 1, #data do
        buffer[InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH + i] = data[i]
      end
    end
    self.logger:trace("serialized operation:", tableutil.dumpTable(buffer))
    return true
  end
  function C.proto:deserializeOperation(inBuff)
    self.logger:trace("deserializeOperation")
    if #inBuff < InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH then
      self.logger:error("failed: UDP/TCP data too short!", #inBuff)
      return false
    end
    if inBuff[1] ~= 243 then
      self.logger:error("failed: MagicNumber should be 0xF3, but it is", inBuff[1])
      return false
    end
    local msgType = bit.band(inBuff[2], 127)
    local isEncrypted = bit.band(inBuff[2], 128) > 0
    self.logger:trace("bodyBuff:", #inBuff, ", msgType:", msgType, "(event = ", CoreConstants.MessageType.MSGT_EV, ")")
    local sw = {
      [CoreConstants.MessageType.MSGT_INIT_RES] = function()
        self:initCallback()
      end,
      [CoreConstants.MessageType.MSGT_OP_RES] = function()
        self:deserializeOperationResponse(inBuff, isEncrypted, msgType)
      end,
      [CoreConstants.MessageType.MSGT_INT_OP_RES] = function()
        self:deserializeOperationResponse(inBuff, isEncrypted, msgType)
      end,
      [CoreConstants.MessageType.MSGT_EV] = function()
        self:deserializeEvent(inBuff, isEncrypted)
      end
    }
    local foo = sw[msgType]
    if foo then
      foo()
    end
    return true
  end
  function C.proto:deserializeOperationResponse(inBuff, isEncrypted, msgType)
    if isEncrypted then
      inBuff = encryption.decrypt(self.sharedKeyHash, inBuff, InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH)
    else
      tableutil.removeFromHead(inBuff, InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH)
    end
    self.logger:trace("deserializeOperationResponse:", tableutil.dumpTable(inBuff))
    local operationReader = GpOperationReader.new(inBuff)
    local opCode = operationReader:deserializeByte()
    local returnCode = operationReader:deserializeShort()
    local operationResponse = OperationResponse.new(opCode, returnCode)
    local debugMsgType = operationReader:deserializeByte()
    local debugMsg = operationReader:deserializeType(debugMsgType)
    if debugMsg and type(debugMsg) == "string" then
      operationResponse:setDebugMessage(debugMsg)
    else
      operationResponse:setDebugMessage("")
    end
    local size = operationReader:deserializeShort()
    local key, val
    for i = 1, size do
      key = operationReader:deserializeByte()
      val = operationReader:deserialize()
      operationResponse:addParameter(key, val)
    end
    local sw = {
      [CoreConstants.MessageType.MSGT_OP_RES] = function()
        local timeBeforeCallback
        local stEn = self.trafficStatsEnabled
        if stEn then
          self.trafficStatsGameLevel:count("opResponse", self.byteCountCurrentDispatch)
          timeBeforeCallback = PhotonTime.now()
        end
        self.mListener:onOperationResponse(operationResponse)
        if stEn then
          self.trafficStatsGameLevel:timeForResponseCallback(opCode, PhotonTime.now() - timeBeforeCallback)
        end
      end,
      [CoreConstants.MessageType.MSGT_INT_OP_RES] = function()
        local timeBeforeCallback
        local stEn = self.trafficStatsEnabled
        if stEn then
          self.trafficStatsGameLevel:count("result", self.byteCountCurrentDispatch)
          timeBeforeCallback = PhotonTime.now()
        end
        if operationResponse.operationCode == InternalConstants.CommandProperties.PHOTON_KEY_INIT_ENCRYPTION then
          self:deriveSharedKey(operationResponse)
        else
          self.logger:error("Received unknown internal operation:", operationResponse:toString(true))
        end
        if stEn then
          self.trafficStatsGameLevel:timeForResponseCallback(opCode, PhotonTime.now() - timeBeforeCallback)
        end
      end
    }
    local foo = sw[msgType]
    if foo then
      foo()
    else
      self.logger:error("msgType not expected here:", msgType)
    end
  end
  function C.proto:deserializeEvent(inBuff, isEncrypted)
    if isEncrypted then
      inBuff = encryption.decrypt(self.sharedKeyHash, inBuff, InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH)
    else
      tableutil.removeFromHead(inBuff, InternalConstants.InternalProperties.IN_BUFF_HEADER_LENGTH)
    end
    self.logger:trace("deserializeEvent:", tableutil.dumpTable(inBuff))
    local operationReader = GpOperationReader.new(inBuff)
    local code = operationReader:deserializeByte()
    local size = operationReader:deserializeShort()
    local parameters = {}
    local k, v
    for i = 1, size do
      k = operationReader:deserializeByte()
      v = operationReader:deserialize()
      parameters[k] = v
    end
    local eventData = EventData.new(code, parameters)
    local timeBeforeCallback
    local stEn = self.trafficStatsEnabled
    if stEn then
      self.trafficStatsGameLevel:count("event", self.byteCountCurrentDispatch)
      timeBeforeCallback = PhotonTime.now()
    end
    self.mListener:onEvent(eventData)
    if stEn then
      self.trafficStatsGameLevel:timeForEventCallback(eventData.code, PhotonTime.now() - timeBeforeCallback)
    end
  end
  function C.proto:updateRoundTripTimeAndVariance(time)
    self.logger:trace("updateRoundTripTimeAndVariance")
    if time < 0 then
      return
    end
    self.roundTripTimeVariance = self.roundTripTimeVariance * 3
    self.roundTripTimeVariance = self.roundTripTimeVariance / 4
    self.roundTripTime = self.roundTripTime + (time - self.roundTripTime)
    self.roundTripTimeVariance = self.roundTripTimeVariance + math.abs(time - self.roundTripTime / 8) / 4
    if self.roundTripTime < self.lowestRoundTripTime then
      self.lowestRoundTripTime = self.roundTripTime
    end
    if self.roundTripTimeVariance > self.highestRoundTripTimeVariance then
      self.highestRoundTripTimeVariance = self.roundTripTimeVariance
    end
    if self.packetThrottleEpoch == 0 or self.timeInt - self.packetThrottleEpoch >= self.packetThrottleInterval then
      self.lastRoundTripTime = self.lowestRoundTripTime
      self.lastRoundTripTimeVariance = self.highestRoundTripTimeVariance
      self.lowestRoundTripTime = self.roundTripTime
      self.highestRoundTripTimeVariance = self.roundTripTimeVariance
      self.packetThrottleEpoch = self.timeInt
    end
  end
  function C.proto:opExchangeKeysForEncryption()
    local secretKey, publicKey = encryption.generateKeys()
    self.secretKey = secretKey
    self.isEncryptionAvailable = false
    Array[Byte].apply(publicKey)
    local p = {}
    p[InternalConstants.CommandProperties.PHOTON_CODE_CLIENT_KEY] = publicKey
    return self:opCustom(OperationRequest.new(InternalConstants.CommandProperties.PHOTON_KEY_INIT_ENCRYPTION, p), true, 0, false, CoreConstants.MessageType.MSGT_INT_OP)
  end
  function C.proto:deriveSharedKey(operationResponse)
    if operationResponse.errCode ~= 0 then
      self.logger:error("Establishing encryption keys failed. Operation response error:", operationResponse.errCode, operationResponse.errMsg)
      self.mListener:onStatusChanged(CoreConstants.StatusCode.ENCRYPTION_FAILED_TO_ESTABLISH)
      return
    end
    local serverPublicKey = operationResponse.parameters[InternalConstants.CommandProperties.PHOTON_CODE_SERVER_KEY]
    if not serverPublicKey then
      self.logger:error("Establishing encryption keys failed. Server's public key is NULL")
      self.mListener:onStatusChanged(CoreConstants.StatusCode.ENCRYPTION_FAILED_TO_ESTABLISH)
      return
    end
    local keySize = #serverPublicKey
    if keySize > 96 then
      self.logger:error("Establishing encryption keys failed. Server's public key has an unexpected size:", keySize)
      self.mListener:onStatusChanged(CoreConstants.StatusCode.ENCRYPTION_FAILED_TO_ESTABLISH)
      return
    end
    self.sharedKeyHash = encryption.deriveSharedKey(self.secretKey, serverPublicKey)
    self.isEncryptionAvailable = true
    self.mListener:onStatusChanged(CoreConstants.StatusCode.ENCRYPTION_ESTABLISHED)
  end
  function C.proto:initCallback()
    self.logger:trace("< read init")
    self.applicationIsInitialized = true
    self:fetchServerTimestamp()
    self.mListener:onStatusChanged(CoreConstants.StatusCode.CONNECT)
  end
  function C.proto:getListener()
    return self.mListener
  end
  function C.proto:getChannelCountUserChannels()
    return self.channelCountUserChannels
  end
  function C.proto:getConnectionState()
    return self.connectionState
  end
  function C.proto:getPeerID()
    return self.peerID
  end
  function C.proto:setPeerID(newPeerId)
    self.peerID = newPeerId
  end
  function C.proto:getPackageHeaderSize()
    return 0
  end
  function C.proto:setTrafficStatsEnabled(x)
    if x then
      self.trafficStatsEnabled = PhotonTime.now()
    else
      self.trafficStatsEnabledTime = self.trafficStatsEnabledTime + PhotonTime.now() - self.trafficStatsEnabled
      self.trafficStatsEnabled = false
    end
  end
  function C.proto:getTrafficStatsEnabled()
    return self.trafficStatsEnabled or false
  end
  function C.proto:getTrafficStatsEnabledTime()
    if self.trafficStatsEnabled then
      return self.trafficStatsEnabledTime + PhotonTime.now() - self.trafficStatsEnabled
    else
      return self.trafficStatsEnabledTime
    end
  end
  function C.proto:resetTrafficStats()
    self.trafficStatsIncoming = TrafficStats.new(self:getPackageHeaderSize())
    self.trafficStatsOutgoing = TrafficStats.new(self:getPackageHeaderSize())
    self.trafficStatsGameLevel = TrafficStatsGameLevel.new()
    self.trafficStatsEnabledTime = 0
    self.trafficStatsEnabled = nil
  end
  function C.proto:resetTrafficStatsMaximumCounters()
    self.trafficStatsGameLevel:resetMaximumCounters()
  end
  return C
end
package.preload["photon.core.internal.PhotonConnect"] = function(...)
  local socket = require("socket")
  local CoreConstants = require("photon.core.constants")
  local InternalConstants = require("photon.core.internal.constants")
  local logger = require("photon.common.Logger").new("PhotonConnect")
  local NetSim = require("photon.core.internal.NetSim")
  local InternalConnectionState = {
    NC_Closed = 0,
    NC_Connecting = 1,
    NC_NotConnectedError = 2,
    NC_Connected = 3
  }
  local PhotonSendRecvState = {
    NC_Reported = 0,
    NC_NeedReportOk = 1,
    NC_NeedReportError = 2
  }
  local class = require("photon.common.class")
  local C = class.declare("PhotonConnect")
  function C:init(peerBase)
    self.mConnectionState = InternalConnectionState.NC_Closed
    self.mSendState = PhotonSendRecvState.NC_Reported
    self.mError = CoreConstants.ErrorCode.SUCCESS
    self.mPeerBase = peerBase
    self.mIP = nil
    self.mPort = 0
  end
  function C:init2()
    if self.sendNetSim then
      self.sendBuffer0 = self.sendBuffer
      self.sendBuffer = self._sendBufferWithSim
    end
    if self.recvNetSim then
      self.recvBuffer = self._recvBufferWithSim
    end
  end
  function C.proto:serviceNetSim()
    if self.sendNetSim then
      self.sendNetSim:servicePop(function(obj)
        self:sendBuffer0(obj)
      end)
    end
    if self.recvNetSim then
      self.recvNetSim:servicePush(function()
        local res, status = self.mSocket:receive()
        if res then
          return {res, status}
        else
          return nil
        end
      end)
    end
  end
  function C.proto:service()
    local iSendRes = 0
    local iRecvRes = CoreConstants.ErrorCode.SUCCESS
    logger:trace("service with connection state:", self.mConnectionState)
    local sw = {
      [InternalConnectionState.NC_Closed] = function()
        logger:trace("NC_Closed")
      end,
      [InternalConnectionState.NC_NotConnectedError] = function()
        logger:trace("NC_NotConnectedError")
        self.mConnectionState = InternalConnectionState.NC_Closed
        if self.mError == CoreConstants.ErrorCode.SUCCESS then
          self.mError = CoreConstants.ErrorCode.NET_ERROR
        end
        self.mPeerBase:onConnectCallback(CoreConstants.ErrorCode.NET_ERROR)
      end,
      [InternalConnectionState.NC_Connecting] = function()
        logger:trace("NC_Connecting")
        if not self:checkConnection() then
          return
        end
        self.mConnectionState = InternalConnectionState.NC_Connected
        self.mPeerBase:onConnectCallback(CoreConstants.ErrorCode.SUCCESS)
      end,
      [InternalConnectionState.NC_Connected] = function()
        logger:trace("NC_Connected")
        self:serviceNetSim()
        if self.mSendState ~= PhotonSendRecvState.NC_Reported then
          local t2 = {
            [PhotonSendRecvState.NC_NeedReportError] = function()
              logger:error("NC_NeedReportError")
              if self.mError == CoreConstants.ErrorCode.SUCCESS then
                self.mError = CoreConstants.ErrorCode.NET_ERROR
              end
              self.mPeerBase:onSendCommands(CoreConstants.ErrorCode.NET_ERROR)
              self.mPeerBase.connectionState = InternalConstants.ConnectionState.DISCONNECTED
              self.mSendState = PhotonSendRecvState.NC_Reported
            end,
            [PhotonSendRecvState.NC_NeedReportOk] = function()
              logger:trace("NC_NeedReportOk")
              if self.mError ~= CoreConstants.ErrorCode.SUCCESS then
                self.mError = CoreConstants.ErrorCode.SUCCESS
              end
              self.mPeerBase:onSendCommands(CoreConstants.ErrorCode.SUCCESS)
              self.mSendState = PhotonSendRecvState.NC_Reported
            end
          }
          local foo2 = t2[self.mSendState]
          if foo2 then
            foo2()
          else
            error("Unknown send state.")
          end
        end
        local buffer
        while iRecvRes == CoreConstants.ErrorCode.SUCCESS and self.mConnectionState ~= InternalConnectionState.NC_Closed do
          iRecvRes, buffer = self:recvBuffer()
          if iRecvRes == CoreConstants.ErrorCode.SUCCESS or iRecvRes == CoreConstants.ErrorCode.NET_ERROR or iRecvRes == CoreConstants.ErrorCode.NET_ENOTCONN then
            self.mPeerBase:onReceiveDataCallback(buffer, iRecvRes)
          elseif iRecvRes ~= CoreConstants.ErrorCode.EITEMBUSY then
            error("Unhandled iRecvRes")
          end
        end
      end
    }
    local foo = sw[self.mConnectionState]
    if foo then
      foo()
    else
      error("Unknown state.")
    end
  end
  function C.proto:startConnection(ipAddr)
    if not ipAddr then
      logger:error("cant start connection for nil host")
      return false
    end
    logger:info(ipAddr, "start connection to host")
    self:stopConnection()
    local port_index = string.find(ipAddr, ":")
    local port = self:defaultPort()
    local host = ipAddr
    if port_index then
      port = string.sub(ipAddr, port_index + 1)
      host = string.sub(ipAddr, 0, port_index - 1)
    end
    port = tonumber(port) or 0
    self.mSocket = self:socket()
    self.mSocket:settimeout(0)
    local connRes, connErr = self.mSocket:setpeername(host, port)
    if not connRes then
      logger:error(ipAddr, "Connection error:", connErr)
      return false
    end
    self.mConnectionState = InternalConnectionState.NC_Connecting
    self.mError = CoreConstants.ErrorCode.SUCCESS
    logger:info(ipAddr, host, port, "successful start connection")
    return true
  end
  function C.proto:stopConnection()
    if self.mSocket then
      self.mSocket:close()
    end
    self.mSocket = nil
    self.mConnectionState = InternalConnectionState.NC_Closed
  end
  function C.proto:sendPackage(src)
    logger:trace("send package")
    if not self.mSocket then
      return CoreConstants.ErrorCode.EFAILED
    end
    if not src or #src == 0 then
      return CoreConstants.ErrorCode.SUCCESS
    end
    local iSendRes = self:sendBuffer(src)
    logger:trace("send buffer result :", iSendRes)
    if iSendRes == CoreConstants.ErrorCode.SUCCESS then
      self.mSendState = PhotonSendRecvState.NC_NeedReportOk
      return iSendRes
    elseif iSendRes == CoreConstants.ErrorCode.NET_ERROR then
      self.mSendState = PhotonSendRecvState.NC_NeedReportError
      return iSendRes
    else
      error("Unhandled iSendRes")
      return CoreConstants.ErrorCode.EFAILED
    end
  end
  function C.proto:sendBuffer(src)
    local res, status = self.mSocket:send(src)
    if res then
      self.mError = CoreConstants.ErrorCode.SUCCESS
      return CoreConstants.ErrorCode.SUCCESS
    else
      logger:error("send package error", status)
      self.mError = CoreConstants.ErrorCode.NET_ERROR
      return CoreConstants.ErrorCode.NET_ERROR
    end
  end
  function C.proto:_sendBufferWithSim(src)
    self.sendNetSim:push(src)
    return CoreConstants.ErrorCode.SUCCESS
  end
  function C.proto:_recvBuffer(res, status)
    if res then
      logger:trace("receive buffer size:", #res)
      self.mError = CoreConstants.ErrorCode.SUCCESS
      return CoreConstants.ErrorCode.SUCCESS, res
    elseif res == nil and status == "timeout" then
      logger:trace("receive buffer timeout")
      self.mError = CoreConstants.ErrorCode.SUCCESS
      return CoreConstants.ErrorCode.EITEMBUSY
    else
      logger:error("receive buffer error. status:", status)
      self.mError = CoreConstants.ErrorCode.NET_ERROR
      return CoreConstants.ErrorCode.NET_ERROR
    end
  end
  function C.proto:recvBuffer()
    local res, status = self.mSocket:receive()
    return self:_recvBuffer(res, status)
  end
  function C.proto:_recvBufferWithSim()
    local obj = self.recvNetSim:pop()
    if obj then
      return self:_recvBuffer(obj[1], obj[2])
    else
      return self:_recvBuffer(nil, "timeout")
    end
  end
  function C.proto:checkConnection()
    error("not implemented")
  end
  function C.proto:defaultPort()
    error("not implemented")
  end
  function C.proto:socket()
    error("not implemented")
  end
  return C
end
package.preload["photon.core.internal.PhotonHeader"] = function(...)
  local byteutil = require("photon.common.util.byteutil")
  local class = require("photon.common.class")
  local C = class.declare("PhotonHeader")
  function C:init()
    self.peerID = 0
    self.flags = 0
    self.commandCount = 0
    self.sentTime = 0
    self.challenge = 0
    self.crc = 0
  end
  function C.proto:setInTable(tbl)
    tbl[1] = byteutil.get_byte(self.peerID, 1)
    tbl[2] = byteutil.get_byte(self.peerID, 0)
    tbl[3] = self.flags
    tbl[4] = self.commandCount
    byteutil.int_to_byte_array_be(self.sentTime, tbl, 5)
    byteutil.int_to_byte_array_be(self.challenge, tbl, 9)
  end
  function C.proto:setCrcInTable(tbl)
    byteutil.int_to_byte_array_be(self.crc, tbl, 13)
  end
  return C
end
package.preload["photon.core.internal.constants"] = function(...)
  local M = {}
  M.ConnectionState = {
    DISCONNECTED = 0,
    CONNECTING = 1,
    CONNECTED = 3,
    DISCONNECTING = 4,
    ZOMBIE = 6
  }
  M.CommandProperties = {
    FLAG_RELIABLE = 1,
    FLAG_UNSEQUENCED = 2,
    FV_UNRELIABLE = 0,
    FV_RELIABLE = 1,
    FV_UNRELIABLE_UNSEQUENCED = 2,
    CT_NONE = 0,
    CT_ACK = 1,
    CT_CONNECT = 2,
    CT_VERIFYCONNECT = 3,
    CT_DISCONNECT = 4,
    CT_PING = 5,
    CT_SENDRELIABLE = 6,
    CT_SENDUNRELIABLE = 7,
    CT_SENDFRAGMENT = 8,
    CT_EG_SERVERTIME = 12,
    COMMANDS_BUF_LEN = 20,
    PHOTON_COMMAND_HEADER_LENGTH = 12,
    PHOTON_COMMAND_UNRELIABLE_HEADER_LENGTH = 4,
    PHOTON_COMMAND_HEADER_FRAGMENT_LENGTH = 32,
    MSG_HEADER_BYTES = 2,
    TCP_HEADER_LENGTH = 7,
    TCP_PING_LENGTH = 9,
    PHOTON_CODE_CLIENT_KEY = 1,
    PHOTON_CODE_SERVER_KEY = 1,
    PHOTON_KEY_INIT_ENCRYPTION = 0
  }
  M.InternalProperties = {
    IN_BUFF_HEADER_LENGTH = 2,
    INIT_BYTES_HEADER_LENGTH = 9,
    APP_NAME_LENGTH = 32,
    INIT_BYTES_LENGTH = 41,
    EG_OPT_MTU_SIZE = 1200,
    PROP_NONE = 0,
    PROP_GAME = 1,
    PROP_ACTOR = 2,
    PROP_GAME_AND_ACTOR = 3,
    WARNING_THRESHOLD_QUEUE_OUTGOING_RELIABLE_DEFAULT = 100,
    WARNING_THRESHOLD_QUEUE_OUTGOING_UNRELIABLE_DEFAULT = 100,
    WARNING_THRESHOLD_QUEUE_OUTGOING_ACKS_DEFAULT = 100,
    WARNING_THRESHOLD_QUEUE_INCOMING_RELIABLE_DEFAULT = 100,
    WARNING_THRESHOLD_QUEUE_INCOMING_UNRELIABLE_DEFAULT = 100,
    WARNING_THRESHOLD_QUEUE_SENT_DEFAULT = 100
  }
  M.PeerProperties = {
    SENTCOUNTALLOWANCE = 5,
    SENTTIMEALLOWANCE = 10000,
    TIMEPINGINTERVAL = 2000,
    CHANNEL_COUNT_DEFAULT = 20,
    WINDOW_SIZE = 128,
    DEBUG_IN_COMMANDS = false,
    DEBUG_IN_QUEUE_COMMANDS = false,
    DEBUG_OUT_COMMANDS = false,
    DEBUG_ACK_COMMANDS = false,
    DEBUG_NEW_IN_COMMANDS = false,
    DEBUG_DISPATCH_COMMANDS = false,
    DEBUG_RING_COUNT = false,
    UDP_PACKAGE_HEADER_LENGTH = 12,
    ENET_PEER_PACKET_LOSS_SCALE = 65536,
    ENET_PEER_DEFAULT_ROUND_TRIP_TIME = 300,
    ENET_PEER_PACKET_THROTTLE_INTERVAL = 5000,
    CRC_LENGTH = 4
  }
  return M
end
package.preload["photon.core.internal.crypto.aeslua.aes"] = function(...)
  local bit = require("photon.common.util.bit.numberlua").bit
  local gf = require("photon.core.internal.crypto.aeslua.gf")
  local util = require("photon.core.internal.crypto.aeslua.util")
  local public = {}
  local private = {}
  public.ROUNDS = "rounds"
  public.KEY_TYPE = "type"
  public.ENCRYPTION_KEY = 1
  public.DECRYPTION_KEY = 2
  private.SBox = {}
  private.iSBox = {}
  private.table0 = {}
  private.table1 = {}
  private.table2 = {}
  private.table3 = {}
  private.tableInv0 = {}
  private.tableInv1 = {}
  private.tableInv2 = {}
  private.tableInv3 = {}
  private.rCon = {
    16777216,
    33554432,
    67108864,
    134217728,
    268435456,
    536870912,
    1073741824,
    2147483648,
    452984832,
    905969664,
    1811939328,
    3623878656,
    2868903936,
    1291845632,
    2583691264,
    788529152
  }
  function private.affinMap(byte)
    local mask = 248
    local result = 0
    for i = 1, 8 do
      result = bit.lshift(result, 1)
      local parity = util.byteParity(bit.band(byte, mask))
      result = result + parity
      local lastbit = bit.band(mask, 1)
      mask = bit.band(bit.rshift(mask, 1), 255)
      if lastbit ~= 0 then
        mask = bit.bor(mask, 128)
      else
        mask = bit.band(mask, 127)
      end
    end
    return bit.bxor(result, 99)
  end
  function private.calcSBox()
    for i = 0, 255 do
      local inverse
      if i ~= 0 then
        inverse = gf.invert(i)
      else
        inverse = i
      end
      local mapped = private.affinMap(inverse)
      private.SBox[i] = mapped
      private.iSBox[mapped] = i
    end
  end
  function private.calcRoundTables()
    for x = 0, 255 do
      local byte = private.SBox[x]
      private.table0[x] = util.putByte(gf.mul(3, byte), 0) + util.putByte(byte, 1) + util.putByte(byte, 2) + util.putByte(gf.mul(2, byte), 3)
      private.table1[x] = util.putByte(byte, 0) + util.putByte(byte, 1) + util.putByte(gf.mul(2, byte), 2) + util.putByte(gf.mul(3, byte), 3)
      private.table2[x] = util.putByte(byte, 0) + util.putByte(gf.mul(2, byte), 1) + util.putByte(gf.mul(3, byte), 2) + util.putByte(byte, 3)
      private.table3[x] = util.putByte(gf.mul(2, byte), 0) + util.putByte(gf.mul(3, byte), 1) + util.putByte(byte, 2) + util.putByte(byte, 3)
    end
  end
  function private.calcInvRoundTables()
    for x = 0, 255 do
      local byte = private.iSBox[x]
      private.tableInv0[x] = util.putByte(gf.mul(11, byte), 0) + util.putByte(gf.mul(13, byte), 1) + util.putByte(gf.mul(9, byte), 2) + util.putByte(gf.mul(14, byte), 3)
      private.tableInv1[x] = util.putByte(gf.mul(13, byte), 0) + util.putByte(gf.mul(9, byte), 1) + util.putByte(gf.mul(14, byte), 2) + util.putByte(gf.mul(11, byte), 3)
      private.tableInv2[x] = util.putByte(gf.mul(9, byte), 0) + util.putByte(gf.mul(14, byte), 1) + util.putByte(gf.mul(11, byte), 2) + util.putByte(gf.mul(13, byte), 3)
      private.tableInv3[x] = util.putByte(gf.mul(14, byte), 0) + util.putByte(gf.mul(11, byte), 1) + util.putByte(gf.mul(13, byte), 2) + util.putByte(gf.mul(9, byte), 3)
    end
  end
  function private.rotWord(word)
    local tmp = bit.band(word, 4278190080)
    return bit.lshift(word, 8) + bit.rshift(tmp, 24)
  end
  function private.subWord(word)
    return util.putByte(private.SBox[util.getByte(word, 0)], 0) + util.putByte(private.SBox[util.getByte(word, 1)], 1) + util.putByte(private.SBox[util.getByte(word, 2)], 2) + util.putByte(private.SBox[util.getByte(word, 3)], 3)
  end
  function public.expandEncryptionKey(key)
    local keySchedule = {}
    local keyWords = math.floor(#key / 4)
    if keyWords ~= 4 and keyWords ~= 6 and keyWords ~= 8 or keyWords * 4 ~= #key then
      print("Invalid key size: ", keyWords)
      return nil
    end
    keySchedule[public.ROUNDS] = keyWords + 6
    keySchedule[public.KEY_TYPE] = public.ENCRYPTION_KEY
    for i = 0, keyWords - 1 do
      keySchedule[i] = util.putByte(key[i * 4 + 1], 3) + util.putByte(key[i * 4 + 2], 2) + util.putByte(key[i * 4 + 3], 1) + util.putByte(key[i * 4 + 4], 0)
    end
    for i = keyWords, (keySchedule[public.ROUNDS] + 1) * 4 - 1 do
      local tmp = keySchedule[i - 1]
      if i % keyWords == 0 then
        tmp = private.rotWord(tmp)
        tmp = private.subWord(tmp)
        local index = math.floor(i / keyWords)
        tmp = bit.bxor(tmp, private.rCon[index])
      elseif keyWords > 6 and i % keyWords == 4 then
        tmp = private.subWord(tmp)
      end
      keySchedule[i] = bit.bxor(keySchedule[i - keyWords], tmp)
    end
    return keySchedule
  end
  function private.invMixColumnOld(word)
    local b0 = util.getByte(word, 3)
    local b1 = util.getByte(word, 2)
    local b2 = util.getByte(word, 1)
    local b3 = util.getByte(word, 0)
    return util.putByte(gf.add(gf.add(gf.add(gf.mul(11, b1), gf.mul(13, b2)), gf.mul(9, b3)), gf.mul(14, b0)), 3) + util.putByte(gf.add(gf.add(gf.add(gf.mul(11, b2), gf.mul(13, b3)), gf.mul(9, b0)), gf.mul(14, b1)), 2) + util.putByte(gf.add(gf.add(gf.add(gf.mul(11, b3), gf.mul(13, b0)), gf.mul(9, b1)), gf.mul(14, b2)), 1) + util.putByte(gf.add(gf.add(gf.add(gf.mul(11, b0), gf.mul(13, b1)), gf.mul(9, b2)), gf.mul(14, b3)), 0)
  end
  function private.invMixColumn(word)
    local b0 = util.getByte(word, 3)
    local b1 = util.getByte(word, 2)
    local b2 = util.getByte(word, 1)
    local b3 = util.getByte(word, 0)
    local t = bit.bxor(b3, b2)
    local u = bit.bxor(b1, b0)
    local v = bit.bxor(t, u)
    v = bit.bxor(v, gf.mul(8, v))
    local w = bit.bxor(v, gf.mul(4, bit.bxor(b2, b0)))
    v = bit.bxor(v, gf.mul(4, bit.bxor(b3, b1)))
    return util.putByte(bit.bxor(bit.bxor(b3, v), gf.mul(2, bit.bxor(b0, b3))), 0) + util.putByte(bit.bxor(bit.bxor(b2, w), gf.mul(2, t)), 1) + util.putByte(bit.bxor(bit.bxor(b1, v), gf.mul(2, bit.bxor(b0, b3))), 2) + util.putByte(bit.bxor(bit.bxor(b0, w), gf.mul(2, u)), 3)
  end
  function public.expandDecryptionKey(key)
    local keySchedule = public.expandEncryptionKey(key)
    if keySchedule == nil then
      return nil
    end
    keySchedule[public.KEY_TYPE] = public.DECRYPTION_KEY
    for i = 4, (keySchedule[public.ROUNDS] + 1) * 4 - 5 do
      keySchedule[i] = private.invMixColumnOld(keySchedule[i])
    end
    return keySchedule
  end
  function private.addRoundKey(state, key, round)
    for i = 0, 3 do
      state[i] = bit.bxor(state[i], key[round * 4 + i])
    end
  end
  function private.doRound(origState, dstState)
    dstState[0] = bit.bxor(bit.bxor(bit.bxor(private.table0[util.getByte(origState[0], 3)], private.table1[util.getByte(origState[1], 2)]), private.table2[util.getByte(origState[2], 1)]), private.table3[util.getByte(origState[3], 0)])
    dstState[1] = bit.bxor(bit.bxor(bit.bxor(private.table0[util.getByte(origState[1], 3)], private.table1[util.getByte(origState[2], 2)]), private.table2[util.getByte(origState[3], 1)]), private.table3[util.getByte(origState[0], 0)])
    dstState[2] = bit.bxor(bit.bxor(bit.bxor(private.table0[util.getByte(origState[2], 3)], private.table1[util.getByte(origState[3], 2)]), private.table2[util.getByte(origState[0], 1)]), private.table3[util.getByte(origState[1], 0)])
    dstState[3] = bit.bxor(bit.bxor(bit.bxor(private.table0[util.getByte(origState[3], 3)], private.table1[util.getByte(origState[0], 2)]), private.table2[util.getByte(origState[1], 1)]), private.table3[util.getByte(origState[2], 0)])
  end
  function private.doLastRound(origState, dstState)
    dstState[0] = util.putByte(private.SBox[util.getByte(origState[0], 3)], 3) + util.putByte(private.SBox[util.getByte(origState[1], 2)], 2) + util.putByte(private.SBox[util.getByte(origState[2], 1)], 1) + util.putByte(private.SBox[util.getByte(origState[3], 0)], 0)
    dstState[1] = util.putByte(private.SBox[util.getByte(origState[1], 3)], 3) + util.putByte(private.SBox[util.getByte(origState[2], 2)], 2) + util.putByte(private.SBox[util.getByte(origState[3], 1)], 1) + util.putByte(private.SBox[util.getByte(origState[0], 0)], 0)
    dstState[2] = util.putByte(private.SBox[util.getByte(origState[2], 3)], 3) + util.putByte(private.SBox[util.getByte(origState[3], 2)], 2) + util.putByte(private.SBox[util.getByte(origState[0], 1)], 1) + util.putByte(private.SBox[util.getByte(origState[1], 0)], 0)
    dstState[3] = util.putByte(private.SBox[util.getByte(origState[3], 3)], 3) + util.putByte(private.SBox[util.getByte(origState[0], 2)], 2) + util.putByte(private.SBox[util.getByte(origState[1], 1)], 1) + util.putByte(private.SBox[util.getByte(origState[2], 0)], 0)
  end
  function private.doInvRound(origState, dstState)
    dstState[0] = bit.bxor(bit.bxor(bit.bxor(private.tableInv0[util.getByte(origState[0], 3)], private.tableInv1[util.getByte(origState[3], 2)]), private.tableInv2[util.getByte(origState[2], 1)]), private.tableInv3[util.getByte(origState[1], 0)])
    dstState[1] = bit.bxor(bit.bxor(bit.bxor(private.tableInv0[util.getByte(origState[1], 3)], private.tableInv1[util.getByte(origState[0], 2)]), private.tableInv2[util.getByte(origState[3], 1)]), private.tableInv3[util.getByte(origState[2], 0)])
    dstState[2] = bit.bxor(bit.bxor(bit.bxor(private.tableInv0[util.getByte(origState[2], 3)], private.tableInv1[util.getByte(origState[1], 2)]), private.tableInv2[util.getByte(origState[0], 1)]), private.tableInv3[util.getByte(origState[3], 0)])
    dstState[3] = bit.bxor(bit.bxor(bit.bxor(private.tableInv0[util.getByte(origState[3], 3)], private.tableInv1[util.getByte(origState[2], 2)]), private.tableInv2[util.getByte(origState[1], 1)]), private.tableInv3[util.getByte(origState[0], 0)])
  end
  function private.doInvLastRound(origState, dstState)
    dstState[0] = util.putByte(private.iSBox[util.getByte(origState[0], 3)], 3) + util.putByte(private.iSBox[util.getByte(origState[3], 2)], 2) + util.putByte(private.iSBox[util.getByte(origState[2], 1)], 1) + util.putByte(private.iSBox[util.getByte(origState[1], 0)], 0)
    dstState[1] = util.putByte(private.iSBox[util.getByte(origState[1], 3)], 3) + util.putByte(private.iSBox[util.getByte(origState[0], 2)], 2) + util.putByte(private.iSBox[util.getByte(origState[3], 1)], 1) + util.putByte(private.iSBox[util.getByte(origState[2], 0)], 0)
    dstState[2] = util.putByte(private.iSBox[util.getByte(origState[2], 3)], 3) + util.putByte(private.iSBox[util.getByte(origState[1], 2)], 2) + util.putByte(private.iSBox[util.getByte(origState[0], 1)], 1) + util.putByte(private.iSBox[util.getByte(origState[3], 0)], 0)
    dstState[3] = util.putByte(private.iSBox[util.getByte(origState[3], 3)], 3) + util.putByte(private.iSBox[util.getByte(origState[2], 2)], 2) + util.putByte(private.iSBox[util.getByte(origState[1], 1)], 1) + util.putByte(private.iSBox[util.getByte(origState[0], 0)], 0)
  end
  function public.encrypt(key, input, inputOffset, output, outputOffset)
    inputOffset = inputOffset or 1
    output = output or {}
    outputOffset = outputOffset or 1
    local state = {}
    local tmpState = {}
    if key[public.KEY_TYPE] ~= public.ENCRYPTION_KEY then
      print("No encryption key: ", key[public.KEY_TYPE])
      return
    end
    state = util.bytesToInts(input, inputOffset, 4)
    private.addRoundKey(state, key, 0)
    local round = 1
    while round < key[public.ROUNDS] - 1 do
      private.doRound(state, tmpState)
      private.addRoundKey(tmpState, key, round)
      round = round + 1
      private.doRound(tmpState, state)
      private.addRoundKey(state, key, round)
      round = round + 1
    end
    private.doRound(state, tmpState)
    private.addRoundKey(tmpState, key, round)
    round = round + 1
    private.doLastRound(tmpState, state)
    private.addRoundKey(state, key, round)
    return util.intsToBytes(state, output, outputOffset)
  end
  function public.decrypt(key, input, inputOffset, output, outputOffset)
    inputOffset = inputOffset or 1
    output = output or {}
    outputOffset = outputOffset or 1
    local state = {}
    local tmpState = {}
    if key[public.KEY_TYPE] ~= public.DECRYPTION_KEY then
      print("No decryption key: ", key[public.KEY_TYPE])
      return
    end
    state = util.bytesToInts(input, inputOffset, 4)
    private.addRoundKey(state, key, key[public.ROUNDS])
    local round = key[public.ROUNDS] - 1
    while round > 2 do
      private.doInvRound(state, tmpState)
      private.addRoundKey(tmpState, key, round)
      round = round - 1
      private.doInvRound(tmpState, state)
      private.addRoundKey(state, key, round)
      round = round - 1
    end
    private.doInvRound(state, tmpState)
    private.addRoundKey(tmpState, key, round)
    round = round - 1
    private.doInvLastRound(tmpState, state)
    private.addRoundKey(state, key, round)
    return util.intsToBytes(state, output, outputOffset)
  end
  private.calcSBox()
  private.calcRoundTables()
  private.calcInvRoundTables()
  return public
end
package.preload["photon.core.internal.crypto.aeslua.gf"] = function(...)
  local bit = require("photon.common.util.bit.numberlua").bit
  local private = {}
  local public = {}
  private.n = 256
  private.ord = 255
  private.irrPolynom = 283
  private.exp = {}
  private.log = {}
  function public.add(operand1, operand2)
    return bit.bxor(operand1, operand2)
  end
  function public.sub(operand1, operand2)
    return bit.bxor(operand1, operand2)
  end
  function public.invert(operand)
    if operand == 1 then
      return 1
    end
    local exponent = private.ord - private.log[operand]
    return private.exp[exponent]
  end
  function public.mul(operand1, operand2)
    if operand1 == 0 or operand2 == 0 then
      return 0
    end
    local exponent = private.log[operand1] + private.log[operand2]
    if exponent >= private.ord then
      exponent = exponent - private.ord
    end
    return private.exp[exponent]
  end
  function public.div(operand1, operand2)
    if operand1 == 0 then
      return 0
    end
    local exponent = private.log[operand1] - private.log[operand2]
    if exponent < 0 then
      exponent = exponent + private.ord
    end
    return private.exp[exponent]
  end
  function public.printLog()
    for i = 1, private.n do
      print("log(", i - 1, ")=", private.log[i - 1])
    end
  end
  function public.printExp()
    for i = 1, private.n do
      print("exp(", i - 1, ")=", private.exp[i - 1])
    end
  end
  function private.initMulTable()
    local a = 1
    for i = 0, private.ord - 1 do
      private.exp[i] = a
      private.log[a] = i
      a = bit.bxor(bit.lshift(a, 1), a)
      if a > private.ord then
        a = public.sub(a, private.irrPolynom)
      end
    end
  end
  private.initMulTable()
  return public
end
package.preload["photon.core.internal.crypto.aeslua.util"] = function(...)
  local bit = require("photon.common.util.bit.numberlua").bit
  local public = {}
  local private = {}
  function public.byteParity(byte)
    byte = bit.bxor(byte, bit.rshift(byte, 4))
    byte = bit.bxor(byte, bit.rshift(byte, 2))
    byte = bit.bxor(byte, bit.rshift(byte, 1))
    return bit.band(byte, 1)
  end
  function public.getByte(number, index)
    if index == 0 then
      return bit.band(number, 255)
    else
      return bit.band(bit.rshift(number, index * 8), 255)
    end
  end
  function public.putByte(number, index)
    if index == 0 then
      return bit.band(number, 255)
    else
      return bit.lshift(bit.band(number, 255), index * 8)
    end
  end
  function public.bytesToInts(bytes, start, n)
    local ints = {}
    for i = 0, n - 1 do
      ints[i] = public.putByte(bytes[start + i * 4], 3) + public.putByte(bytes[start + i * 4 + 1], 2) + public.putByte(bytes[start + i * 4 + 2], 1) + public.putByte(bytes[start + i * 4 + 3], 0)
    end
    return ints
  end
  function public.intsToBytes(ints, output, outputOffset, n)
    n = n or #ints
    for i = 0, n do
      for j = 0, 3 do
        output[outputOffset + i * 4 + (3 - j)] = public.getByte(ints[i], j)
      end
    end
    return output
  end
  function private.bytesToHex(bytes)
    local hexBytes = ""
    for i, byte in ipairs(bytes) do
      hexBytes = hexBytes .. string.format("%02x ", byte)
    end
    return hexBytes
  end
  function public.toHexString(data)
    local type = type(data)
    if type == "number" then
      return string.format("%08x", data)
    elseif type == "table" then
      return private.bytesToHex(data)
    elseif type == "string" then
      local bytes = {
        string.byte(data, 1, #data)
      }
      return private.bytesToHex(bytes)
    else
      return data
    end
  end
  function public.padByteString(data)
    local dataLength = #data
    local random1 = math.random(0, 255)
    local random2 = math.random(0, 255)
    local prefix = string.char(random1, random2, random1, random2, public.getByte(dataLength, 3), public.getByte(dataLength, 2), public.getByte(dataLength, 1), public.getByte(dataLength, 0))
    data = prefix .. data
    local paddingLength = math.ceil(#data / 16) * 16 - #data
    local padding = ""
    for i = 1, paddingLength do
      padding = padding .. string.char(math.random(0, 255))
    end
    return data .. padding
  end
  function private.properlyDecrypted(data)
    local random = {
      string.byte(data, 1, 4)
    }
    if random[1] == random[3] and random[2] == random[4] then
      return true
    end
    return false
  end
  function public.unpadByteString(data)
    if not private.properlyDecrypted(data) then
      return nil
    end
    local dataLength = public.putByte(string.byte(data, 5), 3) + public.putByte(string.byte(data, 6), 2) + public.putByte(string.byte(data, 7), 1) + public.putByte(string.byte(data, 8), 0)
    return string.sub(data, 9, 8 + dataLength)
  end
  function public.xorIV(data, iv)
    for i = 1, 16 do
      data[i] = bit.bxor(data[i], iv[i])
    end
  end
  return public
end
package.preload["photon.core.internal.crypto.bigint"] = function(...)
  local digitsStr = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_ = !@#$%^&*()[]{}|:, . <  > /?`~ \\'\" + -"
  local bpe = 15
  local mask = math.pow(2, bpe) - 1
  local radix = mask + 1
  local _T = function(x)
    return "BI: [" .. table.concat(x, " ") .. "]"
  end
  local function _P(x)
    print(_T(x))
  end
  local halfRadix = math.floor(radix / 2)
  local OneLShiftBpe = math.pow(2, bpe)
  local OneLShiftBpeMin1 = math.pow(2, bpe - 1)
  local newArray = function(n)
    local a = {}
    for i = 1, n do
      table.insert(a, 0)
    end
    return a
  end
  local rshift = function(x, n)
    return math.floor(x / math.pow(2, n))
  end
  local rshift1 = function(x)
    return math.floor(x / 2)
  end
  local lshift = function(x, n)
    return x * math.pow(2, n)
  end
  local function rshiftBpe(x)
    return math.floor(x / OneLShiftBpe)
  end
  local function lshiftBpeMin1(x)
    return x * OneLShiftBpeMin1
  end
  local function testbit(x, n)
    return rshift(x, n) % 2 == 1
  end
  local function applyMask(x)
    return x % OneLShiftBpe
  end
  local function copyInt_(x, n)
    local c = n
    local i = 0
    while c ~= 0 do
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
      i = i + 1
    end
  end
  local function int2bigInt(t, bits, minSize)
    bits = bits or 0
    minSize = minSize or 0
    local i, k
    k = math.ceil(bits / bpe) + 1
    k = math.max(minSize, k)
    local buff = newArray(k)
    copyInt_(buff, t)
    return buff
  end
  local copy_ = function(x, y)
    local i
    local k = math.min(#x, #y)
    for i = 0, k - 1 do
      x[i + 1] = y[i + 1]
    end
    for i = k, #x - 1 do
      x[i + 1] = 0
    end
  end
  local function expand(x, n)
    local ans = int2bigInt(0, math.max(#x, n) * bpe, 0)
    copy_(ans, x)
    return ans
  end
  local function trim(x, k)
    local y
    local i = #x
    while i > 0 and x[i - 1 + 1] == 0 do
      i = i - 1
    end
    y = newArray(i + k)
    copy_(y, x)
    return y
  end
  local inverseModInt = function(x, n)
    local a = 1
    local b = 0
    while true do
      if x == 1 then
        return a
      end
      if x == 0 then
        return 0
      end
      b = b - a * math.floor(n / x)
      n = n % x
      if n == 1 then
        return b
      end
      if n == 0 then
        return 0
      end
      a = a - b * math.floor(x / n)
      x = x % n
    end
  end
  local function inverseModInt_(x, n)
    return inverseModInt(x, n)
  end
  local function negative(x)
    return testbit(x[#x - 1 + 1], bpe - 1)
  end
  local greaterShift = function(x, y, shift)
    local kx = #x
    local ky = #y
    local k = math.min(kx + shift, ky)
    local i = ky - 1 - shift
    while kx > i and i >= 0 do
      if x[i + 1] > 0 then
        return true
      end
      i = i + 1
    end
    i = kx - 1 + shift
    while ky > i do
      if y[i + 1] > 0 then
        return false
      end
      i = i + 1
    end
    i = k - 1
    while shift <= i do
      if x[i - shift + 1] > y[i + 1] then
        return true
      elseif x[i - shift + 1] < y[i + 1] then
        return false
      end
      i = i - 1
    end
    return false
  end
  local greater = function(x, y)
    local i
    local k = math.min(#x, #y)
    for i = #x, #y - 1 do
      if y[i + 1] ~= 0 then
        return false
      end
    end
    for i = #y, #x - 1 do
      if x[i + 1] ~= 0 then
        return true
      end
    end
    for i = k - 1, 0, -1 do
      if x[i + 1] > y[i + 1] then
        return 1
      elseif x[i + 1] < y[i + 1] then
        return false
      end
    end
    return false
  end
  local function rightShift_(x, n)
    local k = math.floor(n / bpe)
    if k ~= 0 then
      local i = 0
      while i < #x - k do
        x[i + 1] = x[i + k + 1]
        i = i + 1
      end
      while i < #x do
        x[i + 1] = 0
        i = i + 1
      end
      n = n % bpe
    end
    local i = 0
    while i < #x - 1 do
      x[i + 1] = applyMask(lshift(x[i + 1 + 1], bpe - n) + rshift(x[i + 1], n))
      i = i + 1
    end
    x[i + 1] = rshift(x[i + 1], n)
  end
  local function leftShift_(x, n)
    local k = math.floor(n / bpe)
    if k ~= 0 then
      local i = #x
      while k <= i do
        x[i + 1] = x[i - k + 1]
        i = i - 1
      end
      while i >= 0 do
        x[i + 1] = 0
        i = i - 1
      end
      n = n % bpe
    end
    if n == 0 then
      return
    end
    local i = #x - 1
    while i > 0 do
      x[i + 1] = applyMask(lshift(x[i + 1], n) + rshift(x[i - 1 + 1], bpe - n))
      i = i - 1
    end
    x[i + 1] = applyMask(lshift(x[i + 1], n))
  end
  local function multInt_(x, n)
    if n == 0 then
      return
    end
    local k = #x
    local c = 0
    for i = 0, k - 1 do
      c = c + x[i + 1] * n
      local b = 0
      if c < 0 then
        b = b - rshiftBpe(c)
        c = c + b * radix
      end
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c) - b
    end
  end
  local function divInt_(x, n)
    local r = 0
    for i = #x - 1, 0, -1 do
      local s = r * radix + x[i + 1]
      x[i + 1] = math.floor(s / n)
      r = s % n
    end
    return r
  end
  local function linCombShift_(x, y, b, ys)
    local k = math.min(#x, ys + #y)
    local kk = #x
    local c = 0
    for i = ys, k - 1 do
      c = c + x[i + 1] + b * y[i - ys + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
    end
    local i = k
    while c ~= 0 and kk > i do
      c = c + x[i + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
      i = i + 1
    end
  end
  local function addShift_(x, y, ys)
    local k = math.min(#x, ys + #y)
    local kk = #x
    local c = 0
    for i = ys, k - 1 do
      c = c + x[i + 1] + y[i - ys + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
    end
    local i = k
    while c ~= 0 and kk > i do
      c = c + x[i + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
      i = i + 1
    end
  end
  local function subShift_(x, y, ys)
    local k = math.min(#x, ys + #y)
    local kk = #x
    local c = 0
    for i = ys, k - 1 do
      c = c + x[i + 1] - y[i - ys + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
    end
    local i = k
    while c ~= 0 and kk > i do
      c = c + x[i + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
      i = i + 1
    end
  end
  local function sub_(x, y)
    local k = math.min(#x, #y)
    local c = 0
    for i = 0, k - 1 do
      c = c + x[i + 1] - y[i + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
    end
    local i = k
    while c ~= 0 and i < #x do
      c = c + x[i + 1]
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c)
      i = i + 1
    end
  end
  local function divide_(x, y, q, r)
    copy_(r, x)
    local ky = #y
    while y[ky - 1 + 1] == 0 do
      ky = ky - 1
    end
    local a = 0
    local b = y[ky - 1 + 1]
    while b ~= 0 do
      b = rshift1(b)
      a = a + 1
    end
    a = bpe - a
    leftShift_(y, a)
    leftShift_(r, a)
    local kx = #r
    while r[kx - 1 + 1] == 0 and ky < kx do
      kx = kx - 1
    end
    copyInt_(q, 0)
    while not greaterShift(y, r, kx - ky) do
      subShift_(r, y, kx - ky)
      q[kx - ky + 1] = q[kx - ky + 1] + 1
    end
    for i = kx - 1, ky, -1 do
      if r[i + 1] == y[ky - 1 + 1] then
        q[i - ky + 1] = mask
      else
        q[i - ky + 1] = math.floor((r[i + 1] * radix + r[i - 1 + 1]) / y[ky - 1 + 1])
      end
      while true do
        local y2 = 0
        if ky > 1 then
          y2 = y[ky - 2 + 1] * q[i - ky + 1]
        end
        local c = rshiftBpe(y2)
        y2 = applyMask(y2)
        local y1 = c + q[i - ky + 1] * y[ky - 1 + 1]
        c = rshiftBpe(y1)
        y1 = applyMask(y1)
        local cond
        if c == r[i + 1] then
          if y1 == r[i - 1 + 1] then
            local tmp = 0
            if i > 1 then
              tmp = r[i - 2 + 1]
            end
            cond = y2 > tmp
          else
            cond = y1 > r[i - 1 + 1]
          end
        else
          cond = c > r[i + 1]
        end
        if cond then
          q[i - ky + 1] = q[i - ky + 1] - 1
        else
          break
        end
      end
      linCombShift_(r, y, -q[i - ky + 1], i - ky)
      if negative(r) then
        addShift_(r, y, i - ky)
        q[i - ky + 1] = q[i - ky + 1] - 1
      end
    end
    rightShift_(y, a)
    rightShift_(r, a)
  end
  local function modInt(x, n)
    local c = 0
    for i = #x - 1, 0, -1 do
      c = (c * radix + x[i + 1]) % n
    end
    return c
  end
  local function addInt_(x, n)
    x[1] = x[1] + n
    local k = #x
    local c = 0
    for i = 0, k - 1 do
      c = c + x[i + 1]
      local b = 0
      if c < 0 then
        b = -rshiftBpe(c)
        c = c + b * radix
      end
      x[i + 1] = applyMask(c)
      c = rshiftBpe(c) - b
      if c == 0 then
        return
      end
    end
  end
  local function str2bigInt(s, base, minSize)
    minSize = minSize or 0
    local k = #s
    local x = int2bigInt(0, base * k, 0)
    if type(s) == "string" then
      for i = 1, k do
        local d = string.find(digitsStr, s:sub(i):sub(1, 1)) - 1
        if base <= 36 and d >= 36 then
          d = d - 26
        end
        if base <= d or d < 0 then
          break
        end
        multInt_(x, base)
        addInt_(x, d)
      end
    elseif type(s) == "table" then
      for i = 0, k - 1 do
        multInt_(x, base)
        addInt_(x, s[i + 1])
      end
    else
      error("str2bigInt: input datra must be string or table")
    end
    k = #x
    while k > 0 and x[k - 1 + 1] == 0 do
      k = k - 1
    end
    k = math.max(minSize, k + 1)
    local y = newArray(k)
    local kk = math.min(k, #x)
    local i = 0
    while kk > i do
      y[i + 1] = x[i + 1]
      i = i + 1
    end
    while k > i do
      y[i + 1] = 0
      i = i + 1
    end
    return y
  end
  local isZero = function(x)
    local i
    for i = 0, #x - 1 do
      if x[i + 1] ~= 0 then
        return false
      end
    end
    return true
  end
  local function dup(x)
    local i
    local buff = newArray(#x)
    copy_(buff, x)
    return buff
  end
  local function bigInt2str(x, base)
    local s = ""
    if base == nil or base == -1 then
      for i = #x - 1, 1, -1 do
        s = s .. x[i + 1] .. ", "
      end
      s = s .. x[1]
    else
      local s6 = dup(x)
      while not isZero(s6) do
        local t = divInt_(s6, base)
        s = digitsStr:sub(t + 1, t + 1) .. s
      end
    end
    if #s == 0 then
      s = "0"
    end
    return s
  end
  local function _S(x)
    return bigInt2str(x, 10)
  end
  local function bigInt2table(x, base)
    local s = {}
    if base == nil or base == -1 then
      for i = 0, #x - 1 do
        s[i + 1] = x[i + 1]
      end
    else
      local s6 = dup(x)
      local tmp = {}
      while not isZero(s6) do
        local t = divInt_(s6, base)
        table.insert(tmp, t)
      end
      for i, v in ipairs(tmp) do
        s[i] = tmp[#tmp + 1 - i]
      end
    end
    return s
  end
  local function mod_(x, n)
    local s4 = dup(x)
    local s5 = dup(x)
    divide_(s4, n, s5, x)
  end
  local function multMod_(x, y, n)
    local i
    local s0 = newArray(2 * #x)
    copyInt_(s0, 0)
    for i = 0, #y - 1 do
      if y[i + 1] ~= 0 then
        linCombShift_(s0, x, y[i + 1], i)
      end
    end
    mod_(s0, n)
    copy_(x, s0)
  end
  local function mont_(x, y, n, np)
    local kn = #n
    local ky = #y
    local sa = newArray(kn)
    copyInt_(sa, 0)
    while kn > 0 and n[kn - 1 + 1] == 0 do
      kn = kn - 1
    end
    while ky > 0 and y[ky - 1 + 1] == 0 do
      ky = ky - 1
    end
    local ks = #sa - 1
    for i = 0, kn - 1 do
      local t = sa[1] + x[i + 1] * y[1]
      local ui = applyMask(applyMask(t) * np)
      local c = rshiftBpe(t + ui * n[1])
      t = x[i + 1]
      local j = 1
      while j < ky - 4 do
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
      end
      while ky > j do
        c = c + sa[j + 1] + ui * n[j + 1] + t * y[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
      end
      while j < kn - 4 do
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
      end
      while kn > j do
        c = c + sa[j + 1] + ui * n[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
      end
      while ks > j do
        c = c + sa[j + 1]
        sa[j - 1 + 1] = applyMask(c)
        c = rshiftBpe(c)
        j = j + 1
      end
      sa[j - 1 + 1] = applyMask(c)
    end
    if not greater(n, sa) then
      sub_(sa, n)
    end
    copy_(x, sa)
  end
  local one = int2bigInt(1, 1, 1)
  local function powMod_(x, y, n)
    local s7 = dup(n)
    if n[1] % 2 == 0 then
      error("powMod: even modules not supported")
    end
    copyInt_(s7, 0)
    local kn = #n
    while kn > 0 and n[kn - 1 + 1] == 0 do
      kn = kn - 1
    end
    local np = radix - inverseModInt(modInt(n, radix), radix)
    s7[kn + 1] = 1
    multMod_(x, s7, n)
    local s3 = dup(x)
    local k1 = #y - 1
    while k1 > 0 and y[k1 + 1] == 0 do
      k1 = k1 - 1
    end
    if y[k1 + 1] == 0 then
      copyInt_(x, 1)
      return
    end
    local k2 = bpe - 1
    while k2 > 0 and not testbit(y[k1 + 1], k2) do
      k2 = k2 - 1
    end
    while true do
      k2 = k2 - 1
      if k2 == -1 then
        k1 = k1 - 1
        if k1 < 0 then
          mont_(x, one, n, np)
          return
        end
        k2 = bpe - 1
      end
      mont_(x, x, n, np)
      if testbit(y[k1 + 1], k2) then
        mont_(x, s3, n, np)
      end
    end
  end
  local function powMod(x, y, n)
    local ans = expand(x, #n)
    powMod_(ans, trim(y, 2), trim(n, 2), 0)
    return trim(ans, 1)
  end
  return {
    int2bigInt = int2bigInt,
    str2bigInt = str2bigInt,
    table2bigInt = str2bigInt,
    bigInt2str = bigInt2str,
    bigInt2table = bigInt2table,
    powMod = powMod
  }
end
package.preload["photon.core.internal.crypto.encryption"] = function(...)
  local aes = require("photon.core.internal.crypto.aeslua.aes")
  local bit = require("photon.common.util.bit.numberlua").bit
  local function _xor(value1, offset1, value2, offset2, length, result)
    local ch1, ch2
    for i = 0, 15 do
      if length < i + 1 then
        ch1 = 16 - length
      else
        ch1 = value1[i + offset1 + 1]
      end
      ch2 = value2[i + offset2 + 1]
      result[i + 1] = bit.bxor(ch1, ch2)
    end
  end
  local function encrypt(key, plainData)
    local keySched = aes.expandEncryptionKey(key)
    local plainDataSize = #plainData
    local blockCount = math.ceil((plainDataSize + 1) / 16)
    local encodedDataSize = blockCount * 16
    local outbuf = {}
    local buf = {}
    for i = 0, blockCount - 1 do
      local currentLength = plainDataSize - i * 16
      for i = 1, 16 do
        buf[i] = 0
      end
      if i > 0 then
        _xor(plainData, i * 16, outbuf, (i - 1) * 16, currentLength, buf)
      else
        local l = math.min(currentLength, 16)
        for i = 1, l do
          buf[i] = plainData[i]
        end
      end
      aes.encrypt(keySched, buf, 1, outbuf, i * 16 + 1)
    end
    return outbuf
  end
  local padding = function(data, dataSize)
    local padding = data[dataSize]
    if padding > 16 then
      return 0
    end
    for i = 0, padding - 1 do
      if data[dataSize - i] ~= padding then
        return 0
      end
    end
    return padding
  end
  local function decrypt(key, encodedData, offset)
    offset = offset or 0
    local encodedDataSize = #encodedData - offset
    local keySched = aes.expandDecryptionKey(key)
    local blockCount = math.ceil(encodedDataSize / 16)
    local buf = {}
    local plainData = {}
    for i = 0, blockCount - 1 do
      aes.decrypt(keySched, encodedData, offset + i * 16 + 1, buf, 1)
      if i > 0 then
        _xor(buf, 0, encodedData, offset + (i - 1) * 16, 16, buf)
      end
      for j = 1, 16 do
        plainData[i * 16 + j] = buf[j]
      end
    end
    local pad = padding(plainData, encodedDataSize)
    for i = encodedDataSize - pad + 1, encodedDataSize do
      plainData[i] = nil
    end
    return plainData
  end
  local sha2 = require("photon.core.internal.crypto.sha2")
  local bigint = require("photon.core.internal.crypto.bigint")
  local OakleyPrime768 = {
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    201,
    15,
    218,
    162,
    33,
    104,
    194,
    52,
    196,
    198,
    98,
    139,
    128,
    220,
    28,
    209,
    41,
    2,
    78,
    8,
    138,
    103,
    204,
    116,
    2,
    11,
    190,
    166,
    59,
    19,
    155,
    34,
    81,
    74,
    8,
    121,
    142,
    52,
    4,
    221,
    239,
    149,
    25,
    179,
    205,
    58,
    67,
    27,
    48,
    43,
    10,
    109,
    242,
    95,
    20,
    55,
    79,
    225,
    53,
    109,
    109,
    81,
    194,
    69,
    228,
    133,
    181,
    118,
    98,
    94,
    126,
    198,
    244,
    76,
    66,
    233,
    166,
    58,
    54,
    32,
    255,
    255,
    255,
    255,
    255,
    255,
    255,
    255
  }
  local OakleyPrime768BigInt = bigint.table2bigInt(OakleyPrime768, 256)
  local function generateKeys()
    local cg = bigint.int2bigInt(22)
    local result = false
    math.randomseed(1000000000 * (math.sin(require("socket").gettime() * 10000) + 1))
    local rnd = {}
    for i = 1, 20 do
      rnd[i] = math.floor(math.random(0, 255))
    end
    local secretKey = bigint.table2bigInt(rnd, 256)
    local publicKey = bigint.powMod(cg, secretKey, OakleyPrime768BigInt)
    local publicKeyBytes = bigint.bigInt2table(publicKey, 256)
    return secretKey, publicKeyBytes
  end
  local function deriveSharedKey(secretKey, serverPublicKey)
    local spk = bigint.table2bigInt(serverPublicKey, 256)
    local sk = bigint.powMod(spk, secretKey, OakleyPrime768BigInt)
    local skBytes = bigint.bigInt2table(sk, 256)
    return sha2.hash256(skBytes)
  end
  return {
    encrypt = encrypt,
    decrypt = decrypt,
    generateKeys = generateKeys,
    deriveSharedKey = deriveSharedKey
  }
end
package.preload["photon.core.internal.crypto.sha2"] = function(...)
  local bit32 = require("photon.common.util.bit.numberlua").bit32
  local band, rrotate, bxor, rshift, bnot = bit32.band, bit32.rrotate, bit32.bxor, bit32.rshift, bit32.bnot
  local string, setmetatable, assert = string, setmetatable, assert
  local k = {
    1116352408,
    1899447441,
    3049323471,
    3921009573,
    961987163,
    1508970993,
    2453635748,
    2870763221,
    3624381080,
    310598401,
    607225278,
    1426881987,
    1925078388,
    2162078206,
    2614888103,
    3248222580,
    3835390401,
    4022224774,
    264347078,
    604807628,
    770255983,
    1249150122,
    1555081692,
    1996064986,
    2554220882,
    2821834349,
    2952996808,
    3210313671,
    3336571891,
    3584528711,
    113926993,
    338241895,
    666307205,
    773529912,
    1294757372,
    1396182291,
    1695183700,
    1986661051,
    2177026350,
    2456956037,
    2730485921,
    2820302411,
    3259730800,
    3345764771,
    3516065817,
    3600352804,
    4094571909,
    275423344,
    430227734,
    506948616,
    659060556,
    883997877,
    958139571,
    1322822218,
    1537002063,
    1747873779,
    1955562222,
    2024104815,
    2227730452,
    2361852424,
    2428436474,
    2756734187,
    3204031479,
    3329325298
  }
  local function str2hexa(s)
    local h = string.gsub(s, ".", function(c)
      return string.format("%02x", string.byte(c))
    end)
    return h
  end
  local function num2s(l, n)
    local s = ""
    for i = 1, n do
      local rem = l % 256
      s = string.char(rem) .. s
      l = (l - rem) / 256
    end
    return s
  end
  local num2bytes = function(n, bytes, i0, i1)
    local inc = 1
    if i1 < i0 then
      inc = -1
    end
    for i = i0, i1, inc do
      local rem = n % 256
      bytes[i] = rem
      n = (n - rem) / 256
    end
  end
  local function s232num(s, i)
    local n = 0
    for i = i, i + 3 do
      n = n * 256 + string.byte(s, i)
    end
    return n
  end
  local bytes2num = function(b, i)
    local n = 0
    for i = i, i + 3 do
      n = n * 256 + b[i]
    end
    return n
  end
  local function preproc(msg, len)
    local extra = 64 - (len + 1 + 8) % 64
    if type(msg) == "string" then
      local lenStr = num2s(8 * len, 8)
      msg = msg .. "\128" .. string.rep("\000", extra) .. lenStr
    elseif type(msg) == "table" then
      local res = {}
      for i, v in ipairs(msg) do
        res[i] = v
      end
      msg = res
      table.insert(msg, 128)
      for i = 1, extra do
        table.insert(msg, 0)
      end
      num2bytes(8 * len, msg, #msg + 8, #msg + 1)
    else
      error("required string or table")
    end
    assert(#msg % 64 == 0)
    return msg
  end
  local initH224 = function(H)
    H[1] = 3238371032
    H[2] = 914150663
    H[3] = 812702999
    H[4] = 4144912697
    H[5] = 4290775857
    H[6] = 1750603025
    H[7] = 1694076839
    H[8] = 3204075428
    return H
  end
  local initH256 = function(H)
    H[1] = 1779033703
    H[2] = 3144134277
    H[3] = 1013904242
    H[4] = 2773480762
    H[5] = 1359893119
    H[6] = 2600822924
    H[7] = 528734635
    H[8] = 1541459225
    return H
  end
  local function digestblock(msg, i, H)
    local w = {}
    if type(msg) == "string" then
      for j = 1, 16 do
        w[j] = s232num(msg, i + (j - 1) * 4)
      end
    elseif type(msg) == "table" then
      for j = 1, 16 do
        w[j] = bytes2num(msg, i + (j - 1) * 4)
      end
    else
      error("required string or table")
    end
    for j = 17, 64 do
      local v = w[j - 15]
      local s0 = bxor(rrotate(v, 7), rrotate(v, 18), rshift(v, 3))
      v = w[j - 2]
      local s1 = bxor(rrotate(v, 17), rrotate(v, 19), rshift(v, 10))
      w[j] = w[j - 16] + s0 + w[j - 7] + s1
    end
    local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
    for i = 1, 64 do
      local s0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
      local maj = bxor(band(a, b), band(a, c), band(b, c))
      local t2 = s0 + maj
      local s1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
      local ch = bxor(band(e, f), band(bnot(e), g))
      local t1 = h + s1 + ch + k[i] + w[i]
      h = g
      g = f
      f = e
      e = d + t1
      d = c
      c = b
      b = a
      a = t1 + t2
    end
    H[1] = band(H[1] + a)
    H[2] = band(H[2] + b)
    H[3] = band(H[3] + c)
    H[4] = band(H[4] + d)
    H[5] = band(H[5] + e)
    H[6] = band(H[6] + f)
    H[7] = band(H[7] + g)
    H[8] = band(H[8] + h)
  end
  local function finalresult224(H)
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) .. num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4))
  end
  local function finalresult256(H)
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) .. num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
  end
  local function finalresultTable256(H)
    local res = {}
    for i = 1, 8 do
      num2bytes(H[i], res, (i - 1) * 4 + 4, (i - 1) * 4 + 1)
    end
    return res
  end
  local HH = {}
  local function hash224(msg)
    msg = preproc(msg, #msg)
    local H = initH224(HH)
    for i = 1, #msg, 64 do
      digestblock(msg, i, H)
    end
    return finalresult224(H)
  end
  local function hash256(msg)
    msg = preproc(msg, #msg)
    local H = initH256(HH)
    for i = 1, #msg, 64 do
      digestblock(msg, i, H)
    end
    if type(msg) == "string" then
      return finalresult256(H)
    elseif type(msg) == "table" then
      return finalresultTable256(H)
    else
      error("required string or table")
    end
  end
  local mt = {}
  local function new256()
    local o = {
      H = initH256({}),
      msg = "",
      len = 0
    }
    setmetatable(o, mt)
    return o
  end
  mt.__index = mt
  function mt:add(m)
    self.msg = self.msg .. m
    self.len = self.len + #m
    local t = 0
    while #self.msg - t >= 64 do
      digestblock(self.msg, t + 1, self.H)
      t = t + 64
    end
    self.msg = self.msg:sub(t + 1, -1)
  end
  function mt:close()
    self.msg = preproc(self.msg, self.len)
    self:add("")
    return finalresult256(self.H)
  end
  return {
    hash224 = hash224,
    hash256 = hash256,
    new256 = new256
  }
end
package.preload["photon.lite.LitePeer"] = function(...)
  local OperationRequest = require("photon.core.OperationRequest")
  local LiteConstants = require("photon.lite.constants")
  local InternalConstants = require("photon.core.internal.constants")
  local Byte = require("photon.common.type.Byte")
  local Integer = require("photon.common.type.Integer")
  local Array = require("photon.common.type.Array")
  local class = require("photon.common.class")
  local C = class.extend(require("photon.core.PhotonPeer"), "LitePeer")
  function C.proto:opJoin(gameName, gameProperties, actorProperties, broadcastActorProperties)
    self.logger:trace("gameId: ", gameName)
    local result = false
    if gameName and #gameName > 0 then
      local parameters = {}
      parameters[LiteConstants.ParameterCode.GAMEID] = gameName
      if gameProperties and #gameProperties > 0 then
        parameters[LiteConstants.ParameterCode.GAME_PROPERTIES] = gameProperties
      end
      if actorProperties and #actorProperties > 0 then
        parameters[LiteConstants.ParameterCode.ACTOR_PROPERTIES] = actorProperties
      end
      if broadcastActorProperties ~= nil and broadcastActorProperties == true then
        parameters[LiteConstants.ParameterCode.BROADCAST] = broadcastActorProperties
      end
      result = self:opCustom(OperationRequest.new(LiteConstants.OperationCode.JOIN, parameters), true, 0, false)
    else
      self.logger:error("failed: gameID is empty!")
    end
    return result
  end
  function C.proto:opLeave(gameId)
    self.logger:trace("LitePeer:opLeave")
    local parameters = {}
    parameters[LiteConstants.ParameterCode.GAMEID] = gameId
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.LEAVE, {}), true, 0, false)
  end
  function C.proto:opSetPropertiesOfActor(actorNr, properties, broadcast, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.ACTORNR] = actorNr
    parameters[LiteConstants.ParameterCode.PROPERTIES] = properties
    if broadcast then
      parameters[LiteConstants.ParameterCode.BROADCAST] = broadcast
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.SETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opSetPropertiesOfGame(properties, broadcast, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = properties
    if broadcast then
      parameters[LiteConstants.ParameterCode.BROADCAST] = broadcast
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.SETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opGetProperties(channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = InternalConstants.InternalProperties.PROP_GAME_AND_ACTOR
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.GETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opGetPropertiesOfActor(properties, actorNrList, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = InternalConstants.InternalProperties.PROP_ACTOR
    if actorNrList then
      parameters[LiteConstants.ParameterCode.ACTORNR] = actorNrList
    end
    if properties then
      parameters[LiteConstants.ParameterCode.ACTOR_PROPERTIES] = properties
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.GETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opGetPropertiesOfActor(properties, actorNrList, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = InternalConstants.InternalProperties.PROP_ACTOR
    if actorNrList then
      parameters[LiteConstants.ParameterCode.ACTORNR] = actorNrList
    end
    if properties then
      parameters[LiteConstants.ParameterCode.ACTOR_PROPERTIES] = properties
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.GETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opGetPropertiesOfGame(properties, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = InternalConstants.InternalProperties.PROP_GAME
    if properties then
      parameters[LiteConstants.ParameterCode.GAME_PROPERTIES] = properties
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.GETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opGetPropertiesOfGame(properties, channelID)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.PROPERTIES] = InternalConstants.InternalProperties.PROP_GAME
    if properties then
      parameters[LiteConstants.ParameterCode.GAME_PROPERTIES] = properties
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.GETPROPERTIES, parameters), true, channelID, false)
  end
  function C.proto:opRaiseEvent(eventCode, evData, sendReliable, channelID, targetActors, eventCaching, receiverGroup)
    self.logger:trace("opRaiseEvent 3")
    self.logger:trace("evCode: ", eventCode)
    local parameters = {}
    parameters[LiteConstants.ParameterCode.DATA] = evData
    parameters[LiteConstants.ParameterCode.CODE] = Byte.new(eventCode)
    if targetActors then
      Array[Integer].apply(targetActors)
      parameters[LiteConstants.ParameterCode.ACTOR_LIST] = targetActors
    else
      if eventCaching and eventCaching ~= LiteConstants.EventCache.DO_NOT_CACHE then
        parameters[LiteConstants.ParameterCode.CACHE] = Byte.new(eventCaching)
      end
      if receiverGroup and receiverGroup ~= LiteConstants.ReceiverGroup.OTHERS then
        parameters[LiteConstants.ParameterCode.RECEIVER_GROUP] = Byte.new(receiverGroup)
      end
    end
    return self:opCustom(OperationRequest.new(LiteConstants.OperationCode.RAISE_EV, parameters), sendReliable, channelID, false)
  end
  return C
end
package.preload["photon.lite.constants"] = function(...)
  local M = {}
  M.EventCache = {
    DO_NOT_CACHE = 0,
    MERGE_CACHE = 1,
    REPLACE_CACHE = 2,
    REMOVE_CACHE = 3,
    ADD_TO_ROOM_CACHE = 4,
    ADD_TO_ROOM_CACHE_GLOBAL = 5,
    REMOVE_FROM_ROOM_CACHE = 6,
    REMOVE_FROM_ROOM_CACHE_FOR_ACTORS_LEFT = 7
  }
  M.OperationCode = {
    JOIN = 255,
    LEAVE = 254,
    RAISE_EV = 253,
    SETPROPERTIES = 252,
    GETPROPERTIES = 251
  }
  M.ParameterCode = {
    GAMEID = 255,
    ACTORNR = 254,
    TARGET_ACTORNR = 253,
    EMPTY_ROOM_LIVE_TIME = 236,
    ACTOR_LIST = 252,
    PROPERTIES = 251,
    BROADCAST = 250,
    ACTOR_PROPERTIES = 249,
    GAME_PROPERTIES = 248,
    CACHE = 247,
    RECEIVER_GROUP = 246,
    DATA = 245,
    CODE = 244
  }
  M.ReceiverGroup = {
    OTHERS = 0,
    ALL = 1,
    MASTER_CLIENT = 2
  }
  return M
end
package.preload["photon.loadbalancing.Actor"] = function(...)
  local class = require("photon.common.class")
  local Byte = require("photon.common.type.Byte")
  local Null = require("photon.common.type.Null")
  local Constants = require("photon.loadbalancing.constants")
  local tableutil = require("photon.common.util.tableutil")
  local Actor = class.declare("Actor")
  local instance = Actor.proto
  function Actor:init(name, actorNr, isLocal)
    self.name = name or ""
    self.actorNr = actorNr or -1
    self.isLocal = isLocal or false
    self.customProperties = {}
    self.loadBalancingClient = nil
    self.suspended = false
  end
  function instance:getRoom()
    return self.loadBalancingClient:myRoom()
  end
  function instance:raiseEvent(eventCode, data, options)
    if self.loadBalancingClient then
      self.loadBalancingClient:raiseEvent(eventCode, data, options)
    end
  end
  function instance:setName(name)
    self.name = name
  end
  function instance:onPropertiesChange(changedCustomProps, byClient)
  end
  function instance:getCustomProperty(name)
    return tableutil.deepCopyUntyped(self.customProperties[name])
  end
  function instance:getCustomPropertyOrElse(name, defaultValue)
    return tableutil.deepCopyUntyped(self.customProperties[name]) or defaultValue
  end
  function instance:setCustomProperty(name, value, forward)
    if value == Null then
      value = nil
    end
    self.customProperties[name] = tableutil.deepCopy(value)
    local props = {}
    props[name] = value == nil and Null or value
    if self.loadBalancingClient and self.loadBalancingClient:isJoinedToRoom() then
      self.loadBalancingClient:setPropertiesOfActor(self.actorNr, props, forward)
    end
    self:onPropertiesChange(tableutil.deepCopyUntyped(props), true)
  end
  function instance:setCustomProperties(properties, forward)
    local props = {}
    for name, value in pairs(properties) do
      if value == Null then
        value = nil
      end
      self.customProperties[name] = tableutil.deepCopy(value)
      props[name] = value
    end
    if self.loadBalancingClient and self.loadBalancingClient:isJoinedToRoom() then
      self.loadBalancingClient:setPropertiesOfActor(self.actorNr, props, forward)
    end
    self:onPropertiesChange(tableutil.deepCopyUntyped(props), true)
  end
  function instance:isSuspended()
    return self.suspended
  end
  function instance:_getAllProperties()
    local p = {}
    p[Byte.new(Constants.ActorProperties.PlayerName)] = self.name
    for k, v in pairs(self.customProperties) do
      p[k] = v
    end
    return p
  end
  function instance:_setLBC(lbc)
    self.loadBalancingClient = lbc
  end
  function instance:_updateFromResponse(vals)
    self.actorNr = vals[Constants.ParameterCode.ActorNr]
    local props = vals[Constants.ParameterCode.PlayerProperties]
    if props then
      local name = props[Constants.ActorProperties.PlayerName]
      if name then
        self.name = name
      end
      self:_updateCustomProperties(props)
    end
  end
  function instance:_updateMyActorFromResponse(vals)
    self.actorNr = vals[Constants.ParameterCode.ActorNr]
  end
  function instance:_updateCustomProperties(vals)
    for k, v in pairs(vals) do
      if v == Null then
        v = nil
      end
      self.customProperties[k] = v
    end
    self:onPropertiesChange(vals, false)
  end
  function instance:_setSuspended(s)
    self.suspended = s
  end
  function Actor._getActorNrFromResponse(vals)
    return vals[Constants.ParameterCode.ActorNr]
  end
  return Actor
end
package.preload["photon.loadbalancing.LoadBalancingClient"] = function(...)
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local Integer = require("photon.common.type.Integer")
  local Logger = require("photon.common.Logger")
  local tableutil = require("photon.common.util.tableutil")
  local Actor = require("photon.loadbalancing.Actor")
  local RoomInfo = require("photon.loadbalancing.RoomInfo")
  local Room = require("photon.loadbalancing.Room")
  local Constants = require("photon.loadbalancing.constants")
  local PhotonPeer = require("photon.core.PhotonPeer")
  local function _P(x)
    print(tableutil.toStringReq(x))
  end
  local class = require("photon.common.class")
  local NameServerPeer = class.extend(PhotonPeer, "NameServerPeer")
  local MasterPeer = class.extend(PhotonPeer, "MasterPeer")
  local GamePeer = class.extend(PhotonPeer, "GamePeer")
  local LoadBalancingClient = class.declare("LoadBalancingClient")
  local instance = LoadBalancingClient.proto
  local JoinMode = {
    Default = 0,
    CreateIfNotExists = 1,
    RejoinOnly = 3
  }
  LoadBalancingClient.PeerErrorCode = {
    Ok = 0,
    MasterError = 1001,
    MasterConnectFailed = 1002,
    MasterConnectClosed = 1003,
    MasterTimeout = 1004,
    MasterEncryptionEstablishError = 1005,
    MasterAuthenticationFailed = 1101,
    GameError = 2001,
    GameConnectFailed = 2002,
    GameConnectClosed = 2003,
    GameTimeout = 2004,
    GameEncryptionEstablishError = 2005,
    GameAuthenticationFailed = 2101,
    NameServerError = 3001,
    NameServerConnectFailed = 3002,
    NameServerConnectClosed = 3003,
    NameServerTimeout = 3004,
    NameServerEncryptionEstablishError = 3005,
    NameServerAuthenticationFailed = 3101
  }
  LoadBalancingClient.State = {
    Error = -1,
    Uninitialized = 0,
    ConnectingToNameServer = 1,
    ConnectedToNameServer = 2,
    ConnectingToMasterserver = 3,
    ConnectedToMaster = 4,
    JoinedLobby = 5,
    ConnectingToGameserver = 6,
    ConnectedToGameserver = 7,
    Joined = 8,
    Disconnected = 10
  }
  local validNextState = {
    [LoadBalancingClient.State.Error] = Array.new(LoadBalancingClient.State.ConnectingToMasterserver, LoadBalancingClient.State.ConnectingToNameServer),
    [LoadBalancingClient.State.Uninitialized] = Array.new(LoadBalancingClient.State.ConnectingToMasterserver, LoadBalancingClient.State.ConnectingToNameServer),
    [LoadBalancingClient.State.ConnectedToNameServer] = Array.new(LoadBalancingClient.State.ConnectingToMasterserver),
    [LoadBalancingClient.State.Disconnected] = Array.new(LoadBalancingClient.State.ConnectingToMasterserver, LoadBalancingClient.State.ConnectingToNameServer),
    [LoadBalancingClient.State.ConnectedToMaster] = Array.new(LoadBalancingClient.State.JoinedLobby),
    [LoadBalancingClient.State.JoinedLobby] = Array.new(LoadBalancingClient.State.ConnectingToGameserver),
    [LoadBalancingClient.State.ConnectingToGameserver] = Array.new(LoadBalancingClient.State.ConnectedToGameserver),
    [LoadBalancingClient.State.ConnectedToGameserver] = Array.new(LoadBalancingClient.State.Joined)
  }
  local webFlags = {
    HttpForward = 1,
    SendAuthCookie = 2,
    SendSync = 4,
    SendState = 8
  }
  local checkGroupNumber = function(g)
    return true
  end
  local checkGroupArray = function(groups, groupsName)
    return true
  end
  local function fillCreateRoomOptions(op, options)
    options = options or {}
    local gp = {}
    if options.isOpen ~= nil then
      gp[Byte.new(Constants.GameProperties.IsOpen)] = options.isOpen
    end
    if options.isVisible ~= nil then
      gp[Byte.new(Constants.GameProperties.IsVisible)] = options.isVisible
    end
    if options.maxPlayers and options.maxPlayers > 0 then
      gp[Byte.new(Constants.GameProperties.MaxPlayers)] = options.maxPlayers
    end
    if options.propsListedInLobby then
      gp[Byte.new(Constants.GameProperties.PropsListedInLobby)] = options.propsListedInLobby
    end
    if options.customGameProperties then
      for k, v in pairs(options.customGameProperties) do
        gp[k] = v
      end
    end
    op[Constants.ParameterCode.GameProperties] = gp
    op[Constants.ParameterCode.CleanupCacheOnLeave] = true
    op[Constants.ParameterCode.Broadcast] = true
    if options.emptyRoomLiveTime and options.emptyRoomLiveTime ~= 0 then
      op[Constants.ParameterCode.EmptyRoomTTL] = Integer.new(options.emptyRoomLiveTime)
    end
    if options.suspendedPlayerLiveTime and options.suspendedPlayerLiveTime ~= 0 then
      op[Constants.ParameterCode.PlayerTTL] = Integer.new(options.suspendedPlayerLiveTime)
    end
    op[Constants.ParameterCode.CheckUserOnJoin] = true
    if options.lobbyName then
      op[Constants.ParameterCode.LobbyName] = options.lobbyName
      if options.lobbyType then
        op[Constants.ParameterCode.LobbyType] = Byte.new(options.lobbyType)
      end
    end
  end
  function LoadBalancingClient:init(serverAddress, appId, appVersion, options)
    self.autoJoinLobby = true
    options = options or {}
    if options.encryptedAuthentication == nil then
      options.encryptedAuthentication = true
    end
    local paramObject = serverAddress
    if type(paramObject) == "table" then
      serverAddress = paramObject.serverAddress
      appId = paramObject.appId
      appVersion = paramObject.appVersion
      options.initRoom = paramObject.initRoom
      options.initActor = paramObject.initActor
    end
    assert(type(serverAddress) == "string", "LoadBalancingClient.new(): serverAddress parameter not specified or is not a string")
    assert(type(appId) == "string", "LoadBalancingClient.new(): appId parameter not specified or is not a string")
    assert(type(appVersion) == "string", "LoadBalancingClient.new(): appVersion parameter not specified or is not a string")
    assert(type(options.encryptedAuthentication) == "boolean", "LoadBalancingClient.new(): options.encryptedAuthentication parameter is not a boolean")
    self.masterServerAddress = serverAddress
    self.nameServerAddress = serverAddress
    self.appId = appId
    self.appVersion = appVersion
    if options.initRoom then
      assert(type(options.initRoom) == "function", "LoadBalancingClient.new(): options.initRoom parameter is not a function")
      self.initRoom = options.initRoom
    end
    if options.initActor then
      assert(type(options.initActor) == "function", "LoadBalancingClient.new(): options.initActor parameter is not a function")
      self.initActor = options.initActor
    end
    self.encryptedAuthentication = options.encryptedAuthentication
    self.crcEnabled = options.crcEnabled
    self.connectOptions = {}
    self.createRoomOptions = {}
    self.joinRoomOptions = {}
    self.lowestActorId = 0
    function self:addActor(a)
      self.actors[a.actorNr] = a
      self.currentRoom.playerCount = self:myRoomActorCount()
      if self.lowestActorId == 0 or self.lowestActorId > a.actorNr then
        self.lowestActorId = a.actorNr
      end
    end
    self.logger = Logger.new("LoadBalancingClient")
  end
  function LoadBalancingClient:init2(serverAddress, appId, appVersion)
    assert(self.currentRoom == nil)
    assert(self._myActor == nil)
    self.currentRoom = self:roomFactoryInternal("")
    self._myActor = self:actorFactoryInternal("", -1, true)
    self:_init()
  end
  function instance:_init()
    self.state = LoadBalancingClient.State.Uninitialized
    self.roomInfos = {}
    if self.actors then
      for k, v in pairs(self.actors) do
        self:onActorLeave(v, true)
      end
    end
    self.actors = {}
    self:addActor(self._myActor)
    self.nameServerPeer = nil
    self.masterPeer = nil
    self.gamePeer = nil
  end
  function instance:getGamePeer()
    return self.gamePeer
  end
  function instance:setUserId(userId)
    self.userId = userId
  end
  function instance:getUserId()
    return self.userId
  end
  function instance:service()
    if self.reconnectOnResetPending then
      self.reconnectOnResetPending = nil
      if self.state == LoadBalancingClient.State.Uninitialized then
        self:connect()
      end
    end
    if self.nameServerPeer then
      self.nameServerPeer:service()
    end
    if self.masterPeer then
      self.masterPeer:service()
    end
    if self.gamePeer then
      self.gamePeer:service()
    end
  end
  function instance:onStateChange(state)
  end
  function instance:onError(errorCode, errorMsg)
    self.logger:error("Load Balancing Client Error", errorCode, errorMsg)
  end
  function instance:onOperationResponse(errorCode, errorMsg, code, content)
  end
  function instance:_onOperationResponseInternal(operationResponse)
    self:onOperationResponse(operationResponse.errCode, operationResponse.errMsg, operationResponse.operationCode, operationResponse.parameters)
  end
  function instance:onEvent(code, content, actorNr)
  end
  function instance:_onEventInternal(code, content, actorNr)
    self:onEvent(code, content, actorNr)
  end
  function instance:onRoomList(rooms)
  end
  function instance:onRoomListUpdate(rooms, roomsUpdated, roomsAdded, roomsRemoved)
  end
  function instance:onMyRoomPropertiesChange()
  end
  function instance:onActorPropertiesChange(actor)
  end
  function instance:onJoinRoom(createdByMe)
  end
  function instance:onActorJoin(actor)
  end
  function instance:onActorLeave(actor, cleanup)
  end
  function instance:onActorSuspend(actor)
  end
  function instance:onFindFriendsResult(errorCode, errorMsg, friends)
  end
  function instance:onLobbyStats(errorCode, errorMsg, lobbies)
  end
  function instance:onAppStats(errorCode, errorMsg, stats)
  end
  function instance:onGetRegionsResult(errorCode, errorMsg, regions)
  end
  function instance:onWebRpcResult(errorCode, message, uriPath, resultCode, data)
  end
  function instance:roomFactory(name)
    return Room.new(name)
  end
  function instance:actorFactory(name, actorNr, isLocal)
    return Actor.new(name, actorNr, isLocal)
  end
  function instance:initRoom(room)
  end
  function instance:initActor(actor)
  end
  function instance:myActor()
    return self._myActor
  end
  function instance:myRoom()
    return self.currentRoom
  end
  function instance:myRoomActors()
    return self.actors
  end
  function instance:myRoomMasterActorNr()
    if self:myRoom().masterClientId then
      return self:myRoom().masterClientId
    else
      return self.lowestActorId
    end
  end
  function instance:myRoomActorCount()
    local n = 0
    for _, _ in pairs(self.actors) do
      n = n + 1
    end
    return n
  end
  function instance:roomFactoryInternal(name)
    local r = self:roomFactory(name)
    r:_setLBC(self)
    self:initRoom(r)
    return r
  end
  function instance:actorFactoryInternal(name, actorNr, isLocal)
    local a = self:actorFactory(name, actorNr, isLocal)
    a:_setLBC(self)
    self:initActor(a)
    return a
  end
  function instance:reset(connect)
    self:disconnect()
    self:_init()
    if connect then
      self.reconnectOnResetPending = true
    end
  end
  function instance:setCustomAuthentication(authParameters, authType, authData)
    self.userAuthType = authType or Constants.CustomAuthenticationType.Custom
    self.userAuthParameters = authParameters
    if type(authData) == "table" then
      Array[Byte].apply(authData)
    end
    self.authData = authData
  end
  function instance:connect(options)
    if type(options) == "boolean" then
      options = {keepMasterConnection = options}
    end
    options = options or {}
    if self:checkNextState(LoadBalancingClient.State.ConnectingToMasterserver, true) then
      self:changeState(LoadBalancingClient.State.ConnectingToMasterserver)
      self.logger:info("Connecting to Master", self.masterServerAddress)
      self.connectOptions = {}
      for k, v in pairs(options) do
        self.connectOptions[k] = options[k]
      end
      self.masterPeer = MasterPeer.new(self)
      self.masterPeer:setCrcEnabled(self.crcEnabled)
      self:initMasterPeer(self.masterPeer)
      self.masterPeer:connect(self.masterServerAddress, self.appId)
      return true
    else
      return false
    end
  end
  function instance:connectToNameServer(options)
    options = options or {}
    if self:checkNextState(LoadBalancingClient.State.ConnectingToNameServer, true) then
      self.connectOptions = {}
      for k, v in pairs(options) do
        self.connectOptions[k] = options[k]
      end
      self:changeState(LoadBalancingClient.State.ConnectingToNameServer)
      self.logger:info("Connecting to NameServer", self.nameServerAddress)
      self.nameServerPeer = NameServerPeer.new(self)
      self.nameServerPeer:setCrcEnabled(self.crcEnabled)
      self:initNameServerPeer(self.nameServerPeer)
      self.nameServerPeer:connect(self.nameServerAddress, "NameServer")
      return true
    else
      return false
    end
  end
  function instance:createRoomFromMy(roomName, options)
    self.currentRoom.name = roomName or ""
    options = options or {}
    options.isVisible = self.currentRoom.isVisible
    options.isOpen = self.currentRoom.isOpen
    options.maxPlayers = self.currentRoom.maxPlayers
    options.customGameProperties = tableutil.deepCopy(self.currentRoom.customProperties)
    options.propsListedInLobby = tableutil.deepCopy(self.currentRoom.propsListedInLobby)
    options.emptyRoomLiveTime = self.currentRoom.emptyRoomLiveTime
    options.suspendedPlayerLiveTime = self.currentRoom.suspendedPlayerLiveTime
    self:createRoomInternal(self.masterPeer, options)
  end
  function instance:createRoom(roomName, options)
    self.currentRoom = self:roomFactoryInternal(roomName)
    self:createRoomInternal(self.masterPeer, options)
  end
  function instance:joinRoom(roomName, options, createOptions)
    local op = {}
    if options then
      if options.createIfNotExists then
        op[Constants.ParameterCode.JoinMode] = Byte.new(JoinMode.CreateIfNotExists)
        fillCreateRoomOptions(op, createOptions)
      end
      if options.rejoin then
        op[Constants.ParameterCode.JoinMode] = Byte.new(JoinMode.RejoinOnly)
      end
    end
    self.currentRoom = self:roomFactoryInternal(roomName)
    op[Constants.ParameterCode.RoomName] = roomName
    self.joinRoomOptions = options or {}
    self.createRoomOptions = createOptions or {}
    self.logger:info("Join Room", roomName, options and options.lobbyName, options and options.lobbyType, "...")
    self.masterPeer:sendOperation(Constants.OperationCode.JoinGame, op)
    return true
  end
  function instance:joinRandomRoom(options)
    local op = {}
    if options then
      if options.matchingType and options.matchingType ~= Constants.MatchmakingMode.FillRoom then
        op[Constants.ParameterCode.MatchMakingType] = Byte.new(options.matchingType)
      end
      local expectedRoomProperties = {}
      local propNonEmpty = false
      if type(options.expectedCustomRoomProperties) == "table" then
        for k, v in pairs(options.expectedCustomRoomProperties) do
          expectedRoomProperties[k] = options.expectedCustomRoomProperties[k]
          propNonEmpty = true
        end
      end
      if type(options.expectedMaxPlayers) == "number" and options.expectedMaxPlayers > 0 then
        expectedRoomProperties[Constants.GameProperties.MaxPlayers] = Integer.new(options.expectedMaxPlayers)
        propNonEmpty = true
      end
      if propNonEmpty then
        op[Constants.ParameterCode.GameProperties] = expectedRoomProperties
      end
      if options.lobbyName then
        op[Constants.ParameterCode.LobbyName] = options.lobbyName
        if options.lobbyType then
          op[Constants.ParameterCode.LobbyType] = Byte.new(options.lobbyType)
        end
      end
      if options.sqlLobbyFilter then
        op[Constants.ParameterCode.Data] = options.sqlLobbyFilter
      end
    end
    self.logger:info("Join Random Room", options and options.lobbyName, options and options.lobbyType, "...")
    self.masterPeer:sendOperation(Constants.OperationCode.JoinRandomGame, op)
    return true
  end
  function instance:setPropertiesOfRoom(properties, forward)
    local op = {}
    op[Constants.ParameterCode.Properties] = properties
    op[Constants.ParameterCode.Broadcast] = true
    if forward then
      op[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.HttpForward)
    end
    self.gamePeer:sendOperation(Constants.OperationCode.SetProperties, op)
  end
  function instance:setPropertiesOfActor(actorNr, properties, forward)
    local op = {}
    op[Constants.ParameterCode.ActorNr] = Integer.new(actorNr)
    op[Constants.ParameterCode.Properties] = properties
    op[Constants.ParameterCode.Broadcast] = true
    if forward then
      op[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.HttpForward)
    end
    self.gamePeer:sendOperation(Constants.OperationCode.SetProperties, op)
  end
  function instance:disconnect()
    if self.nameServerPeer then
      self.nameServerPeer:disconnect()
    end
    self:_cleanupNameServerPeerData()
    if self.masterPeer then
      self.masterPeer:disconnect()
    end
    self:_cleanupMasterPeerData()
    if self.gamePeer then
      self.gamePeer:disconnect()
    end
    self:_cleanupGamePeerData()
    self:changeState(LoadBalancingClient.State.Disconnected)
  end
  function instance:suspendRoom()
    if self:isJoinedToRoom() then
      if self.gamePeer then
        local params = {}
        if options and options.sendAuthCookie then
          params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.SendAuthCookie)
        end
        params[Constants.ParameterCode.IsInactive] = true
        self.gamePeer:sendOperation(Constants.OperationCode.Leave, params)
      end
      self:_cleanupGamePeerData()
      if self:isConnectedToMaster() then
        self:changeState(LoadBalancingClient.State.JoinedLobby)
      else
        self:changeState(LoadBalancingClient.State.Disconnected)
        self:connect(self.connectOptions)
      end
    end
  end
  function instance:leaveRoom(options)
    if self:isJoinedToRoom() then
      if self.gamePeer then
        local params = {}
        if options and options.sendAuthCookie then
          params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.SendAuthCookie)
        end
        self.gamePeer:sendOperation(Constants.OperationCode.Leave, params)
      end
      self:_cleanupGamePeerData()
      if self:isConnectedToMaster() then
        self:changeState(LoadBalancingClient.State.JoinedLobby)
      else
        self:changeState(LoadBalancingClient.State.Disconnected)
        self:connect(self.connectOptions)
      end
    end
  end
  function instance:raiseEvent(eventCode, data, options)
    if self:isJoinedToRoom() then
      self.gamePeer:raiseEvent(eventCode, data, options)
    end
  end
  function instance:changeGroups(groupsToRemove, groupsToAdd)
    if self:isJoinedToRoom() then
      self.logger:debug("Group change:", groupsToRemove, groupsToAdd)
      self.gamePeer:changeGroups(groupsToRemove, groupsToAdd)
    end
  end
  function instance:findFriends(friendsToFind)
    if self:isConnectedToMaster() then
      if friendsToFind and type(friendsToFind) == "table" then
        self.findFriendsRequestList = {}
        for i = 1, #friendsToFind do
          if type(friendsToFind[i]) == "string" then
            self.findFriendsRequestList[i] = friendsToFind[i]
          else
            self.logger:error("FindFriends request error:", "Friend name is not a string", i)
            self:onFindFriendsResult(1101, "Friend name is not a string" .. " " .. i, {})
            return
          end
        end
        self.logger:debug("Find friends:", friendsToFind)
        self.masterPeer:findFriends(friendsToFind)
      else
        self.logger:error("FindFriends request error:", "Parameter is not an array")
        self:onFindFriendsResult(1101, "Parameter is not an array", {})
      end
    else
      self.logger:error("FindFriends request error:", "Not connected to Master")
      self:onFindFriendsResult(1001, "Not connected to Master", {})
    end
  end
  function instance:requestLobbyStats(lobbiesToRequest)
    if self:isConnectedToMaster() then
      self.lobbyStatsRequestList = {}
      if lobbiesToRequest then
        if type(lobbiesToRequest) == "table" then
          for i = 1, #lobbiesToRequest do
            local l = lobbiesToRequest[i]
            if type(l) == "table" then
              local n = l[1]
              if n then
                local t
                if l[2] then
                  if type(l[2]) == "number" then
                    t = l[2]
                  else
                    self:requestLobbyStatsErr("Lobby type is invalid", i)
                    return
                  end
                else
                  t = Constants.LobbyType.Default
                end
                self.lobbyStatsRequestList[i] = {
                  tostring(n),
                  t
                }
              else
                self:requestLobbyStatsErr("Lobby name is empty", i)
                return
              end
            else
              self:requestLobbyStatsErr("Lobby id is not an array", i)
              return
            end
          end
        else
          self:requestLobbyStatsErr("Parameter is not an array")
          return
        end
      end
      self.masterPeer:requestLobbyStats(self.lobbyStatsRequestList)
    else
      self.logger:error("LobbyState request error:", "Not connected to Master")
      self:onLobbyStats(1001, "Not connected to Master", {})
    end
  end
  function instance:requestLobbyStatsErr(m, other)
    other = other or ""
    self.logger:error("LobbyState request error:", m, other)
    self:onLobbyStats(1101, m .. " " .. other, {})
  end
  function instance:getRegions()
    if self:isConnectedToNameServer() then
      self.logger:debug("GetRegions...")
      self.nameServerPeer:getRegions(self.appId)
    else
      self.logger:error("GetRegions request error:", "Not connected to NameServer")
      self:onGetRegionsResult(3001, "Not connected to NameServer", {})
    end
  end
  function instance:webRpc(uriPath, parameters, options)
    if self:isConnectedToMaster() then
      self.logger:debug("WebRpc...")
      self.masterPeer:webRpc(uriPath, parameters, options)
    elseif self:isJoinedToRoom() then
      this.logger.debug("WebRpc...")
      self.masterPeer:webRpc(uriPath, parameters, options)
    else
      self.logger:error("WebRpc request error:", "Not connected to Master server")
      self:onWebRpcResult(1001, "Connected to neither Master nor Game server", uriPath, 0, {})
    end
  end
  function instance:connectToRegionMaster(region)
    if self:isConnectedToNameServer() then
      self.logger:debug("Connecting to Region Master", region, "...")
      self.nameServerPeer:opAuth(region)
      return true
    elseif self:connectToNameServer({region = region}) then
      return true
    else
      self.logger:error("Connecting to Region Master error:", "Not connected to NameServer")
      return false
    end
  end
  function instance:isConnectedToMaster()
    return self.masterPeer and self.masterPeer:isConnected()
  end
  function instance:isConnectedToNameServer()
    return self.nameServerPeer and self.nameServerPeer:isConnected()
  end
  function instance:isInLobby()
    return self.state == LoadBalancingClient.State.JoinedLobby
  end
  function instance:isJoinedToRoom()
    return self.state == LoadBalancingClient.State.Joined
  end
  function instance:isConnectedToGame()
    return self:isJoinedToRoom()
  end
  function instance:availableRooms()
    return self.roomInfos
  end
  function instance:availableRoomsCount()
    return tableutil.getn(self.roomInfos)
  end
  function instance:setLogLevel(level)
    self.logger:setLevel(level)
    if self.nameServerPeer then
      self.nameServerPeer:setLogLevel(level)
    end
    if self.masterPeer then
      self.masterPeer:setLogLevel(level)
    end
    if self.gamePeer then
      self.gamePeer:setLogLevel(level)
    end
  end
  function instance:changeState(nextState)
    self.logger:info("State:", LoadBalancingClient.StateToName(self.state), "->", LoadBalancingClient.StateToName(nextState))
    self.state = nextState
    self:onStateChange(nextState)
  end
  function instance:createRoomInternal(peer, options)
    local op = {}
    op[Constants.ParameterCode.RoomName] = self.currentRoom.name
    fillCreateRoomOptions(op, options)
    if peer == self.masterPeer then
      self.createRoomOptions = options
    end
    if peer == self.gamePeer then
      op[Constants.ParameterCode.PlayerProperties] = self._myActor:_getAllProperties()
    end
    local log
    if peer == self.gamePeer then
      log = self.gamePeer.logger
    else
      log = self.masterPeer.logger
    end
    log:info("Create Room", options and options.lobbyName, options and options.lobbyType, "...")
    peer:sendOperation(Constants.OperationCode.CreateGame, op)
  end
  local errToStr = function(code, msg)
    return " (" .. (code or "") .. " " .. (msg or "") .. ")"
  end
  function instance:updateUserIdAndNickname(vals, logger)
    local userId = vals[Constants.ParameterCode.UserId]
    if userId then
      self:setUserId(userId)
      logger:info("Setting userId sent by server:", userId)
    end
    local nickname = vals[Constants.ParameterCode.Nickname]
    if nickname then
      self._myActor:setName(nickname)
      logger:info("Setting nickname sent by server:", nickname)
    end
  end
  function instance:initNameServerPeer(np)
    np:setLogLevel(self.logger:getLevel())
    np:addPeerStatusListener(PhotonPeer.StatusCodes.Error, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.NameServerError, "NameServer peer error")
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectFailed, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.NameServerConnectFailed, "NameServer peer connect failed: " .. tostring(self.nameServerAddress))
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.Timeout, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.NameServerTimeout, "NameServer peer timeout")
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablishError, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.NameServerEncryptionEstablishError, "NameServer peer encryption establishing error")
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.Connecting, function()
    end)
    function np.opAuth(_, region)
      local op = {}
      op[Constants.ParameterCode.ApplicationId] = self.appId
      op[Constants.ParameterCode.AppVersion] = self.appVersion
      if self.userAuthType and self.userAuthType ~= Constants.CustomAuthenticationType.None then
        op[Constants.ParameterCode.ClientAuthenticationType] = Byte.new(self.userAuthType)
        op[Constants.ParameterCode.ClientAuthenticationParams] = self.userAuthParameters
        op[Constants.ParameterCode.ClientAuthenticationData] = self.authData
      end
      if self.userId then
        op[Constants.ParameterCode.UserId] = self.userId
      end
      op[Constants.ParameterCode.Region] = region
      np:sendOperation(Constants.OperationCode.Authenticate, op, true, 0, self.encryptedAuthentication)
      np.logger:info("Authenticate...")
    end
    np:addPeerStatusListener(PhotonPeer.StatusCodes.Connect, function()
      np.logger:info("Connected")
      if self.encryptedAuthentication then
        np:establishEncryption()
        np.logger:info("Encryption Establishing...")
      else
        self:changeState(LoadBalancingClient.State.ConnectedToNameServer)
      end
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablished, function()
      np.logger:info("Encryption Established")
      self:changeState(LoadBalancingClient.State.ConnectedToNameServer)
      if self.connectOptions.region then
        np:opAuth(self.connectOptions.region)
      end
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.Disconnect, function()
      if np == self.nameServerPeer then
        self:_cleanupNameServerPeerData()
        np.logger:info("Disconnected")
      end
    end)
    np:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectClosed, function()
      np.logger:info("Server closed connection")
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.NameServerConnectClosed, "NameServer server closed connection")
    end)
    np:addResponseListener(Constants.OperationCode.GetRegions, function(data)
      np.logger:debug("resp GetRegions", data)
      local regions = {}
      if data.errCode == 0 then
        local r = data.parameters[Constants.ParameterCode.Region]
        local a = data.parameters[Constants.ParameterCode.Address]
        for i, v in pairs(r) do
          regions[v] = a[i]
        end
      else
        np.logger:error("GetRegions request error:", data.errCode, data.errMsg)
      end
      self:onGetRegionsResult(data.errCode, data.errMsg, regions)
    end)
    np:addResponseListener(Constants.OperationCode.Authenticate, function(data)
      np.logger:debug("resp Authenticate", data)
      if data.errCode == 0 then
        np.logger:info("Authenticated")
        np:disconnect()
        self:updateUserIdAndNickname(data.parameters, np.logger)
        self.masterServerAddress = data.parameters[Constants.ParameterCode.Address]
        np.logger:info("Connecting to Master server", self.masterServerAddress, "...")
        self:connect({
          userAuthSecret = data.parameters[Constants.ParameterCode.Secret]
        })
      else
        self:changeState(LoadBalancingClient.State.Error)
        self:onError(LoadBalancingClient.PeerErrorCode.NameServerAuthenticationFailed, "NameServer authentication failed" .. errToStr(data.errCode, data.errMsg))
      end
    end)
  end
  function instance:initMasterPeer(mp)
    mp:setLogLevel(self.logger:getLevel())
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.Error, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterError, "Master peer error")
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectFailed, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterConnectFailed, "Master peer connect failed: " .. tostring(self.masterServerAddress))
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.Timeout, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterTimeout, "Master peer timeout")
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablishError, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterEncryptionEstablishError, "Master peer encryption establishing error")
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.Connecting, function()
    end)
    local function opAuth()
      local op = {}
      if self.connectOptions.userAuthSecret then
        op[Constants.ParameterCode.Secret] = self.connectOptions.userAuthSecret
        mp:sendOperation(Constants.OperationCode.Authenticate, op)
        mp.logger:info("Authenticate with secret...")
      else
        op[Constants.ParameterCode.ApplicationId] = self.appId
        op[Constants.ParameterCode.AppVersion] = self.appVersion
        if self.userAuthType and self.userAuthType ~= Constants.CustomAuthenticationType.None then
          op[Constants.ParameterCode.ClientAuthenticationType] = Byte.new(self.userAuthType)
          op[Constants.ParameterCode.ClientAuthenticationParams] = self.userAuthParameters
          op[Constants.ParameterCode.ClientAuthenticationData] = self.authData
        end
        if self.userId then
          op[Constants.ParameterCode.UserId] = self.userId
        end
        if self.connectOptions.lobbyStats then
          op[Constants.ParameterCode.LobbyStats] = true
        end
        mp:sendOperation(Constants.OperationCode.Authenticate, op, true, 0, self.encryptedAuthentication)
        mp.logger:info("Authenticate...")
      end
    end
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.Connect, function()
      mp.logger:info("Connected")
      if self.encryptedAuthentication then
        mp:establishEncryption()
        mp.logger:info("Encryption Establishing...")
      else
        opAuth()
      end
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablished, function()
      mp.logger:info("Encryption Established")
      opAuth()
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.Disconnect, function()
      if mp == self.masterPeer then
        self:_cleanupMasterPeerData()
        mp.logger:info("Disconnected")
      end
    end)
    mp:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectClosed, function()
      mp.logger:info("Server closed connection")
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterConnectClosed, "Master server closed connection")
    end)
    mp:addPhotonEventListener(Constants.EventCode.GameList, function(data)
      local gameList = data.parameters[Constants.ParameterCode.GameList]
      self.roomInfos = {}
      for name, info in pairs(gameList) do
        local r = RoomInfo.new(name)
        r:_updateFromProps(info)
        self.roomInfos[name] = r
      end
      self:onRoomList(self.roomInfos)
      mp.logger:debug("ev GameList", self.roomInfos, gameList)
    end)
    mp:addPhotonEventListener(Constants.EventCode.GameListUpdate, function(data)
      local gameList = data.parameters[Constants.ParameterCode.GameList]
      local roomsUpdated = {}
      local roomsAdded = {}
      local roomsRemoved = {}
      for name, info in pairs(gameList) do
        if self.roomInfos[name] then
          local r = self.roomInfos[name]
          r:_updateFromProps(info)
          if r.removed then
            roomsRemoved[name] = r
          else
            roomsUpdated[name] = r
          end
        else
          local r = RoomInfo.new(name)
          r:_updateFromProps(info)
          self.roomInfos[name] = r
          roomsAdded[name] = r
        end
      end
      local riNext = {}
      for name, room in pairs(self.roomInfos) do
        if not room.removed then
          riNext[name] = room
        end
      end
      self.roomInfos = riNext
      self:onRoomListUpdate(self.roomInfos, roomsUpdated, roomsAdded, roomsRemoved)
      mp.logger:debug("ev GameListUpdate:", self.roomInfos, "u:", roomsUpdated, "a:", roomsAdded, "r:", roomsRemoved, gameList)
    end)
    mp:addResponseListener(Constants.OperationCode.Authenticate, function(data)
      mp.logger:debug("resp Authenticate", data)
      if data.errCode == 0 then
        mp.logger:info("Authenticated")
        self:updateUserIdAndNickname(data.parameters, mp.logger)
        if data.parameters[Constants.ParameterCode.Secret] then
          self.connectOptions.userAuthSecret = data.parameters[Constants.ParameterCode.Secret]
        end
        self:changeState(LoadBalancingClient.State.ConnectedToMaster)
        local op = {}
        if self.connectOptions.lobbyName then
          op[Constants.ParameterCode.LobbyName] = self.connectOptions.lobbyName
          if self.connectOptions.lobbyType then
            op[Constants.ParameterCode.LobbyType] = Byte.new(self.connectOptions.lobbyType)
          end
        end
        if self.autoJoinLobby then
          mp:sendOperation(Constants.OperationCode.JoinLobby, op)
          mp.logger:info("Join Lobby", self.connectOptions.lobbyName, self.connectOptions.lobbyType, "...")
        end
      else
        self:changeState(LoadBalancingClient.State.Error)
        self:onError(LoadBalancingClient.PeerErrorCode.MasterAuthenticationFailed, "Master authentication failed" .. errToStr(data.errCode, data.errMsg))
      end
    end)
    mp:addResponseListener(Constants.OperationCode.JoinLobby, function(data)
      mp.logger:debug("resp JoinLobby", data)
      if data.errCode == 0 then
        mp.logger:info("Joined to Lobby")
        self:changeState(LoadBalancingClient.State.JoinedLobby)
      end
      self:_onOperationResponseInternal2(data)
    end)
    mp:addResponseListener(Constants.OperationCode.CreateGame, function(data)
      mp.logger:debug("resp CreateGame", data)
      if data.errCode == 0 then
        self.currentRoom:_updateFromMasterResponse(data.parameters)
        mp.logger:debug("Created/Joined ", self.currentRoom.name)
        self:connectToGameServer(Constants.OperationCode.CreateGame)
      end
      self:_onOperationResponseInternal2(data)
    end)
    mp:addResponseListener(Constants.OperationCode.JoinGame, function(data)
      mp.logger:debug("resp JoinGame", data)
      if data.errCode == 0 then
        self.currentRoom:_updateFromMasterResponse(data.parameters)
        mp.logger:debug("Joined ", self.currentRoom.name)
        self:connectToGameServer(Constants.OperationCode.JoinGame)
      end
      self:_onOperationResponseInternal2(data)
    end)
    mp:addResponseListener(Constants.OperationCode.JoinRandomGame, function(data)
      mp.logger:debug("resp JoinRandomGame", data)
      if data.errCode == 0 then
        self.currentRoom:_updateFromMasterResponse(data.parameters)
        mp.logger:debug("Joined ", self.currentRoom.name)
        self:connectToGameServer(Constants.OperationCode.JoinRandomGame)
      end
      self:_onOperationResponseInternal2(data)
    end)
    mp:addResponseListener(Constants.OperationCode.FindFriends, function(data)
      mp.logger:debug("resp FindFriends", data)
      local res = {}
      if data.errCode == 0 then
        local onlines = data.parameters[Constants.ParameterCode.FindFriendsResponseOnlineList] or {}
        local roomIds = data.parameters[Constants.ParameterCode.FindFriendsResponseRoomIdList] or {}
        self.findFriendsRequestList = self.findFriendsRequestList or {}
        for i = 1, #self.findFriendsRequestList do
          local name = self.findFriendsRequestList[i]
          if name then
            res[name] = {
              online = onlines[i],
              roomId = roomIds[i]
            }
          end
        end
      else
        mp.logger:error("FindFriends request error:", data.errCode, data.errMsg)
      end
      self:onFindFriendsResult(data.errCode, data.errMsg, res)
    end)
    mp:addResponseListener(Constants.OperationCode.LobbyStats, function(data)
      mp.logger:debug("resp LobbyStats", data)
      local res = {}
      if data.errCode == 0 then
        local names = data.parameters[Constants.ParameterCode.LobbyName]
        local types = data.parameters[Constants.ParameterCode.LobbyType] or {}
        local peers = data.parameters[Constants.ParameterCode.PeerCount] or {}
        local games = data.parameters[Constants.ParameterCode.GameCount] or {}
        self.lobbyStatsRequestList = self.lobbyStatsRequestList or {}
        if names then
          for i = 1, #names do
            res[i] = {
              lobbyName = names[i],
              lobbyType = types[i],
              peerCount = peers[i],
              gameCount = games[i]
            }
          end
        else
          for i = 1, #self.lobbyStatsRequestList do
            local l = self.lobbyStatsRequestList[i]
            res[i] = {
              lobbyName = l[1],
              lobbyType = l[2],
              peerCount = peers[i],
              gameCount = games[i]
            }
          end
        end
      else
        mp.logger:error("LobbyStats request error:", data.errCode, data.errMsg)
      end
      self:onLobbyStats(data.errCode, data.errMsg, res)
    end)
    mp:addPhotonEventListener(Constants.EventCode.LobbyStats, function(data)
      mp.logger:debug("ev LobbyStats", data)
      local res = {}
      local names = data.parameters[Constants.ParameterCode.LobbyName]
      local types = data.parameters[Constants.ParameterCode.LobbyType] or {}
      local peers = data.parameters[Constants.ParameterCode.PeerCount] or {}
      local games = data.parameters[Constants.ParameterCode.GameCount] or {}
      if names then
        for i = 1, #names do
          res[i] = {
            lobbyName = names[i],
            lobbyType = types[i],
            peerCount = peers[i],
            gameCount = games[i]
          }
        end
      end
      self:onLobbyStats(0, "", res)
    end)
    mp:addPhotonEventListener(Constants.EventCode.AppStats, function(data)
      mp.logger:debug("ev AppStats", data)
      local res = {
        peerCount = data.parameters[Constants.ParameterCode.PeerCount],
        masterPeerCount = data.parameters[Constants.ParameterCode.MasterPeerCount],
        gameCount = data.parameters[Constants.ParameterCode.GameCount]
      }
      self:onAppStats(0, "", res)
    end)
    mp:addResponseListener(Constants.OperationCode.Rpc, function(d)
      mp.logger:debug("resp Rpc", d)
      local uriPath, message, data, resultCode
      if d.errCode == 0 then
        uriPath = d.parameters[Constants.ParameterCode.UriPath]
        data = d.parameters[Constants.ParameterCode.RpcCallParams]
        resultCode = d.parameters[Constants.ParameterCode.RpcCallRetCode]
      else
        mp.logger:error("WebRpc request error:", d.errCode, d.errMsg)
      end
      self:onWebRpcResult(d.errCode, d.errMsg, uriPath, resultCode, data)
    end)
  end
  function instance:connectToGameServer(masterOpCode)
    if not self.connectOptions.keepMasterConnection then
      self.masterPeer:disconnect()
    end
    if self:checkNextState(LoadBalancingClient.State.ConnectingToGameserver, true) then
      self.logger:info("Connecting to Game", self.currentRoom.address)
      self.gamePeer = GamePeer.new(self)
      self.gamePeer:setCrcEnabled(self.crcEnabled)
      self:initGamePeer(self.gamePeer, masterOpCode)
      self.gamePeer:connect(self.currentRoom.address)
      self:changeState(LoadBalancingClient.State.ConnectingToGameserver)
      return true
    else
      return false
    end
  end
  function instance:initGamePeer(gp, masterOpCode)
    gp:setLogLevel(self.logger:getLevel())
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.Error, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.GameError, "Game peer error")
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectFailed, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.GameConnectFailed, "Game peer connect failed: " .. tostring(self.currentRoom.address))
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.Timeout, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.GameTimeout, "Game peer timeout")
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablishError, function()
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.GameEncryptionEstablishError, "Game peer encryption establishing error")
    end)
    local function opAuth()
      local op = {}
      op[Constants.ParameterCode.ApplicationId] = self.appId
      op[Constants.ParameterCode.AppVersion] = self.appVersion
      if self.connectOptions.userAuthSecret then
        op[Constants.ParameterCode.Secret] = self.connectOptions.userAuthSecret
      end
      if self.userAuthType and self.userAuthType ~= Constants.CustomAuthenticationType.None then
        op[Constants.ParameterCode.ClientAuthenticationType] = Byte.new(self.userAuthType)
      end
      if self.userId then
        op[Constants.ParameterCode.UserId] = self.userId
      end
      gp:sendOperation(Constants.OperationCode.Authenticate, op, true, 0, self.encryptedAuthentication)
      gp.logger:info("Authenticate...")
    end
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.Connect, function()
      gp.logger:info("Connected")
      if self.encryptedAuthentication then
        gp:establishEncryption()
        gp.logger:info("Encryption Establishing...")
      else
        opAuth()
      end
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.EncryptionEstablished, function()
      gp.logger:info("Encryption Established")
      opAuth()
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.Disconnect, function()
      if gp == self.gamePeer then
        self:_cleanupGamePeerData()
        gp.logger:info("Disconnected")
      end
    end)
    gp:addPeerStatusListener(PhotonPeer.StatusCodes.ConnectClosed, function()
      gp.logger:info("Server closed connection")
      self:changeState(LoadBalancingClient.State.Error)
      self:onError(LoadBalancingClient.PeerErrorCode.MasterConnectClosed, "Game server closed connection")
    end)
    gp:addResponseListener(Constants.OperationCode.Authenticate, function(data)
      gp.logger:debug("resp Authenticate", data)
      if data.errCode == 0 then
        gp.logger:info("Authenticated")
        gp.logger:info("Connected")
        if masterOpCode == Constants.OperationCode.CreateGame then
          self:createRoomInternal(gp, self.createRoomOptions)
        else
          local op = {}
          op[Constants.ParameterCode.RoomName] = self.currentRoom.name
          op[Constants.ParameterCode.Broadcast] = true
          op[Constants.ParameterCode.PlayerProperties] = self._myActor:_getAllProperties()
          if masterOpCode == Constants.OperationCode.JoinGame then
            if self.joinRoomOptions.createIfNotExists then
              op[Constants.ParameterCode.JoinMode] = Byte.new(JoinMode.CreateIfNotExists)
              fillCreateRoomOptions(op, self.createRoomOptions)
            end
            if self.joinRoomOptions.rejoin then
              op[Constants.ParameterCode.JoinMode] = Byte.new(JoinMode.RejoinOnly)
            end
          end
          gp:sendOperation(Constants.OperationCode.JoinGame, op)
        end
        self:changeState(LoadBalancingClient.State.ConnectedToGameserver)
      else
        self:changeState(LoadBalancingClient.State.Error)
        self:onError(LoadBalancingClient.PeerErrorCode.GameAuthenticationFailed, "Game authentication failed" .. errToStr(data.errCode, data.errMsg))
      end
    end)
    gp:addResponseListener(Constants.OperationCode.CreateGame, function(data)
      gp.logger:debug("resp CreateGame", data)
      if data.errCode == 0 then
        self._myActor:_updateMyActorFromResponse(data.parameters)
        gp.logger:info("myActor: ", self._myActor)
        self.currentRoom:_updateFromProps(data.parameters[Constants.ParameterCode.GameProperties])
        self.actors = {}
        self:addActor(self._myActor)
        self:changeState(LoadBalancingClient.State.Joined)
        self:onJoinRoom(true)
      end
      self:_onOperationResponseInternal2(data)
    end)
    gp:addResponseListener(Constants.OperationCode.JoinGame, function(data)
      gp.logger:debug("resp JoinGame", data)
      if data.errCode == 0 then
        self._myActor:_updateMyActorFromResponse(data.parameters)
        gp.logger:info("myActor: ", self._myActor)
        self.actors = {}
        self:addActor(self._myActor)
        local actorList = data.parameters[Constants.ParameterCode.ActorList]
        local actorProps = data.parameters[Constants.ParameterCode.PlayerProperties]
        if actorList then
          for _, actorNr in pairs(actorList) do
            local props = {}
            props = actorProps and (actorProps[actorNr] or {})
            local name = props[Constants.ActorProperties.PlayerName]
            local a
            if actorNr == self._myActor.actorNr then
              a = self._myActor
            else
              a = self:actorFactoryInternal(name, actorNr)
              self:addActor(a)
            end
            a:_updateCustomProperties(props)
          end
        end
        self.currentRoom:_updateFromProps(data.parameters[Constants.ParameterCode.GameProperties])
        self:changeState(LoadBalancingClient.State.Joined)
        self:onJoinRoom(false)
      end
      self:_onOperationResponseInternal2(data)
    end)
    gp:addResponseListener(Constants.OperationCode.SetProperties, function(data)
      gp.logger:debug("resp SetProperties", data)
      if data.errCode == 0 then
      end
      self:_onOperationResponseInternal2(data)
    end)
    gp:addPhotonEventListener(Constants.EventCode.Join, function(data)
      gp.logger:debug("ev Join", data)
      if Actor._getActorNrFromResponse(data.parameters) == self._myActor.actorNr then
        self._myActor:_updateFromResponse(data.parameters)
      else
        local actor = self:actorFactoryInternal()
        actor:_updateFromResponse(data.parameters)
        self:addActor(actor)
        self:onActorJoin(actor)
      end
    end)
    gp:addPhotonEventListener(Constants.EventCode.Leave, function(data)
      gp.logger:debug("ev Leave", data)
      self.currentRoom:_updateFromEvent(data.parameters)
      local actorNr = Actor._getActorNrFromResponse(data.parameters)
      if actorNr and actorNr > 0 and self.actors[actorNr] then
        local a = self.actors[actorNr]
        if data.parameters[Constants.ParameterCode.IsInactive] then
          a:_setSuspended(true)
          self:onActorSuspend(a)
        else
          self.actors[actorNr] = nil
          self.currentRoom.playerCount = self:myRoomActorCount()
          if self.lowestActorId == actorNr then
            self.lowestActorId = 0
            for nr, _ in pairs(self.actors) do
              if self.lowestActorId == 0 or nr < self.lowestActorId then
                self.lowestActorId = nr
              end
            end
          end
          self:onActorLeave(a, false)
        end
      end
    end)
    gp:addPhotonEventListener(Constants.EventCode.Disconnect, function(data)
      gp.logger:debug("ev Disconnect", data)
      local actorNr = Actor._getActorNrFromResponse(data.parameters)
      if actorNr and actorNr > 0 and self.actors[actorNr] then
        local a = self.actors[actorNr]
        a:_setSuspended(true)
        self:onActorSuspend(a)
      end
    end)
    gp:addPhotonEventListener(Constants.EventCode.PropertiesChanged, function(data)
      gp.logger:debug("ev PropertiesChanged", data)
      local targetActorNr = data.parameters[Constants.ParameterCode.TargetActorNr]
      if targetActorNr and targetActorNr > 0 then
        if self.actors[targetActorNr] then
          local targetActor = self.actors[targetActorNr]
          targetActor:_updateCustomProperties(data.parameters[Constants.ParameterCode.Properties])
          self:onActorPropertiesChange(targetActor)
        end
      else
        self.currentRoom:_updateFromProps(data.parameters[Constants.ParameterCode.Properties])
        self:onMyRoomPropertiesChange()
      end
    end)
  end
  function instance:_cleanupNameServerPeerData()
  end
  function instance:_cleanupMasterPeerData()
  end
  function instance:_cleanupGamePeerData()
    if self.actors then
      for k, v in pairs(self.actors) do
        self:onActorLeave(v, true)
      end
    end
    self.actors = {}
    self:addActor(self._myActor)
    self.lowestActorId = 0
  end
  function instance:_onOperationResponseInternal2(data)
    self:_onOperationResponseInternal(data)
  end
  function instance:checkNextState(nextState, dontThrow)
    local valid = validNextState[self.state]
    local res = valid and valid:indexOf(nextState) >= 0
    if not res then
      if dontThrow then
        self.logger:error("LoadBalancingPeer checkNextState fail: " .. LoadBalancingClient.StateToName(self.state) .. " -> " .. LoadBalancingClient.StateToName(nextState))
      else
        error("LoadBalancingPeer checkNextState fail: " .. LoadBalancingClient.StateToName(self.state) .. " -> " .. LoadBalancingClient.StateToName(nextState))
      end
    end
    return res
  end
  function LoadBalancingClient.StateToName(state)
    return tableutil.getKeyByValue(LoadBalancingClient.State, state)
  end
  function NameServerPeer:init(client)
    self.client = client
    self.logger:setPrefix(client.logger.prefix .. " NameServer")
  end
  function NameServerPeer.proto:onUnhandledEvent(eventData)
    self.client:_onEventInternal(eventData.code, eventData.parameters[Constants.ParameterCode.CustomEventContent], eventData.parameters[Constants.ParameterCode.ActorNr])
  end
  function NameServerPeer.proto:onUnhandledResponse(operationResponse)
    self.client:_onOperationResponseInternal(operationResponse)
  end
  function NameServerPeer.proto:getRegions(appId)
    local params = {}
    params[Constants.ParameterCode.ApplicationId] = appId
    self:sendOperation(Constants.OperationCode.GetRegions, params, true, 0, self.encryptedAuthentication)
  end
  function MasterPeer:init(client)
    self.client = client
    self.logger:setPrefix(client.logger.prefix .. " Master")
  end
  function MasterPeer.proto:onUnhandledEvent(eventData)
    self.client:_onEventInternal(eventData.code, eventData.parameters[Constants.ParameterCode.CustomEventContent], eventData.parameters[Constants.ParameterCode.ActorNr])
  end
  function MasterPeer.proto:onUnhandledResponse(operationResponse)
    self.client:_onOperationResponseInternal(operationResponse)
  end
  function MasterPeer.proto:findFriends(friendsToFind)
    local params = {}
    Array.string.apply(friendsToFind)
    params[Constants.ParameterCode.FindFriendsRequestList] = friendsToFind
    self:sendOperation(Constants.OperationCode.FindFriends, params)
  end
  function MasterPeer.proto:requestLobbyStats(lobbiesToRequest)
    local params = {}
    if lobbiesToRequest and #lobbiesToRequest > 0 then
      local n = {}
      local t = {}
      for i = 1, #lobbiesToRequest do
        n[i] = lobbiesToRequest[i][1]
        t[i] = lobbiesToRequest[i][2]
      end
      Array.string.apply(n)
      Array[Byte].apply(t)
      params[Constants.ParameterCode.LobbyName] = n
      params[Constants.ParameterCode.LobbyType] = t
    end
    self:sendOperation(Constants.OperationCode.LobbyStats, params)
  end
  function MasterPeer.proto:webRpc(uriPath, parameters, options)
    local params = {}
    params[Constants.ParameterCode.UriPath] = uriPath
    params[Constants.ParameterCode.RpcCallParams] = parameters
    if options and options.sendAuthCookie then
      params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.SendAuthCookie)
    end
    self:sendOperation(Constants.OperationCode.Rpc, params)
  end
  function GamePeer:init(client)
    self.client = client
    self.logger:setPrefix(client.logger.prefix .. " Game")
  end
  function GamePeer.proto:onUnhandledEvent(eventData)
    self.client:_onEventInternal(eventData.code, eventData.parameters[Constants.ParameterCode.CustomEventContent], eventData.parameters[Constants.ParameterCode.ActorNr])
  end
  function GamePeer.proto:onUnhandledResponse(operationResponse)
    self.client:_onOperationResponseInternal(operationResponse)
  end
  function GamePeer.proto:raiseEvent(eventCode, data, options)
    if self.client:isJoinedToRoom() then
      self.logger:debug("raiseEvent", eventCode, data, options)
      local params = {}
      params[Constants.ParameterCode.Code] = Byte.new(eventCode)
      params[Constants.ParameterCode.Data] = data
      local sendReliable, channelId
      if options then
        if options.receivers and options.receivers ~= Constants.ReceiverGroup.Others then
          params[Constants.ParameterCode.ReceiverGroup] = Byte.new(options.receivers)
        end
        if options.cache and options.cache ~= Constants.EventCaching.DoNotCache then
          params[Constants.ParameterCode.Cache] = Byte.new(options.cache)
        end
        if options.interestGroup then
          if checkGroupNumber(options.interestGroup) then
            params[Constants.ParameterCode.Group] = Byte.new(options.interestGroup)
          else
            error("raiseEvent - Group not a number: " .. tostring(options.interestGroup))
          end
        end
        if options.targetActors then
          Array[Integer].apply(options.targetActors)
          params[Constants.ParameterCode.ActorList] = options.targetActors
        end
        if options.webForward then
          params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.HttpForward)
        end
        sendReliable = options.sendReliable
        channelId = options.channelId
      end
      self:sendOperation(Constants.OperationCode.RaiseEvent, params, sendReliable, channelId)
    else
      error("raiseEvent - Not joined!")
    end
  end
  function GamePeer.proto:changeGroups(groupsToRemove, groupsToAdd)
    local params = {}
    if groupsToRemove then
      checkGroupArray(groupsToRemove, "groupsToRemove")
      local r = Array[Byte].new()
      for i = 1, #groupsToRemove do
        local b = groupsToRemove[i]
        if b < 0 or b > 255 then
          self.logger:error("Wrong group: ", b)
          return
        end
        r:push(Byte.new(b))
      end
      params[Constants.ParameterCode.Remove] = r
    end
    if groupsToAdd then
      checkGroupArray(groupsToAdd, "groupsToAdd")
      local a = Array[Byte].new()
      for i = 1, #groupsToAdd do
        local b = groupsToAdd[i]
        if b < 0 or b > 255 then
          self.logger:error("Wrong group: ", b)
          return
        end
        a:push(Byte.new(b))
      end
      params[Constants.ParameterCode.Add] = a
    end
    self:sendOperation(Constants.OperationCode.ChangeGroups, params)
  end
  return LoadBalancingClient
end
package.preload["photon.loadbalancing.Room"] = function(...)
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local Integer = require("photon.common.type.Integer")
  local Null = require("photon.common.type.Null")
  local Constants = require("photon.loadbalancing.constants")
  local tableutil = require("photon.common.util.tableutil")
  local class = require("photon.common.class")
  local RoomInfo = require("photon.loadbalancing.RoomInfo")
  local Room = class.extend(RoomInfo, "Room")
  local instance = Room.proto
  function Room:init()
    self.loadBalancingClient = nil
  end
  function instance:setCustomProperty(name, value, webForward)
    if value == Null then
      value = nil
    end
    self.customProperties[name] = tableutil.deepCopy(value)
    local props = {}
    props[name] = value == nil and Null or value
    if self.loadBalancingClient and self.loadBalancingClient:isJoinedToRoom() then
      self.loadBalancingClient:setPropertiesOfRoom(props, webForward)
    end
    self:onPropertiesChange(tableutil.deepCopyUntyped(props), true)
  end
  function instance:setCustomProperties(properties, webForward)
    local props = {}
    for name, value in pairs(properties) do
      if value == Null then
        value = nil
      end
      self.customProperties[name] = tableutil.deepCopy(value)
      props[name] = value
    end
    if self.loadBalancingClient and self.loadBalancingClient:isJoinedToRoom() then
      self.loadBalancingClient:setPropertiesOfRoom(props, webForward)
    end
    self:onPropertiesChange(tableutil.deepCopyUntyped(props), true)
  end
  function instance:_setProp(name, value)
    if self.loadBalancingClient and self.loadBalancingClient:isJoinedToRoom() then
      local props = {}
      props[name] = value
      self.loadBalancingClient:setPropertiesOfRoom(props)
    end
  end
  function instance:setIsVisible(isVisible)
    if self.isVisible ~= isVisible then
      self.isVisible = isVisible
      self:_setProp(Byte.new(Constants.GameProperties.IsVisible), isVisible)
    end
  end
  function instance:setIsOpen(isOpen)
    if self.isOpen ~= isOpen then
      self.isOpen = isOpen
      self:_setProp(Byte.new(Constants.GameProperties.IsOpen), isOpen)
    end
  end
  function instance:setMaxPlayers(maxPlayers)
    if self.maxPlayers ~= maxPlayers then
      self.maxPlayers = maxPlayers
      self:_setProp(Byte.new(Constants.GameProperties.MaxPlayers), maxPlayers)
    end
  end
  function instance:setEmptyRoomLiveTime(emptyRoomLiveTime)
    if self.emptyRoomLiveTime ~= emptyRoomLiveTime then
      self.emptyRoomLiveTime = emptyRoomLiveTime
      self:_setProp(Byte.new(Constants.GameProperties.EmptyRoomTtl), Integer.new(emptyRoomLiveTime))
    end
  end
  function instance:setSuspendedPlayerLiveTime(suspendedPlayerLiveTime)
    if self.suspendedPlayerLiveTime ~= suspendedPlayerLiveTime then
      self.suspendedPlayerLiveTime = suspendedPlayerLiveTime
      self:_setProp(Byte.new(Constants.GameProperties.PlayerTtl), Integer.new(suspendedPlayerLiveTime))
    end
  end
  function instance:setPropsListedInLobby(props)
    Array.string.apply(props)
    self.propsListedInLobby = props
  end
  function instance:_setLBC(lbc)
    self.loadBalancingClient = lbc
  end
  return Room
end
package.preload["photon.loadbalancing.RoomInfo"] = function(...)
  local class = require("photon.common.class")
  local Null = require("photon.common.type.Null")
  local Constants = require("photon.loadbalancing.constants")
  local tableutil = require("photon.common.util.tableutil")
  local RoomInfo = class.declare("RoomInfo")
  local instance = RoomInfo.proto
  local updateIfExists = function(prevValue, code, props)
    return props[code] or prevValue
  end
  function RoomInfo:init(name)
    local instance = self
    instance.name = name or ""
    instance.address = ""
    instance.maxPlayers = 0
    instance.isVisible = true
    instance.isOpen = true
    instance.playerCount = 0
    instance.emptyRoomLiveTime = 0
    instance.suspendedPlayerLiveTime = 0
    instance.removed = false
    instance.cleanupCacheOnLeave = false
    instance.masterClientId = 0
    self.customProperties = {}
    self.propsListedInLobby = nil
  end
  function instance:onPropertiesChange(changedCustomProps, byClient)
  end
  function instance:_onPropertiesChangeInternal(changedCustomProps, byClient)
    self:onPropertiesChange(tableutil.deepCopyUntyped(changedCustomProps), byClient)
  end
  function instance:getCustomProperty(name)
    return tableutil.deepCopyUntyped(self.customProperties[name])
  end
  function instance:getCustomPropertyOrElse(name, defaultValue)
    return tableutil.deepCopyUntyped(self.customProperties[name]) or defaultValue
  end
  function instance:_updateFromMasterResponse(vals)
    self.address = vals[Constants.ParameterCode.Address]
    local name = vals[Constants.ParameterCode.RoomName]
    if name then
      self.name = name
    end
  end
  function instance:_updateFromProps(props)
    if props then
      self.maxPlayers = updateIfExists(self.maxPlayers, Constants.GameProperties.MaxPlayers, props)
      self.isVisible = updateIfExists(self.isVisible, Constants.GameProperties.IsVisible, props)
      self.isOpen = updateIfExists(self.isOpen, Constants.GameProperties.IsOpen, props)
      self.playerCount = updateIfExists(self.playerCount, Constants.GameProperties.PlayerCount, props)
      self.removed = updateIfExists(self.removed, Constants.GameProperties.Removed, props)
      self.cleanupCacheOnLeave = updateIfExists(self.cleanupCacheOnLeave, Constants.GameProperties.CleanupCacheOnLeave, props)
      self.masterClientId = updateIfExists(self.masterClientId, Constants.GameProperties.MasterClientId, props)
      self.emptyRoomLiveTime = updateIfExists(self.emptyRoomLiveTime, Constants.GameProperties.EmptyRoomTtl, props)
      self.suspendedPlayerLiveTime = updateIfExists(self.suspendedPlayerLiveTime, Constants.GameProperties.PlayerTtl, props)
      local changedProps = {}
      for k, v in pairs(props) do
        if type(k) ~= "number" then
          if v == Null then
            v = nil
          end
          if self.customProperties[k] ~= v then
            self.customProperties[k] = v
            changedProps[k] = v
          end
        end
      end
      self:onPropertiesChange(changedProps)
    end
  end
  function instance:_updateFromEvent(payload)
    if payload then
      self.masterClientId = updateIfExists(self.masterClientId, Constants.ParameterCode.MasterClientId, payload)
    end
  end
  return RoomInfo
end
package.preload["photon.loadbalancing.constants"] = function(...)
  local M = {}
  M.ErrorCode = {
    Ok = 0,
    OperationNotAllowedInCurrentState = -3,
    InvalidOperationCode = -2,
    InternalServerError = -1,
    InvalidAuthentication = 32767,
    GameIdAlreadyExists = 32766,
    GameFull = 32765,
    GameClosed = 32764,
    NoRandomMatchFound = 32760,
    GameDoesNotExist = 32758,
    MaxCcuReached = 32757,
    InvalidRegion = 32756,
    CustomAuthenticationFailed = 32755,
    AuthenticationTicketExpired = 32753,
    PluginReportedError = 32752,
    PluginMismatch = 32751,
    JoinFailedPeerAlreadyJoined = 32750,
    JoinFailedFoundInactiveJoiner = 32749,
    JoinFailedWithRejoinerNotFound = 32748,
    JoinFailedFoundExcludedUserId = 32747,
    JoinFailedFoundActiveJoiner = 32746,
    HttpLimitReached = 32745,
    ExternalHttpCallFailed = 32744,
    SlotError = 32742,
    InvalidEncryptionParameters = 32741
  }
  M.ActorProperties = {PlayerName = 255}
  M.GameProperties = {
    MaxPlayers = 255,
    IsVisible = 254,
    IsOpen = 253,
    PlayerCount = 252,
    Removed = 251,
    PropsListedInLobby = 250,
    CleanupCacheOnLeave = 249,
    MasterClientId = 248,
    PlayerTtl = 246,
    EmptyRoomTtl = 245
  }
  M.EventCode = {
    GameList = 230,
    GameListUpdate = 229,
    QueueState = 228,
    AppStats = 226,
    AzureNodeInfo = 210,
    Join = 255,
    Leave = 254,
    PropertiesChanged = 253,
    Disconnect = 252,
    LobbyStats = 224
  }
  M.ParameterCode = {
    Address = 230,
    PeerCount = 229,
    GameCount = 228,
    MasterPeerCount = 227,
    UserId = 225,
    ApplicationId = 224,
    Position = 223,
    MatchMakingType = 223,
    GameList = 222,
    Secret = 221,
    AppVersion = 220,
    AzureNodeInfo = 210,
    AzureLocalNodeId = 209,
    AzureMasterNodeId = 208,
    RoomName = 255,
    Broadcast = 250,
    ActorList = 252,
    ActorNr = 254,
    PlayerProperties = 249,
    CustomEventContent = 245,
    Data = 245,
    Code = 244,
    GameProperties = 248,
    Properties = 251,
    TargetActorNr = 253,
    ReceiverGroup = 246,
    Cache = 247,
    CleanupCacheOnLeave = 241,
    Group = 240,
    Remove = 239,
    Add = 238,
    EmptyRoomTTL = 236,
    PlayerTTL = 235,
    ClientAuthenticationType = 217,
    ClientAuthenticationParams = 216,
    ClientAuthenticationData = 214,
    JoinMode = 215,
    MasterClientId = 203,
    FindFriendsRequestList = 1,
    FindFriendsResponseOnlineList = 1,
    FindFriendsResponseRoomIdList = 2,
    LobbyName = 213,
    LobbyType = 212,
    LobbyStats = 211,
    Region = 210,
    IsInactive = 233,
    CheckUserOnJoin = 232,
    UriPath = 209,
    RpcCallParams = 208,
    RpcCallRetCode = 207,
    RpcCallRetMessage = 206,
    WebFlags = 234,
    Nickname = 202
  }
  M.OperationCode = {
    Authenticate = 230,
    JoinLobby = 229,
    LeaveLobby = 228,
    CreateGame = 227,
    JoinGame = 226,
    JoinRandomGame = 225,
    Leave = 254,
    RaiseEvent = 253,
    SetProperties = 252,
    GetProperties = 251,
    ChangeGroups = 248,
    FindFriends = 222,
    LobbyStats = 221,
    GetRegions = 220,
    Rpc = 219
  }
  M.MatchmakingMode = {
    FillRoom = 0,
    SerialMatching = 1,
    RandomMatching = 2
  }
  M.EventCaching = {
    DoNotCache = 0,
    MergeCache = 1,
    ReplaceCache = 2,
    RemoveCache = 3,
    AddToRoomCache = 4,
    AddToRoomCacheGlobal = 5,
    RemoveFromRoomCache = 6,
    RemoveFromRoomCacheForActorsLeft = 7
  }
  M.ReceiverGroup = {
    Others = 0,
    All = 1,
    MasterClient = 2
  }
  M.CustomAuthenticationType = {
    Custom = 0,
    Steam = 1,
    Facebook = 2,
    None = 255
  }
  M.LobbyType = {Default = 0, SqlLobby = 2}
  return M
end
package.preload["photon.chat.Channel"] = function(...)
  local class = require("photon.common.class")
  local tableutil = require("photon.common.util.tableutil")
  local Message = require("photon.chat.Message")
  local Channel = class.declare("Channel")
  local instance = Channel.proto
  function Channel:init(name, isPrivate)
    self.name = name
    self.isPrivate = isPrivate ~= nil and isPrivate ~= false
    self.lastId = 0
    self:clearMessages()
  end
  function instance:getName()
    return self.name
  end
  function instance:isPrivate()
    return self.isPrivate
  end
  function instance:getMessages()
    return self.messages
  end
  function instance:getLastId()
    return self.lastId
  end
  function instance:clearMessages()
    self.messages = {}
  end
  function instance:addMessages(senders, messages)
    local newMessages = {}
    for i, s in pairs(senders) do
      if i <= #messages then
        local m = Message.new(senders[i], messages[i])
        table.insert(self.messages, m)
        table.insert(newMessages, m)
      end
    end
    return newMessages
  end
  return Channel
end
package.preload["photon.chat.ChatClient"] = function(...)
  local Array = require("photon.common.type.Array")
  local Byte = require("photon.common.type.Byte")
  local Integer = require("photon.common.type.Integer")
  local Null = require("photon.common.type.Null")
  local Logger = require("photon.common.Logger")
  local tableutil = require("photon.common.util.tableutil")
  local PhotonPeer = require("photon.core.PhotonPeer")
  local Constants = require("photon.chat.constants")
  local Channel = require("photon.chat.Channel")
  local Message = require("photon.chat.Message")
  local LoadBalancingClient = require("photon.loadbalancing.LoadBalancingClient")
  local function _P(x)
    print(tableutil.toStringReq(x))
  end
  local class = require("photon.common.class")
  local ChatClient = class.extend(LoadBalancingClient, "ChatClient")
  local instance = ChatClient.proto
  local webFlags = {
    HttpForward = 1,
    SendAuthCookie = 2,
    SendSync = 4,
    SendState = 8
  }
  ChatClient.PeerErrorCode = {
    Ok = 0,
    FrontEndError = 1001,
    FrontEndConnectFailed = 1002,
    FrontEndConnectClosed = 1003,
    FrontEndTimeout = 1004,
    FrontEndEncryptionEstablishError = 1005,
    FrontEndAuthenticationFailed = 1101,
    NameServerError = 3001,
    NameServerConnectFailed = 3002,
    NameServerConnectClosed = 3003,
    NameServerTimeout = 3004,
    NameServerEncryptionEstablishError = 3005,
    NameServerAuthenticationFailed = 3101
  }
  ChatClient.State = {
    Error = -1,
    Uninitialized = 0,
    ConnectingToNameServer = 1,
    ConnectedToNameServer = 2,
    ConnectingToFrontEnd = 3,
    ConnectedToFrontEnd = 4,
    Disconnected = 10
  }
  function ChatClient.StateToName(state)
    return tableutil.getKeyByValue(ChatClient.State, state)
  end
  function ChatClient:init(serverAddress, appId, appVersion)
    self.autoJoinLobby = false
    self.publicChannels = {}
    self.privateChannels = {}
  end
  function ChatClient:init2(serverAddress, appId, appVersion)
  end
  function instance:onStateChange(state)
  end
  function instance:onError(errorCode, errorMsg)
    self.logger:error("Chat Client Error", errorCode, errorMsg)
  end
  function instance:onSubscribeResult(results)
  end
  function instance:onUnsubscribeResult(results)
  end
  function instance:onChatMessages(channelName, messages)
  end
  function instance:onPrivateMessage(channelName, message)
  end
  function instance:onUserStatusUpdate(userId, status, gotMessage, statusMessage)
  end
  function instance:connectToRegionFrontEnd(region)
    return self:connectToRegionMaster(region)
  end
  function instance:isConnectedToFrontEnd()
    return self.state == ChatClient.State.ConnectedToFrontEnd
  end
  function instance:subscribe(channelNames, options)
    if type(options) == "number" then
      options = {historyLength = options}
    end
    if self:isConnectedToFrontEnd() then
      if channelNames and type(channelNames) == "table" then
        self.logger:debug("Subscribe channels:", channelNames)
        local params = {}
        Array.string.apply(channelNames)
        params[Constants.ParameterCode.Channels] = channelNames
        if options then
          if options.historyLength and options.historyLength ~= 0 then
            params[Constants.ParameterCode.HistoryLength] = Integer.new(options.historyLength)
          end
          if options.lastIds then
            Array[Integer].apply(options.lastIds)
            params[Constants.ParameterCode.MsgIds] = options.lastIds
            if options.historyLength == nil then
              params[Constants.ParameterCode.HistoryLength] = Integer.new(-1)
            end
          end
        end
        self.masterPeer:sendOperation(Constants.OperationCode.Subscribe, params, true)
        return true
      else
        self.logger:error("subscribe request error:", "Parameter is not an array")
        return false
      end
    else
      self.logger:error("subscribe request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:unsubscribe(channelNames)
    if self:isConnectedToFrontEnd() then
      if channelNames and type(channelNames) == "table" then
        self.logger:debug("Unsubscribe channels:", channelNames)
        local params = {}
        Array.string.apply(channelNames)
        params[Constants.ParameterCode.Channels] = channelNames
        self.masterPeer:sendOperation(Constants.OperationCode.Unsubscribe, params, true)
        return true
      else
        self.logger:error("unsubscribe request error:", "Parameter is not an array")
        return false
      end
    else
      self.logger:error("unsubscribe request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:publishMessage(channelName, content, options)
    if self:isConnectedToFrontEnd() then
      local params = {}
      params[Constants.ParameterCode.Channel] = channelName
      params[Constants.ParameterCode.Message] = content
      if options and options.webForward then
        params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.HttpForward)
      end
      self.masterPeer:sendOperation(Constants.OperationCode.Publish, params, true)
      return true
    else
      self.logger:error("publishMessage request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:sendPrivateMessage(userId, content, options)
    if self:isConnectedToFrontEnd() then
      local params = {}
      params[Constants.ParameterCode.UserId] = userId
      params[Constants.ParameterCode.Message] = content
      local encrypt = false
      if options then
        encrypt = options.encrypt
        if options.webForward then
          params[Constants.ParameterCode.WebFlags] = Byte.new(webFlags.HttpForward)
        end
      end
      self.masterPeer:sendOperation(Constants.OperationCode.SendPrivate, params, true, 0, encrypt)
      return true
    else
      self.logger:error("sendPrivateMessage request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:setUserStatus(status, statusMessage, skipMessage)
    if self:isConnectedToFrontEnd() then
      if type(status) == "number" then
        local params = {}
        params[Constants.ParameterCode.Status] = Integer.new(status)
        if skipMessage then
          params[Constants.ParameterCode.SkipMessage] = true
        else
          params[Constants.ParameterCode.Message] = statusMessage or Null
        end
        self.masterPeer:sendOperation(Constants.OperationCode.UpdateStatus, params, true)
        return true
      else
        self.logger:error("setUserStatus request error:", "Status is not a number")
        return false
      end
    else
      self.logger:error("setUserStatus request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:addFriends(userIds)
    if self:isConnectedToFrontEnd() then
      Array.string.apply(userIds)
      local params = {}
      params[Constants.ParameterCode.Friends] = userIds
      self.masterPeer:sendOperation(Constants.OperationCode.AddFriends, params, true)
      return true
    else
      self.logger:error("addFriends request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:removeFriends(userIds)
    if self:isConnectedToFrontEnd() then
      Array.string.apply(userIds)
      local params = {}
      params[Constants.ParameterCode.Friends] = userIds
      self.masterPeer:sendOperation(Constants.OperationCode.RemoveFriends, params, true)
      return true
    else
      self.logger:error("removeFriends request error:", "Not connected to Front End")
      return false
    end
  end
  function instance:getPublicChannels()
    return self.publicChannels
  end
  function instance:getPrivateChannels()
    return self.privateChannels
  end
  function instance:getOrAddChannel(channels, name, isPrivate)
    if not channels[name] then
      channels[name] = Channel.new(name, isPrivate)
    end
    return channels[name]
  end
  function instance:initMasterPeer(mp)
    LoadBalancingClient.proto.initMasterPeer(self, mp)
    mp:addPhotonEventListener(Constants.EventCode.ChatMessages, function(data)
      local senders = data.parameters[Constants.ParameterCode.Senders]
      local messages = data.parameters[Constants.ParameterCode.Messages]
      local channelName = data.parameters[Constants.ParameterCode.Channel]
      local ch = self.publicChannels[channelName]
      if ch then
        local newMessages = ch:addMessages(senders, messages)
        ch.lastId = data.parameters[Constants.ParameterCode.MsgId]
        self:onChatMessages(channelName, newMessages)
      else
        mp.logger:warn("ev ChatMessages: Got message from unsubscribed channel ", channelName)
      end
    end)
    mp:addPhotonEventListener(Constants.EventCode.PrivateMessage, function(data)
      local sender = data.parameters[Constants.ParameterCode.Sender]
      local message = data.parameters[Constants.ParameterCode.Message]
      local userId = data.parameters[Constants.ParameterCode.UserId]
      local channelName = ""
      if self:getUserId() == sender then
        channelName = userId
      else
        channelName = sender
      end
      local ch = self:getOrAddChannel(self.privateChannels, channelName, false)
      ch.lastId = data.parameters[Constants.ParameterCode.MsgId]
      self:onPrivateMessage(channelName, Message.new(sender, message))
    end)
    mp:addPhotonEventListener(Constants.EventCode.StatusUpdate, function(data)
      local sender = data.parameters[Constants.ParameterCode.Sender]
      local status = data.parameters[Constants.ParameterCode.Status]
      local message = data.parameters[Constants.ParameterCode.Message]
      local gotMessage = message ~= nil
      if message == Null then
        message = nil
      end
      self:onUserStatusUpdate(sender, status, gotMessage, message)
    end)
    mp:addPhotonEventListener(Constants.EventCode.Subscribe, function(data)
      mp.logger:debug("ev Subscribe", data)
      local res = {}
      local channels = data.parameters[Constants.ParameterCode.Channels] or {}
      local results = data.parameters[Constants.ParameterCode.SubscribeResults] or {}
      for i, r in pairs(channels) do
        res[r] = false
        if results[i] then
          self:getOrAddChannel(self.publicChannels, r, false)
          res[r] = true
        end
      end
      self:onSubscribeResult(res)
    end)
    mp:addPhotonEventListener(Constants.EventCode.Unsubscribe, function(data)
      mp.logger:debug("ev Unsubscribe", data)
      local res = {}
      local channels = data.parameters[Constants.ParameterCode.Channels] or {}
      for i, r in pairs(channels) do
        self.publicChannels[r] = nil
        res[r] = true
      end
      self:onUnsubscribeResult(res)
    end)
  end
  return ChatClient
end
package.preload["photon.chat.constants"] = function(...)
  local tableutil = require("photon.common.util.tableutil")
  local M = {}
  M.ParameterCode = {
    Channels = 0,
    Channel = 1,
    Messages = 2,
    Message = 3,
    Senders = 4,
    Sender = 5,
    ChannelUserCount = 6,
    UserId = 225,
    MsgId = 8,
    MsgIds = 9,
    SubscribeResults = 15,
    Status = 10,
    Friends = 11,
    SkipMessage = 12,
    HistoryLength = 14,
    WebFlags = 21
  }
  M.OperationCode = {
    Subscribe = 0,
    Unsubscribe = 1,
    Publish = 2,
    SendPrivate = 3,
    ChannelHistory = 4,
    UpdateStatus = 5,
    AddFriends = 6,
    RemoveFriends = 7
  }
  M.EventCode = {
    ChatMessages = 0,
    Users = 1,
    PrivateMessage = 2,
    FriendsList = 3,
    StatusUpdate = 4,
    Subscribe = 5,
    Unsubscribe = 6
  }
  M.UserStatus = {
    Offline = 0,
    Invisible = 1,
    Online = 2,
    Away = 3,
    Dnd = 4,
    Lfg = 5,
    Playing = 6
  }
  function M.UserStatusToName(status)
    return tableutil.getKeyByValue(M.UserStatus, status)
  end
  return M
end
package.preload["photon.chat.Message"] = function(...)
  local class = require("photon.common.class")
  local tableutil = require("photon.common.util.tableutil")
  local Message = class.declare("Message")
  local instance = Message.proto
  function Message:init(sender, content)
    self.sender = sender
    self.content = content
  end
  function instance:getSender()
    return self.sender
  end
  function instance:getContent()
    return self.content
  end
  return Message
end
