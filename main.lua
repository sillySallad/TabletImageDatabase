require "global_guard"

local lf = love.filesystem
local lg = love.graphics

lf.setIdentity("TabletImageDatabase")
lf._setAndroidSaveExternal(true)

lg.setDefaultFilter("linear", "linear")
lg.setDefaultMipmapFilter("linear")

local log = require "log"
local importer = require "importer"
local state = require "state"
local Font = require "Font"

print(collectgarbage('count'))

love.math.setRandomSeed(os.time())

assert(importer.importImages(
	state.database(),
	state.config():str("ImporterImportPath", "import"),
	state.config():str("ImporterImagePath", "images")
))

love.keyboard.setKeyRepeat(true)

require "touch_events"

local canvas = lg.newCanvas(lg.getDimensions())

function love.keypressed(key)
	if key == 'escape' then
		state.currentView():leave()
		state.currentView():refresh()
		state.redraw = true
	elseif key == 'backspace' then
		local view = state.currentView()
		local buffer = view:getBufferedText()
		local new = buffer:match("^(.-)[\x01-\x7F\xC0-\xFF][\x80-\xBF]*$")
		if new then
			view:setBufferedText(new)
			state.redraw = true
		end
	end
end

function love.textinput(text)
	local view = state.currentView()
	local buffer = view:getBufferedText()
	view:setBufferedText(buffer .. text)
	state.redraw = true
end

local debug_format = [[
FPS: %s
Lua: %s kiB
VRAM: %s MiB
Images: %s
Fonts: %s
Draw Calls: %s
Batched Draw Calls: %s]]

local font = Font(24)
local temp_text = lg.newText(font)
function love.draw()
	lg.setBackgroundColor(0.2, 0.2, 0.3)
	local sw, sh = lg.getDimensions()

	if state.redraw then
		local view = state.currentView()
		view:refreshGui()
		lg.setCanvas(canvas)
		lg.clear()
		view:draw(sw, sh)
		lg.setCanvas()
		state.redraw = false
	end

	lg.draw(canvas)

	if state.debug then
		local st = lg.getStats()

		local text = string.format(
			debug_format,
			love.timer.getFPS(),
			math.floor(collectgarbage('count')),
			math.floor(st.texturememory / 0x100000),
			st.images,
			st.fonts,
			st.drawcalls,
			st.drawcallsbatched
		)

		lg.setColor(0, 0, 0, 0.25)
		temp_text:set(text)
		local tw, th = temp_text:getDimensions()
		lg.rectangle("fill", 0, sh - th, tw, th)
		lg.setColor(1, 1, 1, 1)
		lg.draw(temp_text, 0, sh - th)

		st.texturememory = nil
		st.images = nil
		st.canvasswitches = nil
		st.shaderswitches = nil
		st.fonts = nil
		st.canvases = nil
		st.drawcalls = nil
		st.drawcallsbatched = nil

		local y = 100
		for k,v in pairs(st) do
			lg.setColor(0, 0, 0, 0.25)
			temp_text:set(string.format("%s = %s", k, v))
			local tw, th = temp_text:getDimensions()
			lg.rectangle("fill", 0, y, tw, th)
			lg.setColor(1, 1, 1, 1)
			lg.draw(temp_text, 0, y)
			y = y + th
		end
	end

	log.draw()
end

function love.resize(w, h)
	canvas = lg.newCanvas(w, h)
	state.redraw = true
end

function love.quit()
	state.database():flush()
	state.config():flush()
	state.tagDatabase():flush()
end

local orphans = importer.scanOrphanedImages(state.database(), "images")
for path in pairs(orphans) do
	log.warn("orphaned image: %s", path)
end

state.tagDatabase():prune()
