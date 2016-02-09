-- lib/hddprovider.lua
-- provides a hdd to the file system

local fs = ccfs
local provider = {}

function provider.openFile(file, mode)
	return fs.open(file, mode)
end

function provider.deleteFile(file)
	return fs.delete(file)
end

function provider.exists(file)
	return fs.exists(file)
end

return provider