local lg = love.graphics

local Over = {}
Over.__index = Over
Over.type = "Over"

function Over.create()
	local self = setmetatable({}, Over)
	self.children = {}
	return self
end

function Over.addChild(self, child)
	assert(child, "no child provided")
	table.insert(self.children, child)
end

function Over.draw(self, w, h)
	for i, child in ipairs(self.children) do
		child:draw(w, h)
	end
end

function Over.getDimensions(self)
	local w, h = 0, 0
	for i, child in ipairs(self.children) do
		local cw, ch = child:getDimensions()
		w = math.max(w, cw)
		h = math.max(h, ch)
	end
	return w, h
end

function Over.fireEventAt(self, x, y, w, h, ...)
	for i = #self.children, 1, -1 do
		local child = self.children[i]
		if child:fireEventAt(x, y, w, h, ...) then
			return true
		end
	end
	return false
end

return Over
