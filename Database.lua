local lf = love.filesystem

local log = require "log"
local fs = require "fs"
local validation = require "validation"
local Entry = require "Entry"

local Database = {}
Database.__index = Database

function Database.create(db_root)
	local self = setmetatable({}, Database)
	self.db_root = db_root
	self.next_id = 1
	self.entries = {}
	self.entry_count = 0
	lf.createDirectory(db_root)
	self:load()
	self.load = false
	return self
end

function Database.load(self)
	for _, path in ipairs(fs.enumerate(self.db_root)) do
		local data = lf.read(path)
		local entry, err = Entry.decode(data)
		if entry then
			self:addEntry(entry)
		else
			log.error("Database.load(): %s", err)
		end
	end
end

function Database.addEntry(self, entry)
	local id = entry:getId()
	if not id then
		log.error("Database.addEntry(): entry missing id")
		return nil, "malformed entry"
	end
	if self.entries[id] then
		log.error("entry with is of %d already exists", id)
		return nil, "duplicate entry"
	end
	self.entries[id] = entry
	if self.next_id <= id then
		self.next_id = id + 1
	end
	self.entry_count = self.entry_count + 1
	return self
end

function Database.getEntry(self, id)
	if not validation.isValidId(id) then
		return nil, "Database.getEntry(): invalid id"
	end
	local entry = self.entries[id]
	if not entry then
		return false, "Database.getEntry(): no such entry"
	end
	return entry
end

function Database.nextId(self)
	local id = self.next_id
	self.next_id = id + 1
	return id
end

function Database.saveEntry(self, entry)
	local id, iderr = entry:getId()
	if id then
		local path = self:getEntryPathFromId(id)
		local str, strerr = entry:encode()
		if str then
			assert(lf.write(path, str))
			entry:clearDirty()
		else
			return nil, string.format("Database.saveEntry(): %s", strerr)
		end
	else
		return nil, string.format("Database.saveEntry(): %s", iderr)
	end
	return true
end

function Database.flush(self)
	for k,entry in pairs(self.entries) do
		if entry:isDirty() then
			local ok, err = self:saveEntry(entry)
			if not ok then
				log.error("Database.flush(): %s", err)
			end
		end
	end
	return true
end

function Database.getEntryPathFromId(self, id)
	if not validation.isValidId(id) then
		return nil, "invalid id"
	end
	return ("%s/%d.txt"):format(self.db_root, id)
end

function Database.iterateEntries(self)
	return pairs(self.entries)
end

function Database.getEntryCount(self)
	return self.entry_count
end

return Database
