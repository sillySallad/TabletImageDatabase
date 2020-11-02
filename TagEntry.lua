local log = require "log"
local state = require "state"
local tag_name = require "tag_name"

local TagEntry = {}
TagEntry.__index = TagEntry

function TagEntry.create(tag_database, path, tag)
	assert(path)
	assert(tag)

	local self = setmetatable({}, TagEntry)

	local ids = {}
	local category = "unknown"
	local brk = 0
	local usages = 0
	local known = 0
	local implies = {}

	if love.filesystem.getInfo(path) then
		for line in love.filesystem.lines(path) do
			local key, value = line:match("^(%w+)%=(.-)$")
			if key == 'ids' then
				for ch in value:gmatch("([012])") do
					brk = brk + 1
					if ch ~= '0' then
						local present = ch == '2'
						ids[brk] = present
						if present then
							usages = usages + 1
						end
						known = known + 1
					end
				end
			elseif key == 'category' then
				category = value
			elseif key == 'implies' then
				for imp_name in value:gmatch("(%S+)") do
					local imp_tag = tag_name.nameToTag(imp_name)
					implies[imp_tag] = true
				end
			else
				log.warn("TagEntry.create(): invalid tag file line: %q", line)
			end
		end
	end

	self.path = path
	self.tag = tag
	self.category = category
	self.ids = ids
	self.dirty = false
	self.usages = usages
	self.known = known
	self.implies = implies
	self.db = tag_database

	return self
end

-- returns:
-- true, if tag is present on id.
-- false, if it's known absent.
-- or nil, if it's unknown whether it applies to id.
function TagEntry.get(self, id)
	return self.ids[id]
end

local function setRaw(self, id, value)
	if self.ids[id] == value then
		return
	end

	if not self.ids[id] ~= not value then
		local delta = value and 1 or -1
		self.usages = self.usages + delta
	end

	local from_unknown = self.ids[id] == nil
	local to_unknown = value == nil
	if from_unknown ~= to_unknown then
		local delta = from_unknown and 1 or -1
		self.known = self.known + delta
	end

	self.ids[id] = value
	self.dirty = true
end

local function setRecursive(self, id, value, seen)
	if seen[self.tag] then
		return
	end
	seen[self.tag] = true
	if type(id) ~= 'number' or id <= 0 or id % 1 ~= 0 then
		log.error("TagEntry.set(): id must be a positive integer, not %q", tostring(id))
		return
	end
	if value ~= true and value ~= false and value ~= nil then
		log.error("TagEntry.set(): value must be true, false, or nil, not %q", tostring(value))
		return
	end

	local impls = self.db:getImplications(self.tag, false)
	for tag in pairs(impls) do
		local entry = self.db:getTag(tag)
		setRecursive(entry, id, true, seen)
	end
	local impld = self.db:getImpliedBy(self.tag, true)
	for tag in pairs(impld) do
		local entry = self.db:getTag(tag)
		setRecursive(entry, id, false, seen)
	end

	setRaw(self, id, value)
end

function TagEntry.set(self, id, value)
	setRecursive(self, id, value, {})
end

function TagEntry.flush(self)
	if self.dirty then
		local data = self:encode()
		assert(love.filesystem.write(self.path, data))
		self.dirty = false
	end
end

function TagEntry.encode(self)
	local t = {}
	table.insert(t, string.format("category=%s\n", self.category))
	local brk = 0
	for k in pairs(self.ids) do
		if brk < k then
			brk = k
		end
	end
	local u = {}
	for i = 1, brk do
		local val = '0'
		local v = self.ids[i]
		if v == true then
			val = '2'
		elseif v == false then
			val = '1'
		end
		u[i] = val
	end
	table.insert(t, string.format("ids=%s\n", table.concat(u)))
	local implies = {}
	for tag, v in pairs(self.implies) do
		local name = tag_name.tagToName(tag)
		table.insert(implies, name)
	end
	table.insert(t, string.format("implies=%s\n", table.concat(implies, ' ')))
	return table.concat(t)
end

function TagEntry.prune(self)
	local db = state.database()
	for id, value in pairs(self.ids) do
		if not db:getEntry(id) then
			log.warn("Removing tag %s from invalid id %s", self.tag, id)
			self:set(id, nil)
		end
	end
end

function TagEntry.getImplies(self, tag)
	return self.implies[tag] or false
end

function TagEntry.setImplies(self, tag, value)
	self.implies[tag] = value or nil
	self.dirty = true
end

function TagEntry.iterateKnown(self)
	return pairs(self.ids)
end

return TagEntry
