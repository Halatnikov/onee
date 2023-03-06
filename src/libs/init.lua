require("src/libs/utils")

--

require("src/libs/tserial")
json = require("src/libs/json")

-- nuklear gui

if love._os == "Windows" then nuklear = require("nuklear") end

if nuklear then
gui = nuklear.newUI()

function love.keypressed_nuklear(key, scancode, isrepeat) if gui:keypressed(key, scancode, isrepeat) then return end end
function love.keyreleased(key, scancode) if gui:keyreleased(key, scancode) then return end end
function love.mousepressed_nuklear(x, y, button, istouch, presses) if gui:mousepressed(x, y, button, istouch, presses) then return end end
function love.mousereleased(x, y, button, istouch, presses) if gui:mousereleased(x, y, button, istouch, presses) then return end end
function love.mousemoved(x, y, dx, dy, istouch) if gui:mousemoved(x, y, dx, dy, istouch) then return end end
function love.textinput(text) if gui:textinput(text) then return end end
function love.wheelmoved_nuklear(x, y) if gui:wheelmoved(x, y) then return end end
end