local lg = love.graphics

local loading_image = lg.newImage("resource/loading.png")

local ImageCacheEntry = {}
ImageCacheEntry.__index = ImageCacheEntry

function ImageCacheEntry.create(image_cache, path)
	local self = setmetatable({}, ImageCacheEntry)
	self.image_cache = image_cache
	self.path = path
	self.image = loading_image
	self.time = math.huge
	return self
end

function ImageCacheEntry.getImage(self)
	self.time = love.timer.getTime()
	if not self.image then
		assert(false)
		local ok, image = pcall(love.graphics.newImage, self.path, { mipmaps=true })
		if ok then
			self.image = image
		elseif not love.filesystem.getInfo(self.path) then
			self.image = missing_image
		else
			self.image = unsupported_image
		end
	end
	return self.image
end

return ImageCacheEntry
