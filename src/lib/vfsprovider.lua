-- lib/vfsprovider.lua
-- provides an in-memory filesystem

local provider = {}
local files = {
	test = {
		file = "ayy lmao"
	}
}

local function getElement(root, path)
	local normalised = system.paths.normalise(path, true)

	local prev = files[root]
	if prev == nil then
		return error("invalid path")
	end

	local current = nil

	for elem in normalised:gmatch("[^%/]+") do
		current = prev[elem]

		if current == nil then
			return error("invalid path")
		end

		prev = current
	end

	return current
end

function provider.openFile(root, file, mode)
	print(root .. " " .. file)
	local elem = getElement(root, file)
end

function provider.exists(root, file)

end

return provider