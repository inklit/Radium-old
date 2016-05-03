-- boot/boot.lua
-- does... stuff

_G.system = {}
_G.shell = nil

-- useful utility function
function system.expect(arg, typ, n, optional)
	if type(arg) ~= typ and not optional then
		error(("expected %s, got %s for arg %i"):format(typ, type(arg), n), 3)
	elseif type(arg) ~= typ and arg ~= nil and optional then
		error(("expected %s or nil, got %s for arg %i"):format(typ, type(arg), n), 3)
	end
	return arg
end

-- universally compatible version of loadfile
function system.loadfile(file, env)
	system.expect(file, "string", 1)
	system.expect(env, "table", 2, true)

	if not fs.exists(file) or fs.isDir(file) then
		return nil, "file does not exist"
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
	system.expect(file, "string", 1)

	local e = setmetatable({}, {__index = _G})
	local f, err = loadfile(file, e)
	assert(f, err)
	local ok, out = pcall(f)
	assert(ok, out)
	if out ~= nil then
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

local procmgr = assert(system.loadAPI("boot/procmgr.lua"), "failed to load procmgr.lua")

procmgr.startRoot("rom/programs/shell")
procmgr.loop()
print("Shutting down")
sleep(1)
os.shutdown()
