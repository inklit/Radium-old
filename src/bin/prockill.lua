-- bin/prockill.lua
-- kills a process by PID or program name

local args = {...}
if not args[1] then
	print("Usage: prockill <...>\n\nKills all processes with PIDs matching any argument passed.\n\nPassing multiple arguments is allowed.")
end

local list = system.procmgr.list()

for i, v in ipairs(args) do
	v = tonumber(v)
	for _, p in pairs(list) do
		if p == v then
			system.procmgr.kill(p)
		end
	end
end