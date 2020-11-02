local fs = require "fs"
local stringTest = require "stringTest"
local TagEntry = require "TagEntry"
local log = require "log"
local tag_name = require "tag_name"

local TagDatabase = {}
TagDatabase.__index = TagDatabase

function TagDatabase.create(path)
	love.filesystem.createDirectory(path)

	local self = setmetatable({}, TagDatabase)

	local entries = {}

	for i, filename in ipairs(fs.enumerate(path)) do
		local name = filename:match("/([^/%.]*)%.txt$")
		local tag = tag_name.nameToTag(name)
		local entry = TagEntry.create(self, filename, tag)
		entries[tag] = entry
	end

	self.path = path
	self.entries = entries

	return self
end

function TagDatabase.get(self, id, tag)
	local entry = self.entries[tag]
	if entry then
		return entry:get(id)
	end
	return nil
end

function TagDatabase.set(self, id, tag, value)
	if tag == "" then
		log.info("Can't create a tag with empty name")
		return
	end
	local entry = self.entries[tag]
	if not entry then
		local name = tag_name.tagToName(tag)
		local path = string.format("%s/%s.txt", self.path, name)
		self.entries[tag] = TagEntry.create(self, path, tag)
	end
	self.entries[tag]:set(id, value)
end

function TagDatabase.getAll(self, id)
	local tags = {}
	for tag, entry in pairs(self.entries) do
		if entry:get(id) then
			table.insert(tags, tag)
		end
	end
	return tags
end

local function searchSort(item1, item2)
	local d1, d2 = item1.score, item2.score
	if d1 == d2 then
		return #item1.entry.tag < #item2.entry.tag
	end
	return d1 > d2
end

function TagDatabase.search(self, str)
	local t = {}
	for tag, entry in pairs(self.entries) do
		local score = stringTest(str, entry.tag)
		table.insert(t, {entry = entry, score = score})
	end
	table.sort(t, searchSort)
	for i, item in ipairs(t) do
		t[i] = item.entry
	end
	return t
end

function TagDatabase.getTag(self, tag)
	return self.entries[tag]
end

function TagDatabase.flush(self)
	for i, entry in pairs(self.entries) do
		entry:flush()
	end
end

function TagDatabase.iterateEntries(self)
	return pairs(self.entries)
end

function TagDatabase.prune(self)
	for tag, entry in pairs(self.entries) do
		entry:prune()
	end
end

function TagDatabase.getImplications(self, tag, transitive)
	local seen = {}
	local queue = {tag}
	repeat
		local tag = table.remove(queue)
		if not tag then
			break
		end
		local entry = self:getTag(tag)
		if entry then
			for imp in pairs(entry.implies) do
				if not seen[imp] then
					seen[imp] = true
					table.insert(queue, imp)
				end
			end
		end
	until not transitive
	return seen
end

function TagDatabase.getImpliedBy(self, tag, transitive)
	local seen = {}
	local queue = {tag}
	repeat
		local tag = table.remove(queue)
		if not tag then
			break
		end
		for etag, entry in self:iterateEntries() do
			if entry.implies[tag] then
				if not seen[etag] then
					seen[etag] = true
					table.insert(queue, etag)
				end
			end
		end
	until not transitive
	return seen
end

return TagDatabase
