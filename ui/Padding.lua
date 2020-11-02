local lg = love.graphics

local Padding = {}
Padding.__index = Padding
Padding.type = "Padding"

function Padding.create(child, left, top, right, bottom)
	local self = setmetatable({}, Padding)
	self.left = left
	self.top = top
	self.right = right
	self.bottom = bottom
	self.child = child
	return self
end

function Padding.draw(self, w, h)
	lg.push()
	lg.translate(self.left, self.top)
	self.child:draw(w - (self.left + self.right), h - (self.top + self.bottom))
	lg.pop()
end

function Padding.getDimensions(self)
	local w, h = self.child:getDimensions()
	return w + (self.left + self.right), h + (self.top + self.bottom)
end

function Padding.fireEventAt(self, x, y, w, h, ...)
	x, y = x - self.left, y - self.top
	if x < 0 or y < 0 then
		return false
	end
	local cw, ch = self.child:getDimensions()
	if x < cw and y < ch then
		return self.child:fireEventAt(x, y, cw, ch, ...)
	end
	return false
end

return Padding
