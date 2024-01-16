function love.load()
	require("onee")
end

function love.quit()
	
end

-- main loop
function love.update(dt)
	onee.update(dt)
end

function love.draw()
	onee.draw()
end
