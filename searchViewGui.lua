local lg = love.graphics

local state = require "state"
local ui = require "ui"
local ImageView = require "ImageView"
local Font = require "Font"
local Text = require "Text"

local font_size = state.config():num("SearchViewFontSize", 24)

local makeSwapPanelsButtons = require "makeSwapPanelsButtons"

local function makeRightUi(search_view, w, h)
	local image_grid = ui.Grid.create()
	for y = 0, 3 do
		image_grid:addRow()
		for x = 0, 3 do
			local ix, iy = x, y
			local idx = search_view.page + iy * 4 + ix
			local entry = search_view.result_images[idx]
			local item_w, item_h = w / 4, h / 4
			local item
			if entry then
				item = ui.Single.create(item_w, item_h, function(dw, dh)
					local path = entry:getImagePath()
					local image_entry = state.imageCache():get(path)
					local image = image_entry:getImage()
					local iw, ih = image:getDimensions()
					local scale = math.min(dw / iw, dh / ih)
					lg.push()
					lg.translate(dw / 2, dh / 2)
					lg.scale(scale)
					lg.translate(-iw / 2, -ih / 2)
					lg.draw(image)
					lg.pop()
				end,
				function(px, py, pw, ph, event)
					if event == 'tap' then
						state.setCurrentView(ImageView.create(entry, search_view.query_string))
						return true
					end
				end)
			else
				item = ui.Nothing.create(item_w, item_h)
			end
			image_grid:addChild(item)
		end
	end

	return image_grid
end

local plus_text = Text("+", font_size)
local minus_text = Text("-", font_size)
local unknown_text = Text("?", font_size)
local function makeTagButton(search_view, rtag, w)
	local bh = state.config():num("SearchViewTagButtonHeight", 40)
	local grid = ui.Grid.create()

	local plus = ui.Single.create(bh, bh,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			local tw, th = plus_text:getDimensions()
			local y = math.floor((dh - th) / 2)
			lg.draw(plus_text, (dw - tw) / 2, y)
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local pr = search_view:getTagPriority(rtag.entry.tag)
				search_view:setTagPriority(rtag.entry.tag, pr + 1)
				return true
			end
		end
	)
	grid:addRow()
	grid:addChild(plus)

	local minus = ui.Single.create(bh, bh,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			local tw, th = minus_text:getDimensions()
			local y = math.floor((dh - th) / 2)
			lg.draw(minus_text, (dw - tw) / 2, y)
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local pr = search_view:getTagPriority(rtag.entry.tag)
				search_view:setTagPriority(rtag.entry.tag, pr - 1)
				return true
			end
		end
	)
	grid:addChild(minus)

	local count_text = lg.newText(Font(font_size))
	local count = ui.Single.create(bh, bh,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			count_text:set(tostring(search_view:getTagPriority(rtag.entry.tag)))
			local tw, th = count_text:getDimensions()
			local y = math.floor((dh - th) / 2)
			lg.draw(count_text, (dw - tw) / 2, y)
		end
	)
	grid:addChild(count)

	local unknown = ui.Single.create(bh, bh,
		function(dw, dh)
			local unk = search_view:getTagUnknown(rtag.entry.tag)
			if unk then
				lg.rectangle("fill", 0, 0, dw, dh)
				local tw, th = unknown_text:getDimensions()
				local y = math.floor((dh - th) / 2)
				lg.setColor(0,0,0,1)
				lg.draw(unknown_text, (dw - tw) / 2, y)
				lg.setColor(1,1,1,1)
			else
				lg.rectangle("line", 0, 0, dw, dh)
				local tw, th = unknown_text:getDimensions()
				local y = math.floor((dh - th) / 2)
				lg.draw(unknown_text, (dw - tw) / 2, y)
			end
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				local unk = search_view:getTagUnknown(rtag.entry.tag)
				search_view:setTagUnknown(rtag.entry.tag, not unk)
				return true
			end
		end
	)
	grid:addChild(unknown)

	local number_text_width = 100

	local tag_text = Text(rtag.entry.tag, font_size)
	local tag_name = ui.Single.create(w - bh * 5 - number_text_width, bh,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			local tw, th = tag_text:getDimensions()
			local y = math.floor((dh - th) / 2)
			lg.draw(tag_text, y, y)
		end
	)
	grid:addChild(tag_name)

	local number_text = ui.Text.create(number_text_width, bh, tostring(state.database():getEntryCount() - rtag.entry.known), 24)
	grid:addChild(number_text)

	local poke = ui.Text.create(bh, bh, "P", font_size,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				for id, flag in rtag.entry:iterateKnown() do
					rtag.entry:set(id, flag)
				end
				search_view:refresh()
				return true
			end
		end
	)
	grid:addChild(poke)

	return grid
end

local function makeTags(search_view, w, h)
	local grid = ui.Grid.create()
	
	for tag, rtag in pairs(search_view.result_tags) do
		local row = ui.Grid.create()
		local button = makeTagButton(search_view, rtag, w)
		local bw, bh = button:getDimensions()
		local gw, gh = grid:getDimensions()
		if gh + bh > h then
			break
		end
		grid:addRow()
		grid:addChild(button)
	end

	return grid
end

local function makePageButtons(search_view, w)
	local grid = ui.Grid.create()
	local button_height = state.config():num("ButtonHeight", 40)
	grid:addRow()

	local prev_text = Text("< Prev", font_size)
	local next_text = Text("Next >", font_size)

	grid:addChild(ui.Single.create(button_height * 2, button_height,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			prev_text:set(search_view.query_string)
			local tw, th = prev_text:getDimensions()
			lg.draw(prev_text, (dw - tw) / 2, (dh - th) / 2)
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				search_view.page = math.max(1, search_view.page - 4 * 3)
				search_view:refreshImages()
				return true
			end
		end
	))

	grid:addChild(ui.Text.create(w - button_height * 4, button_height, "Debug", 24,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				state.debug = not state.debug
				return true
			end
		end
	))

	local max_page = #search_view.result_images
	max_page = (max_page - max_page % 4) + 1
	grid:addChild(ui.Single.create(button_height * 2, button_height,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			next_text:set(search_view.query_string)
			local tw, th = next_text:getDimensions()
			lg.draw(next_text, (dw - tw) / 2, (dh - th) / 2)
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				search_view.page = math.min(max_page, search_view.page + 4 * 3)
				search_view:refreshImages()
				return true
			end
		end
	))

	return grid
end

local function makeLeftUi(search_view, w, h)
	local grid = ui.Grid.create()
	grid:addRow()
	grid:addChild(ui.Nothing.create(w, 0))

	local text_field_height = state.config():num("TextFieldHeight", 50)

	local search_text = lg.newText(Font(font_size))
	grid:addRow()
	grid:addChild(ui.Single.create(w, text_field_height,
		function(dw, dh)
			lg.rectangle("line", 0, 0, dw, dh)
			search_text:set(search_view.query_string)
			local tw, th = search_text:getDimensions()
			lg.draw(search_text, (dw - tw) / 2, (dh - th) / 2)
		end,
		function(px, py, pw, ph, event, ix, iy)
			if event == 'tap' then
				love.keyboard.setTextInput(true, ix - px, iy - py, pw, ph)
				return true
			end
		end
	))

	grid:addRow()
	grid:addChild(makePageButtons(search_view, w))

	local gw, gh = grid:getDimensions()
	grid:addRow()
	grid:addChild(makeTags(search_view, w, h - gh))

	return grid
end

local function make(search_view)
	local fraction = state.config():num("SearchViewSplitFraction", 0.3)
	local w, h = lg.getDimensions()
	local wl = math.floor(w * fraction)
	local wr = w - wl

	local left = makeLeftUi(search_view, wl, h)
	local right = makeRightUi(search_view, wr, h)

	local grid = ui.Grid.create()
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
	layers:addChild(makeSwapPanelsButtons(search_view, w, h))

	return layers
end

return make