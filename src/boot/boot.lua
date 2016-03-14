-- boot/boot.lua
-- does... stuff

_G.system = {}

-- universally compatible version of loadfile
function system.loadfile(file, env)
	assert(type(file) == "string", "expected string, [table]")
	assert(type(env) == "table" or env == nil, "expected string, [table]")

	if not fs.exists(file) or fs.isDir(file) then
		return
	end

	if load then
		return loadfile(file, env)
	else
		local f, e = loadfile(file)
		if not f then
			return f, e
		end
		return setfenv(f, env), e
	end
end

-- replacement for craftOS's crappy os.loadAPI
function system.loadAPI(file)
	assert(type(file) == "string", "expected string")
	local e = setmetatable({}, {__index = _G})
	local f, err = loadfile(file, e)
	assert(f, err)
	local out = f()
	if type(out) == "table" then
		return out
	else
		local api = {}
		for k, v in pairs(e) do
			api[k] = v
		end
		return api
	end
end

local semver = assert(system.loadAPI("lib/semver.lua"), "failed to load semver.lua")

system.version = semver.new(0, 1, 0, "alpha")

-- temporary
dofile("rom/programs/shell")