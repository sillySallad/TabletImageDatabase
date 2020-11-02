local lg = love.graphics

local Font = require "Font"

local do_traceback = false

local log = {}

local function fmtArg(fmt, ...)
	if fmt then
		return fmt:format(...)
	else
		return (...)
	end
end

function log.info(fmt, ...)
	local msg = fmtArg(fmt, ...)
	if do_traceback then
		msg = debug.traceback(msg, 2)
	end
	log.put(("Info: %s"):format(fmtArg(fmt, ...)))
end

function log.warn(fmt, ...)
	local msg = fmtArg(fmt, ...)
	if do_traceback then
		msg = debug.traceback(msg, 2)
	end
	log.put(("Warn: %s"):format(fmtArg(fmt, ...)))
end

function log.error(fmt, ...)
	local msg = fmtArg(fmt, ...)
	if do_traceback then
		msg = debug.traceback(msg, 2)
	end
	log.put(("Error: %s"):format(msg))
end

function log.put(str)
	local time = love.timer.getTime()
	table.insert(log.history, 1, {
		text = str,
		time = time,
	})
end

local step = 30
local font = Font(step)
local delay = 10
function log.draw()
	lg.setFont(font)
	local w, h = lg.getDimensions()
	local y = 0
	for k,v in ipairs(log.history) do
		lg.setColor(0, 0, 0, 0.5)
		lg.rectangle("fill", 0, y, w, step)
		lg.setColor(1, 1, 1, 1)
		lg.print(v.text, 0, y)
		y = y + step
		if y > h then
			break
		end
	end
	local time = love.timer.getTime()
	while log.history[1] and log.history[#log.history].time + delay < time do
		log.history[#log.history] = nil
	end
end

log.history = {}

return log
