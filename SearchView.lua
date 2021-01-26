local lg = love.graphics

local log = require "log"
local state = require "state"
local stringTest = require "stringTest"
local ImageView = require "ImageView"
local searchViewGui = require "searchViewGui"
local tag_name = require "tag_name"

local View = {}
View.__index = View

local save_filename = state.config():str("SearchViewQuerySaveFilename", "search_query.txt")

function View.create(database)
	assert(database, "View.create(): no database passed");
	local self = setmetatable({}, View)

	local query_tags = {}
	local query_string = ""

	if love.filesystem.getInfo(save_filename) then
		for line in love.filesystem.lines(save_filename) do
			local key, value = line:match("^(%w+)%=(.-)$")
			if key == "QueryString" then
				query_string = tag_name.nameToTag(value)
			elseif key == "QueryTags" then
				for item in value:gmatch("(%S+)") do
					local name, prio, unk = item:match("^(.-)%=(%-?%d+)(%??)$")
					if name then
						local tag = tag_name.nameToTag(name)
						local priority = assert(tonumber(prio))
						local unknown = unk ~= ''
						query_tags[tag] = {priority = priority, unknown = unknown}
					else
						log.error("invalid query tag %q in %s", item, save_filename)
					end
				end
			else
				log.error("invalid key %q in %s", key, save_filename)
			end
		end
	end

	self.gui = false
	self.database = database
	self.query_string = query_string
	self.result_tags = {}
	self.query_tags = query_tags
	self.result_images = {}
	self.page = 1
	self.query_dirty = false
	self.order_tags_by_length = false

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

function View.setQueryString(self, str)
	if self.query_string ~= str then
		self.query_string = str
		self.query_dirty = true
		self:refreshTags()
	end
end

local function sortTagResults_pre(item1, item2)
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

	return nil
end

local function sortTagResultsPreferMostUnknown(item1, item2)
	local flag = sortTagResults_pre(item1, item2)
	if flag ~= nil then
		return flag
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

local function sortTagResultsPreferShortName(item1, item2)
	local flag = sortTagResults_pre(item1, item2)
	if flag ~= nil then
		return flag
	end

	local tag1, tag2 = item1.entry.tag, item2.entry.tag
	if #tag1 ~= #tag2 then
		return #tag1 < #tag2
	end

	local k1, k2 = item1.entry.known, item2.entry.known
	if k1 ~= k2 then
		return k1 < k2
	end

	return tag1 < tag2
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
	local sorter = sortTagResultsPreferMostUnknown
	if self.order_tags_by_length then
		sorter = sortTagResultsPreferShortName
	end
	table.sort(items, sorter)
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
	if qtag.priority ~= priority then
		qtag.priority = priority
		self.query_dirty = true
		trimQueryTag(self, tag)
		self:refresh()
	end
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

			local a = priority > 0 and has
			local b = priority < 0 and not has
			local c = qtag.unknown and has == nil

			local good = a or b or c

			if not good then
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
	unknown = not not unknown
	if qtag.unknown ~= unknown then
		qtag.unknown = unknown
		self.query_dirty = true
		trimQueryTag(self, tag)
		self:refreshTags()
		self:refreshImages()
	end
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

function View.enterRandomImage(self)
	local len = #self.result_images
	if len < 1 then
		return false
	end
	local index = love.math.random(1, len)
	local entry = self.result_images[index]
	local image_view = ImageView.create(entry, self.query_string)
	state.setCurrentView(image_view)
	return true
end

function View.getImageCount(self)
	return #self.result_images
end

function View.encode(self)
	local t = {}
	for tag, qtag in pairs(self.query_tags) do
		table.insert(t, string.format(
			"%s=%d%s",
			tag_name.tagToName(tag),
			qtag.priority or 0,
			qtag.unknown and "?" or ""
		))
	end
	local out = {}
	table.insert(out, string.format("QueryString=%s\n", tag_name.tagToName(self.query_string)))
	table.insert(out, string.format("QueryTags=%s\n", table.concat(t, " ")))
	return table.concat(out)
end

function View.flush(self)
	if self.query_dirty then
		love.filesystem.write(save_filename, self:encode())
	end
end

return View
