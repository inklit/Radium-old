-- bin/besh.lua
-- BEtter SHell - a replacement for the CraftOS shell

do
	local currentDir = ""

	_G.shell = {
		dir = function()
			return currentDir
		end,

		setDir = function(dir)
			currentDir = dir
		end,

		run = function(cmd, ...)
			local resolvedCmd = shell.resolveProgram(cmd) or cmd
			local pid, err = system.procmgr.new(resolvedCmd, ...)
			
			if pid == nil and err ~= nil then
				error(err, 0)
				return false
			end

			return true, pid
		end,

		resolveProgram = function(program)
			local aliasResolved = system.aliases.resolve(program)
			return system.paths.resolve(
				system.paths.path(),
				system.paths.pathExtensions(),
				aliasResolved,
				currentDir
			)
		end,

		resolve = function(file)
			local firstChar = file:sub(1, 1)

			if firstChar == "/" or firstChar == "\\" then
				return fs.combine("", file)
			else
				return fs.combine(currentDir, file)
			end
		end
	}
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

do
	while true do
		write("$ ")

		local input = read(nil, shellHistory)
		shellHistory[#shellHistory + 1] = input

		local preprocessed = preprocessCommand(input)
		processCommand(preprocessed)
	end
end