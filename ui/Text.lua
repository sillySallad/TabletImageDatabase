local lg = love.graphics

local makeText = require "Text"

local Text = {}
Text.__index = Text
Text.type = "Text"

function Text.create(width, height, text, font_size, event_func)
	assert(font_size)
	assert(type(width) == 'number')
	assert(type(height) == 'number')
	local self = setmetatable({}, Text)
	self.text = makeText(text, font_size)
	self.event_func = event_func
	self.width = width
	self.height = height
	return self
end

function Text.draw(self, w, h)
	lg.rectangle("line", 0, 0, w, h)
	local tw, th = self.text:getDimensions()
	lg.draw(self.text, (w - tw) / 2, (h - th) / 2)
end

function Text.getDimensions(self)
	return self.width, self.height
end

function Text.fireEventAt(self, x, y, w, h, ...)
	if self.event_func then
		return self.event_func(x, y, w, h, ...)
	end
end

return Text
