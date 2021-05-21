local li = require "love.image"

local image_load_request_channel = love.thread.getChannel "image_load_requests"
local image_load_done_channel = love.thread.getChannel "image_load_done"

while true do
	local request = image_load_request_channel:demand()
	if love.filesystem.getInfo(request.filename) then
		local ok, image = pcall(li.newImageData, request.filename)
		if ok then
			image_load_done_channel:push{
				status = 'ok',
				filename = request.filename,
				image = image,
			}
		else
			image_load_done_channel:push{
				status = 'unsupported',
				filename = request.filename,
			}
		end
	else
		image_load_done_channel:push{
			status = 'missing',
			filename = request.filename,
		}
	end
	print(request.filename)
end
