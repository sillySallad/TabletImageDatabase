local Single = {}
Single.__index = Single
Single.type = "Single"

function Single.create(width, height, draw_func, event_func)
	assert(type(width) == 'number')
	assert(type(height) == 'number')
	local self = setmetatable({}, Single)
	self.draw_func = draw_func
	self.event_func = event_func
	self.width = width
	self.height = height
	return self
end

function Single.draw(self, w, h)
	self.draw_func(w, h)
end

function Single.getDimensions(self)
	return self.width, self.height
end

function Single.fireEventAt(self, x, y, w, h, ...)
	if self.event_func then
		return self.event_func(x, y, w, h, ...)
	end
end

return Single
