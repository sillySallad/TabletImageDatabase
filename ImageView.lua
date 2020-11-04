local imageViewGui = require "imageViewGui"

local state = require "state"

local ImageView = {}
ImageView.__index = ImageView

function ImageView.create(db_entry, search_string)
	local self = setmetatable({}, ImageView)

	self.gui = false
	self.pan_x = 0
	self.pan_y = 0
	self.scale = 0
	self.entry = db_entry
	self.text_field = search_string

	return self
end

function ImageView.getGui(self)
	if not self.gui then
		self.gui = imageViewGui(self)
	end
	return self.gui
end

function ImageView.draw(self)
	local w, h = love.graphics.getDimensions()
	self:getGui():draw(w, h)
end

function ImageView.fireEventAt(self, ...)
	return self:getGui():fireEventAt(...)
end

function ImageView.getBufferedText(self)
	return self.text_field
end

function ImageView.setBufferedText(self, text)
	self.text_field = text
	self.gui = false
end

function ImageView.refresh(self)
	self:refreshGui()
end

function ImageView.leave(self)
	local search_view = state.searchView()
	state.setCurrentView(search_view)
	search_view:refresh()
end

function ImageView.refreshGui(self)
	self.gui = false
end

return ImageView
