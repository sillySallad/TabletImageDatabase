local lg = love.graphics

local Grid = {}
Grid.__index = Grid
Grid.type = "Grid"

function Grid.create()
	local self = setmetatable({}, Grid)
	self.rows = {}
	return self
end

local function getDetailedDimensions(self)
	local wt = {}
	local ht = {}
	for y,row in ipairs(self.rows) do
		for x,child in ipairs(row) do
			local cw, ch = child:getDimensions()
			assert(cw and ch, child.type)
			if not wt[x] or wt[x] < cw then wt[x] = cw end
			if not ht[y] or ht[y] < ch then ht[y] = ch end
		end
	end
	return wt, ht
end

local function iterateChildren(self, func, ...)
	local wt, ht = getDetailedDimensions(self)
	local dy = 0
	for y,row in ipairs(self.rows) do
		local height = ht[y] or 0
		local dx = 0
		for x,child in ipairs(row) do
			local width = wt[x] or 0
			if func(self, child, dx, dy, width, height, ...) then
				return true
			end
			dx = dx + width
		end
		dy = dy + height
	end
end

function Grid.addRow(self)
	table.insert(self.rows, {})
end

function Grid.addChild(self, child)
	assert(child, "no child provided")
	assert(#self.rows > 0, "need to add a row before any items")
	table.insert(self.rows[#self.rows], child)
end

local function drawFunc(self, child, dx, dy, width, height)
	lg.push()
	lg.translate(dx, dy)
	child:draw(width, height)
	lg.pop()
	return false
end

function Grid.draw(self, w, h)
	iterateChildren(self, drawFunc)
end

function Grid.getDimensions(self)
	local wt, ht = getDetailedDimensions(self)
	local w, h = 0, 0
	for k,v in ipairs(wt) do
		w = w + v
	end
	for k,v in ipairs(ht) do
		h = h + v
	end
	return w, h
end

local function fireEventAtFunc(self, child, dx, dy, width, height, px, py, ...)
	px, py = px - dx, py - dy
	if px < 0 or py < 0 then
		return false
	end
	if px < width and py < height then
		return child:fireEventAt(px, py, width, height, ...)
	end
	return false
end

function Grid.fireEventAt(self, x, y, w, h, ...)
	return iterateChildren(self, fireEventAtFunc, x, y, ...) or false
end

return Grid
