-- boot/recovery.lua
-- run when an error is encountered loading or running boot.lua
-- in the future this may also handle other problems

local args = {...}

-- wipes the terminal, optionally setting the background color
local function clear(c)
	term.redirect(term.native())
	term.setBackgroundColor(c or colors.black)
	term.setTextColor(colors.white)
	term.setCursorPos(1,1)
	term.setCursorBlink(false)
	term.clear()
end

-- simple function to take a long string and make a table of lines that will fit on the screen
local function wrapLines(text, w)
	local w = w or term.getSize()
	local line, lines = {}, {}
	for word in text:gmatch("(%S+)") do
		table.insert(line, word)
		if (#table.concat(line, " ") + 2 + #word) > w then
			table.insert(lines, table.concat(line, " "))
			line = {}
		end
	end
	if #line > 0 then
		table.insert(lines, table.concat(line, " "))
	end
	return lines
end

-- wraps, centers, and prints a string
local function printCenter(text)
	local w, _ = term.getSize()
	for _, l in pairs(wrapLines(text, w-2)) do
		local x = ((w - #l) / 2) + 1
		local _, y = term.getCursorPos()
		term.setCursorPos(x, y)
		term.write(l)
		term.setCursorPos(x, y+1)
	end
end

-- prints the error all fancy and stuff like a BSOD
-- assume that no code after the crash() call will be run
local function crash(err)
	clear(colors.blue)
	term.setCursorPos(1,2)
	printCenter("FATAL ERROR")
	print()
	printCenter("A fatal error has occurred and the system must shut down.")
	print()
	printCenter("The error is as follows:")
	print()
	printCenter(err)
	print()
	printCenter("If this issue persists, please report this and post the contents of the crash.dmp file.")
	print()
	printCenter("Press any key to shutdown.")
	os.pullEvent("key")
	os.shutdown()
end

local function dump(err)
	fs.delete("crash.dmp")
	local f = fs.open("crash.dmp", "w")
	f.write("Radium recovery crash dump\n\n")
	f.write("Error: " .. err .. "\n")
	f.write("CraftOS version: " .. os.version() .. "\n")
	f.write("_HOST variable: " .. (_HOST or "nil") .. "\n")
	f.write("_CC_VERSION variable: " .. (_CC_VERSION or "nil") .. "\n")
	f.close()
end

if args[1] then
	dump(args[1])
	crash(args[1])
else
	-- todo...?
end