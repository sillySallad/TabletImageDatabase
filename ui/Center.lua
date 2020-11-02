local lg = love.graphics

local Center = {}
Center.__index = Center
Center.type = "Center"

function Center.create(child)
	local self = setmetatable({}, Center)
	self.child = child
	return self
end

function Center.draw(self, w, h)
	local cw, ch = self.child:getDimensions()
	lg.push()
	lg.translate((w - cw) / 2, (h - ch) / 2)
	self.child:draw(cw, ch)
	lg.pop()
end

function Center.getDimensions(self)
	return self.child:getDimensions()
end

function Center.fireEventAt(self, x, y, w, h, ...)
	local cw, ch = self.child:getDimensions()
	x, y = x - (w - cw) / 2, y - (h - ch) / 2
	if x < 0 or y < 0 then
		return false
	end
	if x < cw and y < ch then
		return self.child:fireEventAt(x, y, cw, ch, ...)
	end
	return false
end

return Center
