local log = require "log"

local Configuration = {}
Configuration.__index = Configuration

function Configuration.create(path)
	assert("Configuration.create(): no path provided")
	local self = setmetatable({}, Configuration)
	self.path = path
	local numbers = {}
	local strings = {}
	-- local bools = {}
	if love.filesystem.getInfo(path) then
		for line in love.filesystem.lines(path) do
			if not line:find("^%s*$") then
				local typ, key, value = line:match("^%s*([ns])(%w+)%=(.-)$")
				if not typ then
					log.warn("invalid config line: %q", line)
				else
					if typ == 'n' then
						local num = tonumber(value)
						if not num then
							log.warn("malformed number when parsing config line: %q", line)
						else
							numbers[key] = num
						end
					elseif typ == 's' then
						strings[key] = value
					end
				end
			end
		end
	end
	self.strings = strings
	self.numbers = numbers
	return self
end

function Configuration.num(self, key, default)
	if not self.numbers[key] then
		log.info("creating config number key: %s=%s", key, default or 20)
		self.numbers[key] = default
		self.dirty = true
	end
	return self.numbers[key]
end

function Configuration.str(self, key, default)
	if not self.strings[key] then
		log.info("creating config string key: %s=%s", key, default or "")
		self.strings[key] = default
		self.dirty = true
	end
	return self.strings[key]
end

function Configuration.flush(self)
	if self.dirty then
		local t = {}
		for k,v in pairs(self.numbers) do
			table.insert(t, string.format("n%s=%s\n", k, v))
		end
		for k,v in pairs(self.strings) do
			table.insert(t, string.format("s%s=%s\n", k, v))
		end
		local data = table.concat(t)
		assert(love.filesystem.write(self.path, data))
	end
end

return Configuration
