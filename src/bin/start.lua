-- bin/start.lua
-- starts an executable file as a process

local file = ...
local progArgs = { select(2, ...) }

if file == nil then
	printError("Usage: " .. fs.getName(shell.getRunningProgram()) .. " <program> [...]")
	return
end

print(system.procmgr.new(file, table.unpack(progArgs)))