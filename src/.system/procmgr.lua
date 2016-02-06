-- .system/procmgr.lua
-- Provides a process-based multitasking system.

local module = {}

local processes = {}

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
		return error("procNew: no such file")
	end

	local pid = makePID()
	local ptable = {
		path = file;
		env = env;
		pid = pid;
		cwd = fs.getDir(file);
		status = module.pstatus.ready;
	}

	-- don't replace with table.concat, we need to handle
	-- stupid arguments
	ptable.cmdLine = file .. " "

	for _,v in pairs({ ... }) do
		ptable.cmdLine = ptable.cmdLine .. tostring(v)
	end

	local func, err = system.loadfile(file, env)
	if func == nil then
		printError(err)
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

	processes[pid] = ptable
	return pid
end

-- checks if a certain status (system.pstatus) applies to the given pid
function module.checkStatus(pid, _status)
	local proc = getProcess(pid)
	local status = proc.status
	return _bit.band(status, _status) == _status
end

-- returns the current working directory of a pid
function module.getCWD(pid)
	local proc = getProcess(pid)
	return proc.cwd
end

-- changes the current working directory of a pid
function module.setCWD(pid, dir)
	if not fs.isDir(dir) then
		return error("procSetCWD: no such directory")
	end

	local proc = getProcess(pid)
	proc.cwd = dir
end

function module.getPath(pid)
	local proc = getProcess(pid)
	return proc.path
end

-- returns the command line a process was started with
function module.getCmdLine(pid)
	local proc = getProcess(pid)
	return proc.cmdLine
end

function module.kill(pid)
	-- TODO: Inform the process of its murder
	processes[pid] = nil
end

local function checkProcessStatus(proc)
	if coroutine.status(proc.coroutine) == "dead" then
		-- sorry for your loss
		proc.status = module.pstatus.done
		return false
	end

	return true
end

-- resumes each process with the given event data
function module.distribute(...)
	local killQueue = {} -- dang that sounds brutal af

	for _,v in pairs(processes) do
		-- don't resume if the coroutine has died
		if checkProcessStatus(v) then
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
		module.kill(v)
	end
end

return module