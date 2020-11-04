local lg = love.graphics
local lf = love.filesystem

local state = require "state"
local log = require "log"

-- an alias for self-documentation
local none = false

local function fireEventAt(x, y, ...)
	local view = state.currentView()
	local w, h = lg.getDimensions()
	if view:fireEventAt(x, y, w, h, ...) then
		state.redraw = true
	end
end

local function tap(x, y)
	fireEventAt(x, y, "tap", x, y)
end

local function hold(x, y)
	fireEventAt(x, y, "hold", x, y)
end

local function pinch(zoom, x, y, ix, iy)
	fireEventAt(ix, iy, "pinch", ix, iy, zoom, x, y)
end

local function pan(ix, iy, dx, dy)
	fireEventAt(ix, iy, "pan", ix, iy, dx, dy)
end

local finger_move_threshold = state.config():num("FingerMoveThreshold", 10)

local function fingerMove(self, x, y)
	self.ox, self.oy = self.x, self.y
	self.x, self.y = x, y
	local d = math.sqrt((self.ix-x)^2+(self.iy-y)^2)
	if d > finger_move_threshold then
		self.hasmoved = true
	end
end

local function Finger(id, ix, iy)
	return { x=ix, y=iy, ox=ix, oy=iy, ix=ix, iy=iy, id=id, when=0, hasmoved=false, move=fingerMove }
end

local first_finger, second_finger = none, none
local mouse_finger = none

function love.mousepressed(x, y, key)
	mouse_finger = Finger(none, x, y)
end

function love.mousereleased(x, y, key)
	if not first_finger then
		local m = mouse_finger
		if m and not m.hasmoved then
			tap(m.ix, m.iy)
		end
	end
	mouse_finger = none
end

function love.wheelmoved(dx, dy)
	local mx, my = love.mouse.getPosition()
	pinch((2^(1/3))^dy, mx, my, mx, my)
end

function love.mousemoved(x, y, dx, dy)
	local m = mouse_finger
	if m and not first_finger then
		if m then
			if m.hasmoved then
				pan(m.ix, m.iy, x - m.x, y - m.y)
			end
			m:move(x, y)
		end
	end
end

function love.touchpressed(id, x, y)
	if not first_finger then
		first_finger = Finger(id, x, y)
	elseif not second_finger then
		second_finger = Finger(id, x, y)
	end
end

function love.touchreleased(id, x, y)
	if first_finger and first_finger.id == id then
		if second_finger then
			first_finger, second_finger = second_finger, none
		else
			if not first_finger.hasmoved then
				tap(first_finger.ix, first_finger.iy)
			end
			first_finger = none
		end
	end
	if second_finger and second_finger.id == id then
		second_finger = none
	end
end

function love.touchmoved(id, x, y, dx, dy)
	local f, s = first_finger, second_finger
	if f and f.id == id then f:move(x, y) end
	if s and s.id == id then s:move(x, y) end
	if f then
		if s then
			local oz = math.sqrt((f.ox-s.ox)^2+(f.oy-s.oy)^2)
			local z = math.sqrt((f.x-s.x)^2+(f.y-s.y)^2)
			pinch(z / oz, (f.x+s.x)/2, (f.y+s.y)/2, f.ix, f.iy)
		else
			pan(f.ix, f.iy, f.x - f.ox, f.y - f.oy)
		end
	end
end
