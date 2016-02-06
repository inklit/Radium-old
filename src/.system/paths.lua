-- .system/paths.lua
-- Creates and provides manipulation for library and binary paths

-- specifies paths to search for binaries in
-- paths can direct to files or directories
local PATH = "/bin:.:/rom/programs"

-- specifies paths to search for libraries in
-- paths can direct to files or directories
local LIB_PATH = "/lib:."

-- specifies patterns to match filenames to when searching for binaries
-- the * wildcard will match multiple of any character
-- delimited by colons (:)
local PATH_EXT = "*.lua:*"

-- specifies patterns to match filenames to when searching for libraries
-- the * wildcard will match multiple of any character
-- delimited by colons (:)
local LIB_EXT = "*.lua:*"

-- create getter functions

function system.path()
	return PATH
end

function system.libPath()
	return LIB_PATH
end

function system.pathExtensions()
	return PATH_EXT
end

function system.libExtensions()
	return LIB_EXT
end

-- create setter functions

function system.setPath(p)
	assert(type(p) == "string", "expected string")
	PATH = p
end

function system.setLibPath(p)
	assert(type(p) == "string", "expected string")
	LIB_PATH = p
end

function system.setPathExtensions(e)
	assert(type(e) == "string", "expected string")
	PATH_EXT = e
end

function system.setLibExtensions(e)
	assert(type(e) == "string", "expected string")
	LIB_EXT = e
end

-- create resolve functions

local function combine(base, path)
	-- combines the path with the base unless path is absolute
	local s = path:sub(1, 1)
	if s == "/" or s == "\\" then
		return path
	else
		return fs.combine(base, path)
	end
end

-- TODO