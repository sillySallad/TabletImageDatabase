local lg = love.graphics

local Font = require "Font"

local weak_key = {__mode="k"}
local weak_value = {__mode="v"}

local text_cache = setmetatable({}, weak_key)

local function getLine(fnt)
	local line = text_cache[fnt]
	if not line then
		line = setmetatable({}, weak_value)
		text_cache[fnt] = line
	end
	return line
end

local function Text(str, size)
	local fnt = Font(size)
	local line = getLine(fnt)
	local txt = line[str]
	if not txt then
		txt = lg.newText(fnt, str)
		line[str] = txt
	end
	return txt
end

return Text
