local state = require "state"
local ui = require "ui"

local function makeSwapPanelsButtons(view, w, h)
	local button = ui.Text.create(100, 30, "Swap Panels", function(px, py, pw, ph, event)
		if event == 'tap' then
			state.swap_panels = not state.swap_panels
			view:refreshGui()
			return true
		end
	end)

	local bw, bh = button:getDimensions()

	local grid = ui.Grid.create()
	grid:addRow()
	grid:addChild(ui.Nothing.create(0, h - bh))
	grid:addRow()
	grid:addChild(button)
	grid:addChild(ui.Nothing.create(w - bw * 2, 0))
	grid:addChild(button)

	return grid
end

return makeSwapPanelsButtons
