local lg = love.graphics

local makeText = require "Text"

local Text = {}
Text.__index = Text
Text.type = "Text"

function Text.create(width, height, text, event_func)
	assert(type(width) == 'number')
	assert(type(height) == 'number')
	assert(type(text) == 'string')
	assert(type(event_func) ~= 'number')
	assert(event_func == nil or type(event_func) == 'function')
	local self = setmetatable({}, Text)
	self.text = makeText(text, math.ceil(height))
	self.event_func = event_func
	self.width = width
	self.height = height
	return self
end

function Text.draw(self, w, h)
	lg.rectangle("line", 0, 0, w, h)
	local tw, th = self.text:getDimensions()
	local scale = math.min(w / tw, h / th)
	lg.draw(self.text, w / 2, h / 2, 0, scale, scale, tw / 2, th / 2)
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
