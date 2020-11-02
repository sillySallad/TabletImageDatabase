local Nothing = {}
Nothing.__index = Nothing
Nothing.type = "Nothing"

function Nothing.create(width, height)
	local self = setmetatable({}, Nothing)
	self.width = width or 0
	self.height = height or 0
	return self
end

function Nothing.draw(self, w, h)
	-- no-op
end

function Nothing.getDimensions(self)
	return self.width, self.height
end

function Nothing.fireEventAt(self, x, y, w, h, ...)
	-- no-op
end

return Nothing
