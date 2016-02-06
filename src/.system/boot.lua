-- .system/boot.lua
-- loads core functions and the system API

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

-- loads a module by its name into the system table
-- TODO: Module path?
function system.loadModule(name)
	assert(type(name) == "string", "expected string")
	local e = setmetatable({ system = system }, { __index = _G })
	local filename = fs.combine(".system", name .. ".lua")
	assert(fs.exists(filename), "module " .. name .. " not found")
	assert(not fs.isDir(filename), "module " .. name .. " not found")

	if system[name] then
		return true, "module already loaded"
	end

	local func, err = system.loadfile(filename, e)
	if func == nil then
		return false, err
	end
	ok, out = pcall(func)

	if not ok then
		return false, out
	else
		system[name] = out
		return true
	end
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

_G.system = system