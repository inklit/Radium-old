local filename = ...
if filename == nil then
	return printError("Usage: " .. fs.getName(shell.getRunningProgram()) .. " <filename>")
end

local absFile = shell.resolve(filename)
if not fs.exists(absFile) then
	return printError("File not found")
end

local func = loadfile(absFile)
local f = fs.open(absFile .. "_compiled", "wb")
local bytecode = string.dump(func)

for i=1,#bytecode do
	f.write(string.byte(bytecode:sub(i, i)))
end
f.close()