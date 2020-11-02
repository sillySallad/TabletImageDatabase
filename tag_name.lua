local tag_name = {}

local function charToHex(ch)
	local n = string.byte(ch)
	return string.format("-%02X", n)
end

function tag_name.tagToName(tag)
	return tag:gsub("([^a-zA-Z0-9_])", charToHex)
end

local function hexToChar(hex)
	return string.char(tonumber(hex, 16))
end

function tag_name.nameToTag(name)
	return name:gsub("%-(%x%x)", hexToChar)
end

return tag_name
