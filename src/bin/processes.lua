-- bin/processes.lua
-- shows a list of processes

local list = system.procmgr.list()
local procTbl = {
	-- Table Header
	colours.green,
	{ "PID", "Name", "CWD", "Status" }		
}

local function capString(str, len)
	if #str > len then
		str = str:sub(1, #str - (#str - len) - 3)
		return str .. "..."
	end

	return str
end

for _,v in pairs(list) do
	if system.procmgr.has(v) then
		local col = system.procmgr.isAlive(v) and colours.white or colours.red

		procTbl[#procTbl + 1] = col
		procTbl[#procTbl + 1] = {
			v; -- PID
			capString(fs.getName(system.procmgr.getPath(v)), 20); -- Name
			capString(system.paths.normalise(system.procmgr.getCWD(v), true), 20); -- CWD
			system.procmgr.getStatus(v);
		}
	end
end

textutils.pagedTabulate(table.unpack(procTbl))