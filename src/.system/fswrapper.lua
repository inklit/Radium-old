-- .system/fswrapper.lua
-- implements the fs api using system.filesys

function fs.exists(path)
	return system.filesys.exists(path)
end

function fs.list(path)
	return system.filesys.getFiles(path)
end

function fs.isDir(path)
	return system.filesys.isDirectory(path)
end

function fs.makeDir(path)
	return system.filesys.makeDir(path)
end

function fs.delete(path)
	return system.filesys.deleteFile(path)
end

function fs.move(from, to)
	return system.filesys.move(from, to)
end

function fs.copy(from, to)
	return system.filesys.copy(from, to)
end

function fs.open(file, mode)
	return system.filesys.openFile(file, mode)
end

return fs