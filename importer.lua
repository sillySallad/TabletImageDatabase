local lf = love.filesystem

local fs = require "fs"
local Entry = require "Entry"
local log = require "log"

local importer = {}

local function charToHex(char)
	return ("%02x"):format(char:byte())
end

function importer.importImages(database, from_path, to_path)
	lf.createDirectory(from_path)
	lf.createDirectory(to_path)

	for k,name in ipairs(lf.getDirectoryItems(from_path)) do
		local source_path = string.format("%s/%s", from_path, name)
		local ext = name:match("(%.[^%.]+)$")
		if not ext then
			return nil, "importer.importImages(): source image has no file extension"
		end
		local file_data = lf.read(source_path)
		local hash = love.data.hash("md5", file_data):gsub(".", charToHex)
		local image_path = string.format("%s/%s%s", to_path, hash, ext)
		if not lf.getInfo(image_path) then
			local id = database:nextId()
			local entry = Entry.create()

			entry:setId(id)
			entry:setTitle(name)
			entry:setHash(hash)
			entry:setImagePath(image_path)

			local ok, err = entry:validate()
			if not ok then
				return nil, string.format("importer.importImages(): %s", err)
			end

			assert(lf.write(image_path, file_data))

			database:addEntry(entry)
			database:saveEntry(entry)

			lf.remove(source_path)
		else
			log.error("Image %q collides with %q", image_path, source_path)
		end
	end
	return true
end

local function listReferencedImagePaths(database)
	local t = {}
	for k,entry in pairs(self.entries) do
		local image_path = entry:getImagePath()
		t[image_path] = true
	end
	return t
end

function importer.scanOrphanedImages(database, images_path)
	local all_images = {}
	for _,path in ipairs(fs.enumerate(images_path)) do
		all_images[path] = true
	end
	for id,entry in database:iterateEntries() do
		local path = entry:getImagePath()
		local b = all_images[path]
		all_images[path] = false
		if b == nil then
			log.error("importer.scanOrphanedImages(): id %d references missing image: %s", entry:getId(), path)
		end
	end
	for k,v in pairs(all_images) do
		if not v then
			all_images[k] = nil
		end
	end
	return all_images
end

return importer
