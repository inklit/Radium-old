-- bin/besh.lua
-- BEtter SHell - a replacement for the CraftOS shell

local currentDir = ""
local programStack = {}

local shell = {}

function shell.dir()
	return currentDir
end

function shell.setDir(dir)
	currentDir = dir
end

function shell.run(cmd, ...)
	local resolvedCmd = shell.resolveProgram(cmd) or cmd
	if not fs.exists(resolvedCmd) then
		return false, "file not found: " .. resolvedCmd
	end

	programStack[#programStack + 1] = resolvedCmd

	local env = setmetatable({ shell = shell }, { __index = _G })
	local pid, err = system.procmgr.new(resolvedCmd, env, ...)
	
	if pid == nil and err ~= nil then
		error(err, 0)
		return false
	end

	system.procmgr.waitForExit(pid)

	return true
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

function shell.exit()
	system.procmgr.kill(__PID__)
end

function shell.path()
	return system.paths.path()
end

function shell.setPath(path)
	return system.paths.setPath(path)
end

function shell.aliases()
	return system.aliases.list()
end

function shell.setAlias(alias, path)
	return system.aliases.set(alias, path)
end

function shell.clearAlias(alias)
	return system.aliases.set(alias, nil)
end

function shell.programs(includeHidden)
	local programs = {}

	for pathElem in shell.path():gmatch("[^%:]+") do
		local absPath = shell.resolve(pathElem)
		if fs.isDir(absPath) then
			for _,file in pairs(fs.list(absPath)) do
				if not fs.isDir(file) then
					local exts = system.paths.pathExtensions()

					for ext in exts:gmatch("([^:]+)") do
						ext = ext:gsub("%*", "(.+)")
						if file:match(ext) then
							if includeHidden then
								if file:sub(1, 1) == "." then
									programs[#programs + 1] = file
								end
							else
								programs[#programs + 1] = file
							end
						end
					end
				end
			end
		end
	end

	return programs
end

function shell.getRunningProgram()
	return programStack[#programStack]
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
		local success, err = shell.run(table.unpack(elems))
		if err and not success then
			printError(err)
		end
		programStack[#programStack] = nil
	end)
end

do
	while true do
		write(system.paths.normalise(currentDir, true) .. "$ ")

		local input = read(nil, shellHistory)
		shellHistory[#shellHistory + 1] = input

		local preprocessed = preprocessCommand(input)
		processCommand(preprocessed)
	end
end