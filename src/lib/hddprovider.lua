-- lib/hddprovider.lua
-- provides a hdd to the file system

local provider = {}

function provider.openFile(root, file, mode)
	return fs.open(file, mode)
end

function provider.deleteFile(root, file)
	return fs.delete(file)
end

function provider.exists(root, file)
	return fs.exists(file)
end

function provider.getFiles(root, path)
	return fs.list(path)
end

function provider.isDirectory(root, path)
	return fs.isDir(path)
end

function provider.makeDir(root, path)
	return fs.makeDir(path)
end

function provider.move(root, from, to)
	return fs.move(from, to)
end

function provider.copy(root, from, to)
	return fs.copy(from, to)
end

return provider