
onee.love_callbacks = {}

--! hook love callbacks, so it can call multiple functions at once
-- @param name -- if love.x, then put it as "x"
function onee.love(name, func)
	onee.love_callbacks[name] = onee.love_callbacks[name] or {}
	
	local new = onee.love_callbacks[name] == {} and true
	if new then table.insert(onee.love_callbacks[name], love[name]) end
	
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
		love.graphics.clear(onee.colors.bg[1], onee.colors.bg[2], onee.colors.bg[3])
		love.graphics.printf(text, onee.width/2-150, onee.height-16, 150*2, "center")
	end)
	love.graphics.present()
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
