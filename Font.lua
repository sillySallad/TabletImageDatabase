local lg = love.graphics

local weak = {__mode="kv"}

local font_cache = setmetatable({}, weak)

local function Font(size)
	if not font_cache[size] then
		font_cache[size] = lg.newFont(size)
	end
	return font_cache[size]
end

return Font
