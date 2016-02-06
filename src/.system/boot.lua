-- .system/boot.lua
-- Run on startup, loads core functions and the system API

local system = {}

system.version = 0.1
system.name = "Radium " .. system.version

local function readBinaryFile(f)
	local data = ""

	while true do
		local byte = f.read()
		if byte == nil then
			break
		end

		data = data .. string.char(byte)
	end

	return data
end

-- universally compatible loadfile replacement with environment capability
function system.loadfile(file, env)
	assert(type(file) == "string", "expected string, [table]")
	assert(fs.exists(file), "file does not exist")
	assert(not fs.isDir(file), "path is directory")
	assert(env == nil or type(env) == "table", "expected string, [table]")

	local f = fs.open(file, "rb")

	if load then
		local name = fs.getName(file)
		local data = readBinaryFile(f)
		return load(data, name, nil, env or _G)
	else
		local f = fs.open(file, "rb")
		local data = readBinaryFile(f)
		return setfenv(loadstring(data), env or _G)
	end

	f.close()
end

-- load core modules
local e = setmetatable({system = system}, {__index = _G})
system.loadfile(".system/paths.lua", e)()

_G.system = {}
for k, v in pairs(system) do
	_G.system[k] = v
end