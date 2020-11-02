local lf = love.filesystem

local fs = {}

function fs.enumerate(dir)
	local items = lf.getDirectoryItems(dir)
	for k, name in ipairs(items) do
		items[k] = ("%s/%s"):format(dir, name)
	end
	return items
end

return fs
