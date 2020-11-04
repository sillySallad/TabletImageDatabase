local lg = love.graphics

local state = require "state"
local tagViewGui = require "tagViewGui"

local TagView = {}
TagView.__index = TagView

function TagView.create(tag_entry)
	local self = setmetatable({}, TagView)

	self.entry = tag_entry
	self.gui = false
	self.text_field = ""

	return self
end

function TagView.getGui(self)
	if not self.gui then
		self.gui = tagViewGui(self)
	end
	return self.gui
end

function TagView.refreshGui(self)
	self.gui = false
end

function TagView.draw(self)
	local w, h = lg.getDimensions()
	self:getGui():draw(w, h)
end

function TagView.fireEventAt(self, ...)
	return self:getGui():fireEventAt(...)
end

function TagView.enter(self)
	self.back_view = state.currentView()
	state.setCurrentView(self)
	self:refresh()
end

function TagView.refresh(self)
	self:refreshGui()
end

function TagView.leave(self)
	state.setCurrentView(self.back_view)
end

function TagView.getBufferedText(self)
	return self.text_field
end

function TagView.setBufferedText(self, text)
	self.text_field = text
	self:refresh()
end

return TagView
