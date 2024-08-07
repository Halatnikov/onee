-- Simple Device driver for Yui, only depends on LÖVE 2D, listens to
-- keyboard and mouse pointer.

local Device = {}
Device.__index = Device

function Device.new()
    return setmetatable({
        px = nil, py = nil,
        clicking = nil,

        confirm = nil,
        cancel = nil,
        up = nil,
        left = nil,
        down = nil,
        right = nil,
    }, Device)
end

function Device:snapshot()
    local snap = {}

    -- Mouse pointer
    local px,py = window.mouse()
    local clicking = love.mouse.isDown(1)

    snap.px,snap.py = px,py
    snap.pointing = clicking
    snap.clicked = self.clicking and not clicking
    snap.pointer = px ~= self.px or py ~= self.py or snap.clicked or snap.pointing

    -- Keyboard input
    local confirm = love.keyboard.isDown("return") or (not (self.clicking or clicking) and input.a)
    local cancel = love.keyboard.isDown("escape") or (not (self.clicking or clicking) and input.b)
    local up = love.keyboard.isDown("up") or input.up
    local left = love.keyboard.isDown("left") or input.left
    local down = love.keyboard.isDown("down") or input.down
    local right = love.keyboard.isDown("right") or input.right

    snap.confirm = self.confirm and not confirm
    snap.cancel = self.cancel and not cancel
    snap.up = self.up and not up
    snap.left = self.left and not left
    snap.down = self.down and not down
    snap.right = self.right and not right
    snap.action = snap.confirm or snap.cancel or
                  snap.up or snap.left or snap.down or snap.right

    -- Update old state
    self.px,self.py = px,py
    self.clicking = clicking
    self.confirm,self.cancel = confirm,cancel
    self.left,self.up,self.right,self.down = left,up,right,down

    return snap
end

return Device
