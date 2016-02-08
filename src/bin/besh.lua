-- bin/besh.lua
-- BEtter SHell - a replacement for the CraftOS shell

local currentDir = ""

local shell = {}

function shell.dir()
	return currentDir
end

function shell.setDir(dir)
	currentDir = dir
end

function shell.run(cmd, ...)
	local resolvedCmd = shell.resolveProgram(cmd) or cmd
	assert(fs.exists(resolvedCmd), "file not found: " .. resolvedCmd)

	local env = setmetatable({ shell = shell }, { __index = _G })
	local pid, err = system.procmgr.new(resolvedCmd, env, ...)
	
	if pid == nil and err ~= nil then
		error(err, 0)
		return false
	end

	return true, pid
end

function shell.resolveProgram(program)
	local aliasResolved = system.aliases.resolve(program)
	return system.paths.resolve(
		system.paths.path(),
		system.paths.pathExtensions(),
		aliasResolved,
		currentDir
	)
end

function shell.resolve(file)
	local firstChar = file:sub(1, 1)

	if firstChar == "/" or firstChar == "\\" then
		return fs.combine("", file)
	else
		return fs.combine(currentDir, file)
	end
end

local shellHistory = {}

-- resolve environment variables and whatnot
local function preprocessCommand(cmd)
	-- TODO: actually do this
	return cmd
end

local function processCommand(cmd)
	local elems = {}

	for elem in cmd:gmatch("[^%s]+") do
		elems[#elems + 1] = elem
	end

	local ok, err = pcall(function()
		local _, pid = shell.run(table.unpack(elems))
		system.procmgr.waitForExit(pid)
	end)

	if not ok then
		printError(err)
	end
end

local function formatCurrentDir(dir)
	if dir:sub(1, 1) ~= "/" then
		dir = "/" .. dir
	end

	if dir:sub(#dir, #dir) == "/" then
		dir = dir:sub(1, #dir - 1)
	end

	return dir
end

do
	while true do
		write(formatCurrentDir(currentDir) .. "$ ")

		local input = read(nil, shellHistory)
		shellHistory[#shellHistory + 1] = input

		local preprocessed = preprocessCommand(input)
		processCommand(preprocessed)
	end
end