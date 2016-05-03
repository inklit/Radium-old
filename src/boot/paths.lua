-- boot/paths.lua
-- path utility functions

local paths = {}

-- default paths
paths.LIBPATH = ".:lib:/lib:/rom/apis"
paths.LIBEXT = "lua"
paths.PATH = "/bin:/rom/programs:."
paths.PATHEXT = "lua"

local function resolve(base, path)
	local s = path:sub(1,1)
	if s == "/" or s == "\\" then
		return fs.combine("", path)
	else
		return fs.combine(base, path)
	end
end

function paths.possibilities(name, path, exts, cwd)
	system.expect(name, "string", 1)
	system.expect(path, "string", 2)
	system.expect(exts, "string", 3)
	system.expect(cwd, "string", 4, true)

	local output = {}
	cwd = cwd or ""
	for part in path:gmatch("([^:]+)") do
		part = resolve(cwd, part)
		for ext in exts:gmatch("([^:]+)") do
			table.insert(output, fs.combine(part, name .. "." .. ext))
		end
		table.insert(output, fs.combine(part, name))
	end
	return output
end

function paths.locateFile(name, path, exts, cwd)
	system.expect(name, "string", 1)
	system.expect(path, "string", 2)
	system.expect(exts, "string", 3)
	system.expect(cwd, "string", 4, true)

	for i, v in ipairs(paths.possibilities(name, path, exts, cwd)) do
		if fs.exists(v) and not fs.isDir(v) then
			return v
		end
	end
end

return paths
