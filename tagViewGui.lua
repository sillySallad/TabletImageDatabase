local lg = love.graphics

local ui = require "ui"
local state = require "state"
local makeSwapPanelsButtons = require "makeSwapPanelsButtons"
local Font = require "Font"
local stringTest = require "stringTest"
local log = require "log"

local tag_font_size = state.config():num("TagViewTagFontSize", 24)
local tag_font = Font(tag_font_size)
local tag_height = state.config():num("TagViewTagHeight", 40)
local plus_text = lg.newText(tag_font, "+")
local zero_text = lg.newText(tag_font, "0")
local minus_text = lg.newText(tag_font, "-")
local function makeTag(tag_view, ltag, w)
	local grid = ui.Grid.create()
	grid:addRow()

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if ltag.implies then
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
				tag_view.entry:setImplies(ltag.tag, true)
				state.tagDatabase():getTag(ltag.tag):setImplies(tag_view.entry.tag, false)
				tag_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if not ltag.implies and not ltag.implied then
				lg.rectangle("fill", 0, 0, dw, dh)
				local tw, th = zero_text:getDimensions()
				lg.setColor(0, 0, 0)
				lg.draw(zero_text, (dw - tw) / 2, (dh - th) / 2)
				lg.setColor(1, 1, 1)
			else
				lg.rectangle("line", 0, 0, dw, dh)
				local tw, th = zero_text:getDimensions()
				lg.draw(zero_text, (dw - tw) / 2, (dh - th) / 2)
			end
		end,
		function(px, py, pw, ph, event)
			if event == 'tap' then
				tag_view.entry:setImplies(ltag.tag, false)
				state.tagDatabase():getTag(ltag.tag):setImplies(tag_view.entry.tag, false)
				tag_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Single.create(tag_height, tag_height,
		function(dw, dh)
			if ltag.implied then
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
				tag_view.entry:setImplies(ltag.tag, false)
				state.tagDatabase():getTag(ltag.tag):setImplies(tag_view.entry.tag, true)
				tag_view:refresh()
				return true
			end
		end
	))

	grid:addChild(ui.Text.create(w - tag_height * 3, tag_height, ltag.tag, tag_font_size))

	return grid
end

local function sortTagsFunc(item1, item2)
	if item1.string_score ~= item2.string_score then
		return item1.string_score > item2.string_score
	end

	if item1.implies ~= item2.implies then
		return not item2.implies
	end

	if item1.implied ~= item2.implied then
		return not item2.implied
	end

	if #item1.tag ~= #item2.tag then
		return #item1.tag < #item2.tag
	end

	return item1.tag < item2.tag
end

local function getTagList(tag_view)
	local tag_db = state.tagDatabase()
	local items = {}
	for etag, entry in tag_db:iterateEntries() do
		if etag ~= tag_view.entry.tag then
			local string_score = stringTest(tag_view:getBufferedText(), etag)
			local implies = tag_view.entry:getImplies(etag)
			local implied = entry:getImplies(tag_view.entry.tag)
			local item = {
				tag = etag,
				implies = implies,
				implied = implied,
				string_score = string_score,
			}
			table.insert(items, item)
		end
	end
	table.sort(items, sortTagsFunc)
	return items
end

local function makeTagsPanel(tag_view, ltags, w, h)
	local grid = ui.Grid.create()
	grid:addRow()
	grid:addChild(ui.Nothing.create(w, 0))

	for i, ltag in ipairs(ltags) do
		local button = makeTag(tag_view, ltag, w)
		local gw, gh = grid:getDimensions()
		local bw, bh = button:getDimensions()
		if gh + bh > h then
			break
		end
		grid:addRow()
		grid:addChild(button)
	end

	return grid
end

local function makeTags(tag_view, w, h)
	local grid = ui.Grid.create()

	local items = getTagList(tag_view)
	local active = {}
	local inactive = {}

	for i, ltag in ipairs(items) do
		if ltag.implies or ltag.implied then
			table.insert(active, ltag)
		else
			table.insert(inactive, ltag)
		end
	end

	local w2 = math.floor(w / 2)
	grid:addRow()

	local left = makeTagsPanel(tag_view, inactive, w2, h)
	local right = makeTagsPanel(tag_view, active, w - w2, h)

	if state.swap_panels then
		grid:addChild(left)
		grid:addChild(right)
	else
		grid:addChild(right)
		grid:addChild(left)
	end

	return grid
end

local function makeTextField(tag_view, w)
	return ui.Text.create(w, tag_height, tag_view:getBufferedText(), tag_font_size,
		function(px, py, pw, ph, event, ix, iy)
			if event == 'tap' then
				love.keyboard.setTextInput(true, ix - px, iy - py, pw, ph)
			end
		end
	)
end

local function makeBackButton(tag_view, w)
	return ui.Text(w, tag_height, "< Back", tag_font_size,
		function (px, py, pw, ph, event)
			if event == 'tap' then
				tag_view:leave()
				return true
			end
		end
	)
end

local function make(tag_view)
	local w, h = lg.getDimensions()

	local grid = ui.Grid.create()

	grid:addRow()
	grid:addChild(makeTextField(tag_view, w))

	do
		local gw, gh = grid:getDimensions()
		local tags = makeTags(tag_view, w, h - gh)
		grid:addRow()
		grid:addChild(tags)
	end

	local swap = makeSwapPanelsButtons(tag_view, w, h)

	local layers = ui.Over.create()
	layers:addChild(grid)
	layers:addChild(swap)

	return layers
end

return make
