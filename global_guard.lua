local log = require "log"

setmetatable(_G, {
	__index = function(g, k)
		local msg = string.format("attempted read of global variable '%s'", k)
		log.error(nil, debug.traceback(msg, 2))
		error(msg)
	end,
	__newindex = function(g, k, v)
		local msg = string.format("attempted write of '%s' to global variable '%s'", v, k)
		log.error(nil, debug.traceback(msg, 2))
		error(msg)
	end,
})
