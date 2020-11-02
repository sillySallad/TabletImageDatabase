-- compare how well the string 'test' fits into 'against'
-- returns a number whose exact meaning is implementation-defined,
-- but larger numbers are better.
local function cmp(test, against)
	assert(test, "test string missing")
	assert(against, "string to compare against missing")
	local i, j = 1, 1
	while i <= #test do
		if j > #against then
			return 0
		end
		if test:byte(i,i) == against:byte(j,j) then
			i = i + 1
		end
		j = j + 1
	end
	return 1
end

return cmp
