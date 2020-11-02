local lg = love.graphics

local ui = require "ui"
local state = require "state"
local TagView = require "TagView"

local stringTest = require "stringTest"
local makeSwapPanelsButtons = require "makeSwapPanelsButtons"
local Font = require "Font"

local function enforceBounds(self, iw, ih, dw, dh)
	local min_scale = math.min(dw / iw, dh / ih)
	if self.scale < min_scale then
		self.scale = min_scale
	end
	local scale = self.scale
	local wl, hl = iw * scale < dw, ih * scale < dh
	if wl then
		self.pan_x = 0
	else
		local w2, i2 = dw / 2, iw * scale / 2
		local range = i2 - w2
		self.pan_x = math.max(math.min(self.pan_x, range), -range)
	end
	if hl then
		self.pan_y = 0
	else
		local w2, i2 = dh / 2, ih * scale / 2
		local range = i2 - w2
		self.pan_y = math.max(math.min(self.pan_y, range), -range)
	end
end

local function pan(self, ix, iy, dx, dy)
	self.pan_x = self.pan_x + dx
	self.pan_y = self.pan_y + dy
end

local function pinch(self, zoom, x, y, ix, iy, dw, dh)
	self.scale = self.scale * zoom
	x = x - dw / 2
	y = y - dh / 2
	self.pan_x = (self.pan_x - x) * zoom + x
	self.pan_y = (self.pan_y - y) * zoom + y
end

local function makeRightUi(image_view, w, h)
	local image = ui.Single.create(w, h,
	function(dw, dh)
		local image_entry = state.imageCache():get(image_view.entry:getImagePath())
		local image = image_entry:getImage()
		local iw, ih = image:getDimensions()
		enforceBounds(image_view, iw, ih, dw, dh)
		local px, py = lg.transformPoint(0, 0)
		lg.setScissor(px, py, w, h)
		lg.push()
		lg.setColor(1, 1, 1, 1)
		lg.translate(dw / 2, dh / 2)
		lg.translate(image_view.pan_x, image_view.pan_y)
		lg.scale(image_view.scale)
		lg.draw(image, 0, 0, 0, 1, 1, iw / 2, ih / 2)
		lg.pop()
		lg.setScissor()
	end,
	function(px, py, pw, ph, event, ix, iy, arg1, arg2, arg3)
		if event == 'pinch' then
			ix = ix - px
			iy = iy - py
			pinch(image_view, arg1, arg2 - ix, arg3 - iy, px, py, pw, ph)
			return true
		elseif event == 'pan' then
			pan(image_view, px, py, arg1, arg2)
			return true
		end
	end)

	return image
end

local function sortTagsFunc(item1, item2)
	if item1.string_score ~= item2.string_score then
		return item1.string_score > item2.string_score
	end

	if not item1.unknown ~= not item2.unknown then
		return not item2.unknown
	end

	if not item1.present ~= not item2.present then
		return not item2.present
	end

	if not item1.absent ~= not item2.absent then
		return not item2.absent
	end

	local tag1, tag2 = item1.entry.tag, item2.entry.tag
	if #tag1 ~= #tag2 then
		return #tag1 < #tag2
	end

	return tag1 < tag2
end

local function getTagList(image_view)
	local id = image_view.entry:getId()
	local qstr = image_view.text_field
	local items = {}

	for tag, entry in state.tagDatabase():iterateEntries() do
		local has = entry:get(id)
		local string_score = stringTest(qstr, tag)
		local item = {
			entry = entry,
			string_score = string_score,
		}
		if has == true then
			item.present = true
		elseif has == false then
			item.absent = true
		elseif has == nil then
			item.unknown = true
		end
		table.insert(items, item)
	end

	table.sort(items, sortTagsFunc)

	return items
end

local tag_font_size = state.config():num("ImageViewTagFontSize", 24)
local tag_font = Font(tag_font_size)
local tag_height = state.config():num("ImageViewTagHeight", 40)
local plus_text = lg.newText(tag_font, "+")
local minus_text = lg.newText(tag_font, "-")
local question_text = lg.newText(tag_font, "?")
local function makeTag(image_view, ltag, w)
	local grid = ui.Grid.create()
	grid:addRow()

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if ltag.present then
				lg.rectangle("fill", 0, 0, dw, dh)
				local tw, th = plus_text:getDimensions()
				lg.setColor(0, 0, 0)
				lg.draw(plus_text, (dw - tw) / 2, (dh - th) / 2)
				lg.setColor(1, 1, 1)
			else
				lg.rectangle("line", 0, 0, dw, dh)
				local tw, th = plus_text:getDimensions()
				lg.draw(plus_text, (dw - tw) / 2, (dh - th) / 2)
			end
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local id = image_view.entry:getId()
				ltag.entry:set(id, true)
				local tag_db = state.tagDatabase()
				local implications = tag_db:getImplications(ltag.entry.tag, true)
				for tag in pairs(implications) do
					tag_db:set(id, tag, true)
				end
				image_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if ltag.absent then
				lg.rectangle("fill", 0, 0, dw, dh)
				local tw, th = minus_text:getDimensions()
				lg.setColor(0, 0, 0)
				lg.draw(minus_text, (dw - tw) / 2, (dh - th) / 2)
				lg.setColor(1, 1, 1)
			else
				lg.rectangle("line", 0, 0, dw, dh)
				local tw, th = minus_text:getDimensions()
				lg.draw(minus_text, (dw - tw) / 2, (dh - th) / 2)
			end
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local id = image_view.entry:getId()
				ltag.entry:set(id, false)
				local tag_db = state.tagDatabase()
				local implications = tag_db:getImpliedBy(ltag.entry.tag, true)
				for tag in pairs(implications) do
					tag_db:set(id, tag, false)
				end
				image_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if ltag.unknown then
				lg.rectangle("fill", 0, 0, dw, dh)
				local tw, th = question_text:getDimensions()
				lg.setColor(0, 0, 0)
				lg.draw(question_text, (dw - tw) / 2, (dh - th) / 2)
				lg.setColor(1, 1, 1)
			else
				lg.rectangle("line", 0, 0, dw, dh)
				local tw, th = question_text:getDimensions()
				lg.draw(question_text, (dw - tw) / 2, (dh - th) / 2)
			end
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				ltag.entry:set(image_view.entry:getId(), nil)
				image_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Text.create(w - tag_height * 4, tag_height, ltag.entry.tag, tag_font_size))

	grid:addChild(ui.Text.create(tag_height, tag_height, "E", tag_font_size,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				TagView.create(ltag.entry):enter()
				return true
			end
		end
	))

	return grid
end

local function makeTags(image_view, w, h)
	local grid = ui.Grid.create()

	local tags_list = getTagList(image_view)
	for i, ltag in ipairs(tags_list) do
		local tag = makeTag(image_view, ltag, w)
		local tw, th = tag:getDimensions()
		local gw, gh = grid:getDimensions()
		if th + gh > h then
			break
		end
		grid:addRow()
		grid:addChild(tag)
	end

	return grid
end

local function makeLeftUi(image_view, w, h)
	local grid = ui.Grid.create()

	local back_button_height = state.config():num("BackButtonHeight", 50)
	grid:addRow()
	grid:addChild(ui.Text.create(w, back_button_height, "< Back", 24,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local search_view = state.searchView()
				state.setCurrentView(search_view)
				search_view:refresh()
				return true
			end
		end
	))

	local text_field_height = state.config():num("TextFieldHeight", 40)

	local info = ui.Grid.create()
	do
		local id = ui.Text.create(w, text_field_height, "id: " .. tostring(image_view.entry:getId()), tag_font_size)
		local hash = ui.Text.create(w, text_field_height, "md5: " .. tostring(image_view.entry:getHash()), tag_font_size)
		info:addRow()
		info:addChild(id)
		info:addRow()
		info:addChild(hash)
	end
	grid:addRow()
	grid:addChild(info)

	local row = ui.Grid.create()
	row:addRow()
	row:addChild(ui.Text.create(w - text_field_height, text_field_height, image_view.text_field, 24,
		function(px, py, pw, ph, event, ix, iy)
			if event == 'tap' then
				love.keyboard.setTextInput(true, ix - px, iy - py, pw, ph)
			end
		end
	))

	row:addChild(ui.Text.create(text_field_height, text_field_height, "+", 24,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local id = image_view.entry:getId()
				state.tagDatabase():set(id, image_view.text_field, true)
				image_view:refresh()
				return true
			end
		end
	))

	grid:addRow()
	grid:addChild(row)

	local gw, gh = grid:getDimensions()
	grid:addRow()
	grid:addChild(makeTags(image_view, gw, h - gh))

	return grid
end

local function make(image_view)
	local fraction = state.config():num("ImageViewSplitFraction", 0.3)
	local w, h = lg.getDimensions()
	local wl = math.floor(w * fraction)
	local wr = w - wl

	local grid = ui.Grid.create()

	local left = makeLeftUi(image_view, wl, h)
	local right = makeRightUi(image_view, wr, h)

	grid:addRow()
	if state.swap_panels then
		grid:addChild(right)
		grid:addChild(left)
	else
		grid:addChild(left)
		grid:addChild(right)
	end

	local layers = ui.Over.create()
	layers:addChild(grid)
	layers:addChild(makeSwapPanelsButtons(image_view, w, h))

	return layers
end

return make
