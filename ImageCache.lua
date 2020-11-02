local ImageCacheEntry = require "ImageCacheEntry"
local state = require "state"
local log = require "log"

local ImageCache = {}
ImageCache.__index = ImageCache

function ImageCache.create()
	local self = setmetatable({}, ImageCache)
	self.capacity = state.config():num("ImageCacheCapacity", 80)
	self.entries = {}
	return self
end

function ImageCache.get(self, path)
	assert(path)
	for _, entry in ipairs(self.entries) do
		if path == entry.path then
			return entry
		end
	end
	local entry = ImageCacheEntry.create(self, path)
	table.insert(self.entries, entry)
	while #self.entries > self.capacity do
		local min = math.huge
		local key = false
		for k,v in ipairs(self.entries) do
			if v.time <= min then
				min = v.time
				key = k
			end
		end
		table.remove(self.entries, key)
	end
	return entry
end

return ImageCache
