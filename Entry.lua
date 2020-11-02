local log = require "log"

local validation = require "validation"

local Entry = {}
Entry.__index = Entry

function Entry.create()
	local self = setmetatable({}, Entry)
	self.id = false
	self.hash = false
	self.title = false
	self.image_path = false
	self.tags = {}
	self.dirty = true
	return self
end

function Entry.validate(self)
	if not validation.isValidId(self.id) then
		return nil, "Entry.validate(): invalid id"
	end
	if type(self.image_path) ~= 'string' then
		return nil, "Entry.validate(): missing image path"
	end
	return true
end

function Entry.decode(str, path)
	local has_id = false
	local self = Entry.create()
	for line in str:gmatch("([^\n\r]+)") do
		local key,val = line:match("^(%w+)%=(.*)$")
		if key == 'id' then
			if not self:setId(tonumber(val)) then
				return nil, string.format("Entry.decode(): malformed id: '%s'", val)
			end
			has_id = true
		elseif key == 'title' then
			self:setTitle(val)
		elseif key == 'hash' then
			self:setHash(val)
		elseif key == 'imagePath' then
			self:setImagePath(val)
		elseif key == 'tags' then
			for tag in val:gmatch("(%S+)") do
				local ok, err = self:addTag(tag)
				if not ok then
					return nil, err
				end
			end
		else
			log.warn("unknown entry key: '%s'", key)
		end
	end
	if not has_id then
		log.error("%s: entry missing id", path or "?")
		return nil, "missing id"
	end
	self:clearDirty()
	return self
end

function Entry.encode(self)
	local t = {}
	local id = self:getId()
	if not id then
		return nil, "Entry.encode(): missing id"
	end
	table.insert(t, ("id=%d\n"):format(id))
	local image_path = self:getImagePath()
	if not image_path then
		return nil, "Entry.encode(): missing image path"
	end
	table.insert(t, ("imagePath=%s\n"):format(self.image_path))
	if self.title then
		table.insert(t, ("title=%s\n"):format(self.title))
	end
	if self.hash then
		table.insert(t, ("hash=%s\n"):format(self.hash))
	end
	local u = {}
	for tag, yes in pairs(self.tags) do
		if yes then
			table.insert(u, tag)
		end
	end
	table.insert(t, ("tags=%s\n"):format(table.concat(u, ' ')))
	return table.concat(t)
end

function Entry.setId(self, id)
	if not validation.isValidId(id) then
		return nil, "invalid id"
	end
	self.id = id
	self:setDirty(true)
	return self
end

function Entry.getId(self)
	return self.id or nil
end

function Entry.setHash(self, hash)
	assert(type(hash) == 'string')
	assert(not hash:find("[^0-9a-f]"))
	self.hash = hash
	self:setDirty(true)
	return self
end

function Entry.getHash(self)
	return self.hash or nil
end

function Entry.setTitle(self, title)
	assert(type(title) == 'string')
	self.title = title
	self:setDirty(true)
	return self
end

function Entry.getTitle(self)
	return self.title or nil
end

function Entry.setTag(self, tag, value)
	if not validation.isValidTag(tag) then
		return nil, "Entry.setTag(): invalid tag"
	end
	assert(value ~= nil)
	self.tags[tag] = not not value
	self:setDirty(true)
	return self
end

function Entry.getTag(self, tag)
	return self.tags[tag] or false
end

function Entry.addTag(self, tag)
	return self:setTag(tag, true)
end

function Entry.removeTag(self, tag)
	return self:setTag(tag, false)
end

function Entry.hasTag(self, tag)
	return self:getTag(tag)
end

function Entry.setImagePath(self, image_path)
	assert(type(image_path) == 'string')
	self.image_path = image_path
end

function Entry.getImagePath(self)
	return self.image_path or nil
end

function Entry.isDirty(self)
	return self.dirty
end

function Entry.setDirty(self, value)
	self.dirty = value
	return self
end

function Entry.clearDirty(self)
	self:setDirty(false)
	return self
end

return Entry
