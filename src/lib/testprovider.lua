-- lib/testprovider.lua
-- a test file provider

local provider = {}

function provider.openFile(file, mode)
	return {
		write = function() end,
		writeLine = function() end,

		read = function() return 0 end,
		readAll = function() return "test" end,
		readLine = function() return "test" end,

		close = function() end
	}
end

function provider.exists(file)
	return true
end

function provider.isDirectory(file)
	return false
end

function provider.deleteFile(file)

end

return provider