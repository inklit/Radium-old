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
function module.procNew(file, args)
	if not fs.exists(file) then
		return error("procNew: no such file")
	end

	local pid = makePID()
	local ptable = {
		path = file;
		pid = pid;
		cwd = fs.getDir(file);
		status = system.pstatus.ready;
		cmdLine = file;
	}

	if args ~= nil then
		ptable.cmdLine = ptable.cmdLine .. " " .. args
	end

	processes[pid] = ptable
	return pid
end

-- checks if a certain status (system.pstatus) applies to the given pid
function module.procCheckStatus(pid, _status)
	local proc = getProcess(pid)
	local status = proc.status
	return _bit.band(status, _status) == _status
end

-- returns the current working directory of a pid
function module.procCWD(pid)
	local proc = getProcess(pid)
	return proc.cwd
end

-- changes the current working directory of a pid
function module.procSetCWD(pid, dir)
	if not fs.isDir(dir) then
		return error("procSetCWD: no such directory")
	end

	local proc = getProcess(pid)
	proc.cwd = dir
end

function module.procPath(pid)
	local proc = getProcess(pid)
	return proc.path
end

-- returns the command line a process was started with
function module.procCmdLine(pid)
	local proc = getProcess(pid)
	return proc.cmdLine
end

function module.procKill(pid)
	-- TODO: Inform the process of its murder
	processes[pid] = nil
end

return module