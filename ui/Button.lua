local lg = love.graphics

local makeText = require "Text"

local Button = {}
Button.__index = Button
Button.type = "Button"

function Button.create(width, height, text, event_func, active_func)
	assert(type(width) == 'number')
	assert(type(height) == 'number')
	assert(type(text) == 'string')
	assert(type(event_func) ~= 'number')
	assert(event_func == nil or type(event_func) == 'function')
	assert(active_func == nil or type(active_func) == 'function')
	local self = setmetatable({}, Button)
	self.text = makeText(text, math.ceil(height))
	self.event_func = event_func
	self.active_func = active_func
	self.width = width
	self.height = height
	return self
end

function Button.draw(self, dw, dh)
	local tw, th = self.text:getDimensions()
	local scale = math.min(dw / tw, dh / th)

	local active = self.active_func and self.active_func()
	if active then
		lg.rectangle("fill", 0, 0, dw, dh)
		lg.setColor(0,0,0,1)
		lg.draw(self.text, dw / 2, dh / 2, 0, scale, scale, tw / 2, th / 2)
		lg.setColor(1,1,1,1)
	else
		lg.rectangle("line", 0, 0, dw, dh)
		lg.draw(self.text, dw / 2, dh / 2, 0, scale, scale, tw / 2, th / 2)
	end
end

function Button.getDimensions(self)
	return self.width, self.height
end

function Button.fireEventAt(self, x, y, w, h, event, ...)
	if event == 'tap' and self.event_func then
		self.event_func()
		return true
	end
	return false
end

return Button
