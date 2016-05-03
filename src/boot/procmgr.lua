local procmgr = {}

procmgr.procs = {}

local pid = -1
local function nextPID()
	pid = pid + 1
	return pid
end

-- public (safe) process management api
procmgr.public = {}

function procmgr.public.start()
	-- this function should be overridden on process creation
	error("cannot create child process from nil", 2)
end

function procmgr.public.getProcess(pid)
	if type(pid) == "table" then return pid end
	system.expect(pid, "number", 1)
	return procmgr.procs[pid]
end

function procmgr.public.iter(includeDead)
	-- process iterator
	-- by default only returns living processes
	system.expect(includeDead, "boolean", 1, true)
	local n = -1
	return function()
		while procmgr.procs[n+1] do
			n = n + 1
			if procmgr.procs[n].alive or includeDead then
				return procmgr.procs[n]
			end
		end
		return nil
	end
end

local function createProcess(file, args, parent, cwd, env)
	system.expect(file, "string", 1)
	system.expect(args, "table", 2, true)
	system.expect(parent, "table", 3, true)
	system.expect(cwd, "string", 4, true)
	system.expect(env, "table", 5, true)
	local p = {}
	p.file = file
	p.filename = fs.getName(file)
	p.cwd = cwd or fs.getDir(file)
	p.env = env or setmetatable({}, {__index = _G})
	local f, e = system.loadfile(p.file, p.env)
	if not f then error(e, 2) end
	p.args = args or {}
	local pid = nextPID() -- prevent processes from modifying own pid
	p.parent = parent or {}

	p.env.process = {}
	for k,v in pairs(procmgr.public) do
		p.env.process[k] = v
	end
	p.env.process.start = function(file, args, env, cwd)
		system.expect(file, "string", 1)
		system.expect(args, "table", 2, true)
		system.expect(env, "table", 3, true)
		system.expect(cwd, "string", 4, true)
		return createProcess(file, args, p, env)
	end

	p.pid = pid
	p.co = coroutine.create(f)
	p.alive = true
	p.queue = {p.args}
	procmgr.procs[pid] = p
	return pid
end

function procmgr.startRoot(file, args, env, cwd)
	system.expect(file, "string", 1)
	system.expect(args, "table", 2, true)
	system.expect(env, "table", 3, true)
	system.expect(cwd, "string", 4, true)
	return createProcess(file, args, {}, env, cwd)
end

function procmgr.loop()
	-- primary event loop
	-- handles events and resumes coroutines until all processes are
	local br, e, ok, got, event, stop
	while true do
		stop = true
		for proc in procmgr.public.iter() do
			stop = false
			if #proc.queue > 0 then
				e = table.remove(proc.queue, 1)
				while e do
					if coroutine.status(proc.co) == "dead" then
						proc.alive = false
						break
					end
					if proc.filter and e[1] == proc.filter then
						ok, got = coroutine.resume(proc.co, unpack(e))
					elseif not proc.filter then
						ok, got = coroutine.resume(proc.co, unpack(e))
					end
					if ok then
						proc.filter = got
					else
						proc.err = got
					end
					if coroutine.status(proc.co) == "dead" then
						proc.alive = false
						break
					end
					e = table.remove(proc.queue, 1)
				end
			end
		end
		if stop then break end
		event = {os.pullEventRaw()}
		for proc in procmgr.public.iter() do
			table.insert(proc.queue, event)
		end
	end
end

return procmgr
