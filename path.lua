local path = {}

function path.combine(dir, name)
	if dir:sub(-1) == '/' then
		return dir .. name
	end
	return ("%s/%s"):format(dir, name)
end

return path
