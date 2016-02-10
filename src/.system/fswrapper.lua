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

return fs