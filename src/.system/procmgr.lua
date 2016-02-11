-- .system/procmgr.lua
-- Provides a process-based multitasking system.

local module = {}

local processes = {}
local newTaskQueue = {}

local nextPID = -1
local _bit = bit32 or bit

module.pstatus = {
	-- atomic statuses
	running 	= 1;	-- the process is running
	suspended 	= 2;	-- the process has been suspended
	done 		= 4;	-- the process has finished
	dead 		= 8;	-- the process has been killed
	ready 		= 16;	-- the process has not been run yet

	-- virtual statuses
	stopped 	= 12; 	-- the process is done or dead
	still		= 44;	-- the process is done, dead or ready
}

local function makePID()
	nextPID = nextPID + 1
	return nextPID
end

local function getProcess(pid)
	if processes[pid] == nil then
		return error("no process with pid " .. pid)
	end

	return processes[pid]
end

-- makes a new process and returns its pid
function module.new(file, env, ...)
	env = env or setmetatable({}, {__index = _G})

	if not fs.exists(file) then
		return error("procmgr.new: no such file")
	end

	local pid = makePID()

	env.__PID__ = pid

	local parent = getfenv(2).__PID__ or -1

	local ptable = {
		pid = pid;
		path = file;
		env = env;
		cwd = fs.getDir(file);
		status = module.pstatus.ready;
		parent = (parent >= 0 and getProcess(parent));
	}

	env.require = function(name)
		assert(type(name) == "string", "expected string")
		local r = system.libs.resolve(name, ptable.cwd)
		assert(r, "failed to resolve library " .. name)
		return system.libs.load(r)
	end

	-- don't replace with table.concat, we need to handle
	-- stupid arguments
	ptable.cmdLine = file .. " "

	for _,v in pairs({ ... }) do
		ptable.cmdLine = ptable.cmdLine .. tostring(v)
	end

	local func, err = system.loadfile(file, env)
	if func == nil then
		error(err, 0)
	end

	ptable.coroutine = coroutine.create(func)
	
	-- we have to resume once on creation
	-- here, we also pass in the program args
	local resumeData = { coroutine.resume(ptable.coroutine, ...) }
	local ok = resumeData[1]

	if not ok then
		printError(resumeData[2])
		return nil, resumeData[2]
	end

	local evtFilters = { select(2, table.unpack(resumeData)) }

	if #evtFilters == 0 then
		ptable.eventFilters = nil
	else
		ptable.eventFilters = evtFilters
	end

	newTaskQueue[#newTaskQueue + 1] = ptable
	return pid
end

-- checks if a certain process has passed a certain event
-- into os.pullEvent
function module.hasRequestedEvent(pid, event)
	local proc = getProcess(pid)
	
	-- nil means no filter
	if proc.eventFilters == nil then
		return true
	end

	for _,v in pairs(proc.eventFilters) do
		if v == event then
			return true
		end
	end

	return false
end

-- checks if a certain status (system.pstatus) applies to the given pid
function module.checkStatus(pid, _status)
	local proc = getProcess(pid)
	local status = proc.status
	return _bit.band(status, _status) == _status
end

-- checks if a pid is real
function module.has(pid)
	return processes[pid] ~= nil
end

-- returns the current working directory of a pid
function module.getCWD(pid)
	local proc = getProcess(pid)
	return proc.cwd
end

-- changes the current working directory of a pid
function module.setCWD(pid, dir)
	if not fs.isDir(dir) then
		return error("procmgr.setCWD: no such directory")
	end

	local proc = getProcess(pid)
	proc.cwd = dir
end

function module.getPath(pid)
	local proc = getProcess(pid)
	return proc.path
end

-- gets the status code of a process
-- if you want to check a processes' status,
-- try using checkStatus
function module.getStatus(pid)
	local proc = getProcess(pid)
	return proc.status
end

-- returns the command line a process was started with
function module.getCmdLine(pid)
	local proc = getProcess(pid)
	return proc.cmdLine
end

function module.getParent(pid)
	local proc = getProcess(pid)
	return (proc.parent and proc.parent.pid) or -1
end

function module.kill(pid)
	-- TODO: Inform the process of its murder
	local proc = getProcess(pid)
	proc.status = module.pstatus.dead
	os.queueEvent("process_dead", pid)
	-- kill children
	for _, v in pairs(processes) do
		if v.parent and v.parent.pid == pid then
			module.kill(v.pid)
		end
	end
end

local function checkProcessStatus(proc)
	if 	coroutine.status(proc.coroutine) == "dead" or 
		module.checkStatus(proc.pid, module.pstatus.dead) then
		-- sorry for your loss
		proc.status = module.pstatus.done
		return false
	end

	return true
end

-- loads a library into a process
function module.loadLib(pid, lib)
	local proc = getProcess(pid)
	assert(type(lib) == "string", "arg #2 must be a library name")

	local absPath, name

	if lib:sub(1, 1) == "/" then -- absolute!
		assert(fs.exists(lib), "file not found: " .. lib)
		absPath = absPath
	else
		absPath = system.libs.resolve(lib, proc.cwd)
	end

	name = system.paths.getNameNoExt(absPath)
	local libTbl, err = system.require(absPath, proc.env)

	if libTbl == nil then
		return false, err 
	end

	proc.env[name] = libTbl
	return true
end

-- resumes each process with the given event data
function module.distribute(...)
	local evtName = ...

	for _,v in pairs(newTaskQueue) do
		processes[v.pid] = v
	end

	newTaskQueue = {}

	local killQueue = {} -- dang that sounds brutal af

	for _,v in pairs(processes) do
		-- don't resume if the coroutine has died
		if checkProcessStatus(v) then
			if module.hasRequestedEvent(v.pid, evtName) then
				local resumeData = { coroutine.resume(v.coroutine, ...) }
				local ok = resumeData[1]

				if not ok then
					printError(resumeData[2])
				else
					local eventFilters = { select(2, table.unpack(resumeData)) }

					if #eventFilters == 0 then
						v.eventFilters = nil
					else
						v.eventFilters = eventFilters
					end
				end
			end
		else
			-- if a dead coroutine has somehow survived, kill its process
			killQueue[#killQueue + 1] = v.pid
		end

		-- check if the coroutine has died after resuming
		if not checkProcessStatus(v) then
			killQueue[#killQueue + 1] = v.pid
		end
	end

	-- carry on with the execution
	for _,v in pairs(killQueue) do
		if module.has(v) then
			module.kill(v)
			processes[v] = nil
		end
	end

	killQueue = {}
end

-- blocks execution until the specified process is dead
function module.waitForExit(pid)
	repeat
		os.pullEvent("process_dead")
	until not module.has(pid)
end

function module.isAlive(pid)
	return module.checkStatus(pid, module.pstatus.running) or module.checkStatus(pid, module.pstatus.suspended) or module.checkStatus(pid, module.pstatus.ready)
end

-- returns a list of pids
function module.list()
	local pids = {}

	for k,_ in pairs(processes) do
		pids[#pids + 1] = k
	end

	return pids
end

function module.countAlive()
	local count = 0
	for _, proc in pairs(processes) do
		if module.isAlive(proc.pid) then
			count = count + 1
		end
	end
	return count
end

return module