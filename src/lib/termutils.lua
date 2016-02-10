-- lib/termutils.lua
-- terminal utility library containing useful functions

local module = {}

-- if necessary, truncates the input string and adds an ellipsis (...) to the end to make it fit
function module.truncate(input, maxLen)
	return (#input <= maxLen and input) or (input:sub(1, maxLen - 3) .. "...")
end

-- generates a formatted table 
function module.table(data)
	-- sanity check
	assert(type(data) == "table", "expected table")

	-- get row/column counts
	local rowCount = #data
	local colCount = 0
	for _, v in ipairs(data) do
		if #v > colCount then
			colCount = #v
		end
	end

	-- truncate data and calculate widths
	local maxW = math.floor(term.getSize() / colCount)
	local widths = {}
	for _, row in ipairs(data) do
		for i, col in ipairs(row) do
			col = module.truncate(col, maxW)
			if not widths[i] then
				widths[i] = #col
			elseif widths[i] < #col then
				widths[i] = #col
			end
			row[i] = col
		end
	end

	print(textutils.serialize(widths))
end

return module