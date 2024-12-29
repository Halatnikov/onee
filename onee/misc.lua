
onee.love_callbacks = {}

--! hook love callbacks, so it can call multiple functions at once
-- @param name -- if love.x, then put it as "x"
function onee.love(name, func)
	onee.love_callbacks[name] = onee.love_callbacks[name] or {}
	
	if onee.love_callbacks[name] == {} then table.insert(onee.love_callbacks[name], love[name]) end
	
	table.insert(onee.love_callbacks[name], func)
	
	love[name] = function(...)
		for i=1, #onee.love_callbacks[name] do
			onee.love_callbacks[name][i](...)
		end
	end
end

--! default loading screen
function onee.loading(text)
	love.graphics.reset(true)
	window.draw(function()
		love.graphics.clear(rgb(onee.colors.bg))
		love.graphics.printf(text, onee.width/2-150, onee.height-16, 150*2, "center")
	end)
	love.graphics.present()
end

--!
function onee.compatibility(current, needed)
	if not needed then return end
	-- strip pre-releases
	current, needed = semver(string.tokenize(current,"-",1)), semver(string.tokenize(needed,"-",1))
	
	if current == needed then
		return true
	end
	if current > needed then
		-- todo: save your onee version in savefile and show a message box only once
		log("installed onee version is higher than required") 
		return tostring(current)
	end
	if current < needed then
		error("at least onee v"..tostring(needed).." is required! please update from v"..tostring(current))
	end
end

love.graphics.reset_ = love.graphics.reset

--! modified love.graphics.reset() for my needs
function love.graphics.reset(ignore) -- bool=
	if ignore then love.graphics.reset_() end
	
	-- might as well use these here
	love.graphics.setDefaultFilter("nearest", "nearest", 0)
	love.graphics.setLineStyle("rough")
	love.graphics.setBackgroundColor(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
	love.graphics.setFont(onee.font or love.graphics.getFont())
	
	if not ignore then
		-- don't deactivate canvases, transformations, shaders, current font and scissors!
		love.graphics.setColor(1,1,1,1)
		love.graphics.setBlendMode("alpha")
		
		love.graphics.setLineWidth(1)
		love.graphics.setLineJoin("miter")
		love.graphics.setPointSize(1)
		love.graphics.setStencilTest()
		love.graphics.setDepthMode()
		love.graphics.setColorMask()
		love.graphics.setWireframe(false)
		love.graphics.setMeshCullMode("none")
		love.graphics.setFrontFaceWinding("ccw")
	end
end

Test = class({t = {}})

function Test:__init()
	setproxy(self)
	Test.x = 0
	Test.y = 0
end

function Test:__index(k)
	print("index", self, k, Test[k], rawget(self, k))
	-- super hacky but since both getting and setting trigger __index, maybe try storing an older table state and compare it against new one and if it's changed, that's setting
	if type(Test[k]) == "table" then
		Test.__oldstate = Test.__oldstate or {}
		Test.__oldstate[k] = Test.__oldstate[k] or copy(Test[k])
	end
	if type(Test[k]) == "table" and rawget(self, k) == nil and (table.compare(Test.__oldstate[k], Test[k])) then
		self[k] = copy(Test[k])
		Test[k] = copy(Test.__oldstate[k])
	end
	return Test[k]
end

function Test:__newindex(k, v)
	print("newindex", self, k ,v)
	rawset(self, k, v)
end

function Test:__gc()
	print("FUCK!!!!")
end

a = Test()
b = Test()
c = Test()

a.t.huh = "nor way"
b.x = 49

print(a.x)
print(b.x)
print(b.t.huh)

c = nil
