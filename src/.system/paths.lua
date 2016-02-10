-- .system/paths.lua
-- Creates and provides manipulation for library and binary paths

local module = {}

-- specifies paths to search for binaries in
local PATH = "/bin:.:/rom/programs"

do
	if term.isColour() then
		PATH = PATH .. ":/rom/programs/advanced"
	end

	if turtle then
		PATH = PATH .. ":/rom/programs/turtle"
	else
		PATH = PATH .. ":/rom/programs/rednet:/rom/programs/fun"

		if term.isColour() then
			PATH = PATH .. ":/rom/programs/fun/advanced"
		end
	end

	if pocket then
		PATH = PATH .. ":/rom/programs/pocket"
	end

	if commands then
		PATH = PATH .. ":/rom/programs/command"
	end

	if http then
		PATH = PATH .. ":/rom/programs/http"
	end

	-- ew
end

-- specifies paths to search for libraries in
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

function module.path()
	return PATH
end

function module.libPath()
	return LIB_PATH
end

function module.pathExtensions()
	return PATH_EXT
end

function module.libExtensions()
	return LIB_EXT
end

function module.normalise(p, isAbs)
	p = p:gsub("\\", "/")

	if p:sub(1, 1) ~= "/" or p:match("^%s-$") ~= nil then
		if isAbs then
			p = "/" .. p
		else
			p = "./" .. p
		end
	end

	if p:sub(#p, #p) == "/" and p:match("^%.?%/$") == nil then
		p = p:sub(1, #p - 1)
	end

	return p
end

module.normalize = module.normalise

-- create setter functions

function module.setPath(p)
	assert(type(p) == "string", "expected string")
	PATH = p
end

function module.setLibPath(p)
	assert(type(p) == "string", "expected string")
	LIB_PATH = p
end

function module.setPathExtensions(e)
	assert(type(e) == "string", "expected string")
	PATH_EXT = e
end

function module.setLibExtensions(e)
	assert(type(e) == "string", "expected string")
	LIB_EXT = e
end

function module.getNameNoExt(path)
	local name = fs.getName(path)
	local noext = name:match("(.-)%.(.+)")
	return noext
end

function module.resolve(paths, exts, name, workingDir)
	assert(type(paths) == "string", "expected string, string, string, [string]")
	assert(type(exts) == "string", "expected string, string, string, [string]")
	assert(type(name) == "string", "expected string, string, string, [string]")
	assert(workingDir == nil or type(workingDir) == "string", "expected string, string, string, [string]")
	for base in paths:gmatch("([^:]+)") do
		local s = base:sub(1,1)
		if not (s == "/" or s == "\\") then
			base = fs.combine(workingDir or "", base)
		end
		if fs.exists(base) and fs.isDir(base) then
			local files = fs.list(base)
			for i, file in ipairs(files) do
				for ext in exts:gmatch("([^:]+)") do
					ext = ext:gsub("%*", "(.+)")
					if file:match(ext) then
						if file:gsub(ext, "%1") == name then
							local r = fs.combine(base, file)
							if fs.exists(r) and not fs.isDir(r) then
								return r
							end
						end
					end
				end
			end
		end
	end
end

return module