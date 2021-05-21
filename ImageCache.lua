local ImageCacheEntry = require "ImageCacheEntry"
local state = require "state"
local log = require "log"

local missing_image = love.graphics.newImage("resource/missing.png")
local unsupported_image = love.graphics.newImage("resource/unsupported.png")

local image_loader_thread = nil
local image_load_request_channel = love.thread.getChannel "image_load_requests"
local image_load_done_channel = love.thread.getChannel "image_load_done"

local ImageCache = {}
ImageCache.__index = ImageCache

function ImageCache.create()
	local self = setmetatable({}, ImageCache)
	self.capacity = state.config():num("ImageCacheCapacity", 32)
	self.entries = {}

	assert(not image_loader_thread, "there can only be one ImageCache")
	image_loader_thread = love.thread.newThread("image_loader_thread.lua")
	image_loader_thread:start()

	return self
end

function ImageCache.get(self, path)
	local entry = self:findEntry(path)
	if entry then
		return entry
	end
	entry = ImageCacheEntry.create(self, path)
	table.insert(self.entries, entry)
	image_load_request_channel:push{ filename = path }
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

function ImageCache.findEntry(self, path)
	assert(path)
	for _, entry in ipairs(self.entries) do
		if path == entry.path then
			return entry
		end
	end
end

function ImageCache.update(self)
	local any = false
	while true do
		local response = image_load_done_channel:pop()
		if not response then
			break
		end
		local entry = self:findEntry(response.filename)
		if not entry then
			log.warn("Image Loader Thread processed an image that was not needed by the ImageCache")
			goto cont
		end
		if response.status == 'ok' then
			entry.image = love.graphics.newImage(response.image, { mipmaps=true })
		elseif response.status == 'missing' then
			entry.image = missing_image
		else
			entry.image = unsupported_image
		end
		any = true
		::cont::
	end
	if any then
		state.reset_pan = true
	end
	return any
end

return ImageCache
