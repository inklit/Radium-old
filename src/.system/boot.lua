-- .system/boot.lua
-- Run on startup, loads core functions and the system API

local system = {}

system.version = 0.1
system.name = "Radium " .. system.version

-- universally compatible loadfile replacement with environment capability
function system.loadfile(file, env)
	assert(type(file) == "string", "expected string, [table]")
	assert(fs.exists(file), "file does not exist")
	assert(not fs.isDir(file), "path is directory")
	assert(env == nil or type(env) == "table", "expected string, [table]")
	if load then
		local name = fs.getName(file)
		local f = fs.open(file, "r")
		local data = f.readAll()
		f.close()
		return load(data, name, nil, env or _G)
	else
		return setfenv(loadfile(file), env or _G)
	end
end

-- load core modules
local e = setmetatable({system = system}, {__index = _G})
system.loadfile(".system/paths.lua", e)()

_G.system = {}
for k, v in pairs(system) do
	_G.system[k] = v
end