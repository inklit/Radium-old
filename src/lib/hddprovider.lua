-- lib/hddprovider.lua
-- provides a hdd to the file system

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

function provider.getFiles(path)
	return fs.list(path)
end

function provider.isDirectory(path)
	return fs.isDir(path)
end

function provider.makeDir(path)
	return fs.makeDir(path)
end

function provider.move(from, to)
	return fs.move(from, to)
end

function provider.copy(from, to)
	return fs.copy(from, to)
end

return provider