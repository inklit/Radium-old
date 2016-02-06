-- .system/recovery.lua
-- run by bootloader when a fatal error is encountered during boot

local args = {...}

term.clear()
term.setCursorPos(1, 1)
term.setCursorBlink(false)
print("A fatal error has been encountered while booting Radium.")
print("Please report this and provide the following information:")
print()
printError(args[1])
print("_HOST: " .. (_HOST or "nil"))
print("_CC_VERSION: " .. (_CC_VERSION or "nil"))
print("_VERSION: " .. (_VERSION or "nil"))
print()
print("Press 'c' to drop into CraftOS or 's' to exit.")
while true do
	local e = {os.pullEvent("char")}
	if e[2] == "c" or e[2] == "C" then
		os.run({}, "rom/programs/shell")
		break
	elseif e[2] == "s" or e[2] == "S" then
		break
	end
end