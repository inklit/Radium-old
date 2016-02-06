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
	local func, err

	if load then
		local name = fs.getName(file)
		local data = readBinaryFile(f)
		func, err = load(data, name, nil, env or _G)
	else
		local f = fs.open(file, "rb")
		local data = readBinaryFile(f)
		func, err = loadstring(data)
		setfenv(func, env or _G)
	end

	f.close()

	return func, err
end

-- loads a module by its name
-- TODO: Module path?
function system.loadModule(name)
	local e = setmetatable({ system = system }, { __index = _G })
	local func, err = system.loadfile(".system/" .. name .. ".lua", e)

	if func == nil then
		return false, err
	end
	
	func()
	return true
end

-- load core modules
do
	local f = fs.open("/etc/modules.cfg",  "r")

	while true do
		local line = f.readLine()
		if line == nil then
			break
		end

		print("Loading module " .. line .. "...")

		local ok, err = system.loadModule(line)
		if not ok then
			printError(err)
		end
	end
end

_G.system = {}
for k, v in pairs(system) do
	_G.system[k] = v
end