local lg = love.graphics

local ui = require "ui"
local state = require "state"

local stringTest = require "stringTest"

local View = {}
View.__index = View

local searchViewGui = require "searchViewGui"

function View.create(database)
	assert(database, "View.create(): no database passed");
	local self = setmetatable({}, View)

	self.gui = false
	self.database = database
	self.query_string = ""
	self.result_tags = {}
	self.query_tags = {}
	self.result_images = {}
	self.page = 1

	self:refresh()

	return self
end

local function getGui(self)
	if not self.gui then
		self.gui = searchViewGui(self)
	end
	return self.gui
end

function View.draw(self)
	local w, h = lg.getDimensions()
	getGui(self):draw(w, h)
end

function View.fireEventAt(self, ...)
	return getGui(self):fireEventAt(...)
end

local function findQueryTag(self, tag)
	assert(tag)
	for i, qtag in ipairs(self.query_tags) do
		if qtag.entry.tag == tag then
			return i, qtag
		end
	end
	return nil, nil
end

local function sortTagResults(item1, item2)
	local score1, score2 = item1.string_score, item2.string_score
	if score1 ~= score2 then
		return score1 > score2
	end

	local qtag1, qtag2 = item1.qtag, item2.qtag
	if not qtag1 ~= not qtag2 then
		return not qtag2
	end

	if qtag1 then
		if qtag1.unknown ~= qtag2.unknown then
			return qtag1.unknown
		end

		if qtag1.priority ~= qtag2.priority then
			return qtag1.priority > qtag2.priority
		end
	end

	local k1, k2 = item1.entry.known, item2.entry.known
	if k1 ~= k2 then
		return k1 < k2
	end

	local tag1, tag2 = item1.entry.tag, item2.entry.tag
	if #tag1 ~= #tag2 then
		return #tag1 < #tag2
	end

	return tag1 < tag2
end

function View.setQueryString(self, str)
	self.query_string = str
	self:refreshTags()
end

function View.refreshTags(self)
	local str = self.query_string:lower()
	local items = {}
	for tag, entry in state.tagDatabase():iterateEntries() do
		local string_score = stringTest(str, tag:lower())
		local qtag = self.query_tags[tag] or false
		local item = {
			entry = entry,
			string_score = string_score,
			qtag = qtag,
		}
		table.insert(items, item)
	end
	table.sort(items, sortTagResults)
	self.result_tags = items
	self:refreshGui()
end

function View.getTagPriority(self, tag)
	local qtag = self.query_tags[tag]
	return qtag and qtag.priority or 0
end

local function getQueryTag(self, tag)
	assert(tag)
	local qtag = self.query_tags[tag]
	if qtag then
		return qtag
	end

	qtag = {priority = 0, unknown = false}
	self.query_tags[tag] = qtag
	return qtag
end

local function trimQueryTag(self, tag)
	local qtag = self.query_tags[tag]
	if qtag and qtag.priority == 0 and not qtag.unknown then
		self.query_tags[tag] = nil
	end
end

function View.setTagPriority(self, tag, priority)
	local qtag = getQueryTag(self, tag)
	qtag.priority = priority
	trimQueryTag(self, tag)
	self:refresh()
end

function View.refreshImages(self)
	local result = {}

	local tag_database = state.tagDatabase()
	for i, entry in state.database():iterateEntries() do
		local id = entry:getId()
		local allow = true
		for tag, qtag in pairs(self.query_tags) do
			local priority = qtag.priority

			local has = tag_database:get(id, tag)

			if (priority > 0 and not has) or (priority < 0 and has) or (qtag.unknown and has ~= nil) then
				allow = false
				break
			end
		end
		if allow then
			table.insert(result, entry)
		end
	end

	local rev = {}
	for i = #result, 1, -1 do
		rev[#rev + 1] = result[i]
	end

	self.result_images = rev
	self:refreshGui()
end

function View.getTagUnknown(self, tag)
	local qtag = self.query_tags[tag]
	return qtag and qtag.unknown
end

function View.setTagUnknown(self, tag, unknown)
	assert(tag)
	local qtag = getQueryTag(self, tag)
	qtag.unknown = unknown
	trimQueryTag(self, tag)
	self:refreshTags()
	self:refreshImages()
end

function View.getBufferedText(self)
	return self.query_string
end

function View.setBufferedText(self, text)
	self:setQueryString(text)
end

function View.refresh(self)
	self:refreshTags()
	self:refreshImages()
	self:refreshGui()
end

function View.leave(self)
	love.event.quit()
end

function View.refreshGui(self)
	self.gui = false
end

return View
