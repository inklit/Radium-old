-- .system/recovery.lua
-- run by bootloader when a fatal error is encountered during boot

local args = {...}

term.clear()
term.setCursorPos(1, 1)
term.setCursorBlink(false)

-- collect data
local err = args[1]
local host = "_HOST: " .. (_HOST or "nil")
local cc_version = "_CC_VERSION: " .. (_CC_VERSION or "nil")
local version = "_VERSION: " .. (_VERSION or "nil")

-- create crash dump
pcall(function()
	local f = fs.open("crash.dmp", "w")

	f.write(err .. "\n")
	f.write(host .. "\n")
	f.write(cc_version .. "\n")
	f.write(version .. "\n")

	f.close()
end)

-- tell user what happened
print("A fatal error has been encountered while booting Radium.")
print("Please report this and provide the following information:")
print()
printError(err)
print(host)
print(cc_version)
print(version)
print()
print("This data has also been written to 'crash.dmp'.")
print("Press 'c' to drop into CraftOS or 's' to exit.")

-- give user basic option - shell or exit
while true do
	local e = {os.pullEvent("char")}
	if e[2] == "c" or e[2] == "C" then
		os.run({}, "rom/programs/shell")
		break
	elseif e[2] == "s" or e[2] == "S" then
		break
	end
end